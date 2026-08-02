#!/usr/bin/env python3
# project-owned (NOT an upstream file). 见 doc/fw-feedback.md FB-37.
#
# docsx.py — mechanized document-assertion checker (design contract:
# doc/design-prompt/doc_mechanization.md, gated by doc/review/REV-038.md
# §A). It never encodes DUT behavior and never derives an expectation from
# doc/spec.md's *content*: its judgements come only from a documented text's
# own declarations (a marker's `check=`/`left=`/`right=`, a written-down
# in-repo path token, a hardcoded snapshot phrase) compared against a
# mechanically recomputed fact. See doc_mechanization.md C0.3.
#
# Batch 1: F1 (number assertion), F2 (in-repo path existence), F7
# (hardcoded-snapshot heuristic, warning-only per REV-038 D-3), F10
# (baseline, bidirectional) + the §12 executor safety contract.
#
# Batch 2 (this addition): F3 (bidirectional set assertion, docsx:bidiff
# marker), F4 (doc/guards.md guard table), F5 (orphan bidirectional — bug
# row <-> detail page, evidence file <-> bugs.md/testplan reference), and
# a standalone tool-marker-leak checker for BUG-0053 (not an F-family — the
# design contract's own §C disposition for BUG-0053 says "不属任何 docsx
# 族"; it is a fixed, always-on, no-baseline-exemption check because the
# markers it looks for (`</content>`/`</invoke>`) have zero legitimate
# occurrence anywhere, ever — unlike F1/F2's grandfathered historical
# debt). F6/F8/F9 remain out of scope for this file (F8/F9 land with F6 in
# a later batch; F9/§12 the executor contract already exists from batch 1
# and F3/F4 reuse it here).
#
# Reuses docs.py's table parser per doc_mechanization.md C0.2 — a second
# markdown-table parser would let the two checkers read the same table
# differently (BUG-0016 shape). docs.py itself is untouched by this file.
import argparse
import re
import shlex
import subprocess
import sys
from pathlib import Path

from docs import check_table_structure, parse_table, row_cells
from iverif_config import load_config

# ---------------------------------------------------------------------------
# C1.2 live file set (explicit allowlist — must include README.md) and C1.3
# frozen prefixes (historical record; FB-23 "frozen records are never
# rewritten" — these are exempt from F1/F2/F7, not merely path targets that
# happen to live there).
# ---------------------------------------------------------------------------
LIVE_EXPLICIT = (
    "README.md", "CLAUDE.md", "doc/bugs.md", "doc/fw-feedback.md",
    "doc/milestone.md", "doc/testplan.md", "doc/feature-matrix.md",
    "doc/coverage-waivers.md", "doc/lint-waivers.md", "doc/guards.md",
)
LIVE_GLOBS = ("doc/design-prompt/*.md", "workflow/*.md", ".claude/**/*.md")
FROZEN_PREFIXES = ("doc/review/", "doc/evidence/", "doc/archive/",
                   "doc/bugs/")


def is_frozen(rel):
    rel = rel if rel.endswith("/") else rel
    return any(rel == p.rstrip("/") or rel.startswith(p)
               for p in FROZEN_PREFIXES)


def live_files(cfg):
    """Existing files in the C1.2 live set, deterministically ordered.
    Files the set names but this checkout hasn't grown yet (doc/guards.md
    before F4 lands) are silently absent, not an error."""
    seen, out = set(), []
    for rel in LIVE_EXPLICIT:
        p = cfg.root / rel
        if p.exists() and p not in seen:
            seen.add(p)
            out.append(p)
    for pat in LIVE_GLOBS:
        for p in sorted(cfg.root.glob(pat)):
            if p.is_file() and p not in seen:
                seen.add(p)
                out.append(p)
    return sorted(out)


def relpath(cfg, p):
    return str(Path(p).relative_to(cfg.root)).replace("\\", "/")


