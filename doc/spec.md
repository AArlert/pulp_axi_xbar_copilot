# axi_xbar DUT 行为规格（单一事实源）

> v0：初稿经 REV-001 评审（条件通过）并按其 C1~C5 修订后应用，
> sha256 pin 于 `doc/spec.sha256`（`docs.py --pin-spec` 维护）。

本文从上游材料机械提炼（pulp-platform/axi **v0.39.9**，SHA
`a256a3b86394fedf19e361047fccfdd7f6ef83e4`，pin 记录见 `vendor/VENDOR.md`）：

- `vendor/axi/doc/axi_xbar.md`（主文档；下文简称 *xbar.md*）
- `vendor/axi/doc/axi_demux.md`、`vendor/axi/doc/axi_mux.md`（下层部件行为佐证；简称 *demux.md* / *mux.md*）
- `vendor/axi/src/axi_pkg.sv`（`xbar_cfg_t` / `xbar_latency_e` / `xbar_rule_64_t` / `xbar_rule_32_t` 定义段；简称 *axi_pkg*）
- `vendor/axi/src/axi_xbar.sv` 头注释与参数/端口声明段（module 声明部分，不含实现体；简称 *xbar.sv 声明*）

**checker/SVA 的期望值只准从本文推导**；本文有缺口/歧义时走 CLAUDE.md §2 的
失败/歧义登记流程（`doc/bugs.md` → rev 仲裁补 spec），禁止直接照抄 RTL 行为。
仅有 RTL 来源、上游文档未载的条款均已标注 **（来源：RTL——上游文档未载）**。

## 0. 本项目验证适配表 ★

| # | 适配项 | 约定 |
| --- | --- | --- |
| 1 | 验证对象 | 单实例 `axi_xbar`（struct 参数化 API：`slv_req_t/slv_resp_t/mst_req_t/mst_resp_t` 数组端口）。上游 tb 经 `axi_xbar_intf`（AXI_BUS interface 包装，xbar.sv 声明 L174-193）驱动，M0 sanity 沿用；M1+ 自研 UVM env 直接驱动 struct 端口。TB 侧扮演 NoSlvPorts 个 AXI master 与 NoMstPorts 个 AXI slave |
| 2 | 基线配置（M1/M2） | 上游 tb 默认值（orch 卡片钉定；数值经 REV-001（§4 C1 / §3.3）核对 `tb_axi_xbar.sv:66–79`，**标注来源：上游 tb 默认（REV-001 核对）**；本 arch 实例不读 tb 本体）。**`Cfg` 全 13 字段**：`NoSlvPorts=6`、`NoMstPorts=8`（= 6 外部 master × 8 外部 slave）、`MaxMstTrans=10`、`MaxSlvTrans=6`、`FallThrough=1'b0`、`LatencyMode=CUT_ALL_AX`（AW/AR 各 2 拍，§7.2）、`PipelineStages=1`、`AxiIdWidthSlvPorts=5`（⇒ mst 侧 ID 宽 = 5+⌈log₂6⌉ = 8，§5.1）、`AxiIdUsedSlvPorts=3`（< 5 ⇒ **基线即存在假冲突 stall**，§5.2.2）、`UniqueIds=1'b0`、`AxiAddrWidth=32`（rule 用 `xbar_rule_32_t`）、`AxiDataWidth=64`、`NoAddrRules=8`。**模块参数**：`ATOPs=1'b1`（§6）、`Connectivity='1`（全连接，§8）。checker 期望值以上述钉定值为唯一输入推导（尤 `LatencyMode`/`AxiIdUsedSlvPorts`/`FallThrough`/`MaxMstTrans`/`MaxSlvTrans`/`UniqueIds` 决定 stall/latency/保序期望值） |
| 3 | 配置矩阵（M3/M4） | 端口拓扑 {1×N, N×1, 4×4} × `LatencyMode` {NO_LATENCY, CUT_ALL_AX, CUT_ALL_PORTS} × `UniqueIds` {0,1} × `ATOPs` {0,1} × 稀疏 `Connectivity`（非全 '1 矩阵，§8） |
| 4 | 覆盖率口径 | 六类 line+cond+fsm+tgl+branch+assert，≥90% 合格；DUT 范围 = `axi_xbar` 及其**全部强制内部子模块实例**：`axi_xbar_unmuxed`（`axi_xbar` 恒例化 1 个）及其内部的 `addr_decode`、每 slave 端口的 `axi_demux` 与 `axi_err_slv`、每 master 端口的 `axi_mux` 等——以上均为强制内部核心子模块，全部计入 ≥90% 覆盖率层次 |
| 5 | 范围外 | 上游库**旁系**模块不在本项目范围：`axi_lite_xbar`、`axi_interleaved_xbar`（二者**从不被 `axi_xbar` 例化**，与 #4 的强制内部子模块性质不同）及其余不被 `axi_xbar` 例化的 `vendor/axi/src/` 模块（仅当作为 `axi_xbar` 子模块被间接例化时才计入 #4 口径）；`axi_xbar_intf` 仅为 tb 包装、不单独验证。**注：`axi_xbar_unmuxed` 与 `addr_decode` 是强制内部核心子模块（见 #4），不属本行"范围外"清单**（C2 修正，REV-001 §3.3） |
| 6 | spec 歧义处理 | 本 spec 未覆盖/两可的行为 → 登记 `doc/bugs.md` → rev 裁决补 spec（走修改记录），不得由 checker 现场解释；疑似 DUT 行为错误走 DUT_BUG 记录 + 上游 issue，绝不本地改行为（CLAUDE.md §6） |

## 1. 概述

`axi_xbar` 是全连接（fully-connected）AXI4+ATOP crossbar：实现完整 AXI4 协议
外加 AXI5 的原子操作（ATOPs）（xbar.md §开篇；xbar.sv 头注释）。

- 端口方向约定（xbar.md §Design Overview）：crossbar 的 **slave 端口** 挂接外部
  master 模块，**master 端口** 挂接外部 slave 模块；slave/master 端口数均可配。
- 拓扑（xbar.md §Design Overview 框图；CLAUDE.md §6 同述）：每个 slave 端口一个
  `axi_demux` × 每个 master 端口一个 `axi_mux`，任一 slave 端口到全部 master
  端口有直连线（全连接）。
- master 端口的 ID 宽度大于 slave 端口：多出的高位为内部 multiplexer 用于响应
  路由的 slave 端口索引前缀，见 §5（xbar.md §Design Overview）。
- 地址译码在每个 slave 端口独立进行（共享同一张全局地址表），按地址把事务路由
  到目标 master 端口；无匹配时进入每 slave 端口独立的 decode error slave 或
  default master port，见 §3/§4（xbar.md §Address Map、§Decode Errors）。

