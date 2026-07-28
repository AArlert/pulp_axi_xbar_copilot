<!-- Canonical: iverif-workflow/CONSTITUTION.md — pinned snapshot. Axioms: self-application. Consumer: humans and orch at session start, before discipline/profile; kernel/tests/test_constitution.py. -->

# Constitution

The whole framework on one page. Everything else is either a mechanism
contract (query it, don't memorize it) or an environment fact (look it up).
If a rule anywhere cannot be derived from this page, either the page is
wrong or the rule is suspect — both findings are valuable; report them.

## Axioms

| # | Axiom | 中文 | The rule |
|---|---|---|---|
| 0 | self-application | 自反 | The axioms below bind the rules, the tools, and this page itself. |
| 1 | independence | 独立 | A claim counts only with evidence independent of the claimant. |
| 2 | recording | 落盘 | What is not written into the repo does not exist — intent included. |
| 3 | consumption | 消费 | A mechanism nobody reads does not exist; a trigger nobody observes never fires. |
| 4 | pain-gating | 痛点 | No infrastructure ahead of pain; everything built pays a byte budget. |

Theorems: narrowing must be declared (waiver / divergence) · diagnose in
cost order (TOOL_ENV → TB/CONSTRAINT → SPEC → DUT) · correct out of the box.

## The machine (one loop)

```
doc/spec.md — sha256-pinned, the ONLY source of expectations
     │
intent → work → run → evidence → review → ledger+next ──loop──┐
testplan  role   make  make       rev      docs-check          │
row       cards  run   evidence   6 Qs,    make next           │
first     DE‖DV  (log) FAIL=no    closer                       │
  ▲       files        hand=no    ≠fixer                       │
  │       only          │FAIL                                  │
  │                     ▼                                      │
  └─guards feed─ fail branch: bugs.md row → dispatch table →   │
    future cards (workflow/fail/) → FL: anomaly→chain→guard    │
◄──────────────────────────────────────────────────────────────┘
```

Core invariants (hard gates, canonical statement):

1. **No sim log, no ✅** — only `make evidence` turns a scenario green.
2. **Line 1 is the replay command** — every record replays as written.
3. **The closer is never the fixer** — closure needs an independent re-run.
4. **The spec is pinned** — checkers derive from spec, never from RTL;
   silent spec edits fail the gate.

Every gate is an axiom standing sentry on one pipe of this loop. The roles
(orch, arch, de, dv, rev) are the loop's division of labor, nothing more.

## Mechanism index

| Doc (project path) | Axioms | Consumer |
|---|---|---|
| workflow/constitution.md | 0 | session start; test_constitution |
| workflow/discipline.md | 2,4 | every role, before first edit |
| workflow/profile.md | 1 | orch/human at session start; fwsync selects it |
| workflow/testplan_entry.md | 2 | docs-check; make next; dv cards |
| workflow/evidence_record.md | 1,2 | evidence.py; docs-check; rev |
| workflow/review/six_questions.md | 1 | rev, in every review |
| workflow/review/rubric.md | 1,3 | rev at signoff; docs.py --signoff |
| workflow/fail/failure_record.md | 2 | docs-check; make guards; dispatch Q1 grep |
| workflow/fail/failure_taxonomy.md | 2 | every FL taxonomy section; dispatch |
| workflow/fail/rca_template.md | 2 | FL rca authors; rev |
| workflow/fail/assertion_failure.md | 1,2 | dv/human when an assertion fires |
| workflow/fail/regression_failure.md | 2 | orch/human when regress FAILs |
| workflow/fail/coverage_hole.md | 2 | dv/human during coverage closure |
| .claude/skills/handover/SKILL.md | 2 | session start |
| .claude/skills/evidence/SKILL.md | 1,2 | before any ✅ or CLOSED |
| .claude/skills/closeout/SKILL.md | 2 | end of every work cycle |
| .claude/skills/dispatch/SKILL.md | 1,3 | orch, before every card |
| .claude/agents/ (rendered on pull) | 1 | Claude Code role dispatch |
| CLAUDE.md (rendered at init) | 0 | every session |

## Adding a rule

- A new rule names its generating axiom(s) in the CHANGELOG entry; if none
  fits, you found a new axiom (rare, celebrate) or a suspect rule.
- Every shipped doc has a byte cap (`kernel/tests/test_budgets.py`);
  raising one is a reviewed decision, never a fix.
- A mechanism ships only with a named consumer; a trigger only with an
  observer.
- Stories, genealogy, and adjudications go to `governance/`, never here.
