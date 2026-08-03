#!/usr/bin/env python3
# Mechanical evidence generation: extract an excerpt from a simulation log
# into doc/evidence/, then backfill testplan/bugs status. Evidence files are
# never hand-written (prevents transcription errors and hallucinated
# excerpts); the only semantic decision left to the operator is *which*
# scenario/bug id this run belongs to. The anti-forgery anchor remains "the
# simulation really ran here".
#
# Usage (inside the VM, after the run):
#   python3 scripts/evidence.py --scen M1-01 --test smoke_test --seed 42
#   python3 scripts/evidence.py --bug BUG-003 --test err_test --seed 7
#   optional: --log <path> (default from iverif.json sim_log pattern)
#             --spec-ref SPEC-4.2.1[,SPEC-4.2.3]
import argparse
import json
import os
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

import svacheck
from iverif_config import load_config

CFG = None

SUMMARY_MARK = "UVM Report Summary"
PLAIN_MARK = "V C S   S i m u l a t i o n"
# Key-line extraction. `running test` (the UVM `[RNTST] Running test <name>`
# line) is included as an identity anchor: checks that print only at
# UVM_HIGH verbosity leave the key-line section empty at default verbosity,
# and the RNTST line at least pins the excerpt to a concrete test — together
# with the SVA summary and the report summary it stays re-judgeable
# (ppa-lite-copilot BUG-017 R7). `tests failed` / `ended` / `mismatch` cover
# non-UVM tb (ucli `run;exit`-driven `$stop`) scoreboard verdict lines, e.g.
# upstream `tb_axi_xbar`'s "Simulation has ended!" / "Tests Failed: 0" —
# these previously matched none of the UVM-shaped patterns above, leaving
# `## Key check lines` empty despite a sound verdict (pulp_axi_xbar FB-6).
# `[FCOV_SUMMARY]` is the canon convention for functional-coverage summary
# lines (workflow/evidence_record.md: the tb prints one line per covergroup,
# `[FCOV_SUMMARY] <cg> samples=<n> inst_cov=<pct>`) so coverage numbers land
# in the excerpt and signoff never re-opens source logs. Promoted from
# pulp_axi_xbar's project tag (FB-9) by user ruling 2026-07-28: adopting
# projects must be correct with zero config. Genuinely project-specific
# extra tags still ride the `key_line_extra` regex list in iverif.json —
# never edits to this file.
KEY_LINE_RE = re.compile(r"(?i)\b(pass|match|compare ok|check ok"
                         r"|running test|tests failed|ended|mismatch)\b"
                         r"|\[FCOV_SUMMARY\]")
KEY_LINES_MAX = 30
# -assert verbose per-assertion/cover detail lines ('"file", N: inst ...
# X attempts ... Y match') arrive by the hundred and would eat the key-line
# cap as an arbitrary prefix (pulp FB-13); they are aggregated per source
# file instead, and truncation is made visible.
SVA_DETAIL_RE = re.compile(r'^\s*"([^"]+)",\s*\d+:\s*\S+.*?'
                           r'(\d+)\s+attempts?\b.*?(\d+)\s+match', re.I)
# BUG-0060: the row id form actually seen in doc/bugs.md is BUG-NNNN — a
# bare number (e.g. `BUG=0048`, missing the prefix) is rejected outright
# rather than guessed/normalized, since guessing the zero-padding width
# silently would risk writing evidence for the wrong id. 见
# doc/fw-feedback.md FB-32.
BUG_ID_RE = re.compile(r"^BUG-\d+$")
# BUG-0057: catches an absolute-path token embedded in a --cmd string (the
# concrete failure mode found: `CMD: bash /tmp/<session>/scratchpad/x.sh`,
# which stops being replayable the moment that temp dir is gone). Not
# preceded by ':' or a word char, so URL schemes ("http://") and the tail
# of an identifier are skipped. This is a heuristic scan, not a shell
# parser — it exists to catch that concrete shape, not to sandbox
# arbitrary CMD text (workflow/review.md Q3: "stranger reproduce from the
# repo alone"). 见 doc/fw-feedback.md FB-32.
CMD_ABS_PATH_RE = re.compile(r'(?<![:\w])(/[\w./-]+)')


def read_version():
    return json.loads(
        CFG.version_json.read_text(encoding="utf-8"))["version"]


