# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

