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

## 5. 交付形态与验收锚点

- 产物：`tb/` 下 UVM env、master/slave agent、virtual sequencer、smoke sequence，
  收录于 `sim/flist/tb.f`（CLAUDE.md §6）。
- 弹起判据：env build/connect/run phase 无 `UVM_ERROR`/`UVM_FATAL`；smoke 场景由
  M1-01/M1-02 承载并经 `make evidence` 产出 PASS 日志（评审门后 DV 落地）。

## 引用的 spec 章节

§0（行 1/2/3）、§1、§2.2、§2.3、§3.1、§3.2、§4、§5.1、§5.2、§6.3、§6.4、§7.4。
