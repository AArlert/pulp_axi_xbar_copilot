# docsx baseline (F10 — bidirectional)

> Read `doc/design-prompt/doc_mechanization.md` §F10 first. This table is the **one-time sweep boundary set by `doc/review/REV-038.md` §B.1**: "允许一次性入 baseline，但边界为经 rev 审阅的枚举清单 + 排除在飞 bug 位点，非当前所有违规一律追认". The four B.1 boundary conditions this table honors: (a) only violations that already existed in the commit that landed `scripts/docsx.py`; (b) no locus an OPEN/FIXING bug row *mandates fixing* (BUG-0052's 7 actual dead references were fixed in place at `.claude/agents/rev.md`, `.claude/agents/dv.md`, `.claude/skills/dispatch/SKILL.md`, and `doc/bugs.md:3` — none of those 7 loci appear below); (c) every row below cites `REV-038 §B.1` and is grouped by rationale so an over-count is checkable by eye; (d) `docsx.py --check` prunes on fix — a row whose violation stops reproducing turns the whole check red until the row is deleted (F10's reverse direction).

Schema: `| id | family | locus | rev_ref |` (design contract §F10). `locus` is `<path>:<line>` for F1 and `<path>:<line>:<token>` for F2 — the exact string `docsx.py` computes, so a stale row (violation fixed) or an uncited new one is mechanically checkable, not eyeballed.

## doc/bugs.md — BUG-0052's own OPEN row

BUG-0052's row narrates the 7 dead `workflow/` references it reports (now corrected at their actual sites: `.claude/agents/rev.md`, `.claude/agents/dv.md`, `.claude/skills/dispatch/SKILL.md`, `doc/bugs.md:3`). The row's own prose necessarily quotes those same dead strings as evidence of what was wrong — that is not the locus BUG-0052 "mandates fixing" (REV-038 §B.1(b)); it is retrospective narrative that will self-resolve when the row archives (frozen prefix `doc/bugs/`/`doc/archive/`), at which point F10's prune check will force removal of these rows. **Locus line number is not stable** across `make docs-archive` runs (row position shifts as terminal rows above it move out) — a stale/new pair here after an archive pass is expected friction, not a design defect; re-sync by rerunning this generation sweep, same as `doc/lint-baseline.md`'s periodic line-shift re-syncs.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0001 | F2 | doc/bugs.md:22:workflow/fail | REV-038 §B.1 |
| BL-0002 | F2 | doc/bugs.md:22:workflow/fail/ | REV-038 §B.1 |
| BL-0003 | F2 | doc/bugs.md:22:workflow/fail/* | REV-038 §B.1 |
| BL-0004 | F2 | doc/bugs.md:22:workflow/fail/*.md | REV-038 §B.1 |
| BL-0005 | F2 | doc/bugs.md:22:workflow/fail/failure_record.md | REV-038 §B.1 |
| BL-0006 | F2 | doc/bugs.md:22:workflow/review/ | REV-038 §B.1 |
| BL-0007 | F2 | doc/bugs.md:22:workflow/review/* | REV-038 §B.1 |
| BL-0008 | F2 | doc/bugs.md:22:workflow/review/rubric.md | REV-038 §B.1 |
| BL-0009 | F2 | doc/bugs.md:22:workflow/review/six_questions.md | REV-038 §B.1 |

## Forward references to not-yet-built F4/§14 deliverables + the design's own worked examples

`doc/guards.md` (F4's guard table) and `.claude/skills/doc-mechanization/SKILL.md` (§14's human-readable notes) are named by the pinned, rev-approved design contract (`doc/design-prompt/doc_mechanization.md`, REV-038 §A) and by this very sweep's own FB row (`doc/fw-feedback.md`) as deliverables of later batches (REV-038 §15: "均由后续实现卡产出") — grouped here by *token*, regardless of which live file names them, since the rationale is the same wherever it appears. `doc_mechanization.md` also quotes `workflow/nonexistent.md` / `workflow/a.md` / `workflow/b.md` as *worked red_when examples* — text describing a hypothetical action, not a live reference. Editing the pinned contract, or this FB row, to dodge this checker is out of scope for an implementation card.

| id | family | locus | rev_ref |
| --- | --- | --- | --- |
| BL-0010 | F2 | doc/design-prompt/doc_mechanization.md:101:doc/guards.md | REV-038 §B.1 |
| BL-0011 | F2 | doc/design-prompt/doc_mechanization.md:103:doc/guards.md | REV-038 §B.1 |
| BL-0012 | F2 | doc/design-prompt/doc_mechanization.md:186:workflow/a.md | REV-038 §B.1 |
| BL-0013 | F2 | doc/design-prompt/doc_mechanization.md:186:workflow/b.md | REV-038 §B.1 |
| BL-0014 | F2 | doc/design-prompt/doc_mechanization.md:263:doc/guards.md | REV-038 §B.1 |
| BL-0015 | F2 | doc/design-prompt/doc_mechanization.md:272:.claude/skills/doc-mechanization/SKILL.md | REV-038 §B.1 |
| BL-0016 | F2 | doc/design-prompt/doc_mechanization.md:280:doc/guards.md | REV-038 §B.1 |
| BL-0017 | F2 | doc/design-prompt/doc_mechanization.md:282:.claude/skills/doc-mechanization/SKILL.md | REV-038 §B.1 |
| BL-0018 | F2 | doc/design-prompt/doc_mechanization.md:296:doc/guards.md | REV-038 §B.1 |
| BL-0019 | F2 | doc/design-prompt/doc_mechanization.md:306:doc/guards.md | REV-038 §B.1 |
| BL-0020 | F2 | doc/design-prompt/doc_mechanization.md:44:doc/guards.md | REV-038 §B.1 |
| BL-0021 | F2 | doc/design-prompt/doc_mechanization.md:50:doc/guards.md | REV-038 §B.1 |
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

