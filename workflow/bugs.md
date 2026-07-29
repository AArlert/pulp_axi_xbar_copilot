# Bugs: taxonomy, record contract, and dispatch

<!-- Upstream file — local edits are your own to maintain. -->

## The five classes

Every failure record's `## taxonomy` section names exactly one. The class
determines the next action and where the lesson is banked.

Registration is unconditional: any anomaly matching one of the five classes
below gets a `doc/bugs.md` row, regardless of whether it blocked evidence,
was worked around and fixed within the same card, or looked like "just" a
tool/implementation quirk (a `TOOL_ENV` hit mid-implementation, before any
scenario ever ran, still counts). The point of a taxonomy is that the next
person can grep it — a class that was resolved inline and never logged
defeats that purpose as surely as one that was ignored.

**Diagnose in cost order** — cheapest hypothesis first, most expensive
accusation last:

```
TOOL_ENV → TB_BUG / CONSTRAINT_BUG → SPEC_ISSUE → DUT_BUG
```

Blaming the DUT costs the most (a vendored DUT means a patch and possibly an
upstream report; any DUT means it requires rev signoff), so it is earned by
eliminating everything else — not reached by default.

| Class | You are here if… (decision cues, check in order) | Typical next step |
|---|---|---|
| `TOOL_ENV` | Result changes with seed/machine/build but not stimulus; clean lint yet compile-time weirdness; matches a known tool defect (e.g. VCS O-2018 traits — see `scripts/make/vcs-2018.mk` header); stale build artifacts, wrong seed recorded, evidence older than the code it certifies | Clean rebuild + minimal repro; check the project's known-issues list (`P-xxx` patches, TOOL_ENV FLs); record so the next person greps it instead of rediscovering it |
| `TB_BUG` | Driver violates protocol timing (e.g. valid waits on ready); monitor samples the wrong edge; scoreboard's expected value derived wrongly — or derived **from the RTL instead of the spec** | Fix TB → rerun this scenario **and** spot-check neighboring scenarios that share the component |
| `CONSTRAINT_BUG` | Random stimulus produced a protocol-illegal combination; or constraints are so tight the target scenario is unreachable | Fix constraints → **re-examine historical PASSes** of scenarios using the same constraints: were they green only because the stimulus never reached the hard case? |
| `SPEC_ISSUE` | spec.md contradicts upstream documentation, or does not define the behavior at all; DUT and TB each defensible under a different reading | Escalate to rev arbitration → spec change record + re-pin → sync testplan/affected checkers. Never "interpret locally" and move on |
| `DUT_BUG` | Waveform shows DUT output violating an explicit spec clause; reproducible with an independent stimulus path (e.g. upstream smoke TB) | Requires rev signoff to assert. Then: vendored DUT → `P-xxx` patch + optional upstream report (see `doc/VENDOR.md`); own RTL → bug to the design side. Always ends with a regression guard |

**Why `CONSTRAINT_BUG` is its own class.** It could be filed under
`TB_BUG`, but its follow-up is unique and expensive to forget: a constraint
bug **invalidates history**. Every past green run that shared the
constraint may have been vacuously green. No other class forces that
retroactive audit, so the taxonomy keeps it visible.

**Mapping to bugs.md.** The summary row's `suspect` column stays coarse
(`TB / DUT / spec`) for scanability; the taxonomy class lives in the detail
page. Terminal-state correspondence: `TB_BUG` row state ↔ TB_BUG/
CONSTRAINT_BUG classes; `SPEC_CHANGED` ↔ SPEC_ISSUE; `CLOSED` ↔ DUT_BUG
(fixed) or TOOL_ENV (worked around); `WONTFIX` ↔ any class where the
cost/benefit says stop — the record still needs rca + guard-or-rationale.

## The failure record