## 2. 参数与端口

### 2.1 `Cfg`（`axi_pkg::xbar_cfg_t`）字段

依据：xbar.md §Configuration 表 + axi_pkg L482-522 注释。

| 字段 | 类型 | 语义与合法域 |
| --- | --- | --- |
| `NoSlvPorts` | `int unsigned` | crossbar 的 AXI slave 端口数（可挂接的外部 master 模块数） |
| `NoMstPorts` | `int unsigned` | crossbar 的 AXI master 端口数（可挂接的外部 slave 模块数） |
| `MaxMstTrans` | `int unsigned` | 每个 slave 端口按（低 `AxiIdUsedSlvPorts` 位 ID 桶 × 方向）独立计数的在飞事务数上限：每个（ID 桶、方向）计数器独立封顶于**计数器满量程**（有效上限 = `2^idx_width(MaxMstTrans)−1`，本值仅经 `cf_math_pkg::idx_width()` 定计数器位宽、从不进比较器；基线 `MaxMstTrans=10 ⇒ 有效上限 15`——见 §5.4.1、BUG-0016/REV-007），并各带一个记录当前绑定目标 master 端口的寄存器；该同一组计数器/寄存器机制同时是 §5.2 保序 stall 的底层实现（换目标落 §5.2，封顶落 §5.4.1，二者为同一底层机制的两面）**（分桶口径，纠正此前"每 slave 端口一个扁平上限"表述——BUG-0010 裁决，REV-005 §3：依据 axi_demux.md §Ordering and Stalls→Implementation L70-74 + axi_pkg L510"See axi_demux for details"指针；基线 `AxiIdUsedSlvPorts=3<AxiIdWidthSlvPorts=5` 下扁平读法即被机制违反）** |
| `MaxSlvTrans` | `int unsigned` | 经 `axi_xbar.sv` L141 映射到 `axi_mux` 的 `MaxWTrans`——AW→W 之间保存 ID 高位的 **FIFO 深度**（mux.md L29），**非**每 master 端口每 ID 在飞事务数上限；mux 侧**无**按 ID 分桶的在飞计数机制，故不构成每 ID 在飞可断言上界（每 ID 在飞由 §5.4.1 上游 demux 每桶有效上限主导、可超本值）**（撤销此前"每 ID ≤ MaxSlvTrans"表述——BUG-0016 裁决，REV-007 §5(2)：来源 RTL——上游文档 xbar.md L47 "per ID in flight" 与实现不符；复核 BUG-0011）** |
| `FallThrough` | `bit` | AW 通道的路由决策直通（fall through）到 W 通道：=1 时允许 W beat 与对应 AW beat 同拍被接受，代价是 W 通道组合路径叠加 AW 逻辑；=0 无直通 |
| `LatencyMode` | `bit [9:0]`（doc 记 `enum logic [9:0]`） | 各端口各通道的 spill register 配置，详见 §7；`xbar_latency_e` 提供常用配置 |
| `PipelineStages` | `int unsigned` | 内部连线交叉（line cross）上例化的 `axi_multicut` 级数；多级会显著增加 FF 数（axi_pkg L503-505 注释）。**延迟不敏感插桩（BUG-0004 裁决，REV-001 §5）**：在 demux–mux 间 line-cross 上插入 `PipelineStages` 级 `axi_multicut`，增加流水延迟但**不改变功能响应、不损吞吐**（与 §7.1.2 spill register 同类）；**精确每通路（端到端）周期数许可来源未定义，详见 §7.4** **（来源：RTL——上游文档未载：xbar.md §Configuration 表无此字段）** |
| `AxiIdWidthSlvPorts` | `int unsigned` | slave 端口 AXI ID 宽度；master 端口 ID 宽度由此自动导出（§5） |
| `AxiIdUsedSlvPorts` | `int unsigned` | 判定 ID 唯一性时实际比较的低位位数（§5）；合法域：≤ `AxiIdWidthSlvPorts` |
| `UniqueIds` | `bit` | 环境保证在飞事务 ID 唯一时可置 1 以简化硬件，语义与前置条件见 §5.3 |
| `AxiAddrWidth` | `int unsigned` | AXI 地址宽度 |
| `AxiDataWidth` | `int unsigned` | AXI 数据宽度 |
| `NoAddrRules` | `int unsigned` | 地址表 rule 条数；合法域：**全表 ≥1 条**（BUG-0005 裁决，REV-001 §5：采信主文档 xbar.md §Address Map"至少一条"口径；axi_pkg L518-520 注释"每 master 端口……应至少一条"中的 "should" 为**非规范性指引**，主文档优先于源码注释，故无"每 master 端口至少一条"硬性要求）。**无任何 rule 指向的 master 端口为合法配置**（不可达，或仅经 default master port 可达），见 §3.1 |

### 2.2 模块参数（xbar.sv 声明 L18-65）

| 参数 | 默认值 | 语义 |
| --- | --- | --- |
| `Cfg` | `'0` | `axi_pkg::xbar_cfg_t` 配置结构体（§2.1）**（默认值来源：RTL——上游文档未载）** |
| `ATOPs` | `1'b1` | 原子操作（ATOP）支持使能，语义见 §6 **（来源：RTL——上游文档未载：xbar.md 未列此参数）** |
| `Connectivity` | `'1` | `bit [Cfg.NoSlvPorts-1:0][Cfg.NoMstPorts-1:0]` 连通矩阵，语义见 §8 **（来源：RTL——上游文档未载）** |
| `slv_aw_chan_t` … `mst_r_chan_t` | `logic` | 五通道 struct 类型（slave/master 侧各一套，W 通道共用一个 `w_chan_t`）；须用 `axi/typedef.svh` 的 `AXI_TYPEDEF` 宏按 `Cfg` 一致绑定（xbar.md §Configuration 末段） |
| `slv_req_t/slv_resp_t/mst_req_t/mst_resp_t` | `logic` | slave/master 端口的 req/resp struct 类型，绑定要求同上 |
| `rule_t` | `axi_pkg::xbar_rule_64_t` | 地址译码 rule 类型；必须与 `Cfg.AxiAddrWidth` 同地址宽度；须含字段 `{int unsigned idx; axi_addr_t start_addr; axi_addr_t end_addr;}`（xbar.sv 声明 L53-62 注释；xbar.md §Configuration 末段）**（默认值取 64 位规则：来源 RTL——上游文档未载）** |
| `MstPortsIdxWidth`（localparam） | — | `= (Cfg.NoMstPorts == 1) ? 1 : $clog2(Cfg.NoMstPorts)`，即 `default_mst_port_i` 每 slave 端口的索引位宽 **（公式来源：RTL——上游文档未载）** |

