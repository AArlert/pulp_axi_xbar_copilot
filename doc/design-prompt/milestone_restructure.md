# Design prompt — `milestone_restructure`（里程碑架构重构：M4 出口重定义 + 新增 M6）

> **性质：提案。** 本文经 rev 门禁通过、orch 应用（改 `doc/spec.md` §0#4 并重 pin +
> 改 `doc/milestone.md`/`doc/coverage-waivers.md`/`doc/design-prompt/verification_maturity.md`）
> 前，M4 出口条件、M5 版本方案、M6 均未生效。**本文是唯一交付物**——不直接编辑
> spec/milestone/coverage-waivers/verification_maturity，全部改动以 old/new 对照列出，
> 由 orch 在 rev 批准后应用并重 pin。
> **约束层边界**：本文只重构里程碑治理（出口条件、版本、归属分诊），**不新增任何
> DUT 外部可见行为**；唯一触碰 pinned spec 的是 §0#4 覆盖率口径行的**里程碑绑定**
> （百分比门从 M4 迁 M6），六类口径/例化闭包/三态测量规则**一字不改**（behavior-leak
> 禁区遵守：checker 期望仍只从 spec 推导，不因本重构分叉）。
> 前置：`doc/spec.md` §0#4/#5（覆盖率口径）、`doc/milestone.md` 全文、
> `doc/coverage-waivers.md` 抬头、`doc/design-prompt/verification_maturity.md`、
> `doc/bugs/BUG-0047.md`（谱系）、`doc/evidence/v0.4.35/M4-coverage-final-sweep.md`
> （权威扫描）、`doc/review/REV-030.md`/`REV-031.md`（DV 构造指引 + UNOWNED 裁决）。

---

## 1. 动机与谱系

### 1.1 用户裁定

里程碑架构重构：M4 出口从"六类 ≥90%"改为"覆盖测量基建 + 全闭包三态扫描 + 每格
具名归属（UNOWNED = 空集）"；M5 保持纯方法论并瘦身（cov_loop 移交 M6）；新增 M6
承接六类 ≥90% 数字门（拥有约束随机 + cov_loop 正确工具的里程碑）；v1.0.0 改挂 M6
签核。

### 1.2 合法谱系（三条独立支撑）

- **BUG-0047 终判预留选项 (ii)**：BUG-0047（`doc/bugs/BUG-0047.md` `## taxonomy`）
  把 M4"六类含 Toggle ≥90%"出口与"M5 前仅定向、随机不得替代 M4 定向关闭"纪律的
  可行性张力裁为 SPEC_ISSUE，给两条出口：(i) 逐 bin 书面豁免（REV-024 已落地
  Kind-A/Kind-B 框架）；**(ii) 重议 M4 判据口径（须走 spec §0 变更提案 + rev
  门禁）**。REV-024 当时只走了 (i) 的一半（引入豁免框架，不动 pinned spec）。本卡
  是选项 **(ii)** 的正式实现：动 spec §0#4 里程碑绑定 + 里程碑重构，经 rev 门禁。
- **REV-026 十卡实证**：REV-026 十项加固卡清单收官后，宽总线 Toggle 的**定向刷法**
  被实证为边际收益极低的坏配对（用户裁定语：十卡换约 1.5pp）。BUG-0047 `## rca`
  【REV-024 订正】已订正"组合爆炸"失实框架为"定向仅用少数固定取值致多数载荷位
  未双向翻转；随机廉价、定向昂贵"——这正是 90% 数字门应挂在**约束随机**里程碑的
  实证依据。
- **不因目标定得不好而制造不必要工作量**：M4"六类硬 90%"把结构覆盖率百分比门
  绑在了**只有定向激励**的里程碑上，逼出 DV-A~G 这类"结构可达但纯定向不经济"的
  刷宽总线工作。正确框架是让 90% 数字门挂在拥有正确工具（约束随机 + 覆盖闭环）的
  M6；M4 只做它能廉价做到的——**测量 + 分诊到每格有归属**（这本身就是 BUG-0038
  guard 要的"dashboard 上可区分 M4-done 与 M4-done-except-unowned"）。

---

## 2. spec §0#4 精确 old/new 对照（唯一 pinned-spec 改动）

**改动面最小化**：只动 `doc/spec.md` §0 适配表 #4（覆盖率口径行）内一句"处置指向"，
把 ≥90% 百分比达标门从 M4 迁到 M6；六类口径、例化闭包递归范围、三态（N/A/≥90%/
<90%）测量规则、空白不得记 0%/100%/省略等**全部一字不动**。**绝不触碰 §3.2/§6**
（BUG-0045/0046/0044 三条 guard 明文守着）。

**OLD**（§0#4 单元格内一句，`doc/spec.md` L25，精确子串）：

```
有 bin 时须 ≥90%，否则按 `doc/milestone.md` M4 出口条件逐条修补或出具 rev 签核的书面豁免。
```

**NEW**：

```
有 bin 时以 ≥90% 为合格阈值；未达阈值的（模块,类型）格须逐条给出具名归属——已修（≥90% 或被 ≥90% 余量吸收）/ rev 签核 Kind-A 书面豁免（`doc/coverage-waivers.md`）/ 债务行（`doc/bugs.md` `ACCEPTED@M<n>`）/ M6 backlog 登记（`doc/milestone.md` M6 + `doc/design-prompt/milestone_restructure.md` §6），**UNOWNED（无归属）= 空集**。**六类 ≥90% 的百分比达标收敛门属 `doc/milestone.md` M6 出口条件**（拥有约束随机 + cov_loop 工具的里程碑）；**`doc/milestone.md` M4 出口只要求六类测量基建 + 全闭包三态扫描 + 每格具名归属完成**，M4 内不再有百分比达标门（BUG-0047 选项 (ii)，本项目里程碑重构）。
```