A failure record (FL) is the project's medical chart for one defect: what
was observed, where the first anomaly is, what class of failure it was, how
it was fixed, how it was re-verified, and what now guards against its
return. Future debugging greps `doc/bugs/` before analyzing from scratch.
Escape literal `|` in cells as `\|` — an unescaped one shifts every later
column (docs-check fails the row).

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
   - `suspect` ∈ `TB / DUT / spec`. `min_repro` must contain `TEST=` and
     `SEED=`. `fix_commit` is any *traceable* fix reference: `<sha>` /
     `<repo>@<sha>` / `env: <change>` (environment fixes produce no local
     commit). `CLOSED` requires `verify_evidence` to reference an evidence
     record, and the re-runner must not be the fixer (core invariant #3).
2. **Detail page** `doc/bugs/<BUG-ID>.md` — required as soon as the
   debugging story exceeds one line; the primary carrier, the row is the
   index (3000-character table cells proved unreadable once). Fixed `##`
   sections; a checker validates presence + non-emptiness when
   `fl_schema_enforce` is true in `iverif.json` (new repos: on):

```markdown
# BUG-0007 — write responses reordered under back-pressure

## symptom
One-paragraph observable behavior, with the failing check's message.

## first_anomaly
signal: dut.i_rsp_fifo.rsp_valid
time: 12450ns
how_found: xdebug trace from the scoreboard mismatch backwards
(The earliest point where reality diverges from spec — the heart of the
chart. Locate with xdebug; reference waveform time, not vibes.)

## taxonomy
TB_BUG            <- one of the five classes above

## rca
Causal chain from first_anomaly to symptom, ≤5 links (see RCA template
below).

## fix
commit: <sha | repo@sha | env: change>
what: one sentence.

## rerun
Evidence records proving the fix: original failing TEST+SEED now passing,
plus neighboring scenarios re-checked. Non-sim criteria (lint/compile/
tool output) close via
`make evidence BUG=<ID> CMD='<re-verify cmd>' EXPECT='<signature>'`.

## regression_guard
type: sva | covergroup | directed_test | script | checklist
paths: tb/sva/*.sv         <- binding globs, machine-matched (make guards)
ref: tb/sva/per_id_order_check.sv
note: what future regression this blocks.
(Consumed mechanically by `make guards FILES=...` at card assembly and
signoff; no `paths:`, no injection. `paths:` = the note's *scope*, not
`ref:`'s location — a constraint is usually wider than its birth file. A
checklist guard is a mechanization TODO: note what script/SVA it should
become, or why it cannot.)

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
BUG=<ID> TEST=... SEED=...` writes the re-verification evidence and flips
the status itself. `SPEC_CHANGED` requires a rev arbitration record and
triggers the spec change flow (change-record entry + re-pin). With a
vendored DUT, confirmed DUT bugs are recorded, worked around via a `P-xxx`
patch (see `doc/VENDOR.md`), optionally reported upstream — the vendored
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

- **Walk backwards, not forwards.** Start from the failing check and trace
  toward the first anomaly (`xdebug` traces drivers/loads across the
  hierarchy; `xloc` gives stable short ids for log lines). Forward
  simulation-reading finds where things *look* wrong; backward tracing
  finds where they *went* wrong.
- **First anomaly beats first symptom.** The scoreboard mismatch at
  12450ns may originate at 3200ns. The chart records 3200ns.
- **≤5 links.** If the chain needs more, you have skipped a hypothesis test
  somewhere — each link should be verifiable in the waveform or the code.
- **The guard is the deliverable.** rca without a regression guard is a
  story; with one, it is banked engineering.
- **Search the chart archive first.** `grep -il "<symptom keyword>"
  doc/bugs/` — the `## similar` section exists so the third occurrence of a
  failure class takes minutes, not hours.

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

Escalation: if no row resolves it, the failure itself is evidence of a
`SPEC_ISSUE` (two defensible readings) — take it to rev arbitration.

Every path ends in a failure record (above) with a regression guard. An
assertion failure that was debugged but not banked will be debugged again.

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
