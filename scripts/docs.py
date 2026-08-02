#!/usr/bin/env python3
# Mechanical layer of the doc memory system: handoff summary / structure
# guards / rolling archive / spec pinning / check & chain queries.
# Principle: mechanics to scripts, semantics to humans/agents. This script
# only counts, validates, and moves text — it never writes semantic content.
#
# Canonical home: iverif-workflow/scripts/docs.py. This is an upstream file
# in a cloned project — local edits are your own to maintain; `git
# cherry-pick` interesting upstream commits if you want them.
import argparse
import hashlib
import json
import re
import signal
import subprocess
import sys
from pathlib import Path

from iverif_config import (BUG_ACCEPTED_RE, BUG_DONE_STATES, BUG_STATES,
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

# ---------------------------------------------------------------------------
# FB-40 (2026-08-03): scripts/docsx.py (project-owned) dissolved into this
# canon file. F1 (number assertion), F3 (bidirectional set assertion via the
# docsx:bidiff marker), F7 (hardcoded-snapshot heuristic) and F10 (baseline,
# bidirectional) + the §12 lexical executor they all depended on retired —
# the checked object (hand-copied derivable facts) is now banned outright by
# workflow/records.md's "derived facts are never hand-copied" contract, and
# F7 never caught a real defect. F2 (in-repo path existence), F4 (doc/
# guards.md guard table) and F5 (orphan bidirectional: bug row <-> detail
# page, evidence file <-> reference) survive and land here. BUG-0053's
# tool-marker-leak check (never an F-family) also lands here, unchanged
# (always-on, no exemption channel — the markers it looks for have zero
# legitimate occurrence anywhere). See doc/fw-feedback.md FB-40 for the full
# disposition (what was cut, what was merged, how the F10 baseline debt was
# retired without regressing `make check`).
#
# C1.2 live file set (must include README.md) + C1.3 frozen prefixes
# (historical record; FB-23 "frozen records are never rewritten").
F2_LIVE_EXPLICIT = (
    "README.md", "CLAUDE.md", "doc/bugs.md", "doc/fw-feedback.md",
    "doc/milestone.md", "doc/testplan.md", "doc/feature-matrix.md",
    "doc/coverage-waivers.md", "doc/lint-waivers.md", "doc/guards.md",
)
F2_LIVE_GLOBS = ("doc/design-prompt/*.md", "workflow/*.md", ".claude/**/*.md")
FROZEN_PREFIXES = ("doc/review/", "doc/evidence/", "doc/archive/",
                   "doc/bugs/")


def is_frozen(rel):
    return any(rel == p.rstrip("/") or rel.startswith(p)
               for p in FROZEN_PREFIXES)


def relpath(cfg, p):
    return str(Path(p).relative_to(cfg.root)).replace("\\", "/")


def f2_live_files(cfg):
    """Existing files in the F2 live set, deterministically ordered. Files
    the set names but this checkout hasn't grown yet are silently absent,
    not an error."""
    seen, out = set(), []
    for rel in F2_LIVE_EXPLICIT:
        p = cfg.root / rel
        if p.exists() and p not in seen:
            seen.add(p)
            out.append(p)
    for pat in F2_LIVE_GLOBS:
        for p in sorted(cfg.root.glob(pat)):
            if p.is_file() and p not in seen:
                seen.add(p)
                out.append(p)
    return sorted(out)


# F2 — in-repo path existence. Exemptions (both added by FB-40, replacing
# the retired F10 baseline table): (a) a token inside a fenced code block
# (```...```) is a worked example, not a live reference — auto-skipped;
# (b) a `<!-- docsx:skip <token> [<token> ...] -->` marker anywhere in a
# live file exempts those exact literal tokens for every occurrence in that
# same file (not a blanket line/file skip — narrowly scoped to the named
# strings). Total inline markers in this repo: 5 (doc/fw-feedback.md FB-40
# delivery report enumerates each).
PATH_TOKEN_RE = re.compile(
    r'(?<![\w./-])'
    r'(?:(?:README\.md|doc|scripts|workflow|tb|sim|vendor|\.claude|'
    r'\.githooks)/[\w./*-]+|README\.md|CLAUDE\.md)'
)
DOCSX_SKIP_RE = re.compile(r'<!--\s*docsx:skip((?:\s+\S+)*)\s*-->')


def _strip_fenced_lines(text):
    """Blank every line inside a ``` ... ``` fence (including the fence
    markers themselves) while preserving line count, so F2 locus line
    numbers computed against the result still line up with the real file."""
    out = []
    in_fence = False
    for line in text.split("\n"):
        if line.strip().startswith("```"):
            in_fence = not in_fence
            out.append("")
            continue
        out.append("" if in_fence else line)
    return "\n".join(out)


def _docsx_skip_tokens(text):
    tokens = set()
    for m in DOCSX_SKIP_RE.finditer(text):
        tokens.update(m.group(1).split())
    return tokens


def check_f2_text(cfg, rel, text):
    out, seen = [], set()
    skip = _docsx_skip_tokens(text)
    masked = _strip_fenced_lines(text)
    for m in PATH_TOKEN_RE.finditer(masked):
        tok = m.group(0).rstrip(".")
        if not tok or is_frozen(tok) or tok in skip:
            continue
        line_no = masked.count("\n", 0, m.start()) + 1
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


def check_f2(cfg, errors):
    for f in f2_live_files(cfg):
        rel = relpath(cfg, f)
        text = f.read_text(encoding="utf-8", errors="replace")
        for locus, msg in check_f2_text(cfg, rel, text):
            errors.append(msg + " (" + locus + ")")


# F4 — doc/guards.md guard table. The F10-governed "a new type: checklist
# row needs a baseline-authorized rev_ref (REV-035 §Q3(b)/A-c5)" rule
# retired with F10 itself — it had no meaning standalone (every checklist
# row was unconditionally "in violation" until F10's baseline cross-
# reference silenced it; there is no successor authorization channel, and
# inventing one to re-litigate 49 already-rev-approved rows is out of this
# card's scope, see doc/fw-feedback.md FB-40). What remains: `type` must be
# one of GUARD_TYPES, `paths` must be ASCII (BUG-0061), and a `type: script`
# row's `check` cell must be non-empty (§12's executor retired with F1/F3/
# F7, so this is presence-only now, not an executability proof).
GUARD_TYPES = ("script", "checklist")


def load_guards(cfg):
    if not cfg.guards.exists():
        return []
    return parse_table(cfg.guards)


def check_f4(cfg, guard_rows):
    """Returns (viol, warns): viol is keyed by locus (dict, for callers
    that want to dedupe/inspect); warns is a flat list. `paths` glob with
    zero matches is a warning only (design contract F4 / REV-037)."""
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
        if gtype == "script" and (not check_cell or check_cell == "-"):
            viol["doc/guards.md:%s:check" % gid] = (
                "F4 guard %s: type: script but check= is empty" % gid)
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


def check_f4_gate(cfg, errors, warns):
    if not cfg.guards.exists():
        return
    check_table_structure(cfg.guards, errors)
    viol, f4_warns = check_f4(cfg, load_guards(cfg))
    for locus, msg in viol.items():
        errors.append(msg + " (" + locus + ")")
    warns.extend(f4_warns)


# F5 — orphan bidirectional: bug row <-> doc/bugs/<id>.md detail page (BUG-
# 0067), evidence file <-> bugs.md(+archive)/testplan.md reference (BUG-
# 0060). Two accepted-debt channels replace the retired F10 baseline table,
# both narrower than a general-purpose baseline mechanism:
#   (1) suspect=doc rows (workflow/bugs.md's FB-39-defined "fix-in-passing"
#       lane) do not require a detail page at all (CLAUDE.md/workflow/
#       bugs.md's own contract — a doc-bookkeeping fix-in-passing row is
#       explicitly "no detail page unless the RCA is non-obvious").
#   (2) a fixed, closed allowlist of the exact ids/paths REV-038 §B.1 swept
#       as pre-existing debt when F5 first landed in docsx.py — still
#       genuinely open (verified 2026-08-03: none of these ids/files have
#       since gained a page/reference), never appended to. A *new* row or
#       orphan is not in this set and reddens immediately (proven by the
#       card's self-injury demonstration, scripts/tests/test_docs.py).
F5_LEGACY_BUG_IDS = frozenset({
    "BUG-0002", "BUG-0003", "BUG-0004", "BUG-0005", "BUG-0006", "BUG-0035",
    "BUG-0049", "BUG-0050", "BUG-0051", "BUG-0052", "BUG-0053", "BUG-0054",
    "BUG-0055", "BUG-0058", "BUG-0060", "BUG-0061", "BUG-0065", "BUG-0067",
    "BUG-0069", "BUG-0070", "BUG-0071",
    "KILL-0001", "KILL-0002", "KILL-0003", "KILL-0004", "KILL-0005",
    "KILL-0006",
})
F5_LEGACY_EVIDENCE = frozenset({
    "doc/evidence/v0.1.0/M1-01.log",
    "doc/evidence/v0.2.0/M2-CFG01.log",
    "doc/evidence/v0.2.0/M2-WO01.log",
    "doc/evidence/v0.4.17/M4-BP02.log",
    "doc/evidence/v0.4.23/M1-01.log",
    "doc/evidence/v0.4.24/M1-01.log",
    "doc/evidence/v0.4.27/M3-DE01.log",
})
F5_LEGACY_DANGLING_REF = frozenset({"doc/evidence/v0.4.38/0048.log"})
EVIDENCE_LOG_REF_RE = re.compile(r'doc/evidence/[\w./-]+\.log')


def check_f5_bug_pages(cfg):
    """bug row (bugs.md + archive) -> doc/bugs/<id>.md must exist."""
    viol = {}
    if not (cfg.bugs.exists() and cfg.bugs_archive.exists()):
        return viol
    suspect_col = cfg.C.get("bug_suspect", "suspect")
    rows = parse_table(cfg.bugs) + parse_table(cfg.bugs_archive)
    for r in rows:
        bid = r.get(cfg.C.get("bug_id", "id"), "").strip()
        if not bid:
            continue
        if (cfg.bug_pages / ("%s.md" % bid)).exists():
            continue
        if r.get(suspect_col, "").strip().lower() == "doc":
            continue
        if bid in F5_LEGACY_BUG_IDS:
            continue
        viol["bugs.md:%s" % bid] = (
            "F5 bug row %s has no detail page doc/bugs/%s.md (BUG-0067)"
            % (bid, bid))
    return viol


def check_f5_evidence(cfg):
    """doc/evidence/**/*.log <-> a reference somewhere in bugs.md(+archive)
    or testplan.md, both directions (BUG-0060)."""
    viol = {}
    disk = ({relpath(cfg, p) for p in cfg.evidence_dir.rglob("*.log")}
           if cfg.evidence_dir.exists() else set())
    ref_text = ""
    for p in (cfg.bugs, cfg.bugs_archive, cfg.testplan):
        if p.exists():
            ref_text += p.read_text(encoding="utf-8")
    refs = set(EVIDENCE_LOG_REF_RE.findall(ref_text))
    for f in sorted(disk - refs):
        if f in F5_LEGACY_EVIDENCE:
            continue
        viol["evidence:%s" % f] = (
            "F5 evidence file not referenced by bugs.md(+archive)/"
            "testplan.md: %s" % f)
    for r in sorted(refs - disk):
        if r in F5_LEGACY_DANGLING_REF:
            continue
        viol["ref:%s" % r] = (
            "F5 dangling evidence reference (file does not exist): %s" % r)
    return viol


# BUG-0053 — tool-marker leak. Not an F-family: a subagent's `</content>`/
# `</invoke>` tags leaking into a committed record. Whole-line match only,
# fenced code blocks excluded. No exemption channel — these markers have
# zero legitimate occurrence anywhere, at any time.
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
            out.append("BUG-0053 tool-marker leak: whole line is %r (%s:%d)"
                       % (stripped, rel, i))
    return out


def check_tool_marker_leak_tree(cfg, errors):
    for p in sorted(cfg.root.glob("doc/**/*.md")):
        rel = relpath(cfg, p)
        text = p.read_text(encoding="utf-8", errors="replace")
        errors.extend(check_tool_marker_leak(rel, text))


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


def check_table_structure(path, errors):
    """FAIL any data row whose cell count differs from its header's: an
    unescaped `|` inside a cell shifts every later column, and state gates
    then silently read the wrong cells (pulp FB-14, BUG-0016)."""
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
            errors.append("%s:%d row has %d cells, header has %d — "
                          "escape literal | in cells as \\|"
                          % (path.name, i, len(cells), header_n))


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
        if not up.startswith("CMD:") and ("TEST" not in up
                                          or "SEED" not in up):
            errors.append("%s evidence line 1 is not a replay command "
                          "(needs TEST and SEED, or CMD: for non-sim "
                          "re-verification): %s" % (owner, ev))


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
                          "(workflow/bugs.md)"
                          % (page.name, name))
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
    # it so the check reflects real matches. NOTE: existence only — the
    # file's recorded verdict (PASS/CONDITIONAL/REJECTED) is deliberately
    # never machine-read (see milestone_bugs_terminal()'s docstring, BUG-0054
    # / doc/fw-feedback.md FB-31): doc/milestone.md:3 treats "rev signoff
    # record" as one of two independent gates, not something a script judges.
    pattern = CFG.signoff_glob.format(m=mnum)
    return any(any(d.glob(pattern)) for d in milestone_evidence_dirs(mnum))


