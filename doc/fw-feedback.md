# iverif-workflow 框架反馈台账

> 本仓库是 iverif-workflow 的首次实战应用。任何框架摩擦（门禁误伤、脚本缺口、
> 文档失实）当场登记于此，**绝不本地修改 `scripts/` / `workflow/` /
> `.claude/skills/`**（fw-check 红线）。blocking 当日回流框架仓库，
> annoyance 里程碑边界批量回流。回流仪式见 CLAUDE.md §5 与
> `../iverif-workflow/docs/adoption.md`。

severity：blocking（门禁/脚本拒绝正确工作）| annoyance（文档/体验问题）
status：open | reported | fixed@<ver> | wontfix

| id | date | symptom | framework file | severity | status |
|----|------|---------|----------------|----------|--------|
| FB-1 | 2026-07-27 | `--init` 拒绝仅含 LICENSE/README（及 .claude/settings.local.json）的新仓库，只能手工移开-恢复；建议加 `--allow-existing` 白名单或在 adoption.md 记录移开法 | kernel/fwsync.py (cmd_init) | annoyance | open |
| FB-2 | 2026-07-27 | `LM_LICENSE_FILE ?= 27000@localhost` 回退值与本 VM 实测值 `27000@icarray-virtual-machine` 不符，项目只能在 include 前 export 覆盖；建议回退值改为可探测或文档标注必须覆盖 | make/vcs-2018.mk | annoyance | open |
| FB-3 | 2026-07-27 | 待验证：ucli `run; exit` 驱动的 `$stop` 型 tb 下，`-assert verbose` 的 `Summary:` 行是否出现（evidence.py SVA 腿 fail-closed，缺行即拒收）——首次 `make evidence` 时确认/证伪 | make/vcs-2018.mk / kernel/evidence.py | open question | open |