**影响的下游条目**：
- `doc/milestone.md` M4/M5/M6 三节（本文 §3 给完整替换文本）。
- `doc/coverage-waivers.md` 抬头 Kind-B 定义（本文 §4）。
- **BUG-0038 guard（`doc/spec.md` §0#4）合规**：本改动**不动**例化闭包定义（含
  `addr_decode_dync`/`axi_demux_simple` 仍在 ≥90% 范围内）与 N/A 三态成因规则；
  guard 关心的"M4/M6 出口门 checker 须明确哪些模块算入 ≥90% scope"仍由 §0#4 闭包
  定义**原样回答**，且百分比门迁 M6 后该 checker 语言直接对应 M6 出口门（同一
  §0#4 scope）。UNOWNED=∅ 正是 guard 要的"dashboard 可区分"。
- **BUG-0039 guard（`doc/spec.md` §4 clause 7 + testplan）合规**：本改动不触 §4、
  不改任何 decode-miss 激励构造行；`atop ≡ '0` on decode-miss 约束不受扰动。

**重 pin**：orch 在 rev 批准后编辑 §0#4 并 `docs.py --pin-spec` 重算 `doc/spec.sha256`；
BUG-0047 由此获得选项 (ii) 的具体 §0#4 变更 + 重 pin 证据（见 §5 open risk）。

---

## 3. `doc/milestone.md` 完整替换文本

### 3.1 抬头 + Abstract 表（L1–L18 整块替换；L1–L8 与现状逐字相同，只更新 Abstract 三行）

```
# Milestones

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
```

> **Abstract 漂移修正**：M4 行"场景"列由现状 `0 场景行` 订正为 `8/8`——testplan
> 现有 8 条 M4 场景行（M4-RC01/AW01/OV01/FT01/EB01/BP02/BP03/EB02）**全部 ✅**
> （`doc/testplan.md` 现场核对，`grep -cE '^\| M4-[A-Z]'` = 8）。M4 状态维持
> 🔲 进行中（签核曾 REJECTED，本重构后重开）。

### 3.2 M4 节完整替换（现状 L56–L66 整节替换）

```
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
```

### 3.3 M5 节完整替换（现状 L68–L101 整节替换；决策点 5 移出，版本改 v0.5.*）

```
## M5 — 约束随机 + 多种子回归 + 压力/soak 🔲（提案草稿，rev 未过）

> **性质：验证方法论成熟度轴，与 M4/M6 的结构覆盖率百分比轴正交。** 设计输入见
> `doc/design-prompt/verification_maturity.md` 决策点 2–4（决策点 5 cov_loop 随里程碑
> 重构移交 M6）。**排 M4 签核之后启动**；随机只能加固/发现，不能替代 M4 的定向
> 关闭，也不承担 M6 的 ≥90% 收敛门——本里程碑出口全部为"能力落地 + KILL 自证"，
> **无覆盖率百分比门**。M5 的随机/闭环产出**可能**帮更省力关上 M6 结构缺口，但
> 目标性质不同（design-prompt Decision 1，C1.1–C1.4）。
> **进门前置不变**：三条 `ACCEPTED@M5` 债务（BUG-0044/0045/0046）到期于 M5 签核，
> 须**二选一再裁决、不得自动延期**（见各自 guard：BUG-0044 §6 / BUG-0045·0046
> §3.2）；本里程碑与其版本方案变更（v1.1.*→v0.5.*）均**不移动 `@M5` 锚点**——锚定
> 里程碑号 M5、非版本串。

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
- [ ] **三条 ACCEPTED@M5 债务到期二选一仲裁**（rubric #8，不得自动延期）：BUG-0044
      （§6 atop 非-load 应答义务，REV-019 SP-1）、BUG-0045（§3.2 `end_addr=='0`
      末端哨兵，REV-021）、BUG-0046（§3.2 doc-vs-RTL `<=` vs `<`，REV-023）——各自
      到期动作与可证伪解锁见对应 REV 记录 §Q3/§4
- [ ] 签核：`doc/evidence/v0.5.*/signoff-M5.md`（rev 全 rubric）
```

### 3.4 M6 节完整新增（M5 节后追加）

```
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
```

---

## 4. `doc/coverage-waivers.md` 抬头 Kind-B 定义 old/new 对照

**只动抬头（L7–L8）Kind-B 定义行**，适配新架构（Kind-B 解锁 = M5 约束随机层落地 +
M6 cov_loop 对该 bin 重测）。**CW-001~014 各行内容一字不动**（rev 登记面）；抬头
Kind-A 定义（L6）不动；表后"注"（L26–32）不动。

**OLD**（`doc/coverage-waivers.md` L7–L8）：

```
- **Kind-B 方法论受限、延后 M5（临时）**：解锁 = M5 约束随机重测后仍 <90% 才
  讨论转永久；被推翻即作废 = 任一 M5 随机跑使该 bin ≥90%。**须附逐位 toggle 分解**。
```

**NEW**：

```
- **Kind-B 方法论受限、延后至 M5 随机层 + M6 cov_loop（临时）**：解锁 = M5 约束随机
  激励层落地 + M6 cov_loop 对该 bin 重测后仍 <90% 才讨论转永久；被推翻即作废 =
  任一 M5/M6 随机跑使该 bin ≥90%。**须附逐位 toggle 分解**。