def milestone_bugs_terminal(mnum):
    """Bug-terminal machine condition (doc/milestone.md:3's "bugs 终态或未到期
    ACCEPTED"). Extracted out of cmd_signoff so cmd_handoff's `--next` can
    reuse the exact same evaluator instead of maintaining its own — narrower
    — private copy: before this, `--next` never looked at bug status at all,
    so it could report a milestone's "hard conditions met" while bugs were
    still OPEN (BUG-0054). Returns (ok, detail); detail is empty when ok,
    else a " — active: ..." / " — accepted debt due: ..." trailer identical
    to cmd_signoff's condition-3 line. 见 doc/fw-feedback.md FB-31."""
    bug_rows = parse_table(CFG.bugs)
    active, due = [], []
    for r in bug_rows:
        st = r.get(CFG.C["bug_status"], "").strip()
        if st in BUG_DONE_STATES:
            continue
        acc = BUG_ACCEPTED_RE.match(st)
        if acc:
            # Unexpired accepted debt passes this signoff; due-or-overdue
            # debt blocks it — otherwise ACCEPTED becomes the new rug.
            if int(acc.group(1)) <= int(mnum):
                due.append("%s %s" % (r.get(CFG.C["bug_id"], "?"), st))
            continue
        active.append(r.get(CFG.C["bug_id"], "?"))
    closure_errs = []
    for r in bug_rows:
        if r.get(CFG.C["bug_status"], "").strip() == "CLOSED":
            check_evidence(r.get(CFG.C["bug_verify"], ""),
                           "bug %s" % r.get(CFG.C["bug_id"], "?"),
                           closure_errs)
    ok = not active and not due and not closure_errs
    detail = ""
    if active:
        detail += " — active: " + ", ".join(active)
    if due:
        detail += " — accepted debt due: " + ", ".join(due)
    if closure_errs:
        detail += " — " + "; ".join(closure_errs)
    return ok, detail


