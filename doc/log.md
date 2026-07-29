# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.3.6] 2026-07-29 框架 0.8.0 换底盘：手工移植「repo 即模板」模型

**Done**
- **框架 0.7.1 → 0.8.0，性质是断裂而非升级**：上游删除 `fwsync.py`，
  `make fw-pull` **没有对端**；官方升级路径是 `git cherry-pick`，而 0.8.0 是
  一次 24 份契约→4 份的重排，cherry-pick 到本仓库（46 commit / 3 个里程碑
  证据）只会得到冲突堆。⇒ **只能手工移植**，本 chunk 即该移植
- **移植前先在隔离 worktree 实做一遍完整迁移**（删旧机械层→植入 0.8.0→
  跑全部 target→观察），确认可行后才动主树；试迁移 worktree 已清理
- **关键实测结论：数据层 100% 兼容，`doc/` 一个字未改**。`make handoff` /
  `check` / `next` / `guards` 直接跑通既有 testplan / bugs / evidence /
  feature-matrix；`ACCEPTED@M<n>`、`columns_preset` 均保留。换掉的纯是机械层
- **机械层替换清单**：`workflow/` 27 份 → 4 份
  （`discipline` / `bugs` / `records` / `review`）；删
  `scripts/fwsync.py`、`scripts/iverif.manifest.json`、
  `scripts/make/{core,evidence}.mk`；`.claude/agents/` 改为静态 5 份
  （**新增 `orch.md`**，不再渲染）；根 `Makefile` 换成 canon 版 + 追加本项目
  的 sim 转发（smoke/cov/lint/verdi/clean）
- **命令改名对照**（已同步进所有活文件）：`handover`→`handoff` ·
  `docs-check`/`chain-audit`/`signoff-check`/`explore` 四个动词收成一个
  `check`（`SCEN=`/`MILESTONE=` 决定视图）· `docs-archive`→`archive` ·
  `bump-minor`→`bump minor=1` · `replay` 取消（不变量 2 已保证首行即命令）·
  新增 `commit`（add+commit，**永不 push**）与 `selftest`
- **`scripts/regress.py` 保留，归属改为本项目**——0.8.0 删了它但同时明说
  「canon 不再拥有循环，项目拥有循环」，而 `sim/Makefile:72` 实际调用它、
  M2 签核的 11/11 独立重跑依赖它逐字工作。删掉重写属无谓风险
- **`doc/design-prompt/` 路径未动**：核实 `iverif_config.py:181` 仍要求
  `doc/design-prompt/README.md`，CLAUDE.md 表里写 `design-prompt/` 是简写。
  省掉一次会再制造数十处死指针的路径迁移（FB-23 的教训）
- **`CLAUDE.md` 重写**：0.8.0 把 L0–L3 分级表移入项目 CLAUDE.md **并加了
  测试强制它在场**；同时旧文引用的 `constitution.md` / `profile.md` /
  「hash 锁定的框架快照」/ `fw-check` / `docs-check` 全部已不存在。新版
  保留 §0 隔离、§4 环境（xverif 体系与 VCS-2018 变通）、§6 项目专属，
  新增五条不变量与分级表，里程碑定义移出至 `doc/milestone.md`
- **新建 `doc/milestone.md`**（0.8.0 的 orch 自有文件）：M0–M4 出口条件逐条
  落盘，含 M3 的多配置声明式子集裁决与 KILL 要求
- **裁决：不变量 5「无击杀不采信」自 M3 起生效，M0/M1/M2 不回填 KILL 行**
  （同 FB-23「冻结记录不回改」）。实测 `make check MILESTONE=2` 条件 4 现为
  FAIL——但 M2 **确实做过**击杀自证，取证位置
  `doc/evidence/v0.2.5/signoff-M2.md` rubric #5（BUG-0027 缺陷放回见 336 条
  红后复原）。⇒ 已知**记账**缺口，非实质缺口；该判断连同取证位置同时写入
  `CLAUDE.md` 不变量 5 与 `doc/milestone.md` 抬头，避免后人误读为真缺口
- **四个 skill 保留为本地资产并重写**（0.8.0 上游已废弃 `.claude/skills/`）：
  `handover`→`handoff` 目录改名以对齐 make 目标；`closeout` 的门禁步骤改
  `check`+`selftest`；`dispatch` 的分级表**删除本地副本、改为指向 CLAUDE.md**
  （0.8.0 移动它的用意就是终结双份漂移）；`evidence` 的 `replay`/
  `signoff-check` 改为新形态
