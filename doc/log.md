# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.4.22] 2026-08-01 REV-027 加固卡 A 落地——M4-BP02 写向 w_open[3] 转正，LEAD 深度经验安全上探

**背景**：REV-027 驳回 w_open[3] 豁免、判定其是驱动 LEAD 窗口过保守的产物
而非结构不可达，给出加固方向（LEAD 从 MaxSlvTrans-1 抬高到真实下游吸收
深度）。派 L1 DV 卡（sonnet）落地，dv 独立读 REV-027 全文取技术依据，本卡
不代其转述。

**Done**
- **`tb/slvport_agent.sv`**：`drive_burst_wopen` 的 `LEAD` 由固定
  `MaxSlvTrans-1`（=5）改为 `MaxSlvTrans + 2*PipelineStages + 1`（=9，
  只用 Cfg 参数推导，不抄 RTL 值）。**经验探测过程**（每步套 `timeout`
  防止真死锁）：LEAD=6..10 全部干净结束、跨 SEED=1/2/3/42 完成时刻
  逐位一致（确定性非运气）；**LEAD=11 触发驱动任务自死锁**，被
  `tb_top` 自带 watchdog 安全捕获（`UVM_FATAL`，非真挂起）——证实这是
  单线程"先开窗后排空"驱动任务自身的阈值，非 DUT 死锁，与 REV-027 的
  判断一致。最终值留 1 笔余量于探得安全上限（10）、2 笔余量于首次失败
  点（11）。
- `tb/seq_lib.sv` 同步订正两处随之过时的旧注释（不再声称 LEAD 卡在 mux
  FIFO 深度下）。
- **orch 独立复验**（不采信 DV 卡自报）：`git diff` 确认改动只有 3 个
  文件、36 行，外科手术式；单跑 `make run TEST=m4_bp02_demuxlock_test
  SEED=1` 确认 `UVM_ERROR:0`、`SB_SUMMARY` 全零 mismatch、svacheck
  PASS；**从 `make clean` 开始独立整跑一次全量回归**（不复用 DV 卡自己
  的构建产物）确认 28/28 PASS；亲自生成 merged urg 报告，逐字节核对
  `axi_demux_simple` 实例 0（本场景施压的实例）的 `genblk1.w_open[3:0]`
  三列 toggle 状态**全 Yes**（此前 baseline 下该实例与其余实例一样
  `w_open[3]=No`）——`w_open[3]` 转正证据独立复核，非采信转述。
  `axi_demux_simple` 模块级 Toggle 聚合由 70.93%（P0 基线）微升至
  71.18%（符合预期——本卡只关一个 bit，不是全部残余）。
- Evidence 刷新：`doc/evidence/v0.4.21/M4-BP02.log`（`make evidence`
  机械生成，非手写），testplan M4-BP02 行证据路径同步更新，判决门/红线
  正文未变。

**Not done**
- REV-027 加固卡 B（AR 侧对偶：`lock_ar`/`ar_id_cnt_full` + 3 条 AR 侧
  valid-but-not-ready 断言，五件套）尚未派发。
- REV-026 十项 (a) 加固卡均未派发。

**Next**
- 派发加固卡 B（AR 侧对偶新场景）。

**How verified**
- 见上"orch 独立复验"段——单场景 + 从零全量回归 + urg 逐字节核对三重
  独立复核，均未采信 DV 卡自报数字。
- `make check`/`make selftest`（61/61）本轮复跑绿，chain audit 无新增
  gap 类别。

## [0.4.21] 2026-08-01 P0 全量合并重测完成，精确核出十项加固卡当前真实残余（doc/evidence/v0.4.20/M4-P0-remeasure.md）

**背景**：REV-026 强制要求全体 (a) 加固卡派发前先做一次全量 COV=1 合并
重测，用当前（含 M4-EB01/BP02/CW-006/007 落地后）真实数字定各卡精确
scope，而非沿用 v0.4.13 旧 signoff 的过时残余风险表。

**Done**
- `cd sim && make clean && make regress COV=1`：**28/28 PASS**（含全部
  M0-M4 场景）。baseline 拓扑合并报告（22 场景）+ cfgD 独立报告，逐模块
  对照旧 v0.4.13 残余风险表，写入
  `doc/evidence/v0.4.20/M4-P0-remeasure.md`（纯记账，不含处置判断）。
- **确认已完全闭合、无需再派卡的三项**：`axi_xbar_unmuxed` Assert
  53.85%→**100%**（M4-AW01/BP02 的下游背压顺带闭合）；`axi_demux_simple`
  Line 83.72%→**91.86%**；`axi_err_slv` Cond 83.33%→**100%**。