预定义 rule 类型（axi_pkg L524-536）：`xbar_rule_64_t`/`xbar_rule_32_t` =
`{int unsigned idx; logic [63:0]/[31:0] start_addr; …end_addr;}`
**（字段级定义来源：RTL——xbar.md 仅述"axi_pkg 含 64/32 位地址定义"，未列字段）**。

### 2.3 端口

依据：xbar.md §Ports 表 + xbar.sv 声明 L66-91（方向/位宽取自声明段）。

| 端口 | 方向 | 语义 |
| --- | --- | --- |
| `clk_i` | in | 时钟，上升沿有效；除 `rst_ni` 外所有信号与其同步 |
| `rst_ni` | in | 复位，异步、低有效 |
| `test_i` | in | 测试模式使能，高有效（功能验证恒 0） |
| `slv_ports_req_i` / `slv_ports_resp_o` | in/out | `slv_req_t/slv_resp_t [Cfg.NoSlvPorts-1:0]` slave 端口阵列；数组下标 = slave 端口索引，该索引会被前缀进 master 端口侧的事务 ID（§5） |
| `mst_ports_req_o` / `mst_ports_resp_i` | out/in | `mst_req_t/mst_resp_t [Cfg.NoMstPorts-1:0]` master 端口阵列；数组下标 = master 端口索引（= 地址 rule 的 `idx` 目标） |
| `addr_map_i` | in | `rule_t [Cfg.NoAddrRules-1:0]` 全局地址表，全模块共享（§3） |
| `en_default_mst_port_i` | in | `logic [Cfg.NoSlvPorts-1:0]`，每 slave 端口一位：该 slave 端口的 default master port 使能（§3.3） |
| `default_mst_port_i` | in | `logic [Cfg.NoSlvPorts-1:0][MstPortsIdxWidth-1:0]`，每 slave 端口一个 master 端口索引：使能时未匹配事务发往该 master 端口；不用时接 `'0`（xbar.sv 声明 L87-89 注释） |

## 3. 地址译码与路由

依据：xbar.md §Address Map（除注明外）。

### 3.1 地址表结构

1. 全部 slave 端口共享**一张**地址表（xbar.sv 声明 L81-83 注释同述"map is
   global for the whole module"）。
2. 表含任意条 rule，但**全表至少一条**；每条 rule 把一个地址区间映射到一个
   master 端口（`idx`）；多条 rule 可以映射到同一 master 端口。
   **无任何 rule 指向的 master 端口为合法配置**（BUG-0005 裁决，REV-001 §5：
   无"每 master 端口至少一条 rule"的硬性要求——xbar.md 的 default master port
   与 decode-error 机制正为覆盖未匹配地址；axi_pkg 的 "should" 为软性建议）；
   故 M3/M4 含不可达 master 端口的拓扑（如 1×N 单 rule、稀疏 map）合法。
3. 两条 rule 的地址区间**允许重叠**：重叠时，位于地址表**更高（更显著）位置**
   的 rule 胜出。

### 3.2 匹配语义

1. 区间含起址、**不含**终址：地址 `addr` 匹配某 rule 当且仅当
   `addr >= start_addr && addr < end_addr`。
2. 约束：`start_addr <= end_addr`。

### 3.3 default master port

1. 每个 slave 端口可独立配置一个 default master port
   （`en_default_mst_port_i` 位使能 + `default_mst_port_i` 给索引）。
2. 使能时：该 slave 端口上**不匹配任何 rule** 的地址被路由到 default master
   port，而不是 decode error slave（§4）。

### 3.4 运行时可变性

1. 地址表是输入信号，可在运行时定义与更改；但**任一 slave 端口的 AW 或 AR
   通道 valid 期间不得更改**。
2. default master port（使能位与索引）同样运行时可变，且受与地址表相同的
   更改限制。

## 4. 错误处理（decode error）

依据：xbar.md §Decode Errors and Default Slave Port。

1. 每个 slave 端口有**各自的**内部 decode error slave（`axi_err_slv`）。
2. 事务地址不匹配任何 rule 且该 slave 端口未使能 default master port 时，
   事务被路由到本端口的 decode error slave。
3. decode error slave 吞下（absorb）整个事务，并以 decode error 应答
   （响应码 `axi_pkg::RESP_DECERR`，axi_pkg L518-520 注释同述），且响应
   **beat 数正确**（xbar.md "proper number of beats" 涵盖读/写两路，C5
   补写路措辞，REV-001 §3.4）：**读**事务按请求 burst 长度出齐 `AxLEN+1` 个
   R beats（末拍 `RLAST=1`）；**写**事务在收齐整个 W burst 后返回**单拍 B**
   （DECERR）。
4. 读响应每个 beat 的数据为 `32'hBADCAB1E`，按数据宽度零扩展或截断。
5. 响应 ID/握手遵循 AXI4 协议一般规则（本模块声明实现完整 AXI4，xbar.md
   §开篇；协议本身为基线，不在此复述）。
6. decode error slave 的响应与同一 slave 端口其它事务之间的次序关系见
   §5.2.6（BUG-0025 裁决，REV-011）。
7. **ATOP × 译码未命中的应答形态，许可来源未定义**：一笔 `aw.atop != '0`
   且**要求读响应**的原子操作（atomic load），其地址不匹配任何 rule 且该
   slave 端口未使能 default master port 时，被路由到本端口的 decode error
   slave（§4.2）；此时 err_slv 是否也须为该 AW 产出一串 R beat（拍数 /
   数据 / 响应码 DECERR）——**许可来源未定义**（xbar.md §Decode Errors and
   Default Slave Port 全段无 atop/atomic；demux.md/mux.md 对 err_slv 无记载；
   §4.3 只按读/写二分对写事务给**单拍 B**、§6.3 又要求原子读 **B 与 R 两通道
   都应答**，两读互斥；禁读实现体定义之）。**环境约束（BUG-0032 裁决，
   REV-012 §Item 1）**：M3 全部场景**不向译码未命中地址发起任何 ATOP**
   （送往未命中地址的 AW 恒 `aw.atop ≡ '0`），使上述未定义情形**构造性
   不可触发**。据此，decode-error 维度**不整体降级**，在"未命中地址上
   `aw.atop ≡ '0`"的合法子集上正常写 checker。"若强行违反本约束触发该组合时
   err_slv 如何应答"仍为许可来源未定义，作为**上游确认项**另行追踪，
   **不阻塞** M3；未取 DUT_BUG（无任何波形/证据显示行为违规）。

## 5. ID 与保序

### 5.1 ID 前缀机制

1. master 端口 ID 宽度 **必须** 为
   `AxiIdWidthSlvPorts + $clog2(NoSlvPorts)`（xbar.md §Design Overview）。
