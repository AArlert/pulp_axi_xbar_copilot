# Work log archive
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

## [0.3.3] 2026-07-29 arch 卡：M3 场景清单落地 + 推翻 orch 的 constrained-random 决定

**Done**
- **arch 设计输入卡交付**：`doc/testplan.md` 新增 11 条 M3 场景
  （DE01/DE02/OR04/CFG02/OR05/AT02/CF01~04/TL01——TL01 系既有行，核对满足
  BUG-0010 guard 三要素，未改动）；`doc/feature-matrix.md` 新增
  F-M3-02~F-M3-10；`doc/design-prompt/` 五份文件（tb_top/uvm_env/
  scoreboard_refmodel/sva_bind/functional_coverage）各补 M3 增量段
- **arch 反驳了 orch 关于"M3 引入配置维 constrained-random"的决定，
  orch 采纳**。反驳给出三条可机械核验的事实（均已复核为真）：(1) 配置维
  全部是 elaboration 期 `localparam`（`tb/xbar_types_pkg.sv:19-83`），SV
  `randomize()` 是运行期求解器，语义上落不了地；(2) `+ntb_random_seed`
  只进 `run:` 不进 `compile:`（`sim/Makefile:64` vs `:32-35`），要让种子
  决定配置须让 elaboration 消费 SEED，即每种子一次全量重编；(3) 更要命的
  是 `run: compile` 只产一个固定名 `simv`——配置随种子变而产物名不变时，
  VCS 增量编译一旦复用旧 `simv`，"配置 X 通过"与"基线又跑一遍"在日志上
  **完全同形**，与 BUG-0022（lint 假绿）/BUG-0028（分母缩水）同一沉默通过
  家族，且比二者更隐蔽——判决路径的随机缺陷至少会以失配现形，配置随机的
  缺陷表现为"跑的根本不是你以为的那个设计"。**替代方案**：配置维不做随机，
  做**声明式覆盖子集**（4 个配置点 + 基线，spec §0 行 3 每维度每取值至少
  出现一次，72 点全叉 → 5 点），组合爆炸同样被治住而每点由 `TEST` 名唯一
  确定、可复现、可归因。事务序列保持定向未受影响
- 四条 `ACCEPTED@M3` 债务逐条给出场景归属：BUG-0025+BUG-0031 同卡登记
  （M3-DE02 第 1 层 + M3-OR04 第 2/3 层 + M3-CFG02，满足 REV-011 §4 G4 的
  同卡修要求）；BUG-0024 → M3-OR05；**BUG-0018 判定不需要新场景**——新建
  test 会与"逐 test 看、不看 merged"的判据相冲突，到期验收就是逐 test 重跑
  既有 M2-OR01/WO01
- BUG-0012 guard 点名"随条款落地补齐"的定向场景（条款 0.2.0 起已落地但一直
  无人认领）补注册为 M3-AT02
- **新登 BUG-0032**（SPEC_ISSUE，OPEN）：err_slv 对 ATOP 的应答形态许可来源
  未定义——§4.3 按读/写二分只给"写事务返回单拍 B"，§6.3 要求原子读 B/R
  双通道返回，err_slv 该产几拍 R、什么数据、什么响应码，无条款可推；
  arch 亲跑 grep 确认上游文档 §Decode Errors 全段无 ATOP 命中。处置沿用
  BUG-0002/0003 先例：env 构造性约束使其不可触发 + 列上游确认项，不阻塞
  M3——但**状态未终判**，见 Not done
- 一条可选 spec 编辑提案（非强制）：§4/§5.3 正文从不自引用其编号子条款，
  致 `chain-audit` 的 parent-anchored 由 5 增至 15；arch 建议保留精确引用、
  不退化为父级引用，未落地，交 rev 判断是否值得动 pin

**Not done**
- **BUG-0032 未终判**——orch 不得自填状态（同 BUG-0031 先例，ACCEPTED 的
  rationale 须 rev 签名），需派 rev 仲裁卡确认 SPEC_ISSUE 处置 + 是否需要
  spec 补条款
- M3 尚未派发任何 DV/DE 执行卡，五份 design-prompt 增量与 11 条场景描述均
  停留在设计输入阶段
- `make signoff-check` 现状：条件 1 open 11 行、条件 3 active 多 BUG-0032、
  accepted debt due 4 条——均是 M3 正常态，非本 chunk 遗留问题

**Next**
- 派 rev 仲裁卡：BUG-0032 状态终判（沿用 BUG-0002/0003 先例是否成立）+
  是否需要 spec 补条款；顺带评估那条可选的 §4/§5.3 自引用编辑提案是否值得动
- 按 arch 建议的五块切分派发 M3 执行卡（**严格顺序**，④ 必须先于 ⑤）：
  ① BUG-0025+0031 同卡修 + M3-DE01/DE02/OR04/CFG02
  ② BUG-0024 (b) 路线 + M3-OR05
  ③ BUG-0018 修 + 重跑 M2-OR01/WO01 对口场景
  ④ 多配置基建（tb_top C5.1-C5.7 声明式配置点）+ M3-CF01——验收锚点须含
     "既有 11 条证据仍逐字节可复现"
  ⑤ M3-CF02/03/04 + M3-AT02（依赖 ④ 的配置基建）
- M3 签核卡需重做"判决活性矩阵"（M2 签核人交办，非任一 DV 卡交付物）；
  §5.2.6 2.b 非判决 cover 落 `cg_miss_order.same_bucket_diff_full_id_with_err_slv`
  （M3-OR04）
- BUG-0025/BUG-0031 详情页 `ref: 待定` 未填——待其修复卡落地时一次性填入
  具体 cover/assert 名，M3 签核时不得仍是"待定"

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.6.1，26 files pinned）
- `make chain-audit`：dangling **仍为 0**（hard-fail 未被本卡触发）；
  uncited 由 19 降至 9（§4.1/§4.5/§5.2.6/§5.3/§5.5.3/§6.5/§7.2/§8.3 均已
  被新场景覆盖）；parent-anchored 由 5 增至 15（软缺口，见"可选提案"段）
- orch 独立复核 arch 反驳的三条事实：`grep localparam tb/xbar_types_pkg.sv`
  确认配置维全为 elaboration 期常量；`grep ntb_random_seed sim/Makefile`
  确认仅在 `run:` recipe；`grep -n "^run:\|^compile:\|simv" sim/Makefile`
  确认固定产物名 `$(OUT)/simv`——三条独立验证，非采信 arch 转述
- M3-TL01 未改动，核对 BUG-0010 guard 三要素（跨 ID 桶压满 / 单端口合计远超
  扁平上限 / 扁平表现触发 DUT_BUG 复核路径）逐条已具备

## [0.3.2] 2026-07-28 拉框架 0.6.1：FB-21/FB-22 当日闭环，M3 开工前底座就位

**Done**
- **`make fw-pull` → 框架 0.6.1**（commit `87e2eef`），`fw-check`（26 files
  pinned）/ `docs-check` 双绿
- **FB-21 → `fixed@0.6.1`**：按本仓库处方「被看见而非必须绿」落地 ②+①——
  `docs.py --signoff` 现**内嵌打印 chain-audit 全文**，`rubric.md` 新增 **#8
  「Chain audit answered」**（签核记录须粘贴一次运行、逐 gap 类给出处置或书面
  接受；**悬空引用只许修、不许接受**）。刻意不做硬门禁，本仓库「0/23 采纳率下
  硬红 = 豁免压力」的论证原文入框架 CHANGELOG。框架侧原样收下了「无消费者家族
  第三撞、且发生在采纳该教训当天」这一指控，并据此加 fuse 钉住 rubric #8 与
  `--signoff` 输出的永久一致
- **FB-22 → `fixed@0.6.1`**：三条建议全部采纳——数值序 + **全量打印** + fuse
  钉住 §2.1 排在 §10.1 之前。框架侧把本条记为「审计工具的静默截断优先隐藏它
  本该发现的东西」
- 附带观察（列数校验只覆盖 `doc/bugs.md`）**框架侧暂拒**，理由本仓库认同：
  校验跟着门禁走，而 fw-feedback 表上没有门禁判据落着；哪天有机制开始机械读
  它，自动成为 deferred 候选