```

> 说明：原定义把解锁绑死"M5 约束随机重测"，是旧架构下 cov_loop 属 M5 的写法。
> 重构后测量重测归 M6 cov_loop（决策点 5 移交 M6），激励能力归 M5 随机层——两步
> 分属两里程碑，故解锁条件拆为"M5 落地 + M6 重测"。当前 Kind-B 集为空集（REV-025），
> 本改动纯为未来若出现合规 Kind-B 候选时口径正确，不实例化任何行。

---

## 5. `doc/design-prompt/verification_maturity.md` 最小修订对照

该文件归 arch 面；本重构须把**决策点 5（cov_loop）移交 M6**（修订 A/B）并**清理该
文件里被本重构 §7.3 版本方案取代的旧版本串/旧里程碑归属**（修订 C/D/E，G-2 返工补入——
REV-032 轴7/8：verification_maturity 是活体 design-prompt，"历史不回改"不适用，留矛盾态
违反 discipline rule 3）。全部修订**不触碰决策点 2 C2.5——BUG-0044 guard 守卫面，atop
有界子集不变**。

**修订 A**（§0 范围段，L36–L37）：

OLD：
```
范围：本文承载**五个决策点**的提案。Decision 1 给里程碑归属并已在 `milestone.md`
起草 M5 草稿；Decision 2–5 是 M5 内待派 DE/DV 卡的架构输入。
```

NEW：
```
范围：本文承载**五个决策点**的提案。Decision 1 给里程碑归属并已在 `milestone.md`
起草 M5 草稿；Decision 2–4 是 M5 内待派 DE/DV 卡的架构输入；**Decision 5（cov_loop）
随里程碑重构移交 M6**（六类 ≥90% 收敛工具，见 `doc/design-prompt/milestone_restructure.md`）。
```

**修订 B**（§5 标题下追加一行归属批注，`doc/design-prompt/verification_maturity.md`
L293 标题行**后**插入）：

OLD（L293，标题行，保留不动）：
```
## 5. 决策点 5 — 覆盖率驱动闭环机制（`scripts/` 驱动脚本，功能规格）
```

NEW（标题行下新增批注段落）：
```
## 5. 决策点 5 — 覆盖率驱动闭环机制（`scripts/` 驱动脚本，功能规格）

