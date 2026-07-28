# iverif-workflow 框架反馈台账

> 本仓库是 iverif-workflow 的首次实战应用。任何框架摩擦（门禁误伤、脚本缺口、
> 文档失实）当场登记于此，**绝不本地修改 `scripts/` / `workflow/` /
> `.claude/skills/`**（fw-check 红线）。blocking 当日回流框架仓库，
> annoyance 里程碑边界批量回流。回流仪式见 CLAUDE.md §5 与
> `../iverif-workflow/docs/adoption.md`。

severity：blocking（门禁/脚本拒绝正确工作）| annoyance（文档/体验问题）
status：open | reported | fixed@<ver> | wontfix

**第一轮回流已闭环（2026-07-27）**：FB-1~FB-7 全部落入框架 0.2.1，本仓库已
`fwsync --pull`（`iverif.json` 从 0.2.0 → 0.2.1，`make fw-check` / `docs-check`
双绿）。FB-5 的绕行（orch 手动回退 FIX_READY→FIXING）自此作废，按 `.claude/agents/de.md`
新措辞走即可。

| id | date | symptom | framework file | severity | status |
|----|------|---------|----------------|----------|--------|
| FB-1 | 2026-07-27 | `--init` 拒绝仅含 LICENSE/README（及 .claude/settings.local.json）的新仓库，只能手工移开-恢复；建议加 `--allow-existing` 白名单或在 adoption.md 记录移开法 | kernel/fwsync.py (cmd_init) | annoyance | fixed@0.2.1（文档：adoption.md 记录移开法；`--allow-existing` 机制入 deferred 台账待第二次触发） |
| FB-2 | 2026-07-27 | `LM_LICENSE_FILE ?= 27000@localhost` 回退值与本 VM 实测值 `27000@icarray-virtual-machine` 不符，项目只能在 include 前 export 覆盖；建议回退值改为可探测或文档标注必须覆盖 | make/vcs-2018.mk | annoyance | fixed@0.2.1（文档：注释挑明是必须覆盖的占位值） |
| FB-3 | 2026-07-27 | 待验证：ucli `run; exit` 驱动的 `$stop` 型 tb 下，`-assert verbose` 的 `Summary:` 行是否出现（evidence.py SVA 腿 fail-closed，缺行即拒收）——首次 `make evidence` 时确认/证伪 | make/vcs-2018.mk / kernel/evidence.py | open question | fixed@0.2.1（经 FB-6 证实：`Summary:` 行确实出现，缺口在 evidence.py 窗口/正则，非工具选项） |
| FB-5 | 2026-07-27 | 角色文件与门禁自相矛盾：de.copilot.md 规定 DE"置 FIX_READY（不置 CLOSED）"，但 docs-check 要求 FIX_READY 行 fix_commit 非空，而 DE 交付时 orch 尚未提交、hash 不存在——按角色文件走必撞门禁（本次 BUG-0001 实撞）。docs.py NEXT_PHRASES 的本意是 FIXING→（commit 后）→FIX_READY；建议 de.copilot.md 改为"置 FIXING，FIX_READY 由 orch 在提交后连同 fix_commit 一并回填" | agents/de.copilot.md vs kernel/docs.py | blocking（有绕行：orch 回退状态） | fixed@0.2.1（de.copilot.md 改置 FIXING；docs.py 的 `make next` 短语同步改为 orch 提交后回填） |
| FB-4 | 2026-07-27 | Claude Code 会话中途 `fwsync --init` 渲染的 .claude/agents/ 注册有延迟（本次首批 arch/dv 派卡即报 "Agent type not found"，只能用 general-purpose 兜底承载角色文件；数分钟后类型才可用）；建议 adoption.md 在 --init 步骤后提示"重启会话（或等类型注册生效）再派卡" | docs/adoption.md | annoyance | fixed@0.2.1（文档：adoption.md 剧本 1 提示重启会话再派卡） |
| FB-6 | 2026-07-27 | 非 UVM tb（如上游 `tb_axi_xbar`，ucli `run;exit` 驱动 `$stop`）的记分板判决行（如 `Tests Failed: 0`）常落在 `PLAIN_MARK` 摘要窗口上沿之外，且不匹配 `KEY_LINE_RE`（pass\|match\|compare ok\|check ok\|running test），导致已登记证据的 `## Key check lines` 段为空——判定本身仍稳健（`svacheck.judge` 两腿制 fail-closed，SVA 腿独立零失败即拒收），但证据摘要未如实反映功能记分板结果，需人工复读源日志才能确认（signoff-M0 抽查 4 实测，R1）；建议上扩摘要窗口或为非 UVM tb 增补 `Tests Failed`/`ended`/`mismatch` 关键行模式 | kernel/evidence.py | annoyance | fixed@0.2.1（evidence.py 窗口 2→20 行 + 关键行正则，附保险丝测试；**存量 v0.0.1 三条记录仍空**，不追溯重写已签核产物） |
| FB-7 | 2026-07-27 | 四个角色模板（`agents/{arch,de,dv,rev}.copilot.md`）里 `doc/bugs.md` 登记指令都窄化到各自语境（DV 仅"on a mismatch"；DE/arch 仅"自己撞见的 spec 歧义/已挂号 bug 修复"）——`workflow/taxonomy/failure_taxonomy.md` 明确列出的五类判据（尤 `TOOL_ENV`）只要不是"scenario mismatch"触发（如实现期编译/工具报错、同卡内已绕过），没有任何角色文件的指令要求登记；taxonomy.md 正文本身也只描述判据，无一句"登记与是否阻塞 evidence/是否同卡内绕过无关"的显式声明。本仓库 M1-01 实测踩中：VCS-2018 拒绝 `bind <interface> <module>`，DV 同卡内改直接例化绕过，全程只留在代码注释 + rev 评审记录（REV-002/REV-003），未落 `doc/bugs.md`，taxonomy.md 自证的"下一个人能 grep 到"因此落空（orch 事后发现，已补登记 + 项目侧 CLAUDE.md §2 加了一条不豁免声明作本地缓解，但角色模板本身未修）；建议：① taxonomy.md 开头补"登记是无条件的，不因是否阻塞 evidence 或是否同卡内绕过而豁免"；② 四角色模板的固定交付报告格式里都加一条字段"本卡是否命中 taxonomy 任一类异常（含已绕过的）：是/否 + BUG-ID" | agents/*.copilot.md（kernel 渲染源）+ workflow/taxonomy/failure_taxonomy.md | annoyance（未被门禁拒绝，但是静默的可追溯性缺口，建议按核心不变量级别优先处理而非常规 annoyance 排期） | fixed@0.2.1（taxonomy.md 补"登记无条件"段 + 四角色模板增设强制字段） |
| FB-8 | 2026-07-27 | `kernel/docs.py` 的 `NEXT_PHRASES["copilot"]["undelivered"]`/`["prompt_missing"]` 硬编码"dispatch DE card"，隐含"copilot 项目里 feature-matrix 的 module 交付物永远是 DE 写的 RTL"；本仓库是 vendored-DUT 项目（无 `rtl/`，DE 卡按 CLAUDE.md §6 仅限 vendor 工具兼容补丁），feature-matrix 的 module 交付物其实全部是 DV 写的 tb 代码。`make next` 因此对**任何**尚未交付的 tb 模块（本次触发者：M2 新增的 `functional_coverage`，`doc/feature-matrix.md` F-M2-08）都会给出"dispatch DE card"的建议，人工需要凭 CLAUDE.md §6 的项目常识纠偏，而非照做——纯 advisory 文案不准确，未拒绝任何操作，`docs-check`/门禁均不受影响。且该短语无 per-project override 钩子（`columns_override` 有、`NEXT_PHRASES` 没有），项目侧无法本地纠正而不碰 `scripts/`。建议：`NEXT_PHRASES` 支持类似 `columns_override` 的 `iverif.json` 覆盖项（例如 `next_phrases_override`），或在 vendored-DUT 场景下把措辞改得角色中立（如"dispatch a card for the owning role（DE/DV，视本项目 CLAUDE.md 的 RTL/TB 归属而定）"） | kernel/docs.py (NEXT_PHRASES) | annoyance | open |
| FB-9 | 2026-07-28 | `scripts/evidence.py` 的 `KEY_LINE_RE` 不匹配 UVM 报告里的 `[FCOV_SUMMARY]` 明细行，功能覆盖率百分比因此进不了 evidence 摘要的 `## Key check lines` 段——只在"Report counts by id"里露出一个 id 计数（本仓库 F-M2-08 落地后：七条 evidence 各显示 `[FCOV_SUMMARY] 2`，而每个 covergroup 的 samples/inst_cov 数字全部落在摘要窗口之外）。后果：覆盖率证据的**数字**不在证据文件里，里程碑签核时要么回源 log、要么回跑 `make cov`，与"evidence 是自足的可复核制品"这一意图相悖；同类问题的既有先例是 FB-6（判决行落在摘要窗口之外）与 BUG-0008（M0 三条证据 `## Key check lines` 段为空）。建议：`KEY_LINE_RE` 增加对 `[FCOV_SUMMARY]`/`[COV_*]` 一类覆盖率摘要标签的识别，或提供项目侧可配的额外关键行模式（类似 `columns_override` 的 `iverif.json` 钩子），使各项目能把自己的覆盖率摘要标签纳入而不必碰 `scripts/` | scripts/evidence.py (KEY_LINE_RE) | annoyance | open |
