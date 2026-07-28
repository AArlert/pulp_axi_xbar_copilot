# Design prompt — `uvm_env`（M1 UVM env + master/slave agents + smoke 序列）

> 约束层：只约束**实现方式**（UVM 组件划分、职责、驱动纪律）。DUT 外部可见行为一律
> 引用 `doc/spec.md`；本文不新增 spec 未载行为（behavior-leak 禁区）。参考模型与
> 判决逻辑独立成文（`scoreboard_refmodel.md`），本文只描述 env 如何组织与接线。
> 前置：CLAUDE.md §6「tb 架构（M1+ 草图）」= 多 master agent + 多 slave agent +
> spec 推导的地址路由参考模型记分板。

## 0. 目标与范围

在 `tb_top`（`doc/design-prompt/tb_top.md`）之上搭建 UVM env 骨架并跑通 M1 smoke：
`NoSlvPorts=6` 个 master agent（激励源）+ `NoMstPorts=8` 个 slave agent（响应源）+
scoreboard（含参考模型）+ virtual sequencer + config。M1 只做**骨架 + smoke**，功能
场景/随机压测属 M2（spec §0 行 3、CLAUDE.md §6 里程碑）。**只写 tb 代码，不改
`vendor/`。**

## 1. Env 组成与例化数

- **C1.1** master agent 数 = `Cfg.NoSlvPorts` = 6；slave agent 数 = `Cfg.NoMstPorts`
  = 8。每个 master agent 绑定一个 slave 端口接口（TB 扮演外部 master），每个 slave
  agent 绑定一个 master 端口接口（TB 扮演外部 slave）。依据：spec §0 行 2、§1（端口
  方向约定：crossbar slave 端口挂外部 master、master 端口挂外部 slave）、§2.3。
- **C1.2** env 例化 1 个 scoreboard（`scoreboard_refmodel.md`）、1 个 virtual
  sequencer；接口句柄经 `uvm_config_db` 由 tb_top 传入。地址表 `addr_map_i` 定义、
  `en_default_mst_port_i`/`default_mst_port_i` 由 env config 与 tb_top 共享同一份常量
  （tb_top C2.3）。依据：spec §3.1（单一事实源）。

## 2. master agent 职责（TB 扮演外部 AXI master → 驱动 slave 端口）

- **C2.1** driver 按 AXI4 协议在 `slv_ports_req_i[i]` 上发起 AW/W/AR，接收
  `slv_ports_resp_o[i]` 的 B/R；协议本身为基线（spec §1「实现完整 AXI4」）。
- **C2.2** slave 侧事务 ID 宽 = `AxiIdWidthSlvPorts` = 5（spec §2.2、§5.1）。
- **C2.3** monitor 采集该 slave 端口上收发的完整事务（AW/W/B/AR/R 及其 payload、ID、
  地址、burst 属性），转事务对象送 scoreboard 作为「输入观测」。依据：spec §5.1
  （源 slave 端口索引 = 数组下标，参考模型据此推导 master 侧 ID 前缀）。
- **C2.4 驱动纪律（env 侧约束，非 DUT 行为）**：
  - ATOP：M1 baseline `ATOPs=1'b1`，允许发起 `aw.atop != '0` 的原子事务；发起时
    必须保证 ATOP 事务 ID 与**所有**（读+写）在飞事务 ID 不同（AXI5 协议要求）。
    依据：spec §6.4。M1 smoke 若不发 ATOP 亦合法（等价普通读写通路）。
  - 地址：M1 smoke 只发**命中地址表某条 rule** 的地址（不触发 decode error），使
    smoke 停在 happy-path；decode error / default-port 属 M3 错误路径（spec §0 行 3、
    §4）。依据：spec §3.2（匹配语义）。
- **C2.5** agent 应 `NoSlvPorts` 参数化例化、避免逐端口硬编码，便于 M3/M4 端口拓扑
  矩阵 {1×N, N×1, 4×4} 复用（spec §0 行 3）。

## 3. slave agent 职责（TB 扮演外部 AXI slave → 响应 master 端口）

- **C3.1** driver/responder 在 `mst_ports_req_o[j]` 观测到 AW/W/AR 后按 AXI4 协议
  返回 B/R，数据由 slave-side memory model 或可预测生成器提供，使 scoreboard 能据
  发送地址/ID 推导期望回读数据（数据完整性判据的对照源）。依据：spec §1（完整
  AXI4）、§5.1（master 端口侧可观测 ID = {源 slave 端口索引, 原始 slave ID}）。
- **C3.2** master 端口侧观测 ID 宽 = 8（= 5 + `$clog2(6)` = 5 + 3）。slave agent /
  scoreboard 据高 3 位识别源 slave 端口。依据：spec §5.1.1/§5.1.3。
- **C3.3** monitor 采集 master 端口上收发的完整事务送 scoreboard 作为「输出观测」。
- **C3.4** 原子读（atomic load）响应：当收到带读响应的 ATOP AW 时，responder 必须在
  **B 与 R 两个通道都返回响应**。依据：spec §6.3。
- **C3.5 响应时序纪律**：slave agent 的 ready/valid 时序（含随机反压）任意合法即可；
  参考模型判决必须**延迟不敏感**，不得因 slave agent 的具体延迟拍数改变期望值。依据：
  spec §7.4。

## 4. smoke 序列（M1-01 / M1-02，见 `doc/testplan.md`）