**Not done**
- M3 场景清单未设计；四条 `ACCEPTED@M3` 债务未修；M3-TL01 未落地
- chain-audit 的 gap 一条未处置——**它们是 M3 的输入，不是欠账**

**Next**
- 派 **arch 设计输入卡：M3 场景清单**（错误路径 / decode error / 多配置回归）
- 开工前待拍板：M3 是否引入真正的 constrained-random（配置矩阵铺开后定向激励
  组合数爆炸；「激励到不了硬情形导致旧绿灯空过」是本仓库已栽四次的地方）

**How verified**
- **两条修复均实测验收，非采信**：
  - FB-21 —— `make signoff-check` 输出中人工抽查第 8 条存在，**其后紧接
    `== chain audit ==` 全文六行**，即工具与 rubric 同时改了（这正是 FB-18
    当初的病：只改文档没改工具）
  - FB-22 —— 同一条 `make chain-audit`，**计数 19、列出 19**，尾部
    §7.4.3/§7.4.4/§8.3/§8.4 已出现，排序为数值序
- `make fw-check` 绿（0.6.1，26 files pinned）；`make docs-check` 绿

## [0.3.1] 2026-07-28 拉框架 0.6.0（chain-audit 毕业）+ 登记 FB-21/FB-22

**Done**
- **`make fw-pull` → 框架 0.6.0**，`fw-check`（26 files pinned）/ `docs-check`
  双绿。0.6.0 的主体是 **`make chain-audit` 从 deferred 毕业**——spec ↔ testplan
  ↔ feature-matrix ↔ evidence 的断链审计，**其触发器就是本仓库的 signoff-M2**
  （框架 CHANGELOG 记为"生态首次覆盖驱动签核"）。同时 0.5.4 的 FB-19 例外条款
  原样落地在 `.claude/skills/dispatch/SKILL.md`，验收无异议
- **chain-audit 首次运行**（本仓库 M2 文档）：`0 dangling / 1 sourceless(M0-01)
  / 0 orphans / 5 parent-anchored / 19 uncited / 11-of-11 evidence 缺
  spec_ref header`。工具本身有价值——**§5.2.6**（REV-011 当天新增的条款）被
  正确标为"尚无场景引用"，正是该审计存在的意义（M3 缺口）
- **登记 FB-21**（annoyance）：**chain-audit 没有任何门禁或判据来源消费它**。
  实测 grep `chain.audit` / `chain_audit` 于 `rubric.md`、`workflow/*.md`、
  所有 skill = **空集**；`signoff-check` 机器条件 1-3 与人工抽查 4-7 均未提及；
  `docs-check` 不调用；`make next` 不提示。而 0.6.0 CHANGELOG 自己写明它的
  触发器是"the first coverage-driven milestone signoff"——**为签核而生的工具，
  签核却不调用它**。与 FB-11 判例 (a) 逐字同构（`make lint` 从 M0 起就是坏的，
  正因为它不在任何门禁清单里）。本仓库第三次撞同一家族。建议**明确不做成硬
  门禁**（`spec_ref` 采纳率 0/23，硬失败会立刻制造豁免压力），诉求是"签核时
  必须**被看见**"而非"必须绿"
- **登记 FB-22**（annoyance）：**uncited 行静默截断，且截断方向系统性偏向编号
  最大的章节**。`docs.py:1023-1025` 是 `uncited[:15]`，无省略号/无 "+N more"；
  本仓库实测**计数 19、列出 15、静默丢 4**，而同一报告另外四行全量打印 ⇒
  报告内部自相矛盾。排序用 `sorted()` **字符串序** ⇒ 砍掉的恒是编号最大的
  一批：本仓库丢的是 **§7.4.3 / §7.4.4 / §8.3 / §8.4**，即延迟不敏感原则与
  Connectivity 稀疏矩阵，**正好是 M3 的主题地盘**；且 §7.4.4 与 §8.4 恰是
  spec §5.2.6 第 2.b 条引作"上游确认项、不阻塞里程碑"先例的两节。
  ⇒ **一个为发现里程碑缺口而生的审计工具，其静默截断优先隐藏下一个里程碑的
  缺口。**违反框架 0.4.3 为 FB-13/14 立的"可见截断"约定，属本仓库 BUG-0028
  "分母静默缩水"同族
- FB-21/22 + 一条附带观察（**`docs-check` 的表格列数校验只覆盖 `doc/bugs.md`**
  ——写 FB-21 时误打一个字面量 `|` 使该行变 7 列，门禁照样通过）当日送达
  iverif-workflow 侧

**Not done**
- 三条反馈均未闭环（不阻塞本仓库任何工作）
- chain-audit 报出的 gap 一条未处置：1 sourceless（M0-01，上游 tb sanity，
  本就无 spec 条款可引）、5 parent-anchored、19 uncited、11/11 缺 spec_ref
  header。**这些是 M3 的输入，不是本 chunk 的欠账**——尤其 §5.2.6 无场景引用，
  正是 M3 错误路径场景要填的
- M3 场景清单未设计；四条 `ACCEPTED@M3` 债务未修

**Next**
- 派 **arch 设计输入卡：M3 场景清单**（错误路径 / decode error / 多配置回归）。
  输入已齐：spec §5.2.6 三层判据、chain-audit 的 uncited 清单（**含被截断的
  §7.4.3/§7.4.4/§8.3/§8.4——手工补回，不能只看工具输出**）、四条 ACCEPTED@M3
  的到期验收形态、REV-011 §4 G4（BUG-0025+0031 同卡修、守卫场景与 M3
  decode-error 场景同卡注册）
- M3 大概率需要引入真正的 constrained-random：配置矩阵（spec §0 #3）铺开后
  纯定向激励组合数会爆炸，而"激励到不了硬情形导致旧绿灯空过"正是本仓库已栽
  过四次的地方（BUG-0018/0023/0024/0031）。附带效果：`CONSTRAINT_BUG` 这一
  taxonomy 类目前是**结构上不可能**（全仓无一个 `constraint` 块、无一处
  `randomize()` 调用，`axi_txn.sv:15-20` 的 `rand` 限定符是死装饰）

**How verified**
- `make fw-check` 绿（0.6.0，26 files pinned）；`make docs-check` 绿
- FB-21 的"空集"是**实测**而非印象：grep 两式于三处判据来源载体，无命中；
  并逐行读 `make signoff-check` 全部输出（机器 1-3 + 人工 4-7）确认未提及
- FB-22 的 4 条丢失项是**独立复算**得到的，不是从工具输出反推：用与
  `docs.py` 同构的正则重算 `uncited`，得 19 条、前 15 条与工具输出逐字相同、
  尾 4 条为 §7.4.3/§7.4.4/§8.3/§8.4
- 0.6.0 的 pull 范围逐 diff 核对：`docs.py`(+74) / `evidence.mk`(+7，新增
  `chain-audit` target) / `dispatch/SKILL.md`（FB-19 例外条款）/ manifest /
  iverif.json + 4 个重新渲染的 agent 文件，无外溢

## [0.3.0] 2026-07-28 M2 里程碑签核 PASS，收官转入 M3

**Done**
- **M2 签核 PASS**（`doc/evidence/v0.2.5/signoff-M2.md`，rev 新实例——REV-011
  作者不得签自己裁的债）。`make signoff-check` 四项全绿：机器条件 1/2/3 +
  `[yes] signoff file`
- 签核人**没有接受"树未动故条件 2 无需重跑"这条转述**（那是我在卡里给的环境
  事实）：独立重跑 `make regress` 得 11/11，重写 `sim/result_summary.txt` 后
  `git status` 不变脏 ⇒ 与登记证据逐字节相同。并核对分母——`regress.list`
  11 行 ↔ testplan ✅ 11 行、差集为空（BUG-0028 guard 指派给签核人的动作已履行）