2. 事务从 slave 端口 `i` 发往任一 master 端口时，`i` 被前缀（prepend）到事务
   ID 的高位（xbar.md §Ports 表）；内部 multiplexer 用 ID 的高
   `$clog2(NoSlvPorts)` 位把响应路由回来源 slave 端口（mux.md：高位不符将把
   响应送错来源，故设计上以端口索引作前缀保证唯一）。
3. 由此，master 端口上可观测的事务 ID 满足：`id[高 $clog2(NoSlvPorts) 位] =
   来源 slave 端口索引`，低 `AxiIdWidthSlvPorts` 位 = 原始 slave 侧 ID。
4. ID 前缀使不同 slave 端口在 master 端口侧拥有互不相交的 ID 空间
   （mux.md：解耦不同 master 模块的事务、允许 slave 模块交织不同 ID 的响应）。

### 5.2 同 ID 保序与 stall

依据：xbar.md §Ordering and Stalls。

1. 同一 slave 端口收到**两个同 ID、同方向**（同读或同写）、但目标为**不同
   master 端口**的事务时，第二个事务在第一个完成前**不被转发到其目标
   master 端口**；期间核心判决逻辑 stall 该方向的 AW（写）或 AR（读）。其
   **外部可锁定后果**是响应保序：第二笔的响应（B/rlast）不早于第一笔的
   响应返回（§5.2.3）。
   **接受边界即时性说明（BUG-0013 裁决，REV-006 §2.2/§3）**：基线
   `LatencyMode=CUT_ALL_AX`（§7.2）在核心判决逻辑**之前**启用
   `SpillAw`/`SpillAr` 弹性缓冲（demux.md §Configuration："one spill
   register ... before the demultiplexer"；§Pipelining：每通道加一拍、
   不损吞吐）。因此第二笔在外部 slave 端口的 **AW/AR 握手接受时刻**可早于
   核心判决逻辑比对第一笔——"接受握手被即时 stall"**不是可锁定的外部行为**，
   属 §7.4 延迟不敏感插桩的时序表现（窗口深度随启用的 `LatencyMode` 位变化、
   许可来源未给固定拍数）。故 checker/SVA 的保序 stall 判决门**必须锚定
   完成序**（§5.2.3：同一低位 ID 桶、同方向、不同目标的两笔若均被接受，
   其 B/rlast 完成顺序须与接受顺序一致），**不得断言第二笔的接受握手迟于
   第一笔的完成**。
2. "同 ID" 的判定只比较 ID 的低 `AxiIdUsedSlvPorts` 位：取满
   `AxiIdWidthSlvPorts` 可消除假冲突；取小则以更多假冲突（假 stall）换取
   面积/延迟收益。假冲突只影响性能，不影响正确性。
3. 依据（协议动机）：AXI 要求同 ID 同方向事务的响应保序；本 crossbar **无
   reorder buffer**，故以 stall 方式防止跨 master 端口乱序返回。
4. 同 ID、同方向、目标**相同** master 端口的事务不受此 stall 约束（保序由
   下游及 AXI 协议本身维持）**（派生条款：由 §5.2.1"目标为不同 master 端口"
   约束的逻辑逆否推导得出，非直接 RTL/文档来源——C5，REV-001 §3.4）**。
5. **跨方向旁路（派生条款，BUG-0012 裁决，REV-005 §3；详见 §6.5）**：原子读
   （ATOP）经 §6.5 所述机制可能引发一次由**写方向**事件（ATOP 的 AW）触发的
   **读方向** stall——不落在本节 1-4 条"仅同方向配对"的字面框架内，属正常
   设计行为（非退化）。
6. **译码未命中事务的保序地位（BUG-0025 裁决，REV-011 §1）**：
   1. 走 §3.3 default master port 的事务，其目标是一个**真实 master 端口**
      （xbar.md §Decode Errors L35："routed to the default master port
      instead of the decode error slave"），本节 1-4 条**原样适用**，与命中
      rule 的事务无区别。
   2. 走 §4 decode error slave 的事务：`axi_err_slv` 是每 slave 端口的
      **内部**模块（§4.1；xbar.md L33 "its own internal decode error slave
      module"），**不是** master 端口，本节第 1 条的"目标为不同 master 端口"
      不涵盖它。据此分两层：
      - a. **完整 ID 维度（可断言）**：同一 slave 端口上**完整 ID 相同**、
        同方向的事务，其 B/rlast 完成序须与接受序一致——**无论**该事务被
        路由到 master 端口、default master port 还是 decode error slave。
        依据：§1 + §4.5（本模块实现完整 AXI4，err_slv 响应遵循 AXI4 一般
        规则）+ §5.2.3（AXI 要求同 ID 同方向事务响应保序；xbar.md L86
        同述）。checker **必须**把译码未命中事务纳入这一维度的判决。
      - b. **低位 ID 桶维度（不可断言）**：仅低 `AxiIdUsedSlvPorts` 位
        相同、**完整 ID 不同**、且其中一笔走 decode error slave 时，二者
        完成序之间的关系**许可来源未定义**（xbar.md §Ordering and Stalls
        只约束"不同 master 端口"，§Decode Errors 未涉次序；demux.md/mux.md
        对 err_slv 无记载）。**不得**据此写断言（无来源，且会在 M3 错误
        路径场景假红）；须以**非判决 cover** 留痕，并列为**上游确认项**，
        **不阻塞**里程碑（同 §7.4.4 / §8.4 处置）。
   3. checker 对 2.b 的排除必须**显式并引本条**。以"未登记 ⇒ 目标/序号读
      到默认值 ⇒ 比较恰好为假"的方式实现该排除**不成立**：同一完整 ID 若
      曾登记过，陈旧的目标/序号会继续参与比较，既漏检也可能产生无来源
      假红（BUG-0025 实现现状，REV-011 §3.3）。

### 5.3 UniqueIds

依据：xbar.md §Configuration 表（转引 demux.md §Ordering and Stalls）。

1. `UniqueIds = 1'b1` 的**前置条件**（demux.md）——以下至少一条恒成立：
   - 每个事务的 ID 在同方向所有在飞事务中唯一；
   - 或对任意 ID：持该 ID 的事务与所有同 ID 同方向在飞事务目标同一
     master 端口；
   - 或两者皆是。
2. 满足前置条件时置 1 可简化硬件（demux.md：ID 追踪复杂度由 `O(2^I)` 降为
   `O(I)`，`I` 为 ID 位宽）。
3. **前置条件不满足时置 1 → 行为未定义（undefined behavior）**（demux.md）。
   验证侧：UniqueIds=1 配置下激励必须构造性满足前置条件。

### 5.4 事务数上限

