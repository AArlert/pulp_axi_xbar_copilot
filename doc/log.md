# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

## [0.4.16] 2026-08-01 逐位 Toggle 分解完成（Kind-B 前置兑现）——M4 阶段合法 Kind-B 豁免集为空集，转正 3 条 Kind-A（err_slv 恒定输出）

**背景**：REV-024 授权了 Kind-B（方法论受限、延后 M5）豁免路径，但明确"不
预先授予任何具体豁免，须先有逐信号/逐位 toggle 分解证据"。本周期用
Workflow 工具跑一套多 agent 流水线兑现这个前置：刷新覆盖率数据 → 4 模块
（axi_mux/axi_xbar/axi_demux_simple/axi_err_slv）并行逐位分解 → 每条
"载荷候选"由 3 个独立怀疑者做对抗性反驳投票 → 综合报告 → 独立 rev 复核
（REV-025）。

**Done**
- **覆盖率数据刷新**：核实并确认此前 sim/out 已因两次不带 COV=1 的
  make regress（KILL-0004 自证卡、M4 签核卡 falsification）变成非
  instrumented 空壳，干净重跑 make clean && make regress COV=1（26/26
  PASS）；基线聚合数字与 v0.4.9 逐位一致（LINE 80.84/COND 71.66/
  TOGGLE 47.87/FSM 7.14/BRANCH 82.99/ASSERT 78.62/GROUP 90.89，orch 独立
  核对 doc/evidence/v0.4.9/M4-coverage-baseline.md 表格逐位吻合），证明
  数据库确系真实 instrumented。
- **4 模块并行逐位分解**：每个模块独立读 urg Toggle Port Details 报告 +
  RTL 逐信号核实语义。关键发现——
  - `axi_mux` 是唯一被标"载荷候选"的模块：`mst_resp_i.r.data[63:0]`
    （散布 ~30/64 位未双向翻）。同模块 `mst_req_o.w.data[63:0]` 与
    `id[7:0]` 前缀+原ID 两段经核实**已 100% 覆盖、非缺口**，直接反驳
    REV-024 把 W/R.data 打包处理的假设。
  - `axi_xbar` 顶层核实"0 载荷位"——54 个 toggle 位全是窄控制/配置
    （clk/rst/test/en_default/default_mst_port），载荷 toggle 转移到子
    模块度量，无残余宽载荷缺口。
  - `axi_demux_simple` 写载荷 100% 覆盖，读载荷 87.5%（8 位残），主导
    缺口是属性字段（119/225 bin）与地址（67/225 bin），均非载荷类。
  - `axi_err_slv` 入侧写载荷 100% 覆盖；出侧发现三处**恒定常量输出**
    （`r.data=RespData`、`r.resp/b.resp=Resp`、`user` tie-off）——
    结构性 Kind-A，非 Kind-B。
- **对抗性核实**：唯一"载荷候选"（axi_mux R.data）被 3/3 独立怀疑者
  反驳——核心证据：TB `predict_beat_data` 返回 `{beat_a,beat_a}`（32-bit
  地址镜像拼成 64-bit），R.data 实际由读地址决定、并非不透明随机载荷；
  toggle 覆盖每位只需 all-0/all-1 两个饱和向量即可翻遍，根本不需要
  "扫大量互异取值"，故不满足 Kind-B 判据(2)"纯定向不经济"。
- **REV-025（独立 rev 实例）复核**：亲验 `axi_err_slv.sv`/
  `axi_xbar_unmuxed.sv`/`xbar_types_pkg.sv`/`mstport_agent.sv`/
  `seq_lib.sv` 具体行号，确认综合报告结论成立且比报告自述更强（R.data
  的判据(1)"纯载荷"本身也不成立，两判据双失）。Conditional pass，三条
  应用条件：仅新增 Kind-A A-1/A-2/A-3；size[2] 暂缓转正（须先确认 cfgA-E
  全部配置数据总线 ≤64 位）；订正报告一处内部措辞不一致。
- **orch 独立复验**（不采信自报）：亲读 `axi_err_slv.sv:23-27/145/
  188-198` 确认三个常量赋值点；亲读 `axi_xbar_unmuxed.sv:195-211` 确认
  两处例化点均未 override `RespData`；亲读 `xbar_types_pkg.sv:374-385`
  确认 `predict_beat_data` 返回值；亲读 `seq_lib.sv:32-35` 确认 wdata 用
  `$urandom` 随机填充；交叉核对覆盖率数字与 v0.4.9 基线逐位一致。
- **orch 应用**：`doc/coverage-waivers.md` 新增 CW-003/004/005（err_slv
  三条 Kind-A，引 REV-025）；Kind-B 模板行保留但注明"当前结论为空集"；
  待建档区新增 size[2] 条目（附暂缓理由）；`doc/bugs/BUG-0047.md` 标记
  逐位分解前置已完成、清单 B 已具体化到信号/位段级。产出
  `doc/evidence/v0.4.15/M4-toggle-bit-decomposition.md`（完整分解报告 +
  4 模块附录）+ `doc/review/REV-025.md`（仲裁记录）。
- `make check`/`make selftest`（61/61）复跑绿。

**Not done**
- **清单 B**（约 6 类具体信号/位段，已在证据文件里具体化到信号级）仍
  需逐条派 DV 定向覆盖卡——不因本次分解免除，反而更精确（如 axi_mux/
  demux 的 r.data 现在明确知道"定向饱和读 all-0→all-1 即可闭"，不再是
  笼统的"需补场景"）。
- size[2] Kind-A 候选转正前需要一次跨配置（cfgA-E）数据总线宽度确认。
- M4 仍未签核（REJECTED 判决未变，本轮工作是把"该走哪条路"这件事从
  猜测变成了有逐位证据支撑的确定结论——净结果是收窄了处置空间：没有
  Kind-B 可用，全部要么已覆盖、要么走 Kind-A、要么得真去补场景）。

**Next**
- 用户已完成本轮方法学张力优先项。下一步需用户决定：是逐条铺开清单 B
  的 DV 定向覆盖卡（现在已经有信号级精确指引），还是先处理 size[2] 的
  跨配置确认，或是先看其它待建档 Kind-A 项（`rst_ni`、
  `spill_register` tie-off）。

**How verified**
- `make check`：docs-check passed，chain audit 无新增缺口。
- `make selftest`：61/61 OK。
- 覆盖率数字交叉核对：本次刷新的基线聚合数字与 v0.4.9 报告逐位一致。
- REV-025 亲验的全部 RTL/TB 行号，orch 二次独立核对（见 Done 段），
  均准确无误。
- 本周期产生真实仿真（make regress COV=1，26/26），但非 testplan 场景
  评审——不涉及 evidence.py 登记，是覆盖率测量性质的证据文件。

