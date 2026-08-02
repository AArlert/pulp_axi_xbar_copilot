# docsx baseline (F10 — bidirectional)

> Read `doc/design-prompt/doc_mechanization.md` §F10 first. This table is the **one-time sweep boundary set by `doc/review/REV-038.md` §B.1**: "允许一次性入 baseline，但边界为经 rev 审阅的枚举清单 + 排除在飞 bug 位点，非当前所有违规一律追认". The four B.1 boundary conditions this table honors: (a) only violations that already existed in the commit that landed `scripts/docsx.py`; (b) no locus an OPEN/FIXING bug row *mandates fixing* (BUG-0052's 7 actual dead references were fixed in place at `.claude/agents/rev.md`, `.claude/agents/dv.md`, `.claude/skills/dispatch/SKILL.md`, and `doc/bugs.md:3` — none of those 7 loci appear below); (c) every row below cites `REV-038 §B.1` and is grouped by rationale so an over-count is checkable by eye; (d) `docsx.py --check` prunes on fix — a row whose violation stops reproducing turns the whole check red until the row is deleted (F10's reverse direction).

Schema: `| id | family | locus | rev_ref |` (design contract §F10). `locus` is `<path>:<line>` for F1 and `<path>:<line>:<token>` for F2 — the exact string `docsx.py` computes, so a stale row (violation fixed) or an uncited new one is mechanically checkable, not eyeballed.

## doc/bugs.md — BUG-0052's own OPEN row

BUG-0052's row narrates the 7 dead `workflow/` references it reports (now corrected at their actual sites: `.claude/agents/rev.md`, `.claude/agents/dv.md`, `.claude/skills/dispatch/SKILL.md`, `doc/bugs.md:3`). The row's own prose necessarily quotes those same dead strings as evidence of what was wrong — that is not the locus BUG-0052 "mandates fixing" (REV-038 §B.1(b)); it is retrospective narrative that will self-resolve when the row archives (frozen prefix `doc/bugs/`/`doc/archive/`), at which point F10's prune check will force removal of these rows. **Locus line number is not stable** across `make docs-archive` runs (row position shifts as terminal rows above it move out) — a stale/new pair here after an archive pass is expected friction, not a design defect; re-sync by rerunning this generation sweep, same as `doc/lint-baseline.md`'s periodic line-shift re-syncs.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |

## Forward references to not-yet-built §14 deliverables + the design's own worked examples

**Card-2b update**: `doc/guards.md` now exists (F4 landed) — the 8 rows that cited it as a *not-yet-built* forward reference (former BL-0010/0011/0014/0016/0018/0019/0020/0021) are pruned per F10's reverse direction (a baseline row whose violation stopped reproducing must not linger). `.claude/skills/doc-mechanization/SKILL.md` (§14's human-readable notes) remains a deliverable of a later batch (REV-038 §15: "均由后续实现卡产出"). `doc_mechanization.md` also quotes `workflow/nonexistent.md` / `workflow/a.md` / `workflow/b.md` as *worked red_when examples* — text describing a hypothetical action, not a live reference. Editing the pinned contract, or this FB row, to dodge this checker is out of scope for an implementation card.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0012 | F2 | doc/design-prompt/doc_mechanization.md:186:workflow/a.md | REV-038 §B.1 |
| BL-0013 | F2 | doc/design-prompt/doc_mechanization.md:186:workflow/b.md | REV-038 §B.1 |
| BL-0015 | F2 | doc/design-prompt/doc_mechanization.md:272:.claude/skills/doc-mechanization/SKILL.md | REV-038 §B.1 |
| BL-0017 | F2 | doc/design-prompt/doc_mechanization.md:282:.claude/skills/doc-mechanization/SKILL.md | REV-038 §B.1 |
| BL-0022 | F2 | doc/design-prompt/doc_mechanization.md:83:workflow/nonexistent.md | REV-038 §B.1 |
| BL-0023 | F2 | doc/fw-feedback.md:77:.claude/skills/doc-mechanization/SKILL.md | REV-038 §B.1 |

## .claude/skills/dispatch/SKILL.md — historical note on a deleted file

