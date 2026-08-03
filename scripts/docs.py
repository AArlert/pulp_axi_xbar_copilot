#!/usr/bin/env python3
# The single mechanical script for doc bookkeeping (0.5.4 reset — evidence.py
# and bump.py merged in; the old check/chain-audit/pin/signoff machinery is
# gone, see git tag v0.5.3-pre-reset for the previous incarnation).
#
# Operations (one per make target):
#   --handoff    session-start snapshot of status/testplan/bugs
#   --next       mechanically derived next-action list
#   --check      table sanity + green-needs-repro + unfilled-TODO gate
#   --archive    roll old log blocks / status lines / terminal bug rows
#   --bump ARG   version bump (patch | minor | 0.M.P) + skeleton insertion
#   evidence:    --scen/--bug + --test/--seed (sim) or --cmd/--expect (non-sim)
#
# Philosophy: the script replaces hand-copying, never judgment. Only
# `make evidence` may turn a testplan row green (CLAUDE.md red line 1).
import argparse
import json
import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

import svacheck
from iverif_config import (BUG_DONE_STATES, BUG_STATES, STATUS_EMOJIS,
                           load_config)

CFG = None

ESCAPED_PIPE = "\x00"
BLOCK_RE = re.compile(r"^## \[")
TODO_RE = re.compile(r"\bTODO\b")
SEMVER_RE = re.compile(r"^0\.(\d+)\.(\d+)$")
BUG_ID_RE = re.compile(r"^BUG-\d+$")

# ---------------------------------------------------------------- tables

def row_cells(line):
    line = line.replace("\\|", ESCAPED_PIPE)
    return [c.strip().replace(ESCAPED_PIPE, "|")
            for c in line.strip().strip("|").split("|")]


def parse_table(path):
    """Parse the markdown tables in a file into [{header: cell}, ...]."""
    rows, header = [], None
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip().startswith("|"):
            header = None
            continue
        cells = row_cells(line)
        if header is None:
            header = cells
            continue
        if all(set(c) <= set("-: ") for c in cells):
            continue
        rows.append(dict(zip(header, cells)))
    return rows


def check_table_structure(path, errors):
    """FAIL any data row whose cell count differs from its header's: an
    unescaped `|` inside a cell shifts every later column and gates then
    silently read the wrong cells."""
    header_n = None
    for i, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip().startswith("|"):
            header_n = None
            continue
        cells = row_cells(line)
        if header_n is None:
            header_n = len(cells)
            continue
        if all(set(c) <= set("-: ") for c in cells):
            continue
        if len(cells) != header_n:
            errors.append("%s:%d row has %d cells, header has %d — escape "
                          "literal | as \\|" % (path.name, i, len(cells),
                                                header_n))


def split_table_lines(text, id_col=None):
    """Split out the first markdown table (with id_col in its header, when
    given) by line: (pre-table text, header lines, data-row lines,
    post-table text). Other tables stay untouched in pre/post text."""
    head, header, rows, tail = [], [], [], []
    state = 0  # 0=searching, 1=inside target table, 2=after
    pending = []  # lines of a table being probed
    for line in text.splitlines(keepends=True):
        in_table = line.strip().startswith("|")
        if state == 0:
            if in_table:
                if not pending:
                    if id_col is None or id_col in row_cells(line):
                        state = 1
                        header.append(line)
                        continue
                pending.append(line)
            else:
                head.extend(pending)
                pending = []
                head.append(line)
        elif state == 1:
            if in_table:
                (header if len(header) < 2 else rows).append(line)
            else:
                state = 2
                tail.append(line)
        else:
            tail.append(line)
    head.extend(pending)
    return "".join(head), "".join(header), rows, "".join(tail)


def update_row(path, id_col, id_val, updates):
    """Locate a markdown table row by its id column and update cells."""
    out, header, found = [], None, False
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s.startswith("|"):
            header = None
            out.append(line)
            continue
        cells = row_cells(line)
        if header is None:
            header = cells
        elif not all(set(c) <= set("-: ") for c in cells) and not found \
                and dict(zip(header, cells)).get(id_col, "") == id_val:
            found = True
            row = dict(zip(header, cells))
            row.update(updates)
            out.append("| " + " | ".join(
                row.get(h, "").replace("|", "\\|") for h in header) + " |")
            continue
        out.append(line)
    if not found:
        sys.exit("no row with id %s in %s" % (id_val, path.name))
    path.write_text("\n".join(out) + "\n", encoding="utf-8")