1. 每 slave 端口按（低 `AxiIdUsedSlvPorts` 位 ID 桶 × 方向）独立计数，每桶
   in-flight 事务数的**有效上限 = demux 每桶计数器满量程 =
   `2^idx_width(MaxMstTrans) − 1 = 2^⌈log₂(MaxMstTrans)⌉ − 1`**（`IdCounterWidth
   = cf_math_pkg::idx_width(MaxMstTrans)` 位、"full" 判据为计数器全一
   `&in_flight`、**无 `== MaxMstTrans` 比较**）；基线 `MaxMstTrans=10 ⇒ 有效
   上限 15`（非字面 10）。`MaxMstTrans` 是**计数器定宽参数**（保证计数器至少
   能表示该值），**非精确在飞上限**；仅当 `MaxMstTrans = 2ᵏ−1` 时有效上限恰
   等于 `MaxMstTrans`（2 的幂取值下有效上限**低于** `MaxMstTrans`，如
   `MaxTrans=8 ⇒ 7`）**（来源：RTL——上游文档 demux.md L72 "up to and
   including MaxTrans" 与实现不符；有效上限公式为 BUG-0016 裁决，
   REV-007 §5(1)）**
   **（分桶口径，BUG-0010 裁决，
   REV-005 §3：与 §5.2 保序 stall 共用同一组计数器/目标绑定寄存器——见
   axi_demux.md §Ordering and Stalls→Implementation L70-74；纠正此前"每
   slave 端口一个扁平上限"表述）**。
2. **`MaxSlvTrans` 不构成每 ID 在飞可断言上界（撤销此前"每 ID ≤
   MaxSlvTrans"表述）**：`MaxSlvTrans` 经 `axi_xbar.sv` L141 映射到 `axi_mux`
   的 `MaxWTrans`——AW→W 之间保存 ID 高位的 **FIFO 深度**（mux.md L29），
   **非**每 ID 在飞事务上限；mux 侧**无**按 ID 分桶的在飞计数机制（复核
   BUG-0011）。故 master 端口每 ID 在飞数由**上游 demux 每桶有效上限
   （§5.4.1）主导，可超 `MaxSlvTrans`**（基线见证达 8>6）。**此条同时正式
   收回 REV-005 为 M2-TL02 解锁的"每端口×每 ID×每方向 ≤ MaxSlvTrans、
   绝不假红"可观测上界监视器**——其前提（mux 存在 per-ID 上界机制）不成立、
   会假红，**不得升格为 assert** **（来源：RTL——上游文档 xbar.md L47 "per
   ID in flight" 与实现不符；BUG-0016 裁决，REV-007 §5(2)）**。
3. 达到上限时对应端口不再接受新事务（由"至多 in flight"语义推导）：
   `MaxMstTrans` 侧机制明确——同桶计数达**有效上限（§5.4.1 满量程公式
   `2^⌈log₂MaxMstTrans⌉−1`，基线 15 非字面 10）**即拒收，目标绑定寄存器同 §5.2
   （demux.md L70-74 支撑）；该"拒收"的**外部边界即时性**同 §7.4.5 为延迟
   不敏感表现（`SpillAw`/`SpillAr` 在核心计数之前缓冲），判决须锚定延迟
   不敏感观测量、不得断言第 N+1 笔在外部边界某具体时点被拒（BUG-0013/
   REV-006）；**`MaxSlvTrans` 侧无 mux 端每 ID 在飞机制——该参数经
   `axi_xbar.sv` L141 实为 `axi_mux` 的 `MaxWTrans`（AW→W ID 高位 FIFO 深度、
   非在飞上限，§5.4.2）；此前"上游确认项/机制未定义"表述据此升级为"mux 侧
   在飞机制根本不存在"的已定结论（BUG-0016 裁决，REV-007 §5(2)(3)；复核
   BUG-0011）**。

### 5.5 W 通道次序（下层部件佐证）

1. W beats 按对应 AW 的次序路由：依赖 AXI 性质——W burst 必须按 AW 次序
   发出、不同 W burst 的 beats 不得交织（demux.md §Design Overview）。
2. master 端口上，来自不同 slave 端口的 AW/AR 请求经 round-robin 仲裁合并；
   W burst 与其 AW 保持同序、burst 内不与他源交织（mux.md）。
3. slave 端口上，来自不同 master 端口的 B/R 响应经 round-robin 仲裁合并
   （demux.md §Design Overview）。
4. **checker 期望值告诫（C4，REV-001 §3.2）**：§5.5.2/§5.5.3 的
   "round-robin 仲裁合并" 仅为下层部件佐证；round-robin 的**具体仲裁发生序**
   是实现细节（其优先级推进方式在 xbar.md §Design Rationale 中即作为死锁分析
   对象出现），**非可锁定的外部行为**。checker 的期望值只准从以下**性质**推导：
   同 ID 同向保序（§5.2）、W-burst 随其 AW 保持同序且 burst 内不与他源交织
   （§5.5.1）、无饿死（每个持续 valid 的请求终将被授予）；**不得断言任何一条
   特定的 round-robin 发生序、也不得断言某一拍的具体被授权端口**。

## 6. ATOP 支持

1. `axi_xbar` 实现完整 AXI4 加 **AXI5 原子操作（ATOPs）**（xbar.md §开篇；
   xbar.sv 头注释）。ATOP 事务由 `aw.atop != '0` 的 AW 发起（demux.md
   §Atomic Transactions）。
2. `ATOPs` 参数（默认 `1'b1`）控制原子操作支持的使能
   **（来源：RTL——上游文档未载）**；`ATOPs=1'b0` 时收到 `aw.atop != '0` 的
   ATOP 事务的行为在许可来源中**未定义**（xbar.md 未列 ATOPs 参数；禁读实现
   体定义之）。**环境约束（BUG-0003 裁决，REV-001 §5）**：`ATOPs=1'b0` 时
   环境保证**不发起任何 ATOP 事务**（所有 AW 恒 `aw.atop ≡ '0`），违反即未
   定义；M4 配置矩阵的 `ATOPs{0}` 维度在此"无-ATOP 激励"约束下验证（等价于
   验证 ATOP 硬件被裁剪后的普通读写数据通路），该约束使未定义情形不可达、
   不阻塞 M4。
3. 原子读（atomic load，ATOP 带读响应）要求 **B 与 R 两个通道都返回响应**
   （demux.md §Atomic Transactions）。**本条与 §4 decode-error 应答形态的
   交集——ATOP 落在译码未命中地址——许可来源未定义，见 §4 clause 7 的环境
   约束（BUG-0032 裁决，REV-012 §Item 1）。**
