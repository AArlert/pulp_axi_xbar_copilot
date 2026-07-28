# Dispatch: coverage hole

<!-- Canonical: iverif-workflow/loop/fail/coverage_hole.md — pinned snapshot.
     Axioms: recording. Consumer: dv/human during coverage closure. -->

A bin is empty (or a code-coverage gap persists) during closure. The first
question is never "how do I hit it" — it is "should a scenario for this
exist at all". `xcov` queries the VCS/Verdi coverage database with source
mapping; use it to name the hole precisely before dispatching.

| # | Question | Finding | Learning-line action | Copilot-line action |
|---|---|---|---|---|
| 1 | Does a testplan scenario cover this bin's situation? | no → **planning gap** | Do not write a test yet. Register the scenario row first (id + description + spec clause). A hole without a scenario is a testplan defect | orch registers the row; only then may a dv card exist |
| 2 | Scenario registered but test not written? | normal backlog | Write it (normal micro-loop: code → run → evidence) | dispatch dv card |
| 3 | Test runs but the bin stays empty — do constraints exclude the combination? | `CONSTRAINT_BUG` | Loosen/fix; audit historical PASSes per taxonomy rule | dv fixes; orch schedules audit |
| 4 | Constraints legal but still unreachable — does the DUT structure make it impossible? (e.g. bins of a feature the current config excludes) | unreachable | Write the unreachability analysis into `doc/coverage-waivers.md` and request rev signoff. **Silent excludes are forbidden** — an exclude file entry without a waiver row fails review | same; rev signs every exclude |
| 5 | None of the above | escalate | Take to rev with the xcov evidence attached | escalate to human |

Coverage closure ≠ risk closure: the signoff rubric
(`workflow/review/rubric.md`) additionally spot-checks *hit* bins to confirm they
were hit by meaningful scenarios, not by accident.