def row_exists(path, id_col, id_val):
    return any(r.get(id_col, "") == id_val for r in parse_table(path))

# ------------------------------------------------------------ log/status

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


def read_version():
    data = json.loads(CFG.version_json.read_text(encoding="utf-8"))
    return data["version"], data.get("milestone", "")

# --------------------------------------------------------------- handoff

def handoff():
    version, milestone = read_version()
    st = json.loads(
        CFG.status.read_text(encoding="utf-8").splitlines()[0])
    _, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    tp_rows = parse_table(CFG.testplan)

    print("== %s handoff ==" % CFG.project)
    print("version: %s (%s)" % (version, milestone))
    print("status[%s]: %s" % (st["date"], st["summary"]))
    print("\n-- log.md latest block --")
    print(blocks[0].rstrip() if blocks else "(empty)")
    print("\n-- testplan --")
    per_ms = {}
    for r in tp_rows:
        ms = r.get(CFG.C["tp_milestone"], "?")
        emoji = next((e for e in STATUS_EMOJIS
                      if e in r.get(CFG.C["tp_status"], "")), "?")
        per_ms.setdefault(ms, []).append(emoji)
    for ms in sorted(per_ms):
        marks = per_ms[ms]
        print("  %s: ✅%d/%d" % (ms, marks.count("✅"), len(marks)))
    todo = [r.get(CFG.C["tp_id"], "?") for r in tp_rows
            if "✅" not in r.get(CFG.C["tp_status"], "")]
    print("  open scenarios: %s" % (", ".join(todo) if todo else "(none)"))
    print("\n-- bugs --")
    open_bugs = [r for r in parse_table(CFG.bugs)
                 if r.get(CFG.C["bug_id"], "").strip()
                 and r.get(CFG.C["bug_status"], "").strip()
                 not in BUG_DONE_STATES]
    if open_bugs:
        for r in open_bugs:
            print("  %s [%s] %s" % (r.get(CFG.C["bug_id"], "?"),
                                    r.get(CFG.C["bug_status"], "?"),
                                    r.get(CFG.C["bug_summary"], "")))
    else:
        print("  (no open bugs)")
    print("\nHint: `make next` for the derived action list.")

# ------------------------------------------------------------------ next

def next_actions():
    version, milestone = read_version()
    acts = []

    first = CFG.status.read_text(encoding="utf-8").splitlines()[0]
    if json.loads(first).get("summary", "").strip() == "TODO":
        acts.append("closeout unfinished: fill status.jsonl line 1 summary")
    _, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    if blocks and TODO_RE.search(blocks[0]):
        acts.append("closeout unfinished: answer the four questions in "
                    "log.md's first block")

    for r in parse_table(CFG.bugs):
        bid = r.get(CFG.C["bug_id"], "").strip()
        if not bid:
            continue
        st = r.get(CFG.C["bug_status"], "").strip()
        if st == "OPEN":
            acts.append("%s OPEN — triage/fix it (page: %s)"
                        % (bid, r.get(CFG.C["bug_link"], "?")))
        elif st == "FIXING":
            acts.append("%s FIXING — finish, then close via `make evidence "
                        "BUG=%s ...`" % (bid, bid))

    tp_rows = parse_table(CFG.testplan)
    cur = [r for r in tp_rows if r.get(CFG.C["tp_milestone"]) == milestone]
    for r in cur:
        if "❌" in r.get(CFG.C["tp_status"], ""):
            acts.append("%s is ❌ — file the failure in bugs.md"
                        % r.get(CFG.C["tp_id"]))
    open_cur = [r.get(CFG.C["tp_id"], "?") for r in cur
                if "✅" not in r.get(CFG.C["tp_status"], "")]
    if open_cur:
        acts.append("%s open scenarios: %s — implement, run, then `make "
                    "evidence SCEN=<id> TEST= SEED=`"
                    % (milestone, ", ".join(open_cur)))
    if not cur:
        acts.append("%s has no testplan rows yet — register scenario rows "
                    "from doc/milestone.md's %s skeleton before coding"
                    % (milestone, milestone))

    print("== next actions (%s / %s — mechanical derivation; semantic "
          "decisions stay with you) ==" % (version, milestone))
    if not acts:
        print("(none — check doc/milestone.md exit criteria)")
    for i, a in enumerate(acts, 1):
        print("%d. %s" % (i, a))

