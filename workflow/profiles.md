# Profiles: `learning` vs `copilot`

One framework, two operating modes. The profile is declared once in the
project's `iverif.json` (`"profile": "learning" | "copilot"`) and the kernel
branches internally — there are no forked scripts and no forked doc formats.
Evidence produced by either profile is schema-identical, so a learning repo
and its agent twin can be compared claim by claim.

## Contract

| | `learning` | `copilot` |
|---|---|---|
| Who writes RTL/TB code | the human (main session may scaffold compilable skeletons: signatures + TODOs only) | agents (de/dv or coder) |
| Agent set | `rev` only | orch (main session) + arch / de / dv / rev |
| Agent definitions | `.claude/agents/rev.md` rendered from `agents/rev.learning.md` | `.claude/agents/{arch,de,dv,rev}.md` rendered from `agents/*.copilot.md` — regenerated on every `fwsync --pull`; project-specific rules go in CLAUDE.md §Project specifics, never in these files |
| Skills (`.claude/skills/`, hash-pinned) | handover / evidence / closeout | the same three + `dispatch` (the orch card manual: model tiers, must-include/forbidden matrix, isolation self-check) |
| `rev` role | reviewer **and mentor**: written reviews with principles and direction, never implementations, never code edits | reviewer/arbiter: gate reviews, bug adjudication, milestone signoff |
| Who produces evidence | the human runs `make evidence` | runner/dv agents run `make evidence` |
| `--next` wording | addresses the human ("write...", "run...", "request a review of...") | addresses orch ("dispatch a de card...", "dispatch rev...") |
| Guard set (`docs-check`) | core checks only (see below) | full check set |
| Required files | no `doc/design-prompt/` | `doc/design-prompt/` required |
| Instance isolation | degraded to a thinking checklist (below) | hard rule: DE/DV separate instances, closer ≠ fixer, DV never reads DE reasoning |

Shared by both profiles, non-negotiable:

- The four core invariants (no sim log no ✅; replay command on line 1;
  closer ≠ fixer; spec pinned).
- Record schemas (`schema/`), failure taxonomy (`taxonomy/`), decision tables
  (`dispatch/`), six questions and signoff rubric (`signoff/`).
- The rolling-memory system: `doc/status.jsonl` + `doc/log.md` +
  `doc/testplan.md`, archives under `doc/archive/`.

## Learning-profile guard set

The full copilot check set (~20 FAIL branches) overwhelms a part-time human
learner. The learning profile keeps the checks that protect evidence
integrity and drops the ones that only protect agent pipelines:

Kept (hard FAIL):
1. A ✅ scenario must reference an existing evidence file whose line 1 is a
   replay command.
2. A CLOSED bug must carry re-verification evidence.
3. `spec.md` content must match its pinned sha256.
4. Rolling-file limits (status/log/bugs) — the token discipline that keeps
   `make handover` cheap.
5. Version sync between `version.json`, `status.jsonl`, and `log.md`.
6. Junk-file hygiene (`git ls-files` vs swap/backup patterns).

Dropped in learning (copilot-only): design-prompt required-file checks and
anything that polices inter-agent handoffs.

## The thinking checklist (learning profile)

In the copilot line, instance isolation exists to cut common-mode errors
between agents. A single human cannot be two instances — but the underlying
failure mode (checker and design agreeing because both looked at the same
wrong thing) applies to one person too. The checklist replaces the rule:

- Derive expected values from `spec.md`, **never** from the RTL you are
  testing. If the spec is silent, that is a spec issue to log — not a license
  to copy the RTL's behavior into the checker.
- Before closing your own bug, re-run the original failing seed **plus** one
  neighboring scenario; write the re-verification evidence before touching
  the status column (the script does the column anyway).
- When a test passes on the first try, ask what would have made it fail.
  If nothing plausibly could, the check is decorative — tighten it.
- Write the review request to `rev` as if the reviewer knows nothing you did
  not write down. If the request needs your chat history to make sense, the
  evidence chain has a gap.

## Mapping to the original design doc

The design doc (`icverifagentsframework.md`) names five copilot agents:
planner / coder / runner / rca / rev. The battle-tested implementation in
ppa-lite-copilot uses different seams. The canon adopts the implemented set
and records the mapping:

| Design-doc role | Canonical implementation |
|---|---|
| planner | orch (main session) + `make next` (mechanical derivation — most of "planning" turned out to be derivable from testplan state) |
| coder | arch (design prompts) + de (RTL) + dv (TB) |
| runner | the mechanical layer itself: `make run` / `make evidence` / `regress.py` (no LLM needed to run registered commands) |
| rca | dv + `dispatch/` decision tables today; a dedicated rca agent is deferred until the same bug class recurs (see deferred.md) |
| rev | rev (unchanged — the only role with signoff authority) |

Agents never talk to each other directly; every handoff goes through evidence
files. That rule is what makes the whole flow replayable and auditable.