- **C4.1 M1-01 happy-path 路由 smoke**：每个 slave 端口 `i` 发起若干**命中地址表**的
  写 burst + 读 burst，目标覆盖多个不同 master 端口 `j`；scoreboard 参考模型校验
  每笔事务路由到正确 master 端口（§3.1 idx / §3.2 match）、master 侧 ID 前缀正确
  （§5.1）、数据完整性、响应码正常（OKAY），零 mismatch，仿真自然结束。
- **C4.2 M1-02 ID 前缀响应路由 smoke**：构造多个 slave 端口发出**低位相同**的 slave
  侧 ID、目标不同 master 端口的事务；scoreboard 校验每笔响应回送到**正确的源 slave
  端口**（由 master 侧 ID 高 `$clog2(NoSlvPorts)` 位区分，§5.1.2/§5.1.3），无跨端口
  错送。依据：spec §5.1。
  - **注**：M1-02 的激励须构造为**不制造同一 slave 端口内同 ID、同向、跨不同 master
    端口的未决对**，以免落入 §5.2 的保序 stall 语义（保序/stall 的功能场景属 M2）；
    即 smoke 只验响应路由正确性，不验 stall 行为。依据：spec §5.2.1（stall 触发条件）、
    §0 行 3（功能场景归 M2）。

## 5. M2 驱动纪律新增（激活运行时重配置/保序/事务上限/W 次序/ATOP 场景）

以下均为 env 侧**驱动能力/时序纪律**新增（不新增 DUT 外部可见行为断言，判决仍
落在 `scoreboard_refmodel.md`/`sva_bind.md`）：

- **C5.1 运行时重配置窗口（M2-CFG01，spec §3.4）**：env 提供一个"全端口静默"
  同步点（等待全部 6 个 slave 端口的 AW 与 AR 均非 valid 的一拍），仅在该窗口内
  更新一次 `addr_map_i`/`en_default_mst_port_i`/`default_mst_port_i`；变更前/
  变更后各发一批命中新旧表不同路由结果的事务，供 scoreboard（scoreboard_refmodel
  C1.5）区分。
- **C5.2 同 ID 跨端口构造原语（M2-OR01/OR02，spec §5.2）**：master agent 序列
  需能对指定 slave 端口连发两笔请求，独立控制四个维度：(a) 低
  `AxiIdUsedSlvPorts` 位是否相同、(b) 方向是否相同、(c) 地址译码目标是否落在
  不同 master 端口、(d) 两笔间隔（背靠背 or 有意分离）。M2-OR01（stall 触发）取
  相同+相同+不同；M2-OR02（非 stall 对照）取相同+相同+相同，以及相同+不同+任意
  两组。同一套原语覆盖两个场景，不重复开发。
- **C5.3 持续压测原语（M2-TL01/TL02，spec §5.4.1/§5.4.2/§5.4.3）**：master agent 需支持"背靠背
  连发 N 笔、不等待逐笔完成"的非阻塞发送模式（M1 smoke 的发送节奏未验证是否能
  连续压满在飞计数）。M2-TL01 要求这 N 笔低位 ID、方向、目标 master 端口三者
  全部相同（避免与 C5.2 的跨端口 stall 构造混淆——目标一变就落入那条判据而非
  本条的计数上限判据，见 scoreboard_refmodel C5.3 的同一说明）。slave
  agent responder 需能按需**有界拖延** B/R（不违反协议的合法延迟）以维持在飞
  计数处于目标值附近，避免"响应过快、上限从未真正被顶到"的空转（呼应
  `workflow/dispatch/coverage_hole.md` 的可证伪性要求）。
  M2-TL02 的压测目标已由 REV-005 裁决确定为**弱化上界**：向同一 master 端口连发
  同（前缀后）ID、同方向事务压满 `MaxSlvTrans`，供其已解锁的可观测上界 checker
  监视（分组「每 master 端口 × 每可观测前缀后 ID × 每方向」，方向分开计）；机制级
  拒收触发点仍为 spec §5.4.3 上游确认项、不构造针对性激励。
- **C5.4 多源汇聚（M2-WO01，spec §5.5）**：virtual sequencer 需能同步启动 ≥2 个
  不同 slave 端口的写序列，令它们的 AW 落在同一 master 端口且时间上交错到达，
  制造真实仲裁竞争（而非各自独立、先后不重叠的写——那样不会比 M1-02 的偶然
  汇聚更有效）。
- **C5.5 ATOP 序列（M2-AT01，spec §6.3/§6.4）**：复用 C2.4 已有的 ATOP 驱动纪律
  （ID 唯一性），新增一条显式发起"要求读响应的 atop 编码"的序列；slave agent
  responder（C3.4）确认该 AW 收到后走通 B+R 双通道。

## 6. 交付形态与验收锚点

- 产物：`tb/` 下 UVM env、master/slave agent、virtual sequencer、smoke sequence，
  收录于 `sim/flist/tb.f`（CLAUDE.md §6）。
- 弹起判据：env build/connect/run phase 无 `UVM_ERROR`/`UVM_FATAL`；smoke 场景由
  M1-01/M1-02 承载并经 `make evidence` 产出 PASS 日志（评审门后 DV 落地）。
- M2 判据：§5 驱动原语支撑的场景（M2-CFG01/OR01/OR02/TL01/WO01/AT01）经
  `make evidence` 产出 PASS 日志；M2-TL02 落地为已解锁的弱化可观测上界 checker
  （spec §5.4.2；机制级断言仍为 §5.4.3 上游确认项、不派发）。

## 引用的 spec 章节

§0（行 1/2/3）、§1、§2.2、§2.3、§3.1、§3.2、§3.4、§4、§5.1、§5.2、§5.4、§5.5、
§6.3、§6.4、§7.4。
