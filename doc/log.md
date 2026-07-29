# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

## [0.3.9] 2026-07-29 应用 P-REV012-1：spec §4 新增 clause 7 + §6 交叉引用，BUG-0032 落地闭环

**Done**
- **派 arch 卡（L2）起草 P-REV012-1 的 spec 变更提案**：按 REV-012 §Item 1 批准
  的四段模板（照搬 §8.2-8.4/§6 clause 2），起草 §4 新 clause 7（ATOP × 译码
  未命中应答形态许可来源未定义 + env 构造性约束）+ §6 clause 3 交叉引用，
  original/new text、rationale、对 testplan/design-prompt 的 impact 齐全，
  未越 REV-012 已批处置半步
- **派 rev 卡（新实例，L2，spec review 任务型）对该提案文本做 pin 前门禁**：
  产出 `doc/review/REV-013.md`，**CONDITIONAL PASS**——内容/四段结构/上游
  静默（rev 自跑 grep 复验，非采信 arch 复述）/编号惯例四项核查通过，**唯一
  必改**：提案原文两处 `M3/M4` 收窄为 `M3`。理由：REV-012 处置确认句与
  BUG-0032 fix 段均锚 M3；BUG-0032 更明写 M4 覆盖率收敛是最可能触发该组合、
  须重开仲裁的场景；"照搬 §8.4 模板"是形态指令非范围授权，写 M4 会让 spec
  断言一个当前无 M4 config-matrix testplan 行承载的约束（Retention 不一致）。
  reopening 路径由 part④ + guard 承接，收窄不损失
- **orch 按 REV-013 订正后的逐字文本应用**：`doc/spec.md` §4 追加 clause 7、
  §6 clause 3 追加交叉引用（均为外科手术式追加，§4.1-6/§6.1-2/4-5 正文未改
  一字）；change record 新增 #7（引 REV-012+REV-013 为依据）；
  `python3 scripts/docs.py --pin-spec` 重 pin，新 sha256
  `9347b4ac71f824a05581468502109d78160781fd1712710d0d783a2f03b3b806`
- `doc/bugs.md` BUG-0032 行与 `doc/bugs/BUG-0032.md` `## arbitration` 段回填
  REV-013 门禁记录 + 应用记录（spec 锚点、change record 序号、新 sha256）——
  BUG-0032 的约束持久归宿自此是 spec 正文本身，不再只活在 testplan/
  design-prompt/guard 三处
- **卡分级 vs 实际**：arch 卡定级 L2、rev 门禁卡定级 L2，两者实际交付均与
  定级相符，无失配。本次采用"三步子闭环"（arch 起草→rev 门禁→orch 应用）
  而非单卡直接应用，符合高后果动作（spec pin 变更）应有独立把关的谨慎度

**Not done**
- `doc/testplan.md` M3-DE01 行与 `doc/design-prompt/uvm_env.md` §6 C6.2**未
  补充引用新 spec 锚点** SPEC-4.7——arch 交付已指出这是可选的 impact 项（约束
  内容不变，只是引用权威从"review 记录"升级为"spec 正文"），非本次必需，留
  作后续小改
- 本 chunk 不含任何仿真，testplan 计数不变（M3 仍 ✅0/11）
- FB-24 仍 `open`；五张 M3 执行卡仍全部待派
- **REV-012/REV-013 的门禁副作用**：chain-audit 的 parent-anchored 由 15 降至
  8（clause 7 正文内联提及 §4.2/§4.3/§6.3，§6 clause 3 交叉引用内联提及 §6.3）
  ——这是 FB-24 已诊断的解析器口径本身的自然结果（内联提及即计入"被引用"），
  不是本卡刻意追求的指标，未做任何"为降数字而写"的编辑（REV-012 §Item 2 明确
  否决了那类动机）；如实记录以免误读为本卡目标

**Next**
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）
- FB-23~27 按 0.3.7 新性质重新分类（local/noted/upstreamed）——仍是欠框架的
  观察项

