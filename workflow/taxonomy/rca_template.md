# RCA template

Fill the `## rca` section of a failure record with this shape. Keep it
short; the value is in the chain, not the prose.

```
observed:   <the failing check + message, one line>
anomaly:    <first_anomaly restated: signal, time, what it should have been>
chain:      <anomaly> → <link> → <link> → <observed>     (≤5 links)
class:      <one of the five taxonomy classes, with the cue that decided it>
guard:      <if this exact defect were re-introduced tomorrow, which check
             turns red FIRST? If the answer is "the same painful debug",
             the record is not done — add the guard.>
```

## Working rules

- **Walk backwards, not forwards.** Start from the failing check and trace
  toward the first anomaly (`xdebug` traces drivers/loads across the
  hierarchy; `xloc` gives stable short ids for log lines). Forward
  simulation-reading finds where things *look* wrong; backward tracing finds
  where they *went* wrong.
- **First anomaly beats first symptom.** The scoreboard mismatch at
  12450ns may originate at 3200ns. The chart records 3200ns.
- **≤5 links.** If the chain needs more, you have skipped a hypothesis test
  somewhere — each link should be verifiable in the waveform or the code.
- **The guard is the deliverable.** rca without a regression guard is a
  story; with one, it is banked engineering. Guard types in
  `schema/failure_record.md`.
- **Search the chart archive first.** `grep -il "<symptom keyword>"
  doc/bugs/` — the `## similar` section exists so the third occurrence of a
  failure class takes minutes, not hours.
