# Bugs: taxonomy, record contract, and dispatch

<!-- Upstream file — local edits are your own to maintain. -->

## The five classes

Every failure record's `## taxonomy` section names exactly one. The class
determines the next action and where the lesson is banked.

Registration is unconditional: any anomaly matching one of the five
classes gets a `doc/bugs.md` row, regardless of whether it blocked
evidence or was worked around within the same card. A class resolved
inline and never logged defeats the grep.

**Scope: this covers verification failures** — a red sim, a checker
mismatch, a tool blocking a run. Defects in the bookkeeping itself (stale
references, hand-copied numbers, format drift in docs/helper scripts)
take a lighter path (rationale + M4 data: doc/fw-feedback.md FB-39):

- **Fix-in-passing (default).** Fix in the current commit — no row, no
  card, no detail page, no rev; a commit-message mention is enough.
- **Register only if the fix turns recorded green red** (false evidence
  reference, a ✅/CLOSED that no longer stands, a bypassed gate): one
  `suspect=doc` row + one L0 card. The closer is the machine —
  `make check` + `make selftest` green ⇒ CLOSED; `min_repro`/
  `verify_evidence` take the `CMD:` form. No detail page unless the RCA
  is non-obvious; rev reviews these in batch at closeout. docs-check
  drops the detail-page and TEST=/SEED= requirements for `suspect=doc`.

**Diagnose in cost order** — cheapest hypothesis first, most expensive
accusation last:

```
TOOL_ENV → TB_BUG / CONSTRAINT_BUG → SPEC_ISSUE → DUT_BUG
```

Blaming the DUT costs the most (patch + upstream report; rev signoff
required), so it is earned by eliminating everything else.

| Class | You are here if… (decision cues, check in order) | Typical next step |
|---|---|---|
| `TOOL_ENV` | Result changes with seed/machine/build but not stimulus; clean lint yet compile-time weirdness; matches a known tool defect (e.g. VCS O-2018 traits — see `scripts/make/vcs-2018.mk` header); stale build artifacts, wrong seed recorded, evidence older than the code it certifies | Clean rebuild + minimal repro; check the project's known-issues list (`P-xxx` patches, TOOL_ENV FLs); record so the next person greps it instead of rediscovering it |
| `TB_BUG` | Driver violates protocol timing (e.g. valid waits on ready); monitor samples the wrong edge; scoreboard's expected value derived wrongly — or derived **from the RTL instead of the spec** | Fix TB → rerun this scenario **and** spot-check neighboring scenarios that share the component |
| `CONSTRAINT_BUG` | Random stimulus produced a protocol-illegal combination; or constraints are so tight the target scenario is unreachable | Fix constraints → **re-examine historical PASSes** of scenarios using the same constraints: were they green only because the stimulus never reached the hard case? |
| `SPEC_ISSUE` | spec.md contradicts upstream documentation, or does not define the behavior at all; DUT and TB each defensible under a different reading | Escalate to rev arbitration → spec change record + re-pin → sync testplan/affected checkers. Never "interpret locally" and move on |
| `DUT_BUG` | Waveform shows DUT output violating an explicit spec clause; reproducible with an independent stimulus path (e.g. upstream smoke TB) | Requires rev signoff to assert. Then: vendored DUT → `P-xxx` patch + optional upstream report (see `vendor/VENDOR.md`); own RTL → bug to the design side. Always ends with a regression guard |

**Why `CONSTRAINT_BUG` is its own class:** a constraint bug
**invalidates history** — every past green run sharing the constraint may
have been vacuously green. No other class forces that retroactive audit.

**Mapping to bugs.md.** The summary row's `suspect` column stays coarse
(`TB / DUT / spec / doc`); the taxonomy class lives in the detail page.
Terminal-state map: `TB_BUG` ↔ TB_BUG/CONSTRAINT_BUG; `SPEC_CHANGED` ↔
SPEC_ISSUE; `CLOSED` ↔ DUT_BUG (fixed) or TOOL_ENV (worked around);
`WONTFIX` ↔ cost/benefit stop (still needs rca + guard-or-rationale).

## The failure record

A failure record (FL) is the medical chart for one defect: symptom, first
anomaly, class, fix, re-verification, guard. Future debugging greps
`doc/bugs/` first. Escape literal `|` in cells as
`\|` (an unescaped one shifts every later column; docs-check fails the
row).