4. 环境约束（AXI5 协议要求，mux.md/demux.md 同述）：master 必须保证 ATOP
   事务的 ID 与当前**所有**（读+写）在飞事务的 ID 不同；ATOP 亦因此在读写
   通道间引入 AXI4 中不存在的依赖。验证侧激励必须满足此约束。
5. **原子读对读方向的跨方向假冲突 stall（派生条款，BUG-0012 裁决，REV-005
   §3）**：原子读（atomic load）从不发出 AR，故 AR 方向的 §5.2/§5.4 计数/
   比较机制若对其读响应（R beat）一无所知就会下溢；为防止这一下溢，AW 发起
   要求读响应的原子操作时，其 ID 被同时注入 AR 方向的该计数/比较机制（demux.md
   §Atomic Transactions→Implementation L83-87）。该机制仍只比较 ID 的低
   `AxiIdUsedSlvPorts` 位，故一笔原子读可能使同一 slave 端口上另一笔低位
   ID 相同、目标不同 master 端口的**普通读**依 §5.2.1 被 stall——这是一次
   由 ATOP 写事件引发的读方向 stall（交叉引用 §5.2.5），超出 §5.2.1 字面
   "仅同方向配对"框架，但属正常设计行为，非退化。验证侧：该交互只影响是否
   被 stall（性能/时序），不影响功能正确性。

## 7. Latency 模式（`LatencyMode` / `xbar_latency_e`）

### 7.1 spill register 位置语义

依据：xbar.md §Pipelining and Latency。

1. `LatencyMode` 的每一位控制一处 spill register：
   - **master 端口侧（mux）**：每个 master 端口的每条通道（AW/W/B/AR/R）
     **之后**；
   - **slave 端口侧（demux）**：每个 slave 端口的每条通道**之前**。
2. spill register 切断该通道的全部组合路径（payload 与握手），每通道增加
   一拍延迟，**不损失吞吐**（demux.md §Pipelining and Latency）。
3. crossbar **内部**（demux 与 mux 之间）不插流水寄存器：上游文档明确此为
   避免 W 通道循环等待死锁的设计决策（xbar.md §Design Rationale for No
   Pipelining Inside Crossbar）。因此除 `PipelineStages`（§2.1）外，内部
   交叉不引入额外延迟档位。

### 7.2 位图与预置档位

`LatencyMode` 为 10 位掩码，位分配（axi_pkg L451-469）
**（位分配与枚举编码来源：RTL——xbar.md 仅列档位名，未载位图）**：

| bit | 9 | 8 | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 含义 | DemuxAw | DemuxW | DemuxB | DemuxAr | DemuxR | MuxAw | MuxW | MuxB | MuxAr | MuxR |

`xbar_latency_e` 预置档位（axi_pkg L471-479；仅为常用示例，任意 10 位掩码
均合法——axi_pkg L499-501 注释"Example configurations are provided"）：

| 档位 | 编码 | 含义 |
| --- | --- | --- |
| `NO_LATENCY` | `10'b000_00_000_00` | 全组合（配 `FallThrough=1` 可全通路零延迟，xbar.md） |
| `CUT_SLV_AX` | `DemuxAw \| DemuxAr` | 仅切 slave 端口侧 AW/AR **（档位名来源：RTL——上游文档未载）** |
| `CUT_MST_AX` | `MuxAw \| MuxAr` | 仅切 master 端口侧 AW/AR **（档位名来源：RTL——上游文档未载）** |
| `CUT_ALL_AX` | `DemuxAw \| DemuxAr \| MuxAw \| MuxAr` | 两侧 AW/AR 均切：AW/AR 通道延迟 2 拍；**推荐配置**（配 `FallThrough=0`，xbar.md） |
| `CUT_SLV_PORTS` | 全部 Demux 位 | slave 端口侧五通道全切 |
| `CUT_MST_PORTS` | 全部 Mux 位 | master 端口侧五通道全切 |
| `CUT_ALL_PORTS` | `10'b111_11_111_11` | 两侧五通道全切 |

### 7.3 使用约束

依据：xbar.md §Pipelining and Latency。

1. 推荐 `CUT_ALL_AX` + `FallThrough=0`（AW/AR 组合逻辑最重；FallThrough=0
   防止 AW 逻辑延长 W 组合路径）。
2. 两个 crossbar 双向互连（各自一个 master 端口接对方一个 slave 端口）时，
   **两者**的 `LatencyMode` 都必须取 `CUT_SLV_PORTS`、`CUT_MST_PORTS`、
   `CUT_ALL_PORTS` 之一（两者不必相同），否则未切通道上会形成时序环。
   本项目单实例验证，此条仅作集成约束记录，不进配置矩阵。

### 7.4 延迟不敏感原则与周期数未定义（BUG-0004 裁决，REV-001 §5）

1. AXI 为**延迟不敏感**（latency-insensitive）握手协议：事务的功能正确性由
   valid/ready 握手与 payload 决定，不依赖固定拍数。
2. `LatencyMode` 的 spill register（§7.1）与 `PipelineStages` 的
   `axi_multicut`（§2.1）均为**延迟不敏感插桩**：改变通路延迟拍数，但**不改变
   功能响应、不损吞吐**。
3. **精确每通路（端到端）周期数在许可来源中未定义**：xbar.md §Pipelining 仅述
   "每 spill 加一拍、不损吞吐"，未给端到端周期数；axi_pkg 对 `PipelineStages`
   亦无外部周期语义。因此**任何 latency checker 不得断言固定周期数**；功能
   checker（数据完整性 / 响应正确 / 保序）必须**延迟不敏感**——按 valid/ready
   握手跟踪事务，不假设固定拍数。
4. 基线 `PipelineStages=1`、`LatencyMode=CUT_ALL_AX`（§0）因此**不影响** M1
   smoke 功能 checker 的落地。若将来确需 cycle-accurate 时序核查，须另行**上游
   确认**后再补 spec（上游确认项，不阻塞里程碑）。