def cmd_handoff():
    version, milestone = read_version()
    first = CFG.status.read_text(encoding="utf-8").splitlines()[0]
    st = json.loads(first)
    _, blocks = split_log_blocks(CFG.log.read_text(encoding="utf-8"))
    tp_rows = parse_table(CFG.testplan)
    fm_rows = parse_table(CFG.feature_matrix)

    print("== %s handoff ==" % CFG.project)
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

    for t in (CFG.testplan, CFG.feature_matrix, CFG.bugs, CFG.waivers):
        check_table_structure(t, errors)

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
    # (blocks the "bumped but never wrote the handoff block" failure).
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
    _, cur_ms = read_version()
    cur_m = int(cur_ms.lstrip("M")) if cur_ms.lstrip("M").isdigit() else 0
    for r in bug_rows:
        bid = r.get(CFG.C["bug_id"], "?")
        st = r.get(CFG.C["bug_status"], "").strip()
        acc = BUG_ACCEPTED_RE.match(st)
        if st not in BUG_STATES and not acc:
            errors.append("bugs.md %s state invalid: %r (legal: %s or "
                          "ACCEPTED@M<n>)"
                          % (bid, st, "/".join(BUG_STATES)))
        if acc:
            if "REV-" not in " ".join(r.values()):
                errors.append("bugs.md %s is %s but the row names no REV "
                              "record — acceptance needs a rev-signed "
                              "rationale" % (bid, st))
            if int(acc.group(1)) < cur_m:
                errors.append("bugs.md %s %s expired (current %s) — "
                              "re-adjudicate: fix now or WONTFIX via rev"
                              % (bid, st, cur_ms))
        if st in BUG_STATES_NEED_COMMIT and \
                not r.get(CFG.C["bug_fix_commit"], "").strip("-` "):
            errors.append("bugs.md %s is %s but its fix reference "
                          "(fix_commit column) is empty — local sha, "
                          "repo@sha, or env: <change>" % (bid, st))
        if st == "CLOSED":
            check_evidence(r.get(CFG.C["bug_verify"], ""),
                           "bugs.md %s closure" % bid, errors)

    # Bug detail pages, both directions: every bug row must have a page
    # (F5/BUG-0067 — replaces the old, weaker "text explicitly mentions
    # doc/bugs/X.md" scan, which missed rows that never self-cite their own
    # page path; suspect=doc rows and the fixed REV-038 §B.1 legacy-debt set
    # are exempt, see check_f5_bug_pages's docstring / FB-40); no orphan
    # pages without a table row (including archived rows). Terminal bugs'
    # pages must satisfy the failure-record schema when enforced.
    for locus, msg in check_f5_bug_pages(CFG).items():
        errors.append(msg + " (" + locus + ")")
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

    # FB-40 — merged from scripts/docsx.py: F2 (in-repo path existence over
    # free prose, not just table cells), F4 (doc/guards.md guard table),
    # F5's evidence-file direction (bug-page direction is above), and the
    # BUG-0053 tool-marker-leak scan (always-on, no exemption channel).
    check_f2(CFG, errors)
    check_f4_gate(CFG, errors, warns)
    for locus, msg in check_f5_evidence(CFG).items():
        errors.append(msg + " (" + locus + ")")
    check_tool_marker_leak_tree(CFG, errors)

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
                    "workflow/bugs.md); DUT suspicion needs rev signoff",
        "bug_fixing": "%(bid)s FIXING → fill root cause + fix commit, then "
                      "set FIX_READY",
        "bug_fix_ready": "%(bid)s FIX_READY → re-run the registered "
                         "TEST+SEED, then: make evidence BUG=%(bid)s "
                         "(closer ≠ fixer — have rev spot-check the closure)",
        "bug_verifying": "%(bid)s VERIFYING → finish closure via "
                         "make evidence BUG=%(bid)s",
        "bug_accepted_due": "%(bid)s accepted debt due this milestone → "
                            "fix it now, or WONTFIX with a rev-signed "
                            "rationale",
        "tp_fail": "testplan %(rid)s ❌ → check your stimulus/checker first "
                   "(dispatch tables); still DUT-suspect → file in bugs.md",
        "undelivered": "%(mod)s not delivered (%(ids)s) → write it "
                       "(skeletons with signatures + TODOs are fine to ask "
                       "the main session for)",
        "unverified": "%(mod)s scenarios %(scenes)s not ✅ → write/run the "
                      "tests, then make evidence SCEN=<id>",
        "prompt_missing": None,  # design prompts do not exist in learning
        "explore": "%(m)s has no scenario rows yet and %(n)d spec "
                   "subsections are cited by nobody → make explore, draft "
                   "candidate rows, request rev review",
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
        "bug_accepted_due": "%(bid)s accepted debt due this milestone → "
                            "dispatch a rev re-adjudication card",
        "tp_fail": "testplan %(rid)s ❌ → DV checks stimulus/checker first; "
                   "still RTL-suspect → file in bugs.md",
        "undelivered": "%(mod)s deliverable missing (%(ids)s, design prompt "
                       "ready) → dispatch %(role)s card",
        "unverified": "%(mod)s scenarios %(scenes)s not ✅ → dispatch DV "
                      "scenario card",
        "prompt_missing": "%(mod)s lacks doc/design-prompt/%(mod)s.md → "
                          "dispatch arch card (rev gate before any "
                          "%(role)s card)",
        "explore": "%(m)s has no scenario rows yet and %(n)d spec "
                   "subsections are cited by nobody → make explore, then "
                   "dispatch an arch spec-gap card",
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
        else:
            acc = BUG_ACCEPTED_RE.match(st)
            if acc and int(acc.group(1)) <= \
                    int(milestone.lstrip("M") or 0):
                acts.append((1, P["bug_accepted_due"] % ctx))

    # 2) current-milestone progress, grouped by module/component
    tp_rows = parse_table(CFG.testplan)
    fm_rows = parse_table(CFG.feature_matrix)
    tp_pass = testplan_pass_ids(tp_rows)
    cur_tp = [r for r in tp_rows
              if r.get(CFG.C["tp_milestone"]) == milestone]
    cur_fm = [r for r in fm_rows
              if r.get(CFG.C["fm_milestone"]) == milestone]
    # Planning-time frontier nag: fires only while the current milestone
    # has zero registered rows, silent once planning exists — the
    # spec-gap explorer's daily-loop consumer (a mechanism nobody is told
    # to run does not exist).
    if not cur_tp and P.get("explore"):
        uncited = chain_gaps()["uncited"]
        if uncited:
            acts.append((2, P["explore"] % {"m": milestone,
                                            "n": len(uncited)}))
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
        # BUG-0054: reuse cmd_signoff's own evaluator (doc/milestone.md:3's
        # full machine-condition set) instead of the private, narrower copy
        # this block used to carry — that copy never looked at bug status or
        # kill coverage at all, so it could call a milestone "done" with
        # OPEN bugs still on the books. 见 doc/fw-feedback.md FB-31.
        bugs_ok, bugs_detail = milestone_bugs_terminal(mnum)
        if not bugs_ok:
            missing.append("bugs not all terminal/ACCEPTED-unexpired%s"
                           % bugs_detail)
        if not kill_coverage_hits(mnum):
            missing.append("no KILL row tagged %s (kill coverage)"
                           % milestone)
        if not signoff_file_exists(mnum):
            missing.append("rev milestone signoff (%s in doc/evidence/"
                           "v<ver>/)" % CFG.signoff_glob.format(m=mnum))
        if missing:
            acts.append((1, "%s scenarios all ✅ — still missing: %s"
                         % (milestone, "; ".join(missing))))
        else:
            # File existence is not the same as an approving verdict
            # (BUG-0054): the signoff record's actual disposition (PASS /
            # CONDITIONAL PASS / REJECTED) stays a human read, never a
            # regex match — REV-037 §BUG-0054 ruled that parsing prose for
            # a keyword is fragile and gameable, so this line only claims
            # what the machine actually verified and defers the rest.
            acts.append((1, "%s three hard conditions met — before make "
                            "bump-minor + git tag v0.%d.0, read doc/"
                            "evidence/v0.%s.*/%s and confirm its recorded "
                            "verdict is not REJECTED"
                         % (milestone, int(mnum) + 1, mnum,
                            CFG.signoff_glob.format(m=mnum))))

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


