#!/usr/bin/env python3
# Mechanical layer of the doc memory system: handover summary / structure
# guards / rolling archive / spec pinning / signoff & chain queries.
# Principle: mechanics to scripts, semantics to humans/agents. This script
# only counts, validates, and moves text — it never writes semantic content.
#
# Canonical home: iverif-workflow/kernel/docs.py. Project copies are
# hash-pinned; improve the framework, then `fwsync --pull`.
import argparse
import hashlib
import json
import re
import signal
import subprocess
import sys

from iverif_config import (BUG_DONE_STATES, BUG_STATES,
                           BUG_STATES_NEED_COMMIT, FL_CLASSES, FL_SECTIONS,
                           STATUS_EMOJIS, load_config)

# Output is routinely piped to head/grep (token discipline); restore default
# SIGPIPE behavior to avoid BrokenPipeError (POSIX only; absent on Windows).
if hasattr(signal, "SIGPIPE"):
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)

CFG = None  # set in main()

BLOCK_RE = re.compile(r"^## \[")
# Skeleton markers matched exactly (whole line / whole value) so prose that
# merely mentions "TODO" is not flagged. Both the current English skeleton and
# the legacy Chinese one are recognized.
LOG_TODO_RE = re.compile(r"^- TODO$|TODO \(one-line title\)|TODO（一句话标题）",
                         re.M)
BLOCK_VER_RE = re.compile(r"^## \[(\d+\.\d+\.\d+)\]")
SEMVER_RE = re.compile(r"^0\.(\d+)\.(\d+)$")
JUNK_RE = re.compile(r"(\.swp$|\.swo$|~$|\.orig$|(^|/)\.DS_Store$)")

ESCAPED_PIPE = "\x00"


def read_version():
    data = json.loads(CFG.version_json.read_text(encoding="utf-8"))
    return data["version"], data.get("milestone", "")


def split_log_blocks(text):
    """Return (head_text, [block_texts]); blocks start with '## ['."""
    lines = text.splitlines(keepends=True)
    head, blocks, cur = [], [], None
    for line in lines:
        if BLOCK_RE.match(line):
            if cur is not None:
                blocks.append(cur)
            cur = [line]
        elif cur is None:
            head.append(line)
        else:
            cur.append(line)
    if cur is not None:
        blocks.append(cur)
    return "".join(head), ["".join(b) for b in blocks]