- **rubric #5 的证伪是真做的**：废弃分支 `rev011-falsify-scratch` 上把 BUG-0027
  的原缺陷放回 `tb/scoreboard_refmodel.sv`（删掉完成认领 `foreach` 里的
  `break;`），`m2_or03_guard_test SEED=1` ⇒ **`UVM_ERROR: 336` /
  `stall(C5.1/C5.2): violations=336`**，与详情页基线精确相符；复原后归零、
  `SB_SUMMARY` 与登记证据逐字段相同，分支已销毁、工作树干净。选它是因为它守的
  是**七行 M2 场景共用的判决锚点**
- **rubric #7（0.5.3 新条）首次实战，四条 `ACCEPTED@M3` 全数通过**——签核人是
  **带着推翻意图**去查的，12 项承重事实无一得手：BUG-0024 的假红构造三个结构
  前提逐条验证（`stall_sva.sv:131` 无条件覆写 / `:273-283` 合取式里确实没有
  `w_id_open[completing_id]` 项 / `:120-127` 复位只清 `*_id_open`）；BUG-0031
  的三条 grep 事实推翻不了；BUG-0025 的否定性证据复核（`grep -in
  "err_slv|error slave|decode error" axi_demux.md axi_mux.md` = **空集**，
  xbar.md L33/L35/L86 三处引文逐字属实，spec 应用文本与提案逐字相同、无 RTL
  来源）；BUG-0018 的 M4→M3 提前推理成立（`doc/spec.md:25` 六类确不含
  covergroup）。无顺延条目（`ACCEPTED@M<n>` 今日首用），已按 rubric 明确确认
- **一处超出既有记载的发现**：BUG-0018 的盲区差点动摇 **M2-WO01**——其非空转
  判据要求"≥2 不同源 AW 未决"被激励到，而 covergroup 侧 `cp_w_contention` 恰被
  该盲区打空（50%，只填 `single_source`）。实测证明判据由 assert 维度独立承担：
  `axi_xbar_worder_sva.sv:107` 在 master 端口 0 上 `207 attempts, 46 match`
  （同场景 [1..7] 全 0），与 WO01"多源汇聚同一 master 端口"的构造精确吻合
  ⇒ 豁免成立，✅ 不动摇
- REV-011 两条交接条件均已执行，且签核人把 §5.4 那条**推广**成了一张 8 行的
  **判决活性矩阵**——此前记载里只有 CFG01 与 TL02 两个孤点
- **登记 FB-20**（annoyance，由签核人报出）：**终态行携带的未兑现义务对
  `signoff-check` 条件 3 完全不可见——终态即免检**。实例 BUG-0030（WONTFIX，
  却挂着"`LD_LIBRARY_PATH` 必须*恰为*"是否属过度归纳的未做实验）。与 FB-18(b)
  是同一缺口的两侧
- 版本 0.2.5 → **0.3.0（M3）**，tag `v0.3.0`

**Not done**
- 四条 `ACCEPTED@M3` 债务本身未修（0018/0024/0025/0031）——**到期点就是 M3
  签核**，届时 `docs.py:855` 会拦，且不得续期（顺延须重走仲裁，rubric #7）
- BUG-0030 的"恰为"二值实验未做（需 FSDB，已登记为守卫义务 + FB-20）
- M3-TL01 已注册未落地；M3 场景清单尚未设计
- **框架 0.5.4 尚未 pull**（FB-19 已 fixed@0.5.4）——签核卡跑完前刻意不拉，
  避免在其脚下换掉判据来源；现在可拉

**Next**
- `make fw-pull` → 0.5.4
- 派 arch 设计输入卡：**M3 场景清单**（错误路径 / decode error / 多配置回归）。
  两条前置已备好：spec §5.2.6 已定案（译码未命中事务的保序地位三层判据），
  BUG-0025 + BUG-0031 应**同一张修复卡**且其守卫场景与 M3 decode-error 场景
  在**同一张 arch 注册卡**里登记（REV-011 §4 G4）
- 签核人留的两条 M3 指导：(1) `axi_xbar_stall_sva` 的判决活性矩阵须在 M3 新
  场景落地后**重做**；(2) **§5.2.6 2.b 的非判决 cover 是 M3 的硬性抽查项**
  ——M3 主题即错误路径，它缺席时"显式排除"与"忘了写"在报告上同形

**How verified**
- `make signoff-check` 四项全 `[PASS]`/`[yes]`；`make docs-check` / `make
  fw-check`（0.5.3，26 files pinned）绿
- 签核记录 `doc/evidence/v0.2.5/signoff-M2.md`（46 KB）含机器条件输出原文粘贴、
  抽查 4/5/6/7 各自的引证、残留风险 R1–R7、判决 **PASS**
- 判 PASS 而非 conditional 的理由（签核人原文口径）：查出的每一处残留风险
  **都已有登记载体与到期点**，没有一条属于"新发现且无人认领"或"须在 M2 内补做
  才能让 ✅ 成立"；八行 ✅ 的判决锚点均被验证为**存在、非空转、且可变红**
- Taxonomy-class anomaly：**no**。三处候选追查后判定不构成新行，逐条留痕于
  签核记录 §10（`cg_stall` 的 `SC_NONE` 无 bin 是有意设计；stall_sva 空转的成因
  已分属 BUG-0024/0025/0031；BUG-0030 的待兑现实验已在其详情页 `:103-110`）
- 派卡规则偏离（FB-19 那处）经签核人裁断：**未损害本次签核**——rubric #5 本就
  命令签核人自跑同一命令、跑出的 22 条与索引逐条相符；省下的预算实际用在读
  10 份 raw log 与 6 个源文件上，而那正是全部实测结论的来源

**这一轮最该记住的一件事**：本轮三条框架反馈（FB-18/19/20）指向的是**同一个
形状**——机制把最后一道防线放在执行者的自觉上。FB-18(b) 是 ACCEPTED 的
rationale 无人复核，FB-19 是 orch 自行裁量要不要遵守派卡规则，FB-20 是终态行
的未兑现义务无人看见。三次都靠自觉挡住了，三次都说明**凡是需要靠自觉的地方，
就是规则该补的地方**——这句话已入框架 CHANGELOG。与 0.2.1 那轮"看到绿灯要先问
它覆盖了什么"互为表里：那条问的是**门禁的覆盖面**，这条问的是**门禁之外靠什么
兜底**。

## [0.2.5] 2026-07-28 拉框架 0.5.3：FB-18 当日闭环，M2 签核卡解除暂停

**Done**
- **`make fw-pull` → 框架 0.5.3**，`fw-check`（26 files pinned）/ `docs-check`
  双绿。pull 只动 4 个文件（+4 个重新渲染的 agent 文件），逐 diff 核对无外溢：
  `workflow/signoff/rubric.md`、`scripts/docs.py`、`scripts/iverif.manifest.json`、
  `iverif.json`
- **FB-18 → `fixed@0.5.3`**（框架 commit `12b1548`），两半全采纳：
  - (a) rubric 机器条件 3 同步为 "terminal **or unexpired `ACCEPTED@M<n>`**"
  - (b) 新增人工抽查**第 7 条**（`docs.py --signoff` 同步打印，实测已见）：
    "each `ACCEPTED@M<n>` row: the cited REV record states a *falsifiable*
    rationale …… Carry-overs were re-arbitrated — never auto-extended — and
    say why the previous due date slipped"
  ⇒ 本仓库 REV-011 §4 G3 的项目自立规则**入 canon**，§5.4 作为参考形状记入框架
  CHANGELOG；框架侧另加 fuse 钉住 rubric/工具在条件 3 与第 7 条上的永久一致
- **FB-11 → `fixed@0.5.2`**：gate 自证教义按本仓库送出的**对抗原型证伪结论**
  （stamp 候选形态的两个洞 + "elaboration done" 在 VCS O-2018 根本不存在）
  全文重写进框架 deferred 台账；本仓库 `sim/Makefile`（BUG-0022 的无条件重跑 +
  逐文件执行证明）被记为参考实现。本仓库原待办两项已随 BUG-0022 完成，无欠账