def mask_testplan_status(cfg, text):
    """C1.2: testplan.md is live 'except the status column' (that column is
    F8's territory — F8 is a later batch, but F1/F2/F7 must not treat the
    status column as ordinary prose in the meantime). Blanks the status
    cell's *content* only; line count and non-table text are unchanged, so
    line-number loci computed from the returned text still line up with the
    real file."""
    out = []
    header_cells = None
    status_idx = None
    status_col = cfg.C.get("tp_status", "status")
    for line in text.splitlines(keepends=True):
        stripped = line.rstrip("\n")
        if not stripped.strip().startswith("|"):
            out.append(line)
            header_cells = None
            continue
        cells = row_cells(stripped)
        if header_cells is None:
            header_cells = cells
            status_idx = (header_cells.index(status_col)
                         if status_col in header_cells else None)
            out.append(line)
            continue
        if all(set(c) <= set("-: ") for c in cells):
            out.append(line)
            continue
        if status_idx is None or status_idx >= len(cells):
            out.append(line)
            continue
        masked = list(cells)
        masked[status_idx] = "x" * len(masked[status_idx])
        out.append("| " + " | ".join(masked) + " |\n")
    return "".join(out)


def read_scan_text(cfg, path):
    text = path.read_text(encoding="utf-8")
    if path == cfg.testplan:
        text = mask_testplan_status(cfg, text)
    return text


# ---------------------------------------------------------------------------
# §12 executor safety: allowlist + denylist + timeout + cwd lock. The only
# callers are F1's `check=` (this batch) and, later, F3's `left=`/`right=`
# and doc/guards.md's `check` column. C1.4: this is the *only* code path
# that ever calls subprocess — a `ref:` field (existing bug detail pages)
# is never read by anything in this file, so it structurally never reaches
# here (proven by test_docsx.py's C12.4(b) test, not merely asserted).
# ---------------------------------------------------------------------------
TIMEOUT_S = 5
ALLOWLIST_SIMPLE = {
    "grep", "egrep", "comm", "wc", "sort", "uniq", "sed", "awk", "cut",
    "tr", "head", "tail", "cat", "ls", "find", "test", "diff", "echo",
}
PY_SCRIPT_ALLOWLIST = {"scripts/docs.py", "scripts/svacheck.py"}
GIT_SUBCMD_ALLOWLIST = {"ls-files", "log", "grep", "show", "rev-parse"}
GIT_SUBCMD_DENY = {"checkout", "reset", "clean", "rm", "mv", "commit",
                   "push", "add"}
DENY_SIMPLE = {"rm", "mv", "cp", "dd", "chmod", "chown", "make", "truncate",
              "tee", "curl", "wget", "xargs", "ssh", ">", ">>", "<>"}
# A-c1 (REV-038): §12's whole point is that `check=`'s safety must not be
# re-bound to "every script under scripts/*.py is safe" — python3 may only
# invoke this fixed, already-audited, read-only pair.


def _shell_tokens(cmd):
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=True)
    lex.whitespace_split = True
    try:
        return list(lex)
    except ValueError:
        return None


def exec_gate(cmd):
    """Lexical review only — no subprocess call happens here. Returns
    (ok, reason). `reason` is empty when ok."""
    if not cmd or not cmd.strip():
        return False, "check=/left=/right= is empty"
    tokens = _shell_tokens(cmd)
    if tokens is None:
        return False, "unparsable command (unbalanced quoting)"
    if not tokens:
        return False, "empty command"
    for i, tok in enumerate(tokens):
        if tok in DENY_SIMPLE:
            return False, "denylisted token: %s" % tok
        if tok == "sed" and i + 1 < len(tokens) and \
                tokens[i + 1].startswith("-i"):
            return False, "denylisted: sed -i"
        if tok == "find" and any(t in ("-exec", "-delete") for t in tokens):
            return False, "denylisted: find -exec/-delete"
        if tok == "git" and i + 1 < len(tokens) and \
                tokens[i + 1] in GIT_SUBCMD_DENY:
            return False, "denylisted: git %s" % tokens[i + 1]
    # Contract C12.2 spells out the allowlist rule for "每个管道段的首个命令"
    # (pipe segments); it does not ban `;`/`&&`/`||` as operators (the
    # contract's own red_when example chains a denylisted word after `;`
    # and relies on the *word* being denylisted, not the separator). But a
    # non-denylisted, non-allowlisted command chained after `;`/`&&`/`||`
    # would otherwise slip past the allowlist gate entirely, so every
    # command-starting separator — not just `|` — opens a new segment that
    # is held to the same allowlisted-head rule.
    segments, cur = [], []
    for tok in tokens:
        if tok in ("|", ";", "&&", "||"):
            segments.append(cur)
            cur = []
        else:
            cur.append(tok)
    segments.append(cur)
    for seg in segments:
        if not seg:
            return False, "empty command segment"
        head = seg[0]
        if head == "python3":
            if len(seg) < 2 or seg[1] not in PY_SCRIPT_ALLOWLIST:
                return False, ("python3 may only invoke %s"
                              % sorted(PY_SCRIPT_ALLOWLIST))
        elif head == "git":
            sub = seg[1] if len(seg) > 1 else None
            if sub not in GIT_SUBCMD_ALLOWLIST:
                return False, "git subcommand not allowlisted: %r" % sub
        elif head not in ALLOWLIST_SIMPLE:
            return False, "command not allowlisted: %s" % head
    return True, ""