- **CI 与 hook 修复**：`ci.yml` 两处失效调用（`docs.py --handover` 已改名、
  `fwsync.py --check` 文件已删）→ 改为 `--handoff` + 以 `selftest` 顶替
  fw-check 的位置；`.githooks/pre-commit` 删除 fwsync 那两行（原为
  `|| echo`，不挡提交但会每次提交打一句假警告）
- **登记 FB-27**（annoyance，open）：**0.8.0 删掉四个 make 动词，但它自己
  发布的两张角色卡仍在指令角色执行其中两个**——`.claude/agents/arch.md:34`
  写 `make explore`、`rev.md:51` 写 `make signoff-check`，二者均已 retire。
  命中面精确落在最坏位置：这不是背景说明而是 arch 的 spec-gap sweep 与 rev
  的里程碑签核**各自主任务的操作指令**，照做直接 `No rule to make target`。
  两处已就地修并在代码旁注明 `见 FB-27`
- **订正 FB-25（不改原文，并列存证）**：FB-25 断言「没有任何门禁读 CLAUDE.md
  的内容」，0.8.0 起**部分不成立**——`scripts/tests/test_docs.py:477` 会读
  项目 CLAUDE.md 断言 L0–L3 表在场；本仓库迁移时正是被这条挂掉 1/60 才发现。
  FB-25 现只在「路径有效性」半边成立
- **`doc/fw-feedback.md` 抬头仪式改写**：0.8.0 删掉三态漂移检测后，「绝不
  本地修改 scripts/workflow」这条红线**在机制上已不存在**。本仓库改采
  「**先登记、可就地修，两者都做**」，且就地修的每一处必须在台账留行 + 代码
  旁注明 FB 编号——否则退化成 FB-7/BUG-0007 那个形状（变通只落注释、无人可
  grep）
- **收尾时补上一个自造的接手缺口**：迁移中我删掉了 `iverif.json` 的
  `framework_repo`（fwsync 已亡，该字段无人读），但 CLAUDE.md §5 仍写着
  「跟进上游：**保留 remote**」——而 `git remote -v` 里根本没有那个 remote，
  上游位置遂无处可查。**这正是本会话反复报的「指令没有机制」，且是我自己
  造的**。已补：加 `upstream` remote 指向 GitHub（`.git/config` 不随仓库走，
  故同时把这条与 hooksPath 并列写进 CLAUDE.md §5 的一次性设置）；并**记录
  移植基线 `upstream 05a49a0`（0.8.0）**，使「上游比我们多了什么」成为一条
  机械命令：`git log 05a49a0..upstream/master --oneline`。实测该命令当场
  返回 1 条（`e23d938 删除 VENDOR.md`——删的是上游 `doc/VENDOR.md` 壳文件，
  本仓库用的是 `vendor/VENDOR.md`，不受影响）

**Not done**
- **本 chunk 不含任何仿真**，无新证据，testplan 计数不变（M3 仍 ✅0/11）
- **M3 的 KILL 行尚未产生**——不变量 5 自 M3 生效，但注伤自证要到执行卡才
  做得出来。`make check MILESTONE=3` 条件 4 现为 FAIL，属预期，须在 M3 签核
  前由某张执行卡兑现
- FB-23/24/25/26/27 五条均 `open`，本 chunk 只登记未回流
- **L0–L3 分级仍是零实走**（连续第三个 chunk）：本会话三次框架变更、零张卡，
  「定级 vs 实际」失配数据产量仍为 0。此即 FB-26 报告的现象在继续发生
- 0.8.0 的 `workflow/` 四份契约（含新的 `bugs.md` 13.7KB）**未逐字通读**——
  只核对了本仓库直接依赖的接口（KILL、ACCEPTED、五类判据名）。若其中有细则
  变更，会在下一张卡的交付报告格式上暴露
- `DESIGN.md`（上游 canon-only 沿革文档）未克隆进本仓库，需要时去框架 repo 读