- **BUG-0030 上游订正落页，但**不**关闭**：框架 0.5.2（`iverif-workflow@68a7e83`）
  承认尾冒号是**快照缺陷而非环境约束**，`vcs-2018.mk` 改条件拼接。本仓库实测该
  fragment 单独展开确已无尾冒号。**但框架"`env -i` 绕法可退役"的结论未采信**：
  本页判据写的是"必须**恰为** `$VERDI_HOME/share/PLI/VCS/LINUX64`"，而
  `sim/Makefile` 走完整 include 链后实测仍带 VCS lib 前缀 ⇒ **仍不"恰为"**。
  尾冒号与"恰为"是两件事，上游只修了前者；当初的二分定位是逐项**加**变量做的，
  没测过"带无关前缀但无尾冒号"这一形态 ⇒ 二者未经实测无法区分。维持 WONTFIX，
  并在其 `## regression_guard` 登记一项**待兑现的附带义务**（下一张需要 xdebug
  的卡本来就会产 FSDB，顺手做一次二值实验：成功则绕法退役、本条转 CLOSED 走
  FB-16 的 `CMD=`/`EXPECT=` 形态；失败则"恰为"成立、绕法保留）

**Not done**
- M2 签核未做（本 chunk 只解除其前置阻塞）
- BUG-0030 的二值实验未做（需 FSDB，不为不阻塞门禁的终态条目单独烧一次
  编译+仿真；已登记为守卫义务，不是遗忘）
- 四条 ACCEPTED@M3 债务本身未修；M3-TL01 未落地

**Next**
- **派 M2 签核卡**（rev，新实例——REV-011 作者不得签自己裁的债）。三条交接条件：
  1. rubric #4"再读一个被豁免的洞"**明确挑 BUG-0018**（REV-011 §3.3 指定）
  2. **不得**把 `axi_xbar_stall_sva` 的通过计为 M2-CFG01 的独立证据——84/84
     零命中即其空转的机械证明（REV-011 §5.4）
  3. rubric #7 是**新条**，四行 ACCEPTED@M3 全部落在它的抽查范围内
- 签核 PASS 后 `make bump-minor` → 0.3.0 / M3 + `git tag`

**How verified**
- `make fw-check` 绿（0.5.3，26 files pinned）；`make docs-check` 绿
- 新 rubric 逐条读过：条件 3 措辞已含 "or unexpired `ACCEPTED@M<n>`"，人工抽查
  第 7 条存在且 `make signoff-check` 尾部确实打印它（**不是只改文档没改工具**）
- `make signoff-check` 条件 1/2/3 全 PASS，仅余 `[not yet] signoff file`
- BUG-0030 的上游修法是**实测**而非采信：`make -f -` 求值一个只 include 该
  fragment 的临时 Makefile，父变量为空时结果恰为单一路径；对照 `sim/Makefile`
  完整链的实测值带 VCS lib 前缀——正是这个对照支撑了"不采信绕法退役"的判断
- `make guards FILES="sim/Makefile"` 7 条命中，含 BUG-0030 的新增待兑现义务

## [0.2.4] 2026-07-28 FB-18 回流并阻塞 M2 签核：ACCEPTED 只落到机器侧，rubric 两处未同步

**Done**
- 组 M2 签核卡时核对判据来源，发现 **FB-18（blocking）** 并登记 +
  当日送达 iverif-workflow 侧（session「工作流反馈审查」）。两半：
  - **(a) 字面矛盾**：`workflow/signoff/rubric.md:14` 机器条件 3 仍写
    "All bug rows are in terminal states (`CLOSED / TB_BUG / SPEC_CHANGED /
    WONTFIX`)"，而 `scripts/docs.py:877` 已是 "all bugs terminal **or
    ACCEPTED-unexpired**"。0.5.0 改了 `failure_record.md` / `docs.py` /
    `evidence.mk`，**漏了 `rubric.md`**。本仓库正好有四行 `ACCEPTED@M3`
    ⇒ 认真读判据来源的 rev 会判条件 3 不满足，与它自己跑出的 `[PASS]` 冲突。
    按工具走则判据来源形同虚设（连带贬值 rubric #5"必须真做一次证伪"那类
    **只存在于 rubric、无机器背书**的条目）；按 rubric 走则里程碑签不掉
  - **(b) 更实质**：rubric **没有任何条目**要求签核人复核 ACCEPTED 的
    rationale。机器只验两件形式——行内含 `REV-`（`docs.py:489`）、目标里程碑
    未过期（`docs.py:855`）；那份 rationale 是否真的存在、是否可证伪、上一轮
    到期判据是否兑现，**无人查**。而 rubric #6 对 spec debt 恰有同构条目，
    FB-17 提案时正是引它作先例，落地时没推广到 bug debt 这一侧
- 建议两条：机器条件 3 同步措辞；新增人工抽查第 7 条（与 #6 同构，要求
  rationale 存在 + 给出可证伪判据 + 顺延须说明上次判据为何未兑现）。并把
  `doc/review/REV-011.md` §5.4 作为合格形状的参考实现一并送出

**Not done**
- **M2 签核卡按用户指令暂停派发**，待框架闭环 FB-18 → `fwsync --pull` 后再派。
  理由：拿一份已知会误导的判据来源去派签核卡，与 FB-11 那句"没看见错 ≠
  查过了"是同一族错误。绕法（在卡里写明"以 docs.py:877 为准"）存在但没用——
  那等于让项目侧口头覆盖框架文档，不是项目该有的权限
- 四条 ACCEPTED@M3 债务本身未修（语义即如此）；M3-TL01 未落地

**Next**
- 等 iverif-workflow 侧闭环 FB-18 → `make fw-pull` → `make fw-check` 复绿
- 然后派 M2 签核卡（REV-011 交下的两条硬性交接条件不变：rubric #4 明确挑
  BUG-0018；不得把 `axi_xbar_stall_sva` 的通过计为 M2-CFG01 的独立证据，
  84/84 零命中即其空转的机械证明）

**How verified**
- 漂移是逐行比对确认的，非印象：`rubric.md:14` 与 `docs.py:877` 两处原文并列
- `make docs-check` 绿（FB-18 行 6 列）；`make fw-check` 绿（0.5.2，26 files
  pinned——**框架文件一字未改**，本条只走回流，不本地修补）
- `make signoff-check` 条件 1/2/3 仍全 PASS、仅余 `[not yet] signoff file`
  ——即本次暂停**不是**因为机器条件退化，而是因为人工判据来源不可用
- 自 `594bf94`（0.2.1）以来 `tb/`、`sim/` 一字未动，11/11 回归证据与当前树
  逐字节一致，签核恢复时条件 2 无需重跑

## [0.2.3] 2026-07-28 REV-011 台账落地：四条债务转 ACCEPTED@M3 + 新登 BUG-0031，signoff-check 条件 3 转绿

**Done**
- **REV-011 条件 C-2/C-3/C-4 落地**（C-1 spec 部分见 0.2.2）：
  - **C-2 新登 BUG-0031**（TB_BUG）：`tb/sva/axi_xbar_stall_sva.sv:99-100` 调
    `decode_mst_port(aw_addr, **ADDR_MAP**, …)`，地址表取编译期 localparam，而
    `tb/sva_bind.sv:33-35` 该模块**结构上拿不到** `cfg_if`（隔壁 `:41-47` 的
    `axi_xbar_route_sva` 却接了）。`design-prompt/sva_bind.md` §3 明文要求改传
    运行时活值表——函数签名已改（`xbar_types_pkg.sv:148` 收 `amap` 形参），
    **调用点没改，要求只落实了一半**。M2-CFG01 确实在运行时改表
    （`seq_lib.sv:993-996`，rule 0 的 idx 0→5）⇒ 重配后命中 region0 的事务
    `w_id_tgt` 记 mst0、实际 mst5。**误差双向（可假红）**，与 0023/0024/0025 的
    单向漏检不同类
  - **C-3 三条 `## regression_guard` 改写**：0024 的 (a) 路线旧口径
    （"`w_lost_now` 归零即修复"）**明文作废**——(b) 路线下该数不必归零，两种
    口径不得并存；0025 由"待 spec 结论"改为按 §5.2.6 定形的三段式；0018 补入
    M3 归属理由与逐 test 基线数
  - **C-4 三处订正同步进详情页正文**：0024 `## symptom`（"只漏检不会假红"
    不成立，附四步假红构造）、0025 `## symptom`/`## rca` 第 3 点/`## 对已登记
    证据的影响`（"读到 X 恒假"错、"从未被触发"错）、0018 `## symptom` scope
    补 `cg_tx_limit`
  - 额外订正一处 rev 未点到的矛盾：**BUG-0025 的 `min_repro` 列**原值是
    "无（当前激励集全为译码命中路径，本条不可触发）"，与 REV-011 §5.2 的实测
    直接冲突，已改为 `make run TEST=m2_cfg01_reconfig_test SEED=1`