def _run(cmd, cwd, timeout=TIMEOUT_S, require_nonempty=True):
    """The one subprocess.run call site. Deliberately takes the raw text
    (not argv) since the whole point of the exercise is a pipe; the
    allowlist/denylist gate is what makes running it via sh -c safe, not
    argv-splitting.

    `require_nonempty`: F1's meta-check demands "退出 0、stdout 非空" (a
    count marker's command must print a number). F3's bidiff commands are
    only held to "退出 0" (design_mechanization.md F3: "两侧命令均受 §12
    执行器约束与 §F1 元检查（退出 0）") — an empty-set side (e.g. zero
    orphans) is a legitimate, common result, not a failure."""
    try:
        proc = subprocess.run(["sh", "-c", cmd], cwd=str(cwd),
                              timeout=timeout, capture_output=True,
                              text=True)
    except subprocess.TimeoutExpired:
        return False, "", "timeout after %ss" % timeout
    if proc.returncode != 0:
        return False, proc.stdout, ("exit %d: %s"
                                    % (proc.returncode,
                                       proc.stderr.strip()[:200]))
    if require_nonempty and not proc.stdout.strip():
        return False, proc.stdout, "empty stdout"
    return True, proc.stdout, ""


def exec_check(cmd, cfg, timeout=TIMEOUT_S, require_nonempty=True):
    """Gate then run. Returns (ok, stdout, reason)."""
    ok, reason = exec_gate(cmd)
    if not ok:
        return False, "", reason
    return _run(cmd, cfg.root, timeout=timeout,
               require_nonempty=require_nonempty)


# ---------------------------------------------------------------------------
# F1 — number assertion (live + frozen forms, §self meta-check both forms)
# ---------------------------------------------------------------------------
COUNT_MARKER_RE = re.compile(
    r'(?P<value>\d+)[ \t]*'
    r'<!--\s*docsx:count'
    r'(?:\s+frozen@(?P<sha>[0-9a-fA-F]+))?'
    r'(?:\s+check="(?P<cmd>[^"]*)")?'
    r'\s*-->'
)


def check_f1_text(cfg, rel, text):
    """Returns [(locus, message), ...] — every locus is a distinct marker
    occurrence, `<rel>:<line>`."""
    out = []
    for m in COUNT_MARKER_RE.finditer(text):
        line_no = text.count("\n", 0, m.start()) + 1
        locus = "%s:%d" % (rel, line_no)
        value, frozen, cmd = m.group("value"), m.group("sha"), m.group("cmd")
        if cmd is None or cmd.strip() == "":
            out.append((locus, "F1 check= missing or empty"))
            continue
        ok, stdout, reason = exec_check(cmd, cfg)
        if not ok:
            out.append((locus, "F1 meta-check failed for check=%r: %s"
                        % (cmd, reason)))
            continue
        if frozen:
            continue  # frozen: meta-check only, value not recompared
        m_int = re.search(r"\d+", stdout)
        if not m_int or int(m_int.group(0)) != int(value):
            out.append((locus, "F1 value mismatch: doc says %s, `%s` gives "
                              "%r" % (value, cmd, stdout.strip()[:120])))
    return out


