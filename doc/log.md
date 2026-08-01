# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.25] 2026-08-01 REV-026 加固卡 B-1 落地——M1-01 叠加写向地址饱和序列，axi_mux/demux addr toggle 进一步收敛

**背景**：REV-026 批准清单 B-1（addr 饱和，(a)→M1-01）。DV 卡落地前先用
urg 亲自核实残余现状（不假设 A-1/A2 已顺带解决），发现 A-1/A2 是纯读，
`aw.addr` 在同样的位位置仍全 No——B-1 的真实缺口是"写方向从未独立加宽过
地址取值"。

**Done**
- **`tb/seq_lib.sv`**：新增 `slvport_waddr_sat_seq`，与已落地的
  `slvport_rdata_sat_seq`（A-1/A2）逐字节镜像，只是作用于 `aw`/`w` 而非
  `ar`——同一 lo/hi/lo 饱和地址构造搬到写方向，同样作为 M1-01 的第三趟
  fanout 叠加（不替换前两趟）。
- **testplan M1-01 行**在 A-1/A2 的 enrichment 句之后追加 B-1 的
  enrichment 句（未覆盖前者）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 确认改动只加不改；
  从 `make clean` 开始独立整跑全量回归确认 **29/29 PASS**；亲自生成
  merged urg 报告，独立核对 `axi_mux` Toggle **73.49%→76.93%**、
  `axi_demux_simple` Toggle **77.07%→80.45%**——与 DV 卡自报数字完全
  一致。DV 卡如实标注残余归属：字节对齐位 `addr[2:0]`（C-1 范围，非本卡）
  + 部分 `addr[28:31]` 区域窗口位（仅重配 rule 表或未命中/default-port
  路由才会翻转，属 B-3/M3-DE02/M4-RC01 范围）——未为凑数字越界处理。
- Evidence 刷新：`doc/evidence/v0.4.24/M1-01.log`。
- Taxonomy 自查：`make lint-diff` 前后站点数一致（77 个，行号偏移但
  站点集合逐点比对为空差集），确认未引入新 lint 类别，不重复登记
  BUG-0048。

**Not done**
- REV-026 剩余七项加固卡（C-1/D-1/B-2/E-1/B-3/C-2/F-1）+ BUG-0048
  fixer 卡未派发。M1-01 组的 A-1/A2/B-1 三项均已落地。

**Next**
- C-1（M1-01 sideband 属性/WRAP/长突发/稀疏 strb，含 KILL 注伤自证，
  REV-026 附两条硬条件）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对，
  均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.24] 2026-08-01 REV-026 加固卡 A-1+A-2 落地——M1-01 叠加地址镜像饱和读，axi_mux/demux r.data toggle 大幅收敛；顺手登记 BUG-0048（lint 基线过期）

**背景**：REV-026 批准清单 A-1/A-2（r.data 饱和，(a)→M1-01 合并卡）。技术
依据 M4-toggle-bit-decomposition.md：本环境读数据=地址镜像
（`predict_beat_data={beat_a,beat_a}`），故 all-0/all-1 饱和读序列即可
闭合 `axi_mux mst_resp_i.r.data[63:0]`/`axi_demux_simple
slv_resp_o.r.data[63:0]` 的逐位 toggle 缺口。

**Done**
- **`tb/seq_lib.sv`**：新增 `slvport_rdata_sat_seq`，在 M1-01 既有激励
  **之上叠加**（非替换）第二轮 fanout：每 slave 端口对每 master 端口各发
  低饱和（区间内地址位全 0）→高饱和（全 1）→低饱和的单拍读序列——
  lo/hi/lo 三段而非单一 lo→hi 对是刻意的：单一对只能证明一个 toggle
  方向，三段序列自身程序序即可独立完成双向翻转，不依赖其他 slave 端口
  并发流量的偶然交织。
- **testplan M1-01 行**按 REV-026 条件 2 显式列出 enrichment 维度文本
  （不是静默替换）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 确认改动只加不改
  （原 `slvport_basic_seq` 那趟 fanout 一字未动）；从 `make clean` 开始
  独立整跑全量回归确认 **29/29 PASS**；亲自生成 merged urg 报告，独立
  核对 `axi_mux` Toggle **62.55%→73.49%**、`axi_demux_simple` Toggle
  **72.56%→77.07%**——均为真实、显著提升，均未到 90%（DV 卡如实报告
  残余：`axi_mux` 剩 8 位是窄突发字节对齐位（C-1 范围）+ 2 位是仅
  M3-DE02/M4-RC01 default-port 路由才会翻转的地址位（不同场景范围，
  按"小闭环不堆 mega-edit"纪律未强行在本卡内解决），不为凑数字勉强）。