- **BUG-0031 的状态退回 rev 补裁**（orch 不自填）：`ACCEPTED@M<n>` 的 rationale
  按 schema 须 rev 签名，而 `docs.py:489` 只校验行内含 `REV-`、校验不了那份
  rationale 是否真的存在——orch 自行落 ACCEPTED 恰是 REV-011 §4 G3 警告的
  "ACCEPTED 变成新地毯"。rev 补裁 **`ACCEPTED@M3`**（REV-011 §5.4），并给出
  三条**可被同样 grep 推翻**的依据：(1) 全仓只有 `tb_top.sv:59` 与
  `seq_lib.sv:994` 两处写 `cfg_vif.addr_map` ⇒ 除 CFG01 外所有场景编译期表恒等
  于活值表；(2) 唯一用到陈旧表的 `m2_cfg01_reconfig_test_1.log` 里该模块
  **84 条 cover 行全部 0 match**（对照 or01 同名 cover 非零 ⇒ 非日志假象）⇒
  结构性空转、贡献零判决；(3) testplan M2-CFG01 的判决锚点是 scoreboard +
  独立 SVA C3.1，**不含** C3.2。任一条被证伪则该裁决失效、须改判 M2 内修
- **`make signoff-check` 条件 3 转 PASS**：四条 active bug（0018/0024/0025/0031）
  各自获得一份 rev 签名、各自带证伪条件的排期理由，到期点**均为 M3 签核**
  （`docs.py:855`：n ≤ 被签核里程碑即拦）

**Not done**
- M2 里程碑签核（`doc/evidence/v0.2.*/signoff-M2.md`）未做——`signoff-check`
  仅剩 `[not yet] signoff file` 一项
- 四条 ACCEPTED 债务本身未修（这正是 ACCEPTED 的语义：已分析、已排期、未做）
- M3-TL01 已注册但未落地

**Next**
- 派 **M2 签核卡**（rev，新实例）。REV-011 交下来两条**硬性交接条件**：
  1. rubric 第 4 条"再读一个被豁免的洞"**明确挑 BUG-0018**，不得绕开它另挑
     好看的 bin；
  2. **不得**把 `axi_xbar_stall_sva` 的"通过"计为 M2-CFG01 的独立证据——
     84/84 零命中即其空转的机械证明；该场景证据链是 scoreboard
     （`route: match=30 mismatch=0`）+ `axi_xbar_route_sva`(C3.1)。与 BUG-0024
     的 b-3 同一条纪律：任何"SVA 也过了"必须附上那次运行的空转/范围见证
  rubric 第 5 条用 `make guards FILES=<里程碑触及文件>` 定复核范围，至少证伪一条
- M3 开工时：BUG-0025 + BUG-0031 **同一张修复卡**（同一调用点的两个实参，
  REV-011 §4 G4），其守卫场景与 M3 decode-error 场景应在**同一张 arch 注册卡**
  里登记（构造要素重叠）

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.5.2，26 files pinned）
- `make signoff-check` 条件 1/2/3 全 PASS，仅余 `[not yet] signoff file`
- `make guards FILES="tb/sva/axi_xbar_stall_sva.sv"` **8 条命中**（原 7 条 +
  新登的 BUG-0031）——新 guard 的注入机制生效得证，下一张动该文件的卡会自动
  收到它
- 台账终态核对：0018/0024/0025/0031 四行均 `ACCEPTED@M3`，各行文本含 `REV-011`
  （`docs.py:489` 的两道校验：须含 `REV-`、n ≥ 当前里程碑）

**这一段最该记住的一件事**：登记 BUG-0031 让刚刚转绿的条件 3 **立刻又变红**，
而把它填成 ACCEPTED 只需我改一个单词、机器完全查不出来。门禁在这里挡不住
orch——挡住的是"ACCEPTED 的 rationale 必须由 rev 签名"这条**约定**，以及
rev 交回来的那三条**可被 grep 推翻**的依据。可证伪性是自愿交出来的，不是被
门禁逼出来的；这与 REV-011 §4 G1 的"沉默的通过"是同一枚硬币的两面。

## [0.2.2] 2026-07-28 REV-011 spec 条款落地：译码未命中事务的保序地位（BUG-0025 SPEC_ISSUE 半边裁决）

**Done**
- rev 卡 **REV-011** 交付（`doc/review/REV-011.md`）：对 M2 仅剩的三条 active
  bug（0018/0024/0025）做终态再裁决，并**当场完成** BUG-0025 的 SPEC_ISSUE
  半边仲裁。本 chunk 只落地其中的 spec 部分（C-1），其余四项条件（C-2 新登
  BUG-0031、C-3 改写三条 regression_guard、C-4 详情页正文订正、C-5 另派签核
  卡）留给后续 chunk
- **应用条款提案 P-REV011-1**：`doc/spec.md` §5.2 新增第 6 条「译码未命中
  事务的保序地位」——(1) 走 §3.3 default master port 的事务其目标是**真实
  master 端口**（xbar.md L35），§5.2.1-4 原样适用；(2) 走 §4 decode error
  slave 的事务分两层：**完整 ID 维度可断言**（同一 slave 端口上完整 ID 相同、
  同方向事务的 B/rlast 完成序须与接受序一致，**无论**路由去向；依据 §1 +
  §4.5 + §5.2.3 + xbar.md L86 "same ID and direction must remain ordered"
  ——该义务只依赖 slave 端口是 AXI4 接口、不依赖内部路由），**低位 ID 桶
  维度不可断言**（完整 ID 不同且其一走 err_slv 时，次序关系许可来源未定义：
  xbar.md §Ordering and Stalls 只约束"不同 master 端口"、§Decode Errors 未涉
  次序、demux.md/mux.md 对 err_slv 无记载 ⇒ 不得写断言，以非判决 cover 留痕 +
  列上游确认项 + 不阻塞里程碑，同 §7.4.4/§8.4 处置）；(3) checker 对该排除
  必须**显式引本条**，不得以"未登记⇒读默认值⇒比较恰好为假"实现
- **应用条款提案 P-REV011-2**：`doc/spec.md` §4 新增第 6 条一行交叉指针至
  §5.2.6。§5.2.1-5 与 §4.1-5 正文一字未动（surgical）
- Change record 第 6 行登记 + `docs.py --pin-spec` 重 pin（`doc/spec.sha256`
  `bfe8542b…` → `0fd431f7…`）

**Not done**
- REV-011 的其余四项 orch 条件（C-2/C-3/C-4/C-5）——下一 chunk
- 三条 bug 的 `ACCEPTED@M3` 状态改写虽已由 rev 卡在工作树中完成，但**不在本
  commit**：本 chunk 严格限定为 spec 应用，bug 台账变更随 C-2/C-3/C-4 一并
  提交，以免 spec 变更与台账变更混进同一个不可分割的 commit
- M2 里程碑签核（signoff-M2）未做

**Next**
- C-2 登记 BUG-0031（`stall_sva.sv:99-100` 编译期 `ADDR_MAP` 译码 vs
  `sva_bind.sv:33-35` 未传 `cfg_if`——design-prompt §3 的要求只落实了一半，
  误差**双向可假红**）+ C-3 三条 regression_guard 改写 + C-4 详情页正文订正
- C-5 M2 签核卡（rubric #4 明确挑 BUG-0018 作"再读一个被豁免的洞"，#5 须真做
  一次守卫证伪）

**How verified**
- `make docs-check` 绿；`make fw-check` 绿（框架 0.5.2，26 files pinned）
- 结构核对：新条款落在 `doc/spec.md:201`（§5.2 第 6 条，位于原第 5 条之后、
  `### 5.3` 之前）与 `doc/spec.md:151`（§4 第 6 条），编号连续无跳号；
  Change record 第 6 行列数 = 6，与表头一致（FB-14 那类静默串列的自检）