# ---------------------------------------------------------------------------
# F2 — in-repo path existence
# ---------------------------------------------------------------------------
PATH_TOKEN_RE = re.compile(
    r'(?<![\w./-])'
    r'(?:(?:README\.md|doc|scripts|workflow|tb|sim|vendor|\.claude|'
    r'\.githooks)/[\w./*-]+|README\.md|CLAUDE\.md)'
)


def check_f2_text(cfg, rel, text):
    out, seen = [], set()
    for m in PATH_TOKEN_RE.finditer(text):
        tok = m.group(0).rstrip(".")
        if not tok or is_frozen(tok):
            continue
        line_no = text.count("\n", 0, m.start()) + 1
        locus = "%s:%d:%s" % (rel, line_no, tok)
        if locus in seen:
            continue
        seen.add(locus)
        if "*" in tok:
            if not list(cfg.root.glob(tok)):
                out.append((locus, "F2 dead in-repo path reference (glob, "
                                  "0 matches): %s" % tok))
            continue
        if not (cfg.root / tok).exists():
            out.append((locus, "F2 dead in-repo path reference: %s" % tok))
    return out


# ---------------------------------------------------------------------------
# F3 — bidirectional set assertion (docsx:bidiff marker). Generic engine:
# `left`/`right` each produce a line-based set; either direction's set
# difference being non-empty is red. This is the common-mode "the F5
# orphan pairs are conceptually a bidiff" primitive (doc_mechanization.md
# F3:90) — F5 itself does not go through this marker parser (F5's pairs
# are always-on structural checks over fixed data sources, not opt-in
# prose annotations; see F5 section below), but shares the same
# left-vs-right set-diff shape.
# ---------------------------------------------------------------------------
BIDIFF_MARKER_RE = re.compile(
    r'<!--\s*docsx:bidiff\s+left="(?P<left>[^"]*)"\s+right="(?P<right>[^"]*)"'
    r'\s*-->'
)


def _lineset(stdout):
    return {l for l in (x.strip() for x in stdout.splitlines()) if l}


def check_f3_text(cfg, rel, text):
    """Returns [(locus, message), ...]. Each marker occurrence contributes
    up to two loci (one per non-empty direction) so F10 baseline rows can
    target either side independently (design contract: 'both directions
    feed the exit code')."""
    out = []
    for m in BIDIFF_MARKER_RE.finditer(text):
        line_no = text.count("\n", 0, m.start()) + 1
        cmd_l, cmd_r = m.group("left"), m.group("right")
        ok_l, out_l, reason_l = exec_check(cmd_l, cfg, require_nonempty=False)
        if not ok_l:
            out.append(("%s:%d:left" % (rel, line_no),
                        "F3 meta-check failed for left=%r: %s"
                        % (cmd_l, reason_l)))
            continue
        ok_r, out_r, reason_r = exec_check(cmd_r, cfg, require_nonempty=False)
        if not ok_r:
            out.append(("%s:%d:right" % (rel, line_no),
                        "F3 meta-check failed for right=%r: %s"
                        % (cmd_r, reason_r)))
            continue
        set_l, set_r = _lineset(out_l), _lineset(out_r)
        lr = sorted(set_l - set_r)
        rl = sorted(set_r - set_l)
        if lr:
            out.append(("%s:%d:L-R" % (rel, line_no),
                        "F3 bidiff left-right non-empty (%d): %s"
                        % (len(lr), ", ".join(lr[:5]))))
        if rl:
            out.append(("%s:%d:R-L" % (rel, line_no),
                        "F3 bidiff right-left non-empty (%d): %s"
                        % (len(rl), ", ".join(rl[:5]))))
    return out


# ---------------------------------------------------------------------------
# F7 — hardcoded snapshot phrase (warning only, REV-038 D-3)
# ---------------------------------------------------------------------------
SNAPSHOT_RE = re.compile(r"当前已(?:改|迁移|完成|修复).{0,40}[、,，]")