- Evidence 刷新：`doc/evidence/v0.4.23/M1-01.log`。
- **顺手登记 BUG-0048（TOOL_ENV，OPEN）**：DV 卡按纪律对自己改动的
  `tb/seq_lib.sv` 跑 `lint-diff` 做尽职检查，发现 `doc/lint-baseline.md`
  自 BUG-0040 的 2026-07-31 全量重同步后，六次 tb/ 落地（M4-EB01/BP02/
  BP02-w_open3-fix/BP03/本卡）从未重跑重同步步骤，累积 62-77 个新站点
  （0 新类别）。`git stash` 隔离确认与本卡自身改动无关、是既存漂移
  （BUG-0040 自己的 guard 早已预告"未来若不重跑会假绿"，这条正是该预告
  应验）。**orch 独立复核**：亲跑 `cd sim && make clean && make lint-diff
  TEST=m1_01_smoke_test`（本卡改动仍在工作区）确认 77 个新站点，数字
  与登记一致，非虚报。不阻塞 M4 覆盖率工作（lint 不在 `make check`/
  `make selftest` 门禁内）；已建后续 fixer 卡任务（closer≠fixer，逐站点
  分诊）。

**Not done**
- REV-026 剩余九项 (a)/(b) 加固卡（B-1/C-1/D-1/B-2/E-1/B-3/C-2/F-1）+
  BUG-0048 fixer 卡均未派发。

**Next**
- 继续 M1-01 组：B-1（地址饱和/rule 多样性）→ C-1（sideband 属性/WRAP/
  长突发/稀疏 strb，含 KILL 注伤自证）→ D-1（ready-delay 分布，视残余
  决定是否仍需要）。各自独立小闭环。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对 +
  BUG-0048 亲自复现，均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap。

## [0.4.23] 2026-08-01 REV-027 加固卡 B 落地——新场景 M4-BP03（AR 侧对偶），五件套一次性转正

**背景**：REV-027 §5「加固卡 B」+ M4-P0-remeasure.md §3 精确定位：
M4-BP02 是纯写场景，AR 侧对偶（`lock_ar`/`ar_id_cnt_full` 及其伴随的 3
条 valid-but-not-ready 断言）在全部既有场景里从未触达。派 L1 DV 卡落地。

**Done**
- **新 testplan 行 M4-BP03**（`doc/testplan.md`）：M4-BP02 的读方向对偶。
  单 slave 端口并发多笔读 burst（同桶）+ AR 持续背压（新增独立旋钮
  `bp_enable_ar`，`tb/mstport_agent.sv`，镜像 M4-AW01 的 `bp_enable`、
  默认关闭不影响任何既有场景）+ `resp_hold` 作用于 R 通道令同桶在飞读
  数压至 §5.4.1 有效上限。**无需新写驱动任务**——DV 卡指出一个干净的
  不对称性：写方向需要 `drive_burst_wopen` 是因为一个写子项的 W burst
  会在下一个 AW 出现前排空完，而读子项的整个请求阶段就是它的 AR 握手
  本身，既有 `drive_burst()` 非写分支早已背靠背连续发出 AR，读方向的
  持续压力从既有原语里自然落出，不必比照写向再造一个。
  `tb/functional_coverage.sv` 新增 `cg_ar_retry`（外部 valid/ready 观测，
  非判决，镜像 `cg_aw_retry`）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 逐文件读过，确认改动
  精确镜像既有 M4-AW01/BP02 模式、无越权；**从 `make clean` 开始独立
  整跑一次全量回归**确认 **29/29 PASS**；亲自生成 merged urg 报告，
  独立核对 5 项目标 gate 全部转正——`lock_ar_valid_q/_d`/`ar_id_cnt_full`
  在 `gen_slv_port_demux[0]` 实例转 Yes（确认是被本场景施压的那个实例，
  非巧合）；`ar_valid_stable`/`slv_ar_chan_stable`/`slv_ar_select_stable`
  三条 Assert 由 0 real-succeeded 转为各 22 次、0 failure。`axi_demux_simple`
  模块级聚合：LINE 91.86%→**100%**、BRANCH 88.89%→**100%**、
  ASSERT 71.43%→**92.86%**（=13/14，恰好符合预期——14 条中只剩
  `NoAtopAllowed` 在 baseline 下结构性 N/A，已在 cfgD 报告独立闭合，
  非缺口）、COND 79.31%→82.76%、TOGGLE 71.18%→72.56%。
- Evidence：`doc/evidence/v0.4.22/M4-BP03.log`（机械生成），
  `sim/regress/regress.list` 补行。
- **顺手补 feature-matrix**（L0 haiku 卡，独立复核）：新场景导致 chain
  audit 新增 1 个 gap（M4-BP03 无 feature-matrix 行），当场派卡补
  F-M4-07（镜像 F-M4-06 的读方向表述），`make check` 复核 gap 归零。

**Not done**
- REV-026 十项 (a) 加固卡均未派发——两张 REV-027 加固卡已全部落地，
  下一步转向 A-F 队列。

**Next**
- 开始 REV-026 十项 (a) 加固卡：优先处理全部合并进 M1-01 的一组
  （A-1+A-2/B-1/C-1/D-1，各自独立小闭环、不堆 mega-edit），再到
  M3-DE01（B-2/E-1）、M2-CFG01/M3-CFG02（B-3）、M2-AT01（C-2）、
  M3-DE02/M2-CFG01（F-1）。

**How verified**
- 见上"orch 独立复验"段——diff 审读 + 从零全量回归 + urg 逐字节核对
  三重独立复核，均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无残留
  gap（含新场景的 feature-matrix 行已补齐）。

