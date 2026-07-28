# Work log

Newest block first; capped by docs-check — overflow moves to doc/archive/.

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