# ----------------------------------------------------------------- check

def check():
    errors = []
    for p in (CFG.version_json, CFG.status, CFG.log, CFG.testplan,
              CFG.spec, CFG.bugs):
        if not p.exists():
            errors.append("required file missing: %s" % p.name)
    if errors:
        report(errors)

    check_table_structure(CFG.testplan, errors)
    check_table_structure(CFG.bugs, errors)

    seen = set()
    for r in parse_table(CFG.testplan):
        rid = r.get(CFG.C["tp_id"], "").strip()
        if not rid:
            continue
        if rid in seen:
            errors.append("testplan duplicate id: %s" % rid)
        seen.add(rid)
        if "✅" in r.get(CFG.C["tp_status"], ""):
            repro = r.get(CFG.C["tp_repro"], "").strip("` ")
            up = repro.upper()
            if not repro or ("CMD" not in up and ("TEST" not in up
                                                  or "SEED" not in up)):
                errors.append("testplan %s is ✅ but repro cell is not a "
                              "replay command (TEST=/SEED= or CMD)" % rid)
            if not r.get(CFG.C["tp_evidence"], "").strip("- "):
                errors.append("testplan %s is ✅ but evidence cell is empty "
                              "— only `make evidence` may turn rows green"
                              % rid)

    seen = set()
    for r in parse_table(CFG.bugs):
        bid = r.get(CFG.C["bug_id"], "").strip()
        if not bid:
            continue
        if bid in seen:
            errors.append("bugs.md duplicate id: %s" % bid)
        seen.add(bid)
        st = r.get(CFG.C["bug_status"], "").strip()
        if st not in BUG_STATES:
            errors.append("bugs.md %s has unknown status %r (valid: %s)"
                          % (bid, st, "/".join(BUG_STATES)))
        if st in BUG_DONE_STATES and st == "CLOSED" \
                and not r.get(CFG.C["bug_evidence"], "").strip("- "):
            errors.append("bugs.md %s is CLOSED without re-verification "
                          "evidence" % bid)

    try:
        first = CFG.status.read_text(encoding="utf-8").splitlines()[0]
        st = json.loads(first)
        if st.get("summary", "").strip() == "TODO":
            errors.append("status.jsonl line 1 summary is the TODO skeleton")
    except (IndexError, json.JSONDecodeError) as e:
        errors.append("status.jsonl line 1 unreadable: %s" % e)
    _, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    if blocks and TODO_RE.search(blocks[0]):
        errors.append("log.md first block has unfilled TODO skeleton")

    report(errors)


def report(errors):
    if errors:
        print("check: %d error(s)" % len(errors))
        for e in errors:
            print("  ERROR %s" % e)
        sys.exit(1)
    print("check: OK")
    sys.exit(0)

# --------------------------------------------------------------- archive

def archive():
    lim = CFG.limits
    CFG.archive_dir.mkdir(parents=True, exist_ok=True)
    for p in (CFG.status_archive, CFG.bugs_archive):
        if not p.exists():
            p.write_text("", encoding="utf-8")
    if not CFG.log_archive.exists():
        CFG.log_archive.write_text("# Log archive (newest first)\n\n",
                                   encoding="utf-8")
    moved = False

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

    head, header, rows, tail = split_table_lines(
        CFG.bugs.read_text(encoding="utf-8"), id_col=CFG.C["bug_id"])
    if header:
        cols = row_cells(header.splitlines()[0])
        done_idx = [i for i, r in enumerate(rows)
                    if dict(zip(cols, row_cells(r))).get(
                        CFG.C["bug_status"], "").strip() in BUG_DONE_STATES]
        movable = set(done_idx[:-lim["bug_done_keep"]]
                      if lim["bug_done_keep"] else done_idx)
        if movable:
            old = [rows[i] for i in sorted(movable)]
            CFG.bugs.write_text(
                head + header
                + "".join(r for i, r in enumerate(rows) if i not in movable)
                + tail, encoding="utf-8")
            ah, ahdr, arows, atail = split_table_lines(
                CFG.bugs_archive.read_text(encoding="utf-8"),
                id_col=CFG.C["bug_id"])
            if not ahdr:
                ah, ahdr, atail = ("# Bugs archive (newest first)\n\n",
                                   header, "")
            CFG.bugs_archive.write_text(
                ah + ahdr + "".join(old) + "".join(arows) + atail,
                encoding="utf-8")
            print("bugs.md: archived %d row(s)" % len(old))
            moved = True

    if not moved:
        print("nothing to archive")

