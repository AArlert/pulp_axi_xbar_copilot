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
- **C1.5（M2 激活，运行时重配置）** 地址表版本化：M2-CFG01 场景在运行时更改
  `addr_map_i`/`en_default_mst_port_i`/`default_mst_port_i`（仅在全部 slave 端口
  AW/AR 均空闲的窗口内，spec §3.4）。参考模型须按**每笔事务 AW/AR 握手完成时刻**
  生效的表版本译码，而非像 M1 假设的那样把表当全程恒定的编译期常量。
  `xbar_types_pkg::decode_mst_port()`（当前把 `ADDR_MAP` 读作 `localparam`）需扩展
  签名，把地址表/default-port 结构当**输入参数**传入，供 scoreboard 与
  sva_bind C3.1/C3.2 的新增 SVA 对同一个"运行时活值"表译码——单一事实源
  （C1.1 原则的自然延伸），不得各自维护第二份表快照。依据：spec §3.1、§3.4。

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
  §5.2.2/§5.2.3、§0 行 2。**M2 落地要点**：本判据判的是**接受时序**（第二笔的
  AW/AR 握手必须晚于第一笔的 B/R 完成），不是仅凭最终数据/ID 匹配就能下结论——
  需要 C5.5 的接受时间戳基础设施配合。激励来源：M2-OR01。
- **C5.2** 同 ID、同向、**目标相同** master 端口的事务不受该 stall 约束。依据：
  spec §5.2.4。同样需 C5.5 的时间戳判定"未被无谓推迟"。激励来源：M2-OR02（含
  异向对照，见 uvm_env C5.2 的四维度构造原语）。
- **C5.3** 事务数上限（依据 spec §2.1 `MaxMstTrans`/`MaxSlvTrans` 行 +
  §5.4.1/§5.4.2/§5.4.3/§7.4.5、§0 行 2；BUG-0016/REV-007 裁决后，`MaxSlvTrans`
  侧机制由"§5.4.3 上游确认项"改判"mux 侧机制不存在"的已定结论，`MaxMstTrans`
  侧字面值改判"计数器定宽提示"、有效上限公式见 §5.4.1）：
  - 计数模型须按**（低位 ID 桶 × 方向）独立计数**，不得用单一扁平计数器——依据
    spec §2.1 `MaxMstTrans` 行 + §5.4.1：该条已把分桶口径蒸馏为规范（每（约简
    ID 桶、方向）独立计数器、各带一个目标 master 端口绑定寄存器；spec 该条款自身
    的出处标注为 axi_demux.md §Ordering and Stalls→Implementation L70-74），并
    明确纠正此前"每 slave 端口一个扁平上限"表述。**目标端口绑定**这一点同时解释
    了为何本判据须与 C5.1（保序 stall）配合读——同一（ID 桶、方向）在计数非零
    期间只能绑定一个目标：换目标即落入 C5.1/spec §5.2 的 stall 判据，而非本判据
    的计数上限判据（spec §5.4.1）；两者判的是同一底层机制的两个面（spec §2.1
    `MaxMstTrans` 行明述），互不冲突但须在构造激励时分清楚。
  - **每 slave 端口**（依据 spec §5.4.1/§5.4.3/§7.4.5；BUG-0016/REV-007 裁决）：
    该三元组（M2-TL01 收窄到单一低位 ID、方向、目标 master 端口）在飞计数**有效
    上限 = `2^⌈log₂MaxMstTrans⌉−1`**（基线 15，非字面 `MaxMstTrans=10`）——越过
    字面值 10 是分桶计数器位宽取整效应、非 §7.4.5 的接受边界 ±spill 效应，零功能
    损害。**判决门降级**：不再断言"计数不越 `MaxMstTrans`"，改锚 scoreboard 在
    持续同桶压力下路由/数据/响应路由/完成正确（spec §1/§3.1/§5.1，零 mismatch）
    ＋达标 cover（该三元组在飞计数达到 `MaxMstTrans=10` 至少一次，非空转；激励
    来源 M2-TL01）；计数越过 `MaxMstTrans` 字面值的现象保留为非判决见证
    （`SVA_TXLIMIT_OVER` cover/`uvm_info`）。判决锚点仍延迟不敏感（spec §7.4.5，
    BUG-0013 先例）：slave 端口侧 `SpillAw`/`SpillAr` 位于分桶计数核心逻辑之前，
    弹性缓冲只会使接受更早、不会更晚，故"限内（计数 ≤ `MaxMstTrans`）不假 stall"
    仍是可判真失败的观测量；**不得**断言第 N+1（=第 11）笔在外部边界某具体时点/
    拍数被拒收（弹性缓冲窗口深度随 `LatencyMode` 变化、许可来源未给固定拍数，
    spec §7.4.5/§7.4.3）。
  - **每 master 端口每 ID**（前缀后完整 ID，依据 spec §5.4.2/§5.4.3；BUG-0016/
    REV-007 裁决）：REV-005 曾解锁的"≤ `MaxSlvTrans=6` 绝不假红"弱化可观测上界
    checker**已被 spec §5.4.2 正式收回**——其前提（mux 侧存在 per-ID 在飞计数
    机制）不成立：`MaxSlvTrans` 经 `axi_xbar.sv` L141 实为 `axi_mux` 的
    `MaxWTrans`（AW→W ID 高位 FIFO 深度），mux 无按 ID 分桶的在飞计数机制，
    master 端口每 ID 在飞数受上游 demux 每桶有效上限（§5.4.1）主导、可超
    `MaxSlvTrans`（已见证 8>6）。故 master 侧**无任何可断言在飞上界**：判决门
    同 slave 侧锚 scoreboard 正确性 + 达标 cover（该（master 端口、可观测前缀后
    ID、方向）组合计数达到/越过 `MaxSlvTrans` 至少一次，非空转、非判决见证；
    激励来源 M2-TL02）。**不升格 assert**——这不是"机制级断言仍待上游确认"的
    临时状态，而是"mux 侧机制不存在"的已定结论。