def cmd_signoff(mnum=None):
    """Read-only milestone signoff pre-check: print each machine condition
    PASS/FAIL with offenders, then the human spot-check list. Writing the
    signoff file remains rev's job (workflow/review.md). mnum defaults to
    the current milestone (version.json) when not given."""
    if mnum is None:
        _, milestone = read_version()
        mnum = milestone.lstrip("M")
    milestone = "M%s" % mnum
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

    cond3, detail3 = milestone_bugs_terminal(mnum)
    print("[%s] 3. all bugs terminal or ACCEPTED-unexpired, closures "
          "evidenced%s" % ("PASS" if cond3 else "FAIL", detail3))
    if not cond3:
        fails.append(3)

    cond4 = check_kill_coverage(mnum)
    if not cond4:
        fails.append(4)

    signed = signoff_file_exists(mnum)
    print("[%s] signoff file (%s) in doc/evidence/v0.%s.*"
          % ("yes" if signed else "not yet", CFG.signoff_glob.format(m=mnum),
             mnum))

    print("\nHuman spot checks (rev-led, recorded in the signoff file — "
          "workflow/review.md):")
    print("  5. coverage closure ≠ risk closure: verify 2-3 hit bins were "
          "hit by the intended scenario; re-read 1 waived hole")
    print("  6. guards: make guards FILES=<touched> lists the review "
          "scope; falsify at least one (re-introduce its defect, see red)")
    print("  7. open SPEC_ISSUE list empty, or each entry has a written "
          "acceptance rationale")
    print("  8. accepted debt: each ACCEPTED row's REV rationale is "
          "falsifiable; carry-overs re-arbitrated, never auto-extended")
    print("  9. chain audit answered: paste one run into the signoff "
          "record; disposition per gap class (report follows)")
    print("")
    cmd_chain_audit()
    return 1 if fails else 0


