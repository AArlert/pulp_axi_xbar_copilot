---
name: closeout
description: Close a work cycle — bump the skeleton, fill semantics, pass the gates, commit. Run at the end of every substantive work cycle, before committing.
---

<!-- Project-owned since framework 0.8.0 (upstream retired .claude/skills/;
     kept here as a local asset — we maintain it). Consumer: end of every
     work cycle. -->

# Closeout flow (fixed order, no skipping)

1. **Evidence audit**: this cycle's scenario evidence must already be
   registered via `make evidence` (testplan/bugs backfilled by the script);
   fill gaps first. Milestone closeouts additionally need the human evidence
   trio + rev signoff — confirm with `make check MILESTONE=<n>` (which also
   enforces invariant 5: at least one `KILL` row tagged to that milestone).
2. **Bump**: `make bump` (milestone completion: `make bump minor=1`, then
   `git tag v0.M.P`). The script inserts TODO skeletons at the top of
   `doc/status.jsonl` / `doc/log.md` (date/version pre-filled).
3. **Fill the log block's four questions**: done / not done / next / how
   verified. Write for a reader who never saw this session.
4. **Fill the status.jsonl summary**: a one-line overview; details belong in
   the log block.
5. **Archive check**: `make archive` (self-skips when nothing overflows).
6. **Gates**: `make check` must pass (unfilled TODOs are blocked); fix until
   green — bypassing with `--no-verify` is forbidden. `make selftest` should
   also pass (60 tests; it is the only remaining machine check that the canon
   scripts still work on this repo's data — fw-check retired with fwsync in
   0.8.0).
7. **Commit**: conventional commits; code + evidence + docs in the same
   commit. `make commit` is add+commit only and never pushes.
8. **Push** per the project's git policy in `CLAUDE.md`. Report failures
   honestly (network/conflict/auth) — never silent-skip, never force-push;
   on conflict fetch+rebase or ask.
