---
name: evidence
description: Register simulation evidence — evidence.py mechanically extracts from the sim log and auto-backfills testplan/bugs. Run before any scenario goes ✅ or any bug goes CLOSED.
---

<!-- Canonical: iverif-workflow/harness/skills/evidence/SKILL.md — pinned snapshot.
     Axioms: independence, recording. Consumer: before any ✅ or CLOSED. -->

# Evidence registration (mechanical — hand-written evidence is forbidden)

1. Precondition: the simulation really ran (an environment where
   `command -v vcs` succeeds). FAIL logs are never evidence — set the
   scenario ❌/⚠️ and take suspected defects through `doc/bugs.md`
   (triage: `workflow/fail/*.md`).
2. Scenario evidence:
   `make evidence SCEN=<id> TEST=<t> SEED=<n> [SPEC_REF=SPEC-x.y]`
   — the script judges the log (UVM summary or VCS banner), extracts the
   summary + key check lines, writes `doc/evidence/v<ver>/<id>.log` (line 1
   = replay command), auto-backfills the testplan row (✅ / evidence /
   repro), then runs docs-check.
3. Bug re-verification closure:
   `make evidence BUG=<id> TEST=<t> SEED=<n>` (sets CLOSED + verify
   evidence; closer ≠ fixer).
4. If the script refuses (missing log / FAIL / row not found): handle the
   real situation. Never bypass the script by crafting files.
5. Replay and audit: `make replay SCEN=<id>` re-runs exactly what the
   record claims; `make chain SCEN=<id>` prints the full trace
   (spec → evidence → bugs → reviews).
6. Milestone-level evidence stays human-made: regression summary copied
   into the evidence dir, coverage summary excerpt, rev review records —
   checked by `make signoff-check`.
