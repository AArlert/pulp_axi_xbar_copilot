# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.4.18] 2026-08-01 M4-EB01/M4-BP02 落地转绿——两张 DV 卡并行 worktree 实现，独立复验+合并冲突手工消解

**背景**：清单 B 批准清单里的两条新场景（err_slv B 通道背压 / demux 锁定
FSM+ID 计数饱和叠加压力）互相独立、非 merge-gated，用两个并行 worktree
隔离的 DV 卡实现，避免同时编辑共享 tb/ 文件互相踩踏。

**Done**
- **M4-EB01（独立 worktree，DV 卡）**：新增 `slvport_eb01_seq`/
  `m4_eb01_errbp_vseq`/`m4_eb01_errbp_test`，`axi_burst_item` 加
  `b_backpressure` 字段，`slvport_driver`/`slvport_monitor` 实现 B 通道
  持续背压 + `cg_errbp` 非空转见证。判决门复用 M3-DE01 的
  `SB_DECERR_*` 判据族（不新发明期望值）。**orch 独立复验**：亲跑
  `make run TEST=m4_eb01_errbp_test SEED=1` 确认 `UVM_ERROR:0`、
  svacheck CLEAN、`resp match=60 mismatch=0`、`cg_errbp samples=564
  inst_cov=100%`（背压确实被激励到，非空转）；检查 diff 干净、无越权
  改动。DV 卡如实指出卡片指示的文件名有误（`mstport_agent.sv`应为
  `slvport_agent.sv`——err_slv 挂在 slave 侧非 master 侧），已自行纠正，
  未盲从。
- **M4-BP02（独立 worktree，DV 卡）**：新增 `slvport_bp02_seq`/
  `m4_bp02_demuxlock_vseq`/`m4_bp02_demuxlock_test`，`axi_burst_item` 加
  `wopen_mode` 字段 + 滑动窗口驱动 `drive_burst_wopen`（保持 ≥3 个 W
  burst 同时打开）+ 复用 M4-AW01 的 `aw_ready` 背压机制 + 复用
  M2-TL01/M3-TL01 的 `resp_hold` 机制把同桶在飞数压至 §5.4.1 有效上限
  15。**orch 独立复验**：亲跑确认 `UVM_ERROR:0`、CLEAN、
  `route/resp/worder match=15 mismatch=0`、`cg_tx_limit inst_cov=100%`
  （含 `at_effective_ceiling=15` bin）、`cg_aw_retry samples=15
  inst_cov=100%`。DV 卡顺手报告了内部 RTL 事实（xdebug，仅供参考非判决
  依据）：`w_open` 峰值 5、`lock_aw_valid_q` 22 次翻转、
  `aw_id_cnt_full` 曾置位——证明结构覆盖非空转。**Open risk**（DV 卡
  如实标注，非隐瞒）：`w_open[3]`（≥8）在基线 `MaxSlvTrans=6` 下结构性
  不可达（mux AW→W FIFO 封顶），是覆盖率豁免候选而非"需要更强激励"。
- **两个 worktree 独立编写、独立通过后，orch 合并回 master**：
  `doc/testplan.md`/`sim/regress/regress.list`/`sim/result_summary.txt`/
  `tb/test_lib.sv` 四处产生真实文本冲突（两卡各自新增行相邻/两卡各自
  新增 test class 相邻），手工消解——保留两条新增内容而非二选一（doc/
  testplan.md 两行都转 ✅ 各自 evidence 路径；regress.list/
  result_summary.txt 两个 TEST 都保留；test_lib.sv 两个 class 都保留）；
  `tb/axi_txn.sv`/`tb/seq_lib.sv`/`tb/slvport_agent.sv` 三个文件 git
  自动三路合并成功（无冲突，两卡分别新增的字段/函数/类互不重叠）。
  **合并后 orch 在主目录里重新独立验证**：单跑 M4-EB01/M4-BP02 各自仍
  CLEAN，全量回归 `make regress` **28/28 PASS**（较之前 26/26 净增两条，
  证明两个 worktree 的改动合并后确实互不干扰）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- `w_open[3]`（M4-BP02 open risk）尚未走 rev 裁决——是否登记为
  `doc/coverage-waivers.md` 的又一条 Kind-A（结构性不可达，`MaxSlvTrans`
  封顶导致），还是先按下不表，留给后续覆盖率复核时处理。
- 清单 B 剩余的 (a) 类加固（A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1）
  仍未动手——这些都会触及 M1-01/M2-AT01/M3-DE01/M2-CFG01 等既有场景的
  共享激励代码，按 REV-026 条件 6 的"小闭环、非并行"要求排队处理。

**Next**
- 用户表态继续多 subagent 开工；下一批可考虑：(1) 派 rev 卡处置
  `w_open[3]` 覆盖率豁免；(2) 开始清单 B 的 (a) 类加固——因需触及共享
  激励文件，建议串行（pipeline）而非 worktree 并行处理，逐条走"小闭环
  即停"。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口类别。
- `make selftest`：61/61 OK。
- 两张 DV 卡各自独立 worktree 内均已验证转绿（orch 亲跑，非采信自报）；
  合并后主目录里对两个场景分别单跑复核仍 CLEAN；全量回归 28/28（含
  M4-EB01/M4-BP02），交叉核对 `sim/result_summary.txt`。

