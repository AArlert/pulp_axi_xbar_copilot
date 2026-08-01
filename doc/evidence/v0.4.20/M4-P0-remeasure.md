# M4 P0 merge-remeasure — 全量 COV=1 合并重测（REV-026 强制前置）

首行重放：

```
cd sim && make clean && make regress COV=1   # 28/28 PASS
make cov TEST=m1_01_smoke_test               # baseline 拓扑合并（22 场景，out/urgReport）
make cov TEST=m3_cf04_cfgd_test              # cfgD（ATOPs=0，out/cfgD/urgReport）
```

**性质**：本文件是 REV-026「P0 merge-remeasure 为全体加固卡的强制第一步」
的兑现证据——纯度量微闭环，无新激励、无新期望值、无新场景行，只是把
`doc/evidence/v0.4.13/signoff-M4.md` 残余风险表的旧数字换成当前（含
M4-EB01/M4-BP02/CW-006/CW-007 落地后）真实数字。**本文件不作处置判断**
——只报数字 + 标"新增闭合"或"仍残留"，具体哪条加固卡该怎么写，由各自
DV 卡自己依据 REV-026 批准范围决定。

## 0. 数据完整性

`make regress COV=1` 28/28 PASS（含全部 M0-M4 场景）。baseline 拓扑合并
报告覆盖 22 个场景（28 减去 M0/`upstream_sanity` 与 cfgA-E 5 个独立
topology 场景，口径同 `M4-toggle-bit-decomposition.md` §0）。

## 1. 六类 baseline 合并聚合（`out/urgReport/dashboard.html`）

`SCORE 66.64 / LINE 81.20 / COND 72.46 / TOGGLE 48.14 / FSM 7.14 /
BRANCH 83.36 / ASSERT 81.46 / GROUP 92.71`

FSM 7.14% 全局恒定不变（与 v0.4.9/v0.4.13 历史数字逐位一致）——FSM 类
覆盖率缺口在整个设计里唯一有意义的来源是 `axi_atop_filter`（REV-017
环境约束书面豁免，已生效），非新缺口。

## 2. 逐模块新旧对照（旧数字来自 `doc/evidence/v0.4.13/signoff-M4.md`
§残余风险清单；新数字来自本次 baseline 合并报告，除标注外）

| 模块 | 类型 | 旧（v0.4.13） | 新（本次 P0） | 状态 |
|---|---|---|---|---|
| `axi_atop_filter` | L/C/Tgl/FSM/Br | 46/35/40/7.14/34.78 | 46.36/38.71/41.30/7.14/36.96（ASSERT 100） | 不变，REV-017 书面豁免已覆盖，非缺口 |
| `axi_xbar` | Toggle | 40.74% | **40.74%（原样未动）** | **仍残留**——`default_mst_port_i` 双向翻转未触达（F-1 对象）；`rst_ni`/`test_i` 部分已由 CW-006/CW-002 书面豁免覆盖 |
| `axi_xbar_unmuxed` | Assert | 53.85% | **100.00%** | **已完全闭合**（M4-AW01/M4-BP02 的下游背压机制顺带覆盖），非缺口 |
| `axi_demux_simple` | Line | 83.72% | **91.86%** | **已闭合**（≥90%） |
| `axi_demux_simple` | Cond | 72-76% | 79.31% | 仍残留，接近阈值 |
| `axi_demux_simple` | Branch | 77.78% | 88.89% | 仍残留，接近阈值 |
| `axi_demux_simple` | Toggle | （未量化，`补场景`） | 70.93% | 仍残留——内部控制寄存器 `w_open[3]`/`lock_ar`/`ar_id_cnt_full` 是其中一部分（REV-027 两张加固卡对象），属性/地址/strb 多样性是另一部分（A/B/C 类） |
| `axi_demux_simple` | Assert | 50% | **71.43%（10/14 real-succeeded）** | 仍残留但已精确定位——逐条见 §3 |
| `addr_decode_dync` | Toggle | 53-57% | 59.00% | 仍残留（B-3 对象） |
| `addr_decode_dync` | Branch | 83.33% | 83.33%（原样未动） | 仍残留，接近阈值（B-3 对象） |
| `axi_mux` | Toggle | 55-58% | 62.55% | 仍残留（A-1/A-2/B-1/C-1/C-2 对象；Line/Cond/Branch/Assert 均已 100%） |
| `axi_err_slv` | Cond | 83.33% | **100.00%** | **已闭合** |
| `axi_err_slv` | Toggle | 42-44% | 45.93% | 仍残留（E-1/B-2 对象；Line/Branch/Assert 均已 100%） |

