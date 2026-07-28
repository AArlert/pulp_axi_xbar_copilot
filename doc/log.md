# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

