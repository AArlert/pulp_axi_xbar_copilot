# Design prompt — `scoreboard_refmodel`（地址路由参考模型记分板）

> 约束层：本文规定参考模型/记分板的**实现结构**；其**期望值全部从 `doc/spec.md`
> 推导并逐条引用章节**（DV checker 期望值只准从 spec 推导——CLAUDE.md §0/§6、
> spec §0 行 6）。本文**不新增** spec 未载的判决语义；凡需要而 spec 未覆盖者，登记
> `doc/bugs.md` 走 rev 仲裁补 spec，绝不在本 design-prompt 里私自定义（behavior-leak
> 禁区）。
> 前置：CLAUDE.md §6「spec 推导的地址路由参考模型记分板」。

## 0. 目标与范围

记分板消费 master agent monitor（slave 端口侧「输入观测」）与 slave agent monitor
（master 端口侧「输出观测」）两路事务流，用参考模型计算每笔 slave 端口入站事务的
**期望路由目标 / 期望 master 侧 ID / 期望数据**，与实际输出观测比对判决。M1 只落地
smoke 所需的判决子集（routing + ID 前缀 + 数据完整性 + 响应码），保序/stall/decode
error 等语义在本文中**描述为参考模型应具备的能力**但其**断言由后续里程碑场景激活**
（M2 功能场景、M3 错误路径）。

## 1. 地址译码参考模型（依据 spec §3）

- **C1.1** 参考模型与驱动侧**共享同一份** `addr_map_i` rule 表定义（tb_top C2.3），
  以 `NoAddrRules=8` 条 `xbar_rule_32_t` 表达；全部 slave 端口共享同一张全局表。依据：
  spec §3.1.1。
- **C1.2** 匹配语义：地址 `addr` 命中某 rule 当且仅当
  `addr >= start_addr && addr < end_addr`（含起址、不含终址）；表定义须满足
  `start_addr <= end_addr`。依据：spec §3.2。
- **C1.3** 重叠决议：两条 rule 区间重叠时，**地址表中位置更高（更显著）**的 rule
  胜出；参考模型的译码函数必须复现此优先级。依据：spec §3.1.3。
- **C1.4** default master port：当某 slave 端口 `en_default_mst_port_i[i]=1` 且地址
  不匹配任何 rule 时，期望目标 = `default_mst_port_i[i]`（而非 decode error slave）；
  `=0` 时不匹配地址期望走 decode error slave（§2）。M1 smoke 取 `en=...=0` 且只发
  命中地址，故此分支在 M1 不被激励，但参考模型须实现之（M3 激活）。依据：spec §3.3、
  §4.2。

## 2. Decode error 参考模型（依据 spec §4；M3 激活）

- **C2.1** 事务地址不匹配任何 rule 且该 slave 端口未使能 default master port 时，
  期望由本 slave 端口的内部 decode error slave 应答，响应码 = `axi_pkg::RESP_DECERR`。
  依据：spec §4.1/§4.2/§4.3。
- **C2.2** beat 数期望：**读**事务出齐 `AxLEN+1` 个 R beat（末拍 `RLAST=1`）；**写**
  事务在收齐整个 W burst 后返回**单拍 B**（DECERR）。依据：spec §4.3。
- **C2.3** 读响应每 beat 数据期望 = `32'hBADCAB1E`，按 `AxiDataWidth` 零扩展/截断。
  依据：spec §4.4。
- **注**：M1 smoke 不发未匹配地址（uvm_env C2.4），本节判据在 M3 错误路径场景激活；
  此处成文以固定期望值来源，避免 M3 时另起炉灶。

## 3. ID 前缀与响应回送参考模型（依据 spec §5.1）

- **C3.1** slave 端口 `i` 发往任一 master 端口的事务，在 master 端口侧的观测 ID
  期望满足：`id[高 $clog2(NoSlvPorts) 位] = i`（源 slave 端口索引），
  低 `AxiIdWidthSlvPorts` 位 = 原始 slave 侧 ID。基线：高 3 位 = `i`，低 5 位 = 原
  ID，总宽 8。依据：spec §5.1.1/§5.1.2/§5.1.3。
