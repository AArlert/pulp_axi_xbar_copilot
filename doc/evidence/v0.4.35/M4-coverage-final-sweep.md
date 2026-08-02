# M4 覆盖率全景复测 — 权威扫描表（v0.4.35）

```
CMD (取数用，均已亲跑，VCS/urg O-2018.09-SP2，本 VM)：
cd sim
export VCS_HOME=/home/synopsys/vcs-mx/O-2018.09-SP2
export VERDI_HOME=/home/synopsys/verdi/Verdi_O-2018.09-SP2
export SCL_HOME=/home/synopsys/scl/2018.06
export VCS_ARCH_OVERRIDE=linux
export PATH=$VCS_HOME/bin:$VERDI_HOME/bin:$SCL_HOME/linux64/bin:$PATH
export LM_LICENSE_FILE=27000@icarray-virtual-machine

# ① 完整性核验：merged 基线 out/cov.vdb 是否已含 regress.list 全部可合并场景
#   （见 §1；不做 make clean，未重跑任何 sim，只读既有 vdb）
urg -full64 -dir out/cov.vdb -dir out/cfgE/cov.vdb \
    -report /tmp/urgReport_merged_ft01   # 探测 cfgE 是否可并入 —— 见 §1，结论：不可，UCAPI-INSTANCEMISMATCH

# ② 六类全闭包扫描（本报告全部数字来源，text 格式，逐模块/逐信号可查）
rm -rf out/urgText6
urg -full64 -dir out/cov.vdb -format text -report out/urgText6 \
    -metric line+cond+fsm+tgl+branch+assert
# 产出：out/urgText6/{dashboard,modlist,modinfo,hierarchy,asserts,tests}.txt
```

## 0. 取数来源声明

- 全部百分比取自本卡在本 VM 现场重生的 `sim/out/urgText6/{modlist,modinfo,hierarchy}.txt`
  （命令②），而非任何历史文档转述。
- merged 库 `sim/out/cov.vdb`：由上一张 DV 卡（M4-EB02）在 `regress.list`
  当前 30 行的第 24 个可并入场景（`m4_eb02_errbp_test`）跑完后累积生成，
  本卡未新跑任何 sim、未 `make clean`，只做了完整性核验（命令①）与只读的
  `urg` 报告重生（命令②，`-report` 目标是新目录 `out/urgText6`，不覆盖既有
  `out/urgReport`）。
- 场景 PASS 状态核对：`sim/result_summary.txt`（现场文件，未由本卡生成）
  末次记录 `date=2026-08-02 passed=30/30`，`regress.list` 30 行全 PASS
  （含本卡涉及的全部 24 个基线拓扑场景）。
- 例化闭包关系（模块名/实例路径/参数 tie-off）核对源：
  `vendor/axi/src/{axi_xbar.sv,axi_xbar_unmuxed.sv,axi_demux.sv,axi_demux_simple.sv,axi_mux.sv,axi_err_slv.sv,axi_atop_filter.sv,axi_id_prepend.sv,axi_multicut.sv,axi_cut.sv}`、
  `vendor/common_cells/src/{addr_decode.sv,addr_decode_dync.sv,rr_arb_tree.sv,lzc.sv,fifo_v3.sv,counter.sv,delta_counter.sv,spill_register.sv,spill_register_flushable.sv,stream_register.sv}`。
  **边界重申**：以上 RTL 阅读仅用于确认例化关系/参数取值/N/A 成因（结构事实），
  **未从中推导任何 checker 期望值**（BUG-0038 许可模式，卡片边界条款）。

## 1. Merged 覆盖库完整性核验

`sim/out/urgText6/dashboard.txt` 首行：`Number of tests: 24`。

`regress.list` 现 30 行。按拓扑/顶层设计分组：

| 组 | 场景数 | 是否在 `out/cov.vdb`（本报告数据源）内 | 原因 |
| --- | --- | --- | --- |
| 基线拓扑（6×8，全连接，`ATOPs=1`，`PipelineStages=1`，`FallThrough=0`） | 24 | **是**（testdata 目录逐条核对：`m1_01_smoke_test_1` … `m4_bp03_demuxlock_ar_test_1`，含 `m4_eb02_errbp_test_1`） | 本报告数据源 |
| `upstream_sanity` | 1 | 否 | 顶层为 `tb_axi_xbar`（M0 专属），与 `tb_top` 结构不同——BUG-0037 既有裁决，独立 `out/m0/cov.vdb` |
| `m3_cf01~04_test`（cfgA/B/C/D） | 4 | 否 | 端口拓扑/`UniqueIds`/`Connectivity` 与基线不同，各自独立 `out/cfgX/cov.vdb`（BUG-0037 既有裁决） |
| `m4_ft01_cfge_test`（cfgE） | 1 | 否 | 见下——本卡新核实为**结构性不兼容**，非构建产物隔离的偶然结果 |

`1 + 4 + 1 = 6`；`30 − 6 = 24`，与 dashboard 的 `24` 逐位对上 —— **merged 库对"基线拓扑"这一范围完整，无需补合并**。

**cfgE 单独核实（命令①的实测过程，本卡新增诊断，非因袭旧结论）**：`m4_ft01_cfge_test`
的拓扑参数（`NoSlvPorts=6`/`NoMstPorts=8`/`UniqueIds=0`/`Connectivity='1`）与基线**逐项相同**，
唯一差异是 `FallThrough=1'b1`（`tb/xbar_types_pkg.sv:93-172` `XBAR_CFG_E` 分支），
按直觉应可与基线合并。**亲跑命令①验证**（`urg -dir out/cov.vdb -dir out/cfgE/cov.vdb`）
结果为 **8 条 `Warning-[UCAPI-INSTANCEMISMATCH]`**，全部指向
`gen_mst_port_mux[0..7].i_axi_mux.gen_mux.i_w_fifo` 的 **Condition coverage 对象数不一致**
——即 `FallThrough` 改变了 `axi_mux` 内 `i_w_fifo`（`fifo_v3` 实例）的可综合条件覆盖形状，
并非仅仅是 `sim/Makefile` 出于 C5.1/C5.2 构建产物隔离习惯而人为分开的产物。
**结论：cfgE 与基线拓扑对覆盖率合并而言结构不兼容，不可并入，维持独立报告**
（与 v0.4.9 基线报告 §0 的既有处理一致，本卡是**独立复核**而非因袭）。
cfgE 自身的六类数字不在本卡范围（本卡范围=基线拓扑，spec §0#4 主体），如需另行补测由
后续卡处理。

**结论**：`out/cov.vdb`（24 场景）**已完整**，直接用于下方全闭包扫描，无需补合并、
无需 `make clean`。

## 2. 全闭包三态扫描

### 2.1 闭包成员核实（urg 模块清单 + RTL 例化关系逐一核对）

`sim/out/urgText6/modlist.txt`：`Total modules in report: 35`。按"是否落在
`axi_xbar` 顶层实例递归例化闭包内"逐一归类（`tb_top.i_xbar_dut` 为闭包根，
`hierarchy.txt` 亲验）：

**DUT 闭包内（22 个模块，本报告主体）**：`axi_xbar`、`axi_xbar_unmuxed`、
`addr_decode`（父，纯例化壳）、`addr_decode_dync`（子，真正承载逻辑）、
`axi_demux`（父，纯例化壳）、`axi_demux_simple`（子）、`axi_demux_id_counters`
（`axi_demux_simple.sv` 内定义的第二模块，**本报告首次单独按模块页测量**）、
`counter`、`delta_counter`（`counter` 内嵌）、`axi_err_slv`、`axi_atop_filter`、
`stream_register`（`axi_atop_filter` 内 `r_resp_cmd`）、`axi_mux`、
`axi_id_prepend`（`axi_mux` 内 ID 前缀子模块，**本报告首次单独测量**）、
`rr_arb_tree`（**首次单独测量**）、`lzc`（`rr_arb_tree` 内 `FairArb` 分支，
**首次单独测量**）、`fifo_v3`（**首次单独测量**）、`axi_multicut`、`axi_cut`、
`spill_register`（薄壳，包 `spill_register_flushable`）、
`spill_register_flushable`、`axi_pkg`（参数/函数包，无实例化，含 1 条内嵌
assert）。

