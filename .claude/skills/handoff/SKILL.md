---
name: handoff
description: Take over the project — one command for current version, status head, latest log block, testplan/feature-matrix stats and open bugs. Run at session start or when resuming work.
---

<!-- Project-owned since framework 0.8.0 (upstream retired .claude/skills/;
     kept here as a local asset — we maintain it). Renamed handover→handoff
     to match the make target. Consumer: session start. -->

# Handoff flow

1. Run `make handoff` (= `python3 scripts/docs.py --handoff`) and read the
   whole output.
2. Run `make next` for the mechanically derived action list (bug
   progression / pending dispatch / milestone gaps). Only do targeted
   reading for the items it names: grep to locate the exact
   testplan/bugs/spec rows, then Read locally.
3. Forbidden: bulk-reading `doc/archive/*`, the details of already-✅
   scenarios, or the full spec (take the outline with
   `grep -n "^#" doc/spec.md`, then read by section).
4. If the take-over state conflicts with the user's task, the user's task
   wins — but state the conflict first.
