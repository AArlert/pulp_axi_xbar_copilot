# Work log

滚动工作日志（最新在前，块数超限经 `make archive` 滚入 `doc/archive/`）。
每块回答四问：done / not done / next / how verified。0.5.4 之前的历史
见 `git show v0.5.3-pre-reset:doc/log.md` 及其归档。

## [1.1.0] 2026-08-04 M7 开局：收口审计与知识沉淀

**Done**
- `doc/milestone.md` 登记 M7 里程碑——出口条件 = 五项交付物（追溯矩阵 /
  红线 2 抽查 / 方法学对标 / 知识沉淀 / 迁移手册）
- Abstract 表追加 M7 行；M6 章节标题 🔲→✅ 笔误修正
- version.json 1.0.0→1.1.0（M7）手动 bump——`make bump` 的 SEMVER_RE 只
  接受 `0.M.P` 格式，1.0.0 不兼容；M7 为最后里程碑不值得改脚本
- `doc/M7-traceability.md`（闭环 B）：spec↔checker 追溯矩阵——逐条
  §0–§8 全部条款 × scoreboard 22 判决点 + SVA 14 断言 + testplan 43 行
  交叉引用；结论：无真实无人认领条款（三类弱覆盖均有充分理由：§5.4
  BUG-0016 降级 / §5.5 cl.3 spec 自禁 / §6.5 正常行为）
- `doc/M7-redline2-audit.md`（闭环 C）：红线 2 渗漏抽查——SB 22 判决点
  期望值来源全量审计零渗漏 + ERR_RDATA 合规（BUG-0033/REV-014 升格）+
  import 零 DUT 行为 RTL 引用 + BUG-0075 静态关闭 SOUND（gen_addr_map
  32 位算术不可回绕、无 rand 旁路、5 配置点共用同一公式）
- `doc/M7-methodology-review.md`（闭环 D）：工业方法学对标评估——11 维度
  39 项逐项三态评级（30 达标 / 1 不适用 / 8 缺口），无致命项；8 缺口
  均为深度/精度层面（G1 vPlan 无 checker 列 / G2 功能覆盖非 spec 驱动 /
  G8 无 assertion coverage 报告等），每项附新仓库具体对策

- `doc/coverage.md`（闭环 E）：覆盖率教学文档——白话讲六类覆盖（Line/Cond/
  FSM/Toggle/Branch/Assert）、urg 报告结构、bin 长什么样、格与三态判定、
  waiver 构成（以 CW-015 为例）、定向闭合 vs 种子饱和两条收敛路线、功能
  覆盖 vs 代码覆盖、M6 收敛工作流实录、常见误区——全部用本仓库真实例子
- `doc/glossary.md`（闭环 E）：42 条术语一行白话释义（含 bin/urg/waiver/
  scoreboard/oracle/ABV/backpressure/注伤自证/格 cell 等），按首字母排序
- `doc/migration-handbook.md`（闭环 F）：迁移手册 8 节——(1) 新仓库目录结构
  (2) vplan schema（增 spec-clause + checker 列） (3) bug 五环模板（含"人的
  假设"字段 + CLOSED-STATIC 标记） (4) 分工三区表 + 学习机制五条 (5) 签核级
  完成定义（5 项） (6) 迁移资产清单（原样搬/复用/从零手写/agent 重写）(7) 文档-
  问题对照表 (8) agent 工作流复盘（5 条教训含 M4 空转、orch 模式、单一事实源、
  小闭环+rev 门禁、完备性核对两独立教训）

**Not done**
- M7 exit criteria 尚需勾选 → 做

**Next**
- M7 Phase 1 完成（闭环 B–F 全部交付）；Phase 2 新仓库 bootstrap 待用户启动

**How verified**
- `make check` 通过 + rev 评审 PASS（闭环 A–E）+ CONDITIONAL PASS→fulfilled（闭环 F）

## [1.0.0] 2026-08-04 M6 收口：覆盖率收敛完成

**Done**
- rev 签核新 CW 候选（CW-015..019 + CW-006ext/007ext），全部 PASS 登记进
  `doc/coverage-waivers.md`