> **里程碑归属（里程碑重构后）：本决策点移交 M6**（六类 ≥90% 收敛线），不再属 M5；
> M5 保留 Decision 2–4（约束随机 + 多种子 + soak）。本节内一切"M4 六类 ≥90% 目标"
> 的引用（C5.3 可选覆盖目标、C5.4 覆盖范围），重构后**目标门指 M6 收敛门、口径指
> spec §0#4**——§0#4 六类测量口径本身不变（M4 测量、M6 收敛），故 C5.x 功能规格
> **无需逐行改动**。见 `doc/design-prompt/milestone_restructure.md` §2/§3.4。
```

> 说明：C5.1–C5.12 的功能规格（输入/循环/输出/边界）**无需改动**——它们描述 cov_loop
> 脚本行为，与所属里程碑正交；口径引用（§0 item 4）在重构后仍是同一测量定义。修订 B
> 的批注段一次性重定向本节所有里程碑目标引用，避免逐行改（外科手术式最小改动）。

**修订 C**（决策点 1 §1 建议句，`verification_maturity.md` **L43–L44**——里程碑归属与
版本双过时：旧标题含"覆盖率闭环"（cov_loop 已移交 M6）、"M4（六类 ≥90%）签核转
v1.0.0"（M4 无 ≥90% 门、不转 v1.0.0））：

OLD：
```
**建议：新开 M5「约束随机 + 多种子回归 + 压力/soak + 覆盖率驱动闭环」，不并入
M4；且 M5 排在 M4（六类 ≥90%）签核转 v1.0.0 之**后**（作 v1.0 后的方法学加固线）。**
```

NEW：
```
**建议：新开 M5「约束随机 + 多种子回归 + 压力/soak」，不并入 M4；且 M5 排在 M4
签核之**后**（作方法学加固线）。**（**里程碑重构后**：覆盖率驱动闭环＝决策点 5 移交
M6，M4 出口改"测量 + 三态扫描 + 每格具名归属"、六类 ≥90% 门迁 M6；版本方案见
`doc/design-prompt/milestone_restructure.md` §7.3，M4 不再转 v1.0.0。）
```

**修订 D**（版本方案段，`verification_maturity.md` **L70–L71**——旧提案 v1.1.* 占位，
被本重构 §7.3 取代）：

OLD：
```
**版本方案（开放，orch 定）**：M4 签核转 v1.0.0；M5 建议走 v1.1.0（或另立 v2 线）。
本文按 M5 起草 `milestone.md` 草稿（见该文件），版本号占位 `v1.1.*`。
```

NEW：
```
**版本方案（里程碑重构后定稿，见 `doc/design-prompt/milestone_restructure.md` §7.3）**：
0.M.P 规则下 **M5=v0.5.\*、M6=v0.6.\***，**v1.0.0 挂 M6 签核**（M4 不再转 v1.0.0）。
本文按 M5 起草 `milestone.md` 草稿（决策点 5 cov_loop 移交 M6，见该文件）。
```

**修订 E**（决策点 3 §3.2 C3.8 证据路径示例，`verification_maturity.md` **L242**——
路径例含旧版本串 `v1.1.*`）：

OLD：
```
捕获为回归证据（如 `doc/evidence/v1.1.*/regress-multiseed.log`），显示全部种子行
```

NEW：
```
捕获为回归证据（如 `doc/evidence/v0.5.*/regress-multiseed.log`，M5=v0.5.\* 按 §7.3），显示全部种子行
```

> 逐处点名：L44（修订 C）· L70/L71（修订 D）· L242（修订 E）——四处 `v1.1.*`/"M4 转
> v1.0.0" 口径全部对齐 §7.3，`verification_maturity.md` 应用后无版本自相矛盾态。

---

## 6. M6 backlog 表（提案核心制品）

数据源**只准**用下列实测/裁决记录，逐条引用：
- **[FS]** = `doc/evidence/v0.4.35/M4-coverage-final-sweep.md`（权威扫描 + 归属标注）
- **[R30]** = `doc/review/REV-030.md` §3（DV-A~E 构造指引）
- **[R31]** = `doc/review/REV-031.md` §5/§7（DV-F/G 新卡 + DV-A~D 阴影 + 结构残余重测）
- **[R33]** = `doc/review/REV-033.md` + `doc/coverage-waivers.md` CW-014（`stream_register`
  三格归属裁决——**G-1 返工据此补入**，闭合 REV-032 轴4 发现 / BUG-0049 漏账）

### 6.1 待派定向卡（DV-A~G）+ 结构残余重测项

| 条目 | 目标（模块,类型）/bin | 处置状态 | random-first? | 估级 | 数据源 |
| --- | --- | --- | --- | --- | --- |
| **DV-A** | mux & err_slv `ar/aw.size[1:0]`(1→0)/`addr[2:0]`/`len[7:4]`；mux `r.data[2:0]/[34:32]`（+ rr_arb_tree/multicut/cut/spill/spill_flushable/counter `i_r_counter len` 高位载荷阴影）；**（D1，err_slv 宿主族）`stream_register`（r_resp_cmd）Toggle `data_i.len[7:4]` 8 bit 两向**——`aw.len` 组合馈通、与 ATOP 无关、送一笔 len≥16 译码未命中写 burst 即翻（REV-033 §DV） | 待派；两轨：err_slv 轨（廉价，宿主 M3-DE01 enrichment；**含 D1：AWLEN 随机域放宽至 ≥16，无新 oracle**）+ mux 轨（须扩 `predict_beat_data` 窄传输/非对齐/长突发预测器 + KILL） | **强**——约束随机 C2.1(len 软角落 {254,255})/C2.2(addr 软角落) 自然覆盖 size/addr/len（含 D1 的 len≥16）；仅 mux 轨预测器扩展须定向验证 | err_slv L1（含 D1）/ mux L2 | [R30] §3 DV-A；[FS] §3 行3/4；[R31] §7 阴影；**D1：[R33]（REV-033 §DV，`data_i.len[7:4]` 8 bit）** |
| **DV-B** | mux `r.resp[1:0]`/`b.resp[1:0]`/`r.user`/`b.user`/`r.data[28]/[60]`（+ 薄壳/fifo_v3 mem 值域载荷阴影） | 待派；responder resp∈{OKAY,SLVERR,DECERR} 轮换 + 非零 user + 饱和读地址 | **强**——responder 随机反压 + resp 轮换（C3.5）自然扫；scoreboard 响应期望改读 TB 注入值须 KILL | L1/L2 | [R30] §3 DV-B；[FS] §3 行4；[R31] §7 |
| **DV-C（#17）** | mux `mst_req_o.b_ready`（+ axi_id_prepend `slv_b_readies_i`/`mst_b_readies_o` 阴影，CW-012 拆分后的定向分量） | 待派；新增外部主机 B 侧背压驱动（对偶 `resp_ready_delay`）+ 多笔同 master 并发写 | **中**——随机 B 背压（C3.5）可达，但需并发汇聚构造 | L2 | [R30] §3 DV-C；[R31] §3/§7 |
| **DV-D（#18）** | err_slv `slv_resp_o.ar_ready` **已由 `m4_eb02_errbp_test` 关闭（0.4.35）**；残余 = counter `i_r_counter q_o[7:2]`（r_fifo 填满读向背压）阴影 | 主目标已闭；残余随 M6 重测，仍未覆则定向补 | **强**——读向背压随机可达 | L1（仅残余） | [R30] §3 DV-D；[FS] §3 行3；[R31] §7 |
| **DV-E（#16）** | demux `axi_demux_simple.sv:168` `ar_id_cnt_full && aw.atop[ATOP_R_RESP]` 双 1 交叉（Cond 5 bin 之 4） | 待派；新混向 primitive（`resp_hold` 撑满同桶 AR ≥15 笔 + 满窗口内 fork atop-load 写，命中地址避 §4 clause 7） | **弱**——同拍共存罕见，directed-fallback 主导（#16 可行性 [R30] §5 终判"可构造、非结构矛盾"） | L2 | [R30] §3 DV-E/§5；[FS] §3 行2 |
| **DV-F（新）** | rr_arb_tree Toggle 内部仲裁节点：`gen_arbiter.index_nodes` 其余位/`req_nodes[6]`/`gen_levels[*].sel`/`upper_mask[0]`/`lower_empty` | 待派；多主并发汇聚同一 master 端口 + 请求端口分布多样化（轮转/稀疏/满载）使 `rr_q` 遍历全起点 | **中**——随机汇聚流量遍历 rr 指针部分可达；节点组合模式须定向补 | L2 | [R31] §7 DV-F；[FS] §5-3 |
| **DV-G（新，DV-E 家族）** | axi_demux_id_counters Line/Toggle/Branch（`axi_demux_simple.sv:582-589` `push_en&&inject_en` 同拍同 index，经 AR 侧 `inject_i(atop_inject)` 活信号）+ delta_counter id-bucket 在飞高位（深同-ID 占用） | 待派；fork：同 index 群 AR + 窗口内呈现 atop-load 写（命中地址）；深占用用 `resp_hold` | **弱**——同拍同 index 巧合罕见，directed-fallback 主导 | L2 | [R31] §7 DV-G；[FS] §5-1/§5-6 |
| **重测-1** | fifo_v3 Cond 80.19%/Toggle 82.09%/Branch 78.43% 的**非-flush 余量** | flush 分量已 CW-010 承接（bin-scoped）；非-flush 余量随 DV-A/DV-B（背压+mem 值域）闭合；**定向闭合后重测，仍 <90% 才登记结构残余 Kind-A（不预登记）** | 随 DV-A/B | — | [R31] §5/§8 行5；[FS] §5-5 |
| **重测-2** | spill_register_flushable Cond 82.49%/Toggle 79.76% 的**非-flush 余量** | flush 分量已 CW-010 承接；非-flush（背压 `a_full_q/b_full_q/ready_i` + 载荷值域）随 DV-A/DV-B 闭合；**定向闭合后重测，仍 <90% 才登记结构残余** | 随 DV-A/B | — | [R31] §5/§8 行8；[FS] §5-7 |

> **薄壳 Toggle 阴影不单列卡**：axi_multicut/axi_cut/spill_register 薄壳 Toggle
> （89.22/89.22/88.51%，逼近 90%）= 透传载荷位，随 DV-A/DV-B 越门，**不新开卡**
> （[R31] §5 行7/§8 行7）。

### 6.2 排除说明（已由 CW-001~014 / BUG-0044 承接，**不入 M6 backlog**）

以下格已有归属（Kind-A 永久豁免 = 结构不可达、不需 ≥90% 收敛；或 debt = spec-gap），
故**不进 backlog 的 ≥90% 收敛工作**：

| 归属 | 承接的（模块,类型）/bin | 性质 | 来源 |
| --- | --- | --- | --- |
| CW-001 | `axi_atop_filter` 六类（`w_state_q` 全非-FEEDTHROUGH + `r_state_q.INJECT_R`；**R_HOLD 已 Covered 除外**） | Kind-A env 不可达（ATOP miss-addr 构造性禁止） | [FS] §3 行5/§4；coverage-waivers CW-001；[R31] §4 |
| CW-002 | `axi_xbar`/`axi_mux`/err_slv `test_i` scan | Kind-A 出验证范围 | coverage-waivers CW-002 |
| CW-003/004/005 | `axi_err_slv` 恒定错误应答 `r.data[63:0]`/`r.resp`/`b.resp`/`r.user`/`b.user` | Kind-A 编译期常量 tie-off | coverage-waivers CW-003/004/005；[R30] §1 |
| CW-006 | 四模块 `rst_ni` 运行中复位方向 | Kind-A（spec §2.3 无热复位语义，范围外） | coverage-waivers CW-006 |
| CW-007 | mux/demux/err_slv `ar/aw.size[2]` 总线宽度上限位 | Kind-A（64-bit 总线 size[2]≡0） | coverage-waivers CW-007 |
| CW-008 | `addr_decode_dync` Branch（`sv:146` else，config_ongoing X-theater） | Kind-A（`config_ongoing_i≡0` tie-off，X 守卫永不可达） | coverage-waivers CW-008；[FS] §3 行1 |
| CW-009 | `axi_demux_simple` Cond `w_open==15`（1 bin） | Kind-A（mux w_fifo 深度 6 结构封顶 w_open≈9<15） | coverage-waivers CW-009；[FS] §3 行2 |
| CW-010 | flush_i tie-off 根因：rr_arb_tree Line / spill_register_flushable Assert（vacuous）/ fifo_v3·spill_flushable flush Cond·Branch 分量（bin-scoped） | Kind-A（flush 全例化点 tie `1'b0`） | coverage-waivers CW-010；[R31] §1；[FS] §5-3/§5-8 |
| CW-011 | `lzc` Toggle（常量 `index_lut` + 非-2-幂 padding，结构性永<90%） | Kind-A | coverage-waivers CW-011；[R31] §2；[FS] §5-4 |
| CW-012 | `axi_id_prepend` `pre_id_i[2:0]`（generate-loop 常量，bin-scoped） | Kind-A | coverage-waivers CW-012；[R31] §3；[FS] §5-2 |
| CW-013 | counter/delta_counter tie-off 位（`clear_i`/`load_i`/`d_i`/`down_i`/`overflow_o`，bin-scoped） | Kind-A | coverage-waivers CW-013；[R31] §6；[FS] §5-6 |
| CW-014 | `stream_register`（`r_resp_cmd`，6 例）**Line 全格（75.00）** + **Branch 全格（50.00）** + **Toggle 31-bit Kind-A 分量（22.00，bin-scoped）**：clr_i/testmode_i tie-off(P1,4bit) + rst_ni 1→0(P3,1bit) + push-gate valid/ready/data_o/reg_ena(P2,26bit)。**Toggle 的 `data_i.len[7:4]` 8 bit 定向可达分量不入本豁免**——路由 §6.1 DV-A(D1) | Kind-A（P1 tie-off + P2 push-gate 同 CW-001 INJECT_R 根因、env clause 7 禁 ATOP 送未命中 + P3 rst_ni 同 CW-006；**不折入父模块 CW-001**，spec §0#4 判定单位=（模块,类型）+ BUG-0038） | [R33]（REV-033 逐格裁决表 + coverage-waivers CW-014）；[FS] §2.3 L132 | 
| BUG-0044 | mux/err_slv `aw.atop[4]/[5]` 非-load 子类型（STORE/SWAP/CMP） | `ACCEPTED@M5` debt（§6 无非-load 应答 oracle） | bugs.md BUG-0044；[FS] §3 行3/4；[R30] §2.1 |

