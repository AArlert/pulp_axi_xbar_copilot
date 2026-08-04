# M7 闭环 C：红线 2 渗漏抽查

> **红线 2**（CLAUDE.md）：checker/SVA 的期望值只准从 `doc/spec.md` 推导，
> 绝不来自被测 RTL。波形/覆盖率是观测事实，可以看，不得抄成期望值。

## 1. scoreboard 期望值推导路径审计

### 方法

逐条 `tb/scoreboard_refmodel.sv` 的 22 个 `uvm_error` 判决点，追溯每个期望值
的推导链到最终来源（spec 条款 / AMBA 标准常量 / TB 自身请求字段）。同步检查
`tb/xbar_types_pkg.sv` 中的共享函数 `decode_mst_port` 和 `predict_beat_data`。

### 结果：零渗漏

| 判决点 | 期望值 | 来源 | 合规 |
|---|---|---|---|
| SB_ROUTE | port/addr/len/size/burst/atop | decode_mst_port (spec §3.1/§3.2) + 自身请求字段 | ✅ |
| SB_WDATA | 每拍 data/strb | 自身请求字段 pass-through (spec §1) | ✅ |
| SB_WDATA_LEN | beat count | 自身请求字段 AxLEN+1 (spec §1) | ✅ |
| SB_RDATA | 每拍 data/resp | predict_beat_data (AMBA A3-51 beat_addr 公式, spec §1) | ✅ |
| SB_RBEATS | beat count | AxLEN+1 (spec §1) | ✅ |
| SB_BRESP | RESP_OKAY | axi_pkg AMBA 常量 (spec §1 implicit) | ✅ |
| SB_NOPEND | pending record 存在 | build_exp_id prefix 公式 (spec §5.1.1) | ✅ |
| SB_RESP_ROUTE | 响应回到发起端口 | prefix 高位解码 (spec §5.1.2/§5.1.3) | ✅ |
| SB_DANGLING | 请求必须最终送达 | spec §5.1.1/§3.1 | ✅ |
| SB_RESP_DANGLING | 响应必须最终返回 | spec §5.1.2/§5.1.3 | ✅ |
| SB_OR_REORDER | 完成序不反超 | accept_time 序列 (spec §5.2.1/§5.2.3) | ✅ |
| SB_OR_DANGLING | 保序记录必须完成 | spec §5.2.1/§5.2.3 | ✅ |
| SB_DECERR_ORDER | 同 full-ID 完成序=接受序 | err_order_q FIFO (spec §5.2.6 cl.2a) | ✅ |
| SB_DECERR_BRESP | RESP_DECERR | axi_pkg AMBA 常量 (spec §4.3) | ✅ |
| SB_DECERR_RBEATS | AxLEN+1 | spec §4.3 | ✅ |
| SB_DECERR_RDATA | ERR_RDATA=64'hCA11AB1EBADCAB1E | spec §4.4（经 BUG-0033/REV-014 从 RTL 正式升格入 spec）| ✅ |
| SB_WORDER | 完成序=AW 接受序 | accept_time 序列 (spec §5.5.1) | ✅ |
| SB_WORDER_DANGLING | 写 burst 必须完成 | spec §5.5.1 | ✅ |
| SB_ATOP_OVERLAP | ATOP ID 不重复 | spec §6.4 (env guard, TB_BUG) | ✅ |
| SB_ATOP_DANGLING | ATOP 对必须两半都返回 | spec §6.3/§6.7/§6.8 | ✅ |
| SB_ATOP_DECODE | ATOP 不发往未映射地址 | spec §4.7 / BUG-0032 (env guard) | ✅ |
| SB_UNIQUEIDS | 同 ID 同向同目标 | spec §5.3.1 (env guard) | ✅ |

### 关键共享函数

- **`decode_mst_port`**（xbar_types_pkg.sv:360-381）：实现 spec §3.2 cl.1
  区间匹配 + §3.1 cl.3 高位 rule 优先 + §3.3 default port 回落。未引用任何
  RTL 文件。
- **`predict_beat_data`**（xbar_types_pkg.sv:389-400）：委托
  `axi_pkg::beat_addr`（AMBA A3-51 标准拍地址公式）。TB 内部生成器，responder
  和 scoreboard 共用同一函数——单一真值源，非 RTL 观测值。
- **`ERR_RDATA` 常量**（scoreboard_refmodel.sv:184-185）：唯一一个来源于 RTL
  观测的期望值，但经 BUG-0033 登记 → REV-014 裁决 → spec §4.4 正式收录，
  checker 只读 spec.md，不读 RTL 文件。这是 CLAUDE.md 规定的合规路径
  （spec 有缺口 → 登记 SPEC_ISSUE → 补 spec → 再写 checker）。

### import/include 扫描

scoreboard_refmodel.sv 和 xbar_types_pkg.sv 均只引用：
- `axi_pkg::*`（AMBA 常量/类型定义，CLAUDE.md 许可的参数定义源）
- UVM 宏

**未引用任何 DUT 行为 RTL 文件**（无 `axi_xbar*.sv` / `axi_demux*.sv` /
`axi_mux*.sv` / `axi_err_slv*.sv` import）。

---

## 2. SVA 期望值审计

### import/include 扫描

6 个 SVA 模块（`tb/sva/*.sv`）均只引用 `xbar_types_pkg`、`axi_pkg`、`uvm_pkg`。
**未引用任何 DUT 行为 RTL 文件。**

### SVA 判决点（`uvm_error`）枚举