- 5 个定向闭合测试 M6-CV01..05 实现落地（seq_lib/test_lib），266/266 PASS
  + 5 条 evidence 收集完毕
- `make regress COV=1` 全量 266 测试绿（default config），urg 重测覆盖率
- `cov_baseline.py` 更新（M4_WAIVERED 扩充 31 条，M4_UNOWNED 清空）
- 覆盖率现状表：132 cells, 108 ≥90%, 24 waivered, 0 gap
- rev M6 close-out CONDITIONAL PASS — EC-3 scope reduction 已兑现注记
- milestone.md 四条 exit criteria 全 [x]，Abstract M6 行 ✅
- 转 v1.0.0

**Not done**
- （无）

**Next**
- 项目验证完成（M0–M6 全里程碑 ✅）

**How verified**
- `sim/result_summary.txt` passed=266/266 (COV=1)
- `doc/evidence/v0.6.3/M6-closeout.md` 完整证据（覆盖率网格 + 退出条件评估）
- rev milestone close-out CONDITIONAL PASS（EC-3 scope reduction acknowledged）
- `make check` OK

## [0.6.3] 2026-08-04 M6 闭环 3：覆盖率缺口分析（步 1）

**Done**
- 30 cells <90% 逐格分诊完成：urg modinfo.txt bin 级核查 + RTL 例化点/tie-off
  交叉验证，产出 `doc/M6-cov-triage.md`
- 分诊结果：8 格纯 CW 已关闭 + 3 格 bin-scoped CW 已关闭 + 4 格 CW 使 raw%
  永久 <90%（waiver 即解决方案）+ 4 格 CW+DV 混合 + 11 格 UNOWNED 需新 CW+DV
- 识别 7 个新 CW 候选（CW-015..019 + CW-006ext/007ext），每条附 RTL 行号 +
  urg bin 判据摘要，待 rev 签核
- 关键发现：`axi_err_slv` Toggle 需 CW-015（`err_req.aw.atop[5:0]` 12 bit，
  `axi_atop_filter.sv:252` 硬清零）才能跨 90% 门槛（89.71% → 90.74%）
- 5 个 DV 定向闭合场景登记进 testplan（M6-CV01..05）：长 burst + 地址/size
  多样化、slave 响应多样化、B/R backpressure、ID 饱和 + ATOP inject、
  err_slv FIFO 容量 + 多样 ID

**Not done**
- CW-015..019 + CW-006ext/007ext 未经 rev 签核（候选，非正式条目）
- DV 测试代码未实现（本闭环只做分析+登记，不写 tb）

**Next**
- 闭环 4：rev 评审新 CW 候选 → 签核后登记 `doc/coverage-waivers.md`
- 闭环 5+：实现 M6-CV01..05 测试代码 → `make regress COV=1` 重测

**How verified**
- `doc/M6-cov-triage.md` 完整分诊表（30 格 × 5 组）
- `doc/testplan.md` M6-CV01..05 五行新增（状态 🔲）
- `make check` OK

## [0.6.2] 2026-08-04 M6 闭环 2：覆盖率基线测量（步 0）

**Done**
- `make regress COV=1` 全量 241/241 PASS（7 config points: baseline 196 +
  cfgA-E 各 8 + m0 5 = 241），覆盖率累积到 per-config cov.vdb
- urg 文本报告重生成（baseline `out/urgText6/`，cfgA-E/m0 各自
  `out/<cfg>/urgText6/`），`cov_baseline.py` 产出 22 模块 × 6 类型现状表
- 基线结果：132 cells，30 cells below 90%（18 UNOWNED + 11 waivered +
  1 pending 0%），全格有数字
- xcov 交叉核对 NPI_INIT_FAILED（Verdi O-2018 pynpi.cov 缺失），
  记录为环境限制，urg 数字为唯一权威来源
- `make evidence SCEN=M6-BL01` 翻绿 testplan

**Not done**
- xcov 数字交叉核对（环境限制，非遗漏）