- pin 一致性：`sha256sum doc/spec.md` 与 `doc/spec.sha256` 相符
- spec-from-RTL 红线：REV-011 §1.3 明确声明未读 `axi_xbar.sv`/`axi_demux.sv`
  实现体，条款的许可来源清单全部为 `vendor/axi/doc/*.md` 与 spec 内部章节；
  `axi_mux.md` 对 err_slv 无记载被作为"未定义"的**否定性证据**引用

## [0.2.1] 2026-07-28 M2 场景收官 + 框架五版回流 + bug 台账 12→4：签核前最后一段

**Done**
- **F-M2-08 功能覆盖采集基建落地**：`tb/functional_coverage.sv` 六个 covergroup，
  采样点全部取自既有 monitor/scoreboard 的判决状态（单一事实源，未新增第三套解码）。
  merged 后 `cg_addr_reconfig`/`cg_w_order` 100%、`cg_stall` 88.9%、`cg_tx_limit` 80%，
  其中 `above_max_11/12` 各命中 12 次——BUG-0016 的越限现象被 covergroup 独立留痕。
  派卡前发现四份 design-prompt 落后于 BUG-0016 重 pin 后的 spec（REV-007 §5 只列了
  spec 正文、漏了设计输入同步），先派 arch 再锚定 + REV-008 增量门禁才放行。
- **M2-OR03 守卫场景落地**（testplan 由 7 条增至 8 条，全 ✅）：为 BUG-0023/0024 定向
  构造「同完整 ID 多笔在飞 + 目标跨 master 端口切换」。BUG-0023 守卫闭环——
  `w/r_collide_kept_now` 由既有 9 场景的 0/0 变 192/264，且去掉同沿保护后双双归 0
  （证伪成立，不是恒真空守卫）。写方向原本打不中的原因值得留档：均匀 `AxLEN=0` 的
  写流与 B 流锁相，同沿永不发生；按 `k%2` 交替 `AxLEN` 扫相位后才命中。
- **`make lint` 门禁从「三层坏」修到可用**：BUG-0014（缺 `-assert svaext`）→ 暴露
  BUG-0019（缺 `-top`）→ 暴露 BUG-0021（285 条既有告警）→ 分诊出 11 条真缺陷
  （F1/F2/F3，全在 `tb/sva/`）→ 修复期又撞出 BUG-0022（增量假绿）。BUG-0022 的修法是
  **无条件重跑 + 逐文件执行证明**（枚举源是 `find ../tb` 而非 flist，故 flist 缩水也挡得住）。
- **BUG-0020 修复**：`make run … FSDB=1` 可选波形路径，默认路径成本逐项对齐未变；
  `xdebug session.open` 首次在本仓库成功（`mode: waveform`）。
- **框架 0.3.0 → 0.4.5 连拉五版**，FB-10~FB-17 八条回流，其中 FB-10（guard 注入）
  当日进入 canon 0.4.1：`regression_guard` 新增 `paths:` glob、`make guards` 纯路径求交、
  dispatch + rubric #5 双消费挂点。本仓库 18 条存量 guard 全部回填 `paths:`，复验
  `make guards FILES="tb/sva/axi_xbar_stall_sva.sv"` 命中含 BUG-0015——**被 F1 违反的
  正是它**，缺口关闭得证。此后每张卡都按该机制注入，DV 反馈「BUG-0013 没有它我很可能会漏」。
- **bug 台账 12 条 active → 4 条**（REV-010 逐条裁决 + 复验）：5 条 CLOSED（rev 在
  一次性 worktree 内亲手证伪，非仅看日志）、3 条 WONTFIX（0017 版本墙 / 0021 附守卫
  改写 / 0030 环境约束）、2 条由 orch 复验后 CLOSED（0020/0022）。新增
  `doc/lint-baseline.md` 作为 BUG-0021 WONTFIX 的守卫载体（285 条按类别×文件×行登记），
  `make lint-diff` 为其执行入口。

**Not done**
- **M2 未签核**：`signoff-check` 条件 3 剩 4 条 active——BUG-0018（covergroup 采样相位，
  rev 判为 **M4** 前置而非 M3）、BUG-0024（`w_id_open` 单 bit，须择 REV-010 §4 G4 的
  (a) 重建队列 / (b) 正式收窄 SVA 判决范围）、BUG-0025（含**必须先仲裁的 SPEC_ISSUE
  半边**：error slave 响应能否越过更老响应，spec 未定义）、BUG-0029（等框架 FB-16）。
- `doc/evidence/v0.2.0/signoff-M2.md` 未出（rubric 人工抽查三项未做）。
- M3-TL01 已注册但未落地（BUG-0010 守卫，其 guard 原文钉在 M3/M4，不挡 M2）。

**Next**
- BUG-0025 的 SPEC_ISSUE 半边派 rev 仲裁——**必须在 M3 场景被设计之前**完成，
  M3 判据形态取决于结论。
- BUG-0024 择 G4 的 (a) 或 (b)；BUG-0018 落终态（M4 前置的书面接受理由）。
- 四条清零后派 rev 签核卡（rubric #5 现要求「里程碑触及文件命中的全部 guard 入围复核 +
  至少证伪一条」，用 `make guards` 定范围）。

**How verified**
- `make regress` **11/11 PASS**（此前只有 3/3——BUG-0028：七个 M2 场景自落地起从未进过
  回归清单，`make regress` 报绿而分母静默缩水，本轮补齐并登记
  `doc/evidence/v0.2.0/result_summary.txt`）。
- 八条 M2 证据全部重跑重登记（框架 0.4.3 起每条含 5 个 SVA 模块的聚合行，
  `axi_xbar_stall_sva.sv: 60 properties/covers, 2640 attempts, 24 match` 首次进入证据——
  正是 BUG-0026 说「从来就不在证据文件里」的那个数字，该条据此 CLOSED）。
- orch 独立复验 BUG-0020/0022（非修复方）：lint 连跑三次 exit 2/假绿签名归零/
  `lint-diff` 225/225；默认 `make run` 不产波形而 `FSDB=1` 产出 345 KB 且 xdebug 可开 session。
- `make docs-check` / `make fw-check`（框架 0.4.5，26 files pinned）全绿。

**这一轮最该记住的一件事**：`make lint` 从 M0 起就是坏的，因为它**不在任何门禁清单里**——
没有机制去验证「验证工具本身是否有效」。同一形状在本轮出现了五次（lint 假绿 / fwsync 缺
profile 静默降级 / bugs.md 表格错位后门禁照过 / regress 分母缩水 / BUG-0015 的 guard 写下了
却没有强制消费）。前四条已回流框架成 FB-11/12/14 与 BUG-0028，第五条促成了 0.4.1 的
guard 注入机制。**看到绿灯要先问它覆盖了什么。**

## [0.2.0] 2026-07-27 M1 里程碑签核 PASS：M1-02 落地 + BUG-0008/0009 终态 + regress 覆盖补全，转入 M2

**Done**
- DV 卡：M1-02（ID 前缀响应路由 smoke）落地——`tb/seq_lib.sv`/`test_lib.sv`
  新增 `m1_02_id_prefix_{seq,vseq,test}`（多 slave 端口共享低位 ID、各指
  不同 master 端口，规避 §5.2.1 假冲突 stall）；`tb/scoreboard_refmodel.sv`
  新增 C3.2 源端口响应路由判据（`resp_expect[]`，独立于既有 payload/resp-
  code 判据，可捕获 B 通道无 payload 的跨端口错送）；evidence
  `doc/evidence/v0.1.2/M1-02.log`（96/96/96 match），testplan M1-02 🔲→✅
- 落地期发现并修复 **BUG-0009**（TB_BUG，CLOSED）：`mstport_monitor` 单槽
  AW/W 配对方案在 master 端口 AW-W 解耦/多写 burst 汇聚时错配（第二个 AW
  覆盖首个未收尾 burst 的元数据）；改 AW FIFO 队列配对（`aw_q[$]`，镜像
  `mstport_responder` 既有写法）；同轮修复 scoreboard `pending_by_id` 键加
  方向位（读写独立通道，同 id 不再别名）。DUT 全程功能正确（resp-route
  C3.2 96/0）。detail page `doc/bugs/BUG-0009.md` 补齐（orch 发现该行初始
  漏建详情页 + taxonomy 标签误用非正典的 "DV_ISSUE"，均已订正为 TB_BUG）
