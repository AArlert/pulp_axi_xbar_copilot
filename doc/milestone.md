# Milestones

<!-- docsx:skip scripts/cov_loop.py -->
（M6 两处 `scripts/cov_loop.py` 提及是决策点 5 的前瞻引用——脚本随 M6 落地时才
交付，见 `doc/design-prompt/verification_maturity.md` §5、`doc/fw-feedback.md`
FB-40。）

版本号 0.M.P，M 即里程碑号。出口条件由 `make check MILESTONE=<n>` 机器核验（全场景 ✅ · regress 摘要入证据 · bugs 终态或未到期 ACCEPTED · **KILL 覆盖**）加 rev 签核记录 `doc/evidence/v0.M.*/signoff-M<n>.md`，二者缺一不可。

> **KILL 覆盖（不变量 5）自 M3 起生效。** 
> - M0/M1/M2 在旧 rubric 下已合法签核，按「冻结记录不回改」裁决**不回填** KILL 行，故其条件 4 恒红——已知记账缺口，非实质缺口。
> - M2 的击杀自证取证位置：`doc/evidence/v0.2.5/signoff-M2.md` rubric #5（BUG-0027 缺陷放回，见 336 条红后复原）。裁决记于 log [0.3.6]。

## Abstract

| 里程碑 | 内容 | 场景 | 状态 |
|---|---|---|---|
| M0 | 基建 + upstream sanity + spec v0 | 1/1 | ✅ |
| M1 | UVM env + smoke | 2/2 | ✅ |
| M2 | 功能场景 + SVA + 功能覆盖 | 8/8 | ✅ |
| M3 | 多配置回归 + 错误路径 | 11/11 | ✅ |
| M4 | 六类覆盖测量基建 + 全闭包三态扫描 + 每格具名归属（UNOWNED=∅） | 8/8 | 🔲 进行中 |
| M5 | 约束随机 + 多种子回归 + 压力/soak（方法论线） | 提案（rev 门禁前不生效） | 🔲 提案 |
| M6 | 六类覆盖 ≥90% 收敛（cov_loop，含 Toggle） | 提案（rev 门禁前不生效） | 🔲 提案 |

## M0 — 基建 + sanity + spec v0 ✅

Exit criteria:

- [x] 仿真基建可跑：flist 分层（vendor → dut → tb_upstream 三层）、`sim/Makefile` 入口、VCS-MX O-2018 跑通上游 tb sanity
- [x] `doc/spec.md` v0 由 arch 从许可来源蒸馏，经 rev 评审后 sha256 钉死
- [x] 签核：`doc/evidence/v0.0.2/signoff-M0.md`

## M1 — UVM env + smoke ✅

Exit criteria:

- [x] `tb_top` + UVM env（多 master/slave agent + 地址路由参考模型记分板）可跑
- [x] smoke 场景 ✅，证据入库
- [x] 附带评估 vendor v0.39.9 → v0.39.10 升级（结论记于评审记录）
- [x] 签核：`doc/evidence/v0.1.2/signoff-M1.md`

## M2 — 功能场景 + SVA + 功能覆盖 ✅

Exit criteria:

- [x] 八条功能场景全 ✅，`make regress` 11/11 独立重跑
- [x] 协议/时序 SVA 挂接并非空转（每 assert 配同触发前提的 cover）
- [x] 功能覆盖 covergroup 落地，非空转自证
- [x] 签核：`doc/evidence/v0.2.5/signoff-M2.md`（rubric #7 首次实战）

## M3 — 多配置回归 + 错误路径 ✅

Exit criteria:

- [x] 11 条场景全 ✅（DE01/DE02/OR04/CFG02/OR05/AT02/CF01~04/TL01）
- [x] 多配置维以**声明式覆盖子集**实现（4 配置点 + 基线，每维度每取值至少出现一次），**不做 constrained-random**——配置维全是 elaboration 期 localparam，且 `run: compile` 产物名固定 `simv`，随机化会让"配置 X 通过"与"基线又跑一遍"在日志上同形（裁决见 log [0.3.3]）
- [x] 四条 `ACCEPTED@M3` 债务逐条了结：BUG-0018 / BUG-0024 / BUG-0025+BUG-0031
- [x] **KILL 覆盖：至少一条打 M3 标签的 KILL 行**（不变量 5 首个生效里程碑）
- [x] 签核：`doc/evidence/v0.3.20/signoff-M3.md`（C1/C2 兑现记录见该文件 §八，由 0.3.21 closer 卡追加）

## M4 — 六类覆盖测量基建 + 全闭包三态扫描 + 每格具名归属 🔲