### 6.3 22 模块 × 6 类全格 → 归属对照（UNOWNED=∅ 可复核底板，REV-032 轴4 要求）

数据源 = [FS] §2.3 全闭包扫描表（逐格数字）。每格 token：**PASS**=≥90% 达标 · **N/A ⁿ**=
无 bin（成因号见表下）· **CW-xxx / BUG-xxxx**=书面豁免/债务承接 · **DV-x / 重测-n**=
§6.1 backlog 条目。**判据（spec §0#4）**：每个非-PASS/非-N/A 格必落 CW/BUG/§6.1 之一，
无空格 = UNOWNED=∅。这张表就是未来签核 rev 做 UNOWNED=∅ 交叉核读 + §8.2 未来 tooling
卡的底板。

| 模块 | 例 | Line | Cond | Toggle | FSM | Branch | Assert |
| --- | --- | --- | --- | --- | --- | --- | --- |
| axi_xbar | 1 | N/A¹ | N/A¹ | PASS(94.44) | N/A² | N/A¹ | PASS |
| axi_xbar_unmuxed | 1 | N/A¹ | PASS | PASS(98.89) | N/A² | PASS | PASS |
| addr_decode（父壳） | 12 | N/A¹ | N/A¹ | PASS(92.68) | N/A² | N/A¹ | N/A¹ |
| addr_decode_dync | 12 | PASS | PASS | PASS(92.00) | N/A² | **CW-008**(83.33) | PASS |
| axi_demux（父壳） | 6 | N/A¹ | N/A¹ | PASS(91.99) | N/A² | N/A¹ | N/A¹ |
| axi_demux_simple | 6 | PASS | **CW-009+DV-E**(82.76) | PASS(93.73) | N/A² | PASS | PASS(92.86) |
| axi_demux_id_counters | 12 | **DV-G**(73.91) | PASS | **DV-G**(74.06) | N/A² | **DV-G**(79.49) | PASS |
| counter | 108 | N/A³ | N/A³ | **CW-013+DV-A/DV-G**(43.48) | N/A² | N/A³ | N/A³ |
| delta_counter | 108 | PASS | N/A⁴ | **CW-013+DV-A/DV-G**(41.20) | N/A² | PASS | N/A⁵ |
| axi_err_slv | 6 | PASS | PASS | **CW-002/003/004/005/006/007+BUG-0044+DV-A+DV-D**(70.22) | N/A² | PASS | PASS |
| axi_atop_filter | 6 | **CW-001**(48.18) | **CW-001**(41.94) | **CW-001**(65.19) | **CW-001**(14.29) | **CW-001**(41.30) | PASS |
| stream_register | 6 | **CW-014**(75.00) | N/A⁶ | **CW-014+DV-A(D1)**(22.00) | N/A² | **CW-014**(50.00) | N/A⁵ |
| axi_mux | 8 | PASS | PASS | **CW-002/006/007+BUG-0044+DV-A/B/C**(89.34) | N/A² | PASS | PASS |
| axi_id_prepend | 48 | PASS | N/A⁷ | **CW-012+DV-C**(78.26) | N/A² | N/A⁷ | PASS |
| rr_arb_tree | 28 | **CW-010**(80.00) | PASS(95.74) | **CW-007/010+DV-A+DV-F**(77.45) | N/A² | PASS(91.59) | PASS |
| lzc | 56 | N/A³ | PASS(97.73) | **CW-011**(42.59) | N/A² | PASS(97.73) | PASS |
| fifo_v3 | 26 | PASS(92.68) | **CW-010+重测-1**(80.19) | **CW-010+DV-A/B+重测-1**(82.09) | N/A² | **CW-010+重测-1**(78.43) | PASS |
| axi_multicut | 48 | N/A¹ | N/A¹ | **DV-A/B 阴影**(89.22) | N/A² | N/A¹ | PASS |
| axi_cut | 48 | N/A¹ | N/A¹ | **DV-A/B 阴影**(89.22) | N/A² | N/A¹ | N/A¹ |
| spill_register（薄壳） | 322 | N/A¹ | N/A¹ | **DV-A/B 阴影**(88.51) | N/A² | N/A¹ | N/A¹ |
| spill_register_flushable | 322 | PASS | **CW-010+重测-2**(82.49) | **CW-010+DV-A/B+重测-2**(79.76) | N/A² | PASS | **CW-010**(0.00,vacuous) |
| axi_pkg | — | N/A⁸ | N/A⁸ | N/A⁸ | N/A² | N/A⁸ | PASS |