def check_kill_coverage(mnum):
    """Invariant 5's machine backing: no kill, no trust. A checker that has
    never been proven able to go red is a hypothesis, not evidence — this
    checks doc/bugs.md (and archive) for at least one KILL row (status=KILL)
    tagged to this milestone (summary contains the bare milestone token,
    e.g. "M2"). Deliberately a minimum, not a per-checker-class census:
    there is no canonical registry of "every checker this milestone touched"
    to enumerate against, so whether the KILL set is actually complete stays
    a human call at rubric review (workflow/review.md, the kill-coverage
    question) — this only catches the milestone with zero kills at all.
    See doc/fw-feedback.md FB-29."""
    tag = "M%s" % mnum
    hits = kill_coverage_hits(mnum)
    ok = bool(hits)
    print("[%s] 4. kill coverage: >=1 KILL row tagged %s (%s)"
          % ("PASS" if ok else "FAIL", tag,
             ", ".join(hits) if hits else
             "none — no checker proven able to fail this milestone"))
    return ok


def kill_coverage_hits(mnum):
    """Pure-data half of check_kill_coverage() above — the hit list, no
    printing. cmd_handoff (`--next`) reuses this to gate milestone
    completion without the PASS/FAIL banner leaking into its action-list
    output (BUG-0054 / doc/fw-feedback.md FB-31)."""
    tag = "M%s" % mnum
    bug_rows = parse_table(CFG.bugs)
    abug_rows = parse_table(CFG.bugs_archive)
    return [r.get(CFG.C["bug_id"], "?") for r in bug_rows + abug_rows
            if r.get(CFG.C["bug_status"], "").strip() == "KILL"
            and re.search(r"\b%s\b" % re.escape(tag),
                          r.get(CFG.C["bug_summary"], ""))]


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