**TB 侧（13 个模块，非本报告范围，spec §0#4 明文"不含 tb 侧例化"）**：`tb_top`、
`rand_verif_pkg`、`uvm_pkg`、`uvm_custom_install_verdi_recording`、
`mstport_if`、`slvport_if`、`xbar_cfg_if`（tb 侧重配置驱动接口，直接挂在
`tb_top` 下，不在 `i_xbar_dut` 子树内）、`axi_chan_sva`、`axi_xbar_atop_sva`、
`axi_xbar_txlimit_sva`、`axi_xbar_stall_sva`、`axi_xbar_worder_sva`、
`axi_xbar_route_sva`（后 6 个为 DV 侧协议/时序 SVA，按 CLAUDE.md §4 "VCS-2018
拒绝 bind，SVA 走宿主模块 generate 循环直接例化"落地在 `tb_top` 内，`hierarchy.txt`
亲验其父路径均为 `tb_top.gen_*_sva[N].u_*`，非 `i_xbar_dut` 子树成员）。

`22 + 13 = 35`，与 modlist 声明的 35 逐位对上。**无跨作用域污染核实**：
`grep` `tb/*.sv` 未见任何 TB 侧代码直接实例化上述 22 个 DUT 模块名（唯一
`axi_xbar #(` 实例化点在 `tb/tb_top.sv:116`）——故各模块页的聚合数字可直接
采信为"闭包子树内全部实例合并值"，无需按 spec §0#4 "若模块在子树外另有实例
须限定到子树"这一条款做额外过滤。

### 2.2 三态判定标尺

- **N/A**（无 bin）：模块源码经核实无对应过程语句/多项布尔条件表达式/
  `enum` 型状态寄存器；逐条见下表"成因"列。
- **≥90%**：PASS，无需动作。
- **<90%**：有 bin 但未达标，见 §3 归属标注。

### 2.3 全闭包扫描表（22 个 DUT 模块 × 6 类；实例数据源：`hierarchy.txt` 精确计数）

| 模块 | 实例数 | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `axi_xbar`（顶层） | 1 | N/A¹ | N/A¹ | **94.44** | N/A² | N/A¹ | **100.00** |
| `axi_xbar_unmuxed` | 1 | N/A¹ | **100.00** | **98.89** | N/A² | **100.00** | **100.00** |
| `addr_decode`（父，纯例化壳） | 12 | N/A¹ | N/A¹ | **92.68** | N/A² | N/A¹ | N/A¹ |
| `addr_decode_dync`（子，真正逻辑） | 12 | **100.00** | **100.00** | **92.00** | N/A² | 83.33 | **100.00** |
| `axi_demux`（父，纯例化壳） | 6 | N/A¹ | N/A¹ | **91.99** | N/A² | N/A¹ | N/A¹ |
| `axi_demux_simple`（子） | 6 | **100.00** | 82.76 | **93.73** | N/A² | **100.00** | **92.86** |
| `axi_demux_id_counters`（`axi_demux_simple.sv` 内第二模块） | 12 | 73.91 | **100.00** | 74.06 | N/A² | 79.49 | **100.00** |
| `counter` | 108 **[勘误 E1 → §10]** | N/A³ | N/A³ | 43.48 | N/A² | N/A³ | N/A³ |
| `delta_counter` | 108 | **100.00** | N/A⁴ | 41.20 | N/A² | **100.00** | N/A⁵ |
| `axi_err_slv` | 6 | **100.00** | **100.00** | 70.22 | N/A² | **100.00** | **100.00** |
| `axi_atop_filter` | 6 | 48.18 | 41.94 | 65.19 | 14.29 | 41.30 | **100.00** |
| `stream_register`（`atop_filter` 内 `r_resp_cmd`） | 6 | 75.00 | N/A⁶ | 22.00 | N/A² | 50.00 | N/A⁵ |
| `axi_mux` | 8 | **100.00** | **100.00** | 89.34 | N/A² | **100.00** | **100.00** |
| `axi_id_prepend`（`axi_mux` 内 ID 前缀子模块） | 48 | **100.00** | N/A⁷ | 78.26 | N/A² | N/A⁷ | **100.00** |
| `rr_arb_tree` | 28 | 80.00 | **95.74** | 77.45 | N/A² | **91.59** | **100.00** |
| `lzc`（`rr_arb_tree` 的 `FairArb` 分支内） | 56 | N/A³ | **97.73** | 42.59 | N/A² | **97.73** | **100.00** |
| `fifo_v3` | 26 | **92.68** | 80.19 | 82.09 | N/A² | 78.43 | **100.00** |
| `axi_multicut` | 48 | N/A¹ | N/A¹ | 89.22 | N/A² | N/A¹ | **100.00** |
| `axi_cut` | 48 | N/A¹ | N/A¹ | 89.22 | N/A² | N/A¹ | N/A¹ |
| `spill_register`（薄壳，包 flushable） | 322 | N/A¹ | N/A¹ | 88.51 | N/A² | N/A¹ | N/A¹ |
| `spill_register_flushable` | 322 | **100.00** | 82.49 | 79.76 | N/A² | **100.00** | 0.00 |
| `axi_pkg`（参数/函数包） | — | N/A⁸ | N/A⁸ | N/A⁸ | N/A² | N/A⁸ | **100.00** |

粗体 = ≥90% PASS；数字未加粗 = <90%（见 §3 归属）。

**N/A 成因逐条核实（读 RTL 结构，非期望值推导）**：

1. **[勘误 E6 → §10：本脚注主体（纯例化壳判定）成立；仅末句"以上均只有 Toggle
   有意义…Line/Cond/Branch/Assert 无 bin"对 `axi_xbar`/`axi_xbar_unmuxed`/`axi_multicut`
   三者的 **Assert** 分量失真（三者 Assert=100.00，见 §2.3 表）。§10.3 首行已载此发现，
   但此前脚注 1 无就地标记、§10.1 无表行、§10.5 无事实行——本条补齐同形处置（BUG-0064）。
   三态判定不受影响（§2.3 这些格未标 `N/A¹`）。下文原文保留不改。]**
   **纯例化壳，无本体过程语句**：`addr_decode.sv`（109 行，只对
   `addr_decode_dync` 做参数透传例化）、`axi_demux.sv`（只例化
   `axi_demux_simple` + spill 链）、`axi_multicut.sv`（237 行，纯 generate-for
   例化 `axi_cut` 链，逐行核实无 `always_comb`/`if`/`case`）、`axi_cut.sv`
   （290 行，纯 generate 例化 5 条 `spill_register` 通道，逐行核实同上）、
   `spill_register.sv`（17-46 行，仅端口透传例化 `spill_register_flushable`）、
   顶层 `axi_xbar.sv`/`axi_xbar_unmuxed.sv` 自身也是纯 generate 例化壳（承载逻辑
   在其内部子模块）——以上均只有 Toggle 有意义（端口/内部信号仍会翻转），
   Line/Cond/Branch/Assert 无 bin。
2. **FSM**：除 `axi_atop_filter`（唯一声明 `enum` 型 `w_state_q`/`r_state_q`
   状态寄存器）外，闭包内其余模块均无 VCS FSM 抽取口径认可的 `enum` 状态寄存器
   （`rr_arb_tree` 的 `lock_q`/`req_q` 为普通 `logic` 向量，非 `enum`，故其时序
   逻辑不计入 FSM 口径——与 v0.4.0/v0.4.9 报告"组合 `rr_arb_tree`，非本报告口径
   FSM"的既有措辞一致，本卡独立复核确认）。
3. **[勘误 E2 → §10：本条对 `lzc` 的陈述与成因均已被原始 `modinfo.txt` 证伪；
   `counter` 部分成立。下文原文保留不改。]** **`counter.sv`（28 行）/`lzc.sv` 的 Line/Cond/Branch N/A**：`counter.sv`
   为 `delta_counter` 的纯参数透传壳（`delta_i` 恒接 `{{W-1{1'b0}},1'b1}`），
   无自身过程语句；`lzc.sv` 顶层模块体本身在 `MODE`/`WIDTH` 参数下走
   generate-case 选择内部实现，Line/Branch 的"有意义代码"落在其内部 generate
   分支的过程块里，但该分支代码在 VCS 的 line/branch 统计口径下未见独立 bin
   （亲验 `modinfo.txt` `lzc` 小节 Line/Branch 均为空白，Cond/Toggle/Assert 有
   数），与 v0.4.0/v0.4.9 报告对 `addr_decode`/`axi_demux` 父壳的空白判定属
   同一 VCS 统计现象类别。