# ------------------------------------------------------------------ bump

LOG_SKELETON = """## [{ver}] {today} TODO (one-line title)

**Done**
- TODO

**Not done**
- TODO

**Next**
- TODO

**How verified**
- TODO

"""


def bump(arg):
    data = json.loads(CFG.version_json.read_text(encoding="utf-8"))
    cur = data["version"]
    m = SEMVER_RE.match(cur)
    if not m:
        sys.exit("current version is invalid: %s" % cur)
    major, patch = int(m.group(1)), int(m.group(2))
    if arg == "patch":
        new = "0.%d.%d" % (major, patch + 1)
    elif arg == "minor":
        new = "0.%d.0" % (major + 1)
    elif SEMVER_RE.match(arg):
        new = arg
    else:
        sys.exit("invalid argument: %s (use: patch / minor / 0.M.P)" % arg)
    data["version"] = new
    data["milestone"] = "M%s" % SEMVER_RE.match(new).group(1)
    CFG.version_json.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    print("%s -> %s (%s)" % (cur, new, data["milestone"]))

    today = date.today().isoformat()
    lines = [l for l in CFG.status.read_text(encoding="utf-8").splitlines()
             if l.strip()]
    if not lines or json.loads(lines[0]).get("version") != new:
        rec = {"date": today, "version": new, "summary": "TODO"}
        lines.insert(0, json.dumps(rec, ensure_ascii=False))
        CFG.status.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print("status.jsonl: skeleton line inserted (summary to fill)")
    text = CFG.log.read_text(encoding="utf-8")
    if not re.search(r"^## \[%s\]" % re.escape(new), text, flags=re.M):
        block = LOG_SKELETON.format(ver=new, today=today)
        mo = re.search(r"^## \[", text, flags=re.M)
        text = (text[:mo.start()] + block + text[mo.start():] if mo
                else text.rstrip() + "\n\n" + block)
        CFG.log.write_text(text, encoding="utf-8")
        print("log.md: skeleton block inserted (four questions to fill)")
    print("Reminder: fill the skeletons, then make check; on milestone "
          "completion tag: git tag v" + new)

# -------------------------------------------------------------- evidence

SUMMARY_MARK = "UVM Report Summary"
PLAIN_MARK = "V C S   S i m u l a t i o n"
KEY_LINE_RE = re.compile(r"(?i)\b(pass|match|compare ok|check ok"
                         r"|running test|tests failed|ended|mismatch)\b"
                         r"|\[FCOV_SUMMARY\]")
KEY_LINES_MAX = 30
SVA_DETAIL_RE = re.compile(r'^\s*"([^"]+)",\s*\d+:\s*\S+.*?'
                           r'(\d+)\s+attempts?\b.*?(\d+)\s+match', re.I)
CMD_ABS_PATH_RE = re.compile(r'(?<![:\w])(/[\w./-]+)')