SPEC_REF_RE = re.compile(r"SPEC-(\d+(?:\.\d+)*)")
SPEC_SEC_RE = re.compile(r"(?:^#{1,6}\s*|§)(\d+(?:\.\d+)*)", re.M)


def chain_gaps():
    """Break-link computation shared by cmd_chain_audit() (part of bare
    --check) and --explore (planning view)."""
    spec_text = CFG.spec.read_text(encoding="utf-8", errors="replace")
    secs = set(SPEC_SEC_RE.findall(spec_text))
    titles = dict(re.findall(r"^#{1,6}\s*(\d+(?:\.\d+)*)\s+(.+)$",
                             spec_text, re.M))
    tp_rows = parse_table(CFG.testplan)
    linked = {s for r in parse_table(CFG.feature_matrix)
              for s in linked_scenes(r)}

    dangling, parented, sourceless, orphans, all_refs = [], [], [], [], set()
    ev_missing_specref, ev_checked = 0, 0
    for r in tp_rows:
        rid = r.get(CFG.C["tp_id"], "?").strip()
        refs = set(SPEC_REF_RE.findall(" ".join(r.values())))
        all_refs |= refs
        if not refs:
            sourceless.append(rid)
        for ref in sorted(refs):
            if ref in secs:
                continue
            anc, hit = ref, False
            while "." in anc:
                anc = anc.rsplit(".", 1)[0]
                if anc in secs:
                    parented.append("%s SPEC-%s→§%s" % (rid, ref, anc))
                    hit = True
                    break
            if not hit:
                dangling.append("%s SPEC-%s" % (rid, ref))
        if rid not in linked:
            orphans.append(rid)
        if "✅" in r.get(CFG.C["tp_status"], ""):
            ev = r.get(CFG.C["tp_evidence"], "").strip("` ")
            p = CFG.root / ev
            if ev.startswith("doc/evidence/") and p.exists():
                ev_checked += 1
                if "# spec_ref:" not in p.read_text(encoding="utf-8",
                                                    errors="replace"):
                    ev_missing_specref += 1
    # Numeric sort + full print: string sort truncated the highest-numbered
    # chapters — exactly the next milestone's territory — and silently
    # (pulp FB-22). This is the one line that must never be cut.
    uncited = sorted(
        (s for s in secs if "." in s and s not in all_refs
         and not any(ref == s or ref.startswith(s + ".")
                     for ref in all_refs)),
        key=lambda s: [int(x) for x in s.split(".")])
    return {"dangling": dangling, "parented": parented,
            "sourceless": sourceless, "orphans": orphans,
            "uncited": uncited, "titles": titles,
            "ev_missing_specref": ev_missing_specref,
            "ev_checked": ev_checked}


