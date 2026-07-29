# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.3.7] 2026-07-29 删除 orch.md 并入 /dispatch；反馈台账转为实践记录

**Done**
- **裁决：与上游的关系反转。** 0.8.0 删掉 fwsync/manifest/divergence 三态后
  已无回流机制，用户裁定新姿势为——**我们先实践，做得好让上游来
  cherry-pick**。本 chunk 落实这条裁决的两个后果
- **删除 `.claude/agents/orch.md`，内容并入 `/dispatch` skill + `CLAUDE.md`
  §0**（登记 FB-28，status `local`）。**机制事实为本会话直接观测所得、非
  推断**：`.claude/agents/*.md` 在 Claude Code 里只注册**可派发的子代理
  类型**，正文仅在派发时注入**新实例**；主会话收到的只有 frontmatter 的
  `description` 一行。⇒ 那 87 行通篇写着 "You are orch — the main session"
  的硬规则，**唯一读不到它的就是主会话**，直到有人显式 `Read`
- **它也不该被派发**：嵌套 orch 会同时违反它自己两条规则——(1) §"Handoffs
  are records, not conversation" 禁止只传上下文的旁路，而子代理唯一的回传
  形式就是口头摘要；(2) §"Closer ≠ fixer is your call" 要求 orch 自己追踪
  路由，嵌套实例的路由对持有台账的主会话不可见。且它写不了
  `status.jsonl`/`log.md`。**唯一站得住的用法是反过来**：当独立的组卡
  审查员（审隔离与共模防火墙），那是审计不是编排
- **放大风险已识别**：0.8.0 同时废弃 `.claude/skills/`（orch 手册原本住那儿、
  主会话会读）**又**把规则搬进 agent 卡（主会话读不到）⇒ 对严格照上游默认
  走的采纳者，orch 的隔离硬规则**没有任何人读得到**。本仓库侥幸没事，只因
  0.3.6 选择保留四个 skill 作本地资产——那个选择比当时看起来重要得多
- **并入 `/dispatch` 的三块是它原本没有的**：① **closer ≠ fixer 的路由判断**
  （skill 此前完全没提这四个字）② **rev 卡只给范围不给结论**（"a card that
  hands rev a conclusion instead of a scope list is malformed"）③ 新增
  **§3b「旁路即漂移」**——两角色需要同一背景时指向同一份归档记录而非互相
  转述；一方挖出的上下文另一方要重挖是**留存失败**而非效率损失，修法是把
  发现写到下一张卡找得到的地方，**永不为此放宽防火墙**
- **分层理由记明**：`CLAUDE.md` 是常驻但**字节受限**层，skill 是用时载入、
  不受预算约束层，而 `/dispatch` 恰在每次派卡前被调用 ⇒ **消费时机比
  CLAUDE.md 更准**。故 §0 留简版 + 指针，操作细则全在 skill
- **`doc/fw-feedback.md` 性质变更，但文件名与 `FB-` 编号一律不动**。用户提
  "甚至可以删掉"，实测否决：`FB-xx` 被引用 **165 次 / 20 个文件**，文件名
  被引 **29 次**，其中 **10 处在冻结记录里**（`signoff-M0`/`signoff-M2`、
  `REV-004`/`REV-010`、三份 bug 详情页、三份归档）——按 FB-23 裁决那些不得
  回改。⇒ 删或改名会一次性制造死引用，且**我们自己规定了不许去修**。
  改的是这个文件**是什么**，不是它在哪
- **新旧性质写进抬头**：旧（FB-1~27）= 向上游提交的反馈台账；新（FB-28 起）
  = **实践记录**，每行回答"我们改了什么、为什么、上游要不要抄"。新 status
  词表 `local` / `noted` / `upstreamed` 取代 `open`/`reported`/`fixed@ver`
- **唯一的硬要求反而更重了**：既然已无 manifest 记录我们动过哪些上游文件，
  **本台账就是那份记录本身**。任何对 `workflow/`/`scripts/`/`.claude/` 的
  本地改动必须留行 + 代码旁注明 `见 doc/fw-feedback.md FB-xx`，漏了就退化成
  FB-7/BUG-0007 那个形状，**而这次连 `fw-check` 都不会再提醒**。该要求同时
  写进 `CLAUDE.md` §5

**Not done**
- **本 chunk 不含任何仿真**，无新证据，testplan 计数不变（M3 仍 ✅0/11）
- **字节预算逼近上限：39369 / 39500，仅剩 131 字节**。下次往 `CLAUDE.md`
  加任何东西必须先删等量内容。结构性成因已看清但**暂不登记**（痛点未真正
  发生）：该预算覆盖 `CLAUDE.md` + `workflow/*.md`，而 `workflow/` 的
  29922 字节是上游文风、我们不控制 ⇒ 上游一长，采纳者记录项目事实的空间
  就被挤压，而"抬高上限"按纪律属于为过卡放宽门。真撞上再登记
- **L0–L3 分级仍是零实走**（连续第四个 chunk），失配数据产量仍为 0
- FB-23/24/25/26/27 五条仍 `open`；按新裁决它们不再是"等上游修"，而是
  "我们可以自己动手" —— 尚未逐条重新分类
- `/dispatch` 的新增内容（closer≠fixer 路由、rev 范围卡、§3b）**未经真实
  派卡检验**

**Next**
- 派 rev 仲裁卡（L3），一卡四事：① BUG-0032 终判 ② §4/§5.3 自引用提案
  **建议否决**（须带 FB-24 根因入卡）③ 复核 orch 三处越界判断（0.3.4 动
  design-prompt 三行、0.3.6 动两张角色卡、本次删 orch.md 并改写 skill）
  ④ 该卡本身即 `/dispatch` 新内容的首次实检
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）。**其中至少一张须兑现 M3 的 KILL 行**
- 把 FB-23~27 按新性质重新分类：哪些我们直接动手（转 `local`）、哪些只是
  记录（转 `noted`）

**How verified**
- `make check` 绿；`make selftest` **60/60 OK**（删除 orch.md 未触发任何
  测试——已先 `grep` 确认 `scripts/*.py` 与 `scripts/tests/*.py` 对
  `orch.md`/`agents/` **零引用**，删除是机械无风险的）
- `.claude/agents/` 现为 arch/de/dv/rev 四份，`ls` 实测
- 删除决策的证据非目测：`grep -ro "FB-[0-9]*"` 得 165 处 id 引用、
  `grep -ro "fw-feedback"` 得 29 处文件名引用，再对
  `doc/{evidence,review,bugs,archive}` 单独求交得出 10 处落在冻结记录
- orch.md 正文不可达的判断源自**本会话的直接观测**：该文件出现时系统提示
  只给了一行 `description`，正文直到显式 `Read` 才可见——非查文档推断
- 字节预算 `wc -c CLAUDE.md workflow/*.md` = 39369 / 39500，实测

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