Two carriers, one record:

1. **Summary row** in `doc/bugs.md` — one line, scannable. Columns:
   `id | status | suspect | summary | min_repro | root_cause | fix_commit |
   verify_evidence`.
   - `status` ∈ `OPEN / FIXING / FIX_READY / VERIFYING / CLOSED / TB_BUG /
     SPEC_CHANGED / WONTFIX` (exact spelling; docs-check validates) — plus
     `ACCEPTED@M<n>`: analyzed, scheduled debt. The row must name a REV
     record; unexpired it passes signoff, due-or-overdue it blocks. Never
     terminal, never archived. (WONTFIX may not mean "later"; OPEN may not
     mean "decided".)
   - `suspect` ∈ `TB / DUT / spec / doc`. `min_repro` must contain `TEST=`
     and `SEED=` (`suspect=doc` rows: `CMD:` form instead). `fix_commit` is any *traceable* fix reference: `<sha>` /
     `<repo>@<sha>` / `env: <change>` (environment fixes produce no local
     commit). `CLOSED` requires `verify_evidence` to reference an evidence
     record, and the re-runner must not be the fixer (core invariant #3).
2. **Detail page** `doc/bugs/<BUG-ID>.md` — required once the story
   exceeds one line (`suspect=doc`: only if the RCA is non-obvious); the
   primary carrier, the row is the index. Fixed `##` sections, validated
   when `fl_schema_enforce` is true in `iverif.json`:

```markdown
# BUG-0007 — write responses reordered under back-pressure

## symptom
One-paragraph observable behavior, with the failing check's message.

## first_anomaly
signal: dut.i_rsp_fifo.rsp_valid
time: 12450ns
how_found: xdebug trace from the scoreboard mismatch backwards
(Earliest point reality diverges from spec; locate with xdebug, reference
waveform time, not vibes.)

## taxonomy
TB_BUG            <- one of the five classes above

## rca
Causal chain from first_anomaly to symptom, ≤5 links (see RCA template
below).

## fix
commit: <sha | repo@sha | env: change>
what: one sentence.

## rerun
Evidence proving the fix: the failing TEST+SEED now passing + neighbors
re-checked. Non-sim criteria close via
`make evidence BUG=<ID> CMD='<re-verify cmd>' EXPECT='<signature>'`.

## regression_guard
type: sva | covergroup | directed_test | script | checklist
paths: tb/sva/*.sv         <- binding globs, machine-matched (make guards)
ref: tb/sva/<checker>.sv
note: what future regression this blocks.
(Machine-consumed by `make guards`; no `paths:`, no injection. `paths:` =
the note's *scope*, wider than `ref:`'s birth file. A checklist guard is
a mechanization TODO: note what it should become, or why it cannot.)

## similar
FL ids of related historical failures, or "none searched-on: <keywords>".
```

**Lifecycle (who moves the status).**

```
OPEN → (fixer assigned) FIXING → FIX_READY → (re-run by non-fixer)
VERIFYING → CLOSED
   ↘ TB_BUG / SPEC_CHANGED / WONTFIX  (terminal reclassifications)
```

Anyone may open. The **fixer never sets CLOSED**: `make evidence
BUG=<ID> ...` writes the re-verification evidence and flips the status.
`SPEC_CHANGED` requires a rev arbitration record + spec change flow
(change-record entry + re-pin). Vendored DUT bugs: record, work around
via `P-xxx` patch (`vendor/VENDOR.md`), optionally report upstream — the
snapshot itself is read-only.

## RCA template

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

**Working rules.**

- **Walk backwards, not forwards.** From the failing check toward the
  first anomaly (`xdebug` traces drivers/loads; `xloc` gives stable log
  ids). Forward reading finds where things *look* wrong; backward tracing
  finds where they *went* wrong.
- **First anomaly beats first symptom.** The mismatch at 12450ns may
  originate at 3200ns; the chart records 3200ns.
- **≤5 links.** More means a skipped hypothesis test; each link must be
  verifiable in the waveform or the code.
- **The guard is the deliverable.** rca without a guard is a story; with
  one, it is banked engineering.
- **Search the chart archive first.** `grep -il "<keyword>" doc/bugs/` —
  so the third occurrence of a class takes minutes, not hours.

## Dispatch: assertion failure

An SVA assertion fired (or a checker flagged a violation). Answer the
questions **in order**; the first "yes/found" row decides. Do not skip to
blaming the DUT.

| # | Question | If yes → class | Action |
|---|---|---|---|
| 1 | Does the chart archive know this? `grep -il "<assertion name / symptom>" doc/bugs/` | (reuse prior FL) | Read the old record first; test its rca hypothesis against the current waveform before fresh analysis |
| 2 | Is the property's meaning actually what the spec clause says? (`xsva` renders the property's temporal structure; put it next to the spec sentence) | property bug → `TB_BUG` | Fix the property; the FL record must say *why* the old reading was wrong — that misreading is the lesson |
| 3 | Was the stimulus at trigger time protocol-legal? (check the driving interface's own assertions and the monitor trace around the failure) | illegal stimulus → `TB_BUG` (driver) or `CONSTRAINT_BUG` (randomization) | Fix driver/constraints; if CONSTRAINT_BUG, audit historical PASSes sharing the constraint (taxonomy rule) |
| 4 | Same seed, clean rebuild — does it still fire? | no → `TOOL_ENV` | Minimal repro; check `P-xxx` / TOOL_ENV FLs; record the environment cue |
| 5 | All above eliminated: locate `first_anomaly` in the waveform (`xdebug` backward trace from the assertion time) | `DUT_BUG` **candidate** | Write the FL with first_anomaly + chain, then request rev signoff — only rev's record makes it an asserted DUT bug |

Escalation: if no row resolves it, that is itself evidence of a
`SPEC_ISSUE` (two defensible readings) — rev arbitration. Every path ends
in a failure record with a regression guard: debugged-but-not-banked will
be debugged again.

## Dispatch: regression failure

`make regress` reports FAILs that were green before. Order of questions:

| # | Question | Finding | Action |
|---|---|---|---|
| 1 | What changed since the last green run? (`git log --oneline <last-green>..HEAD`, diff the touched areas) | recent-change suspect | Suspect the latest edits first — re-read the diff before opening waves |
| 2 | Does the same seed reproduce after a clean rebuild? | no → `TOOL_ENV` (or a real race) | Rebuild, rerun same seed ×3; if flaky, treat as a race candidate, not noise — file the FL anyway |
| 3 | Are multiple cases failing together? | shared root | Cluster by symptom (same assertion? same component in the message?) — **one FL per root cause**, not per test |
| 4 | Single case, reproducible | normal triage | Continue from Q1 of the assertion-failure dispatch above |

After the fix, the rerun set is **not** just the failing test:

```
rerun = failing case(s)
      + historical cases of the same taxonomy class (grep doc/bugs/)
      + every case the new/updated regression_guard covers
```

Then `make evidence BUG=<ID> ...` closes the record (non-fixer rule
applies), and the failing seed joins `sim/regress/regress.list`
permanently.

## Dispatch: coverage hole

A bin is empty (or a code-coverage gap persists) during closure. The first
question is never "how do I hit it" — it is "should a scenario for this
exist at all". `xcov` queries the VCS/Verdi coverage database with source
mapping; use it to name the hole precisely before dispatching.

| # | Question | Finding | Action |
|---|---|---|---|
| 1 | Does a testplan scenario cover this bin's situation? | no → **planning gap** | Do not write a test yet. Register the scenario row first (id + description + spec clause). A hole without a scenario is a testplan defect |
| 2 | Scenario registered but test not written? | normal backlog | Write it (normal micro-loop: code → run → evidence) |
| 3 | Test runs but the bin stays empty — do constraints exclude the combination? | `CONSTRAINT_BUG` | Loosen/fix; audit historical PASSes per taxonomy rule |
| 4 | Constraints legal but still unreachable — does the DUT structure make it impossible? (e.g. bins of a feature the current config excludes) | unreachable | Write the unreachability analysis into `doc/coverage-waivers.md` and request rev signoff. **Silent excludes are forbidden** — an exclude file entry without a waiver row fails review |
| 5 | None of the above | escalate | Take to rev with the xcov evidence attached |

Coverage closure ≠ risk closure: the signoff rubric (`workflow/review.md`)
additionally spot-checks *hit* bins to confirm they were hit by meaningful
scenarios, not by accident.