def cmd_chain_audit():
    """Whole-graph break-link audit: spec ↔ testplan ↔ feature-matrix ↔
    evidence. Hard-fails only on dangling spec refs (cited section absent
    from spec.md, ancestors included); other break classes are reported
    for review — convention layers (spec_ref headers) are counted, not
    enforced, until adoption catches up."""
    g = chain_gaps()
    print("== chain audit ==")
    print("[%s] dangling spec refs (cited, no such section): %d%s"
          % ("FAIL" if g["dangling"] else "PASS", len(g["dangling"]),
             " — " + ", ".join(g["dangling"]) if g["dangling"] else ""))
    for label, items in (("scenarios citing no spec clause",
                          g["sourceless"]),
                         ("scenarios in no feature-matrix row",
                          g["orphans"]),
                         ("refs anchored only at a parent section",
                          g["parented"])):
        print("[gap] %s: %d%s" % (label, len(items),
                                  " — " + ", ".join(items) if items else ""))
    print("[gap] spec subsections cited by no scenario: %d%s"
          % (len(g["uncited"]),
             " — §" + ", §".join(g["uncited"]) if g["uncited"] else ""))
    print("[gap] ✅ evidence without a spec_ref header: %d/%d "
          "(convention, not yet enforced)"
          % (g["ev_missing_specref"], g["ev_checked"]))
    return 1 if g["dangling"] else 0