## [0.4.17] 2026-08-01 清单 B 分诊 + rev 门禁应用——注册 M4-EB01/M4-BP02，登记 CW-006/007；orch 独立复核纠正"P0 merge-remeasure"前提错误

**背景**：用 Workflow 派 arch 把清单 B（Toggle 定向覆盖缺口）分诊成"(a) 扩充
既有场景/(b) 新 testplan 行"两类提案，再派独立 rev 门禁审核（REV-026，
CONDITIONAL PASS）。

**Done**
- **arch 分诊**：清单 B 六类（A-F）逐条给出 (a)/(b) 归属 + 具体构造思路；
  新增两条 testplan 行草案（M4-EB01：err_slv B 通道背压，非 merge-gated；
  M4-BP02：demux 锁定 FSM + ID 计数饱和，arch 原判 merge-gated）；
  `rst_ni` 运行中复位给出二选一建议（范围豁免 vs 造一个"空闲窗口热复位"
  新场景），不自行拍板；顺手核实 size[2] 转正前置（全配置 DATA_W=64）。
- **REV-026（独立 rev 实例）门禁**：CONDITIONAL PASS。批准 A-1/A-2/B-1/
  B-2/B-3/E-1（(a) 加固，无新判决维度）；C-1 需修改后批准（预测器扩展
  须做 KILL 注伤自证+期望锚 AXI4 非 RTL，enrichment 须显式列入 testplan
  行禁静默改激励）；C-2 批准附残余上报纪律（exotic ATOP 编码走
  SPEC_ISSUE，不现场解释）；M4-EB01 批准可直接派；M4-BP02 批准为条件
  注册；**独立裁决 rst_ni**——采纳范围豁免（CW-006），**明确驳回**
  "造一个空闲窗口热复位场景"这个方案（判定其为"toggle-theater"：构造性
  保证零在飞、不测试任何有意义的复位语义，纯粹为翻一个 toggle 位造场景，
  违反"目标即门"纪律）；size[2] 独立复核确认转正前置已解。
- **orch 独立复验并发现一处重要premise错误**：REV-026 把"P0 merge-
  remeasure"定为全体加固卡的强制前置（理由：怀疑 M2-TL01/TL02/M3-TL01/
  M4-AW01/M3-DE02/M2-CFG01 等场景的覆盖率数字未被合并进基线报告）。
  orch 独立核查 `sim/Makefile` `COV_DIR` 解析逻辑 + `sim/regress/
  regress.list` + `doc/testplan.md` 各行拓扑列，证实：**这个前提是错的**
  ——这 6 个场景全部是 baseline 拓扑（`COV_DIR` 默认走同一个
  `out/cov.vdb`），且全部在 `regress.list` 里，`make regress COV=1`
  会把它们的覆盖率累积合并进同一份数据库；`doc/evidence/v0.4.15/
  M4-toggle-bit-decomposition.md` 引用的 `urgReport_baseline` 报告本就是
  这次合并后的产物（`make cov TEST=m1_01_smoke_test` 只是借用一个基线
  拓扑成员的名字去解析已合并数据库的路径，不是"只测了 m1_01 一个"）。
  **结论：不需要另跑一次"合并重测"——现有残余数字已经是真实合并后数字**，
  `lock_aw/ar` FSM 与 `w_open[3:2]` 的缺口是确凿的、可以直接注册
  M4-BP02，不必等待一个实际上已经做过的步骤。
- **orch 应用**：`doc/testplan.md` 注册 M4-EB01（🔲）+ M4-BP02（🔲，
  行文本按 arch 草案 + 前提纠正说明）；`doc/coverage-waivers.md` 新增
  CW-006（`rst_ni` 运行中复位范围豁免）+ CW-007（`size[2]` 总线宽度上限
  位，转正）；`doc/review/REV-026.md` 落盘。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- M4-EB01/M4-BP02 均只是**注册**（🔲），尚未实现——下一步要派 DV 卡写场景。
- 清单 B 的 (a) 类加固（A-1/A-2/B-1/B-2/B-3/C-1/C-2/D-1/E-1/F-1）均未
  动手——已有明确构造思路，等待 DV 卡逐条落地。
- CW-006 平行的 spec §2.3 条款订正（P-REV026-1）未走——REV-026 明确这是
  独立门禁、非 CW-006 生效阻塞，可稍后处理。
- `spill_register` tie-off 的 Kind-A 论证仍待建档。

**Next**
- 派多个 DV 卡实现批准清单：M4-EB01/M4-BP02 两条新场景（相互独立，可
  并行）；M1-01 目标的多项 (a) 加固（A-1+A-2/B-1/C-1/D-1）因同时触及
  同一份激励代码，按"小闭环、非并行"顺序处理；M2-AT01（C-2）/M3-DE01
  （B-2+E-1）/M2-CFG01+M3-CFG02（B-3+F-1）等目标不同场景的加固可与
  M4-EB01/M4-BP02 并行。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口（testplan 新增
  2 行计入既有 feature-matrix gap 类别，非新增 gap 类型）。
- `make selftest`：61/61 OK。
- orch 独立核查 `sim/Makefile` COV_DIR 解析逻辑（`ifeq ($(TEST),
  upstream_sanity)` 分支外一律走默认 `out/cov.vdb`）+ `grep` 确认 6 个
  场景均在 `regress.list` + `doc/testplan.md` 拓扑列均为 baseline，
  纠正 REV-026 的 merge-premise 错误，证据充分、可复核。