- **C3.2** 响应回送：master 端口返回的 B/R 期望被路由回**其 ID 高
  `$clog2(NoSlvPorts)` 位所指的源 slave 端口**；记分板须校验每笔响应落在正确源端口，
  无跨端口错送（M1-02 主判据）。依据：spec §5.1.2/§5.1.4。
- **C3.3** ID 空间不相交：不同 slave 端口在 master 端口侧的 ID 空间互不相交（前缀
  保证）；参考模型可据此把「输出观测」唯一归因到某源 slave 端口。依据：spec §5.1.4。

## 4. 数据完整性判据（依据 spec §1 完整 AXI4；M1 主判据）

- **C4.1** 写路径：某 slave 端口写入的 W burst 数据/`wstrb`/`wlast` 应原样出现在
  目标 master 端口对应事务上；记分板据路由结果比对。依据：spec §1、§3。
- **C4.2** 读路径：某 slave 端口读回的 R burst 数据应等于目标 master 端口 slave
  agent 为该地址/ID 提供的可预测数据（slave agent memory model，uvm_env C3.1）；
  记分板端到端比对。依据：spec §1、§5.1（响应回送正确性）。
- **C4.3** burst 属性（`len`/`size`/`burst`/`last`）在路由前后一致。依据：spec §1。

## 5. 保序 / stall / 事务上限（依据 spec §5.2/§5.4/§5.5；M2 激活）

- **C5.1** 同一 slave 端口收到两个**同 ID（低 `AxiIdUsedSlvPorts=3` 位相同）、同向、
  目标不同 master 端口**的事务时，第二个在第一个完成前不被接受（AW/AR stall）。
  基线 `AxiIdUsedSlvPorts=3 < AxiIdWidthSlvPorts=5` ⇒ 存在**假冲突 stall**；参考模型
  的「同 ID」判定只比较低 3 位。假冲突只影响性能不影响正确性。依据：spec §5.2.1/
  §5.2.2/§5.2.3、§0 行 2。
- **C5.2** 同 ID、同向、**目标相同** master 端口的事务不受该 stall 约束。依据：
  spec §5.2.4。
- **C5.3** 事务数上限：每 slave 端口在飞 ≤ `MaxMstTrans=10`；每 master 端口每 ID
  在飞 ≤ `MaxSlvTrans=6`。依据：spec §5.4、§0 行 2。
- **C5.4** W-beat 次序：W burst 随其 AW 保持同序、burst 内不与他源交织。依据：
  spec §5.5.1/§5.5.2。
- **注**：M1 smoke 的 M1-02 激励构造为不制造 §5.2.1 的未决对（uvm_env C4.2 注），
  故 M1 不断言 stall 行为；本节判据在 M2 功能场景激活。

## 6. 判决红线（延迟不敏感 + 禁断言仲裁序）

- **C6.1 延迟不敏感**：所有判决按 valid/ready 握手跟踪事务完成，**不得断言任何固定
  周期数 / 端到端拍数**；`LatencyMode=CUT_ALL_AX`、`PipelineStages=1` 均为延迟不敏感
  插桩，不改功能响应。依据：spec §7.4（含 BUG-0004 裁决）。
- **C6.2 禁断言 round-robin 具体发生序**：记分板**不得**断言任一条特定 round-robin
  仲裁发生序、也不得断言某一拍的具体被授权端口；只准从**性质**推导期望：同 ID 同向
  保序（§5.2）、W-burst 随 AW 同序且 burst 内不交织（§5.5.1）、无饿死。依据：
  spec §5.5.4（C4 裁决）。
- **C6.3** ATOP：`ATOPs=1'b1` 基线下若激励含原子读，期望 B 与 R 两通道均返回；参考
  模型须成对跟踪。依据：spec §6.3。

## 7. 交付形态与验收锚点

- 产物：`tb/` 下 scoreboard + 参考模型（译码函数、ID 前缀函数、事务匹配/判决），
  收录于 `sim/flist/tb.f`。
- M1 判据激活集：C1（译码，M1 只走命中分支）、C3（ID 前缀/回送）、C4（数据完整性）、
  C6（判决红线）。C2/C5 成文但由 M2/M3 场景激活。

## 引用的 spec 章节

§0（行 2/6）、§1、§3.1、§3.2、§3.3、§4.1、§4.2、§4.3、§4.4、§5.1、§5.2、§5.4、
§5.5、§6.3、§7.4。