- rev 卡 REV-004：仲裁 BUG-0008（M0 三条存量证据 `## Key check lines` 段
  为空）处置——赞同不追溯重写、不改 signoff-M0，并纠正终态应由 OPEN 转
  **WONTFIX**（已应用）；独立核验 CLAUDE.md 两处"本地重述→指针"收成
  （taxonomy 登记无条件、执行纪律→discipline.md）语义无损，本地仪式
  （`/closeout`+`git push`+等待指令）确认仍落在保留句里，未悄悄消失
- 补全 `sim/regress/regress.list`：M0 期只有 `upstream_sanity`，M1 落地后
  一直未跟进；补入 `m1_01_smoke_test`/`m1_02_id_prefix_test`（恰对应
  BUG-0007/0009 的 min_repro，满足清单自身"每个已闭合 bug 失败 seed 永久
  入列"的约定），`make regress` 3/3 PASS，`doc/evidence/v0.1.2/
  result_summary.txt` 登记，`make signoff-check` 机器条件三项转全绿
- rev 卡：M1 里程碑签核 `doc/evidence/v0.1.2/signoff-M1.md`——**PASS**（带
  2 项非阻塞残留风险：R1 已登记的 `v0.1.0/M1-01.log` 字节滞后于 BUG-0009
  后的当前树，功能面由回归摘要+详情页+签核三路独立复跑覆盖；R2 本轮改动
  提交前 `fix_commit` 为占位，随本次 closeout 提交回填）。人工抽查 5 对
  BUG-0009 做了真实的一次性废弃分支守卫证伪：回退 monitor 单槽版本后
  确定性复现"4 route 失配+7 dangling"登记签名，逐字节复原后丢弃分支

**Not done**
- M2（功能场景 + SVA + 功能覆盖）未开始
- BUG-0008 存量三条 M0 证据仍未重生成（REV-004 裁决为不重写，非待办）
- signoff-M1 R1：`doc/evidence/v0.1.0/M1-01.log` 未随 BUG-0009 修复重生
  （非阻塞，功能面已三路复验覆盖，留给后续视需要处理）

**Next**
- 派 arch 设计输入卡：M2 功能场景清单（保序/stall/decode error/ATOP 等，
  design-prompt C2/C5 已成文待激活）+ SVA 覆盖点规划
- M2 功能覆盖率采集基建（六类覆盖率路线图见 CLAUDE.md §6）

**How verified**
- 独立重跑 `make run TEST=m1_02_id_prefix_test SEED=1`（96/96/96 match，
  UVM_ERROR 0，SVA 0 failures）与 `make run TEST=m1_01_smoke_test SEED=1`
  回归（48/48/48，0 错误，新判据无回归）；`make regress` 3/3 PASS；
  `make signoff-check` 全绿（含 `[yes] signoff file`）；`make docs-check`/
  `make fw-check` 全绿；REV-004/signoff-M1 见 `doc/review/`、
  `doc/evidence/v0.1.2/`

## [0.1.2] 2026-07-27 框架 0.2.0 → 0.3.0 两轮回流闭环 + BUG-0008 补登

**Done**
- FB 首轮回流闭环：FB-1~FB-7 全部落入框架 0.2.1，本仓库 `fwsync --pull`
  两次（0.2.1 → 0.3.0），`doc/fw-feedback.md` 七行 `open` → `fixed@0.2.1`
  并加头注。实质拿回来的变化：`evidence.py` 非 UVM tb 摘要窗口 2 → 20 行
  + 关键行正则增补（FB-6）；`.claude/agents/de.md` 修复交付改置 FIXING，
  fix_commit 与 FIX_READY 归 orch 提交后回填（FB-5，绕行作废）；四角色
  交付报告新增强制字段"本卡是否命中 taxonomy 异常（含已绕过的）"
  + taxonomy 正典补"登记无条件"段（FB-7）；`vcs-2018.mk` 的
  `LM_LICENSE_FILE` 注释挑明是必须覆盖的占位值（FB-2）。
- 框架 0.3.0 带来 `workflow/discipline.md`（执行纪律五条，优先级高于便利、
  低于核心不变量与角色隔离），CLAUDE.md 与四个角色文件都指向它。本仓库
  自产的"小步快跑"被上收为正典 rule 5。
- 反漂移清理两处本地重述：CLAUDE.md §2 的 taxonomy 登记表述、以及那段
  自产"执行纪律"三条，都收成指向正典的指针，只保留本仓库特有的内容
  （M1-01 案例、落地判据含 `/closeout` 的本地仪式）。
- **BUG-0008 补登**（TOOL_ENV，OPEN）：`doc/evidence/v0.0.1/` 三条 M0 证据
  的 `## Key check lines` 段为空。此事 signoff-M0 抽检 R1 就发现了，却只
  进了 `doc/fw-feedback.md` FB-6 和评审记录，`doc/bugs.md` 一直没有行——
  与 BUG-0007 同一形状的可追溯性缺口，按"登记无条件"补上。

**Not done**
- 存量三条 M0 证据未重新生成。`doc/evidence/v0.0.1/` 是 signoff-M0 已签核
  指向的产物，用新抽取器覆写会改动被签核对象而签核记录无法同步重签；
  权衡后判定"摘要不全"轻于"签核指向的证据在签核后被改过"。是否重生成
  属 rev 裁决，orch 不自行 WONTFIX（路径写在 BUG-0008 的 `## rerun`）。
- M1-02 未动（scoreboard_refmodel / sva_bind 两行仍非 ✅）。

**Next**
- 派 rev 卡：① 裁决 BUG-0008 存量是否重生成；② 复核本轮两处本地重述收编
  是否有语义丢失。
- 派 DV 卡推进 M1-02。

**How verified**
- 每轮 pull 后 `make fw-check` + `make docs-check` 双绿（当前
  framework 0.3.0，26 个 pin 文件）；BUG-0008 行与详情页加入后 docs-check
  仍绿（FL 详情页非终态可部分填写，本页已按 schema 八段写全）。
- 框架侧 48 例自测全过（新增一例钉住 discipline.md 到位且两种 profile 下
  每个角色文件都指向它），framework master 与两个标签已推送。
- FB-6 的修复在框架侧有保险丝：还原窗口与正则后 48 例中恰好只有
  `test_plain_nonuvm_verdict_line_captured` 失败。

## [0.1.1] 2026-07-27 M1 首个场景：UVM env 骨架落地 + M1-01 smoke ✅

**Done**
- arch 设计输入卡：`doc/design-prompt/{tb_top,uvm_env,scoreboard_refmodel,sva_bind}.md`（每约束引 spec 章节）+ feature-matrix `F-M1-01~04` + testplan `M1-01`/`M1-02`（🔲）+ vendor 升级评估 `doc/vendor-upgrade-v0.39.10.md`（结论 Defer：v0.39.9→v0.39.10 对 axi_xbar 全部 spec 蒸馏来源逐字节相同，唯一差异为非行为的冗余 elaboration 断言删除 #407）
- rev 交付门 `REV-002`：M1 design-prompt 集放行（cleared for DV），未见 behavior-leak；`sva_bind.md` 两处引用瑕疵（PASS-with-notes，非阻塞）；vendor 升级 memo 结论逐条实测证实
- DV 卡：`tb/` UVM env 骨架（tb_top + slave/master agent + 地址路由/ID 前缀参考模型记分板 + SVA）落地，`sim/flist/tb.f` + `sim/Makefile`（按 TEST 名切换 M0 上游 tb / M1 UVM tb_top，M0-01 复现命令不变）；M1-01 smoke 通过（scoreboard route/resp 48/48 match、SVA 2119 assertions 0 failures、UVM_ERROR 0、自然终止），evidence 登记 `doc/evidence/v0.1.0/M1-01.log`；`sva_bind.md` 两处引用瑕疵随手订正
- 工具偏离处理：VCS-2018.09-SP2 拒绝 `bind <interface> <module>`（`Error-[IIM]`），DV 改直接例化挂 SVA；rev 独立复核 `REV-003`（含最小探针复现该报错签名）确认行为等价、放行，`sva_bind.md` C1.1 补订正说明，CLAUDE.md §4 补记该工具限制供后续卡参考
- 附带完成（同周期、独立提交推送）：README 新增"DUT 模块层级"小节（grep 例化关系逐级追至叶子/common_cells 基础单元）+ "数据流概览"讲解 + `doc/attach/axi_xbar_dataflow.svg` 示意图

