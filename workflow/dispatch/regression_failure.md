# Dispatch: regression failure

`make regress` reports FAILs that were green before. Order of questions:

| # | Question | Finding | Learning-line action | Copilot-line action |
|---|---|---|---|---|
| 1 | What changed since the last green run? (`git log --oneline <last-green>..HEAD`, diff the touched areas) | recent-change suspect | Suspect your latest edits first — re-read the diff before opening waves | orch pulls the diff into the dv triage card |
| 2 | Does the same seed reproduce after a clean rebuild? | no → `TOOL_ENV` (or a real race) | Rebuild, rerun same seed ×3; if flaky, treat as a race candidate, not noise — file the FL anyway | orch reruns (`make run`, clean rebuild); flaky results are never silently retried into green |
| 3 | Are multiple cases failing together? | shared root | Cluster by symptom (same assertion? same component in the message?) — **one FL per root cause**, not per test | orch clusters by symptom before dispatch: one dv card per root cause; one FL, N affected tests listed |
| 4 | Single case, reproducible | normal triage | Continue in `dispatch/assertion_failure.md` from Q1 | same |

After the fix, the rerun set is **not** just the failing test:

```
rerun = failing case(s)
      + historical cases of the same taxonomy class (grep doc/bugs/)
      + every case the new/updated regression_guard covers
```

Then `make evidence BUG=<ID> ...` closes the record (non-fixer rule
applies), and the failing seed joins `sim/regress/regress.list` permanently.