## 3. `axi_demux_simple` Assert 逐条（14 条，10 real-succeeded，本次新增精确
定位，供 REV-027 两张加固卡验收判据直接引用）

Real-succeeded（>0，含 v0.4.13 未点名的 AW 侧 valid-but-not-ready 稳定性
断言——本次证实**已被 M4-AW01/M4-BP02 的下游背压顺带闭合**，非新债）：
`ar_select`(1647)、`aw_select`(1978)、**`aw_valid_stable`(292)**、
`internal_ar_select`(1029)、`internal_aw_select`(1510)、
**`slv_aw_chan_stable`(292)**、**`slv_aw_select_stable`(292)**、
`w_underflow`(548)、`validate_params.*`(132/132，elaboration-time，恒真)。

0 real-succeeded（4 条，逐条辨明性质，不笼统归为"缺口"）：
- **`NoAtopAllowed`**：`` `ASSUME(NoAtopAllowed, !AtopSupport && aw_valid |-> aw.atop=='0) ``
  （`axi_demux_simple.sv:505`）——前提 `!AtopSupport` 在 baseline
  （`ATOPs=1`）恒假，本报告内结构性不可达属正常；**已在 cfgD
  （`ATOPs=0`，M3-CF04）独立报告中 real-succeeded 24 次**（`make cov
  TEST=m3_cf04_cfgd_test` 核实，见 `out/cfgD/urgReport`）——**非缺口**，
  不需要新卡。
- **`ar_valid_stable`**/**`slv_ar_chan_stable`**/**`slv_ar_select_stable`**
  （AW 侧三条的 AR 镜像）：**真实缺口**——AR 侧从未被下游背压触达。与
  0.4.19 `doc/review/REV-027.md` §2.5 用真库核实的
  `lock_ar_valid_q/_d`/`ar_id_cnt_full` 全 7 实例 `No` 同根：现有 28 个
  场景里**没有任何一个**对 AR 侧的下游 `ar_ready` 施加过持续背压。
  REV-027 加固卡 B（AR 侧对偶新场景）落地后，这三条连同
  `lock_ar_valid_q/_d`/`ar_id_cnt_full` 应一并转正——**同一个构造闭合
  五个独立缺口**（3 条 Assert + 2 组 Toggle 位）。

## 4. 结论（机械记账，不含处置判断）

- **已完全闭合、无需再派卡**：`axi_xbar_unmuxed` Assert（100%）、
  `axi_demux_simple` Line（91.86%）、`axi_err_slv` Cond（100%）、
  `axi_demux_simple` 内 `NoAtopAllowed`（cfgD 已闭）。
- **REV-026 批准清单十项 (a) 加固全部仍有真实残留**，无一项因"合并后已
  自然闭合"而作废——`doc/evidence/v0.4.20/M4-P0-remeasure.md`（本文件）
  即 REV-026 条件 1 的兑现证据，各卡按原批准范围继续派发。
- **REV-027 两张加固卡的验收判据可加精**：加固卡 B（AR 侧对偶）除
  `lock_ar_valid_q/_d`（No→Yes）/`ar_id_cnt_full`（No→Yes）外，
  **一并**验收 `axi_demux_simple` 的 `ar_valid_stable`/
  `slv_ar_chan_stable`/`slv_ar_select_stable` 三条 Assert（0→>0
  real-succeeded）——五件套同一个构造闭合，非额外工作。