def check_f7_text(rel, text):
    warns = []
    for m in SNAPSHOT_RE.finditer(text):
        line_start = text.rfind("\n", 0, m.start()) + 1
        line_end = text.find("\n", m.end())
        line = text[line_start:(line_end if line_end != -1 else len(text))]
        if "docsx:" in line or "make next" in line or "make handoff" in line:
            continue
        line_no = text.count("\n", 0, m.start()) + 1
        warns.append("F7 hardcoded snapshot phrase (advisory, not counted "
                     "toward the exit code): %s:%d: %s"
                     % (rel, line_no, line.strip()[:100]))
    return warns


# ---------------------------------------------------------------------------
# F4 — doc/guards.md guard table (C1.1: "guard/baseline 走结构化表，不用内联
# 标记" — no marker parsing here, this reads the structured table directly,
# same as F10's baseline table).
# ---------------------------------------------------------------------------
GUARD_COLS = ("id", "bugs", "type", "paths", "check", "note")
GUARD_TYPES = ("script", "checklist")


def load_guards(cfg):
    if not cfg.guards.exists():
        return []
    return parse_table(cfg.guards)


def check_f4(cfg, guard_rows):
    """Returns (viol, warns). `viol` is F10-governed (keyed by locus,
    family "F4") — a new `type: checklist` row with no baseline row is red
    (REV-035 §Q3(b): checklist is a mechanization TODO); the A-c5 exception
    channel is simply "the checklist row's locus has a baseline row" (F10
    already treats a baselined violation as suppressed — no separate A-c5
    code path needed). Non-ASCII `paths` is likewise F10-governed (a
    genuinely permanent exemption, if ever needed, is still expressed the
    same way: a baseline row). `paths` glob with zero matches is a
    *warning* only (design contract F4: "REV-037 的量化依据...作 warning
    可以" — the id half of BUG-0061, applied per-guard here rather than
    per-file as docs.py's cmd_guards does). Table-shape validity (column
    count, dup ids) is `check_table_structure`'s job, called by cmd_check
    directly — not duplicated here."""
    viol, warns = {}, []
    for row in guard_rows:
        gid = row.get("id", "").strip()
        gtype = row.get("type", "").strip()
        paths_cell = row.get("paths", "")
        check_cell = row.get("check", "").strip()
        if gtype not in GUARD_TYPES:
            viol["doc/guards.md:%s:type" % gid] = (
                "F4 guard %s: type %r is not one of %s"
                % (gid, gtype, "/".join(GUARD_TYPES)))
        if any(ord(c) > 127 for c in paths_cell):
            viol["doc/guards.md:%s:paths" % gid] = (
                "F4 guard %s: paths cell contains non-ASCII: %r"
                % (gid, paths_cell))
        if gtype == "checklist":
            viol["doc/guards.md:%s" % gid] = (
                "F4 guard %s: type: checklist with no baseline row "
                "(REV-035 §Q3(b) — new checklist guards must be type: "
                "script unless rev-authorized via a baseline rev_ref, "
                "A-c5)" % gid)
        elif gtype == "script":
            if not check_cell or check_cell == "-":
                viol["doc/guards.md:%s:check" % gid] = (
                    "F4 guard %s: type: script but check= is empty" % gid)
            else:
                ok, _, reason = exec_check(check_cell, cfg,
                                           require_nonempty=False)
                if not ok:
                    viol["doc/guards.md:%s:check" % gid] = (
                        "F4 guard %s: check= not executable: %s"
                        % (gid, reason))
        globs = [g for g in re.split(r"[,\s]+", paths_cell.strip()) if g]
        for g in globs:
            if any(ord(c) > 127 for c in g):
                continue  # already flagged above; do not double-warn
            if "*" not in g and not (cfg.root / g).exists():
                warns.append("F4 guard %s: paths token has zero matches "
                             "(no glob, path does not exist): %s"
                             % (gid, g))
            elif "*" in g and not list(cfg.root.glob(g)):
                warns.append("F4 guard %s: paths token has zero matches "
                             "(glob): %s" % (gid, g))
    return viol, warns