def cmd_explore():
    """Planning view of the gap frontier: spec subsections no scenario
    cites, as candidates for the next testplan rows. Mechanical listing
    only — whether a section deserves a scenario is a semantic call
    (arch proposes, rev gates; declining a section is a recorded
    decision, like any narrowing)."""
    _, milestone = read_version()
    g = chain_gaps()
    cur = [r for r in parse_table(CFG.testplan)
           if r.get(CFG.C["tp_milestone"]) == milestone]
    print("== explore: spec-gap frontier (%s, %d scenario rows "
          "registered) ==" % (milestone, len(cur)))
    if not g["uncited"]:
        print("no uncited spec subsections — the registered frontier "
              "covers the spec; remaining gap surfaces are coverage holes "
              "and ❌ rows")
        return
    print("spec subsections cited by no scenario: %d" % len(g["uncited"]))
    for s in g["uncited"]:
        print("  §%-10s %s" % (s, g["titles"].get(s, "")))
    if g["sourceless"]:
        print("scenarios citing no spec clause (anchor or retire): %s"
              % ", ".join(g["sourceless"]))
    if CFG.profile == "copilot":
        print("next: dispatch an arch spec-gap card carrying this list "
              "verbatim; rev gates the proposed rows before registration")
    else:
        print("next: draft candidate testplan rows for the sections this "
              "milestone owns; request rev review before registering")
    print("note: not every section needs a scenario — declining one is a "
          "rev-recorded decision (narrowing must be declared)")


def cmd_guards(paths):
    """Print every registered guard (doc/guards.md's F4 table, one row per
    former `## regression_guard` page section — migrated under REV-038 §C,
    see doc/design-prompt/doc_mechanization.md §F4) whose `paths:` globs
    match any given file path. Consumed at card assembly (dispatch
    self-check) and by rubric #5 — constraint propagation by registered
    fact, which is what the instance-isolation rules cannot carry (pulp
    BUG-0015: a guard named the next victim file and nothing consumed it).

    FB-40: this replaces the old page-scan implementation (`## regression_
    guard` sections in doc/bugs/*.md) now that doc/guards.md is the guard
    table's load-bearing structure; the *output contract* is unchanged —
    `"== <bugs> guard (hit: ...) =="` per match + a trailing `"N guard(s)
    matched"` line — every existing `grep '== BUG-XXXX guard'`-shaped
    consumer (REV-037 S1-S3, the dispatch SKILL self-check, historical REV
    records) keeps working. `<label>` is the row's `bugs` cell (not its
    `id`), byte-identical to the page-scan era's `page.stem`. See
    doc/fw-feedback.md FB-38 (page-scan -> table era) and FB-40 (this
    file -> scripts/docsx.py -> back into this file)."""
    import fnmatch
    hits = 0
    for row in load_guards(CFG):
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


def main():
    global CFG
    parser = argparse.ArgumentParser(
        description="iverif doc mechanical layer")
    parser.add_argument("--handoff", action="store_true",
                        help="print the handoff summary")
    parser.add_argument("--next", action="store_true",
                        help="mechanically derive the next-action list")
    parser.add_argument("--check", action="store_true",
                        help="doc structure + chain audit; combine with "
                             "--scen or --milestone to narrow the view")
    parser.add_argument("--scen", metavar="SCEN",
                        help="with --check: one scenario's full evidence "
                             "chain instead of the whole-repo check")
    parser.add_argument("--milestone", metavar="M",
                        help="with --check: milestone signoff precheck "
                             "(machine conditions + kill coverage + human "
                             "spot-check list) instead of the whole-repo "
                             "check")
    parser.add_argument("--archive", action="store_true",
                        help="roll archives (log/status/bugs/waivers)")
    parser.add_argument("--pin-spec", action="store_true",
                        help="re-pin spec.md sha256")
    parser.add_argument("--guards", nargs="+", metavar="PATH",
                        help="print regression_guards binding these paths")
    parser.add_argument("--repro", metavar="SCEN",
                        help="print a scenario's replay command")
    parser.add_argument("--explore", action="store_true",
                        help="planning view: spec subsections no scenario "
                             "cites (candidate testplan rows)")
    args = parser.parse_args()
    CFG = load_config()
    # FB-40: doc/guards.md is not part of iverif_config.Config (docs.py's own
    # canon class) — attach it here rather than editing that upstream file,
    # same pattern scripts/docsx.py used before it dissolved into this file.
    CFG.guards = CFG.root / "doc" / "guards.md"
    if args.pin_spec:
        cmd_pin_spec()
    if args.archive:
        cmd_archive()
    if args.check:
        if args.scen:
            cmd_chain(args.scen)
        elif args.milestone:
            sys.exit(cmd_signoff(args.milestone.lstrip("M")))
        else:
            struct_rc = cmd_check()
            audit_rc = cmd_chain_audit()
            sys.exit(struct_rc or audit_rc)
    if args.guards:
        cmd_guards(args.guards)
    if args.repro:
        cmd_repro(args.repro)
    if args.explore:
        cmd_explore()
    if args.handoff:
        cmd_handoff()
    if args.next:
        cmd_next()
    if not any(vars(args).values()):
        parser.print_help()


if __name__ == "__main__":
    main()