**Next**
- M6 步 1：覆盖率缺口分析——30 cells 逐格分诊，识别可定向闭合的
  UNOWNED 格（toggle 为主，部分 line/cond/branch），登记定向场景

**How verified**
- `sim/result_summary.txt` passed=241/241
- `doc/evidence/v0.6.1/M6-BL01-coverage-baseline.md` 完整证据
- `make check` OK

## [0.6.1] 2026-08-04 M6 闭环 1：BUG-0075 处置 + testplan 注册

**Done**
- BUG-0075 处置 CLOSED（option 2：env 约束路线）：spec §3.2 clause 4
  追加环境约束——DV 地址表构造不产生 `end_addr=='0` rule（四表
  `end_addr` 最大 `32'h8000_0000`，构造性不触发 clause 3 哨兵），
  `decode_mst_port()` 维持现状。rev 评审 PASS（红线 2 / 文档一致性 /
  已有证据有效性 / 先例一致性四维度零阻塞）。§8.3 先例。
- M6 初始 testplan 行 M6-BL01（覆盖率基线测量，步 0）注册进
  testplan.md + feature-matrix.md F-M6-01。
- milestone.md M6 步 0 说明中 BUG-0075 状态更新为已关闭。

**Not done**
- M6 步 0 执行（`make regress COV=1` + xcov + 现状表 + UNOWNED 归属）。
- M6 exit criteria 1-4 全部待启。

**Next**
- M6 步 0：`make regress COV=1` 测量基线 + 现状表落 doc/evidence/。

**How verified**
- `make check` 全绿；BUG-0075 复验为静态（spec env 约束在位 + 四表
  end_addr 非零，见 bug 详细记录 repro 节）。

## [0.6.0] 2026-08-04 M5 收口 → M6 开启

**Done**
- milestone.md M5 簿记收口：四条 exit criteria 全部 [x]（各附兑现注记与
  证据指针）、Abstract M5 ✅、M6 转"进行中"、场景骨架注记补第七行
  M5-AT03；本次收口由 0.5.15 新增的 milestone 一致性检查（Abstract ↔
  复选框 ↔ version.json 三方对齐）机械看护，与 bump minor 原子落地。
- M6 准备（0.5.15 已落）：§M6 步 0（测量基线：`make regress COV=1` 合并
  测量 →（模块,类型）格现状表 → 对照 M4 UNOWNED 清单标注归属）写入
  milestone.md；xcov 在位、COV=1 流程、pre-reset 缺口清单指针均已验证。
- rev 收口独立评审 **PASS with observations**（判决中立性/文档一致性/
  工作流/红线四路核查零阻塞）；两条观察项即行收口：testplan M5-AT03 行
  "三阶段"措辞跟进 Phase D；RN02 边界探针按"失败无条件登记"惯例补登
  BUG-0079（TB_BUG，与 0077/0078 同型，CLOSED，复验证据 v0.6.0）。

**Not done**
- M6 全部工作（步 0 起）。
- BUG-0075（休眠 TB_BUG，M6 二选一处置）。

**Next**
- M6 步 0：`make regress COV=1` 测量基线 + 现状表落 doc/evidence/。

**How verified**
- `make check` 全绿（milestone 一致性三方检查在位）；M5 出口条件逐条对照
  0.5.15 的 241/241 回归与 v0.5.15 证据（见上一块与 milestone.md 注记）。

## [0.5.15] 2026-08-04 M5 收口审计修复 + 多种子出口达标 241/241 PASS