# ---------------------------------------------------------------------------
# F5 — orphan bidirectional. Always-on structural checks over fixed data
# sources (bug rows/pages, evidence files/references) — not opt-in prose
# markers (see F3's docstring). docs.py already covers the page -> row
# direction (a referenced-but-missing page errors); this adds the row ->
# page direction (BUG-0067: a bug row with no page went unreported) and
# both evidence directions (BUG-0060: an orphan .log written to
# doc/evidence/ went unreported).
# ---------------------------------------------------------------------------
def check_f5_bug_pages(cfg):
    """bug row (bugs.md + archive) -> doc/bugs/<id>.md must exist."""
    viol = {}
    if not (cfg.bugs.exists() and cfg.bugs_archive.exists()):
        return viol
    rows = parse_table(cfg.bugs) + parse_table(cfg.bugs_archive)
    for r in rows:
        bid = r.get(cfg.C["bug_id"], "").strip()
        if not bid:
            continue
        if not (cfg.bug_pages / ("%s.md" % bid)).exists():
            viol["bugs.md:%s" % bid] = (
                "F5 bug row %s has no detail page doc/bugs/%s.md (BUG-0067)"
                % (bid, bid))
    return viol


EVIDENCE_LOG_REF_RE = re.compile(r'doc/evidence/[\w./-]+\.log')


def check_f5_evidence(cfg):
    """doc/evidence/**/*.log <-> a reference somewhere in bugs.md(+archive)
    or testplan.md, both directions (BUG-0060). No early return on a
    missing evidence dir — an empty disk set still needs to be diffed
    against refs, or a dangling reference (right-only) would go silently
    unreported."""
    viol = {}
    disk = ({relpath(cfg, p) for p in cfg.evidence_dir.rglob("*.log")}
           if cfg.evidence_dir.exists() else set())
    ref_text = ""
    for p in (cfg.bugs, cfg.bugs_archive, cfg.testplan):
        if p.exists():
            ref_text += p.read_text(encoding="utf-8")
    refs = set(EVIDENCE_LOG_REF_RE.findall(ref_text))
    for f in sorted(disk - refs):
        viol["evidence:%s" % f] = (
            "F5 evidence file not referenced by bugs.md(+archive)/"
            "testplan.md: %s" % f)
    for r in sorted(refs - disk):
        viol["ref:%s" % r] = (
            "F5 dangling evidence reference (file does not exist): %s" % r)
    return viol


# ---------------------------------------------------------------------------
# BUG-0053 — tool-marker leak. Not an F-family (design contract §C: "不属
# 任何 docsx 族"): a subagent's `</content>`/`</invoke>` tags leaking into
# a committed record. Whole-line match only, fenced code blocks excluded
# (a fenced block quoting the marker as an example — as this very file's
# docstrings and doc/bugs/BUG-0053.md's own narrative do — must not
# self-trip the check). No baseline path: unlike F1/F2's grandfathered
# historical debt, this marker has zero legitimate occurrence anywhere, at
# any time — REV-037/REV-038 both settled on "must not exist", never
# "exists here for a reason".
# ---------------------------------------------------------------------------
TOOL_MARKER_LINES = ("</content>", "</invoke>")


def check_tool_marker_leak(rel, text):
    out = []
    in_fence = False
    for i, line in enumerate(text.splitlines(), start=1):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        if stripped in TOOL_MARKER_LINES:
            out.append(("%s:%d" % (rel, i),
                        "BUG-0053 tool-marker leak: whole line is %r"
                        % stripped))
    return out


def check_tool_marker_leak_tree(cfg):
    """paths: doc/**/*.md (doc/bugs/BUG-0053.md's own guard field, once
    migrated) — deliberately every markdown file under doc/, including
    the C1.3 frozen prefixes: the incident this guards (REV-033.md, a
    doc/review/ file) *was* frozen, and a frozen file is not exempt from
    "this should never have been written", only from "must be rewritten
    to match a moving target"."""
    out = []
    for p in sorted(cfg.root.glob("doc/**/*.md")):
        rel = relpath(cfg, p)
        text = p.read_text(encoding="utf-8", errors="replace")
        out.extend(check_tool_marker_leak(rel, text))
    return out


# ---------------------------------------------------------------------------
# F10 — baseline (bidirectional), and the report printer
# ---------------------------------------------------------------------------
BASELINE_COLS = ("id", "family", "locus", "rev_ref")


def load_baseline(cfg):
    if not cfg.docsx_baseline.exists():
        return []
    return parse_table(cfg.docsx_baseline)


