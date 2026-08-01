# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.4.19] 2026-08-01 REV-027——w_open[3] 覆盖率豁免驳回（非结构不可达，是激励产物），顺带查出 M4-BP02 只闭合 AW 侧、AR 侧对偶缺口仍开

**背景**：0.4.18 遗留的 open risk——DV 卡称 w_open[3]（值≥8）在基线
`MaxSlvTrans=6` 下"结构性不可达"、建议 Kind-A 豁免。用户授权 orch 全权
派卡裁决。派发一张 L3 rev 卡（独立首过，opus，全 rubric），只给一手材料
文件/行号清单，不带任何一方结论（含 26 条 make guards 命中，Hard/Context
分栏逐字粘贴）。

**Done**
- **rev 独立裁决完毕，doc/review/REV-027.md**：**驳回豁免**（不登记任何
  coverage-waivers.md 条目，CW-008 保留未用）。核心发现：w_open 是
  demux 内部"W 解复用控制计数器"（4 位，由 `MaxMstTrans=10` 定宽），RTL
  门仅在满量程 15 设限，**不在 8**；spec §5.4.2"基线见证达 8>6"讨论的是
  另一个计数器（每桶 AW ID 计数器，pop 于 B），**不是** w_open（pop 于
  W）——DV 卡的转述张冠李戴。w_open 真实上界 = 下游 AW 吸收深度（mux
  w_fifo 深度 6 + demux→mux `axi_multicut` spill 容量 2 + demux 自身
  lock 1 ≈ 8~9），且随 `LatencyMode` 逐 config 浮动（cfgB 更宽）——结构
  上足以翻 bit3，非结构常量。观测峰值 5 = 驱动 `drive_burst_wopen` 自设
  `LEAD=MaxSlvTrans-1` 的产物（基于"LEAD≥mux FIFO 深度即死锁"这一**不
  准确**的前提——mux w_fifo 满是可恢复背压，W 末拍无条件弹出、与 full
  无关）。Kind-A 举证责任未尽；Kind-B 被 BUG-0047 guard + REV-024 §4
  （控制/计数位排除在外）双重禁止。
- **rev 亲自重跑取数**：裁决开始时 sim/out 是未带 COV=1 的空壳（同
  KILL-0004 型号），亲自 `make clean && make regress COV=1`（28/28
  PASS）后从真实 merged 基线 vdb 用 `urg` 取逐位 toggle（本机 xcov 因
  Verdi 版本早于受测基线不可用，记 TOOL_ENV、非阻塞）。
- **顺带查出（rev Q5 核实）**：M4-toggle-bit-decomposition.md 原把
  `lock_aw/ar`、`aw/ar_id_cnt_full` 成对列为缺口，M4-BP02 是纯写场景，
  **只闭合了 AW 侧**（`lock_aw_valid_q/_d` 全 7 实例 Yes、`aw_id_cnt_full`
  受压端口 Yes、`w_open[2:0]` 全 Yes）；**AR 侧（`lock_ar_valid_q/_d`、
  `ar_id_cnt_full`）全 7 实例仍为 No，完全未闭合**——0.4.18 未点出这一半
  缺口，本次据真库补记。
- **taxonomy-class anomaly（rev 强制字段）**：否——w_open[3]/lock_ar/
  ar_id_cnt_full 是覆盖率缺口（零 mismatch、无 checker 见红），非
  failure_taxonomy 五类失败，不开 bugs.md 行；DV 转述的两处事实性偏差
  （"结构不可达"框架、"LEAD≥FIFO 即死锁"注释）是本次裁决订正的评审发现，
  非 DUT/TB/工具/spec/约束缺陷，M4-BP02 场景本身判决无泄漏、功能正确。
- **rev 交付 guidance（不写激励代码）**：排两张独立"需补场景"DV 卡，供
  orch 后续按 REV-024 §2 既定处置排队派发——加固卡 A（写向，关
  `w_open[3]`）：把 LEAD 从 `MaxSlvTrans-1` 经验性提高到真实下游吸收深度
  （≈8，须探定安全上界而非盲设常数，LEAD 推导只准用 Cfg 参数+经验探测，
  不得抄 RTL 内部信号值）；加固卡 B（读向，关 `lock_ar`/`ar_id_cnt_full`）
  ：AR 持续背压 + 读桶在飞数压至 §5.4.1 有效上限，判决门复用既有读向
  判据。两卡均不占用 coverage-waivers.md 条目。
- **定级 vs 实际**：L3/opus/全 rubric 与实际工作量相符（多文件 RTL/spec
  交叉推导 + 独立取数复验），无失配。
- 首轮派发因 orch 自己给的 Workflow 结构化输出 schema 设计缺陷
  （`taxonomy_anomaly` 字段声明为"必填+可空对象"，subagent 工具调用层
  反复无法满足校验，5 次重试耗尽后 workflow 报错退出）导致一次空跑；
  rev 的实际投入（186807 tokens、63 次工具调用、约 23 分钟）**并未浪费**
  ——doc/review/REV-027.md 已被完整写出（非结构化回传失败与审阅记录落盘
  是两件独立的事），orch 从磁盘上的记录文件直接读取裁决全文，未采信任何
  转述。schema 已改为扁平字段（去掉嵌套可空对象）供下次复用，但本次未
  重新触发 agent 调用（记录已存在，无需重跑）。

**Not done**
- 加固卡 A/B（w_open[3] 写向、lock_ar/ar_id_cnt_full 读向）尚未派发——
  按"小闭环即停"原则，本轮只完成裁决闭环，派发留给下一轮。
- 清单 B 剩余 (a) 类加固（A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1）仍未
  动手，需串行处理（REV-026 条件 6）。

**Next**
- 派发加固卡 A（w_open[3]，写向 LEAD 加深）与加固卡 B（AR 侧对偶缺口）
  ——两者互相独立、不触碰同一 seq 类的同一段代码（A 改 drive_burst_wopen
  的 LEAD 计算，B 是新读向场景），但均触及 tb/seq_lib.sv/slvport_agent.sv
  等共享文件，按 REV-026 条件 6 精神串行排队，不并行 worktree。
- 之后再回到清单 B 剩余 (a) 类加固。

**How verified**
- rev 亲自 `make clean && make regress COV=1`（28/28 PASS）+ `urg` 真库
  逐位 toggle 核对，非采信任何转述（doc/review/REV-027.md §0/§2.5）。
- orch 独立复核：确认 doc/review/REV-027.md 已完整落盘（六问结构齐备、
  Overall verdict 明确），未采信失败的 StructuredOutput 回传碎片。
- `make check`/`make selftest` 本轮收尾前复跑（见下）。