**Next**
- 派 rev 仲裁卡（L3），一卡三事：① BUG-0032 终判 ② §4/§5.3 自引用提案
  **建议否决**（须把 FB-24 的根因分析入卡，否则 rev 会在不知道
  parent-anchored=15 是解析器产物的前提下裁决）③ 复核本 chunk 的两处 orch
  越界判断——0.3.4 动 design-prompt 三行、本次动 `.claude/agents/` 两处
  （后者在 0.8.0 语义下已属本地文件，但仍是 orch 改角色卡）
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）。**其中至少一张须兑现 M3 的 KILL 行**
- 首次派卡时同时验证：新版静态角色卡的实际行为、L0–L3 定级失配记录、
  `/dispatch` skill 指向 CLAUDE.md 分级表是否真的可用

**How verified**
- `make check` 绿（docs-check passed + chain audit，dangling 仍 0）；
  `make selftest` **60/60 OK**（移植过程中一度 59/60，挂的正是
  `test_claude_md_carries_risk_grades`，重写 CLAUDE.md 后转绿——该失败即
  FB-25 订正的直接证据）
- `make handoff` / `make next` / `make guards FILES=...` 三条均实跑，输出与
  0.7.1 下逐项一致（next 12 条动作、guards 正确命中 BUG-0007）
- `make check MILESTONE=2` 与 `MILESTONE=3` 均实跑，条件 4 FAIL 系亲眼所见
  而非推断；M2 击杀自证的取证位置经 `doc/status.jsonl` 0.3.0 行复核
- 字节预算：`CLAUDE.md` + `workflow/*.md` = **38531 / 39500**，较迁移前
  （39042）**更宽松**——旧 CLAUDE.md 9120B 换成新版后总量下降
- 失效引用清扫：`grep` 全部活文件（CLAUDE.md / .claude/ / doc 表头 /
  .githooks / .github）确认无残留旧命令名与旧 workflow 路径；命中的剩余项
  全部位于 `doc/fw-feedback.md` 的**冻结历史行**，按 FB-23 裁决不动
- 上游动词悬空（FB-27）非目测：`grep -o "^[a-z]*:" Makefile` 取实有目标集，
  与 `grep -on "make [a-z-]*" .claude/agents/*.md` 求差得出
- 接手性实测（本 chunk 收尾）：`make handoff` 实跑，版本/状态/log 尾块正常
  读出；`git status` 0 未提交、`git log origin/master..HEAD` 0 未推送；
  `git log 05a49a0..upstream/master` 实跑返回 1 条，证明新加的上游基线机制
  确实可用而非又一条空指令

## [0.3.5] 2026-07-29 pull 框架 0.7.1 + 压测 explore：§id 解析器幻影率 44%（FB-24）

**Done**
- **pull 框架 0.7.0 → 0.7.1**（27 files pinned）。与 0.3.4 那次不同，**本次是
  行为变更**：两行从 deferred 台账**由用户裁决提前毕业**，CHANGELOG 明写
  「to be stress-walked by the adopters」——那个 adopter 就是本仓库。同样先在
  隔离 worktree 预演（fw-check / docs-check / chain-audit 全绿，chain-audit
  逐项与 0.7.0 一致）后才落主树
- **(a) spec-gap 探索器**（`docs.py --explore` / `make explore`）：chain-audit
  图的规划视图，把 uncited 章节连同标题列成候选 testplan 行。附带一个
  `--next` 规划期提示，**仅在当前里程碑零登记行时触发**——本仓库 M3 已有 11
  行 ⇒ 实测正确保持沉默（无 FB-19 那种常驻唠叨）。新增 copilot 卡型
  「arch spec-gap sweep」，契约要求 explore 列表**逐字进卡**且禁止 orch 掺入
  自己的场景想法
- **(b) L0–L3 风险分级**进 dispatch 手册，取代原「模型档位」清单：L0 文档/
  构建 · L1 TB/序列/覆盖 · L2 RTL/SVA/scoreboard · L3 spec/豁免/签核。分级
  **只调链条重量**，taxonomy 登记与 evidence 门禁在每一级都无条件。每张卡须
  声明分级，且**每卡记录「分级 vs 实际」的失配**——该裁决推翻了 0.4.6 的
  观察者设计，理由锋利：无人抱怨流程重 ≠ 流程轻，因为每个子代理只看见自己
  那张卡、链条重量只有 orch 看得见、而**orch 不疼**。零记录 ≠ 零重量
