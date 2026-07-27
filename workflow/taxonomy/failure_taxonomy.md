# Failure taxonomy

Five classes. Every failure record's `## taxonomy` section names exactly
one. The class determines the next action (see `dispatch/`) and where the
lesson is banked.

**Diagnose in cost order** — cheapest hypothesis first, most expensive
accusation last:

```
TOOL_ENV → TB_BUG / CONSTRAINT_BUG → SPEC_ISSUE → DUT_BUG
```

Blaming the DUT costs the most (in a learning repo it means a vendor patch
and possibly an upstream report; in any repo it requires rev signoff), so it
is earned by eliminating everything else — not reached by default.

## The five classes

| Class | You are here if… (decision cues, check in order) | Typical next step |
|---|---|---|
| `TOOL_ENV` | Result changes with seed/machine/build but not stimulus; clean lint yet compile-time weirdness; matches a known tool defect (e.g. VCS O-2018 traits — see `make/vcs-2018.mk` header); stale build artifacts, wrong seed recorded, evidence older than the code it certifies | Clean rebuild + minimal repro; check the project's known-issues list (`P-xxx` patches, TOOL_ENV FLs); record so the next person greps it instead of rediscovering it |
| `TB_BUG` | Driver violates protocol timing (e.g. valid waits on ready); monitor samples the wrong edge; scoreboard's expected value derived wrongly — or derived **from the RTL instead of the spec** | Fix TB → rerun this scenario **and** spot-check neighboring scenarios that share the component |
| `CONSTRAINT_BUG` | Random stimulus produced a protocol-illegal combination; or constraints are so tight the target scenario is unreachable | Fix constraints → **re-examine historical PASSes** of scenarios using the same constraints: were they green only because the stimulus never reached the hard case? |
| `SPEC_ISSUE` | spec.md contradicts upstream documentation, or does not define the behavior at all; DUT and TB each defensible under a different reading | Escalate to rev arbitration → spec change record + re-pin → sync testplan/affected checkers. Never "interpret locally" and move on |
| `DUT_BUG` | Waveform shows DUT output violating an explicit spec clause; reproducible with an independent stimulus path (e.g. upstream smoke TB) | Requires rev signoff to assert. Then: vendored DUT → `P-xxx` patch + optional upstream report; own RTL → bug to the design side. Always ends with a regression guard |

## Mapping to bugs.md

- The summary row's `suspect` column stays coarse (`TB / DUT / spec`) for
  scanability; the taxonomy class lives in the detail page.
- Terminal-state correspondence: `TB_BUG` row state ↔ TB_BUG/CONSTRAINT_BUG
  classes; `SPEC_CHANGED` ↔ SPEC_ISSUE; `CLOSED` ↔ DUT_BUG (fixed) or
  TOOL_ENV (worked around); `WONTFIX` ↔ any class where the cost/benefit
  says stop — the record still needs rca + guard-or-rationale.

## Why CONSTRAINT_BUG is its own class

It could be filed under TB_BUG, but its follow-up is unique and expensive to
forget: a constraint bug **invalidates history**. Every past green run that
shared the constraint may have been vacuously green. No other class forces
that retroactive audit, so the taxonomy keeps it visible.