**N/A 成因号**（[FS] §2.3 逐条已核实）：¹ 纯例化壳/薄壳无本体过程语句（仅 Toggle 有 bin）·
² 无 `enum` FSM 状态寄存器 · ³ 顶层壳/generate 选择，Line/Cond/Branch 无独立 bin ·
⁴ 无多项布尔组合式（VCS Cond 不生 bin）· ⁵ 无 `assert` · ⁶ 无 `if`/`case`/`?:` 条件语句 ·
⁷ generate-if 编译期常量条件（无运行时 Cond/Branch bin）· ⁸ package-scope 内联计入调用点模块。

**UNOWNED=∅ 核验**：全表 132 格逐格有 token，**无空白格、无未归属 <90% 格**——`stream_register`
三格（Line/Toggle/Branch，REV-032 轴4 曾发现的漏账）现由 CW-014（+ Toggle 的 D1→DV-A）承接，
UNOWNED 归零。

---

## 7. 锚点完整性核对清单

逐条自证"零移动 / 不受扰动"：

### 7.1 三条 `ACCEPTED@M5` 债务锚点零移动

| 债务 | 守卫 spec 面 | 到期锚 | 本提案是否触碰 | 结论 |
| --- | --- | --- | --- | --- |
| BUG-0044 | §6（atop 非-load 应答义务）+ verification_maturity 决策点 2 C2.5 | @M5 签核 | **否**——不动 §6、不动 C2.5（只动 verification_maturity §0 范围行 + §5 标题批注） | 锚零移动，`@M5` 字符串不改 |
| BUG-0045 | §3.2（`end_addr=='0` 哨兵） | @M5 签核 | **否**——不动 §3.2 | 锚零移动 |
| BUG-0046 | §3.2（doc-vs-RTL `<=` vs `<`，不得悄收紧为 `<`） | @M5 签核 | **否**——不动 §3.2 | 锚零移动 |