5. **接受/拒收边界的即时性是延迟不敏感表现（BUG-0013 裁决，REV-006）**：
   slave 端口侧 spill register（`SpillAw`/`SpillAr`，基线 `CUT_ALL_AX`
   启用）位于核心判决逻辑（demux 计数/比较，demux.md L70-74）**之前**
   （demux.md §Configuration L31、`axi_demux.sv` L89-209 结构），会在核心
   判决之前对 AW/AR 提供弹性缓冲。故**外部 slave 端口 AW/AR 握手的接受
   （或拒收）时刻本身**——无论是 §5.2 的保序 stall、还是 §5.4.3 的"达到
   上限即拒收"——均为延迟不敏感时序表现，**不得作为 checker/SVA 的判决
   锚点**。判决须落在延迟不敏感的可观测量上：保序 stall 落**完成序**
   （§5.2.3）；事务上限落"**限内不假 stall**（弹性缓冲只会使接受更早、
   不会更晚，故限内的边界 stall 仍是真失败）**＋上限最终被守**（此处"上限"
   特指 §5.4.1 的**有效上限 `2^⌈log₂MaxMstTrans⌉−1`**（基线 15），**非**
   `MaxMstTrans`/`MaxSlvTrans` 字面值；容忍弹性缓冲窗口深度，不断言第 N+1
   笔在某具体时点被拒于外部边界）"。**越过 `MaxMstTrans` 字面值不构成本条的
   接受边界 ±spill 效应，而是计数器位宽取整效应（BUG-0016/REV-007 §5(3)）**。
   窗口深度随 `LatencyMode` 变化、许可来源未给固定拍数（§7.4.3）。

## 8. Connectivity 稀疏连接矩阵语义

**（本节整体来源：RTL——上游文档未载；xbar.md 无 Connectivity 参数的任何
描述，以下仅为 xbar.sv 声明 L25-26 可支持的最小语义）**

1. `Connectivity` 为 `bit [Cfg.NoSlvPorts-1:0][Cfg.NoMstPorts-1:0]` 连通
   矩阵，默认 `'1`；按声明注释与默认值推断：`Connectivity[i][j]=1` 表示
   slave 端口 `i` 与 master 端口 `j` 连通，默认全连接。
2. `Connectivity[i][j]=0`（稀疏连接）时，"从 slave 端口 `i` 发出、地址译码
   命中**非连通** master 端口 `j`" 的事务如何应答，**许可来源未定义**
   （xbar.md 无 Connectivity 任何记载；禁读实现体定义之）。
3. **环境约束（BUG-0002 裁决，REV-001 §5）**：M3/M4 稀疏 `Connectivity`
   配置下，地址表（`addr_map_i`）与 default master port 须构造为**不把任一
   slave 端口 `i` 的任何地址译码到其非连通 master 端口 `j`（`Connectivity[i][j]=0`）**，
   使上述未定义情形**构造性不可触发**。据此，稀疏 `Connectivity` 维度**不整体
   降级**，在"地址表与连通矩阵一致"的合法子集上正常写 checker。
4. "若强行违反 §8.3 约束触发该情形时 DUT 如何应答"仍为许可来源未定义，作为
   **上游确认项**另行追踪，**不阻塞** M3/M4；未取 DUT_BUG（无任何波形/证据
   显示行为违规）。

## Change record

