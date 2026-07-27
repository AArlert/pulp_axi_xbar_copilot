# Dispatch: assertion failure

An SVA assertion fired (or a checker flagged a violation). Answer the
questions **in order**; the first "yes/found" row decides. Do not skip to
blaming the DUT.

| # | Question | If yes → class | Learning-line action | Copilot-line action |
|---|---|---|---|---|
| 1 | Does the chart archive know this? `grep -il "<assertion name / symptom>" doc/bugs/` | (reuse prior FL) | Read the old record first; test its rca hypothesis against your waveform before fresh analysis | rca agent loads the FL record into context before any new tracing |
| 2 | Is the property's meaning actually what the spec clause says? (`xsva` renders the property's temporal structure; put it next to the spec sentence) | property bug → `TB_BUG` | Fix the property; the FL record must say *why* the old reading was wrong — that misreading is the lesson | dv agent fixes; rev spot-checks the new property against spec |
| 3 | Was the stimulus at trigger time protocol-legal? (check the driving interface's own assertions and the monitor trace around the failure) | illegal stimulus → `TB_BUG` (driver) or `CONSTRAINT_BUG` (randomization) | Fix driver/constraints; if CONSTRAINT_BUG, audit historical PASSes sharing the constraint (taxonomy rule) | same, via dv agent; orch schedules the historical-PASS audit |
| 4 | Same seed, clean rebuild — does it still fire? | no → `TOOL_ENV` | Minimal repro; check `P-xxx` / TOOL_ENV FLs; record the environment cue | runner reproduces; rca classifies |
| 5 | All above eliminated: locate `first_anomaly` in the waveform (`xdebug` backward trace from the assertion time) | `DUT_BUG` **candidate** | Write the FL with first_anomaly + chain, then request rev signoff — only rev's record makes it an asserted DUT bug | rca drafts FL; rev must sign before "DUT bug" is claimed anywhere |

Escalation: if no row resolves it, the failure itself is evidence of a
`SPEC_ISSUE` (two defensible readings) — take it to rev arbitration.

Every path ends in a failure record (`schema/failure_record.md`) with a
regression guard. An assertion failure you debugged but did not bank will be
debugged again.
