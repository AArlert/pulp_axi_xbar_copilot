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
- **C4.2（M2 新增挂接点）**：`sva_bind.md` §3 的 C3.1/C3.2（配置稳定性、同 ID
  跨端口 stall）观测范围超出单一 AXI 通道接口——除该 slave 端口自身的 AW/AR/B/R
  信号外，还需读取**全局共享**的 `addr_map_i`，以及**该 slave 端口一位/一索引**
  的 `en_default_mst_port_i[i]`/`default_mst_port_i[i]`。tb_top 需在其 slave 端口
  挂接点（既有 generate 循环内）额外把这三路信号接给新增的 SVA 实例；`addr_map_i`
  对 6 个实例是同一句柄（无需复制），`en_default_mst_port_i[i]`/
  `default_mst_port_i[i]` 按下标传入。master 端口侧挂点（C4.1 既有）不需要这三路
  信号，不受影响。依据：spec §2.3（`addr_map_i`/`en_default_mst_port_i`/
  `default_mst_port_i` 端口定义）、§3.4。

## 5. M3 增量：配置点参数化与多配置构建

M3 要把 spec §0 行 3 的配置矩阵落成可回归的构建产物。本节只约束**构建/选型机制**，
配置点各自要验什么由 `doc/testplan.md` M3-CF01~CF04 承载。

- **C5.1 配置点由 `TEST` 名唯一选定**。理由是机械的：`scripts/regress.py`（pinned
  snapshot，本地不可改）对每条回归条目只执行 `make -C sim run TEST=<t> SEED=<n>`，
  除 `TEST`/`SEED` 外不传任何变量——配置点若不由 `TEST` 名决定，回归清单就无法
  表达它。同时核心不变式要求 `make run TEST=<t> SEED=<n>` 唯一确定"被仿真的是
  哪个设计"，故配置点**不得**由环境变量、外部文件或随机数决定。
- **C5.2 每配置点独立构建产物**（独立输出目录与 `simv`），不得共用同一个
  `$(OUT)/simv`。理由：配置为 elaboration 时常量，切换配置必须重新 elaborate；
  共用产物时 VCS 增量编译一旦复用上一配置的 `simv`，"配置 X 通过"与"基线又跑了
  一遍"在日志上完全同形——即 BUG-0022（lint 假绿）/BUG-0028（分母缩水）那一类
  **沉默的通过**。
- **C5.3 运行自报生效配置**：每次仿真在开头打印本次 elaborate 生效的**全部 13 个
  `Cfg` 字段 + `ATOPs` + `Connectivity` + 地址表条目**。这样每份 evidence 自证其
  配置点，签核抽查不必反推。依据：spec §2.1/§2.2（字段清单）、§0 行 3。
- **C5.4 基线配置逐位不变**：参数化重构**不得**改变基线（C1.2）的任何取值或地址表
  区间布局。验收锚点是既有 11 条证据仍可复现——`make regress` 产出的
  `sim/result_summary.txt` 与 `doc/evidence/v0.2.*/result_summary.txt` 保持一致。
- **C5.5 配置点的定义规则**：配置点之间**只**变动 spec §0 行 3 列举的维度
  （`NoSlvPorts`/`NoMstPorts`、`LatencyMode`、`UniqueIds`、`ATOPs`、`Connectivity`）；
  其余 `Cfg` 字段（`MaxMstTrans`/`MaxSlvTrans`/`FallThrough`/`PipelineStages`/
  `AxiIdWidthSlvPorts`/`AxiIdUsedSlvPorts`/`AxiAddrWidth`/`AxiDataWidth`/
  `NoAddrRules=8`）与 8 条 rule 的地址区间布局一律沿用基线，rule 的 `idx` 取
  `rule_index mod NoMstPorts`（cfgD 例外见 C5.7）。目的：让配置点之间的差异**只有
  被验的那一维**，失败可归因。依据：spec §0 行 2/行 3、§3.1（多条 rule 可指向同一
  master 端口）。
- **C5.6 `NoSlvPorts=1` 的 ID 前缀退化**（cfgA）：按 spec §5.1 的公式字面取值，
  master 端口 ID 宽 = `AxiIdWidthSlvPorts + $clog2(1)` = `AxiIdWidthSlvPorts` = 5，
  前缀为 **0 位宽**。类型定义与参考模型须按该字面取值处理，不得沿用基线的 3 位
  前缀假设；0 位宽 part-select 在 SV 中非法，实现应把该情形表达为"无前缀字段"而
  不是宽度为 0 的切片。依据：spec §5.1。
- **C5.7 稀疏 `Connectivity` 的构造规则**（cfgD）：地址表是**全局共享**的一张表
  （spec §3.1.1），故译码结果与源 slave 端口无关；要让 spec §8.3 的环境约束
  （不把任一 slave 端口的任何地址译码到其非连通 master 端口）**构造性**成立，
  唯一可行的构造是——**凡有 rule 指向的 master 端口，对所有 slave 端口连通**；
  稀疏只能出现在**无任何 rule 指向**的 master 端口上，而这类端口是合法配置、仅经
  default master port 可达（spec §3.1.2）。cfgD 据此令 8 条 rule 只指向 mst0/mst1，
  mst2/mst3 仅作逐 slave 端口的 default master port，`Connectivity` 逐行只留出本行
  自己的 default 端口。依据：spec §3.1、§3.3、§8.3。

## 6. 交付形态与验收锚点

- 产物：`tb/`（或按 flist 约定路径）下的 `tb_top`（静态 SV），可被 `sim/flist/tb.f`
  收录（CLAUDE.md §6 flist 布局）。
- 编译弹起：DUT + 6 slave / 8 master 接口 + SVA bind 在 VCS-2018 下 elaborate 通过
  （已知 P-001/P-002 补丁已消 NCE）。
- 功能弹起判据由 M1-01 smoke 场景承载（见 `doc/testplan.md`）。

## 引用的 spec 章节

§0（行 1/2/3/4）、§1、§2.1、§2.2、§2.3、§3.1、§3.3、§3.4、§4、§5.1、§7.4、§8.3。