Explains (FB-28) that `.claude/agents/orch.md` was deliberately deleted and its content merged into this file. Rewording the explanation to hide the now-dead path would be worse than an honest, cited baseline entry.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0024 | F2 | .claude/skills/dispatch/SKILL.md:8:.claude/agents/orch.md | REV-038 §B.1 |

## doc/fw-feedback.md — frozen-by-policy historical entries

FB-23 ("冻结记录不回改"): once written, an FB row is a historical record of the upstream file layout *at the time it was filed* — several rows (FB-7..FB-12 era) cite the pre-0.8.0 upstream paths (`workflow/schema/*.md`, `workflow/signoff/rubric.md`, `scripts/make/evidence.mk`, `scripts/fwsync.py`, ...). `doc/fw-feedback.md` is a live file by C1.2 (it keeps growing), but FB-23 puts old rows out of reach for editing the same way the directory-based frozen prefixes do for `doc/bugs/`/`doc/review/` — the exemption is per-locus (these exact, dated rows), not a blanket pass for the file: a dead reference in a *new* FB row is still real and will not be in this table (see FB-35/FB-36, added the same day this baseline was built, which deliberately avoid the dead-path shape instead of being baselined; FB-37's one forward-reference token lands in group B above, not here). `doc/fw-feedback.md:46`'s `tb/-rooted` is a heuristic artifact of the same kind as row F below (prose shorthand the path-token regex over-captures), filed here because it lives in the same frozen-by-policy row.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0025 | F2 | doc/fw-feedback.md:45:workflow/taxonomy/failure_taxonomy.md | REV-038 §B.1 |
| BL-0026 | F2 | doc/fw-feedback.md:46:tb/-rooted | REV-038 §B.1 |
| BL-0027 | F2 | doc/fw-feedback.md:48:workflow/schema/failure_record.md | REV-038 §B.1 |
| BL-0028 | F2 | doc/fw-feedback.md:48:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0029 | F2 | doc/fw-feedback.md:49:scripts/make/evidence.mk | REV-038 §B.1 |
| BL-0030 | F2 | doc/fw-feedback.md:49:workflow/schema/evidence_record.md | REV-038 §B.1 |
| BL-0031 | F2 | doc/fw-feedback.md:49:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0032 | F2 | doc/fw-feedback.md:50:scripts/fwsync.py | REV-038 §B.1 |
| BL-0033 | F2 | doc/fw-feedback.md:50:scripts/make/core.mk | REV-038 §B.1 |
| BL-0034 | F2 | doc/fw-feedback.md:50:workflow/profile.md | REV-038 §B.1 |
| BL-0035 | F2 | doc/fw-feedback.md:50:workflow/profiles.md | REV-038 §B.1 |
| BL-0036 | F2 | doc/fw-feedback.md:52:workflow/schema/failure_record.md | REV-038 §B.1 |
| BL-0037 | F2 | doc/fw-feedback.md:53:workflow/schema/failure_record.md | REV-038 §B.1 |
| BL-0038 | F2 | doc/fw-feedback.md:54:workflow/schema/failure_record.md | REV-038 §B.1 |
| BL-0039 | F2 | doc/fw-feedback.md:55:scripts/make/evidence.mk | REV-038 §B.1 |
| BL-0040 | F2 | doc/fw-feedback.md:55:workflow/schema/failure_record.md | REV-038 §B.1 |
| BL-0041 | F2 | doc/fw-feedback.md:55:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0042 | F2 | doc/fw-feedback.md:56:workflow/schema/failure_record.md | REV-038 §B.1 |
| BL-0043 | F2 | doc/fw-feedback.md:56:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0044 | F2 | doc/fw-feedback.md:57:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0045 | F2 | doc/fw-feedback.md:58:workflow/schema/failure_record.md | REV-038 §B.1 |
| BL-0046 | F2 | doc/fw-feedback.md:58:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0047 | F2 | doc/fw-feedback.md:59:scripts/make/evidence.mk | REV-038 §B.1 |
| BL-0048 | F2 | doc/fw-feedback.md:59:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0049 | F2 | doc/fw-feedback.md:61:scripts/iverif.divergence.json | REV-038 §B.1 |
| BL-0050 | F2 | doc/fw-feedback.md:61:workflow/signoff/rubric.md | REV-038 §B.1 |
| BL-0051 | F2 | doc/fw-feedback.md:64:scripts/fwsync.py | REV-038 §B.1 |
| BL-0052 | F2 | doc/fw-feedback.md:64:workflow/dispatch/*.md | REV-038 §B.1 |
| BL-0053 | F2 | doc/fw-feedback.md:64:workflow/schema/testplan_entry.md | REV-038 §B.1 |
| BL-0054 | F2 | doc/fw-feedback.md:64:workflow/taxonomy/failure_taxonomy.md | REV-038 §B.1 |
| BL-0055 | F2 | doc/fw-feedback.md:68:.claude/agents/orch.md | REV-038 §B.1 |

## M6 forward reference: scripts/cov_loop.py

`doc/milestone.md` + two design-prompts name the M6 constrained-random driver `scripts/cov_loop.py` as a not-yet-built deliverable (REV-037 §BUG-0052 boundary note: "是 M6 待交付物的前向引用，不是漂移，需在判据里显式允许"). It will exist once M6 lands; until then it is a legitimate forward reference, not drift.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0056 | F2 | doc/design-prompt/milestone_restructure.md:205:scripts/cov_loop.py | REV-038 §B.1 |
| BL-0057 | F2 | doc/design-prompt/milestone_restructure.md:219:scripts/cov_loop.py | REV-038 §B.1 |
| BL-0058 | F2 | doc/design-prompt/verification_maturity.md:306:scripts/cov_loop.py | REV-038 §B.1 |
| BL-0059 | F2 | doc/milestone.md:136:scripts/cov_loop.py | REV-038 §B.1 |
| BL-0060 | F2 | doc/milestone.md:150:scripts/cov_loop.py | REV-038 §B.1 |

## doc/milestone.md:25 — flist layering shorthand

"flist 分层（vendor/dut/tb_upstream）" enumerates three flist layer names (`vendor.f`/`dut.f`/`tb_upstream.f`) separated by `/` as prose shorthand; the path-token regex (C1.2's char class allows `-`/`.`) over-captures it as one nested path. A known, bounded heuristic false positive, not a real reference — rewriting project prose solely to dodge a regex shape is out of scope for this card.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0061 | F2 | doc/milestone.md:25:vendor/dut/tb_upstream | REV-038 §B.1 |

## workflow/bugs.md — canon template's illustrative examples

`workflow/bugs.md` is an upstream (canon) file; editing it needs a framework-feedback line and is out of scope here. Its `## regression_guard` template example (`ref: tb/sva/per_id_order_check.sv`) and its DUT_BUG dispatch guidance (`doc/VENDOR.md`, this project's actual convention is `vendor/VENDOR.md` per CLAUDE.md §6) are generic illustrative text, not references into this project's tree.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0062 | F2 | workflow/bugs.md:114:tb/sva/per_id_order_check.sv | REV-038 §B.1 |
| BL-0063 | F2 | workflow/bugs.md:139:doc/VENDOR.md | REV-038 §B.1 |
| BL-0064 | F2 | workflow/bugs.md:35:doc/VENDOR.md | REV-038 §B.1 |

## workflow/records.md — canon template's canonical example

The "**Canonical example.**" fenced block under "Evidence record" is illustrative generic prose (`sim/out/m2_01_smoke_test_20260719.log`), not a reference into this project's tree; `workflow/records.md` is an upstream (canon) file.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0065 | F2 | workflow/records.md:49:sim/out/m2_01_smoke_test_20260719.log | REV-038 §B.1 |

## doc_mechanization.md §F4 self-count drift (F1, REV-038 §A-c4)

REV-038 §A-c4 named this exact locus while gating the design contract: the design doc's own `<!-- docsx:count -->` marker (added precisely so this number stops being hand-maintained) reads 44, computed at REV-038's own evidence time (T1); the live count has since moved to 49 as more `## regression_guard` detail pages were added. This is F1 doing exactly its job — the marker recomputes and disagrees with the frozen prose number. Editing the pinned design contract's number is out of scope for an implementation card; the marker itself proves the drift will be caught the day someone edits the surrounding paragraph instead.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0066 | F1 | doc/design-prompt/doc_mechanization.md:104 | REV-038 §A-c4 |

## doc/guards.md — migrated guard prose (BUG-0011's original text)


`doc/bugs/BUG-0011.md`'s `## regression_guard` prose (now living, verbatim, in `doc/guards.md`'s `note` cell for G-0011) names `workflow/dispatch/coverage_hole.md` — a pre-existing dead reference in the *original* page text (unrelated to this migration; the page was a C1.3 frozen prefix and exempt from F2 until its content moved into the live `doc/guards.md` table). Rewriting a bug's own historical guard rationale to dodge a checker is out of scope for a mechanical migration card.


| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0067 | F2 | doc/guards.md:56:workflow/dispatch/coverage_hole.md | REV-038 §B.1 |

## doc_mechanization.md §F3 — the design contract's own worked-syntax example


`doc/design-prompt/doc_mechanization.md:92` writes the F3 marker's *grammar* as prose (`left="<cmdL>" right="<cmdR>"`, placeholder angle-bracket tokens, not a real command) to document the syntax — the same shape as F2's BL-0022 (`workflow/nonexistent.md` as a worked red_when example, not a live reference). `<cmdL>`'s placeholder text trips the executor's own denylist (`>` — an actual shell redirection operator, coincidentally). Editing the pinned, rev-gated design contract to dodge this checker is out of scope for an implementation card.


| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0068 | F3 | doc/design-prompt/doc_mechanization.md:92:left | REV-038 §B.1 |

## doc/guards.md — F4 type: checklist exceptions (A-c5)


48 of the 49 migrated guards (`doc/design-prompt/doc_mechanization.md` §F4's card-2b delivery report has the full per-guard reasoning) describe actions that require `make run`/`make regress`/`xdebug`/non-repo `sim/out/urgText6/` data, or a `python3` invocation outside the §12 A-c1 whitelist — none of which the §12 executor can safely run (its `make` denylist and `python3 scripts/docs.py`/`scripts/svacheck.py`-only allowlist are deliberate gates, not something a migration card routes around). Every one of them is `type: checklist`, exempted here per REV-038 §A-c5 ("确经 rev 判明不可机械化的新 checklist guard...经 baseline 的 rev_ref 收录后不判红"). Two rows (G-0057/G-0059) additionally carry their own REV-037 per-bug ruling in their `note` cell, cited here for completeness; the general channel is REV-038 §A-c5 for all 48.


| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0105 | F4 | doc/guards.md:G-0001 | REV-038 §A-c5 |
| BL-0106 | F4 | doc/guards.md:G-0007 | REV-038 §A-c5 |
| BL-0107 | F4 | doc/guards.md:G-0008 | REV-038 §A-c5 |
| BL-0108 | F4 | doc/guards.md:G-0009 | REV-038 §A-c5 |
| BL-0109 | F4 | doc/guards.md:G-0010 | REV-038 §A-c5 |
| BL-0110 | F4 | doc/guards.md:G-0011 | REV-038 §A-c5 |
| BL-0111 | F4 | doc/guards.md:G-0012 | REV-038 §A-c5 |
| BL-0112 | F4 | doc/guards.md:G-0013 | REV-038 §A-c5 |
| BL-0113 | F4 | doc/guards.md:G-0014 | REV-038 §A-c5 |
| BL-0114 | F4 | doc/guards.md:G-0015 | REV-038 §A-c5 |
| BL-0115 | F4 | doc/guards.md:G-0016 | REV-038 §A-c5 |
| BL-0116 | F4 | doc/guards.md:G-0017 | REV-038 §A-c5 |
| BL-0117 | F4 | doc/guards.md:G-0018 | REV-038 §A-c5 |
| BL-0118 | F4 | doc/guards.md:G-0019 | REV-038 §A-c5 |
| BL-0119 | F4 | doc/guards.md:G-0020 | REV-038 §A-c5 |
| BL-0120 | F4 | doc/guards.md:G-0021 | REV-038 §A-c5 |
| BL-0121 | F4 | doc/guards.md:G-0022 | REV-038 §A-c5 |
| BL-0122 | F4 | doc/guards.md:G-0023 | REV-038 §A-c5 |
| BL-0123 | F4 | doc/guards.md:G-0024 | REV-038 §A-c5 |
| BL-0124 | F4 | doc/guards.md:G-0025 | REV-038 §A-c5 |
| BL-0125 | F4 | doc/guards.md:G-0026 | REV-038 §A-c5 |
| BL-0126 | F4 | doc/guards.md:G-0027 | REV-038 §A-c5 |
| BL-0127 | F4 | doc/guards.md:G-0028 | REV-038 §A-c5 |
| BL-0128 | F4 | doc/guards.md:G-0029 | REV-038 §A-c5 |
| BL-0129 | F4 | doc/guards.md:G-0030 | REV-038 §A-c5 |
| BL-0130 | F4 | doc/guards.md:G-0031 | REV-038 §A-c5 |
| BL-0131 | F4 | doc/guards.md:G-0032 | REV-038 §A-c5 |
| BL-0132 | F4 | doc/guards.md:G-0033 | REV-038 §A-c5 |
| BL-0133 | F4 | doc/guards.md:G-0034 | REV-038 §A-c5 |
| BL-0134 | F4 | doc/guards.md:G-0036 | REV-038 §A-c5 |
| BL-0135 | F4 | doc/guards.md:G-0037 | REV-038 §A-c5 |
| BL-0136 | F4 | doc/guards.md:G-0038 | REV-038 §A-c5 |
| BL-0137 | F4 | doc/guards.md:G-0039 | REV-038 §A-c5 |
| BL-0138 | F4 | doc/guards.md:G-0040 | REV-038 §A-c5 |
| BL-0139 | F4 | doc/guards.md:G-0041 | REV-038 §A-c5 |
| BL-0140 | F4 | doc/guards.md:G-0042 | REV-038 §A-c5 |
| BL-0141 | F4 | doc/guards.md:G-0043 | REV-038 §A-c5 |
| BL-0142 | F4 | doc/guards.md:G-0044 | REV-038 §A-c5 |
| BL-0143 | F4 | doc/guards.md:G-0045 | REV-038 §A-c5 |
| BL-0144 | F4 | doc/guards.md:G-0046 | REV-038 §A-c5 |
| BL-0145 | F4 | doc/guards.md:G-0047 | REV-038 §A-c5 |
| BL-0146 | F4 | doc/guards.md:G-0048 | REV-038 §A-c5 |
| BL-0147 | F4 | doc/guards.md:G-0056 | REV-038 §A-c5 |
| BL-0148 | F4 | doc/guards.md:G-0057 | REV-037 §BUG-0057; REV-038 §A-c5 |
| BL-0149 | F4 | doc/guards.md:G-0059 | REV-037 §BUG-0059; REV-038 §A-c5 |
| BL-0150 | F4 | doc/guards.md:G-0063 | REV-038 §A-c5 |
| BL-0151 | F4 | doc/guards.md:G-0064 | REV-038 §A-c5 |
| BL-0152 | F4 | doc/guards.md:G-0066 | REV-038 §A-c5 |
| BL-0153 | F4 | doc/guards.md:G-0068 | REV-038 §B.2; REV-038 §A-c5 |

## doc/bugs.md rows with no doc/bugs/<id>.md page — pre-existing historical debt (F5, BUG-0067)


28 rows (22 BUG-* + 6 KILL-*) in `doc/bugs.md`(+archive) predate the F5 checker (design contract `doc_mechanization.md` F5's own `red_when` *is* BUG-0067's original defect — F5 landing is what makes this debt visible for the first time, not something this migration card created). Card boundary text: "存量缺页大军（27+ 条无详情页的历史行）按 F10 入 baseline（rev_ref=REV-038 §B.1——历史行不补页，新行必须有页；契约 F5 有分界，照办）" — historical rows are swept once, not fixed in place; a *new* bug row filed after this baseline lands must have a page or F5 reddens it immediately. Five of these ids (BUG-0052/0053/0060/0061/0067) are separately named by REV-038 §C as bugs whose *own future closure* is "F5 红至补齐" (build the page, then prune this row) — baselining them today does not excuse that closure card from doing the real work; it only keeps today's check green for debt this card did not create and was not asked to retire.


| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0069 | F5 | bugs.md:BUG-0002 | REV-038 §B.1 |
| BL-0070 | F5 | bugs.md:BUG-0003 | REV-038 §B.1 |
| BL-0071 | F5 | bugs.md:BUG-0004 | REV-038 §B.1 |
| BL-0072 | F5 | bugs.md:BUG-0005 | REV-038 §B.1 |
| BL-0073 | F5 | bugs.md:BUG-0006 | REV-038 §B.1 |
| BL-0074 | F5 | bugs.md:BUG-0035 | REV-038 §B.1 |
| BL-0075 | F5 | bugs.md:BUG-0049 | REV-038 §B.1 |
| BL-0076 | F5 | bugs.md:BUG-0050 | REV-038 §B.1 |
| BL-0077 | F5 | bugs.md:BUG-0051 | REV-038 §B.1 |
| BL-0078 | F5 | bugs.md:BUG-0052 | REV-038 §B.1 |
| BL-0079 | F5 | bugs.md:BUG-0053 | REV-038 §B.1 |
| BL-0080 | F5 | bugs.md:BUG-0054 | REV-038 §B.1 |
| BL-0081 | F5 | bugs.md:BUG-0055 | REV-038 §B.1 |
| BL-0082 | F5 | bugs.md:BUG-0058 | REV-038 §B.1 |
| BL-0083 | F5 | bugs.md:BUG-0060 | REV-038 §B.1 |
| BL-0084 | F5 | bugs.md:BUG-0061 | REV-038 §B.1 |
| BL-0085 | F5 | bugs.md:BUG-0065 | REV-038 §B.1 |
| BL-0086 | F5 | bugs.md:BUG-0067 | REV-038 §B.1 |
| BL-0088 | F5 | bugs.md:BUG-0069 | REV-038 §B.1 |
| BL-0089 | F5 | bugs.md:BUG-0070 | REV-038 §B.1 |
| BL-0090 | F5 | bugs.md:BUG-0071 | REV-038 §B.1 |
| BL-0091 | F5 | bugs.md:KILL-0001 | REV-038 §B.1 |
| BL-0092 | F5 | bugs.md:KILL-0002 | REV-038 §B.1 |
| BL-0093 | F5 | bugs.md:KILL-0003 | REV-038 §B.1 |
| BL-0094 | F5 | bugs.md:KILL-0004 | REV-038 §B.1 |
| BL-0095 | F5 | bugs.md:KILL-0005 | REV-038 §B.1 |
| BL-0096 | F5 | bugs.md:KILL-0006 | REV-038 §B.1 |

## doc/evidence/**/*.log orphans + one dangling reference — pre-existing historical debt (F5, BUG-0060)


7 `.log` files under `doc/evidence/` (superseded reruns of the same TEST at earlier version dirs, e.g. `M1-01.log` recurring under `v0.1.0`/`v0.4.23`/`v0.4.24`) that no `doc/bugs.md`(+archive)/`doc/testplan.md` row cites by exact path, plus one dangling reference (`doc/evidence/v0.4.38/0048.log`, quoted inside BUG-0060's own row as a description of a since-deleted orphan artifact from its `min_repro` — the file the closer who produced it "自行删除" per that row's own text). Deleting historical evidence files or editing a closed narrative to dodge this checker is out of scope for a migration card; both sides of BUG-0060's own detection-gate mandate (build the F5 checker) are satisfied — this baseline sweeps the *incidental* historical debt the checker also happens to find, not the checker itself.


| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0097 | F5 | evidence:doc/evidence/v0.1.0/M1-01.log | REV-038 §B.1 |
| BL-0098 | F5 | evidence:doc/evidence/v0.2.0/M2-CFG01.log | REV-038 §B.1 |
| BL-0099 | F5 | evidence:doc/evidence/v0.2.0/M2-WO01.log | REV-038 §B.1 |
| BL-0100 | F5 | evidence:doc/evidence/v0.4.17/M4-BP02.log | REV-038 §B.1 |
| BL-0101 | F5 | evidence:doc/evidence/v0.4.23/M1-01.log | REV-038 §B.1 |
| BL-0102 | F5 | evidence:doc/evidence/v0.4.24/M1-01.log | REV-038 §B.1 |
| BL-0103 | F5 | evidence:doc/evidence/v0.4.27/M3-DE01.log | REV-038 §B.1 |
| BL-0104 | F5 | ref:doc/evidence/v0.4.38/0048.log | REV-038 §B.1 |