- **版本方案变更不移锚**：M5 版本串由 `v1.1.*` 改 `v0.5.*`，但三债务锚定的是
  **里程碑号 M5**（`ACCEPTED@M5`），非版本串——`@M5` 字符串在 bugs.md 三行**一字
  不改**。M5 编号与性质（方法论里程碑、排 M4 签核后）不变，故债务到期语义零改动。

### 7.2 五条 guard 逐条不违反（`make guards` 命中面）

| guard | 守卫 paths | 本提案动的面 | 合规论证 |
| --- | --- | --- | --- |
| BUG-0038 | `doc/spec.md` §0#4 | §0#4 处置指向句（百分比门迁 M6） | **不动**例化闭包定义（`addr_decode_dync`/`axi_demux_simple` 仍在 scope）与 N/A 三态成因规则；guard 要的"出口门 checker 须明确 ≥90% scope"仍由 §0#4 闭包定义原样回答，迁 M6 后对应 M6 出口门（同 scope）；UNOWNED=∅ 正是 guard 要的 dashboard 可区分 |
| BUG-0039 | `doc/spec.md` §4 clause 7 + testplan | **无**（不触 §4、不改任何 decode-miss 激励行） | decode-miss `atop≡'0` 约束不受扰动；M4 签核机核抽查（grep decode-miss 激励 atop≡'0）形式不变 |
| BUG-0044 | `doc/spec.md` §6 + verification_maturity 决策点 2 C2.5 | verification_maturity §0 范围行 + §5 标题批注 | **不动** §6、**不动** C2.5；atop 有界子集（`{'0}∪load 编码`）不放开，无 store/swap/compare |
| BUG-0045 | `doc/spec.md` §3.2 | **无** | §3.2 一字不动 |
| BUG-0046 | `doc/spec.md` §3.2 | **无** | §3.2 一字不动，`<=` 不悄悄收紧为 `<` |

### 7.3 版本方案自洽

0.M.P 规则下：M4=0.4.x（签核仍在 v0.4.*，**不再**转 v1.0.0）· M5=0.5.x
（签核 v0.5.*）· M6=0.6.x（签核 v0.6.*，签核后转 **v1.0.0**）。旧草稿 M5 挂 v1.1.*/
转 v1.0.0 的写法（0.M.P 不自洽的遗留）本提案修正。**`iverif.json` `framework`
字段（0.8.0）= 上游框架版本，与项目里程碑版本正交，不动**。

### 7.4 既有 chain-audit 形状不受扰动

- **"仅锚父节" 14 处**（log [0.4.36]/[0.4.35]）：本提案**不增删任何 testplan 场景
  行、不增删任何 feature-matrix 行**——只重构里程碑治理文本 + spec §0#4 一句 +
  coverage-waivers 抬头一行 + verification_maturity 两处。故 chain audit 的
  feature↔scenario 链接形状零改动，"仅锚父节 14 处"与现状一致。
- **Abstract M4 场景列 `0→8/8`** 是显示订正（对齐 testplan 现有 8 行事实），非新增
  场景，不进 chain audit。

---

## 8. M4 新出口的机核 / 人核划分说明

**原则（BUG-0038 guard 精神）**：不得把无法机核的条件伪装成机器门。

### 8.1 机器可核（`make check MILESTONE=4` 现有四条，本重构不改其形）

| # | 条件 | 机核方式 |
| --- | --- | --- |
| 1 | M4 全 8 场景 ✅（或带 rev 记录豁免） | testplan 状态列机读 |
| 2 | `make regress` 摘要入证据、100% PASS（含全 regression-guard） | result_summary 机读 |
| 3 | bugs 全终态或未到期 `ACCEPTED`；CLOSED 行有复验证据；FL 页必填段非空 | bugs.md 机读 |
| 4 | ≥1 条打 M4 标签的 KILL 行 | bugs.md 机读 |

### 8.2 机核性质澄清：`UNOWNED = 空集` **当前为人核，机核可选待建**

- **诚实声明**：`UNOWNED=∅` 需交叉核对**扫描表 × CW 表 × bugs.md 债务 × M6 backlog**
  四份 markdown 表的集合差（<90% 格集 − 已归属集 = ∅）。**`make check` 今日无此
  交叉校验脚本**，现状是 rev/orch 人工交叉读（log [0.4.36] orch 独立复验即此形）。
- **不伪装成机器门**（BUG-0038 guard：checklist 型，"if/when one is mechanized
  beyond urg eyeballing"）：本提案**不**宣称 UNOWNED=∅ 是 `make check` 机器条件；
  它是 **rev 签核人核项**（§8.3）。
