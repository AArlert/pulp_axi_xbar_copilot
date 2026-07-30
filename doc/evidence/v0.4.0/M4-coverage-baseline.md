# M4 六类覆盖率基线（测量记录，非 evidence.py 证据行）

首行重放（三条互相独立的命令，理由见 §5/§6 的多设计合并异常说明——
一次单纯的 `make regress COV=1` + `make cov` **不能**得到干净的基线数字，
必须按下列三组分别跑）：

```
# ① 基线拓扑合并六类（本报告 §2/§3/§4 的主数字来源，17 个 M1-M3 场景，
#   排除 upstream_sanity 与 m3_cf01~04；6x8 单一设计）
cd sim && make clean && \
  for t in m1_01_smoke_test m1_02_id_prefix_test m2_cfg01_reconfig_test \
           m2_or01_stall_test m2_or02_nonstall_test m2_or03_guard_test \
           m2_tl01_txlimit_test m2_tl02_slvtrans_test m2_wo01_worder_test \
           m2_at01_atop_test m3_de01_decerr_test m3_de02_default_test \
           m3_or04_order_test m3_or05_range_test m3_at02_atop_read_test \
           m3_tl01_xbucket_test m3_cfg02_reconfig_test; do \
    make run TEST=$t SEED=1 COV=1; \
  done && make cov

# ② M0 upstream sanity 单独（不同顶层 tb_axi_xbar，见 §5，不可与 ① 共用 cov.vdb）
cd sim && make clean && make run TEST=upstream_sanity SEED=1 COV=1 && make cov

# ③ 四个 M3 配置点各自隔离（见 §6，CM 命令行覆盖，未改任何文件）
cd sim && rm -rf out/cfgA out/cfgB out/cfgC out/cfgD
make run TEST=m3_cf01_cfga_test SEED=1 COV=1 CM="-cm line+cond+fsm+tgl+branch+assert -cm_dir out/cfgA/cov.vdb" && make cov OUT=out/cfgA
make run TEST=m3_cf02_cfgb_test SEED=1 COV=1 CM="-cm line+cond+fsm+tgl+branch+assert -cm_dir out/cfgB/cov.vdb" && make cov OUT=out/cfgB
make run TEST=m3_cf03_cfgc_test SEED=1 COV=1 CM="-cm line+cond+fsm+tgl+branch+assert -cm_dir out/cfgC/cov.vdb" && make cov OUT=out/cfgC
make run TEST=m3_cf04_cfgd_test SEED=1 COV=1 CM="-cm line+cond+fsm+tgl+branch+assert -cm_dir out/cfgD/cov.vdb" && make cov OUT=out/cfgD
```

上述三组均已亲跑（VCS-MX O-2018.09-SP2，本 VM）。原始 `urg` HTML 报告已存档到
scratchpad 供本卡撰写时查阅（未纳入版本库，属大文件产物）；本文数字全部逐条
从这些报告的原始 HTML 表格摘录。

## 0. 为什么不是一条 `make regress COV=1`

按卡片指示先亲跑了最直接的路径：`make regress COV=1`（22 个场景）→
`make cov`。**功能判决未受影响**（22/22 PASS，`svacheck.py --judge` 逐条
复核同为 PASS），但 `make cov` 的 `urg` 生成日志里出现两类合并异常
（详见 §5/§6，已登记 BUG-0037，OPEN）。因此改为按 §0 顶部三条命令分别
测量，逐条论据见 §5/§6。**这不是本卡自行判断"该不该修"——只是在拿到
可信数字前必须先看清楚发生了什么**；BUG-0037 是否修、何时修是 orch 的
后续判断。

## 1. 场景状态

`make regress COV=1`（原始一次性路径，22 个场景，含 `upstream_sanity` +
17 个 M1-M3 基线拓扑场景 + 4 个 M3 配置点）：**22/22 PASS**。