def extract(log_path, rid):
    """Mechanical extraction: UVM Report Summary section (or the VCS
    completion banner for non-UVM TBs) + SVA assertion summary + key
    PASS/compare lines + lines mentioning the scenario id. FAIL logs are
    rejected — failures are filed in bugs.md, never registered as evidence.

    The verdict is two-legged (svacheck.judge): assertion failures do not
    increment UVM_ERROR, so a log can read `UVM_ERROR : 0` while assertions
    failed or were silenced — leg 2 judges them independently."""
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
        # Non-UVM tb scoreboard verdict lines ("Simulation has ended!",
        # "Tests Failed: 0") commonly print a dozen-plus lines before the
        # completion banner, not immediately above it — widen enough to
        # catch a typical verdict tail (pulp_axi_xbar FB-6).
        summary = lines[max(0, idx - 20):idx + 8]
    # Archive the native assertion-count lines with the excerpt so the
    # evidence itself stays independently re-judgeable by svacheck.py.
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


def row_exists(path, id_col, id_val):
    """Peek a markdown table for a matching id without writing anything —
    used to validate --bug *before* any evidence file touches disk
    (BUG-0060: writing before validating left a fully-formed, orphaned
    .log file on an id typo, invisible to docs.py's orphan scan since that
    only walks doc/bugs/*.md, never doc/evidence/). 见
    doc/fw-feedback.md FB-32."""
    esc = "\x00"
    header = None
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s.startswith("|"):
            header = None
            continue
        cells = [c.strip().replace(esc, "|")
                 for c in s.replace("\\|", esc).strip("|").split("|")]
        if header is None:
            header = cells
        elif not all(set(c) <= set("-: ") for c in cells) and \
                dict(zip(header, cells)).get(id_col, "") == id_val:
            return True
    return False


def update_row(path, id_col, id_val, updates):
    """Locate a markdown table row by its id column and update the given
    columns (supports \\| escapes)."""
    esc = "\x00"
    out, header, found = [], None, False
    for line in path.read_text(encoding="utf-8").splitlines():
        s = line.strip()
        if not s.startswith("|"):
            header = None
            out.append(line)
            continue
        cells = [c.strip().replace(esc, "|")
                 for c in s.replace("\\|", esc).strip("|").split("|")]
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


