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
# Batch 1 (this file): F1 (number assertion), F2 (in-repo path existence),
# F7 (hardcoded-snapshot heuristic, warning-only per REV-038 D-3), F10
# (baseline, bidirectional) + the §12 executor safety contract shared by F1
# and (in a later batch) F3/bidiff. F3-F6/F8/F9 land in later batches.
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


def _run(cmd, cwd, timeout=TIMEOUT_S):
    """The one subprocess.run call site. Deliberately takes the raw text
    (not argv) since the whole point of the exercise is a pipe; the
    allowlist/denylist gate is what makes running it via sh -c safe, not
    argv-splitting."""
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
    if not proc.stdout.strip():
        return False, proc.stdout, "empty stdout"
    return True, proc.stdout, ""


def exec_check(cmd, cfg, timeout=TIMEOUT_S):
    """Gate then run. Returns (ok, stdout, reason)."""
    ok, reason = exec_gate(cmd)
    if not ok:
        return False, "", reason
    return _run(cmd, cfg.root, timeout=timeout)


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
    once. Split out from cmd_check so `--kill-proof` and tests can reuse it
    without re-parsing argv."""
    f1, f2, warns = {}, {}, []
    for f in live_files(cfg):
        rel = relpath(cfg, f)
        text = read_scan_text(cfg, f)
        for locus, msg in check_f1_text(cfg, rel, text):
            f1[locus] = msg
        for locus, msg in check_f2_text(cfg, rel, text):
            f2[locus] = msg
        warns.extend(check_f7_text(rel, text))
    return {"F1": f1, "F2": f2}, warns


def cmd_check(cfg):
    viol_by_family, warns = collect_violations(cfg)
    errors = []
    if cfg.docsx_baseline.exists():
        check_table_structure(cfg.docsx_baseline, errors)
    errors.extend(check_f10(load_baseline(cfg), viol_by_family))
    return report(errors, warns)


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
                   "(F1/F2/F7/F10 this batch)")
    parser.add_argument("--check", action="store_true",
                        help="run the live file set through F1/F2/F7, "
                             "reconcile against docsx-baseline.md (F10)")
    parser.add_argument("--kill-proof", action="store_true",
                        help="§12 executor-safety self-injury proof "
                             "(doc/bugs.md KILL-0006's min_repro command)")
    args = parser.parse_args()
    cfg = load_config()
    # docsx_baseline is not part of iverif_config.Config (docs.py owns that
    # file); attach it here rather than editing the canon Config class.
    cfg.docsx_baseline = cfg.root / "doc" / "docsx-baseline.md"
    if args.kill_proof:
        sys.exit(cmd_kill_proof(cfg))
    if args.check:
        sys.exit(cmd_check(cfg))
    parser.print_help()


if __name__ == "__main__":
    main()