**Done**
- **收口审计**（红线 2 rev 全量评审 PASS + 证据链反稀释核查）暴露 M5 三行
  must-reach 未兑现即翻绿，全部修复并复验：
  - BUG-0076 AT03 缺 atomicload 阶段（cp_atop_subtype 实为 3/4 bins，
    FCOV_SUMMARY 恰不印该项掩盖缺口）→ seq Phase D + 补印，修后 100%。
  - BUG-0077 soak 层无未命中激励（SK03"命中与未命中均覆盖"实为 decerr
    resp=0）→ xbar_soak_seq 增 decode-miss leg（region NO_ADDR_RULES，
    atop='0，§4.7 宽读），修后 cfgA resp=2 / baseline resp=12。
  - BUG-0078 fall-through cover 结构性恒 0（RN03 与基准 M4-FT01 均
    samples=0；驱动器串行 AW→W 呈现使四信号同拍不可达）→
    axi_burst_item.aw_w_decoupled 复用 EB01 解耦 fork（不动 b_ready），
    cfgE 专属 xbar_soak_cfge_seq 启用，修后 samples=139。
  - RN02 增连通域边界确定性探针（region 低/高边界地址，构造性保证惯例）。
  - 七行 M5 证据经 make evidence 重生成于 doc/evidence/v0.5.15/。
- **多种子回归按出口条件字面达标**：regress.list 51→241 行（定向 16 测试
  ×5 种子 + 时序/保序子集 14 测试 ×10 + M5 7 测试 ×3），修复后代码态整轮
  `make regress` 241/241 PASS，无 flaky。
- 登记 BUG-0075（共享译码 oracle 缺 §3.2.3 end_addr=='0 哨兵语义，休眠
  非阻塞，M6 二选一处置）。
- **工作流加固**：make check 新增三组机械检查（feature-matrix 双向映射、
  milestone Abstract/复选框/version 三方一致、证据路径存在性——工作树或
  pre-reset tag），均注伤自证能红后还原；CI 死 selftest 步骤移除（引用
  0.5.4 已删的 scripts/tests，此前每次必红）+ checkout 补 fetch-depth:0；
  feature-matrix 补 F-M5-01..05 五行并校正 F-M3-02 旧 DECERR 常量；
  txlimit_sva/scoreboard 过时注释订正（BUG-0016 终态、uid 监视器现活）；
  iverif.json key_line_extra 捕获 SB_UNIQUEIDS_SUMMARY 数值进摘录；
  孤儿证据 v0.5.7/M5-SK01.log 删除（无引用，v0.5.8 重跑版在案）。

**Not done**
- M5 里程碑簿记收口（milestone.md 勾选/Abstract ✅/bump minor）——紧接的
  下一 commit（新 milestone 一致性检查强制其与 bump 原子落地）。
- BUG-0075 修复（M6 处置，见 doc/bugs/BUG-0075.md fix plan）。

**Next**
- M5 簿记收口 + 转 0.6.0（M6），随后 M6 步 0 测量基线（milestone.md §M6）。

**How verified**
- `make regress` 241/241 PASS（sim/result_summary.txt，2026-08-04，修复后
  代码态整轮重跑）；三个修复各自的角落数据如上（修前/修后对照见各 bug 页）；
  `make check` 全绿（含三组新检查注伤自证：ghost scene / 全勾未✅ / 幽灵
  证据路径各注入一次均报错）。

## [0.5.14] 2026-08-03 M5 多种子回归 51/51 PASS

**Done**
- `regress.list` M5 全 7 个测试扩充 seed {1,2,3}（+14 行），M0-M4 维持
  seed 1。总计 51 行（30 M0-M4 + 21 M5）。
- `make regress` 51/51 PASS：约束随机层在 3 种子下行为稳定，无 flaky。

**Not done**
- M6 覆盖率收敛未启动。

**Next**
- M6（`doc/milestone.md`）。

**How verified**
- `make regress` 51/51 PASS（`sim/result_summary.txt`）。

## [0.5.13] 2026-08-03 BUG-0044 关闭 — M5-AT03 仿真 PASS + evidence 收集

**Done**
- `make run TEST=m5_at03_atop_subtypes_test SEED=1` PASS（VM 运行）。
  SB_SUMMARY: route match=18 mismatch=0 | resp match=30 mismatch=0 |
  atop(§6.3/§6.6-6.8) pairs=12 open=0 | zero UVM_ERROR/FATAL。
  数学核对：18 笔事务（6 端口 × 3 子类型）；30 resp = 6 B-only(store) +
  12 B+R(swap) + 12 B+R(compare)；12 atop pairs = 6(swap) + 6(compare)。