**Not done**
- `M1-02`（ID 前缀响应路由 smoke）未做，仍 🔲；`scoreboard_refmodel.md` 里为 M1-02 预留的判决路径仍是 stub
- M1 里程碑未收官（尚缺 M1-02 + 里程碑签核）
- `FB-1~FB-6` 批量回流 iverif-workflow 框架仓库仍未做——里程碑边界约定时点已过一个版本周期，欠账中

**Next**
- 派 DV 卡实现 `M1-02`
- `FB-1~FB-6` 批量回流 iverif-workflow（已逾期一个周期，优先级提高）
- M1 里程碑收官（M1-02 完成后）

**How verified**
- 独立重跑 `make compile`（0 error/0×NCE）+ `make run TEST=m1_01_smoke_test SEED=1`（scoreboard 48/48 match、SVA 0 failures、UVM_ERROR 0，与 DV 交付报告一致）+ `make run TEST=upstream_sanity SEED=1`（M0-01 回归不变，Tests Failed 0）；`make docs-check`/`make fw-check` 全绿；`REV-002`/`REV-003` 见 `doc/review/`

## [0.1.0] 2026-07-27 M0 里程碑签核 PASS：基建+sanity+spec v0 收官，转入 M1

**Done**
- rev 全新实例（非本里程碑任何 review/fix 当事人）执行 M0 里程碑签核：机器条件 3×PASS 自跑复核 + 3 项人工抽查（抽查 4 覆盖闭合 N/A 但按精神等价核验目标机制命中；抽查 5 守卫证伪——一次性废弃分支 revert BUG-0006 修复、`make compile` 复现原 6×NCE 签名、清理分支；抽查 6 spec 债务清零核对 REV-001 §5 逐条裁决）
- 签核记录 `doc/evidence/v0.0.2/signoff-M0.md`：总体裁决 **PASS**，2 项非阻塞残留风险（R1 证据摘要窗口未捕获非 UVM 记分板判决行；R2 末拍在飞断言，良性）
- R1 回流 `doc/fw-feedback.md` FB-6（kernel/evidence.py，annoyance）
- `make signoff-check` 全绿（含 signoff 文件识别）；`make bump-minor` 0.0.2→0.1.0

**Not done**
- M1（UVM env + smoke，评估 v0.39.10 升级）未开始
- FB-1~FB-6 回流框架仓库（iverif-workflow）未做——里程碑边界批量回流的约定时点已到，尚待执行
- R1（evidence.py 摘要窗口）本身未修——按框架红线本仓库不改 scripts/，需上游修复

**Next**
- FB-1~FB-6 批量回流 iverif-workflow（里程碑边界回流仪式，见 CLAUDE.md §5）
- 派 arch 设计输入卡：M1 UVM env 骨架（tb_top + 多 master/slave agent + 地址路由参考模型记分板）+ 评估 v0.39.10 升级影响
- `git tag v0.1.0`

**How verified**
- `make signoff-check` 全绿（机器条件 3×PASS + signoff 文件 `[yes]`）；`make docs-check` / `make fw-check` 全绿；签核记录见 `doc/evidence/v0.0.2/signoff-M0.md` §5 裁决

## [0.0.2] 2026-07-27 DV 复验闭环：M0-01 ✅ + BUG-0001/0006 CLOSED

**Done**
- DV 复验卡（全新实例，closer≠fixer）：`make compile`（clean rebuild）0×Error-[NCE]、`make smoke TEST=upstream_sanity SEED=1` 自然终止零 mismatch（178296/178296，SVA 3198 assertions 0 failures）、`make regress` 1/1 PASS
- 三条 evidence 经 `make evidence` 机械登记：BUG-0001、BUG-0006、M0-01（均落 `doc/evidence/v0.0.1/`，line 1 replay + 生成戳）
- BUG-0001 FIX_READY → CLOSED；BUG-0006 FIX_READY → CLOSED；testplan M0-01 ❌ → ✅（状态格由 evidence.py 回填，非手改）
- `sim/result_summary.txt` 拷入 `doc/evidence/v0.0.1/`，`make signoff-check` 机器条件 1~3 全 PASS
- CLAUDE.md §2 新增原则"小步快跑"（Small closed loops, then stop）：长任务切小块闭环，完成即推送并等待用户指令

**Not done**
- M0 里程碑未收官：rev signoff 卡未派（`signoff-M0*.md` 缺失，`make signoff-check` 卡在人工抽检 4~6 项）
- FB-1~FB5 回流框架仓库未做

**Next**
- 派 rev 里程碑签核卡（覆盖闭合抽检 + guard falsification + SPEC_ISSUE 清单）→ signoff-M0 记录 → `make bump-minor` → tag v0.1.0
- FB 批量回流 iverif-workflow

**How verified**
- `make docs-check` / `make fw-check` 全绿；`make signoff-check` 机器条件 1~3 PASS（4~6 待 rev）；见 `doc/evidence/v0.0.1/{BUG-0001,BUG-0006,M0-01,result_summary}`

## [0.0.1] 2026-07-27 M0 基建首循环：vendor pin + 编译排雷 + spec v0

**Done**
- iverif-workflow 0.2.0 首次实战接入（copilot/en，正文中文约定见 CLAUDE.md §6）；fw-feedback.md 台账建立并登记 FB-1~FB-5
- vendor pin：axi v0.39.9 + 三依赖库（SHA 见 vendor/VENDOR.md），上游 tb/doc 按同 tag 补拉
- sim 基建：flist 三件套（floo 已验证 Bender 序）+ sim/Makefile（VCS-2018 workaround + SIM_OPTS_2018）
- 编译排雷：BUG-0001（P-001，$sformatf/genvar NCE，@1a15627）与 BUG-0006（P-002，struct 成员端口位宽 NCE 共 3 处，@8062976）均 FIX_READY，make compile 全过（simv 生成）
- spec v0：arch 蒸馏 → REV-001 评审（条件通过，C1~C5）→ 修订应用 → 重 pin（@cbd2b09）；四 spec 缺口（BUG-0002~0005）经 rev 裁决 SPEC_CHANGED（环境约束/延迟不敏感/采信主文档）

**Not done**
- M0-01 仍 ❌：DV 复验未跑（编译已通，仿真 + evidence 未执行——本循环按"小步快跑"在此暂停）
- BUG-0001/0006 未 CLOSED（等 DV 复验闭环，closer ≠ fixer）
- regress/result_summary 归档、rev 签核、M0 里程碑完成均未开始
- fw-feedback 回流框架仓库未做（FB-1~FB-5 全部 open）

**Next**
- 派 DV 复验卡：重跑 M0-01（make smoke）→ make evidence SCEN=M0-01 → make evidence BUG=0001/0006 闭环 → regress + result_summary 归档（顺带实证 FB-3 的 Summary 行悬案）
- 之后：rev 签核卡（含 P-001/P-002 补丁评审回填 VENDOR.md review 列）+ signoff-check + bump-minor → v0.1.0 tag；FB 批量回流 iverif-workflow

**How verified**
- make docs-check / fw-check 全绿（本块提交前复跑）；make compile 结论见 BUG-0006 root_cause 实证（out/simv 生成、comp.log 0×NCE）；spec pin=2637206e…（提交 cbd2b09）

## [0.0.0] 2026-07-27 scaffolded

**Done**
- fwsync --init (framework snapshot + doc seeds)

**Not done**
- everything else

**Next**
- M0 bring-up: vendor/flists/sim Makefile, spec v0

**How verified**
- make docs-check