def extract(log_path, rid):
    """Mechanical excerpt: UVM Report Summary (or VCS completion banner) +
    SVA assertion summary + key PASS/compare lines. FAIL logs are rejected —
    failures are filed in bugs.md, never registered as evidence. Two-legged
    verdict (svacheck.judge): assertion failures do not increment UVM_ERROR,
    so a log can read `UVM_ERROR : 0` while assertions failed."""
    text = log_path.read_text(encoding="utf-8", errors="replace")
    verdict, reason, sva = svacheck.judge(
        text, CFG, baseline=svacheck.load_baseline(CFG))
    if verdict == "NOSUMMARY":
        sys.exit("log has neither a UVM summary nor a VCS completion banner "
                 "— cannot judge the result: %s" % log_path)
    if verdict == "FAIL":
        detail = "\n".join(sva.detail_lines()) if sva and sva.failed else ""
        sys.exit("log judged FAIL (%s) — FAIL logs are never evidence; file "
                 "the failure in bugs.md (source: %s)%s"
                 % (reason, log_path,
                    "\nfailing assertions:\n%s" % detail if detail else ""))
    lines = text.splitlines()
    idx = next((i for i, l in enumerate(lines) if SUMMARY_MARK in l), None)
    if idx is not None:
        summary = lines[max(0, idx - 1):idx + 14]
    else:
        idx = next(i for i, l in enumerate(lines) if PLAIN_MARK in l)
        summary = lines[max(0, idx - 20):idx + 8]
    sva_lines = [l for l in lines if svacheck.SUMMARY_RE.match(l)]
    extra = []
    for i, pat in enumerate(CFG.key_line_extra):
        try:
            extra.append(re.compile(pat))
        except re.error as exc:
            sys.exit("iverif.json key_line_extra[%d] is not a valid regex "
                     "(%s): %r" % (i, exc, pat))
    agg, keys = {}, []
    for l in lines:
        dm = SVA_DETAIL_RE.match(l)
        if dm:
            a = agg.setdefault(dm.group(1), [0, 0, 0])
            a[0] += 1
            a[1] += int(dm.group(2))
            a[2] += int(dm.group(3))
            continue
        if KEY_LINE_RE.search(l) or rid in l \
                or any(rx.search(l) for rx in extra):
            keys.append(l)
    dropped = len(keys) - KEY_LINES_MAX
    keys = keys[:KEY_LINES_MAX]
    if dropped > 0:
        keys.append("... (%d more key lines truncated)" % dropped)
    agg_lines = ["%s: %d properties/covers, %d attempts, %d match"
                 % (f, c[0], c[1], c[2]) for f, c in sorted(agg.items())]
    return summary, sva_lines, agg_lines + keys