- `make evidence SCEN=M5-AT03` 翻绿 testplan M5-AT03 行。
- BUG-0044 FIXING → CLOSED（bugs.md + BUG-0044.md，evidence 列指向
  `doc/evidence/v0.5.12/M5-AT03.log`）。

**Not done**
- M5 多种子回归未跑。
- M6 未启动。

**Next**
- M5 多种子回归（`make regress` 扩充 SEED 列表）。
- M6 覆盖率收敛（`doc/milestone.md`）。

**How verified**
- `make check` 绿。
- `make evidence` 从真实仿真 log 提取证据（红线 1）。
- SB_SUMMARY 各字段数值与序列结构数学一致。

## [0.5.12] 2026-08-03 BUG-0044 Step 3 — ATOP 全子类型测试场景 + BUG 关闭

**Done**
- 新增 `slvport_at03_atop_subtypes_seq`（seq_lib.sv）：三阶段定向序列——
  Phase A atomicstore（`{ATOP_ATOMICSTORE, LITTLE_END, ADD}`，SPEC-6.6
  仅 B 无 R）、Phase B atomicswap（`6'b110000`，SPEC-6.7 B+R）、Phase C
  atomiccompare（`6'b110001`，SPEC-6.8 B+R）。每笔 `len=0`，blocking
  driver 使 SPEC-6.4 ID 唯一性 trivial。
- 新增 `m5_at03_atop_subtypes_vseq`（fanout_per_slv 复用）+
  `m5_at03_atop_subtypes_test`（test_lib.sv）。
- M5-AT03 行注册进 testplan.md（status 🔲，判据锚 §6.6/§6.7/§6.8 +
  `cp_atop_subtype` 四 bins 全命中 + 红线：期望值只从 spec 推导）。
- `sim/regress/regress.list` 新增一行。
- AT01 注释更新：stale "BUG-0044, ACCEPTED@M5" → "exercised by M5-AT03
  (BUG-0044 resolution; spec §6.6/§6.7/§6.8)"。
- BUG-0044 维持 FIXING（三步代码全部落地，待 VM 运行 M5-AT03 PASS 后
  `make evidence` 关闭）。

**Not done**
- M5-AT03 仿真未跑（需 VM 编译验证），testplan status 仍 🔲。
- BUG-0044 待仿真 PASS + evidence 后 FIXING → CLOSED。
- M5 多种子回归未跑。
- M6 未启动。

**Next**
- VM 编译运行 `make run TEST=m5_at03_atop_subtypes_test SEED=1`，
  PASS 后 `make evidence SCEN=M5-AT03` 翻绿。
- M5 多种子回归。
- M6 覆盖率收敛。

**How verified**
- `make check` 绿。
- 代码审查：scoreboard `write_slv_req` L547 `ro.atop[ATOP_R_RESP]` gate
  天然覆盖 atomicstore（bit5=0→仅 B）和 swap/compare（bit5=1→B+R），
  无逻辑改动；driver（slvport_agent:113）和 responder（mstport_agent:166）
  同理。
- seq_lib.sv AT03 序列的三个 atop 编码值逐一核对 axi_pkg.sv 定义。

## [0.5.11] 2026-08-03 BUG-0044 Step 2 — scoreboard oracle 支持全 ATOP 子类型

**Done**
- 核实 scoreboard 现有逻辑天然支持全 ATOP 子类型：`write_slv_req` line 547
  的 `ro.atop[ATOP_R_RESP]` gate 已经是通用的，atomicswap/compare
  （bit5=1）走 B+R pair 路径，atomicstore（bit5=0）仅 B——**无逻辑改动**。
- 注释/消息泛化：7 处 "atomic load" → 覆盖全子类型描述（SB_ATOP_OVERLAP、
  SB_ATOP_DANGLING、SB_SUMMARY、atop_pend 注释块、fcov 注释）。
- `cg_atop` 增强：`sample_atop` 签名从 `(src_port, r_resp bit)` 改为
  `(src_port, atop_t)`；新增 `cp_atop_subtype` coverpoint（4 bins：
  atomicstore/atomicload/atomicswap/atomiccmp，swap/cmp 用 `iff` 区分
  `atop[3:0]`）。