- **压测 `make explore` 当场命中一条实质缺陷 → 登记 FB-24**（annoyance，
  open）：explore 交给 arch 的 9 条前沿里 **4 条不是 spec 章节，幻影率 44%**。
  `§1.3` 实为 `spec.md:436` 的 **`REV-011 §1.3`**（评审记录章节号被吸进 spec
  命名空间）；`§7.1.2`/`§7.4.3`/`§7.4.4` 是 `§7.1`/`§7.4` **正文有序列表的第
  2/3/4 条**（实读 `spec.md:328-345`、`376-400` 确认 §7.4 body 是 1.–5. 列表、
  无任何子标题）
- **全谱实算**（脚本，非目测）：spec 有 **25 个真标题**，正文出现 **45 个
  §id**，其中 **22 个无对应标题**——`§5.4.1` 被引 9 次、`§5.2.1`/`§5.2.3` 各
  7 次。⇒ 本仓库 spec 的**主导引用惯例就是「§<标题>.<列表项>」**，是文体不是
  笔误。0.6.0 引入 inline-token 解析本为让 `SPEC-5.2.1` 可解析（否则 100%
  假阳），代价即 uncited 集合混入列表项
- **定性：不是回归，是「无消费者的不精确，在获得消费者的当天暴露」**——
  chain-audit 阶段它只是个没人行动的计数（FB-21 同族），0.7.1 把它变成派工
  指令且**禁止 orch 过滤**，不精确遂变成错工单
- **比幻影更糟的一类已识别**：`§7.4.3` 是真条款但内容为**禁令**（「任何
  latency checker **不得**断言固定周期数」）。禁令由 checker 的**缺席**满足，
  语义上永远无法被场景覆盖 ⇒ arch 只能逐条写 decline，而 decline 按卡契约是
  narrowing 须 rev 门禁 ⇒ **解析器的不精确机械地制造 rev 工作量**
- **同一根因解释了 parent-anchored=15**：`§4` 只有 `## 4.` 一个标题、条款是
  列表项 4.1–4.5；testplan 引 SPEC-4.1~4.5，其中在正文被 inline 提及的
  （§4.1/§4.5）解析成功，未提及的（§4.2/4.3/4.4）跌回父级 §4。**据此建议
  否决 arch 在 0.3.3 提的「§4/§5.3 补自引用以降 parent-anchored」提案**——
  那实质是往 spec 正文里写字去迁就解析器，spec 文体不该为工具让步；根因在
  FB-24，修在框架侧
- **对 FB-22 的自我订正已存证**：FB-22 举证「静默截断丢掉 §7.4.3/§7.4.4/
  §8.3/§8.4」，按今日全谱统计**这四个 id 全是幻影**。FB-22 核心主张（字符串
  序 + 无提示截断）不受影响且已正确修复；受影响的只是「被隐藏的是什么」这半
  段举证。按 FB-23 同一裁决**不改 FB-22 原文**，在台账并列一行 `recorded` 存证

**Not done**
- **本 chunk 不含任何仿真**，无新证据，testplan 计数不变（M3 仍 ✅0/11）
- FB-24 与 FB-23 均 `open`，尚未回流框架仓库
- **L0–L3 分级机制一次也没实走**——本会话仍未派任何卡，「分级 vs 实际」失配
  数据（0.7.1 明说这才是提前释出的目的）产量为 **0**。本条是欠框架的
- M3 实质工作仍一步未动：rev 仲裁卡与五张执行卡全部待派
- explore 的另外 5 条（§2.1/§2.2/§2.3/§7.1/§7.3，均为真标题）**未评估**是否
  值得建行——那是 arch 的判断，orch 不代劳

**Next**
- **arch spec-gap 卡在 FB-24 闭环前不派**——卡契约要求 explore 列表逐字进卡
  且禁止 orch 过滤，现在派就是让 arch 按 44% 错的清单干活
- 派 rev 仲裁卡（L3）：BUG-0032 终判 + **§4/§5.3 自引用提案建议否决**（须把
  FB-24 的根因分析一并入卡，否则 rev 会在不知道 parent-anchored 是解析器
  产物的前提下裁决）。该卡同时是 L0–L3 分级与新版角色文件的首次实测
- 五张 M3 执行卡（**严格顺序**，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L1/L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）——分级为初判，派卡时按 dispatch 手册复核并记失配
- 若 rev 认为 0.3.4 里 orch 动 design-prompt 三行越界，回退那三行

