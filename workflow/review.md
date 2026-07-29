# Review: the seven questions and the signoff rubric

<!-- Upstream file — local edits are your own to maintain. -->

## The seven review questions

Every rev review — of a component, a passing scenario, or a milestone —
answers these seven questions in writing. They are the framework's
definition of "this evidence can be trusted". A review that skips one is
incomplete.

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

7. **Kill coverage.** Which checkers have a KILL record? Falsifiability
   (Q2) asks whether one check *could* fail; this asks whether, at
   milestone granularity, every *class* of checker actually has. "No kill,
   no trust" is one of the five invariants: each checker class needs at
   least one instance of injected-defect → red → fixed → green, logged as
   a KILL row in `doc/bugs.md`. A checker that has never been proven
   capable of failing is not evidence, no matter how green it has been —
   `make check MILESTONE=<n>` is the machine backstop for this question,
   but the review still has to look at what it printed and judge whether
   the coverage of checker classes, not just of bins, is real.

**Output discipline.**

- Written record in `doc/review/REV-<seq>.md`, fixed structure:
  **scope list → per-item verdict (pass / issue + citation) → guidance
  (principles and direction, never implementations) → overall verdict**
  (pass / conditional pass with listed conditions / rejected with listed
  gaps).
- Verdicts cite sources: spec section, file path, evidence path. "Looks
  fine" is not a verdict.
- rev points at gaps; rev does not write code or prescribe fixes.

## Milestone signoff rubric

Signoff is not "the coverage number is high enough". It is the answer to:
**is the evidence sufficient to support the judgment that this milestone's
risks are retired?** Two halves: machine-checkable conditions (printed by
`make check MILESTONE=<n>`) and human spot checks (led by rev).

**Machine conditions (`make check MILESTONE=<n>`).**

1. Every testplan scenario of this milestone is ✅, or carries a waiver with
   a rev record reference.
2. `make regress` summary for the full list is registered as evidence
   (100% PASS, includes every regression-guard case).
3. All bug rows are in terminal states (`CLOSED / TB_BUG / SPEC_CHANGED /
   WONTFIX`) or unexpired `ACCEPTED@M<n>`; every CLOSED row has
   re-verification evidence; every FL detail page has its required
   sections non-empty (when `fl_schema_enforce` on).
4. At least one `KILL` row in `doc/bugs.md` is tagged to this milestone
   (invariant 5's machine backing). This is a minimum, not a per-checker
   census — there is no canonical registry of every checker class a
   milestone touched to enumerate against, so whether the KILL set is
   actually *complete* is human spot check 5, not this condition.

The tool prints each condition PASS/FAIL and, for FAILs, the offending ids.
It is read-only — it never edits state.

**Human spot checks (rev, recorded in the signoff file).**

5. **Coverage closure ≠ risk closure.** Pick 2–3 well-hit bins and confirm
   in the waves/logs that they were hit by the *intended* scenario, not
   incidentally. Pick 1 waived hole and re-read the unreachability
   argument. While here, judge whether the KILL set (condition 4) actually
   covers every checker class this milestone exercised — the tool only
   checked "at least one", not "enough".
6. **Guard consumption + falsification.** `make guards FILES="<files this
   milestone touched>"` — every hit is review scope: confirm it was
   honored. Falsify at least one: re-introduce the original defect
   (locally, throwaway branch) and confirm the guard fires. A guard that
   has never been seen red is a hypothesis, not a guard.
7. **Spec debt is zero or accepted.** The open SPEC_ISSUE list is empty, or
   each entry has a written acceptance rationale.
8. **Accepted debt is real debt.** Each `ACCEPTED@M<n>` row: the cited
   REV record states a *falsifiable* rationale (which fact, if refuted,
   voids the ruling). Carry-overs were re-arbitrated — never
   auto-extended — and say why the previous due date slipped.
9. **Chain audit answered.** Paste one `make check MILESTONE=<n>` run into
   the signoff record; give each gap class a disposition or a written
   acceptance. Dangling refs are fixed, never accepted. (Visibility, not
   a gate — the command prints the report so it cannot go unseen.)

**The signoff record.**

- File: `doc/evidence/v<version>/signoff-M<n>.md` — written by rev, and it
  is the thing `make next` checks for milestone completion.
- **Signoff ≠ review.** The signoff record *cites* the process reviews
  (`REV-xxx`) plus the spot-check results and states the verdict; it is
  never a copy of a review file (one adopter's M0 signoff once turned out
  byte-identical to its review — that is the failure mode).
- Contents: machine-condition printout (pasted), spot-check details with
  citations, residual-risk list, verdict.