- **确认 REV-026 批准的十项 (a) 加固全部仍有真实残留**，无一项因合并后
  自然闭合而作废——各卡按原批准范围继续派发（P0 本身即 REV-026 条件 1
  的兑现证据）。
- **精确定位 axi_demux_simple 14 条 Assert 中 4 条 0-real-success 的
  逐条性质**：`NoAtopAllowed` 在 baseline（ATOPs=1）结构性不可达属正常，
  已在 cfgD（ATOPs=0，M3-CF04）独立报告中 real-succeeded 24 次，**非
  缺口**；`ar_valid_stable`/`slv_ar_chan_stable`/`slv_ar_select_stable`
  （AW 侧三条稳定性断言的 AR 镜像）**真实未闭合**——与 REV-027 §2.5 核实
  的 `lock_ar_valid_q/_d`/`ar_id_cnt_full` 同根，同一个 AR 侧持续背压
  构造应一并闭合这 5 项（3 Assert + 2 Toggle）。已更新任务清单：
  REV-027 加固卡 B 的验收判据据此加精。

**Not done**
- 十项 (a) 加固卡 + REV-027 两张加固卡均未派发——本轮只完成 P0 记账。

**Next**
- 开始逐条派发：优先 REV-027 加固卡 A（w_open[3] LEAD 加深，M4-BP02 上
  改动）与加固卡 B（AR 侧对偶，五件套一次闭合），再回到 A-F 十项，逐条
  小闭环、独立核实、evidence、closeout、push。

**How verified**
- `make regress COV=1` 亲跑 28/28 PASS；`make cov` 分别生成 baseline 与
  cfgD 报告，urg HTML 逐模块/逐断言亲读取数（非采信任何转述），取数命令
  见 `doc/evidence/v0.4.20/M4-P0-remeasure.md` 首行。
- `make check`/`make selftest` 本轮收尾前复跑（见下）。

## [0.4.20] 2026-08-01 feature-matrix 补齐 6 条 M4 行（chain audit gap 清零）+ P0 全量合并重测已在后台起跑

**背景**：用户授权 orch 全权自动推进 M4 到极致，每闭环推送，不中途请示。
按 REV-026 汇总清单，第一步是全体加固卡的强制前置——P0 merge-remeasure
（`make regress COV=1` 全量重跑，供后续各条 (a) 加固定精确范围）；与此
并行，先处理一张互不冲突（纯文档，不碰 tb/、不跑仿真）的 L0 卡，避免
干等。

**Done**
- **L0 文档卡（haiku，无 rev）**：`doc/feature-matrix.md` 补齐 F-M4-01~06
  六行，对应 M4-RC01/AW01/OV01/FT01/EB01/BP02。orch 独立复核：`git diff`
  确认只改了这一个文件、6 行纯新增；`make check` 复跑确认 chain audit 的
  "scenarios in no feature-matrix row" gap 由 6→0，无新增 gap 类别。
- **P0 merge-remeasure 已在后台发起**：`cd sim && make clean && make
  regress COV=1`（28 个场景，含 0.4.18 新增的 M4-EB01/BP02）。用于给
  REV-026 批准清单里的 A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1 十项
  (a) 加固卡定精确残余范围（先合并再定范围，REV-026 §汇总："这是 M4
  出口的正确下一动作"）。

**Not done**
- P0 合并重测本轮尚未跑完（后台运行中，跨轮次继续等待，完成后独立核对
  真实残余数字，非采信任何转述）。
- REV-026 批准清单里的十项 (a) 加固卡、REV-027 的两张读/写向补场景卡、
  以及最终 M4 签核卡均未派发——依赖 P0 结果定范围，本轮暂不能派。

**Next**
- P0 跑完后：逐条核对 v0.4.13 旧 signoff 残余风险表 + M4-toggle-bit-
  decomposition.md 的六类缺口，在当前（含 EB01/BP02/CW-006/CW-007）
  基线上哪些已经关闭、哪些仍残留，据此定十项加固卡的精确 scope，逐条
  派 DV 卡（同一目标 testplan 行的多项加固仍按 REV-026 条件 6 拆成独立
  小闭环，不堆 mega-edit），每卡独立核实+evidence+closeout+push。

**How verified**
- feature-matrix 补行：`make check` chain audit 段落亲跑核对（见上）。
- `make selftest` 本轮收尾前复跑（见下）。