| # | 日期 | 版本 | 章节 | 摘要 | 依据 |
| --- | --- | --- | --- | --- | --- |
| 1 | 2026-07-27 | 0.0.0 | 全文 | v0 初稿（草稿 spec-draft-v0.md，待 rev 评审后应用至 spec.md 并重 pin） | vendor/axi/doc/{axi_xbar,axi_demux,axi_mux}.md、src/axi_pkg.sv 定义段、src/axi_xbar.sv 声明段 @ v0.39.9（SHA a256a3b8） |
| 2 | 2026-07-27 | 0.0.1 | §0(item 2/4/5)、§2.1、§3.1、§4、§5.2、§5.5、§6、§7.4、§8 | v0 修订（依据 REV-001）：C1 补齐 §0 基线全 13 Cfg 字段 + ATOPs/Connectivity 钉定值；C2 修正 §0 item 4/5 子模块层次（axi_xbar_unmuxed/addr_decode 列为强制内部核心子模块，移出范围外清单）；C3 应用 BUG-0002~0005 四条裁决（§8 构造性环境约束 / §6 无-ATOP 环境约束 / §2.1·§7.4 延迟不敏感+周期数未定义 / §2.1·§3.1 采信 xbar.md NoAddrRules 口径）；C4 §5.5 加固 round-robin 措辞；C5 §4 补写路 B(DECERR)、§5.2.4 标注派生条款 | REV-001（doc/review/REV-001.md）；基线数值来源：上游 tb 默认（REV-001 核对） |
| 3 | 2026-07-27 | 0.2.0 | §2.1、§5.2、§5.4、§6 | M2 蒸馏三条新发现 SPEC_ISSUE 裁决应用（依据 REV-005，仅落地 REV-005 §3 逐条列明的"orch 应用范围"，不外溢）：BUG-0010 `MaxMstTrans` 由扁平口径改为按（约简 ID 桶×方向）分桶计数口径（§2.1、§5.4.1），并标注其与 §5.2 保序 stall 共用同一底层计数器/目标绑定寄存器机制；BUG-0011 保留 §5.4.2 可观测上界 + "per ID"采 xbar.md 口径澄清，执行机制列上游确认项、不阻塞里程碑（§5.4.3）——§2.1 `MaxSlvTrans` 字段行未改动（REV-005 该条裁决未授权此行）；BUG-0012 补 ATOP 原子读注入 AR 计数器可致读方向跨方向假冲突 stall 的派生条款（§6.5），并在 §5.2 加交叉引用（§5.2.5） | REV-005（doc/review/REV-005.md）；来源：vendor/axi/doc/axi_demux.md §Ordering and Stalls→Implementation（L70-74）、§Atomic Transactions→Implementation（L83-87）、axi_xbar.md L46/L47、axi_pkg.sv L489-494/L510、axi_mux.md（全篇核验，无对应按 ID 分桶计数机制段落）@ v0.39.9（SHA a256a3b8） |
| 4 | 2026-07-28 | 0.2.0 | §5.2、§7.4、§5.4 | M2-OR01 仿真新发现 BUG-0013 裁决应用（依据 REV-006，仅落地 REV-006 §3 逐条列明的"orch 应用范围"）：收窄 §5.2.1"接受边界"字面表述为"不早于完成、判决锚完成序（§5.2.3）"，消除与基线 `CUT_ALL_AX` spill register 弹性缓冲的假红；§7.4 新增第 5 条，把"接受/拒收边界即时性"通用归入延迟不敏感表现（同时覆盖 §5.2 stall 与 §5.4.3 拒收，预防 M2-TL01 独立撞见同类交互）；§5.4.3 MaxMstTrans 侧句尾加交叉指针至 §7.4.5。§5.2.3 正文未改动（现文已充分表述功能目的，surgical） | REV-006（doc/review/REV-006.md）；来源：vendor/axi/doc/axi_xbar.md §Ordering and Stalls（L84/L86）、vendor/axi/doc/axi_demux.md §Configuration（L31）/§Pipelining and Latency（L37）/§Implementation（L70-74）、vendor/axi/src/axi_demux.sv（L89-116/L189-209 spill-register 结构） @ v0.39.9（SHA a256a3b8） |
| 5 | 2026-07-28 | 0.2.0 | §2.1、§5.4、§7.4 | M2-TL01/TL02 仿真新发现 BUG-0016 裁决应用（依据 REV-007，taxonomy 终判 SPEC_ISSUE，改判 DUT_BUG——DUT 未产生错误输出、`MaxTrans` 为 `idx_width` 定宽提示而非精确上限，许可来源三方矛盾；仅落地 REV-007 §5 逐条列明的"orch 应用范围"，不外溢）：§5.4.1 把每桶在飞上限由字面 `≤MaxMstTrans` 改为**有效上限 `2^idx_width(MaxMstTrans)−1 = 2^⌈log₂MaxMstTrans⌉−1`**（基线 10⇒15；`MaxTrans` 从不进比较器、full 判据为 `&in_flight` 全一）；§5.4.2 **撤销**"每 ID ≤ MaxSlvTrans"可断言上界（`MaxSlvTrans`→`axi_mux.MaxWTrans` = AW→W ID 高位 FIFO 深度、mux 无 per-ID 在飞计数机制），并正式收回 REV-005 为 M2-TL02 解锁的"≤MaxSlvTrans 绝不假红"可观测上界监视器；§5.4.3 把 MaxMstTrans 侧拒收门改锚有效上限、MaxSlvTrans 侧由"上游确认项"升级为"mux 侧机制不存在"已定结论；§7.4.5 把"上限最终被守"绑定 §5.4.1 有效上限公式、明确越字面值为位宽取整效应非 spill；§2.1 `MaxMstTrans`/`MaxSlvTrans` 字段行同步收口。§5.2 保序机制与 BUG-0010 分桶口径措辞未动 | REV-007（doc/review/REV-007.md）；来源：vendor/axi/src/axi_demux_simple.sv（L69 `IdCounterWidth=idx_width(MaxTrans)`、L168/L322 full 门、L557/L615 `&in_flight` 判满、L460-508 无 MaxTrans 合法性检查）、vendor/common_cells/src/cf_math_pkg.sv（L57-58 `idx_width`）、vendor/common_cells/src/delta_counter.sv（`overflow_o` 语义）、vendor/axi/src/axi_xbar.sv（L141 `MaxWTrans←MaxSlvTrans`）、axi_xbar_unmuxed.sv（L175 `MaxTrans←MaxMstTrans`）、axi_mux.sv（L46/L319 `MaxWTrans` FIFO 深度）、vendor/axi/doc/{axi_xbar.md L46/L47,axi_demux.md L72,axi_mux.md L29}、axi_pkg.sv L489-494（四处散文互相矛盾）@ v0.39.9（SHA a256a3b8） |
| 6 | 2026-07-28 | 0.2.2 | §5.2、§4 | BUG-0025 SPEC_ISSUE 半边仲裁应用（依据 REV-011 §1.3，仅落地条款提案 P-REV011-1/P-REV011-2 原文，不外溢）：§5.2 新增第 6 条**译码未命中事务的保序地位**——(1) 走 §3.3 default master port 的事务目标是真实 master 端口，§5.2.1-4 原样适用；(2) 走 §4 decode error slave 的事务分两层，**完整 ID 维度可断言**（同一 slave 端口上完整 ID 相同、同方向事务的 B/rlast 完成序须与接受序一致，无论路由去向，checker 必须纳入判决）、**低位 ID 桶维度不可断言**（完整 ID 不同且其一走 err_slv 时次序许可来源未定义，不得写断言、以非判决 cover 留痕并列上游确认项、不阻塞里程碑）；(3) 该排除必须显式引本条，**不得**以"未登记⇒读默认值⇒比较恰好为假"实现（陈旧值会继续参与比较，既漏检也可产生无来源假红）。§4 新增第 6 条一行交叉指针至 §5.2.6。§5.2.1-5 与 §4.1-5 正文未改动（surgical） | REV-011（doc/review/REV-011.md §1）；来源：vendor/axi/doc/axi_xbar.md L33/L35（Decode Errors and Default Slave Port）、L84/L86（Ordering and Stalls）、§开篇（完整 AXI4+ATOP）；vendor/axi/doc/axi_demux.md L54-76、vendor/axi/doc/axi_mux.md（对 err_slv 无记载，作为"未定义"的否定性证据）；spec 内部 §1/§3.3/§4.1/§4.5/§5.2.1/§5.2.2/§5.2.3 @ v0.39.9（SHA a256a3b8）。**无 RTL 实现体来源**——REV-011 明确声明未读 axi_xbar.sv/axi_demux.sv 实现体，spec-from-RTL 红线未破 |
| 7 | 2026-07-29 | 0.3.9 | §4、§6 | BUG-0032 SPEC_ISSUE 终判应用（依据 REV-012 §Item 1 approve P-REV012-1，经 REV-013 spec-review 门禁 conditional pass 后按其订正文本逐字应用，不外溢）：§4 新增第 7 条——err_slv 对**要求读响应的 ATOP（atomic load）**落在译码未命中地址时的应答形态**许可来源未定义**（§4.3 写事务单拍 B 与 §6.3 原子读 B+R 两读互斥）；**环境约束（BUG-0032 裁决，REV-012 §Item 1）**：M3 全部场景不向译码未命中地址发起任何 ATOP，使该未定义情形构造性不可触发，decode-error 维度不整体降级、在合法子集上正常写 checker；违反约束时的应答仍列上游确认项、不阻塞 M3、未取 DUT_BUG。§6 clause 3 尾部加一行交叉引用指回 §4 clause 7。**REV-013 门禁订正**：提案原文两处 `M3/M4` 收窄为 `M3`——M4 覆盖率收敛若需触发该组合须重开仲裁，spec 现无 M4 config-matrix 承载该约束，写 M4 会构成 spec-vs-artifact 的 Retention 不一致；reopening 路径由本条第四部分 + BUG-0032 guard 承接，不因收窄受损。§4.1-6、§6.1-2/4-5 正文未改动（surgical） | REV-012（doc/review/REV-012.md §Item 1）+ REV-013（doc/review/REV-013.md，spec-review 门禁 + 逐字订正文本）；来源：vendor/axi/doc/axi_xbar.md §Decode Errors and Default Slave Port（全段无 atop/atomic，REV-012/REV-013 各自复核 grep 空集）、vendor/axi/doc/axi_demux.md §Atomic Transactions（L79-87，只涉路由/ID 计数器注入，不涉 err_slv）、vendor/axi/doc/axi_mux.md（对 err_slv 零命中）@ v0.39.9（SHA a256a3b8）。**无 RTL 实现体来源**——REV-012/REV-013 均未读 axi_xbar.sv/axi_demux.sv 实现体，spec-from-RTL 红线未破 |