- Rev 独立评审 PASS：逻辑正确性全路径追踪确认、coverage bin 核对、接口
  类型匹配、红线检查通过。5 处 LOW 陈旧注释（rev 发现）已全修。

**Not done**
- Step 3：atop 约束放开 + 测试场景。

**Next**
- Step 3（0.5.12）：放开 atop rand 约束到全子类型、注册 testplan 行、写
  test class、跑仿真（需要 VM 编译验证）、make evidence。

**How verified**
- `make check` 绿。
- Rev 独立评审 PASS（四路径追踪 atomicstore/load/swap/compare、coverage
  bin 编码核对 axi_pkg.sv、`iff` guard 正确性、`sample_atop` 接口一致性）。

## [0.5.10] 2026-08-03 BUG-0044 裁决 Step 1 — spec §6 补齐 ATOP 子类型条款

**Done**
- Spec §6 新增三条条款：SPEC-6.6（atomicstore 仅 B，无 R，`ATOP_R_RESP`=0）、
  SPEC-6.7（atomicswap B+R，`ATOP_R_RESP`=1）、SPEC-6.8（atomiccompare B+R，
  `ATOP_R_RESP`=1）。来源 `axi_pkg.sv` L381-447（标注"来源：RTL——上游文档
  未载"，demux.md 仅显式提及 atomic load）。
- §6.5 泛化：从"仅 atomic load"到"要求读响应的全部原子操作
  （`ATOP_R_RESP`=1：load/swap/compare）"，标注泛化范围依据 §6.7/§6.8 的
  RTL 来源条款推导。
- BUG-0044 状态 OPEN → FIXING，bugs.md 摘要同步更新。
- Rev 独立评审 PASS（F-1：clause 5 泛化来源标注已修；O-1：clauses 7/8
  实现模块名替换为机制描述）。

**Not done**
- Step 2：scoreboard oracle 扩展（基于新 spec 条款）。
- Step 3：atop 约束放开 + 测试场景。

**Next**
- Step 2（0.5.11）：scoreboard 对 atomicstore 只期望 B、对 swap/compare
  登记 B+R pair；更新 fcov sampling。
- Step 3（0.5.12）：放开 atop rand 约束到全子类型、注册 testplan 行、写
  test class、跑仿真、make evidence。

**How verified**
- `make check` 绿。
- Rev 独立评审 PASS（事实核对 axi_pkg.sv/axi_demux_simple.sv/demux.md、
  来源标注检查、红线检查——无 RTL 实现体值泄漏为期望值）。

## [0.5.9] 2026-08-03 M5 全 6 行翻绿（Slice 2-4 交付）

**Done**
- Slice 2（M5-SK02/SK03/RN03）：纯复用 `xbar_soak_vseq`，各 config point
  新增 test class + Makefile `TEST` 前缀→`+define` 映射。SK02 cfgB（6×1）
  `resp_hold=20`（6 端口汇聚到 1 个 responder，100 会顶 watchdog）；
  SK03 cfgA（1×8）/RN03 cfgE `resp_hold=100`。rev 发现 SK03 仅 1 个 slave
  端口 + `num_rounds=4` 最多只访问 4/8 个 master 端口——追加 target sweep
  （`fire_round` 遍历每个 round 0 未命中的 master 端口）；cfgA 下+7 sweep
  项，cfgB/baseline 下+0/~7 项，watchdog 余量充足。全回归 35/35。
- Slice 3（M5-RN02 cfgD）：新建 `xbar_soak_cfgd_seq`（继承 `xbar_soak_seq`，
  override `body()`）+ `xbar_soak_cfgd_vseq`。`cfgd_region()` 将逻辑目标
  映射到地址区域（mst0/mst1 走 rule region，default port 走 unmapped
  region `NO_ADDR_RULES*REGION_SIZE`=0x8000_0000）；target 限定于
  `CONNECTIVITY[slv_port_idx]`；default-port config 沿用 m3_cf04 同一
  `set_cfgd_default()` 模式。rev PASS + 清理 dead `def_port` 变量。36/36。