4. **`delta_counter.sv` Cond N/A**：其 `if`/`else if` 链（29-77 行）逐条核实
   均为**单一信号条件**（`if (clear_i)`/`else if (load_i)`/`else if (en_i)`
   内嵌 `if (down_i)`），无 `&&`/`||` 多项布尔组合表达式——VCS `-cm cond`
   未对单项条件生成 bin（对照 `fifo_v3`/`spill_register_flushable` 等模块的
   Cond 确有数值，佐证 VCS 确实会在多项组合式处生成 bin，此处空白应理解为
   "该模块没有多项布尔组合式"而非工具异常）。
5. **[勘误 E4 → §10：Assert N/A 判定与其操作性成因（实测无 `assert`）均成立；
   仅括注"全文无 `if`"一句失真，同 E3 根因。本条为 §10.3 抽样反证新发现，
   不在 BUG-0051 原登记面内。下文原文保留不改。]**
   **`stream_register.sv`/`spill_register_flushable.sv` 的 Assert N/A 例外**：
   `stream_register.sv` 全文无 `if`（纯组合值锁存 + 一条 `assert`... 实测无
   assert，Assert 列 N/A）；`spill_register_flushable` **有** 1 条 assert
   （`flush_valid`，见 §3 表末条特别说明，非 N/A，是 0.00% 的真实数字）。
6. **[勘误 E3 → §10：N/A 判定成立，但本条给出的成因已被原始 `modinfo.txt`
   证伪，§10.2 给出重写后的成因。下文原文保留不改。]**
   **`stream_register.sv` Cond N/A**：全文（约数十行）无 `if`/`case`/`?:`，
   纯组合赋值 + 时序锁存，无条件语句可供 VCS 生成 Cond bin。
7. **`axi_id_prepend.sv` Cond/Branch N/A**：唯一的 `if (PreIdWidth == 0)`
   （82 行）是**编译期常量条件**（generate-if，由参数值在综合前确定分支，
   非运行时可翻转的分支），故不产生运行时 Cond/Branch bin；本闭包配置下
   `PreIdWidth=3≠0`，走非零分支，该分支内部是纯组合赋值，无运行时条件。
8. **`axi_pkg` Line/Cond/Toggle/Branch N/A**：`axi_pkg` 是参数/类型/函数
   package（无实例化、无独立端口），其内部 `case` 语句（burst 边界/mtype
   解码函数，`axi_pkg.sv:155/246`）按 VCS 的 package-scope 覆盖归属惯例内联
   计入调用点模块（如 `axi_xbar_unmuxed`/`addr_decode_dync`）的覆盖数据，
   未在 `axi_pkg` 自身模块页留痕；唯一独立留痕的是内嵌 1 条 assert
   （`wrap_boundary`，100% real-succeeded，408/408 attempts）。

## 3. <90% 格子归属标注（只标注，不处置）