```
pulp_axi_xbar_copilot regression  date=2026-07-30  passed=22/22
PASS   upstream_sanity SEED=1
PASS   m1_01_smoke_test SEED=1
...(22 行全 PASS，无 UVM_ERROR，SB_SUMMARY 零 mismatch，见 sim/result_summary.txt)
```

随后按 §0 三组分别重新执行（18 次独立 `make run`，含 M0 的 1 次 + 基线
17 次 + 4 个配置点各 1 次），每条均用 `python3 scripts/svacheck.py --judge`
独立复核，**全部 PASS**（逐条列在下方，非汇总口径）：

| TEST | SEED | 判决 |
| --- | --- | --- |
| upstream_sanity | 1 | PASS |
| m1_01_smoke_test | 1 | PASS |
| m1_02_id_prefix_test | 1 | PASS |
| m2_cfg01_reconfig_test | 1 | PASS |
| m2_or01_stall_test | 1 | PASS |
| m2_or02_nonstall_test | 1 | PASS |
| m2_or03_guard_test | 1 | PASS |
| m2_tl01_txlimit_test | 1 | PASS |
| m2_tl02_slvtrans_test | 1 | PASS |
| m2_wo01_worder_test | 1 | PASS |
| m2_at01_atop_test | 1 | PASS |
| m3_de01_decerr_test | 1 | PASS |
| m3_de02_default_test | 1 | PASS |
| m3_or04_order_test | 1 | PASS |
| m3_or05_range_test | 1 | PASS |
| m3_at02_atop_read_test | 1 | PASS |
| m3_tl01_xbucket_test | 1 | PASS |
| m3_cfg02_reconfig_test | 1 | PASS |
| m3_cf01_cfga_test | 1 | PASS |
| m3_cf02_cfgb_test | 1 | PASS |
| m3_cf03_cfgc_test | 1 | PASS |
| m3_cf04_cfgd_test | 1 | PASS |

## 2. 六类总体基线（整个已编译设计，含 UVM 库/tb 脚手架，未按 DUT 范围过滤）

以下均取自各自 `urg` 报告的 "Total Coverage Summary" 行（`SCORE` 列为
VCS 加权综合分，不是六类之一，仅供参考；`GROUP` = functional covergroup，
按 REV-011 §3.3/milestone.md M4 裁决**不计入**本页机器判据，仅列出供
对照）：

| 集合 | 场景数 | LINE | COND | TOGGLE | FSM | BRANCH | ASSERT | GROUP(供参考) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **基线拓扑合并（M1-M3，6x8，本报告主数字）** | 17 | 80.85 | 71.20 | 47.66 | 7.14 | 82.94 | 78.88 | 89.58 |
| M0 upstream_sanity（单独，tb_axi_xbar，供对照） | 1 | 81.34 | 78.32 | 70.55 | 7.14 | 83.91 | 87.18 | n/a |
| cfgA（1×8，NO_LATENCY，单场景） | 1 | 70.04 | 54.21 | 28.09 | 7.14 | 73.60 | 56.99 | 31.54 |
| cfgB（6×1，CUT_ALL_PORTS，单场景） | 1 | 70.15 | 55.38 | 40.46 | 7.14 | 69.10 | 56.86 | 35.38 |
| cfgC（4×4，UniqueIds=1，单场景） | 1 | 77.41 | 59.18 | 34.59 | 7.14 | 77.88 | 64.62 | 31.54 |
| cfgD（4×4，稀疏 Connectivity，ATOPs=0，单场景） | 1 | 67.84 | 57.87 | 34.66 | （空白，见 §6） | 69.85 | 65.89 | 35.38 |

**注 1**：本表是"整个编译设计"的总百分比，包含 uvm_pkg、common_cells 全库
（不止 DUT 用到的部分因编译单元粒度而全部计入 line/toggle 分母）、
tb 侧脚手架代码。spec §0#4 的 DUT 范围口径（`axi_xbar` 及其强制内部子
模块）需要看 §3/§4 的按模块表，不能直接读本表数字当 M4 判据。