- Slice 4（M5-RN01 cfgC UniqueIds=1）：`drive_burst()` 逐 burst 全排空
  响应（`wait(done_cnt>=total)` + `item_done()`），故 `fire_round()` 间
  无跨 burst 在飞重叠——SPEC-5.3.1 结构性保证，无需运行时 ID 分配器。
  peak burst 15 项同桶 ID 循环（{0,8,16,24} 各 3-4 次）在 resp_hold=100
  下同时在飞同目标，覆盖"合法堆积"分支。`SB_UNIQUEIDS_SUMMARY:
  violations=0`。rev PASS；testplan M5-RN01 行描述更新为结构性方案
  （原文描述"集中 ID 分配器"与实现不符）。36/36。
- 每片 rev 独立评审 PASS（Slice 2/3/4 各一轮，共 3 次 rev 调用）。

**Not done**
- BUG-0044 仍 OPEN（ATOP store/swap/compare 无 oracle）。
- M5 多种子回归未跑（当前每行仅 SEED=1）。
- M6（覆盖率收敛）未启动。

**Next**
- BUG-0044 裁决（补 spec §6 条款 or 书面标范围外）。
- M5 多种子回归（`make regress` 扩充 SEED 列表，验证随机层稳定性）。
- M6 覆盖率收敛（`doc/milestone.md`）。

**How verified**
- `make regress` 36/36（含 M5 全 6 行：SK01/SK02/SK03/RN01/RN02/RN03）。
- 每 Slice 独立 rev 评审 PASS（3 轮）。
- 关键覆盖：cg_xbucket_total 每行 100%；RN02 cg_default_port_tracked
  100%（13 samples）；RN01 SB_UNIQUEIDS_SUMMARY violations=0。
- `make check` 绿；`make evidence` 逐行收集。

## [0.5.8] 2026-08-03 M5-SK01 落地（Slice 1/4）；新流程：每闭环强制 rev 门禁

**Done**
- 用户确立新标准流程（此后默认适用）：任务切成可闭环小片；每片做完必须
  派 rev 独立评审；rev prompt 不带我的推理叙事（只给改了什么/在哪 + 客观
  要求原文 + charter 维度，不塞"我验证过 X"）；rev 过了才 git push。
- 把"M5 第二张活"切成 4 片（TaskCreate #7-10）：Slice1=核心机制+M5-SK01
  (baseline)、Slice2=纯复用 SK02/SK03/RN03、Slice3=cfgD+RN02、
  Slice4=cfgC ID 分配器+RN01。
- 摸清驱动模型：`axi_seq_item`/`drive_write`/`drive_read` 单笔阻塞（等
  B/R 才 item_done），建不了同桶在飞深度；`axi_burst_item`/`drive_burst`
  才能背靠背下发多笔（M2-TL01/M3-TL01 先例），且必须配 `resp_hold`（否则
  响应即时回收、深度"空转"——现场验证过：不设 resp_hold 时
  `cg_xbucket_total` samples=0）。
- 落地 `tb/seq_lib.sv`：`xbar_soak_seq`/`xbar_soak_vseq`（复用
  `build_txlimit_burst`+`fanout_per_slv`，未新增底层机制）；round 0 是
  确定性"peak"轮（bucket0 压到 SPEC-5.4.1 结构有效上限 15、bucket1=3 同时
  非空，每颗种子必中，不靠随机撞）；其余 3 轮小幅随机（桶/深度/方向/
  目标端口）。`tb/test_lib.sv` 新增 `m5_sk01_soak_test`（resp_hold=100）。
