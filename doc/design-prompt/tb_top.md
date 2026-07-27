# Design prompt — `tb_top`（M1 UVM env 静态骨架）

> 约束层：本 design-prompt 只约束**实现方式**（tb 静态骨架的结构/例化/连线）。
> 任何外部可见 DUT 行为一律以 `doc/spec.md` 为唯一源并**引用**其章节；本文不
> 新增 spec 未载的行为定义（behavior-leak 禁区）。
> 前置：CLAUDE.md §6「tb 架构（M1+ 草图）」为既定项目约定，本文将其落到可交付
> 的实现约束。

## 0. 目标与范围

M1 的静态验证顶层 `tb_top`：例化**单个** `axi_xbar` DUT + 时钟/复位 + N 个 slave
端口侧 AXI master 接口 + M 个 master 端口侧 AXI slave 接口 + SVA `bind` 挂接点；
为 UVM env（`doc/design-prompt/uvm_env.md`）提供接口句柄。本文不含 UVM 动态组件、
不含参考模型（分别见 `uvm_env.md` / `scoreboard_refmodel.md`）。**只写 tb 代码，
不改 `vendor/`。**

## 1. DUT 例化与参数绑定

- **C1.1** 例化恰好一个 `axi_xbar`（struct 参数化 API，直接驱动 `slv_ports_req_i`/
  `slv_ports_resp_o`/`mst_ports_req_o`/`mst_ports_resp_i` struct 数组端口，**不**经
  `axi_xbar_intf` 包装）。依据：spec §0 行 1（M1+ 自研 env 直接驱动 struct 端口）。
- **C1.2** `Cfg`（`axi_pkg::xbar_cfg_t`）**全 13 字段**按基线钉定值绑定：
  `NoSlvPorts=6`、`NoMstPorts=8`、`MaxMstTrans=10`、`MaxSlvTrans=6`、
  `FallThrough=1'b0`、`LatencyMode=axi_pkg::CUT_ALL_AX`、`PipelineStages=1`、
  `AxiIdWidthSlvPorts=5`、`AxiIdUsedSlvPorts=3`、`UniqueIds=1'b0`、
  `AxiAddrWidth=32`、`AxiDataWidth=64`、`NoAddrRules=8`。模块参数 `ATOPs=1'b1`、
  `Connectivity='1`。依据：spec §0 行 2（基线全字段钉定）、§2.1（字段语义）、
  §2.2（模块参数）。这些值应集中在一个 tb 侧配置常量/参数包，便于 M3/M4 配置矩阵
  复用（spec §0 行 3）。
- **C1.3** 五通道 struct 类型与 `slv_req_t/slv_resp_t/mst_req_t/mst_resp_t` 必须用
  `axi/typedef.svh` 的 `AXI_TYPEDEF` 宏按上述 `Cfg` 一致绑定；slave 侧 ID 宽 = 5，
  master 侧 ID 宽 = `AxiIdWidthSlvPorts + $clog2(NoSlvPorts)` = 5 + 3 = 8。依据：
  spec §2.2、§5.1.1。
- **C1.4** `rule_t` 取 `axi_pkg::xbar_rule_32_t`（地址宽度须与 `AxiAddrWidth=32`
  一致）。依据：spec §0 行 2、§2.2。

## 2. 端口接口与连线

- **C2.1** 例化 `Cfg.NoSlvPorts`（=6）个 slave 端口侧接口：TB 在此扮演外部 **AXI
  master**，驱动 `slv_ports_req_i[i]`、采样 `slv_ports_resp_o[i]`。数组下标 `i` =
  slave 端口索引，该索引会被前缀进 master 端口侧事务 ID（供参考模型比对）。依据：
  spec §2.3（`slv_ports_*`）、§5.1。
- **C2.2** 例化 `Cfg.NoMstPorts`（=8）个 master 端口侧接口：TB 在此扮演外部 **AXI
  slave**，采样 `mst_ports_req_o[j]`、驱动 `mst_ports_resp_i[j]`。数组下标 `j` =
  master 端口索引（= 地址 rule 的 `idx` 目标）。依据：spec §2.3（`mst_ports_*`）、
  §3.1。
- **C2.3** `addr_map_i` 绑定为 `NoAddrRules=8` 条 `xbar_rule_32_t` 常量地址表，作为
  tb 侧配置常量提供给 UVM env 与参考模型**共享同一份定义**（单一事实源，避免驱动
  与判决分叉）。地址表构造规则见 `scoreboard_refmodel.md` C1；本文只要求「一份定义、
  两处引用」。依据：spec §3.1（全局共享一张表）、§2.3（`addr_map_i`）。
- **C2.4** `en_default_mst_port_i` 与 `default_mst_port_i` 作为可配置输入接出到 env
  控制；M1 smoke 基线取 `en_default_mst_port_i='0`、`default_mst_port_i='0`（不使能
  default master port，未匹配地址走 decode error slave）。依据：spec §2.3、§3.3、§4。
- **C2.5** `test_i` 恒接 `1'b0`（功能验证恒 0）。依据：spec §2.3（`test_i`）、
  §0 行 4 说明范围。
- **C2.6** 运行时约束落到 env 侧驱动纪律、由本文接口暴露：`addr_map_i`/
  `en_default_mst_port_i`/`default_mst_port_i` **不得在任一 slave 端口 AW/AR valid
  期间变更**；M1 smoke 取恒定地址表（上电即定、全程不变），构造性满足该约束。依据：
  spec §3.4。

## 3. 时钟/复位

- **C3.1** 单一 `clk_i` 上升沿有效；`rst_ni` 异步、低有效。复位释放后所有接口进入
  AXI4 空闲态（`*valid=0`）。依据：spec §2.3（`clk_i`/`rst_ni`）。
- **C3.2** 时钟生成、复位序列、超时看门狗（防止死锁挂起）由 tb_top 提供；超时判据
  必须**延迟不敏感**（按 valid/ready 握手推进判活，不假设固定拍数），仅用于兜底挂起
  检测而非功能判决。依据：spec §7.4（延迟不敏感原则、不得断言固定周期数）。

## 4. SVA bind 挂接点

- **C4.1** tb_top 负责把 `tb/sva/` 下的协议/时序 SVA 模块经 `bind` 挂接到每个
  slave 端口接口与每个 master 端口接口；SVA 模块清单与断言内容见
  `doc/design-prompt/sva_bind.md`。tb_top 只提供 `bind` 语句与信号可见性，不在
  tb_top 内联写断言。依据：CLAUDE.md §6（SVA 经 bind 挂接）、spec §1（DUT 实现完整
  AXI4，协议为基线）。

## 5. 交付形态与验收锚点

- 产物：`tb/`（或按 flist 约定路径）下的 `tb_top`（静态 SV），可被 `sim/flist/tb.f`
  收录（CLAUDE.md §6 flist 布局）。
- 编译弹起：DUT + 6 slave / 8 master 接口 + SVA bind 在 VCS-2018 下 elaborate 通过
  （已知 P-001/P-002 补丁已消 NCE）。
- 功能弹起判据由 M1-01 smoke 场景承载（见 `doc/testplan.md`）。

## 引用的 spec 章节

§0（行 1/2/3/4）、§1、§2.1、§2.2、§2.3、§3.1、§3.3、§3.4、§4、§5.1、§7.4。