**How verified**
- `make fw-check` 绿（framework 0.7.1，27 files pinned）；`make docs-check` 绿
- `make chain-audit` 逐项与 0.7.0 完全一致（dangling 仍 0 / sourceless 1 /
  orphans 0 / parent-anchored 15 / uncited 9）⇒ 0.7.1 未改判据，explore 与
  chain-audit 共用 `chain_gaps()` 属实
- `make explore` 实跑，输出 9 条前沿 + 「M3, 11 scenario rows registered」；
  `make next` 实跑确认规划期 nag **未**触发（M3 非零登记行）
- 幻影认定非目测：逐个 `grep "^#\+ *§\?<id>"` 确认无标题，再 `sed -n` 实读
  §7.1（L328-345）与 §7.4（L376-400）正文确认是有序列表；`§1.3` 实读
  `spec.md:436` 确认前缀为 `REV-011`
- 25/45/22 三个数字由一次性 python 脚本实算（正则提取标题集与 inline §id 集
  求差），非估计
- 升级前预演在 `git worktree` 隔离副本完成，主工作树全程干净，预演后
  `worktree remove --force` + `prune`

## [0.3.4] 2026-07-29 pull 框架 0.7.0（结构重排）+ 路径迁移的活/冻二分裁决

**Done**
- **pull 框架 0.6.1 → 0.7.0**（27 files pinned，较 0.6.1 +1）。**升级前先在
  临时 worktree 实拉预演**（`git worktree add --detach` → `fwsync --pull` →
  跑全部门禁 → `worktree remove`），未采信 CHANGELOG 自述；预演证实：
  fw-check / docs-check / handover / chain-audit 四项全绿，本仓库
  `scripts/iverif.divergence.json` 为空 ⇒ 无本地改动需 re-key，10 个孤儿
  文件被 fwsync 自动清扫
- **实测认定 0.7.0 为纯结构重排、零行为规则变更**。逐字读 diff（13 文件
  45+/30-）后归为三类且仅此三类：① 路径重命名（`workflow/signoff/` →
  `workflow/review/`；`workflow/{schema,taxonomy,dispatch}/` → 顶层 +
  `workflow/fail/`）；② 每份文档新增 provenance 标头（`Axioms:` /
  `Consumer:`）；③ 一处死指针订正——`discipline.md` 原写"四条核心不变式
  (README)"，而 README 不在快照内 ⇒ **该指针在每个项目副本里都是死的**，
  0.7.0 改指新增的 `workflow/constitution.md`。**无一条判据/门禁阈值/角色
  边界/报告格式变化** ⇒ M2 已签核的 8 条证据与 M3 已交付的设计输入均不受
  影响，无需重跑任何仿真
- 新增 `workflow/constitution.md`（4800B 硬上限）：五条公理（自反·独立·
  落盘·消费·痛点）+ 一张机器循环图 + 四条核心不变式的正式归属地 + 文档→
  公理→消费者索引表。会话阅读序变为 constitution → discipline → profile
- **活文件路径迁移（框架不自动改，须手工）**：`CLAUDE.md` 三条框架路径
  （§1 testplan 契约 / §2 分诊表 + failure_record / §2 failure_taxonomy）
  + 抬头补 constitution read-first 行 + 渲染来源注释改指
  `harness/templates/`；`doc/testplan.md:3` 与 `doc/bugs.md:3` 表头契约路径
  （**核实过**：0.7.0 的 `fwsync.py:340-363` seed 已写新路径，但只在
  `--init` 生成，既有仓库不会自动更新）；`doc/fw-feedback.md:7` 的
  `iverif-workflow/docs/adoption.md` → `governance/adoption.md`
- **三份 design-prompt 的 `workflow/dispatch/coverage_hole.md` 死指针已修**
  （`sva_bind.md:81`、`functional_coverage.md:127`、`uvm_env.md:99`）——这
  三份正是 M3 五张执行卡的输入，留着会让 DV 实例按图索骥扑空。**边界声明**：
  design-prompt 属 arch 制品（CLAUDE.md §0「orch 不写 design-prompt」），
  orch 此处只做**纯路径 token 替换**，每份净变更 1 行、`git diff
  --word-diff` 已自证除路径外一字未动；派 arch 卡改三个路径不合比例
  （公理 4 痛点 / discipline rule 2 简单优先）。若 rev 认为仍越界，回退成本
  为三行
