# Testplan entry contract

`doc/testplan.md` is the scenario truth table: the single machine-readable
answer to "what is verified, what is not". `make handover` / `make next`
derive project state from it live — status is never cached anywhere else.

## Columns (en preset)

| id | milestone | description | config | status | evidence | repro |
|---|---|---|---|---|---|---|

- `id` — `M<n>-<TAG><seq>` (e.g. `M2-BP03`). Unique; feature-matrix rows
  reference these ids and docs-check fails on ghost references.
- `milestone` — `M0..Mn`. Milestone completion is derived by counting rows.
- `description` — the scenario in one sentence: stimulus + what must hold.
  Write it so a failure is conceivable; "runs without error" is not a
  scenario.
- `config` — DUT parameterization this scenario runs under (e.g.
  `dualport`, `baseline`). One scenario id per config point that matters.
- `status` — `🔲` planned / `⚠️` partial / `❌` failing / `✅` passed.
- `evidence`, `repro` — **script-owned columns.** evidence.py fills them;
  humans and agents leave them as `-`.

## Rules

1. **Register before you code.** The scenario row (id, milestone,
   description, config, status `🔲`) exists before the test is written.
   This is what makes coverage holes dispatchable: a hole with no scenario
   row is a *planning* gap, not a stimulus gap
   (`dispatch/coverage_hole.md`).
2. **✅ only via `make evidence`.** docs-check fails any ✅ row whose
   evidence file is missing or whose line 1 lacks `TEST=`/`SEED=`.
3. **❌ rows link a bug.** A scenario observed failing gets a BUG id in the
   description or a row note; it never silently returns to 🔲.
4. **Descriptions carry the spec.** Where a scenario enforces a specific
   spec clause, name it (`SPEC-4.2.1`) in the description; the evidence
   record's `spec_ref` header should match.