def check_f10(baseline_rows, viol_by_family):
    """Pure function (no filesystem access) so it is unit-testable against
    synthetic baseline/violation data, independent of a real live-file
    scan. Returns a list of error strings."""
    errors = []
    seen_ids = set()
    baseline_by_family = {}
    for row in baseline_rows:
        rid = row.get("id", "").strip()
        fam = row.get("family", "").strip()
        locus = row.get("locus", "").strip()
        rev_ref = row.get("rev_ref", "").strip()
        if rid in seen_ids:
            errors.append("docsx-baseline.md duplicate id: %s" % rid)
        seen_ids.add(rid)
        if not rev_ref:
            errors.append("docsx-baseline.md %s: rev_ref is empty (an "
                          "unauthorized exemption is not an exemption)"
                          % (rid or locus))
        baseline_by_family.setdefault(fam, {})[locus] = rid or "?"
    for fam, viol in viol_by_family.items():
        base = baseline_by_family.get(fam, {})
        cur_loci, base_loci = set(viol), set(base)
        for locus in sorted(cur_loci - base_loci):
            errors.append("%s violation not in docsx-baseline.md: %s — %s"
                          % (fam, locus, viol[locus]))
        for locus in sorted(base_loci - cur_loci):
            errors.append("docsx-baseline.md stale entry %s (%s locus %s) "
                          "— violation no longer present, prune it"
                          % (base[locus], fam, locus))
    return errors


def report(errors, warns):
    for w in warns:
        print("[warn] %s" % w)
    if errors:
        for e in errors:
            print("[FAIL] %s" % e)
        print("\ndocsx-check failed: %d problem(s)" % len(errors))
        return 1
    print("docsx-check passed")
    return 0


# ---------------------------------------------------------------------------
# orchestration
# ---------------------------------------------------------------------------
def collect_violations(cfg):
    """Returns (viol_by_family, warns) by scanning the whole live file set
    once, plus the always-on structural families (F4/F5) that do not
    depend on any one file's prose. Split out from cmd_check so
    `--kill-proof` and tests can reuse it without re-parsing argv."""
    f1, f2, f3, warns = {}, {}, {}, []
    for f in live_files(cfg):
        rel = relpath(cfg, f)
        text = read_scan_text(cfg, f)
        for locus, msg in check_f1_text(cfg, rel, text):
            f1[locus] = msg
        for locus, msg in check_f2_text(cfg, rel, text):
            f2[locus] = msg
        for locus, msg in check_f3_text(cfg, rel, text):
            f3[locus] = msg
        warns.extend(check_f7_text(rel, text))
    f4, f4_warns = check_f4(cfg, load_guards(cfg))
    warns.extend(f4_warns)
    f5 = {}
    f5.update(check_f5_bug_pages(cfg))
    f5.update(check_f5_evidence(cfg))
    return {"F1": f1, "F2": f2, "F3": f3, "F4": f4, "F5": f5}, warns


def cmd_check(cfg):
    viol_by_family, warns = collect_violations(cfg)
    errors = []
    if cfg.docsx_baseline.exists():
        check_table_structure(cfg.docsx_baseline, errors)
    if cfg.guards.exists():
        check_table_structure(cfg.guards, errors)
    errors.extend(check_f10(load_baseline(cfg), viol_by_family))
    for locus, msg in check_tool_marker_leak_tree(cfg):
        errors.append(msg + " (" + locus + ")")
    return report(errors, warns)