| # | (模块,类型) | 数值 | 归属 | 依据 |
| --- | --- | --- | --- | --- |
| 1 | `addr_decode_dync` Branch | 83.33% | **[CW-008]** | `doc/coverage-waivers.md` CW-008（Kind-A，REV-029：`config_ongoing_i` 恒 0 tie-off 致 `addr_decode_dync.sv:146` else 分支为 X-theater 守卫，永不可达） |
| 2 | `axi_demux_simple` Cond | 82.76% | **[CW-009] + [DV-E/#16]（拆分）** | 5 bin 之 1（`w_open==15`）= CW-009（Kind-A，REV-030）；其余 4 bin（`ar_id_cnt_full && atop[R_RESP]` 交叉）= REV-030 §3 DV-E（#16），责成后续 DV 卡 |
| 3 | `axi_err_slv` Toggle | 70.22%（REV-030 记录时 69.78%，本次 24 场景含 `m4_eb02` 后提升 0.44pp） | **[CW-003/004/005/006/002/007 + BUG-0044 + DV-A + DV-D]（全量已分诊）** | REV-030 §1 逐信号拆解：恒定错误应答数据/resp/user = CW-003/004/005；`rst_ni`/`test_i`/`size[2]` = CW-006/002/007；`atop[4]/[5]` 非-load 子类型 = BUG-0044；`ar/aw.size[1:0]`/`addr[2:0]`/`len[7:4]` = DV-A（err_slv 支）；**`ar_ready` 已由 DV-D（#18）对应的 `m4_eb02_errbp_test` 关闭**（见下方"本卡新核实"） |
| 4 | `axi_mux` Toggle | 89.34% | **[CW-002/006/007 + BUG-0044 + DV-A/DV-B/DV-C]（全量已分诊）** | REV-030 §1 逐信号拆解，见其 axi_mux 行；`b_ready` 背压残余 = DV-C（#17），责成后续 DV 卡 |
| 5 | `axi_atop_filter` 六类（Line 48.18/Cond 41.94/Toggle 65.19/FSM 14.29/Branch 41.30） | 见左 | **[CW-001]（Kind-A，但见下方"核实发现"——部分归因需 rev 复核）** | `doc/coverage-waivers.md` CW-001（环境约束致不可达，REV-017）。**本卡核实发现**：CW-001 的论证文本对 `r_state_q` 的 `R_HOLD` 状态**不成立**，见 §4 |
| 6 | `axi_demux_id_counters` Line/Toggle/Branch | 73.91% / 74.06% / 79.49% | **UNOWNED（新发现）** | 见 §5-1 |
| 7 | `axi_id_prepend` Toggle | 78.26% | **UNOWNED（新发现，含与 DV-C 同根的子集）** | 见 §5-2 |
| 8 | `rr_arb_tree` Line/Toggle | 80.00% / 77.45% | **UNOWNED（新发现）** | 见 §5-3 |
| 9 | `lzc` Toggle | 42.59% | **UNOWNED（新发现）** | 见 §5-4 |
| 10 | `fifo_v3` Cond/Toggle/Branch | 80.19% / 82.09% / 78.43% | **UNOWNED（新发现）** | 见 §5-5 |
| 11 | `counter`/`delta_counter` Toggle | 43.48% / 41.20% | **UNOWNED（新发现，与 CW-009 部分同根）** | 见 §5-6 |
| 12 | `axi_multicut`/`axi_cut`/`spill_register`（薄壳）Toggle | 89.22% / 89.22% / 88.51% | **UNOWNED（新发现——订正 REV-024 §2.2 行 9 的数据错误，见 §6）** | 见 §5-7 |
| 13 | `spill_register_flushable` Cond/Toggle | 82.49% / 79.76% | **UNOWNED（新发现）** | 见 §5-7 |
| 14 | `spill_register_flushable` Assert | 0.00%（Attempts 2,912,000／Real Successes 0，非"failing"） | **UNOWNED（新发现，强 Kind-A 候选）** | 见 §5-8 |

## 4. 核实发现：CW-001 对 `axi_atop_filter r_state_q` 的论证文本有一处不成立

`doc/coverage-waivers.md` CW-001 的不可达性论证文本是"进入其状态须 atop!=0
抵达 miss 地址，被环境约束构造性禁止"，适用范围含 `axi_atop_filter` 六类
"非-FEEDTHROUGH 状态/迁移及其从属 line/cond/tgl/branch"。

**本次全闭包扫描的 FSM 明细（`modinfo.txt` `axi_atop_filter` 小节）显示**：

- `w_state_q`（写侧）：2/7 状态、1/20 迁移，**与 REV-024/REV-030 记录完全一致，
  未变**——`BLOCK_AW`/`ABSORB_W`/`HOLD_B`/`INJECT_B`/`WAIT_R` 仍全部
  Not Covered。RTL 核实（`axi_atop_filter.sv:151-243`）：这些状态的迁移条件
  确实系于 `slv_req_i.aw.atop[5:4]` 非 `ATOP_NONE` 且非纯 load 类编码，CW-001
  对写侧的论证**成立**。
- `r_state_q`（读侧）：**States 3/4（75.00%），较 REV-024/REV-030 记录的
  2/4 状态多 1 个**——`R_HOLD`（:275）现为 **Covered**，`R_FEEDTHROUGH->R_HOLD`
  与 `R_HOLD->R_FEEDTHROUGH` 两条迁移弧均 **Covered**。
- **RTL 核实迁移条件**（`axi_atop_filter.sv:273-306`）：
  `R_FEEDTHROUGH: if (mst_resp_i.r_valid && !slv_req_i.r_ready) r_state_d = R_HOLD;`
  ——此条件**与 ATOP 完全无关**，是"任意一笔（含非 ATOP 的普通）读事务的 R
  响应 valid 但下游未 ready"这一**普通读背压**条件。`R_HOLD` 由此被
  M2-TL01/TL02（`resp_hold` 机制）或 M4-EB01/EB02 一类的读侧背压场景触达，
  与"是否构造过非-load ATOP 编码"无关。
- **本卡未发现任何新 ATOP 序列变体**（`tb/seq_lib.sv` 全仓库仍只有
  `ATOP_LOAD_ADD` 一种编码，REV-030 §1 已确认，本卡未重验此点、采信既有
  记录）——即 `R_HOLD` 的覆盖改善**不是**因为 ATOP 多样性提升，而是纯粹的
  读背压场景（M2-TL01/TL02/M4-EB01/EB02 中某一个或多个）副作用命中。
  `INJECT_R`（:281，真正需要 `r_resp_cmd_pop_valid`——即真正的 ATOP R 响应
  注入）**仍未覆盖**，与 CW-001 论证一致。

**结论（只报告事实，不处置、不改 CW-001、不判断 Kind）**：CW-001
的不可达性论证对 `w_state_q` 全部状态和 `r_state_q` 的 `INJECT_R` 仍然成立，
但对 `r_state_q` 的 `R_HOLD` 状态/迁移**不成立**——该状态是普通读背压路径，
已被现有非-ATOP 背压场景实际触达且与 ATOP 编码多样性无关。这不改变
CW-001 覆盖的模块整体六类判据（`axi_atop_filter` 六类仍全部 <90%，仍需要
CW-001 承接其余大宗），但 CW-001 的论证文本存在这一处与 RTL 结构事实不符的
表述，留给 rev 复核是否需要订正措辞（同 REV-028/029 对 REV-024 行 6 的"只订正
归因、不改判"先例）。

## 5. UNOWNED 清单（逐条结构核实，供 rev/orch 分类，本卡不判断 Kind）

**5-1. `axi_demux_id_counters` Line 73.91% / Toggle 74.06% / Branch 79.49%**

`modinfo.txt` 显示未覆盖行集中在 `axi_demux_simple.sv:582-589`（`unique case`
的 `3'b110`/`3'b010` 分支，`push_en[i] && inject_en[i]` 同时为 1、
`cnt_delta=cnt_t'(2)`/`cnt_t'(1)`）。RTL 核实（`axi_demux_simple.sv:210-228`
`i_aw_id_counter` 例化）：AW 侧计数器的 `.inject_i(1'b0)` **恒接常量 0**——故
该分支对 `i_aw_id_counter` 结构性不可达（Kind-A 候选）。但**AR 侧**
`i_ar_id_counter`（`axi_demux_simple.sv:355-374`）的 `.inject_i(atop_inject)`
是**真实信号**，`push_i=ar_push`（真实 AR 接受），二者可在**同一 index i**
（即 `slv_req_i.ar.id` 与 `slv_req_i.aw.id` 低位相同）的同一拍同时为 1——这
需要"同拍接受一笔 AR 且注入一笔 ATOP 写的 R 响应、且二者 ID 低位相同"这一
构造，环境至今未构造过。**与 REV-030 §3 DV-E（#16）同族但不同 bin**：
DV-E 针对 `axi_demux_simple.sv:168`（`ar_id_cnt_full && atop[R_RESP]`，判断
AR 计数器是否"已满"），本条针对 `axi_demux_id_counters` 内部计数器自身的
"push+inject 同拍同 index"路径（判断计数器如何"变化"）——是相邻但独立的
(模块,类型) 缺口，当前无任何 CW/BUG/DV-x 条目点名。

**5-2. `axi_id_prepend` Toggle 78.26%**

Port Details 显示 3 类未翻转信号：`pre_id_i[2:0]`（No/No/No）、
`slv_b_readies_i`（No/No/No）、`mst_b_readies_o`（No/No/No）。
- `pre_id_i`：RTL 核实（`axi_mux.sv:227` `.pre_id_i(switch_id_t'(i))`）—— 这是
  **generate-loop 编译期常量**（每个实例的固定值，非运行时信号），结构上
  永不可能在单个实例内"翻转"（Kind-A 候选，性质同 CW-007/CW-002）。
- `slv_b_readies_i`/`mst_b_readies_o`：这是 B 通道 ready 信号的直通，
  **与 REV-030 §1 DV-C（#17）"axi_mux `mst_req_o.b_ready` 无背压路径"同根**
  （外部主机 `b_ready` 恒高，`slvport_agent.sv:44-45`）——但 DV-C 当前登记的
  目标信号是 `axi_mux` 顶层端口，未点名 `axi_id_prepend` 这一嵌套子模块的
  同名信号，作为独立 (模块,类型) 记录目前无条目覆盖。若 DV-C 落地，此处应
  随之改善，但**目前是独立 UNOWNED 记录**。

**5-3. `rr_arb_tree` Line 80.00% / Toggle 77.45%**（Cond 95.74%/Branch
91.59%/Assert 100% 均已 PASS，不在本清单）

Line 未覆盖集中在 `flush_i` 分支（`rr_arb_tree.sv:158-159`
`if (flush_i) lock_q <= '0` 与 181-182 `if (flush_i) req_q <= '0`）。
RTL 核实：**全部** `rr_arb_tree` 实例化点（`axi_mux.sv:272/324/417`、
`axi_demux_simple.sv:273/391`）均 `.flush_i(1'b0)`——本 DUT 集成从未对外
暴露 `flush_i` 能力，结构性不可达（Kind-A 候选）。Toggle 缺口另需按信号
分解（未逐位展开，超出本卡"只标注不处置"范围）。**当前无 CW/BUG 条目
点名 `rr_arb_tree` 本身**。

**5-4. `lzc` Toggle 42.59%**（Cond 97.73%/Branch 97.73%/Assert 100% 已 PASS）

`lzc_lower`/`lzc_upper` 是 `rr_arb_tree` `FairArb` 分支内用于"从上一次
仲裁位置的上/下半区找最近置位请求"的编码器（`rr_arb_tree.sv:197-201` 附近
`gen_mask`/`upper_idx`/`lower_idx` 逻辑）。Toggle 缺口性质为"仲裁请求向量的
特定位组合模式未被穷举"（例如某些请求端口位置从未在"上半区搜索"或
"下半区搜索"路径下单独命中）——这与仲裁流量分布/端口数目有关，未见任何
现有 CW/BUG/DV-x 条目点名 `lzc` 本身。

**5-5. `fifo_v3` Cond 80.19% / Toggle 82.09% / Branch 78.43%**

`fifo_v3` 在闭包内有 3 处不同例化上下文（`axi_mux.sv:319` 的 `i_w_fifo`，
`axi_err_slv.sv:90/123/165` 的 `i_w_fifo`/`i_b_fifo`/`i_r_fifo`），
`.flush_i(1'b0)` 在全部例化点恒接常量（同 §5-3 的 flush_i 结构性不可达
模式，跨模块重复出现）。除 flush 相关行外，其余 Cond/Branch 缺口未逐位
展开定位；**当前无 CW/BUG/DV-x 条目点名 `fifo_v3` 本身**。

**5-6. `counter`/`delta_counter` Toggle 43.48% / 41.20%**

模块页聚合跨 3 类不同语境的实例（`axi_demux_id_counters` 内 in-flight 计数器
96 例、`axi_demux_simple` 内 `i_counter_open_w` 6 例、`axi_err_slv` 内
`i_r_counter` 6 例，合计 108 例）。其中 `i_counter_open_w` 一支与
**CW-009 同根**（`doc/coverage-waivers.md` CW-009：`w_open` 因下游 `axi_mux`
`i_w_fifo` 深度=6 的结构性封顶，从未达到 4-bit 计数器的全一值 15——CW-009
登记的是 `axi_demux_simple.sv:168` 的 **Cond** bin，未覆盖 `counter`/
`delta_counter` 自身的 **Toggle** bin，是相邻但独立的 (模块,类型) 记录）；
`in-flight` 计数器一支与 §5-1 的 push+inject 同拍同 index 缺口同根；
`i_r_counter` 一支未见任何既有条目讨论。**三个子成因均已知一部分线索但
均未以"counter/delta_counter 模块自身"为条目登记**——UNOWNED。

**5-7. `axi_multicut`/`axi_cut`/`spill_register`（薄壳）Toggle 89.22%/
89.22%/88.51%；`spill_register_flushable` Cond 82.49%/Toggle 79.76%**

见 §6 REV-024 对账——REV-024 §2.2 行 9 记录的"Cond 55-65%"数字，本卡核实
后确认 `axi_multicut`/`axi_cut` **结构上没有 Cond bin**（§2.3 N/A 成因 1），
该数字应属 `spill_register_flushable` 的 Cond（本卡测得 82.49%，较 v0.4.9
记录的 65.16% 已改善，见 §6）。`axi_multicut`/`axi_cut`/`spill_register`
薄壳的 **Toggle**（89.22%/89.22%/88.51%）是本卡新发现的 <90% 数字（原 v0.4.9
表格误将其记为 N/A），未逐位展开定位，**当前无 CW/BUG/DV-x 条目点名**。

**5-8. `spill_register_flushable` Assert 0.00%（Attempts 2,912,000 / Real
Successes 0）——强 Kind-A 候选，但当前 UNOWNED**

唯一 assert 为 `flush_valid: flush_i |-> ~valid_i`
（`spill_register_flushable.sv:99`）。**RTL 核实**：`flush_i` 在闭包内全部
322 个实例的例化点（经由 `spill_register`/`axi_cut` 两层薄壳）追溯到根，
均恒接常量 `1'b0`（`axi_mux.sv`/`axi_demux.sv`/`axi_cut.sv` 逐处核实）——
该 assert 的前提 `flush_i` 永不为真，是**结构性 vacuous**（不是"失败"，
Failures=0；是"从未真正触发过前提"）。与 §5-3/§5-5 的 `flush_i` 结构性
不可达是**同一根因的第三处体现**（`rr_arb_tree`/`fifo_v3`/
`spill_register_flushable` 三个模块的 flush 相关 bin 均系于同一个"本
DUT 集成从未对外暴露 flush 能力"的事实）。**当前无 CW/BUG 条目覆盖此
assert**。

## 6. 与 REV-024 §2.2 逐行对账

| REV-024 行 | (模块,类型) | REV-024 记录数值（v0.4.9 快照） | 本次实测数值（24 场景，2026-08-02） | 差异说明 |
| --- | --- | --- | --- | --- |
| 1 | `axi_atop_filter` 六类 | Line 46.36/Cond 35.48/Toggle 40.34/FSM 7.14/Branch 34.78 | Line 48.18/Cond 41.94/**Toggle 65.19**/**FSM 14.29**/Branch 41.30 | 全五项均有小幅改善；**FSM 从 7.14%→14.29%（翻倍）核实为 `r_state_q` 的 `R_HOLD` 状态新覆盖，根因为读背压场景副作用、与 ATOP 多样性无关**（§4 详述，CW-001 论证有一处不成立） |
| 2 | `addr_decode`/`axi_demux`（父）Line/Cond/Branch/Assert | 空白（结构性 N/A） | 空白（结构性 N/A，本卡独立复核 RTL 确认无过程语句） | 无变化，判定维持 |
| 3 | `axi_xbar` Toggle | 40.74%（`<90%`，需补场景） | **94.44%（现 PASS，≥90%）** | **已解决**——`en_default_mst_port_i`/`default_mst_port_i` 具体位双向翻转已由后续 M4 场景（RC01/BP02/BP03/EB01/EB02 等）补齐，不再是缺口。按 REV-028/029 先例，已过门不再逐信号追问 |
| 4 | `axi_xbar_unmuxed` Assert | 53.85%（26 attempted/14 real-succeeded，`default_aw_mst_port` 系列 real-succeeded=0） | **100.00%（现 PASS，26/26 assertion 至少一次 real-succeeded）** | **已解决**——`gen_slv_port_demux[i].default_aw_mst_port`/`_en` 现 Real Successes=45~51（逐实例核实，非 0），对照 AR 侧同结构 assert 仍为 Real Successes=97~115。本卡未追溯具体是哪张历史卡关闭了此项（REV-030 报告时刻该项已不在其残余表内，说明在 REV-024→REV-030 之间已被关闭），仅如实报告当前数字 |
| 5 | `axi_demux_simple` Line/Cond/Branch/Assert | 83.72%/72-76%/77.78%/50.00% | **Line 100.00/Branch 100.00/Assert 92.86（三项现 PASS）**；Cond 82.76%（仍 <90%） | Line/Branch/Assert 三项已解决；Cond 项由 REV-029/REV-030 拆分为 CW-009（1 bin）+ DV-E（4 bin），见 §3 |
| 6 | `addr_decode_dync` Toggle/Branch | 53-57% / 83.33% | **Toggle 92.00%（现 PASS）**；Branch 83.33%（不变） | Toggle 已解决；Branch 数值不变，其归属已由 REV-029 裁为 CW-008（Kind-A），本卡数字与 REV-029 记录一致 |
| 7 | `axi_mux` Toggle | 55.75-58.63% | 89.34%（不变，与 REV-030 记录一致） | REV-024→REV-030 期间已大幅改善（55-58%→89.34%），REV-030→本次（24 场景）持平，已由 REV-030 §1 全量拆解分诊 |
| 8 | `axi_err_slv` Cond/Toggle | 83.33% / 42-44% | **Cond 100.00%（现 PASS）**；Toggle 70.22%（较 REV-030 记录的 69.78% 又提升 0.44pp） | Cond 已解决；Toggle 项由 REV-030 全量拆解分诊，其中 **`ar_ready`（DV-D/#18）已被本次新增的 `m4_eb02_errbp_test` 关闭**（本卡核实：`slv_resp_o.ar_ready` 现 Yes/Yes/Yes，REV-030 记录时为 No/No/No） |
| 9 | `axi_multicut`/`axi_cut`/`spill_register` Cond | 55-65% | **`axi_multicut`/`axi_cut` 实测 Cond = N/A（结构性，无 bin）；`spill_register_flushable` Cond = 82.49%** | **REV-024 §2.2 行 9（承 v0.4.9 §4.2 表）存在数据错误**：`axi_multicut`/`axi_cut` 源码（237/290 行）逐行核实**无任何 `if`/`case`/`?:` 表达式**，结构上不可能产生 Cond bin；v0.4.9 报告该行的"55.96%"数字应属 `spill_register_flushable` 的 Cond（当时约 65.16%，其行文本身也把 spill_register 单独列为 65.16%，与 axi_multicut/axi_cut 的 55.96% 并列，暗示当时可能发生了列错位或数值误植）。本卡**只订正数据本身、不推测具体成因**（保留原记录不改，同 REV-028/029 先例）；`spill_register_flushable` 的 Toggle（79.76%）与 Assert（0.00%）均为本卡新增测量粒度，UNOWNED，见 §5-7/§5-8 |

## 7. 与 REV-030 §1 全景表交叉核实（三模块残余，确认无回退）

`axi_mux`/`axi_demux_simple`/`axi_err_slv` 三模块的六类数字与 REV-030 §1
逐项比对：**除 `axi_err_slv` Toggle（69.78%→70.22%，因 `m4_eb02` 关闭
DV-D 而提升）外，其余全部数字逐位相同**——确认 REV-030 之后到本卡之间
（除新增 `m4_eb02_errbp_test` 外）无回归、无新增波动。

## 8. UNOWNED 汇总清单（供 orch 路由，本卡不建议具体处置路径）

`axi_demux_id_counters`（Line/Toggle/Branch）、`axi_id_prepend`（Toggle）、
`rr_arb_tree`（Line/Toggle）、`lzc`（Toggle）、`fifo_v3`（Cond/Toggle/Branch）、
`counter`/`delta_counter`（Toggle）、`axi_multicut`/`axi_cut`/
`spill_register`薄壳（Toggle）、`spill_register_flushable`（Cond/Toggle/
Assert）——**9 个 (模块,类型) 组合，跨 8 个模块**，均为 spec §0#4 "闭包成员
非穷举举例清单"下此前从未被任何 DV/rev 卡以模块页粒度单独测量、也从未被
`doc/coverage-waivers.md`/`doc/bugs.md`/REV-030 §1 点名的缺口。其中：

- 至少 3 处（`rr_arb_tree` Line、`fifo_v3` 部分、`spill_register_flushable`
  Assert）共享同一结构事实——**`flush_i` 在本 DUT 集成的全部例化点恒接
  `1'b0`**，是很强的 Kind-A 候选（同 CW-002/CW-006/CW-007 的"能力未被暴露"
  模式），但本卡不越权登记。
- 至少 2 处（`axi_id_prepend` 的 `pre_id_i`、同上 `flush_i` 相关）是
  generate-loop 编译期常量/tie-off，结构上不可能翻转，Kind-A 候选性质
  更强。
- 其余（`axi_demux_id_counters` 的 push+inject 同 index、`counter`/
  `delta_counter` 部分、`lzc`、`axi_multicut`/`axi_cut`/`spill_register`
  薄壳的 Toggle）性质更接近"定向可达未测"（需补场景），与 REV-030 已分诊
  的 DV-A~E 类似但目标信号不同、不属其登记范围。

## 9. 结论边界重申

本文件只是测量记录：**不判定 M4 是否达标、不判断任何缺口的 Kind、不登记
豁免、不建 bug 行、不派发 DV 卡**。§3/§5/§8 的 UNOWNED 标注与 §4 的 CW-001
核实发现，均留给 orch/rev 收到本报告后分诊。

## 10. 勘误（2026-08-02 追记，BUG-0051 订正卡；`doc/review/REV-035.md` §Q2(b) 裁定）

**处置形态**：**不覆写、不删除，只追加 + 就地标记**。§1-§9 的全部既有字节原样保留；
四处错处只在**原位新增**了一个 `[勘误 En → §10]` 标记。保留原文的理由（REV-035
§Q2(b)）：读者须能看见"当时相信的是什么"，以及三轮复核（REV-031/032/033）与
四路独立复算中的三路为何都放过了它——覆写会把这条教训一并删掉。**可引用的边界**：
"不回改" = 不覆写、不删除；**不等于不许批注**。加标记是加法（保留全部原信息 +
新增一条指针），覆写是减法。

**本节全部数字均回源自原始 urg 文本报告与 vendor RTL，未以本文件任何汇总节
（§3/§5/§8）为输入**（REV-035 §G7：以汇总为输入的核对，核的是"抄得一致"而非
"抄得对"——那正是 BUG-0049 的成因）。

### 10.1 逐条勘误

| id | 错处 | 原文所述 | 机器实测（回源） | 取数来源 |
| --- | --- | --- | --- | --- |
| **E1** | §2.3 `counter` 行"实例数"列 | `108` | **12**（6×`i_r_counter` + 6×`i_counter_open_w`） | `modinfo.txt` L1692 起 `counter` 模块页 `Module self-instances :` 表逐行数 = 12；交叉核对 `hierarchy.txt`：`grep -c i_r_counter`=6、`grep -c i_counter_open_w`=6。`108` 是**下一行 `delta_counter`** 的数（96×`i_in_flight_cnt` + 12×`counter.sv:28-31` 壳内 `i_counter`），系单格错抄 |
| **E2** | 脚注 3（标题 + 正文对 `lzc` 的部分） | "`lzc.sv` 的 Line/**Cond**/**Branch** N/A"；"亲验 `modinfo.txt` `lzc` 小节 Line/**Branch** 均为空白" | `lzc` 模块页实有 Coverage 节 = **Assert / Branch / Cond / Toggle**（**无 Line 节**）；**仅 Line 为 N/A**，Cond=**97.73**、Branch=**97.73** | `modinfo.txt` L146860 起 `lzc` 模块页节种类枚举；`modlist.txt:48` `lzc` 行 = `84.51 -- 97.73 42.59 -- 97.73 100.00`（LINE 列为 `--`，COND/BRANCH 列有数） |
| **E3** | 脚注 6（成因；N/A 判定本身成立） | "`stream_register.sv` 全文无 `if`/`case`/`?:`，纯组合赋值 + 时序锁存，无条件语句可供 VCS 生成 Cond bin" | 该模块**有** `if`：`:37`/`:38` 的 `FFLARNC` 宏展开出 `if (!rst_ni)` / `if (clr_i)` / `else if (ready_o\|reg_ena)`，urg Line 表逐支计数（37.5/37.8/37.10/38.5/38.8/38.10）、Branch 表列 `IF 37` 与 `IF 38` 各 4 支。**Cond 为 N/A 成立**（该页实有节 = Branch / Line / Toggle，无 Cond 节），**但原成因不成立**；重写见 §10.2 | `modinfo.txt` L2611 起 `stream_register` 模块页：节种类枚举 + Line 表 `ALWAYS 37`/`ALWAYS 38` + Branch 表 `IF 37`/`IF 38` |
| **E4** | 脚注 5 的括注（**本次 §10.3 抽样反证新发现，不在 BUG-0051 原登记面内，已报 orch**） | "`stream_register.sv` 全文无 `if`" | 同 E3，该句失真。**但脚注 5 承载的是 Assert 格**，其操作性成因"实测无 `assert`"经复核**成立**（`grep -c assert vendor/common_cells/src/stream_register.sv` = **0**；该页无 Assert 节）⇒ `(stream_register, Assert)` 的 N/A 判定与成因**均不受影响** | 同上 + vendor RTL 亲读 |
| **E5** | §10.2(B)（`:491`）判别式自洽段"有 Cond 节的 11 个模块…全部 Cond bin 的源码行" | "共 **31** 个行号" | **57** 个不同（模块,行号）对 / **53** 个不同行号（两口径互证）。结论"无一例外含 `&&`/`\|\|`/`?:`"不受影响 | `modinfo.txt` 按 `Cond Coverage for Module : <mod>` 分节提取 `LINE <n>`，22 DUT 模块过滤后程序化重算——命令/分布/局限见 §10.5（BUG-0063） |
| **E6** | 脚注 1 末句（§10.3 首行 2026-08-02 已载，此前未获就地标记/表行/事实行——BUG-0064 同构缺陷处置不对称） | "以上均只有 Toggle 有意义…Line/Cond/Branch/Assert 无 bin"（其列举含 `axi_xbar`/`axi_xbar_unmuxed`/`axi_multicut`） | 该三模块 **Assert=100.00**（有 bin，非"无 bin"）；其 Line/Cond/Branch 仍 N/A 成立 | `modlist.txt`/`modinfo.txt` 该三模块 Assert 节 + §2.3 表逐格；三态判定不受影响（§2.3 未标 `N/A¹`） |

**E1 的影响面**：实例数**不是** `doc/milestone.md` M4 出口条件第二条的判据要件（该条要件
是"逐格 N/A 附已核实成因"），故 E1 不使任何格判为未满足；但它已被
`doc/design-prompt/milestone_restructure.md` §6.3 原样继承过一次，**该处（非冻结的
设计输入）已就地订正为 12**（REV-035 §Q2(c)：底板的价值全在可机械复算）。

### 10.2 两格 N/A 成因重写（M4 出口条件第二条要件）

`doc/spec.md` §0#4 与 `doc/milestone.md` M4 出口第二条要求 N/A 附**已核实的**成因。
被自己援引的数据源证伪的成因不是已核实的成因 ⇒ 下列两条为重写后的成因，**每条都由
原始报告正向支持**（不是"没被推翻"）。

**(A) `(lzc, Line)` N/A —— 成因重写**

- `lzc` 模块体内**唯一的过程块**是 `lzc.sv:56-60` 的 `always_comb : flip_vector`，
  它位于 `:54` `if (MODE) begin : g_flip` 之内。
- 本闭包的两个 `lzc` 实例——`rr_arb_tree.sv:202-205` `i_lzc_upper` 与 `:211-214`
  `i_lzc_lower`——**均传 `.MODE(1'b0)`**；urg 亲证本闭包只精化出两种参数变体
  `WIDTH=6,MODE=0` 与 `WIDTH=9,MODE=0`（`modlist.txt:53/54`）。故被精化的是 `:61-64`
  的 `g_no_flip` 分支（`assign in_tmp = in_i;`），`g_flip` 连同其 `always_comb`
  **未被精化**。
- 模块内其余语句全部是 generate 内的连续 `assign`（`:41/42/63/67/75/76-78/82/83/
  87/88/93-97/102/103`）⇒ `-cm line` 无过程语句可插桩 ⇒ **该模块页整节无 Line 数据**。
- **正向支持**：`modinfo.txt` L146860 起的 `lzc` 页实有节 = `Assert/Branch/Cond/
  Toggle`，**无 `Line Coverage for Module : lzc` 节**；`modlist.txt:48` Line 列 `--`。
- **判别式在全闭包上自洽**（REV-035 §G4 要求："要能同时解释哪些模块有该类节、哪些
  没有"）：判别式 = **该模块是否有至少一个被精化的过程块**（含宏展开）。
  无 Line 节的 10 个模块中，9 个（`axi_xbar`/`axi_xbar_unmuxed`/`addr_decode`/
  `axi_demux`/`counter`/`axi_multicut`/`axi_cut`/`spill_register`/`axi_pkg`）源码
  `always*` 计数为 **0**；`lzc` 是唯一"源码有、但被 generate 参数排除"的一例。
  反向：`stream_register` 源码 `always` 字面计数为 **0** 却**有** Line 节（75.00%）
  ——因 `FFLARNC` 宏展开出 `always_ff`（urg Line 表标 `ALWAYS 37`/`ALWAYS 38`）。
  两侧都被同一判别式解释。
- **同时订正原脚注 3 的因果预设**：原文设想"有意义代码落在 generate 分支的**过程块**
  里、只是 VCS 未生成 bin"。本闭包下 `lzc` **没有任何过程块被精化**，故不是"有 bin
  未统计"，而是**结构上无 bin 可生成**。
- **`(lzc, Cond)`/`(lzc, Branch)` 不是 N/A**：实测均 97.73%，由 `:76-78` 与 `:95-97`
  两处 `?:` 生成——urg `lzc` Cond 节的源码行号集合 = `{76, 95}`，Branch 节构造 =
  `TERNARY 76` / `TERNARY 95`。**§2.3 表中 `lzc` 行的逐格标记原本即正确**（仅 Line
  列标 `N/A³`），失真的只有脚注 3 的文字。
- **脚注 3 的 `counter` 部分成立、不受本条影响**：`counter.sv` 确为纯例化壳（全文
  仅 `:28-42` 一处 `delta_counter` 例化、无过程语句），`modinfo.txt` `counter` 页
  实有节仅 `Toggle` ⇒ Line/Cond/Branch/Assert 四类 N/A 判定与成因均成立。

**(B) `(stream_register, Cond)` N/A —— 成因重写**

- 判别式（**运算符种类**，不是语句形态）：本次 urg 运行的 `-cm cond` 口径**只对
  逻辑/条件运算符**（`&&`、`||`、`?:`，及作为其操作数修饰的 `!`）且**运行时操作数
  ≥2 项**的表达式生成 Cond bin；对 **(a) 单信号条件**、**(b) 按位运算符**
  （`&`、`|`、`~`，即便操作数只有 1 bit）**均不生成**。
- `stream_register` 两侧都落在"不生成"一边：
  - 该模块**唯二**的多操作数表达式是 `:34` `ready_o = ready_i | ~valid_o` 与
    `:35` `reg_ena = valid_i & ready_o`——用的是**按位** `|` / `&`，非逻辑
    `||` / `&&`。
  - 该模块**仅有**的条件语句来自 `:37`/`:38` 的 `FFLARNC` 宏展开，其条件
    （`!rst_ni`、`clr_i`、`ready_o`、`reg_ena`）**逐条都是单信号**——落在脚注 4
    已确立的规则里。
- **正向支持（同一份报告、同一次运行内的模块内对照，非跨模块类比）**：
  - `spill_register_flushable`：`:90` `!a_full_q || !b_full_q`（逻辑 `||`）**生成了**
    Cond bin；同一模块 `:93` `a_full_q | b_full_q`（按位 `|`）**没有**——该模块
    Cond 节的源码行号集合实测 = `{53,72,78,79,84,85,90,96}`，**93 不在其中**。
  - `lzc`：`:76`/`:95` 的 `?:` **生成了** Cond bin；同一模块 `:75` 与 `:93-94` 的
    按位 `|` **没有**——Cond 行号集合实测 = `{76, 95}`。
- **判别式在全闭包上自洽**（REV-035 §G4）：
  - **有 Cond 节的 11 个模块**——`axi_xbar_unmuxed`/`addr_decode_dync`/
    `axi_demux_simple`/`axi_demux_id_counters`/`axi_err_slv`/`axi_atop_filter`/
    `axi_mux`/`rr_arb_tree`/`lzc`/`fifo_v3`/`spill_register_flushable`——其**全部**
    Cond bin 的源码行（程序化逐行核对，共 31 个行号 **[勘误 E5 → §10：该数与其自称的机器来源不符——从 `modinfo.txt` 按 `Cond Coverage for Module : <mod>` 分节提取 `LINE <n>`（22 DUT 模块过滤）实为 **57** 个不同（模块,行号）对 / **53** 个不同行号；提取命令、分布与局限见 §10.5。结论"无一例外都含 `&&`/`||`/`?:`"不受影响——57/57 逐条回 RTL 均含。下文原文保留不改。]**）**无一例外**都含 `&&`/`||`/`?:`。
  - **无 Cond 节的 11 个模块**——精化后均无此类表达式：`counter`/`addr_decode`/
    `axi_demux`/`axi_multicut`/`axi_cut`/`spill_register`/`axi_id_prepend`/
    `stream_register` 源码 `&&`/`||`/`?:` 计数为 0（`stream_register` 只有按位
    `|`/`&`）；`axi_xbar`/`axi_demux` 的 `?:` 只出现在**参数声明**里
    （`axi_xbar.sv:65/185`、`axi_demux.sv:62/232`，编译期常量）；`delta_counter`
    仅有的两条逻辑运算（`:43` `clear_i || load_i`、`:45` `!overflow_q && en_i`）
    位于 `:29 if (STICKY_OVERFLOW)` 的 `gen_sticky_overflow` 分支内，而本闭包两个
    参数变体**均为 `STICKY_OVERFLOW=0`**（`modlist.txt:43/44`）⇒ 该分支未精化，
    精化部分（`:54-82`）条件全为单信号。
- **明确不采用脚注 4 的现成规则**（REV-035 §Q2(d) 硬警告 1）：脚注 4 的表述是
  "无多项布尔组合式 ⇒ 不生 bin"。它解释不了本格——`:34`/`:35` **是**二元组合式。
  本条把判别式收紧到**运算符种类**，才同时解释了 `spill_register_flushable:90`
  生成而 `:93` 不生成这一模块内对照。**脚注 4 对 `delta_counter` 的结论仍成立**
  （其精化部分确为单信号条件），只是其规则表述不足以推广。

### 10.3 8 条 N/A 成因脚注的正向抽样反证（REV-035 §Q2(d) 要求，成因维）

方法：对每条脚注至少取一格，用 `modinfo.txt` 机械导出"该模块页实有哪几个 Coverage
节"，与脚注声称的 N/A 类型**正向**比对（不是"看起来说得通"）。

| 脚注 | 抽样格 | 该模块页实有 Coverage 节（modinfo 亲取） | 结论 |
| --- | --- | --- | --- |
| 1 | `addr_decode` Line | `{Toggle}` | ✅ 成立（`addr_decode.sv` `always*` 计数 = 0，纯参数透传例化）。**另记一处措辞过宽**：末句"以上均只有 Toggle 有意义…Assert 无 bin"对 `axi_xbar`/`axi_xbar_unmuxed`/`axi_multicut` 不成立（三者 Assert=100.00），但 §2.3 表中这些格**并未标 `N/A¹`**，逐格标记全部正确 ⇒ 三态判定不受影响 |
| 2 | `rr_arb_tree` FSM | 全库 `FSM Coverage for Module :` 节**仅 1 个**（`modinfo.txt` L4406，属 `axi_atop_filter`） | ✅ 成立（其余 21 模块 FSM 无节） |
| 3 | `lzc` Line / `counter` Line | `lzc`={Assert,Branch,Cond,Toggle}；`counter`={Toggle} | ❌ **lzc 部分证伪 → E2/§10.2(A)**；counter 部分 ✅ |
| 4 | `delta_counter` Cond | `{Branch, Line, Toggle}` | ✅ 成立（无 Cond 节；成因经 §10.2(B) 的精化面复核仍立） |
| 5 | `stream_register` Assert | `{Branch, Line, Toggle}` | ✅ 判定与操作性成因成立（RTL 中 `assert` 计数 = 0）；括注失真 → E4 |
| 6 | `stream_register` Cond | `{Branch, Line, Toggle}` | ✅ 判定成立（无 Cond 节）；❌ **成因证伪 → E3/§10.2(B)** |
| 7 | `axi_id_prepend` Branch | `{Assert, Line, Toggle}` | ✅ 成立（无 Cond/Branch 节；`:82 if (PreIdWidth == 0)` 在 `for (genvar …)` generate 内、条件为参数常量；`:86-92` `always_comb` 体内无运行时条件） |
| 8 | `axi_pkg` Line | `{Assert}`，self-instances = 0 | ✅ 成立（`asserts.txt` `axi_pkg.wrap_boundary` 408 attempts / 408 real successes） |

**抽样结论**：8 条中 6 条成因正向成立；证伪 2 条（脚注 3 的 lzc 部分、脚注 6），
另发现 1 处不影响判定的失真括注（脚注 5）。**三态判定本身（哪些格是 N/A）
经 132 格逐格复算与 `modlist`/`modinfo` 完全一致，无一格判错**——这正是 BUG-0026
guard 那句话的第三次实例化："判定可以是对的，而摘要仍然误导人"。

### 10.4 §2.3 其余数字的复算结论（划定本勘误的边界）

- **22 模块 × 6 类 = 132 个数值**：与 `modinfo.txt` 各模块页 `SCORE` 行逐格复算
  **全部一致**，无第四处数值错误。
- **实例数列**：除 `counter`（E1）外，其余 21 行与 `modinfo.txt`
  `Module self-instances :` 逐行计数**全部一致**（`delta_counter`=108 正确）
  ⇒ E1 是单格错抄，**非整列失效**，故"例/实例数"列予以保留而非删除
  （REV-035 §Q2(c)：该列是 §2.3 与原始 `hierarchy.txt`/`modinfo.txt` 之间唯一的
  交叉核对锚点）。

### 10.5 机器可复算断言块（closer 复验入口）

下列每行 = `<勘误 id> <模块> <字段> <值>`，由本节表格逐条对应；closer 的复验命令
直接以 `modinfo.txt` / vendor RTL 校验之，**任一行与机器事实不符即红**。

```
ERRATA-FACTS
E1 counter self_instances 12
E2 lzc sections Assert,Branch,Cond,Toggle
E3 stream_register sections Branch,Line,Toggle
E4 stream_register rtl_assert_count 0
E5 cond_bins module_line_pairs 57
E5 cond_bins distinct_line_numbers 53
E6 axi_xbar assert_score 100.00
E6 axi_xbar_unmuxed assert_score 100.00
E6 axi_multicut assert_score 100.00
```

### 10.6 E5/E6 的可重放取数与结构等式（BUG-0063/0064 订正卡追记，2026-08-02·arch·L2）

**处置形态同 §10**：不覆写、不删除，只追加 + 就地标记。E5 就地标记落在 §10.2(B)
`:491`；E6 就地标记落在脚注 1。两者的 §10.1 表行、上方 `ERRATA-FACTS` 事实行同批补入。

**E5（BUG-0063）——`共 31 个行号` 的正确计数，自 `modinfo.txt` 现场重算**。取数命令
（只读，未 `make clean`、未 `make regress`、未写 `sim/out/`）：

```
python3 - <<'PY'
import re
DUT={"axi_xbar","axi_xbar_unmuxed","addr_decode","addr_decode_dync","axi_demux",
 "axi_demux_simple","axi_demux_id_counters","counter","delta_counter","axi_err_slv",
 "axi_atop_filter","stream_register","axi_mux","axi_id_prepend","rr_arb_tree","lzc",
 "fifo_v3","axi_multicut","axi_cut","spill_register","spill_register_flushable","axi_pkg"}
hdr=re.compile(r'^(\S+) Coverage for Module : (\S+)'); ln=re.compile(r'^\s*LINE\s+(\d+)\b')
metric=mod=None; pairs=set()
for r in open("sim/out/urgText6/modinfo.txt",encoding="utf-8",errors="replace"):
    m=hdr.match(r)
    if m: metric,mod=m.group(1),m.group(2); continue
    if metric=="Cond" and mod in DUT:
        x=ln.match(r)
        if x: pairs.add((mod,int(x.group(1))))
print(len(pairs),"pairs /",len({n for _,n in pairs}),"distinct lines")
PY
```

实测输出：`57 pairs / 53 distinct lines`。逐模块分布（不同行号数，和 = 57）：
`axi_atop_filter` 19 · `rr_arb_tree` 8 · `spill_register_flushable` 8 · `axi_demux_simple` 4 ·
`fifo_v3` 4 · `axi_demux_id_counters` 3 · `axi_mux` 3 · `addr_decode_dync` 2 · `axi_err_slv` 2 ·
`axi_xbar_unmuxed` 2 · `lzc` 2（**11 个模块有 Cond 节**，与 §10.2(B) 的模块枚举一致；6 个
SVA 模块 `axi_chan_sva`/`axi_xbar_{atop,route,stall,txlimit,worder}_sva` 也各有 Cond 节，
非 DUT 闭包成员，已被 22 模块过滤排除）。`spill_register_flushable`={53,72,78,79,84,85,90,96}、
`lzc`={76,95} 与 §10.2(B) 括注的两个子集**逐字一致**——缺陷严格限于"31"这个标量，
判别式与结论不受影响（57/57 逐条含 `&&`/`||`/`?:`）。

**E6（BUG-0064）——脚注 1 末句"Assert 无 bin"对三壳失真的事实**：`axi_xbar`/
`axi_xbar_unmuxed`/`axi_multicut` 的 Assert 得分均 **100.00**（§2.3 表逐格，源自
`modlist.txt`/`modinfo.txt` 各自 Assert 节），故"无 bin"不成立。**结构等式（本条要害，
钉"同构缺陷必须获得同形处置"而非某条事实）**：§10.3 判为失真的脚注 = {1,3,5,6}（4 条），
脚注侧就地 `[勘误 E… → §10]` 标记 = 脚注 3(E2)/5(E4)/6(E3) + 本条补的脚注 1(E6) = 4 条
⇒ **4 == 4**（本条补入 E6 前为 4 != 3）。可机器复算：
`grep -c '\[勘误 E[0-9]* → §10' <脚注 1-8 区段>` = 4（脚注侧标记数）。

**Q3 局限（须明写，不得默认可重放）**：E5 取数源 `sim/out/urgText6/modinfo.txt` 在
`.gitignore`（`sim/out/`）内、不受版本控制，且会被任何 `make regress` 删除
（`scripts/regress.py` 无条件 `make -C sim clean`，另见 BUG-0056/0066）。故本取数
**不满足七问 Q3"陌生人只凭仓库即可复现"**——这是 §10 全部以 urgText6 为源的断言
（E1–E6）共有的局限；E6 的三个 Assert 得分同源同限。closer 复验须在有该 vdb/urgText6
的机器上跑，或先按 §0 命令②从 `out/cov.vdb` 重生 `out/urgText6`（不 `make clean`）。