- **可选待建（非本 L3 提案范围，建议未来 L0/L1 tooling 卡）**：一个解析四表、算
  集合差的脚本可把 UNOWNED=∅ 升为机核——属本仓库自有 `scripts/` 资产，不受上游
  同步约束。**§6.3 的 22×6 全格→归属对照表即该脚本的解析底板**（REV-032 Guidance 3）。
  **建议但不强制**；未建成前维持人核，绝不预先在 `make check` 里挂一个空转的"总是
  绿"伪门。

### 8.3 人核（rev 签核 rubric，`doc/evidence/v0.4.*/signoff-M4.md`）

| rubric | M4 人核项 |
| --- | --- |
| #5 | **UNOWNED=∅ 交叉核读**（核心新出口）：以 §6.3 22×6 全格→归属对照为底板，逐 <90% 格确认归入四类归属之一、无空白格（含 `stream_register` CW-014，REV-032 轴4 曾漏的格）；抽 1 条 Kind-A 重读不可达论证；判 KILL 集是否覆盖 M4 触及的每类 checker（不只"≥1"） |
| #6 | `make guards FILES="doc/spec.md doc/milestone.md doc/coverage-waivers.md"` 每命中项确认已遵守；证伪至少一条（抛回原缺陷确认 guard 变红） |
| #7 | open SPEC_ISSUE 清单空或各有书面接受理由 |
| #8 | 三条 `ACCEPTED@M5` 债务真实（各引 REV 记录有可证伪理由；非自动延期） |
| #9 | 贴一次 `make check MILESTONE=4` 报告，每 gap 类给处置或书面接受 |

---

## 9. 自查

### 9.1 五条不变量合规自评

1. **无 sim log 不 ✅**：本提案是治理重构，**不把任何场景变绿**、不声称任何 evidence；
   M4/M5/M6 出口的 ✅ 仍只由 `make evidence` 产生。合规。
2. **记录首行即重放命令**：本文是 design-prompt 提案、非 evidence 记录，无重放命令
   要求；引用的取数命令（[FS] 命令①②）均已在源文件带 CMD 头。合规。
3. **closer ≠ fixer**：本卡 arch 产出，去 rev 门禁（卡C）由**独立 rev 实例**审——
   arch 与 rev 绝不共用（§0 隔离）。合规。
4. **spec 钉死**：唯一 pinned-spec 改动（§0#4）是**里程碑绑定**改动（百分比门迁
   M6），六类口径不变；期望值仍只从 spec 推导，不从 RTL——backlog 表全部信号/bin
   来自 rev 已亲验的 [FS]/[R30]/[R31]（观测事实作路由线索，非 checker 期望）。
   **本文不改 spec 正文、不重 pin**（orch 在 rev 批准后做）。合规。
5. **无击杀不采信**：M4 KILL 覆盖要求保留；M5 三类新 checker KILL 保留；M6 定向卡
   新 checker 路径 KILL 新增要求。不变量 5 三里程碑全覆盖。合规。

### 9.2 §3 门禁顺序合规自评

- **DE 新功能卡派发前 design-prompt 过 rev**：本 design-prompt 自身即待 rev 门禁
  （卡C）；orch 未过 rev 前不应用、不派任何据此的 DV-A~G 卡。合规。
- **bug 卡派发前 bugs.md 行存在**：本卡不派 bug 卡；BUG-0047 谱系行已存在
  （archive）。合规。
- **里程碑关闭前 make check + rev 签核二者缺一不可**：新 M4/M5/M6 出口均保留
  `make check MILESTONE=<n>` + `signoff-M<n>.md` 双要求。合规。

### 9.3 「定级 vs 实际」

- **定级 L3**（spec/豁免/签核面，rev 必到，全 rubric）。**实际 L3 相符**：本卡动
  pinned-spec §0#4（提案）+ 里程碑治理三节 + coverage-waivers 抬头 + arch 面
  verification_maturity——纯治理/判据口径重构，无 RTL/TB/仿真、无期望值推导。
  **无失配**。

### 9.4 Taxonomy-class anomaly

- **命中已有 SPEC_ISSUE：BUG-0047**（非新类）。本卡是 BUG-0047 终判**选项 (ii)**
  （重议判据口径 + spec §0 变更提案 + rev 门禁）的正式实现——**不新开 bugs.md 行**。
- **flag 给 orch（登记面，非新类）**：BUG-0047 archive 行 taxonomy 现记
  `SPEC_CHANGED`，但其 `BUG-0047.md ## fix` 段写"无 spec 正文改动、不重 pin"（REV-024
  当时只走选项 (i) 的豁免框架）。**本提案 §2 首次给出 BUG-0047 的实际 §0#4 变更**；
  orch 在 rev 批准、编辑 §0#4 并重 pin 后，须把 BUG-0047 的终态与该重 pin 证据对齐
  （补选项 (ii) 的落地引用）。这是既有行的状态对齐，不是新 taxonomy 实例。
- **G-1 返工谱系：BUG-0049**（已有台账行，非新类）。REV-032 门禁轴4 发现本提案初版
  §6 继承 [FS] §8 / REV-031 的 `stream_register` 三格漏账（silent-exclude 失效类，
  `workflow/bugs.md` L229），登记 `doc/bugs.md` BUG-0049；归属裁决由独立 rev 完成
  （REV-033：Line/Branch 全 Kind-A、Toggle 31-bit Kind-A + 8-bit D1 定向）。**本次
  返工据 REV-033/CW-014 补入 §6.1 DV-A(D1) + §6.2 CW-014 + §6.3 全格对照**，闭合该
  漏账，UNOWNED=∅ 现为**可复核事实**（§6.3）而非失实宣告。BUG-0049 属 BUG-0047
  planning-gap 同伞，其 `CLOSED` 由 closer（≠fixer/≠rev）另派——非本卡动作。
