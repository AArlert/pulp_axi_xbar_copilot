# Milestone signoff rubric

Signoff is not "the coverage number is high enough". It is the answer to:
**is the evidence sufficient to support the judgment that this milestone's
risks are retired?** Two halves: machine-checkable conditions (printed by
`docs.py --signoff`) and human spot checks (led by rev).

## Machine conditions (`make signoff-check`)

1. Every testplan scenario of this milestone is ✅, or carries a waiver with
   a rev record reference.
2. `make regress` summary for the full list is registered as evidence
   (100% PASS, includes every regression-guard case).
3. All bug rows are in terminal states (`CLOSED / TB_BUG / SPEC_CHANGED /
   WONTFIX`); every CLOSED row has re-verification evidence; every FL detail
   page has its required sections non-empty (when `fl_schema_enforce` on).

The tool prints each condition PASS/FAIL and, for FAILs, the offending ids.
It is read-only — it never edits state.

## Human spot checks (rev, recorded in the signoff file)

4. **Coverage closure ≠ risk closure.** Pick 2–3 well-hit bins and confirm
   in the waves/logs that they were hit by the *intended* scenario, not
   incidentally. Pick 1 waived hole and re-read the unreachability
   argument.
5. **Guard consumption + falsification.** `make guards FILES="<files this
   milestone touched>"` — every hit is review scope: confirm it was
   honored. Falsify at least one: re-introduce the original defect
   (locally, throwaway branch) and confirm the guard fires. A guard that
   has never been seen red is a hypothesis, not a guard.
6. **Spec debt is zero or accepted.** The open SPEC_ISSUE list is empty, or
   each entry has a written acceptance rationale.

## The signoff record

- File: `doc/evidence/v<version>/signoff-M<n>.md` — written by rev, and it
  is the thing `docs.py --next` checks for milestone completion.
- **Signoff ≠ review.** The signoff record *cites* the process reviews
  (`REV-xxx`) plus the spot-check results and states the verdict; it is
  never a copy of a review file (one adopter's M0 signoff once turned out
  byte-identical to its review — that is the failure mode).
- Contents: machine-condition printout (pasted), spot-check details with
  citations, residual-risk list, verdict.