**How verified**
- `make check` 绿（docs-check passed；chain-audit dangling 仍 0，本 chunk
  无新增悬空引用）
- `python3 scripts/docs.py --pin-spec` 的 anti-sneak-edit 检查实测生效：先加
  change-record 行后才允许重 pin（脚本对比 change-record 行数 vs git HEAD，
  行数未增会直接 `sys.exit`）
- `grep -n "REV-013\|clause 7" doc/spec.md` 确认新 clause 7 与 §6 交叉引用均
  已落盘；`grep -n "9347b4ac" doc/spec.sha256` 确认新 sha 已写入 pin 文件
- `doc/bugs.md`/`doc/bugs/BUG-0032.md` 均已回填应用记录，`grep -n "已应用"
  doc/bugs/BUG-0032.md` 实读确认
- 三步子闭环的隔离自检：arch 卡与 rev 门禁卡为独立新实例（非同一 session），
  rev 门禁卡自行复验上游 grep 而非采信 arch 复述的静默断言

## [0.3.8] 2026-07-29 派 rev 仲裁卡 REV-012：BUG-0032→SPEC_CHANGED、否决 §4/§5.3 自引用提案、3 处 orch 自标越界均未越界

**Done**
- **派发首张按 0.8.0 新版 `/dispatch` + 静态角色卡实测的 rev 仲裁卡（L3）**，
  一卡三事，`doc/review/REV-012.md` 落盘：
  - **① BUG-0032 终判**：rev 亲跑 grep 复验五份许可来源（xbar.md/demux.md/
    mux.md/axi_pkg.sv/xbar.sv 头注释）确认 err_slv 对要求读响应的 ATOP 应答
    形态确系空白、非蒸馏遗漏；SPEC_ISSUE 分类与 env 构造性约束处置（同
    BUG-0002/0003 先例）均确认成立。但**升级为 `SPEC_CHANGED`**（非
    `ACCEPTED@M4`）——约束目前只活在 testplan/design-prompt/guard，spec §4
    正文只字未提该缺口，与两条被引先例（约束均已写入 spec 正文）不同形。
    **approve P-REV012-1**：补 §4 平行条款（四段模板同 §8.4）+ §6 clause 3
    交叉引用；rev 明确"exact wording 由 orch/arch 拟，rev 不代写"——按
    `CLAUDE.md` §0 与 `.claude/agents/arch.md`（"Proposals are arbitrated by
    rev, then applied... by orch — you never edit the spec body yourself"），
    实际起草者只能是 arch，orch 仅机械应用+重 pin。故 P-REV012-1 的文本草拟
    是**下一张卡**（arch），本 chunk 不产出 spec 正文
  - **② §4/§5.3 自引用提案：REJECTED**。rev 独立复核 FB-24 举证（spec 只有
    两级标题、§4.2/§5.3.1 全程是 inline clause reference 而非标题）与
    parent-anchored=15 的构成（现场重跑 chain-audit，15 条中确认多条正是
    `SPEC-4.2/4.3/4.4→§4`、`SPEC-6.3→§6`、`SPEC-5.3.1/5.3.3→§5.3` 这类幻影
    模式）——裁定这是内容迁就工具口径、零验证收益，持久归宿仍是 FB-24（上游
    修解析器）
  - **③ 复核 3 处 orch 自标越界**（0.3.4 design-prompt 3 行 token 迁移 /
    0.3.6 `.claude/agents/*` 底盘移植+新增 orch.md / 0.3.7 删 orch.md 并入
    `/dispatch`）：**三处均未越 dispatcher-only 实质边界**——§0 的禁令精确
    列举四类技术制品（RTL/TB/design-prompt 内容/spec 内容），三处编辑全部是
    机械可证、零语义的底盘/路径维护，本属 orch 职责。B、C 予以底盘豁免存档；
    A 予以豁免，**并现场查出一条新 corrective**：0.8.0 重排已把
    `workflow/fail/` 整个折进 `workflow/bugs.md`，A 当时改的三处
    design-prompt 引用已再次变成死指针
  - **rev 强制字段**：taxonomy-class anomaly = 否（BUG-0032 已是行；design-
    prompt 死指针与 FB-24 均属框架/文档摩擦，非五分类项目失效）