**注 2**：4 个配置点每个只有 **1 个场景**（各自 testplan 行只注册了 1 个
定向场景），数字天然低于 17 场景合并的基线——不是"配置点覆盖率差"，是
"单场景 vs 17 场景"的样本量差异，不可与基线行直接比较优劣。

**注 3**：FSM 在基线/M0/cfgA/B/C 四处均恰好是 **7.14%**，与场景数量、
场景种类无关（1 个场景与 17 个场景合并结果相同）——这不是巧合，根因见
§4 第 1/2 条：全设计里唯一贡献 FSM bin 的模块（`axi_atop_filter`）其
5/7 状态、19/20+6/8 迁移弧从未被触达，且触达与否与"跑多少个场景"无关，
只与"是否曾构造过某一类 ATOP 编码"有关（本仓库全部场景均未构造过）。
cfgD 该处空白是因为 `ATOPs=1'b0`（该配置点不例化 `axi_atop_filter`），
与"未跑到"无关，是结构性的（该模块根本不存在于这次编译中）——两种空白
成因不同，均如实标注。

## 3. 按模块细分（DUT 范围，spec §0#4 命名模块；数字取自 §0①命令产出的
基线拓扑 17 场景合并报告，逐实例列出）

### 3.1 axi_xbar（顶层 DUT）—— 1 例

| 类型 | 数值 | 备注 |
| --- | --- | --- |
| Line | 空白（无本体过程代码，纯 generate 例化） | |
| Cond | 空白 | 同上 |
| Toggle | 29.63%（54 bit 中 16 覆盖；1→0 方向仅 3.70%） | 详见 §4 第 4 条 |
| FSM | 空白 | 顶层自身无 FSM |
| Branch | 空白 | |
| Assert | 100.00%（attempted，"succeeded/matched" 未单独列于顶层，见 axi_xbar_unmuxed） | |

### 3.2 axi_xbar_unmuxed —— 1 例

| 类型 | 数值 |
| --- | --- |
| Line | 空白（纯 generate 例化壳，同 axi_xbar） |
| Cond | 100.00% |
| Toggle | 85.93% |
| FSM | 空白（自身无 FSM） |
| Branch | 100.00% |
| Assert | 53.85%（26 条 attempted 100%，但只有 14 条 real-succeeded；见 §4 第 5 条） |

### 3.3 addr_decode —— 12 例（6 slave 端口 × {AR 译码器, AW 译码器}）

| 类型 | 数值 |
| --- | --- |
| Line/Cond/Branch/Assert | **空白（结构性 N/A，见 §4 第 3 条 / BUG-0038）** |
| Toggle | 12 个实例区间 43.90% ~ 48.78%（见下表） |

| 实例 | Toggle % |
| --- | --- |
| gen_slv_port_demux[0].i_axi_ar_decode | 43.90 |
| gen_slv_port_demux[1].i_axi_ar_decode | 45.12 |
| gen_slv_port_demux[2].i_axi_ar_decode | 45.12 |
| gen_slv_port_demux[4].i_axi_ar_decode | 45.12 |
| gen_slv_port_demux[0].i_axi_aw_decode | 46.34 |
| gen_slv_port_demux[3].i_axi_ar_decode | 46.34 |
| gen_slv_port_demux[5].i_axi_ar_decode | 46.34 |
| gen_slv_port_demux[1].i_axi_aw_decode | 47.56 |
| gen_slv_port_demux[2].i_axi_aw_decode | 47.56 |
| gen_slv_port_demux[4].i_axi_aw_decode | 47.56 |
| gen_slv_port_demux[3].i_axi_aw_decode | 48.78 |
| gen_slv_port_demux[5].i_axi_aw_decode | 48.78 |

### 3.4 axi_demux —— 6 例（1 / slave 端口）

