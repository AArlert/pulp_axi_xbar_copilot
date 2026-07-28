# Execution discipline

<!-- Canonical: iverif-workflow/loop/discipline.md — pinned snapshot.
     Axioms: recording, pain-gating. Consumer: every role, before its
     first edit of a session. -->

Behavioral rules for whoever is holding the keyboard — the learning-line
engineer, orch, or any dispatched agent. They apply to every card, every
session, both profiles.

**Priority.** Above ordinary convenience: when a rule here conflicts with
"just get it done faster", the rule wins. Below the four core invariants
(workflow/constitution.md) and each role's isolation boundary: those are hard gates enforced
by scripts; this is how you behave *between* the gates, where no script is
watching. Read this before your first edit of a session.

Adapted from Andrej Karpathy's LLM-coding guidelines
([multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)),
fused with the pain this framework has already banked. The bias is caution
over speed; on a trivial task, use judgment.

## 1. Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State your assumptions explicitly. If uncertain, ask.
- If a spec clause has multiple readings, present them — never pick
  silently. Here a silent pick has a name and a home: it is a `SPEC_ISSUE`,
  it goes in `doc/bugs.md`, and rev arbitrates.
- The local form of this failure: *"the RTL does X, so X must be intended."*
  That is not an assumption you are allowed to make — expectations derive
  from the pinned spec, never from the thing under test.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what is confusing. Ask.

## 2. Simplicity first

**Minimum code that solves the stated problem. Nothing speculative.**

- No features beyond what the card asked for. No abstractions for
  single-use code. No configurability nobody requested. No error handling
  for impossible scenarios.
- If you wrote 200 lines and it could be 50, rewrite it. Ask: *would a
  senior engineer call this overcomplicated?*
- Prose follows the same rule: state the rule and its check, one line of
  why at most; the backstory belongs in the CHANGELOG, not the doc.
- The framework's own version of this rule is the deferred ledger — a
  mechanism ships when its trigger fires, not when it seems useful.
- **The one exception is a gate.** A check that refuses to pass without
  proof (`sva_enforce` fail-closed, the spec sha256 pin, FIX_READY
  requiring a fix commit) is not defensive over-engineering — it is the
  product. Never "simplify" a gate open, and never widen one to make your
  own card pass.

## 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting. Don't refactor
  what isn't broken. Match the existing style even where you'd choose
  differently.
- Remove imports/variables/functions that *your* change orphaned. Don't
  delete pre-existing dead code — mention it.
- "Mention it" is not a chat remark: if what you noticed matches a
  `workflow/fail/failure_taxonomy.md` class, it gets a `doc/bugs.md` row.
  Registration is unconditional.
- **The pinned snapshot is not surgically editable at all.** `scripts/`,
  `workflow/`, `.claude/skills/` and the rendered `.claude/agents/` come
  from the framework; a fix goes to the framework first, then comes back by
  `fwsync --pull`. `make fw-check` is watching.
- The test: every changed line traces directly to the card.

## 4. Goal-driven execution

**Define the success criterion first. Loop until it is met.**

- "Add validation" → "a test for the invalid inputs exists and passes".
- "Fix the bug" → "the recorded `min_repro` TEST+SEED re-runs clean and
  `make evidence` accepts the closure".
- "Close the coverage hole" → "those bins are hit in a registered evidence
  record".
- In this framework the criterion is rarely a matter of taste — it is a
  machine verdict. **If you cannot state your goal as a gate that passes,
  restate the goal.**
- For multi-step work, write the plan as step → verify pairs before
  starting:

```
1. [step] → verify: [the check that proves it]
2. [step] → verify: [the check that proves it]
```

Strong criteria let you loop on your own. Weak ones ("make it work") force
someone else to referee every iteration.

## 5. Small closed loops, then stop

*(framework-native — contributed by pulp_axi_xbar_copilot, 2026-07-27)*

Cut long work into the smallest chunk that reaches a clean stopping point by
itself: gates green, records written, committed. Then **stop and report** —
don't cascade into the next chunk unprompted. A card already in flight runs
to its own completion first; the rule bounds what you *start*, not what you
finish.

---

**These rules are working if:** diffs contain no unrequested lines, fewer
rewrites are needed for overcomplication, and clarifying questions arrive
before the implementation instead of after the review.