- **orch 落实 REV-012 查出的 corrective**：`doc/design-prompt/
  {functional_coverage,sva_bind,uvm_env}.md` 三处 `workflow/fail/
  coverage_hole.md` 死指针迁移至 0.8.0 现址 `workflow/bugs.md`「Dispatch:
  coverage hole」节——纯 token 替换，referent 存在，word-diff 自证零语义，
  与 rev 裁定的"orch 可对活文档做机械可证、零语义迁移"的豁免线相符，无需
  另派卡
- **卡分级 vs 实际**：本卡定级 L3，实际交付（spec 仲裁 + 3 处流程自审）与
  定级相符，无失配

**Not done**
- **P-REV012-1 尚未应用**——spec §4 平行条款 + §6 交叉引用的具体文本待 arch
  起草（rev 明确拒绝代写正文），本 chunk 只留下已批准的方向与模板；BUG-0032
  行状态已改 `SPEC_CHANGED` 但 spec.md 正文与 sha256 pin 均未动，约束的活
  载体暂仍是 testplan M3-DE01 + uvm_env C6.2 + guard
- 本 chunk 不含任何仿真，testplan 计数不变（M3 仍 ✅0/11）
- FB-24 仍 `open`（upstream 解析器修复，未回流）；FB-23/25/26/27 状态未动
- 五张 M3 执行卡仍全部待派

**Next**
- 派 arch 卡（L2，草拟 spec 变更提案）：按 REV-012 approve 的模板（同 §4.2
  BUG-0003 四段式、§8.4 BUG-0002 四段式）为 §4 起草平行条款 + 为 §6 clause 3
  加交叉引用，原文/新文/rationale/impact 齐全，引用 REV-012 §Item 1 为基准；
  orch 应用该提案时机械核对措辞落在批准模板内，写 change record + 重 pin
- 五张 M3 执行卡（严格顺序，④ 先于 ⑤）：① BUG-0025+0031 同卡修 +
  M3-DE01/DE02/OR04/CFG02（L2）② BUG-0024 (b) + M3-OR05（L2）③ BUG-0018 修 +
  重跑 M2-OR01/WO01（L2）④ 多配置基建 + M3-CF01（L2）⑤ M3-CF02/03/04 +
  M3-AT02（L1）
- FB-23~27 按 0.3.7 的新性质裁决重新分类（local/noted/upstreamed）——本
  chunk 未做，仍是欠框架的观察项

**How verified**
- `make check` 绿（docs-check passed；chain-audit 与升级前一致：dangling
  仍 0、parent-anchored 仍 15——REV-012 否决 §4/§5.3 提案后本就不该变、rev
  在裁决中现场重跑验证过这一点）
- `doc/bugs.md` BUG-0032 行与 `doc/bugs/BUG-0032.md` `## arbitration` 段均
  已写入 REV-012 引用与终判，`grep -n "BUG-0032" doc/bugs.md` 实读确认
  ruling 列含 "REV-012 §Item 1 终判"字样
- 三处 design-prompt 死指针迁移后 `grep -rn "workflow/fail/coverage_hole"
  doc/design-prompt/` 零命中，`grep -n "Dispatch: coverage hole"
  workflow/bugs.md` 确认目标锚点存在
- 派卡自检：card 只含 scope list（文件路径/行号/commit sha）与判据源，未
  夹带任何一方结论——rev 交付里三项 verdict 均为其独立复验产物（如 Item 1
  的五源 grep、Item 2 的 chain-audit 现场重跑），非对 orch 卡面结论的背书

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