> **性质变更（里程碑重构，本卡提案 → rev 门禁 → orch 应用重 pin）**：M4 出口从
> "六类 ≥90%"改为"覆盖测量基建 + 全闭包三态扫描 + 每个 <90%（模块,类型）格有
> 具名归属"。**六类 ≥90% 的百分比达标收敛门移交 M6**（拥有约束随机 + cov_loop
> 正确工具的里程碑）。谱系：BUG-0047 终判预留选项 (ii)"重议判据口径（spec §0
> 变更提案 + rev 门禁）"；REV-026 十卡实证定向刷宽总线 Toggle 为坏配对。
> **KILL 覆盖（不变量 5）与 rev 签核要求不变；M4 内不再有任何百分比达标门。**

Exit criteria:

- [ ] **六类覆盖测量基建**：merged 覆盖库（基线拓扑 24 场景）+ urg 六类判据
      （`line+cond+fsm+tgl+branch+assert`，口径以 spec §0#4 为准，含例化闭包递归
      全部子模块，**不含 functional covergroup**——REV-011 §3.3）报告可确定性重生
      （取证 `doc/evidence/v0.4.35/M4-coverage-final-sweep.md` 命令①②）。
- [ ] **全闭包三态扫描**：22 个 DUT 模块 × 六类，逐格 N/A（附已核实成因）/ ≥90% /
      <90% 三态判定完成，与 urg modlist 逐位对账（22+13=35，`M4-coverage-final-sweep.md`
      §2）。
- [ ] **每个 <90%（模块,类型）格有具名归属，UNOWNED = 空集**：每格归入且仅归入
      四类之一——(a) 已修（≥90% 或被 ≥90% 余量吸收，REV-028 先例）；(b) rev 签核
      Kind-A 书面豁免（`doc/coverage-waivers.md` CW-001~014）；(c) 债务行
      （`doc/bugs.md` `ACCEPTED@M<n>`，如 BUG-0044）；(d) M6 backlog 登记
      （`doc/design-prompt/milestone_restructure.md` §6 / 本页 M6）。核对面 = 扫描表 ×
      CW 表 × bugs.md 债务 × M6 backlog（详见本页 M6 backlog 表 §6.3 的 22×6 全格
      对照）。**现状订正**：0.4.36 闭环**曾宣告** UNOWNED = 空集，经 REV-032 门禁
      **证伪**（`stream_register` 三格 Line/Toggle/Branch 漏账，登记 BUG-0049）；
      **REV-033 裁决 CW-014（Kind-A）+ D1 定向路由后方达成 UNOWNED = 空集**
      （引用链 BUG-0049 / REV-032 / REV-033）。
- [ ] **KILL 覆盖（不变量 5）**：至少一条打 M4 标签的 KILL 行。
- [ ] **Kind-B 豁免登记规则（BUG-0047 guard + REV-024 §2.1）**：任何 Kind-B 登记须
      先附逐信号/逐位 toggle 分解，解锁 = M5 约束随机层落地 + M6 cov_loop 重测（见
      `doc/coverage-waivers.md` 抬头新定义）。当前 M4 阶段合法 Kind-B 集为**空集**
      （REV-025 裁定），本重构不新增 Kind-B。
- [ ] **functional covergroup（`cg_*`）非空转**仍按 rubric 第 4/5 条人工抽查把关，
      不受六类机器口径约束；BUG-0018 cross bin 盲区须维持已解决（否则以"永远填
      不满"再现）。
- [ ] 签核：`doc/evidence/v0.4.*/signoff-M4.md`（rev 全 rubric；重点核 UNOWNED=∅
      交叉核对 + Kind-A 论证 + KILL 集完备性 + BUG-0044/45/46 债务真实性）

## M5 — 约束随机 + 多种子回归 + 压力/soak 🔲（提案草稿，rev 未过）

> **性质：验证方法论成熟度轴，与 M4/M6 的结构覆盖率百分比轴正交。** 设计输入见
> `doc/design-prompt/verification_maturity.md` 决策点 2–4（决策点 5 cov_loop 随里程碑
> 重构移交 M6）。**排 M4 签核之后启动**；随机只能加固/发现，不能替代 M4 的定向
> 关闭，也不承担 M6 的 ≥90% 收敛门——本里程碑出口全部为"能力落地 + KILL 自证"，
> **无覆盖率百分比门**。M5 的随机/闭环产出**可能**帮更省力关上 M6 结构缺口，但
> 目标性质不同（design-prompt Decision 1，C1.1–C1.4）。
> **进门前置**：原三条 `ACCEPTED@M5` 债务中，BUG-0045+0046 已于 0.5.3 合并为
> spec §3.2 clause 3/4 并转 `SPEC_CHANGED`（不再到期）；**余 BUG-0044**（§6 ATOP
> 非-load 子类型应答义务）仍到期于 M5 签核，须**二选一再裁决、不得自动延期**
> （见 guard G-0044）。本里程碑与其版本方案变更（v1.1.*→v0.5.*）均**不移动
> `@M5` 锚点**——锚定里程碑号 M5、非版本串。