- rev 独立评审 verdict PASS（现场读 raw log/coverage feeder 交叉核对，非
  信任 testplan 行文字）：确认 cg_tx_limit `at_effective_ceiling`（15）与
  cg_xbucket_total 均真实命中、无 RTL 值泄漏为期望值、无 silent-pass。
  2 处非阻塞发现已处理：①（中）我自己写的"worst case 72000ns 安全"注释
  算漏了跨端口叠加到同一 responder 的情形（真实最坏~234000ns 可能顶到
  watchdog）——收窄随机轮深度上限 6→3，重算最坏情形 144000ns 留足余量；
  ②（低）`xbar_random_vseq` 这个名字是 milestone.md 留给未来真正
  rand/constraint 求解通用层的，本实现无 rand/constraint 块，占用会话
  RN0x 实现时的语义——更名 `xbar_soak_vseq`，同步改 testplan M5-SK01 行。
- `make evidence SCEN=M5-SK01`；`sim/regress/regress.list` 新增一行。

**Not done**
- Slice 2/3/4（M5-SK02/SK03/RN01/RN02/RN03）未动。

**Next**
- Slice 2：M5-SK02（cfgB）/SK03（cfgA）/RN03（cfgE）——纯复用
  `xbar_soak_vseq`，各自新 test class + sim/Makefile 加 TEST 名前缀→
  `+define` 映射（当前只有 m3_cf01../m3_cf04../m4_ft01_ 前缀，M5 测试名
  需要新增对应行）。

**How verified**
- `make regress` 31/31（改前 30/31 基线 + 改后两次，rename/收窄后重跑
  确认 corner 仍命中：cg_tx_limit cp_inflight=100%、cg_xbucket_total
  samples=36/100%，Time=57925000ps < watchdog 200000000ps）；rev 独立
  评审 PASS；`make check` 绿。

## [0.5.7] 2026-08-03 文档漂移修复：M5 六行注册进 testplan.md（真值表归位）

**Done**
- 用户指出潜在文档漂移：milestone.md 的"场景骨架（6 行）"表（id/config/
  内容）号称"注册进 testplan 时逐行落判据"，但一直未真正注册——
  testplan.md 才是 CLAUDE.md 定义的场景真值表，milestone.md 只是进度表，
  两处并存同形表格是真实漂移风险（而非已经漂移，因为内容还没来得及分岔，
  但下一次任一处被单独改动就会分岔）。核实：`testplan.md` 自己的表头就写
  明"Register rows BEFORE coding"；`scripts/docs.py` 的 `update_row`/
  `row_exists` 只改已存在行，不建行——注册新行必须是人工步骤，机械脚本
  不代劳。历史沿用的"未开始"状态符号是 `🔲`（评审/证据列留 `-`），git log
  证实（重置前 59 处 `🔲`、55 处 `-`）。
- 补齐 6 行 M5-RN01/RN02/RN03/SK01/SK02/SK03 到 testplan.md（status 🔲，
  evidence/repro 留 `-`），每行落判据（oracle 复用现有 scoreboard/SVA、
  spec 锚点、反稀释"必须真正到达"角落、适用红线），而非照抄 milestone.md
  的一句话摘要——testplan 行本身要自包含。
- milestone.md 的"场景骨架"表整块移除，改一段指回 testplan.md 的指针
  （"场景真值表以 testplan.md 为准，本页不重复维护该表"），只保留仍然
  正确归属 milestone.md 的共享设计依据（约束设计要点、反稀释四条）。
- `make check`/`make next` 验证：`make next` 现在正确列出 6 个 M5 open
  scenarios（此前一直是"M5 has no testplan rows yet"），确认机械推导层
  与真实状态对齐。

**Not done**
- 6 行仍是 🔲（判据已落但代码未写）——M5 第二张活：约束随机层
  `xbar_random_vseq` 待实现，实现后逐行 `make evidence` 转绿。

**Next**
- 写 `xbar_random_vseq`（milestone.md 约束设计要点：len/addr/id/atop 四
  类硬软约束），先落 cfgC 一行（M5-RN01，集中 ID 分配器）跑通，再横向铺
  其余 5 行。

**How verified**
- `make check` 绿；`make next` 输出从"M5 has no testplan rows yet"变为
  列出 6 个具体 open scenario id，确认真值表与机械推导层对齐；6 行列数
  逐行核对（7 列/8 个竖线，与表头一致）。