- **C5.4** W-beat 次序：W burst 随其 AW 保持同序、burst 内不与他源交织。依据：
  spec §5.5.1/§5.5.2。激励来源：M2-WO01（≥2 个 slave 端口并发写同一 master 端口，
  比 M1-02 的偶然汇聚更刻意）；判定机制见 C5.5。
- **C5.5（M2 新增，结构澄清）** 接受时间戳基础设施：C5.1（stall 判定）与 C5.4
  （W 次序判定）均需要**握手接受时刻**（仿真时间或周期序号），而非仅最终数据/ID/
  resp 匹配——M1 的记分板只做数据比对，未记录任一笔 AW/AR/W-burst 起始的接受
  时间戳。M2 需在 monitor 或 scoreboard 侧补记：(a) 每笔 AW/AR 握手（`valid&&ready`）
  的接受时间戳，按源 slave 端口分组；(b) 每个 master 端口上 W burst 起始/结束
  的时间戳。用途：(a) 校验 C5.1 stall 期间 DUT 确未接受第二笔；(b) 校验 C5.4 的
  **每一源 slave 端口各自**的 W burst：其在 master 端口侧被服务/完成的先后与**该
  同一源**的 AW 接受先后一致（W-burst 随其 AW 同序，§5.5.1），且 burst 内不与他源
  交织。**不得**据此断言**跨不同源 slave 端口**之间的 burst 服务序 == 跨源 AW 接受
  序——跨源仲裁发生序非可锁定外部行为（C6.2 / spec §5.5.4），且受各源独立 demux
  `SpillAw` 弹性缓冲与 mux round-robin 优先级轮转双重扰动（接受边界即时性另见
  spec §7.4.5、REV-006 §4.3）。**不新增判决语义，只新增记录颗粒度**——期望值仍
  完全来自 spec §5.2/§5.5，不引入新行为假设。
- **注**：M1 smoke 的 M1-02 激励构造为不制造 §5.2.1 的未决对（uvm_env C4.2 注），
  故 M1 不断言 stall 行为；本节判据在 M2 场景 M2-OR01/OR02/TL01/TL02/WO01 激活
  （M2-TL01/TL02 均已按 BUG-0016/REV-007 裁决从 assert 降级为非判决 cover/
  `uvm_info`，spec §5.4.1/§5.4.2/§5.4.3，判决门锚 scoreboard 正确性，见 C5.3）。

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
- M2 判据激活集：C1.5（地址表运行时版本化，M2-CFG01）、C5.1/C5.2/C5.5（保序 stall
  与时间戳基础设施，M2-OR01/OR02）、C5.3（事务上限，slave 侧 M2-TL01 + master 侧
  M2-TL02，均已按 BUG-0016/REV-007 裁决降级为非判决 cover/`uvm_info`、判决门锚
  scoreboard 正确性）、C5.4（W 次序，M2-WO01）、C6.3 的原子读成对判据落地实际
  激励（M2-AT01）。C2（decode error）仍待 M3。

## 引用的 spec 章节

§0（行 2/6）、§1、§2.1、§3.1、§3.2、§3.3、§3.4、§4.1、§4.2、§4.3、§4.4、§5.1、
§5.2、§5.4、§5.5、§6.3、§7.4。
