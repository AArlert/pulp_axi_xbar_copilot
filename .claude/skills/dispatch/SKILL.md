---
name: dispatch
description: Dispatch-card assembly (copilot profile, orch only) — grade the card (L0–L3), assemble inputs per the fixed card templates, pass the isolation self-check. Run before every subagent dispatch.
---

<!-- Project-owned. Consumer: orch (the main session), before every card.
     This file IS orch's operative contract: upstream 0.8.0 shipped one as
     .claude/agents/orch.md, but that path only ever reaches a *spawned*
     subagent's prompt — the main session sees the frontmatter description
     and nothing else, so 87 lines addressed to "you, the main session"
     were delivered to everyone except it. We deleted that file and merged
     its operative content here (loaded at the moment of use) plus the
     brief always-on version in CLAUDE.md §0. See doc/fw-feedback.md
     FB-28. -->

# Dispatch flow (orch only)

## 1. Grade the card (L0–L3), then the model tier follows

**The grade table is in `CLAUDE.md` (派卡定级) — read it there, never copy it
here.** 0.8.0 moved it into CLAUDE.md and `scripts/tests/test_docs.py`
enforces its presence; a second copy in this file is exactly the drift the
move was meant to end.

Grade by the heaviest surface the card touches; in doubt, grade up. Grades
tune the **chain and model tier only** — taxonomy registration and evidence
gates stay unconditional at every grade. When a card straddles two levels
(a "doc fix" that touches a register definition, a "coverage tweak" that
needs a new checker), escalate rather than downgrade.

## 2. Assemble the card (only listed inputs — the common-mode firewall)

`make next` first for the mechanically derived action list, then build the
card by type:

| Card type | Must include | Must NOT include |
| --- | --- | --- |
| arch design input | spec sections (or the new-need description), feature-matrix scope, design-prompt README/conventions path | orch's preconceptions about the implementation |
| arch spec proposal | the ambiguity's BUG id or description, sections involved | any party's preferred ruling |
| arch spec-gap sweep | the exploration frontier from `make next` pasted verbatim, spec section list | orch's own scenario ideas |
| DE new feature | `doc/design-prompt/<module>.md` path (**must have passed the rev gate**), spec sections, feature-matrix ids, interface file paths | DV checker code/reasoning, rejected arch drafts |
| DE fix | bugs.md row id (symptom / min repro / spec basis), spec sections, relevant rtl paths | DV's expected-value derivation, waveform-analysis reasoning |
| DV scenario | testplan row id, spec sections, RTL module ports (header only, not the body), the designated register/parameter defs file | DE's implementation approach, RTL internals, design-prompts |
| DV re-verification | bugs.md row id, recorded TEST+SEED, regression scope to carry | DE's fix reasoning (fix commit id only) |
| rev gate/review/arbitration/signoff | the review scope list (files/rows), the criteria source (spec sections / workflow/review/) | any party's verbal conclusions (rev reads the primary material itself) |

## 3. Pre-dispatch self-check (every line)

- [ ] Fresh instance; no instance reuse across roles on the same module;
      arch and rev on separate instances.
- [ ] The card contains only file paths, section numbers, row ids — no
      other instance's reasoning.
- [ ] DE new-feature cards only after the design-prompt passed the rev gate
      (behavior-leak check).
- [ ] Bug dispatches only after the bugs.md row exists (no verbal
      dispatch).
- [ ] **rev cards carry a scope list, never a conclusion.** rev reads the
      primary material itself (files, logs, diffs) — a card that hands rev
      someone else's verdict to ratify is malformed.
- [ ] **closer ≠ fixer routing decided here, by you.** The fix card and the
      closing card go out as *two separate dispatches, never to the same
      executor*. No script enforces this: same git author / same VM is not
      a reliable signal either way, and a check like that would look like a
      gate while catching nobody. What the machine *can* verify is that the
      closing card carries its own independent re-run evidence; whether the
      hands were independent is yours to track at dispatch time.
- [ ] The card states its acceptance criteria (rev gate passed /
      compile+lint clean / scenario PASS + evidence / review record path)
      **and its grade** (L0–L3; in doubt, graded up).
- [ ] `make guards FILES="<the card's file list>"` run; every matched
      guard block pasted verbatim (registered fact, no reasoning).
      Above ~6 hits split **hard** (paths match files this card edits)
      from **context** (boundary hits — help, not noise); both verbatim.
      **Exception** — when the card's criteria source itself orders the
      dispatchee to run the same query (signoff cards: rubric #5), paste
      no bodies: give the deterministic FILES list + the command that
      computed it + the hit index lines + a count self-check ("your
      count/id set differs → stop and report"). The dispatchee executing
      and proving it beats relaying a snapshot that can go stale.

## 3b. Why the firewall is worth its cost (read once, then it's obvious)

A side channel that "only carries context" is exactly how DV's expectations
drift from *spec-derived* to *implementation-agreed* — the common-mode
failure the role split exists to prevent. So when two roles need the same
background, that need is **the price of the firewall, not a bug in it**:
point them at the same archived record (`doc/bugs/`, `doc/log.md`,
`doc/review/`) instead of relaying a summary between them.

Corollary worth internalizing: when one role digs out context and the next
has to redo the dig from scratch, that is a **retention failure, not wasted
efficiency**. The fix is to write the finding where the next card can find
it — never to widen the firewall so reasoning can pass through informally.

## 4. Collection check

- Accept against the role file's fixed delivery-report format; missing
  items go back for completion.
- Evidence counts only if generated by `make evidence` (line 1 replay
  command + generation stamp). Delivery/verification status is
  script-computed (`make next`) — orch maintains no status cells.
- Status cells (testplan/bugs) are backfilled by evidence.py; run
  `make check` before closing the card.
- Grade vs reality, every card: did the chain weight match the work? A
  mismatch either way (L0 work dragged through an L2 chain, or an "L0"
  that touched RTL) is framework feedback — record it. Subagents cannot
  see chain weight; this per-card line is the only observer.