Exit criteria（草稿，rev 门禁前不生效）：

- [ ] **约束随机激励层**：`axi_seq_item` 四 `rand` 字段配 rev 批准的 `constraint`
      块（合法性边界编码进约束、非事后 scoreboard 兜底），`atop` 升为有界 `rand`
      （`{'0} ∪ 合法 atomic-load 编码`，零 spec 改动）；一条配置无关的通用随机
      虚拟序列（`xbar_random_vseq`）在 baseline + cfgA–E 全配置点复用跑通
      （design-prompt Decision 2，C2.1–C2.7）
- [ ] **多种子回归**：M1–M4 全 UVM 定向场景至少 N=5 固定记录种子全过（时序/保序
      高价值子集 N=10），`sim/regress/regress.list` 承载种子行，`result_summary.txt`
      捕获入回归证据显示全部种子 `passed=N/N`（testplan 行 canonical 种子不变、
      scripts schema 零改动，design-prompt Decision 3）
- [ ] **压力/soak**：每拓扑类（baseline 6×8 + cfgB 6×1 + cfgA 1×8）至少一条长随机
      饱和场景，判据 = 自检三层（scoreboard/SVA/functional cov）零 mismatch/零 assert
      失败 + **无 watchdog 超时（liveness，引 §5.5.4，REV-019 校正）** + **覆盖率趋于饱和**（连续
      K 窗口增量 < ε，作停止判据非 PASS/FAIL）；判决延迟不敏感（§7.4），各桶在飞
      同时压到 §5.4.1 有效上限（design-prompt Decision 4）
- [ ] **KILL 覆盖（不变量 5）**：M5 新引入的每类 checker（soak watchdog liveness、
      饱和探测器、随机约束合法性 env 兜底监视）各至少一条打 M5 标签的 KILL 行
- [ ] **BUG-0044 到期二选一仲裁**（rubric #8，不得自动延期）：§6 atop 非-load 子
      类型应答义务（REV-019 SP-1；已核实事实见 `doc/bugs/BUG-0044.md` 的 orch
      investigation note）——到期动作与可证伪解锁见该记录。姊妹两条 BUG-0045/0046
      已于 0.5.3 合并入 spec §3.2 clause 3/4 转 `SPEC_CHANGED`，不再到期；其残留
      约束（refmodel 哨兵分支未实现）改由 guard G-0045 承接
- [ ] 签核：`doc/evidence/v0.5.*/signoff-M5.md`（rev 全 rubric）

## M6 — 六类覆盖 ≥90% 收敛（cov_loop，含 Toggle）🔲（提案草稿，rev 未过）

> **性质：结构覆盖率百分比达标轴的收敛里程碑——承接 M4 移交的 ≥90% 数字门。**
> 工具 = M5 约束随机层（决策点 2–4）+ `scripts/cov_loop.py`（决策点 5，见
> `doc/design-prompt/verification_maturity.md` §5，随重构移交本里程碑）。
> **工作原则 = random-first, directed-fallback**：先跑 M5 随机层 + cov_loop 测量，
> 只对随机未命中的 bin 写定向卡（避免 REV-026 实证的"定向刷宽总线 Toggle"坏配对）。
> **谱系**：BUG-0047 终判选项 (ii)——90% 数字门挂在拥有正确工具的里程碑。

Exit criteria（草稿，rev 门禁前不生效）：

- [ ] **六类覆盖 ≥90% 收敛**（含 Toggle）：全部（模块,类型）格 ≥90%，DUT 范围 =
      spec §0#4 例化闭包六类；未达标格须 rev 签核书面豁免（Kind-A 结构不可达
      CW-001~014，或到期重裁的 Kind-B）。
- [ ] **承接 M4 移交 backlog**：`doc/design-prompt/milestone_restructure.md` §6 的
      DV-A~G 定向卡 + fifo_v3 / spill_register_flushable 结构残余重测，逐条闭合或
      书面豁免。
- [ ] **cov_loop 落地**（决策点 5）：`scripts/cov_loop.py` 跑确定性随机种子、查
      功能+结构覆盖、逐种子记边际贡献、饱和/预算上限则停、残余缺口清单——脚本只
      测量不作 oracle（design-prompt B0.2/B0.3），残余缺口 → 定向 testplan 行**或**
      书面记随机不可达。
- [ ] **KILL 覆盖（不变量 5）**：M6 若为随机未命中 bin 派定向卡而新增/扩展 checker
      期望路径，各至少一条打 M6 标签的 KILL 行。
- [ ] 签核：`doc/evidence/v0.6.*/signoff-M6.md`（rev 全 rubric）
- [ ] 签核后转 v1.0.0