def main():
    global CFG
    ap = argparse.ArgumentParser(
        description="mechanical evidence generation + status backfill")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--scen", help="testplan scenario id (marks ✅)")
    g.add_argument("--bug", help="bugs.md id (re-verify + close)")
    ap.add_argument("--test", help="test name (sim evidence)")
    ap.add_argument("--seed", help="simulation seed (sim evidence)")
    ap.add_argument("--log", help="sim log path (default from iverif.json)")
    ap.add_argument("--cmd", help="non-sim re-verification command "
                                  "(bug closure only; runs it now)")
    ap.add_argument("--expect", help="regex the command output must match "
                                     "— the signature proving the fix "
                                     "(required with --cmd)")
    ap.add_argument("--spec-ref", help="spec clause id(s) this run "
                                       "evidences, e.g. SPEC-4.2.1")
    args = ap.parse_args()
    CFG = load_config()

    rid = args.scen or args.bug
    if args.bug:
        # BUG-0060: validate the id — form, then existence — before
        # anything runs or gets written. Previously the row lookup
        # happened after the evidence file was already on disk, so a typo
        # (e.g. `BUG=0048` missing the prefix) left an orphaned, fully
        # signed .log with no bugs.md row to back it.
        if not BUG_ID_RE.match(args.bug):
            sys.exit("--bug expects the row id in its full BUG-NNNN form "
                     "(got %r) — a bare number/short form is rejected "
                     "rather than guessed" % args.bug)
        if not row_exists(CFG.bugs, CFG.C["bug_id"], args.bug):
            sys.exit("no row with id %s in %s — evidence not written"
                     % (args.bug, CFG.bugs.name))
    if args.cmd:
        # Non-sim re-verification (lint/compile/tool-output criteria —
        # pulp FB-16). Fail-closed twice: nonzero exit is never evidence,
        # and an output with no declared signature is "no visible error",
        # not "checked".
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
                         "the repo alone (workflow/review.md Q3); rejected "
                         "before running anything" % tok)
        try:
            exp = re.compile(args.expect)
        except re.error as e:
            sys.exit("--expect is not a valid regex (%s): %r"
                     % (e, args.expect))
        # BUG-0073: this subprocess is itself a child of the `make evidence`
        # recipe, so it inherits MAKEFLAGS/MAKELEVEL/MFLAGS. If args.cmd
        # nests another `make <target>` call, that nested make would detect
        # (via these inherited vars) that it is a sub-make and print GNU
        # Make's standard Entering/Leaving-directory banners around its
        # output — banners a direct top-level shell invocation of the same
        # string never prints, silently changing the captured stdout shape
        # (e.g. breaking `tail -N`-based signatures). Strip only these
        # sub-make-detection vars so a nested `make` behaves as a top-level
        # invocation; no other environment variable is touched.
        cmd_env = os.environ.copy()
        for var in ("MAKEFLAGS", "MAKELEVEL", "MFLAGS"):
            cmd_env.pop(var, None)
        cp = subprocess.run(args.cmd, shell=True, capture_output=True,
                            text=True, cwd=str(CFG.root), env=cmd_env)
        out = (cp.stdout + cp.stderr).splitlines()
        if cp.returncode != 0:
            sys.exit("re-verification command failed (exit %d) — FAIL "
                     "runs are never evidence:\n%s"
                     % (cp.returncode, "\n".join(out[-15:])))
        hits = [l for l in out if exp.search(l)]
        if not hits:
            sys.exit("expected signature %r not found in command output — "
                     "no signature, no evidence" % args.expect)
        ev_dir = CFG.evidence_dir / ("v%s" % read_version())
        ev_dir.mkdir(parents=True, exist_ok=True)
        ev_path = ev_dir / ("%s.log" % rid)
        ev_path.write_text("\n".join(
            ["CMD: %s" % args.cmd,
             "# Generated by scripts/evidence.py on %s, exit_code: 0, "
             "expect: %s" % (date.today(), args.expect),
             "", "## Expected-signature lines", *hits[:20],
             "", "## Output tail", *out[-20:], ""]), encoding="utf-8")
        rel = str(ev_path.relative_to(CFG.root)).replace("\\", "/")
        print("evidence written: %s" % rel)
        update_row(CFG.bugs, CFG.C["bug_id"], args.bug,
                   {CFG.C["bug_status"]: "CLOSED",
                    CFG.C["bug_verify"]: rel})
        print("bugs.md %s backfilled (CLOSED / verify evidence) — "
              "remember: closer ≠ fixer" % args.bug)
        sys.exit(subprocess.run(
            [sys.executable,
             str(Path(__file__).resolve().parent / "docs.py"),
             "--check"]).returncode)
    if not args.test or not args.seed:
        sys.exit("sim evidence needs --test and --seed (or use --cmd for "
                 "non-sim re-verification)")
    log_path = (Path(args.log).resolve() if args.log
                else CFG.sim_log_path(args.test, args.seed))
    if not log_path.exists():
        sys.exit("sim log not found: %s (no log, no evidence)" % log_path)

    summary, sva_lines, keys = extract(log_path, rid)
    cmd = "make run TEST=%s SEED=%s" % (args.test, args.seed)
    ev_dir = CFG.evidence_dir / ("v%s" % read_version())
    ev_dir.mkdir(parents=True, exist_ok=True)
    ev_path = ev_dir / ("%s.log" % rid)
    src = (log_path.relative_to(CFG.root)
           if str(log_path).startswith(str(CFG.root)) else log_path)
    body = [cmd,
            "# Generated by scripts/evidence.py on %s, source log: %s"
            % (date.today(), str(src).replace("\\", "/"))]
    if args.spec_ref:
        body.append("# spec_ref: %s" % args.spec_ref)
    body += ["", "## Report Summary", *summary,
             "", "## SVA assertion summary (VCS -assert verbose native "
             "counts; zero failures required)",
             *(sva_lines
               or ["(no native summary in source log — sva_enforce off)"]),
             "", "## Key check lines", *keys, ""]
    ev_path.write_text("\n".join(body), encoding="utf-8")
    rel = str(ev_path.relative_to(CFG.root)).replace("\\", "/")
    print("evidence written: %s" % rel)

    if args.scen:
        update_row(CFG.testplan, CFG.C["tp_id"], args.scen,
                   {CFG.C["tp_status"]: "✅", CFG.C["tp_evidence"]: rel,
                    CFG.C["tp_repro"]: "`%s`" % cmd})
        print("testplan %s backfilled (✅ / evidence / repro)" % args.scen)
    else:
        update_row(CFG.bugs, CFG.C["bug_id"], args.bug,
                   {CFG.C["bug_status"]: "CLOSED", CFG.C["bug_verify"]: rel})
        print("bugs.md %s backfilled (CLOSED / verify evidence) — remember: "
              "closer ≠ fixer" % args.bug)

    rc = subprocess.run([sys.executable,
                         str(Path(__file__).resolve().parent / "docs.py"),
                         "--check"]).returncode
    sys.exit(rc)


if __name__ == "__main__":
    main()
