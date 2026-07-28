# Failure record contract

A failure record (FL) is the project's medical chart for one defect: what
was observed, where the first anomaly is, what class of failure it was, how
it was fixed, how it was re-verified, and what now guards against its
return. Future debugging greps `doc/bugs/` before analyzing from scratch.
Escape literal `|` in any table cell as `\|` — RTL or-expressions
otherwise shift every later column, and docs-check fails the row.

Two carriers, one record:

1. **Summary row** in `doc/bugs.md` — one line, scannable.
2. **Detail page** `doc/bugs/<BUG-ID>.md` — required as soon as the debugging
   story exceeds one line. The page is the primary carrier, the row is the
   index (3000-character table cells proved unreadable once).

## Summary row (doc/bugs.md)

Columns (en preset — zh preset in `config/presets/columns.zh.json`):

| id | status | suspect | summary | min_repro | root_cause | fix_commit | verify_evidence |
|---|---|---|---|---|---|---|---|

- `status` ∈ `OPEN / FIXING / FIX_READY / VERIFYING / CLOSED / TB_BUG /
  SPEC_CHANGED / WONTFIX` (exact spelling; docs-check validates).
- `suspect` ∈ `TB / DUT / spec` — the coarse triage guess. The precise
  taxonomy class lives in the detail page.
- `min_repro` must contain `TEST=` and `SEED=`.
- `CLOSED` requires `verify_evidence` to reference an evidence record, and
  the re-runner must not be the fixer (core invariant #3).

## Detail page sections (doc/bugs/<BUG-ID>.md)

Fixed `##` sections; a checker validates presence + non-emptiness when
`fl_schema_enforce` is true in `iverif.json` (new repos: on).

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
TB_BUG            <- one of the five classes in taxonomy/failure_taxonomy.md

## rca
Causal chain from first_anomaly to symptom, ≤5 links
(taxonomy/rca_template.md).

## fix
commit: <sha>
what: one sentence.

## rerun
Evidence records proving the fix: original failing TEST+SEED now passing,
plus neighboring scenarios re-checked.

## regression_guard
type: sva | covergroup | directed_test | script | checklist
paths: tb/sva/*.sv         <- binding globs, machine-matched (make guards)
ref: tb/sva/per_id_order_check.sv
note: what future regression this blocks.
(Guards are consumed mechanically — `make guards FILES=...` at card
assembly and at signoff; no `paths:`, no injection. `paths:` = the note's
*scope*, not `ref:`'s location — a constraint is usually wider than its
birth file. A checklist guard is a mechanization TODO: note what
script/SVA it should become, or why it cannot.)

## similar
FL ids of related historical failures, or "none searched-on: <keywords>".
```

## Lifecycle (who moves the status)

```
OPEN → (fixer assigned) FIXING → FIX_READY → (re-run by non-fixer)
VERIFYING → CLOSED
   ↘ TB_BUG / SPEC_CHANGED / WONTFIX  (terminal reclassifications)
```

- Anyone may open. The **fixer never sets CLOSED** — closing happens via
  `make evidence BUG=<ID> TEST=... SEED=...`, which writes the
  re-verification evidence and flips the status itself.
- `SPEC_CHANGED` requires a rev arbitration record and triggers the spec
  change flow (change-record entry + re-pin).
- In a learning repo with a vendored DUT, confirmed DUT bugs are recorded,
  worked around via a `P-xxx` patch (see `templates/VENDOR.md`), and
  optionally reported upstream — the vendored snapshot itself is read-only.