- **裁决：冻结记录一律不迁移**——`doc/review/REV-*.md`、
  `doc/evidence/*/signoff-M*.md`、`doc/bugs/BUG-*.md`、`doc/archive/` 共
  **16 份文件 39 处**旧路径引用保持原样。理由：它们记录的是"当时那份契约在
  哪"，回改等于伪造审计线索，与 evidence 不可回改同一条道理。代价是这 39
  处从此指向不存在的路径，且**没有任何门禁会报**（docs-check/fw-check/
  chain-audit 都不校验 workflow 路径引用）
- **登记 FB-23**（annoyance，open）：canon 重排在采纳者冻结记录里留下永久
  死指针，而 0.7.0 升级须知只覆盖活文件（CLAUDE.md / divergence.json /
  next_phrases_override），对不得回改的记录只字未提。含一处框架内部真张力
  （落盘公理 vs evidence 不可回改 ⇒ 指针必然死，非谁做错），故需一条明写
  约定否则每个采纳者各判一遍；本仓库实证含三份签核书的"判据来源"抬头指向
  已不存在的 `workflow/signoff/rubric.md`——**签核书声明自己依据的那份判据
  路径已不存在**。三条建议：① CHANGELOG 明文声明"冻结记录保留旧路径是正确
  行为"；② 加只追加的 `governance/path-map.md` 供反查（落在消费公理上：
  这些指针的消费者是未来回溯审计线索的人，今天无机制服务他）；③ 由 fwsync
  从历次 manifest 差分机械生成该表

**Not done**
- **本 chunk 不含任何仿真**——纯框架升级 + 文档路径迁移，无新证据登记，
  testplan 计数不变（M3 仍 ✅0/11）
- FB-23 状态 `open`，尚未回流框架仓库（框架作者在隔壁 session，可当日闭环）
- M3 实质工作一步未动：rev 仲裁卡（BUG-0032）与五张执行卡仍全部待派
- `.claude/agents/` 四份角色文件已由 pull 重新生成，但**本会话未实际派发过
  任何卡** ⇒ 新版角色文件在真实派发下的行为未经实测（adoption.md 提示
  agent 类型注册有延迟，首次派发若报 "Agent type not found" 是已知现象，
  重启会话即可，不要去 debug 卡本身）

**Next**
- 派 rev 仲裁卡：BUG-0032 状态终判（沿用 BUG-0002/0003 先例是否成立）+
  是否需要 spec 补条款；顺带评估 §4/§5.3 自引用编辑提案是否值得动 pin。
  **该卡同时是新版角色文件的首次实测**
- 按 arch 建议的五块切分派发 M3 执行卡（**严格顺序**，④ 必须先于 ⑤）：
  ① BUG-0025+0031 同卡修 + M3-DE01/DE02/OR04/CFG02 ② BUG-0024 (b) 路线 +
  M3-OR05 ③ BUG-0018 修 + 重跑 M2-OR01/WO01 ④ 多配置基建（tb_top
  C5.1-C5.7 声明式配置点）+ M3-CF01 ⑤ M3-CF02/03/04 + M3-AT02
- 若 rev 认为 orch 动 design-prompt 越界，回退那三行并改派 arch 卡
- M3 签核卡需重做"判决活性矩阵"（M2 签核人交办）；BUG-0025/0031 详情页
  `ref: 待定` 待其修复卡落地时填入具体 cover/assert 名

**How verified**
- `make fw-check` 绿（framework 0.7.0，27 files pinned）；`make docs-check`
  绿；`make handover` 正常读出状态
- `make chain-audit`：dangling **仍为 0**；sourceless 1 / matrix orphans 0 /
  parent-anchored 15 / uncited 9 / 无 spec_ref 头 11——**逐项与升级前
  （0.3.3 区块记录）完全一致**，证实升级未改变任何审计判据
- 升级前预演在 `git worktree` 隔离副本中完成，主工作树全程干净
  （`git status --short` 空），预演结束 `worktree remove --force` +
  `worktree prune`
- design-prompt 三处改动的"纯路径替换"以 `git diff --word-diff=plain` +
  `--numstat` 双重自证：每份 `1  1`，词级 diff 仅显示路径 token 一对一替换
- 冻结记录死指针规模以 `grep -rl` / `grep -ro` 双计得出：16 份文件、39 处