| SVA tag | 文件 | spec 锚点 | 期望值来源 |
|---|---|---|---|
| SVA_AW_STABLE | axi_chan_sva.sv:166 | §1 | AXI4 协议规则：valid 保持 + payload $stable |
| SVA_W_STABLE | axi_chan_sva.sv:170 | §1 | 同上 |
| SVA_B_STABLE | axi_chan_sva.sv:174 | §1 | 同上 |
| SVA_AR_STABLE | axi_chan_sva.sv:178 | §1 | 同上 |
| SVA_R_STABLE | axi_chan_sva.sv:182 | §1 | 同上 |
| SVA_RST_IDLE | axi_chan_sva.sv:191 | §2.3/§1 | AXI4 复位规则：rst 期间 valid 低 |
| SVA_RST_RELEASE_IDLE | axi_chan_sva.sv:195 | §2.3/§1 | AXI4 复位释放规则 |
| SVA_WLAST_LEN | axi_chan_sva.sv:262,291 | §1/§4.3 | beat count vs AxLEN（spec §1）|
| SVA_RLAST_LEN | axi_chan_sva.sv:314 | §1/§4.3 | 同上 |
| SVA_ATOP_ID_UNIQ | axi_xbar_atop_sva.sv:152 | §6.4 | ATOP ID 不与在飞 ID 重复（spec §6.4）|
| SVA_ATOP_DANGLING | axi_xbar_atop_sva.sv:173 | §6.3 | ATOP 对须两半返回（spec §6.3）|
| a_cfg_stable_during_ax | axi_xbar_route_sva.sv:47 | §3.4 | 配置不变量（spec §3.4）|
| SVA_OR_W_REORDER | axi_xbar_stall_sva.sv:450 | §5.2.1/§5.2.3 | 完成序保序（spec §5.2）|
| SVA_OR_R_REORDER | axi_xbar_stall_sva.sv:456 | §5.2.1/§5.2.3 | 同上 |

axi_xbar_txlimit_sva.sv 和 axi_xbar_worder_sva.sv 无 `uvm_error`（纯 cover/
`uvm_info`，非判决性）。

14 个 SVA 判决点全部引用 spec 条款作为期望值来源，**零 RTL 来源渗漏**。
共享函数 `decode_mst_port`（stall_sva 使用）已在上节 scoreboard 审计中覆盖。

---

## 3. BUG-0075 静态关闭复核

### 背景

BUG-0075：共享译码 oracle `decode_mst_port` 未实现 spec §3.2 cl.3 的
`end_addr=='0` 哨兵语义。处置选 option 2（env 约束路线）：§3.2 clause 4 追加
环境约束使哨兵构造性不可触发，oracle 维持现状。CLOSED 状态，证据为静态论证。

### 复核结论：**SOUND**

| 检查项 | 结果 |
|---|---|
| env 约束是否存在于代码中？| ✅ `gen_addr_map()`（xbar_types_pkg.sv:240-249）`end_addr = (i+1) * REGION_SIZE`，REGION_SIZE=32'h1000_0000，max=0x8000_0000，32 位下不可能回绕到 0 |
| 是否有旁路路径？| ✅ 搜索全部 `tb/` 文件：`rule_t`/`addr_map` 从不被 `rand`/`randomize`；运行时只有三处驱动 `cfg_if.addr_map`（tb_top:59 ADDR_MAP / seq_lib:1446 ADDR_MAP_V1 / seq_lib:2601 ADDR_MAP_OV1），全部追溯到 `gen_addr_map()` |
| 五个配置点是否都安全？| ✅ cfgA–E 共享同一 `gen_addr_map()` 和 REGION_SIZE/NO_ADDR_RULES 常量，`ifdef` 分支只影响拓扑/latency/ATOP/connectivity，不影响地址表生成公式 |
| `gen_addr_map_v1()` / `gen_addr_map_ov1()` 是否引入新的 end_addr？| ✅ 只改写 `idx`（重配目标端口）或复制已有 rule（重叠测试），不生成新 end_addr 值 |
| M5 随机化是否威胁约束？| ✅ M5 随机化的是事务地址（seq_lib 的 `rand addr`），不是 rule 表本身 |

**结论**：`end_addr=='0` 在当前代码的全部配置点和全部测试路径下确实不可触发。
静态关闭论证封死了所有触发路径。

### 小瑕疵（不影响结论）

spec/bug 文档中的"四张地址表"措辞暗示 cfgD 有独立地址表，实际 cfgD 复用
`gen_addr_map()` 且仅变更 `idx`（目标端口），`end_addr` 值与 baseline 完全
相同。文档精度瑕疵，不构成论证漏洞。

---

## 总结

| 审计项 | 结论 |
|---|---|
| scoreboard 22 个判决点期望值来源 | **零渗漏**——全部追溯到 spec.md / AMBA 常量 / 自身请求字段 |
| SVA 14 个判决点期望值来源 | **零渗漏**——全部引用 spec 条款 |
| ERR_RDATA（唯一 RTL 来源值）| **合规**——经 BUG-0033/REV-014 正式升格入 spec §4.4 |
| import/include 扫描（SB + SVA 全部文件）| **零 DUT 行为 RTL 引用** |
| BUG-0075 静态关闭 | **SOUND**——env 约束气密，全路径封死 |

**红线 2 在 scoreboard 全 22 个判决点、SVA 全 14 个判决点、及共享函数内未被
违反。** import 扫描确认 SB 和 SVA 全部源文件无 DUT 行为 RTL 引用。
