---
name: closeout
description: Close a work cycle — bump the skeleton, fill semantics, pass the gates, commit. Run at the end of every substantive work cycle, before committing.
---

<!-- Canonical: iverif-workflow/skills/closeout/SKILL.md — pinned snapshot. -->

# Closeout flow (fixed order, no skipping)

1. **Evidence audit**: this cycle's scenario evidence must already be
   registered via `make evidence` (testplan/bugs backfilled by the script);
   fill gaps first. Milestone closeouts additionally need the human evidence
   trio + rev signoff — confirm with `make signoff-check`.
2. **Bump**: `make bump` (milestone completion: `make bump-minor`, then
   `git tag v0.M.P`). The script inserts TODO skeletons at the top of
   `doc/status.jsonl` / `doc/log.md` (date/version pre-filled).
3. **Fill the log block's four questions**: done / not done / next / how
   verified. Write for a reader who never saw this session.
4. **Fill the status.jsonl summary**: a one-line overview; details belong in
   the log block.
5. **Archive check**: `make docs-archive` (self-skips when nothing
   overflows).
6. **Gates**: `make docs-check` must pass (unfilled TODOs are blocked); fix
   until green — bypassing with `--no-verify` is forbidden. `make fw-check`
   should also be green (a red fw-check is a standing reminder to flow local
   fixes back to the framework).
7. **Commit**: conventional commits; code + evidence + docs in the same
   commit.
8. **Push** per the project's git policy in `CLAUDE.md`. Report failures
   honestly (network/conflict/auth) — never silent-skip, never force-push;
   on conflict fetch+rebase or ask.