def evidence(args):
    rid = args.scen or args.bug
    if args.bug:
        if not BUG_ID_RE.match(args.bug):
            sys.exit("--bug expects the row id in its full BUG-NNNN form "
                     "(got %r)" % args.bug)
        if not row_exists(CFG.bugs, CFG.C["bug_id"], args.bug):
            sys.exit("no row with id %s in %s — evidence not written"
                     % (args.bug, CFG.bugs.name))

    if args.cmd:
        # Non-sim re-verification (lint/compile/tool-output criteria).
        # Fail-closed twice: nonzero exit is never evidence, and output with
        # no declared signature is "no visible error", not "checked".
        if not args.bug:
            sys.exit("--cmd evidence is for bug closure only (--bug)")
        if not args.expect:
            sys.exit("--cmd requires --expect <regex>: name the output "
                     "signature that proves the fix")
        for tok in CMD_ABS_PATH_RE.findall(args.cmd):
            resolved = str(Path(tok).resolve())
            if resolved != str(CFG.root) and \
                    not resolved.startswith(str(CFG.root) + "/"):
                sys.exit("--cmd references an out-of-repo absolute path "
                         "(%s) — evidence commands must be replayable from "
                         "the repo alone; rejected" % tok)
        try:
            exp = re.compile(args.expect)
        except re.error as e:
            sys.exit("--expect is not a valid regex (%s): %r"
                     % (e, args.expect))
        # A nested `make` inside args.cmd would inherit MAKEFLAGS/MAKELEVEL/
        # MFLAGS from the `make evidence` recipe and print sub-make
        # Entering/Leaving banners a top-level invocation never prints,
        # silently changing the captured output shape (BUG-0073).
        cmd_env = os.environ.copy()
        for var in ("MAKEFLAGS", "MAKELEVEL", "MFLAGS"):
            cmd_env.pop(var, None)
        cp = subprocess.run(args.cmd, shell=True, capture_output=True,
                            text=True, cwd=str(CFG.root), env=cmd_env)
        out = (cp.stdout + cp.stderr).splitlines()
        if cp.returncode != 0:
            sys.exit("re-verification command failed (exit %d) — FAIL runs "
                     "are never evidence:\n%s"
                     % (cp.returncode, "\n".join(out[-15:])))
        hits = [l for l in out if exp.search(l)]
        if not hits:
            sys.exit("expected signature %r not found in command output — "
                     "no signature, no evidence" % args.expect)
        rel = write_evidence_file(rid, [
            "CMD: %s" % args.cmd,
            "# Generated by scripts/docs.py on %s, exit_code: 0, expect: %s"
            % (date.today(), args.expect),
            "", "## Expected-signature lines", *hits[:20],
            "", "## Output tail", *out[-20:], ""])
        update_row(CFG.bugs, CFG.C["bug_id"], args.bug,
                   {CFG.C["bug_status"]: "CLOSED",
                    CFG.C["bug_evidence"]: rel})
        print("bugs.md %s backfilled (CLOSED / evidence)" % args.bug)
        check()

    if not args.test or not args.seed:
        sys.exit("sim evidence needs --test and --seed (or --cmd for "
                 "non-sim re-verification)")
    log_path = (Path(args.log).resolve() if args.log
                else CFG.sim_log_path(args.test, args.seed))
    if not log_path.exists():
        sys.exit("sim log not found: %s (no log, no evidence)" % log_path)

    summary, sva_lines, keys = extract(log_path, rid)
    cmd = "make run TEST=%s SEED=%s" % (args.test, args.seed)
    src = (log_path.relative_to(CFG.root)
           if str(log_path).startswith(str(CFG.root)) else log_path)
    body = [cmd,
            "# Generated by scripts/docs.py on %s, source log: %s"
            % (date.today(), str(src).replace("\\", "/"))]
    if args.spec_ref:
        body.append("# spec_ref: %s" % args.spec_ref)
    body += ["", "## Report Summary", *summary,
             "", "## SVA assertion summary (VCS -assert verbose native "
             "counts; zero failures required)",
             *(sva_lines
               or ["(no native summary in source log — sva_enforce off)"]),
             "", "## Key check lines", *keys, ""]
    rel = write_evidence_file(rid, body)

    if args.scen:
        update_row(CFG.testplan, CFG.C["tp_id"], args.scen,
                   {CFG.C["tp_status"]: "✅", CFG.C["tp_evidence"]: rel,
                    CFG.C["tp_repro"]: "`%s`" % cmd})
        print("testplan %s backfilled (✅ / evidence / repro)" % args.scen)
    else:
        update_row(CFG.bugs, CFG.C["bug_id"], args.bug,
                   {CFG.C["bug_status"]: "CLOSED",
                    CFG.C["bug_evidence"]: rel})
        print("bugs.md %s backfilled (CLOSED / evidence)" % args.bug)
    check()


def write_evidence_file(rid, body_lines):
    version, _ = read_version()
    ev_dir = CFG.evidence_dir / ("v%s" % version)
    ev_dir.mkdir(parents=True, exist_ok=True)
    ev_path = ev_dir / ("%s.log" % rid)
    ev_path.write_text("\n".join(body_lines), encoding="utf-8")
    rel = str(ev_path.relative_to(CFG.root)).replace("\\", "/")
    print("evidence written: %s" % rel)
    return rel

# ------------------------------------------------------------------ main

def main():
    global CFG
    ap = argparse.ArgumentParser(
        description="single mechanical script: doc bookkeeping + evidence")
    ap.add_argument("--handoff", action="store_true")
    ap.add_argument("--next", action="store_true")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--archive", action="store_true")
    ap.add_argument("--bump", metavar="ARG",
                    help="patch | minor | 0.M.P")
    ap.add_argument("--scen", help="testplan scenario id (marks ✅)")
    ap.add_argument("--bug", help="bugs.md id (re-verify + close)")
    ap.add_argument("--test", help="test name (sim evidence)")
    ap.add_argument("--seed", help="simulation seed (sim evidence)")
    ap.add_argument("--log", help="sim log path (default from iverif.json)")
    ap.add_argument("--cmd", help="non-sim re-verification command")
    ap.add_argument("--expect", help="regex the command output must match")
    ap.add_argument("--spec-ref", help="spec clause id(s), e.g. SPEC-4.2.1")
    args = ap.parse_args()
    CFG = load_config()

    if args.handoff:
        handoff()
    elif args.next:
        next_actions()
    elif args.check:
        check()
    elif args.archive:
        archive()
    elif args.bump:
        bump(args.bump)
    elif args.scen or args.bug:
        evidence(args)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
