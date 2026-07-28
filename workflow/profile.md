# Profile contract: copilot

<!-- Canonical: iverif-workflow/loop/profile.copilot.md — pinned snapshot.
     Axioms: independence. Consumer: orch at session start; fwsync
     selects it as workflow/profile.md. -->

Agents write the code. orch (the main session) dispatches cards to
arch / de / dv / rev (`.claude/agents/`, regenerated on every pull —
project-specific rules go in CLAUDE.md, never in those files). The dispatch
skill (`.claude/skills/dispatch/`) is the card manual: model tiers,
must-include/forbidden matrix, isolation self-check. `--next` speaks to orch
("dispatch a … card"), deriving the deliverable-owning role from the
`delivery` config.

## Non-negotiable (both profiles)

- The four core invariants: no sim log no ✅ · replay command on line 1 ·
  closer ≠ fixer · spec pinned.
- Record schemas (`workflow/` + `workflow/fail/`), failure taxonomy, dispatch tables,
  six questions, signoff rubric.
- Rolling memory: `doc/status.jsonl` + `doc/log.md` + `doc/testplan.md`,
  archives under `doc/archive/`.

## Instance isolation (hard rules)

- DE and DV on separate instances; never reuse an instance across roles on
  the same module; arch and rev separate.
- DV derives expectations only from the pinned spec and never receives DE
  reasoning; rev reads primary material itself — no verbal conclusions.
- Closer ≠ fixer, enforced mechanically by `make evidence BUG=`.
- Design prompts (`doc/design-prompt/`, one per module) pass the rev gate
  before any de/dv card. Full docs-check set is on.

## Handoffs are records, not conversation

A side channel that "only carries context" is how DV's expectations drift
from spec-derived to implementation-agreed — the common-mode failure the
role split exists to prevent (relaxation proposed by external review
2026-07-26; declined). The cost — two roles may dig the same waveform — is
answered by the archive: dispatch Q1 greps `doc/bugs/` before fresh
analysis, and an undocumented first dig is a retention failure (six
questions Q6). Fix the record, not the firewall.
