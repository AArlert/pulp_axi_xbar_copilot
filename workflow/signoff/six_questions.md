# The six review questions

Every rev review — of a component, a passing scenario, or a milestone —
answers these six questions in writing. They are the framework's definition
of "this evidence can be trusted". A review that skips one is incomplete.

1. **Origin.** Which spec clause does this test / assertion / covergroup
   trace to? (Check the evidence record's `spec_ref` header and the
   testplan description. A test with no spec origin is not evidence of
   anything — it is the "sourceless test" this framework exists to
   prevent.)

2. **Falsifiability.** If the DUT did the opposite, would this check turn
   red? Name the concrete wrong behavior that would be caught. A checker
   that cannot fail is decoration. Watch for the classic tell: expected
   values derived from the RTL under test.

3. **Replayability.** Are the three replay ingredients present —
   command + seed on line 1 of the evidence record, and the record
   committed with the code it certifies? Could a stranger reproduce this
   run from the repo alone?

4. **Attribution.** If this ever FAILed: is the failure record complete
   (first_anomaly / taxonomy / rca / fix / rerun / regression_guard), and
   is the taxonomy class supported by evidence rather than assumption?
   Was the closer someone other than the fixer?

5. **Judgment.** Does the evidence at hand actually support the claimed
   status (✅ / CLOSED / milestone done)? If not, name exactly what is
   missing — the gap list is the review's actionable output.

6. **Retention.** Did the lesson land somewhere durable — a guard, a
   taxonomy note, a checklist line, a waiver with rationale? Or does it
   live only in a chat transcript that the next session will never read?

## Output discipline

- Written record in `doc/review/REV-<seq>.md`, fixed structure:
  **scope list → per-item verdict (pass / issue + citation) → guidance
  (principles and direction, never implementations) → overall verdict**
  (pass / conditional pass with listed conditions / rejected with listed
  gaps).
- Verdicts cite sources: spec section, file path, evidence path. "Looks
  fine" is not a verdict.
- rev points at gaps; rev does not write code or prescribe fixes. In the
  learning line this is what keeps the learning with the learner.