def parse_table(path):
    """Parse the markdown tables in a file into [{header: cell}, ...]
    (skips header/separator rows, supports \\| escapes)."""
    rows, header = [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip().startswith("|"):
            header = None
            continue
        line = line.replace("\\|", ESCAPED_PIPE)
        cells = [c.strip().replace(ESCAPED_PIPE, "|")
                 for c in line.strip().strip("|").split("|")]
        if header is None:
            header = cells
            continue
        if all(set(c) <= set("-: ") for c in cells):
            continue
        rows.append(dict(zip(header, cells)))
    return rows


def row_cells(line):
    line = line.replace("\\|", ESCAPED_PIPE)
    return [c.strip().replace(ESCAPED_PIPE, "|")
            for c in line.strip().strip("|").split("|")]


def split_table_lines(text):
    """Split out the first markdown table by line:
    (pre-table text, 2 header lines, data-row lines, post-table text).
    Data rows keep their original text — used for archive moves."""
    head, header, rows, tail = [], [], [], []
    state = 0  # 0=before table, 1=inside, 2=after
    for line in text.splitlines(keepends=True):
        in_table = line.strip().startswith("|")
        if state == 0:
            (header if in_table else head).append(line)
            state = 1 if in_table else 0
        elif state == 1:
            if in_table:
                (header if len(header) < 2 else rows).append(line)
            else:
                state = 2
                tail.append(line)
        else:
            tail.append(line)
    return "".join(head), "".join(header), rows, "".join(tail)


def waiver_done(row):
    """A lint waiver row is settled when the conclusion says waived AND the
    rev-review column is filled (an unreviewed waiver does not count)."""
    cpfx = CFG.C["wv_conclusion_prefix"]
    rpfx = CFG.C["wv_review_prefix"]
    concl = next((v for k, v in row.items() if k.startswith(cpfx)), "")
    review = next((v for k, v in row.items() if k.startswith(rpfx)), "")
    # Accept either the en keyword or the legacy zh keyword in the cell.
    settled = ("waive" in concl.lower()) or ("豁免" in concl)
    return settled and bool(review.strip("-— "))


def archive_table_rows(src, dst, done_fn, keep, label):
    """Move settled data rows (done_fn true) from src's table to dst, keeping
    the newest `keep` settled rows. Unsettled rows never move; dst is
    newest-first. Returns whether anything moved."""
    head, header, rows, tail = split_table_lines(src.read_text(encoding="utf-8"))
    if not header:
        return False
    cols = row_cells(header.splitlines()[0])
    done_idx = [i for i, r in enumerate(rows)
                if done_fn(dict(zip(cols, row_cells(r))))]
    movable = set(done_idx[:-keep] if keep else done_idx)
    if not movable:
        return False
    old = [rows[i] for i in sorted(movable)]
    src.write_text(head + header
                   + "".join(r for i, r in enumerate(rows) if i not in movable)
                   + tail, encoding="utf-8")
    ahead, aheader, arows, atail = split_table_lines(
        dst.read_text(encoding="utf-8"))
    dst.write_text(ahead + aheader + "".join(old) + "".join(arows) + atail,
                   encoding="utf-8")
    print("%s: archived %d row(s)" % (label, len(old)))
    return True


def status_counts(rows):
    """Count statuses per milestone."""
    out = {}
    for r in rows:
        ms = r.get(CFG.C["tp_milestone"], "?")
        st = next((e for e in STATUS_EMOJIS
                   if e in r.get(CFG.C["tp_status"], "")), "?")
        if ms not in out:
            out[ms] = {e: 0 for e in STATUS_EMOJIS}
            out[ms]["?"] = 0
        out[ms][st] += 1
    return out


def linked_scenes(row):
    return row.get(CFG.C["fm_scenes"], "").replace(",", " ").split()


def testplan_pass_ids(tp_rows):
    return {r.get(CFG.C["tp_id"], "").strip() for r in tp_rows
            if "✅" in r.get(CFG.C["tp_status"], "")}


def fm_stats(fm_rows, tp_pass):
    """Feature-matrix derived stats: delivery computed live from files,
    verification computed live from testplan — neither is ever stored."""
    out = {}
    for r in fm_rows:
        ms = r.get(CFG.C["fm_milestone"], "?")
        d = out.setdefault(ms, {"total": 0, "deliv_total": 0, "deliv": 0,
                                "verif": 0})
        d["total"] += 1
        dv = CFG.delivered(r.get(CFG.C["fm_module"], ""))
        if dv is not None:
            d["deliv_total"] += 1
            d["deliv"] += dv
        scenes = linked_scenes(r)
        if scenes and any(s in tp_pass for s in scenes):
            d["verif"] += 1
    return out


def fmt_counts(counts):
    lines = []
    for ms in sorted(counts):
        c = counts[ms]
        total = sum(c.values())
        lines.append("  %s: ✅%d/%d  ❌%d ⚠️%d 🔲%d"
                     % (ms, c["✅"], total, c["❌"], c["⚠️"], c["🔲"]))
    return "\n".join(lines)


def check_evidence(cell, owner, errors):
    """Triple check on an evidence cell: path prefix, file exists, .log line 1
    contains the replay command (TEST + SEED)."""
    ev = cell.strip("` ")
    if not ev.startswith("doc/evidence/"):
        errors.append("%s evidence does not point into doc/evidence/" % owner)
        return
    p = CFG.root / ev
    if not p.exists():
        errors.append("%s evidence file missing: %s" % (owner, ev))
        return
    if ev.endswith(".log"):
        first = next((l for l in p.read_text(encoding="utf-8",
                                             errors="replace").splitlines()
                      if l.strip()), "")
        up = first.upper()
        if "TEST" not in up or "SEED" not in up:
            errors.append("%s evidence line 1 is not a replay command "
                          "(needs TEST and SEED): %s" % (owner, ev))


def check_dup_ids(rows, key, name, errors):
    seen = set()
    for r in rows:
        rid = r.get(key, "").strip()
        if rid and rid in seen:
            errors.append("%s has duplicate %s: %s" % (name, key, rid))
        seen.add(rid)


def count_mod_records(text):
    """Count data rows of the spec change-record table; None if absent."""
    heading = CFG.C["spec_change_heading"]
    lines = text.splitlines()
    start = next((i for i, l in enumerate(lines)
                  if l.strip().startswith(heading)), None)
    if start is None:
        return None
    n, seen_header = 0, False
    for l in lines[start + 1:]:
        s = l.strip()
        if s.startswith("#"):
            break
        if not s.startswith("|"):
            continue
        if not seen_header:
            seen_header = True
            continue
        if set(s.replace("|", "").strip()) <= set("-: "):
            continue
        n += 1
    return n


def check_fl_page(page, status, errors):
    """Failure-record detail page: fixed sections present and non-empty for
    terminal bugs; taxonomy value must be one of the five classes."""
    text = page.read_text(encoding="utf-8")
    sections = {}
    cur = None
    for line in text.splitlines():
        m = re.match(r"^## +(\w+)", line)
        if m:
            cur = m.group(1).lower()
            sections[cur] = []
        elif cur is not None:
            sections[cur].append(line)
    if status not in BUG_DONE_STATES:
        return  # in-progress pages may be partial
    for name in FL_SECTIONS:
        body = "\n".join(sections.get(name, [])).strip()
        if not body:
            errors.append("%s: section '## %s' missing or empty "
                          "(schema/failure_record.md)" % (page.name, name))
    tax = "\n".join(sections.get("taxonomy", [])).strip()
    if tax and not any(c in tax for c in FL_CLASSES):
        errors.append("%s: taxonomy %r is not one of %s"
                      % (page.name, tax.splitlines()[0],
                         "/".join(FL_CLASSES)))


def milestone_evidence_dirs(mnum):
    return list(CFG.doc.glob("evidence/v0.%s.*" % mnum))


def signoff_file_exists(mnum):
    # Fixed shape of the drifted-once bug: Path.glob() returns a generator,
    # and a generator object is always truthy — the inner any() must consume
    # it so the check reflects real matches.
    pattern = CFG.signoff_glob.format(m=mnum)
    return any(any(d.glob(pattern)) for d in milestone_evidence_dirs(mnum))


def cmd_handover():
    version, milestone = read_version()
    first = CFG.status.read_text(encoding="utf-8").splitlines()[0]
    st = json.loads(first)
    _, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    tp_rows = parse_table(CFG.testplan)
    fm_rows = parse_table(CFG.feature_matrix)

    print("== %s handover ==" % CFG.project)
    print("version: %s (%s)  profile: %s" % (version, milestone, CFG.profile))
    print("status[%s]: %s" % (st["date"], st["summary"]))
    print("\n-- log.md latest block --")
    print(blocks[0].rstrip() if blocks else "(empty)")
    print("\n-- testplan --")
    print(fmt_counts(status_counts(tp_rows)))
    todo = [r.get(CFG.C["tp_id"], "?") for r in tp_rows
            if "✅" not in r.get(CFG.C["tp_status"], "")]
    print("  open scenarios: %s" % (", ".join(todo) if todo else "(none)"))
    print("\n-- feature-matrix (delivery from files, verification from "
          "testplan — computed live, never stored) --")
    tp_pass = testplan_pass_ids(tp_rows)
    for ms, d in sorted(fm_stats(fm_rows, tp_pass).items()):
        print("  %s: delivered %d/%d  verified ✅%d/%d"
              % (ms, d["deliv"], d["deliv_total"], d["verif"], d["total"]))
    open_bugs = [r for r in parse_table(CFG.bugs)
                 if r.get(CFG.C["bug_status"], "").strip()
                 not in BUG_DONE_STATES]
    print("\n-- bugs --")
    if open_bugs:
        for r in open_bugs:
            print("  %s [%s] %s" % (r.get(CFG.C["bug_id"], "?"),
                                    r.get(CFG.C["bug_status"], "?"),
                                    r.get(CFG.C["bug_summary"], "")))
    else:
        print("  (no open bugs)")
    print("\nHint: `make next` for the mechanically derived action list; "
          "grep then read precisely; archives and ✅ rows are not read by "
          "default.")


def cmd_check():
    errors, warns = [], []

    for f in CFG.required_files:
        if not f.exists():
            errors.append("required file missing: %s"
                          % f.relative_to(CFG.root))
    if errors:
        return report(errors, warns)

    # version.json
    version, _ = read_version()
    if not SEMVER_RE.match(version):
        errors.append("version.json version does not match 0.M.P: %s"
                      % version)

    # status.jsonl
    lim = CFG.limits
    lines = [l for l in CFG.status.read_text(encoding="utf-8").splitlines()
             if l.strip()]
    for i, line in enumerate(lines, 1):
        try:
            rec = json.loads(line)
            for key in ("date", "version", "summary"):
                if key not in rec:
                    errors.append("status.jsonl line %d missing field %s"
                                  % (i, key))
        except json.JSONDecodeError:
            errors.append("status.jsonl line %d is not valid JSON" % i)
    # Re-parse line 1 defensively: if it is broken JSON the loop above has
    # already recorded the error — degrade instead of crashing.
    try:
        first = json.loads(lines[0]) if lines else None
    except json.JSONDecodeError:
        first = None
    if first is not None:
        if len(first.get("summary", "")) > lim["summary_max_chars"]:
            errors.append("status.jsonl line 1 summary exceeds %d chars — "
                          "trim it; details belong in log.md"
                          % lim["summary_max_chars"])
        if first.get("version") != version:
            errors.append("status.jsonl line 1 version %s != version.json %s "
                          "(bump first, then write status)"
                          % (first.get("version"), version))
        if first.get("summary", "").strip() == "TODO":
            errors.append("status.jsonl line 1 summary is still the TODO "
                          "skeleton — fill it during closeout")
    if len(lines) > lim["status_max_lines"]:
        errors.append("status.jsonl has %d lines > %d — run: "
                      "make docs-archive" % (len(lines),
                                             lim["status_max_lines"]))

    # log.md: block cap + first-block version sync with version.json
    # (blocks the "bumped but never wrote the handover block" failure).
    _, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    if len(blocks) > lim["log_max_blocks"]:
        errors.append("log.md has %d blocks > %d — run: make docs-archive"
                      % (len(blocks), lim["log_max_blocks"]))
    if blocks:
        m = BLOCK_VER_RE.match(blocks[0])
        if not m:
            errors.append("log.md first block header malformed "
                          "(expected '## [version] date title')")
        elif m.group(1) != version:
            errors.append("log.md first block version %s != version.json %s "
                          "(after bump, add a new block on top)"
                          % (m.group(1), version))
        if LOG_TODO_RE.search(blocks[0]):
            errors.append("log.md first block still contains the TODO "
                          "skeleton — answer the four questions (done / not "
                          "done / next / how verified)")

    # testplan evidence chain: ✅ requires a real evidence file (.log line 1
    # is a replay command) + a repro cell containing SEED.
    tp_rows = parse_table(CFG.testplan)
    check_dup_ids(tp_rows, CFG.C["tp_id"], "testplan", errors)
    for r in tp_rows:
        rid = r.get(CFG.C["tp_id"], "?")
        st = r.get(CFG.C["tp_status"], "")
        if not any(e in st for e in STATUS_EMOJIS):
            errors.append("testplan %s has an invalid status: %r" % (rid, st))
        if "✅" in st:
            check_evidence(r.get(CFG.C["tp_evidence"], ""),
                           "testplan %s" % rid, errors)
            if "SEED" not in r.get(CFG.C["tp_repro"], "").upper():
                errors.append("testplan %s is ✅ but its repro cell has no "
                              "SEED command" % rid)

    # feature-matrix: pure planning artifact (no status column); the guard
    # only checks reference integrity — every feature maps to >=1 scenario
    # and every referenced id must exist in the testplan.
    fm_rows = parse_table(CFG.feature_matrix)
    check_dup_ids(fm_rows, CFG.C["fm_id"], "feature-matrix", errors)
    tp_ids = {r.get(CFG.C["tp_id"], "").strip() for r in tp_rows}
    for r in fm_rows:
        fid = r.get(CFG.C["fm_id"], "?")
        scenes = linked_scenes(r)
        if not scenes:
            errors.append("feature-matrix %s has no linked scenarios (every "
                          "feature maps to >=1 testplan scenario)" % fid)
        for s in scenes:
            if s not in tp_ids:
                errors.append("feature-matrix %s links scenario %s which "
                              "does not exist in the testplan (ghost "
                              "reference)" % (fid, s))

    # bugs.md: legal states + fix-commit backfill + closure evidence.
    bug_rows = parse_table(CFG.bugs)
    abug_rows = parse_table(CFG.bugs_archive)
    check_dup_ids(bug_rows + abug_rows, CFG.C["bug_id"], "bugs.md(+archive)",
                  errors)
    done_bugs = [r for r in bug_rows
                 if r.get(CFG.C["bug_status"], "").strip() in BUG_DONE_STATES]
    if len(done_bugs) > lim["bug_done_max"]:
        errors.append("bugs.md has %d terminal rows > %d — run: "
                      "make docs-archive" % (len(done_bugs),
                                             lim["bug_done_max"]))
    for r in abug_rows:
        if r.get(CFG.C["bug_status"], "").strip() not in BUG_DONE_STATES:
            errors.append("bugs archive %s state %r is not terminal — active "
                          "bugs must move back to bugs.md"
                          % (r.get(CFG.C["bug_id"], "?"),
                             r.get(CFG.C["bug_status"], "")))
    for r in bug_rows:
        bid = r.get(CFG.C["bug_id"], "?")
        st = r.get(CFG.C["bug_status"], "").strip()
        if st not in BUG_STATES:
            errors.append("bugs.md %s state invalid: %r (legal: %s)"
                          % (bid, st, "/".join(BUG_STATES)))
        if st in BUG_STATES_NEED_COMMIT and \
                not r.get(CFG.C["bug_fix_commit"], "").strip("-` "):
            errors.append("bugs.md %s is %s but the fix-commit column is "
                          "empty" % (bid, st))
        if st == "CLOSED":
            check_evidence(r.get(CFG.C["bug_verify"], ""),
                           "bugs.md %s closure" % bid, errors)

    # Bug detail pages, both directions: referenced pages must exist; no
    # orphan pages without a table row (including archived rows). Terminal
    # bugs' pages must satisfy the failure-record schema when enforced.
    bugs_text = (CFG.bugs.read_text(encoding="utf-8")
                 + CFG.bugs_archive.read_text(encoding="utf-8"))
    for ref in set(re.findall(r"doc/bugs/([A-Za-z0-9_-]+)\.md", bugs_text)):
        if not (CFG.bug_pages / ("%s.md" % ref)).exists():
            errors.append("bugs.md references a missing detail page: "
                          "doc/bugs/%s.md" % ref)
    state_by_id = {}
    for r in bug_rows + abug_rows:
        state_by_id[r.get(CFG.C["bug_id"], "").strip()] = \
            r.get(CFG.C["bug_status"], "").strip()
    if CFG.bug_pages.is_dir():
        for f in sorted(CFG.bug_pages.glob("*.md")):
            if f.stem not in state_by_id:
                errors.append("doc/bugs/%s has no matching row in bugs.md"
                              "(+archive) (orphan detail page)" % f.name)
            elif CFG.fl_enforce:
                check_fl_page(f, state_by_id[f.stem], errors)

    # lint-waivers.md: unique ids (incl. archive) + settled-row cap + the
    # archive may not contain unreviewed rows.
    wv_rows = parse_table(CFG.waivers)
    awv_rows = parse_table(CFG.waivers_archive)
    check_dup_ids(wv_rows + awv_rows, CFG.C["wv_id"],
                  "lint-waivers.md(+archive)", errors)
    done_wv = [r for r in wv_rows if waiver_done(r)]
    if len(done_wv) > lim["waiver_done_max"]:
        errors.append("lint-waivers.md has %d settled rows > %d — run: "
                      "make docs-archive" % (len(done_wv),
                                             lim["waiver_done_max"]))
    for r in awv_rows:
        if not waiver_done(r):
            errors.append("waivers archive %s%s is not rev-approved — "
                          "unsettled waivers must move back"
                          % (CFG.C["wv_id"], r.get(CFG.C["wv_id"], "?")))

    # spec.md change guard (edits require a change-record entry + re-pin).
    spec_text = CFG.spec.read_text(encoding="utf-8")
    actual = hashlib.sha256(CFG.spec.read_bytes()).hexdigest()
    pinned = CFG.spec_sha.read_text(encoding="utf-8").strip()
    if actual != pinned:
        errors.append("doc/spec.md does not match its pinned sha256 — add a "
                      "change-record entry, then run: "
                      "python3 scripts/docs.py --pin-spec")
    if count_mod_records(spec_text) is None:
        errors.append("doc/spec.md lacks the '%s' table (the spec guard "
                      "depends on it)" % CFG.C["spec_change_heading"])

    # Junk-file hygiene: tracked editor swap/backup files fail the gate
    # (a tracked .Makefile.swp once shipped in a project repo).
    ls = subprocess.run(["git", "-C", str(CFG.root), "ls-files"],
                        capture_output=True, text=True)
    if ls.returncode == 0:
        for f in ls.stdout.splitlines():
            if JUNK_RE.search(f):
                errors.append("junk file tracked by git: %s (rm + gitignore)"
                              % f)
    else:
        warns.append("git ls-files unavailable — junk-file check skipped")

    return report(errors, warns)


def report(errors, warns):
    for w in warns:
        print("[warn] %s" % w)
    if errors:
        for e in errors:
            print("[FAIL] %s" % e)
        print("\ndocs-check failed: %d problem(s)" % len(errors))
        return 1
    print("docs-check passed")
    return 0


# --next action wording per profile: learning speaks to the human doing the
# work; copilot speaks to orch dispatching cards. The deliverable-owning
# role in the copilot wording (%(role)s) is derived from the project's own
# delivery config (tb/-rooted glob → DV-owned tb code, else DE-owned RTL;
# explicit delivery.owner wins) so vendored-DUT repos are correct with zero
# config (pulp_axi_xbar FB-8). `next_phrases_override` in iverif.json stays
# as the escape hatch for genuinely project-specific wording; overrides must
# keep the original phrase's %(...)s placeholders.
NEXT_PHRASES = {
    "learning": {
        "bug_open_spec": "%(bid)s OPEN (spec issue) → request rev arbitration",
        "bug_open": "%(bid)s OPEN → triage yourself (dispatch tables in "
                    "workflow/dispatch/); DUT suspicion needs rev signoff",
        "bug_fixing": "%(bid)s FIXING → fill root cause + fix commit, then "
                      "set FIX_READY",
        "bug_fix_ready": "%(bid)s FIX_READY → re-run the registered "
                         "TEST+SEED, then: make evidence BUG=%(bid)s "
                         "(closer ≠ fixer — have rev spot-check the closure)",
        "bug_verifying": "%(bid)s VERIFYING → finish closure via "
                         "make evidence BUG=%(bid)s",
        "tp_fail": "testplan %(rid)s ❌ → check your stimulus/checker first "
                   "(dispatch tables); still DUT-suspect → file in bugs.md",
        "undelivered": "%(mod)s not delivered (%(ids)s) → write it "
                       "(skeletons with signatures + TODOs are fine to ask "
                       "the main session for)",
        "unverified": "%(mod)s scenarios %(scenes)s not ✅ → write/run the "
                      "tests, then make evidence SCEN=<id>",
        "prompt_missing": None,  # design prompts do not exist in learning
    },
    "copilot": {
        "bug_open_spec": "%(bid)s OPEN (spec issue) → dispatch a rev "
                         "arbitration card",
        "bug_open": "%(bid)s OPEN → orch triages ownership: RTL suspect → "
                    "DE fix card / TB suspect → DV self-fix",
        "bug_fixing": "%(bid)s FIXING → DE delivers the fix + root cause; "
                      "orch commits it, backfills fix_commit, then sets "
                      "FIX_READY (DE has no commit hash at delivery time)",
        "bug_fix_ready": "%(bid)s FIX_READY → dispatch DV re-verify card "
                         "(re-run registered TEST+SEED; closer ≠ fixer)",
        "bug_verifying": "%(bid)s VERIFYING → DV closes via evidence.py "
                         "--bug %(bid)s after the re-run",
        "tp_fail": "testplan %(rid)s ❌ → DV checks stimulus/checker first; "
                   "still RTL-suspect → file in bugs.md",
        "undelivered": "%(mod)s deliverable missing (%(ids)s, design prompt "
                       "ready) → dispatch %(role)s card",
        "unverified": "%(mod)s scenarios %(scenes)s not ✅ → dispatch DV "
                      "scenario card",
        "prompt_missing": "%(mod)s lacks doc/design-prompt/%(mod)s.md → "
                          "dispatch arch card (rev gate before any "
                          "%(role)s card)",
    },
}


def cmd_next():
    """Mechanically derive next actions from the tables and guard state.
    Pure state-machine derivation — semantic decisions (ownership calls,
    card contents) stay with the human/orch."""
    version, milestone = read_version()
    P = dict(NEXT_PHRASES[CFG.profile])
    bad = sorted(set(CFG.next_phrases_override) - set(P))
    if bad:
        sys.exit("iverif.json next_phrases_override: unknown key(s) %s — "
                 "valid keys: %s (a typo here would otherwise silently "
                 "no-op)" % (", ".join(bad), ", ".join(sorted(P))))
    P.update(CFG.next_phrases_override)
    acts = []  # (priority, text): 0=guard debt, 1=bugs+milestone, 2=progress

    # 0) guard debt
    actual = hashlib.sha256(CFG.spec.read_bytes()).hexdigest()
    if actual != CFG.spec_sha.read_text(encoding="utf-8").strip():
        acts.append((0, "spec.md does not match pinned sha → add change "
                        "record, then python3 scripts/docs.py --pin-spec"))
    first_line = CFG.status.read_text(encoding="utf-8").splitlines()[0]
    if json.loads(first_line).get("summary", "").strip() == "TODO":
        acts.append((0, "status.jsonl line 1 is the TODO skeleton → finish "
                        "closeout"))
    _, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    if blocks and LOG_TODO_RE.search(blocks[0]):
        acts.append((0, "log.md first block has TODO skeleton → answer the "
                        "four questions"))

    # 1) bug flow
    for r in parse_table(CFG.bugs):
        bid = r.get(CFG.C["bug_id"], "?")
        st = r.get(CFG.C["bug_status"], "").strip()
        owner = r.get(CFG.C["bug_suspect"], "")
        ctx = {"bid": bid}
        if st == "OPEN":
            key = "bug_open_spec" if "spec" in owner.lower() else "bug_open"
            acts.append((1, P[key] % ctx))
        elif st == "FIXING":
            acts.append((1, P["bug_fixing"] % ctx))
        elif st == "FIX_READY":
            acts.append((1, P["bug_fix_ready"] % ctx))
        elif st == "VERIFYING":
            acts.append((1, P["bug_verifying"] % ctx))

    # 2) current-milestone progress, grouped by module/component
    tp_rows = parse_table(CFG.testplan)
    fm_rows = parse_table(CFG.feature_matrix)
    tp_pass = testplan_pass_ids(tp_rows)
    cur_tp = [r for r in tp_rows
              if r.get(CFG.C["tp_milestone"]) == milestone]
    cur_fm = [r for r in fm_rows
              if r.get(CFG.C["fm_milestone"]) == milestone]
    for r in cur_tp:
        if "❌" in r.get(CFG.C["tp_status"], ""):
            acts.append((1, P["tp_fail"] % {"rid": r.get(CFG.C["tp_id"])}))
    mods = {}
    for r in cur_fm:
        mods.setdefault(r.get(CFG.C["fm_module"], "?"), []).append(r)
    for mod, rows in mods.items():
        deliv = CFG.delivered(mod)  # None = no delivery notion (e.g. "(all)")
        ids = [r.get(CFG.C["fm_id"], "?") for r in rows]
        unverif = sorted({s for r in rows for s in linked_scenes(r)
                          if s not in tp_pass})
        ctx = {"mod": mod, "ids": " ".join(ids),
               "scenes": " ".join(unverif),
               "role": CFG.delivery_owner.upper()}
        prompt = CFG.doc / "design-prompt" / ("%s.md" % mod)
        if deliv is False and P["prompt_missing"] and not prompt.exists():
            acts.append((2, P["prompt_missing"] % ctx))
        elif deliv is False:
            acts.append((2, P["undelivered"] % ctx))
        elif unverif:
            acts.append((2, P["unverified"] % ctx))

    # 3) milestone completion (three hard conditions; delivery computed live)
    if cur_fm and cur_tp and \
       all(CFG.delivered(r.get(CFG.C["fm_module"], "")) is not False
           for r in cur_fm) and \
       all("✅" in r.get(CFG.C["tp_status"], "") for r in cur_tp):
        mnum = milestone.lstrip("M")
        ev_dirs = milestone_evidence_dirs(mnum)
        missing = []
        if not any((d / "result_summary.txt").exists() for d in ev_dirs):
            missing.append("regress evidence (copy result_summary.txt into "
                           "doc/evidence/v<ver>/)")
        if not signoff_file_exists(mnum):
            missing.append("rev milestone signoff (%s in doc/evidence/"
                           "v<ver>/)" % CFG.signoff_glob.format(m=mnum))
        if missing:
            acts.append((1, "%s scenarios all ✅ — still missing: %s"
                         % (milestone, "; ".join(missing))))
        else:
            acts.append((1, "%s three hard conditions met → make bump-minor "
                            "+ git tag v0.%d.0 to enter the next milestone"
                         % (milestone, int(mnum) + 1)))

    print("== next actions (%s / %s, %s profile — mechanical derivation; "
          "semantic decisions stay with you) ==" % (version, milestone,
                                                    CFG.profile))
    if not acts:
        print("(none — if the milestone scope changed, update "
              "feature-matrix/testplan first)")
    for i, (_, text) in enumerate(sorted(acts, key=lambda a: a[0]), 1):
        print("%d. %s" % (i, text))


def cmd_archive():
    lim = CFG.limits
    CFG.archive_dir.mkdir(parents=True, exist_ok=True)
    moved = False
    # log.md: keep newest log_keep blocks, move the rest (archive is
    # newest-first too).
    head, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    if len(blocks) > lim["log_keep"]:
        keep, old = blocks[:lim["log_keep"]], blocks[lim["log_keep"]:]
        CFG.log.write_text(head + "".join(keep), encoding="utf-8")
        ahead, ablocks = split_log_blocks(
            CFG.log_archive.read_text(encoding="utf-8"))
        CFG.log_archive.write_text(ahead + "".join(old) + "".join(ablocks),
                                   encoding="utf-8")
        print("log.md: archived %d block(s)" % len(old))
        moved = True
    # status.jsonl: keep newest status_keep lines.
    lines = [l for l in CFG.status.read_text(encoding="utf-8").splitlines()
             if l.strip()]
    if len(lines) > lim["status_keep"]:
        keep, old = lines[:lim["status_keep"]], lines[lim["status_keep"]:]
        CFG.status.write_text("\n".join(keep) + "\n", encoding="utf-8")
        alines = [l for l in
                  CFG.status_archive.read_text(encoding="utf-8").splitlines()
                  if l.strip()]
        CFG.status_archive.write_text("\n".join(old + alines) + "\n",
                                      encoding="utf-8")
        print("status.jsonl: archived %d line(s)" % len(old))
        moved = True
    # bugs.md: terminal rows beyond the keep count move out; active rows stay.
    moved |= archive_table_rows(
        CFG.bugs, CFG.bugs_archive,
        lambda r: r.get(CFG.C["bug_status"], "").strip() in BUG_DONE_STATES,
        lim["bug_done_keep"], "bugs.md")
    # lint-waivers.md: settled rows beyond the keep count move out.
    moved |= archive_table_rows(CFG.waivers, CFG.waivers_archive,
                                waiver_done, lim["waiver_done_keep"],
                                "lint-waivers.md")
    if not moved:
        print("nothing to archive")


def cmd_pin_spec():
    # Anti-sneak-edit: if spec differs from git HEAD, the change-record table
    # must have gained a row before re-pinning is allowed.
    cur = CFG.spec.read_text(encoding="utf-8")
    head = subprocess.run(["git", "-C", str(CFG.root), "show",
                           "HEAD:doc/spec.md"],
                          capture_output=True, text=True)
    if head.returncode == 0 and head.stdout != cur:
        old_n, new_n = count_mod_records(head.stdout), count_mod_records(cur)
        if old_n is not None and new_n is not None and new_n <= old_n:
            sys.exit("pin refused: doc/spec.md changed vs HEAD but the "
                     "change-record table gained no row — record the change "
                     "first, then --pin-spec")
    elif head.returncode != 0:
        print("[warn] cannot read spec.md at git HEAD — change-record delta "
              "check skipped")
    sha = hashlib.sha256(CFG.spec.read_bytes()).hexdigest()
    CFG.spec_sha.write_text(sha + "\n", encoding="utf-8")
    print("pinned doc/spec.md: %s" % sha)


def cmd_signoff():
    """Read-only milestone signoff pre-check: print each machine condition
    PASS/FAIL with offenders, then the human spot-check list. Writing the
    signoff file remains rev's job (signoff/rubric.md)."""
    version, milestone = read_version()
    mnum = milestone.lstrip("M")
    fails = []

    tp_rows = [r for r in parse_table(CFG.testplan)
               if r.get(CFG.C["tp_milestone"]) == milestone]
    not_pass = [r.get(CFG.C["tp_id"], "?") for r in tp_rows
                if "✅" not in r.get(CFG.C["tp_status"], "")]
    cond1 = not tp_rows or not not_pass
    print("[%s] 1. all %s scenarios ✅%s"
          % ("PASS" if cond1 else "FAIL", milestone,
             "" if cond1 else " — open: " + ", ".join(not_pass)))
    if not cond1:
        fails.append(1)

    ev_dirs = milestone_evidence_dirs(mnum)
    cond2 = any((d / "result_summary.txt").exists() for d in ev_dirs)
    print("[%s] 2. regress summary registered as evidence "
          "(result_summary.txt in doc/evidence/v0.%s.*)"
          % ("PASS" if cond2 else "FAIL", mnum))
    if not cond2:
        fails.append(2)

    bug_rows = parse_table(CFG.bugs)
    active = [r.get(CFG.C["bug_id"], "?") for r in bug_rows
              if r.get(CFG.C["bug_status"], "").strip()
              not in BUG_DONE_STATES]
    closure_errs = []
    for r in bug_rows:
        if r.get(CFG.C["bug_status"], "").strip() == "CLOSED":
            check_evidence(r.get(CFG.C["bug_verify"], ""),
                           "bug %s" % r.get(CFG.C["bug_id"], "?"),
                           closure_errs)
    cond3 = not active and not closure_errs
    detail = ""
    if active:
        detail += " — active: " + ", ".join(active)
    if closure_errs:
        detail += " — " + "; ".join(closure_errs)
    print("[%s] 3. all bugs terminal, closures evidenced%s"
          % ("PASS" if cond3 else "FAIL", detail))
    if not cond3:
        fails.append(3)

    signed = signoff_file_exists(mnum)
    print("[%s] signoff file (%s) in doc/evidence/v0.%s.*"
          % ("yes" if signed else "not yet", CFG.signoff_glob.format(m=mnum),
             mnum))

    print("\nHuman spot checks (rev-led, recorded in the signoff file — "
          "workflow/signoff/rubric.md):")
    print("  4. coverage closure ≠ risk closure: verify 2-3 hit bins were "
          "hit by the intended scenario; re-read 1 waived hole")
    print("  5. guards: make guards FILES=<touched> lists the review "
          "scope; falsify at least one (re-introduce its defect, see red)")
    print("  6. open SPEC_ISSUE list empty, or each entry has a written "
          "acceptance rationale")
    return 1 if fails else 0


def cmd_chain(rid):
    """Print one scenario's full evidence chain: testplan row → evidence
    excerpt head → related bugs → reviews/signoffs that cite it."""
    tp_rows = parse_table(CFG.testplan)
    row = next((r for r in tp_rows
                if r.get(CFG.C["tp_id"], "").strip() == rid), None)
    if row is None:
        sys.exit("scenario %s not found in testplan" % rid)
    print("== chain: %s ==" % rid)
    print("scenario [%s] %s" % (row.get(CFG.C["tp_status"], "?"),
                                row.get(CFG.C["tp_milestone"], "?")))
    for key in ("tp_id", "tp_evidence", "tp_repro"):
        val = row.get(CFG.C[key], "").strip()
        if val and val != "-":
            print("  %s: %s" % (CFG.C[key], val))
    desc = next((v for k, v in row.items()
                 if k not in {CFG.C[c] for c in
                              ("tp_id", "tp_milestone", "tp_status",
                               "tp_evidence", "tp_repro")} and v.strip()),
                "")
    if desc:
        print("  %s" % desc)

    ev = row.get(CFG.C["tp_evidence"], "").strip("` ")
    if ev.startswith("doc/evidence/") and (CFG.root / ev).exists():
        print("\n-- evidence head: %s --" % ev)
        for l in (CFG.root / ev).read_text(
                encoding="utf-8", errors="replace").splitlines()[:5]:
            print("  %s" % l)
    else:
        print("\n(no evidence file yet)")

    hits = [r.get(CFG.C["bug_id"], "?") for r in parse_table(CFG.bugs)
            if rid in " ".join(r.values())]
    print("\nbugs mentioning %s: %s" % (rid, ", ".join(hits) or "(none)"))

    citations = []
    pools = []
    if CFG.review_dir.is_dir():
        pools.append(CFG.review_dir.glob("*.md"))
    if CFG.evidence_dir.is_dir():
        pools.append(CFG.evidence_dir.glob("v*/*.md"))
    for pool in pools:
        for f in sorted(pool):
            if rid in f.read_text(encoding="utf-8", errors="replace"):
                citations.append(str(f.relative_to(CFG.root)))
    print("reviews/signoffs citing it: %s" % (", ".join(citations)
                                              or "(none)"))


def cmd_repro(rid):
    """Print just the replay command for a scenario (consumed by
    `make replay SCEN=<id>`)."""
    for r in parse_table(CFG.testplan):
        if r.get(CFG.C["tp_id"], "").strip() == rid:
            cmd = r.get(CFG.C["tp_repro"], "").strip().strip("`")
            if not cmd or cmd == "-":
                sys.exit("scenario %s has no repro command yet" % rid)
            print(cmd)
            return
    sys.exit("scenario %s not found in testplan" % rid)


def cmd_guards(paths):
    """Print every registered regression_guard whose `paths:` globs match
    any given file path. Consumed at card assembly (dispatch self-check)
    and by rubric #5 — constraint propagation by registered fact, which is
    what the instance-isolation rules cannot carry (pulp BUG-0015: a guard
    named the next victim file and nothing consumed it)."""
    import fnmatch
    hits = 0
    for page in sorted(CFG.bug_pages.glob("*.md")):
        text = page.read_text(encoding="utf-8", errors="replace")
        m = re.search(r"^## regression_guard\s*\n(.*?)(?=^## |\Z)", text,
                      re.M | re.S)
        if not m:
            continue
        block = m.group(1).strip()
        pm = re.search(r"^paths:\s*(.+)$", block, re.M)
        if not pm:
            continue
        globs = [g for g in re.split(r"[,\s]+", pm.group(1).strip()) if g]
        matched = [p for p in paths
                   if any(fnmatch.fnmatch(p, g) for g in globs)]
        if matched:
            hits += 1
            print("== %s guard (hit: %s) ==" % (page.stem,
                                                " ".join(matched)))
            print(block + "\n")
    print("%d guard(s) matched" % hits)


def main():
    global CFG
    parser = argparse.ArgumentParser(
        description="iverif doc mechanical layer")
    parser.add_argument("--handover", action="store_true",
                        help="print the handover summary")
    parser.add_argument("--next", action="store_true",
                        help="mechanically derive the next-action list")
    parser.add_argument("--check", action="store_true",
                        help="doc structure + evidence-chain guards")
    parser.add_argument("--archive", action="store_true",
                        help="roll archives (log/status/bugs/waivers)")
    parser.add_argument("--pin-spec", action="store_true",
                        help="re-pin spec.md sha256")
    parser.add_argument("--signoff", action="store_true",
                        help="print milestone signoff machine conditions")
    parser.add_argument("--chain", metavar="SCEN",
                        help="print a scenario's full evidence chain")
    parser.add_argument("--repro", metavar="SCEN",
                        help="print a scenario's replay command")
    parser.add_argument("--guards", nargs="+", metavar="PATH",
                        help="print regression_guards binding these paths")
    args = parser.parse_args()
    CFG = load_config()
    if args.pin_spec:
        cmd_pin_spec()
    if args.archive:
        cmd_archive()
    if args.check:
        sys.exit(cmd_check())
    if args.signoff:
        sys.exit(cmd_signoff())
    if args.chain:
        cmd_chain(args.chain)
    if args.repro:
        cmd_repro(args.repro)
    if args.guards:
        cmd_guards(args.guards)
    if args.handover:
        cmd_handover()
    if args.next:
        cmd_next()
    if not any(vars(args).values()):
        parser.print_help()


if __name__ == "__main__":
    main()