def cmd_guards(cfg, paths):
    """C13.3: `make guards` now reads `doc/guards.md` (F4's table) instead
    of `docs.py`'s `## regression_guard` page scan — the table is the guard
    load-bearing structure now that F4 has landed. Output *contract* is
    kept identical to `docs.py`'s `cmd_guards` (design contract C13.3:
    "make guards FILES=... 的输出契约保持"): `"== <label> guard (hit:
    ...) =="` per match, a trailing `"N guard(s) matched"` line — every
    existing `grep '== BUG-XXXX guard'`-shaped consumer (REV-037 S1-S3,
    the dispatch SKILL self-check, milestone signoff records) keeps
    working unchanged. `<label>` is the row's `bugs` cell (not its `id`)
    so a single-bug row's header text is still `== BUG-0043 guard ==`,
    byte-identical to the page-scan era. 见 doc/fw-feedback.md FB-38."""
    import fnmatch
    hits = 0
    for row in load_guards(cfg):
        label = row.get("bugs", "").strip()
        globs = [g for g in re.split(r"[,\s]+", row.get("paths", "").strip())
                if g]
        matched = [p for p in paths if any(fnmatch.fnmatch(p, g)
                                           for g in globs)]
        if matched:
            hits += 1
            print("== %s guard (hit: %s) ==" % (label, " ".join(matched)))
            print("id: %s | type: %s | check: %s"
                 % (row.get("id", ""), row.get("type", ""),
                    row.get("check", "")))
            print(row.get("note", "") + "\n")
    print("%d guard(s) matched" % hits)


def cmd_kill_proof(cfg):
    """§12 / C12.4 self-injury proof, run on demand (`--kill-proof`) as the
    single reproducible command named in doc/bugs.md's KILL-0006 row
    min_repro (KILL rows are hand-registered, not routed through
    `scripts/evidence.py --bug` — its BUG_ID_RE requires a `BUG-` prefix
    and always writes status CLOSED, neither of which fits a KILL row;
    see the archived KILL-0001..0005 rows for the same convention).
    Spies on subprocess.run (module-level, so it also catches calls made
    from inside this file) to prove *zero* calls happen, not just that the
    end result looks right."""
    calls = []
    orig_run = subprocess.run

    def spy(*a, **kw):
        calls.append(a[0] if a else kw.get("args"))
        return orig_run(*a, **kw)

    subprocess.run = spy
    try:
        ok, _, _ = exec_check("grep -c x doc/bugs.md && rm -rf sim/out", cfg)
        proof_a = (not ok) and (len(calls) == 0)
        calls.clear()
        sample = "ref: cd sim && make clean && make lint-diff\n"
        check_f1_text(cfg, "synthetic.md", sample)
        check_f2_text(cfg, "synthetic.md", sample)
        proof_b = len(calls) == 0
    finally:
        subprocess.run = orig_run
    if proof_a and proof_b:
        print("[KILL-A] rm-injection rejected pre-exec, 0 subprocess calls")
        print("[KILL-B] ref: text never reaches the executor, 0 subprocess "
             "calls")
        print("[KILL-DOCSX-12] both self-injury proofs hold — the executor "
             "only ever receives docsx:count/docsx:bidiff check=/left=/"
             "right= values, never a bug-page `ref:` field")
        return 0
    print("[FAIL] KILL proof A=%s B=%s" % (proof_a, proof_b))
    return 1


def main():
    parser = argparse.ArgumentParser(
        description="docsx: prose-level document assertion checker "
                   "(F1/F2/F3/F4/F5/F7/F10 + BUG-0053 tool-marker leak)")
    parser.add_argument("--check", action="store_true",
                        help="run the live file set through F1/F2/F3/F7, "
                             "the structural F4/F5 checks and the "
                             "BUG-0053 tool-marker scan, reconcile against "
                             "docsx-baseline.md (F10)")
    parser.add_argument("--kill-proof", action="store_true",
                        help="§12 executor-safety self-injury proof "
                             "(doc/bugs.md KILL-0006's min_repro command)")
    parser.add_argument("--guards", nargs="+", metavar="PATH",
                        help="print doc/guards.md rows whose paths bind "
                             "these files (C13.3 — replaces docs.py "
                             "--guards as make guards' target)")
    args = parser.parse_args()
    cfg = load_config()
    # docsx_baseline/guards are not part of iverif_config.Config (docs.py
    # owns that file); attach them here rather than editing the canon
    # Config class.
    cfg.docsx_baseline = cfg.root / "doc" / "docsx-baseline.md"
    cfg.guards = cfg.root / "doc" / "guards.md"
    if args.kill_proof:
        sys.exit(cmd_kill_proof(cfg))
    if args.check:
        sys.exit(cmd_check(cfg))
    if args.guards:
        cmd_guards(cfg, args.guards)
        return
    parser.print_help()


if __name__ == "__main__":
    main()