| 类型 | 数值 |
| --- | --- |
| Line/Cond/Branch/Assert | **空白（结构性 N/A，同 §3.3 成因，见 §4 第 3 条 / BUG-0038）** |
| Toggle | 62.01% ~ 63.19%（6 实例，见下表） |

| 实例 | Toggle % |
| --- | --- |
| gen_slv_port_demux[3].i_axi_demux | 62.01 |
| gen_slv_port_demux[2].i_axi_demux | 62.17 |
| gen_slv_port_demux[1].i_axi_demux | 62.32 |
| gen_slv_port_demux[4].i_axi_demux | 62.40 |
| gen_slv_port_demux[5].i_axi_demux | 62.40 |
| gen_slv_port_demux[0].i_axi_demux | 63.19 |

### 3.5 axi_mux —— 8 例（1 / master 端口）

全部 8 例的 Line/Cond(除#0)/Branch/Assert 完全一致（同一份未覆盖行清单，
见 §4 第 6 条），仅 Toggle 因端口流量分布不同而略有差异：

| 实例 | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- |
| gen_mst_port_mux[0].i_axi_mux | 72.41 | 100.00 | 56.73 | 空白 | 71.43 | 100.00 |
| gen_mst_port_mux[1].i_axi_mux | 72.41 | 85.71 | 56.38 | 空白 | 71.43 | 100.00 |
| gen_mst_port_mux[2].i_axi_mux | 72.41 | 85.71 | 58.49 | 空白 | 71.43 | 100.00 |
| gen_mst_port_mux[3].i_axi_mux | 72.41 | 85.71 | 57.64 | 空白 | 71.43 | 100.00 |
| gen_mst_port_mux[4].i_axi_mux | 72.41 | 85.71 | 58.63 | 空白 | 71.43 | 100.00 |
| gen_mst_port_mux[5].i_axi_mux | 72.41 | 85.71 | 58.63 | 空白 | 71.43 | 100.00 |
| gen_mst_port_mux[6].i_axi_mux | 72.41 | 85.71 | 56.24 | 空白 | 71.43 | 100.00 |
| gen_mst_port_mux[7].i_axi_mux | 72.41 | 85.71 | 55.33 | 空白 | 71.43 | 100.00 |

FSM 空白 = 该模块自身无 state_e 风格 FSM 构造（仲裁用组合 `rr_arb_tree`，
非本报告口径下的"FSM"对象），非缺口。

### 3.6 axi_err_slv —— 6 例（1 / slave 端口）

| 实例 | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- |
| gen_slv_port_demux[0].i_axi_err_slv | 100.00 | 83.33 | 42.37 | 空白 | 100.00 | 100.00 |
| gen_slv_port_demux[1].i_axi_err_slv | 100.00 | 83.33 | 43.04 | 空白 | 100.00 | 100.00 |
| gen_slv_port_demux[2].i_axi_err_slv | 100.00 | 83.33 | 42.81 | 空白 | 100.00 | 100.00 |
| gen_slv_port_demux[3].i_axi_err_slv | 100.00 | 83.33 | 43.78 | 空白 | 100.00 | 100.00 |
| gen_slv_port_demux[4].i_axi_err_slv | 100.00 | 83.33 | 42.81 | 空白 | 100.00 | 100.00 |
| gen_slv_port_demux[5].i_axi_err_slv | 100.00 | 83.33 | 43.93 | 空白 | 100.00 | 100.00 |

### 3.7 axi_atop_filter（未在 spec §0#4 明文列出，但由 `axi_xbar_unmuxed`
在 `ATOPs=1'b1` 时按每 slave 端口强制例化一次，"等"字兜底范围内；ATOPs=0
时不例化，见 cfgD）—— 6 例

| 实例（代表值，6 例几乎相同） | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- |
| gen_slv_port_demux[N].i_atop_filter（N=0..5） | 46.36 | 35.48 | 40.34 | **7.14** | 34.78 | 100.00 |

FSM 明细见 §4 第 1/2 条——本项目 M4 六类基线里**最大的单一缺口**。

## 4. 差距最大的具体缺口清单（按"越具体越好"要求，含信号名/行号/状态名；
全部来自 §0①命令产出的干净基线报告，逐条可查）

**1. `axi_atop_filter.w_state_q`（FSM，6 个 slave 端口实例同形）——
7 状态中仅 2 个被覆盖、20 条迁移弧中仅 1 条被覆盖**
- 已覆盖状态：`W_RESET`（axi_atop_filter.sv:338）、`W_FEEDTHROUGH`
  （:119）
- **从未覆盖**状态：`ABSORB_W`(:167)、`BLOCK_AW`(:151)、`HOLD_B`(:161)、
  `INJECT_B`(:163)、`WAIT_R`(:228)
- 已覆盖迁移：仅 `W_RESET->W_FEEDTHROUGH`
- **从未覆盖**迁移（19 条，节选关键几条）：
  `BLOCK_AW->ABSORB_W`(:190)、`ABSORB_W->HOLD_B`(:200)、
  `ABSORB_W->INJECT_B`(:202)、`HOLD_B->INJECT_B`(:210)、
  `INJECT_B->WAIT_R`(:228)、`INJECT_B->W_FEEDTHROUGH`(:230)、
  `WAIT_R->W_FEEDTHROUGH`(:239)
- **根因（读 tb 侧序列源码得到的事实陈述，不涉及任何 checker 期望值）**：
  `tb/seq_lib.sv` 中全部 ATOP 相关序列（M2-AT01 `:401/418`、M3-AT02
  `:1651/1685`）只使用同一个 `localparam` 编码
  `ATOP_LOAD_ADD`（`ATOP[5:4]=ATOMICLOAD`）——AtomicLoad 类操作**不带
  W burst**（AXI5 atomics 规则），因此 filter 的写侧从未见过一笔"既有
  W burst 又要求 R 响应"的原子操作（AtomicStore/AtomicCompare 类编码，
  `ATOP[5:4]=01` 或 `11`），`ABSORB_W`（吸收 W 数据）/`BLOCK_AW`（阻塞
  新 AW）/`HOLD_B`+`INJECT_B`（暂存/注入 B 响应）/`WAIT_R` 这条"需要
  同时处理 W 吸收与延后 B/R 协调"的路径因此从未被激励到。

**2. `axi_atop_filter.r_state_q`（FSM，同 6 实例）—— 4 状态中 2 个被
覆盖、8 条迁移弧中仅 1 条**
- 已覆盖：`R_RESET`(:336)、`R_FEEDTHROUGH`(:271)
- 从未覆盖：`INJECT_R`(:281)、`R_HOLD`(:275)
- 从未覆盖迁移：`R_FEEDTHROUGH->R_HOLD`(:275)、`R_HOLD->R_FEEDTHROUGH`
  (:304)、`R_FEEDTHROUGH->INJECT_R`(:281)、`INJECT_R->R_FEEDTHROUGH`
  (:295)、其余 2 条含 reset
- 根因同第 1 条——同一份 stimulus 缺口的另一半（读侧的"暂存/注入"路径
  同样需要 AtomicCompare 类编码才会触发）。

**3. `addr_decode`（12 实例）与 `axi_demux`（6 实例）—— Line/Cond/
Branch/Assert 四类结构性空白，仅 Toggle 有数（见 §3.3/§3.4 表）**
- 根因（读 RTL 得到的结构事实，未用于任何 checker 期望值，见
  BUG-0038）：`vendor/common_cells/src/addr_decode.sv`
  （109 行）整体只是对 `addr_decode_dync` 的参数透传例化，自身无
  `always_comb`/`case`/`for`；`vendor/axi/src/axi_demux.sv` 同理只
  例化 `axi_demux_simple`。这两个 spec §0#4 明文命名的模块，其"六类
  ≥90%"里的 4 类天生无法读到有意义的数字——真正的可覆盖逻辑在未被
  spec 明文列出的子模块里。已登记 BUG-0038（SPEC_ISSUE，OPEN，待 rev
  仲裁"等"字是否已经覆盖这两个子模块）。

**4. `axi_xbar`（顶层）Toggle 仅 29.63%（54 bit 中 16 个），且
"1→0" 方向仅 3.70%（27 bit 中仅 1 个）**
- 具体信号（"1→0: No" 即从未在运行期间被拉回 0/低电平）：
  `rst_ni`（全程只在 t=0 附近有一次 0→1，此后从未再被拉低——本项目
  回归里**没有任何"运行中二次复位/热复位"场景**，见 §5 covreset 说明）；
  `en_default_mst_port_i[5:0]`（M2-CFG01/M3-DE02/M3-CFG02 只把它从
  0 改到某个非零值，改完之后从未在同一次运行里再改回 0）；
  `default_mst_port_i[*][*]` 多个具体 bit 同理，只见 0→1、未见 1→0。
- `test_i` 全程 0（scan/test 模式从未被激励，符合预期，非缺口）。

**5. `axi_xbar_unmuxed` 内建 Assert：`default_aw_mst_port`/
`default_aw_mst_port_en`（6 个 slave 端口实例，逐实例列出）—— attempted
4542 次，real-succeeded **0** 次；对照同结构的 AR 侧
`default_ar_mst_port`/`default_ar_mst_port_en` 每实例 real-succeeded
48 次**
- 6 个实例（`gen_slv_port_demux[0..5].default_aw_mst_port` /
  `..._en`）逐一核对，数字完全一致：Attempts=4542, Real Successes=0,
  Failures=0（不是"failing"，是"从未真正 match/完成"）。
- 这与 M3-DE02 testplan 行本身记录的已知缺口同源
  （`tb/sva/axi_xbar_stall_sva.sv:99-100` 把 `en_default` 硬编码为
  `1'b0`，及 BUG-0025/BUG-0031 的既有讨论）——本条只是在 `urg` assert
  coverage 口径下的独立、可复现确认，不重复登记新 bug（同一根因的
  既有 OPEN/ACCEPTED@M3 债务）。

**6. `axi_mux`（8 实例同形）Line/Branch 缺口 —— `axi_mux.sv:293/
295-298/308-309/315.6`（AW 仲裁"下游背压后锁定重试"路径）从未执行**
- 未覆盖行：`293`(`mst_aw_valid = 1'b1`)、`295`(`if (mst_aw_ready)`)、
  `296-298`(`aw_ready`/`lock_aw_valid_d`/`load_aw_lock` 赋值)、
  `308-309`（`lock_aw_valid_d`/`load_aw_lock` 置位分支）、`315.6`
  （`lock_aw_valid_q <= lock_aw_valid_d` 时序更新）。
- 现象：`lock_aw_valid_q` 这条"仲裁已选中某 slave 但下游 `mst_aw_ready`
  当拍未就绪，需要锁定选择、下一拍重试"的路径，8 个 master 端口实例
  全部从未进入——意味着本回归环境从未在"mux 已经决定转发某笔 AW"的
  那一拍让下游 master 端口 agent 的 `aw_ready` 恰好为低。

## 5. covreset（VCS O-2018 合并共享覆盖率 DB 时丢弃异步复位 FSM 弧）
处理说明

**未触发该坑的前提条件本身就不成立**：`sim/regress/regress.list` 22
个场景里**没有一个是专门的"运行中复位"场景**——`§4 第 4 条`已经证实
`rst_ni` 在全部场景里都只在 t≈0 附近有一次 0→1（而且是每个 test
各自独立仿真、各自独立 t=0 复位一次，不是同一次仿真里的两次复位）。
`vcs-2018.mk` 头部描述的 `covreset` 模式针对的是"专门构造一个**运行
过程中**触发异步复位的测试，需要单独 `OUT=`、单独 merge"——本项目
回归里从未存在这样的测试，因此该坑在字面意义上"不适用"（无可 merge
的对象，而不是"合并了但被静默丢弃"）。**这是一个值得让 orch 知道的
事实性缺口而非本卡去处理的问题**：如果 M4 之后要专门构造一个热复位
场景，届时才需要真正验证 `covreset` 模式本身好不好用。

## 6. 多配置点 merge 处理说明

**踩中了，已登记 BUG-0037（OPEN）**。按卡片指示如实说明：

- 直接跑 `make regress COV=1` 后 `make cov`：`urg` 生成日志出现 825 行
  `Warning-[UCAPI-INSTANCEMISMATCH]`（4 个配置点与基线 6x8 结构不同的
  实例，如 `gen_mst_port_mux[3].i_axi_mux.gen_mux.i_aw_arbiter...` 的
  仲裁树深度随 `NoSlvPorts` 变化）+ 2971 行 `Warning-[CMR-VCINF]`
  （`upstream_sanity` 的 `tb_axi_xbar` 顶层与 `tb_top` 顶层结构完全
  不同导致的"instance not found"）。
- 根因：`scripts/make/vcs-2018.mk` 里 `CM := -cm ... -cm_dir
  $(OUT)/cov.vdb` 用 `:=` 在 include 时就已用默认 `OUT=out` 展开完毕；
  `sim/Makefile` 里 M3-CF01~04 的 `override OUT := $(OUT)/cfgA` 只
  改了构建产物路径（`simv`/`daidir`），改不动已经展开完的 `CM` 字符串
  ——四个配置点的覆盖率因此仍全部写入同一个 `out/cov.vdb`，`upstream_
  sanity` 与 `tb_top` 系列测试同理共享默认 `OUT`。VCS 自身对结构不匹配
  的 instance 采取"拒绝合并 + 警告"（安全网，不是静默算错），但这让
  "一次 `make regress COV=1` 就能拿到干净基线"这一假设不成立。
- **处理方式（本卡范围内，测量用途，未改任何 `sim/Makefile`/
  `scripts/make/vcs-2018.mk` 文件）**：
  1. 基线六类数字（§2/§3/§4）改为单独跑 17 个 M1-M3 基线拓扑场景
     （排除 `upstream_sanity` 与 4 个配置点），`make clean` 后逐个
     `make run TEST=... SEED=1 COV=1`，共享同一个干净 `out/cov.vdb`
     ——`make cov` 生成日志 **0 处 mismatch 警告**。
  2. `upstream_sanity` 单独 `make clean` + `make run ... COV=1` +
     `make cov` —— **0 处 mismatch 警告**，数字见 §2 表格对照行。
  3. 4 个配置点各自用 `CM="-cm line+cond+fsm+tgl+branch+assert
     -cm_dir out/cfgX/cov.vdb"` 命令行覆盖（`CM` 变量在 `sim/Makefile`
     里没有 `override` 修饰，命令行赋值可以正常压过 include 时的展开
     值——这是 make 变量优先级的正常用法，不是改文件）跑
     `make run`，各自 `make cov OUT=out/cfgX` —— 4 份报告均 **0 处
     mismatch 警告**，数字见 §2 表格。
- 是否需要分开报告：**是**——§2 表格把 17-场景基线、M0、cfgA/B/C/D
  分成 6 行分别列出，不做跨设计合并平均，避免用一个数字掩盖"这其实是
  6 个结构不同的设计各自的覆盖率"这一事实。

## 7. 结论边界重申

本文件只是测量记录：**不判定 M4 是否达标、不判定哪个缺口该由哪张卡去
补**。90% 门槛是否已达到、`addr_decode`/`axi_demux` 的 SPEC_ISSUE
（BUG-0038）与 BUG-0037 的处置顺序，均留给 orch 收到本报告后分诊。
