#!/usr/bin/env python3
"""SVA assertion-failure detection — the single judgment point shared by
evidence.py and regress.py (ported from ppa-lite-copilot BUG-014, with the
BUG-017/BUG-018 adversarial hardenings).

## Why this module exists

Concurrent-assertion action blocks are conventionally `else $error(...)`.
`$error` is a SystemVerilog system task: it does **not** go through the UVM
report server, does **not** increment UVM_ERROR, and 2018-era VCS does not
change the simv exit code for it. Measured in the origin project (two
assertions deliberately broken): the log carried 26 assertion failures while
the UVM report summary still said `UVM_ERROR : 0`, simv exited 0, make
exited 0. So "UVM_ERROR==0 && UVM_FATAL==0 => PASS" waves through the entire
assertion-failure class. This module adds the missing leg.

## Judgment layers (independent, any hit = FAIL)

Layer 1 — VCS SVA engine failure lines (`started at ... failed at ...`).
  Printed by the assertion engine itself, action block or not. The hier
  segment tolerates `::` (class-scope instances) and escaped identifiers
  with spaces; the line may carry a same-line tail such as
  `  Offending '<sig>'` (real VCS output does).

Layer 1b — action-block severity lines (`Error:`/`Fatal:` prefix form), for
  logs that were trimmed down to severity lines only. Exists only when the
  action block actually called `$error`/`$fatal`.

Layer 2 — VCS native structured counts (requires the sim to run with
  `-assert verbose`, which scripts/make/vcs-2018.mk pins into the run
  pattern)::

      Summary: 91 assertions, 88 with attempts, 0 with failures

  A log may contain several Summary lines (concatenated/multi-run logs);
  **every** line is checked — any `failures>0` fails (taking only the last
  line was defeated once by a fail-then-clean concatenation).

Layer 3 — assertion total/attempt baseline floor (optional; configured via
  iverif.json `"sva_baseline": "<path>"`). `failures==0` alone misses a
  whole bypass class: `$assertoff` drops *attempted* to 0, removing the sva
  file from the flist drops *total* — failures stays 0 in both. The floor
  (total_min / attempted_min, registered by a human, never auto-adapted)
  catches exactly these. When the config names a baseline the file is
  loaded fail-closed: missing/corrupt => hard error (deleting the baseline
  must not be a bypass). Retro-scanning older builds: CLI `--no-baseline`.

## Coverage matrix (which layer catches which shape — no blanket claims)

| Assertion shape x log condition | L1 | L1b | L2 (needs verbose) | L3 (needs baseline) |
| --- | --- | --- | --- | --- |
| concurrent, with $error/$fatal | hit | hit | hit | — |
| concurrent, engine line with same-line tail | hit | hit | hit | — |
| concurrent, no action block | hit | miss | hit | — |
| concurrent, class-scope hier with `::` | hit | hit | hit | — |
| immediate assert, with $error/$fatal | miss | hit | hit | — |
| immediate assert, no action block | miss | miss | **only** hit | — |
| silenced by $assertoff (attempted drops) | miss | miss | miss | **only** hit |
| sva file dropped from flist (total drops) | miss | miss | miss | **only** hit |
| concatenated fail-then-clean log | hit | hit | hit (all lines) | — |

Consequences made explicit rather than assumed: immediate asserts without an
action block depend entirely on `-assert verbose` (hence evidence/regress
treat a missing Summary line as FAIL when `sva_enforce` is on), and
removed/silenced assertions depend entirely on a registered baseline.

## Why this does not false-positive

All three line regexes anchor **structure** (`"file", line: hier:` + fixed
phrase / `^Summary:`), never the word "error": signal names like
`length_error_o`, the UVM summary line `UVM_ERROR : 0`, compile diagnostics
`Error-[XXX]`, and `... started at ... not finished` (unfinished attempt at
sim end) all fail to match. The `^"` / `^Error:` line anchors keep quoted
forms (an evidence excerpt citing a failure line mid-sentence) out.
"""
import argparse
import re
import sys
from pathlib import Path

from iverif_config import load_config, log_verdict

# Layer 1: engine failure line. Non-greedy hier tolerates `::` and escaped
# identifiers; the `started at ... failed at` phrase is the strong anchor.
# Tail `(?:\s.*)?$` admits same-line trailing text (e.g. `Offending '<sig>'`);
# `.` does not cross lines, so two failure lines never merge.
FAIL_LINE_RE = re.compile(
    r'^"(?P<file>[^"]+)",\s*(?P<line>\d+):\s*(?P<hier>.+?):\s*'
    r'started at \S+\s+failed at (?P<time>\S+)(?:\s.*)?$', re.M)

# Layer 1b: action-block severity line ($error/$fatal printed via the
# assertion action block); hier relaxed as in layer 1.
SEVERITY_LINE_RE = re.compile(
    r'^(?P<sev>Error|Fatal):\s*"(?P<file>[^"]+)",\s*(?P<line>\d+):\s*'
    r'(?P<hier>.+?):\s*at time (?P<time>\d[\d.]*\s*\w+)', re.M)

# Layer 2: VCS native assertion counts (-assert verbose).
SUMMARY_RE = re.compile(
    r'^Summary:\s*(?P<total>\d+)\s+assertions?,\s*(?P<attempted>\d+)'
    r'\s+with attempts,\s*(?P<failed>\d+)\s+with failures', re.M)


def load_baseline(cfg):
    """Resolve the layer-3 baseline from config. Returns a dict with
    total_min/attempted_min, or None when the project registers no baseline.
    A configured-but-missing/corrupt file is fail-closed: deleting the
    baseline must not become a bypass."""
    if not cfg.sva_baseline:
        return None
    p = cfg.root / cfg.sva_baseline
    if not p.exists():
        sys.exit("SVA baseline named by iverif.json is missing: %s — "
                 "refusing to judge without it (fail-closed). Retro-scan "
                 "older builds with svacheck.py --no-baseline." % p)
    try:
        import json
        data = json.loads(p.read_text(encoding="utf-8"))
        return {"total_min": int(data["total_min"]),
                "attempted_min": int(data["attempted_min"])}
    except (ValueError, KeyError, TypeError) as e:
        sys.exit("SVA baseline file corrupt/invalid: %s (%s) — fail-closed."
                 % (p, e))


class SvaResult:
    """Assertion verdict for one log."""

    def __init__(self, failures, severities, summaries, baseline):
        self.failures = failures      # layer-1 hits
        self.severities = severities  # layer-1b hits
        self.summaries = summaries    # ALL layer-2 Summary lines
        self.baseline = baseline      # {total_min, attempted_min} or None

    @property
    def has_native_summary(self):
        return bool(self.summaries)

    @property
    def multi_summary(self):
        return len(self.summaries) > 1

    @property
    def summary_failed(self):
        return any(s["failed"] > 0 for s in self.summaries)

    @property
    def baseline_violations(self):
        if self.baseline is None:
            return []
        out = []
        for s in self.summaries:
            why = []
            if s["total"] < self.baseline["total_min"]:
                why.append("total %d<%d" % (s["total"],
                                            self.baseline["total_min"]))
            if s["attempted"] < self.baseline["attempted_min"]:
                why.append("attempted %d<%d"
                           % (s["attempted"], self.baseline["attempted_min"]))
            if why:
                out.append(dict(s, why=", ".join(why)))
        return out

    @property
    def failed(self):
        return bool(self.failures) or bool(self.severities) or \
            self.summary_failed or bool(self.baseline_violations)

    @property
    def n_assert_failed(self):
        """Failing assertion COUNT (layer 2 preferred)."""
        if self.summary_failed:
            return max((s["failed"] for s in self.summaries), default=0)
        return len({f["hier"] for f in self.failures}
                   | {s["hier"] for s in self.severities})

    @property
    def n_hits(self):
        """Failure OCCURRENCES (one assertion failing many cycles counts
        each time)."""
        return max(len(self.failures), len(self.severities))

    def reason(self):
        """One-line failure reason for result_summary.txt / refusal text."""
        if not self.failed:
            return ""
        parts = []
        if self.failures or self.severities or self.summary_failed:
            parts.append("SVA failures: %d assertion(s)/%d hit(s)"
                         % (self.n_assert_failed, self.n_hits))
        if self.baseline_violations:
            parts.append("SVA baseline violated: "
                         + "; ".join(v["why"] for v in
                                     self.baseline_violations)
                         + " (assertions dropped from build or $assertoff)")
        if self.multi_summary and not (self.failures or self.severities):
            parts.append("note: %d Summary lines (concatenated/multi-run "
                         "log, suspicious)" % len(self.summaries))
        return "; ".join(parts)

    def detail_lines(self, limit=20):
        out = []
        for f in self.failures[:limit]:
            out.append("  %s  %s:%s  @%s  (%s)"
                       % (f["name"], f["file"], f["line"], f["time"],
                          f["hier"]))
        if len(self.failures) > limit:
            out.append("  ... (%d more hits, see the raw log)"
                       % (len(self.failures) - limit))
        if not self.failures:
            for s in self.severities[:limit]:
                out.append("  %s  %s:%s  @%s  [%s]"
                           % (s["name"], s["file"], s["line"], s["time"],
                              s["sev"]))
            if self.summary_failed and not self.severities:
                worst = max(self.summaries, key=lambda s: s["failed"])
                out.append("  VCS native summary: %d failing of %d "
                           "assertions (%d attempted)"
                           % (worst["failed"], worst["total"],
                              worst["attempted"]))
        for v in self.baseline_violations:
            out.append("  [baseline] Summary %d/%d/%d — %s"
                       % (v["total"], v["attempted"], v["failed"], v["why"]))
        return out


def _name_of(hier):
    return hier.rsplit(".", 1)[-1]


def scan_text(text, baseline=None):
    failures = [{"file": m["file"], "line": m["line"], "hier": m["hier"],
                 "name": _name_of(m["hier"]), "time": m["time"]}
                for m in FAIL_LINE_RE.finditer(text)]
    severities = [{"sev": m["sev"], "file": m["file"], "line": m["line"],
                   "hier": m["hier"], "name": _name_of(m["hier"]),
                   "time": m["time"].strip()}
                  for m in SEVERITY_LINE_RE.finditer(text)]
    summaries = [{"total": int(m["total"]), "attempted": int(m["attempted"]),
                  "failed": int(m["failed"])}
                 for m in SUMMARY_RE.finditer(text)]
    return SvaResult(failures, severities, summaries, baseline)


def scan_file(path, baseline=None):
    p = Path(path)
    return scan_text(p.read_text(encoding="utf-8", errors="replace"),
                     baseline=baseline)


def judge(text, cfg, baseline=None):
    """Two-leg verdict for one sim log: leg 1 = log_verdict (UVM summary /
    VCS banner), leg 2 = SVA layers. Returns (verdict, reason, SvaResult)
    with verdict in {PASS, FAIL, NOSUMMARY}. Assertion failures do NOT
    increment UVM_ERROR, hence the independent leg — never merge them.

    With cfg.sva_enforce (default on), a log lacking the native Summary line
    is FAIL: the vendored run pattern pins `-assert verbose`, so its absence
    means the log came from a different flow (or the option was bypassed) —
    assertion cleanliness cannot be proven, fail-closed. Legacy repos whose
    flow predates `-assert verbose` set "sva_enforce": false until they
    adopt it."""
    leg1 = log_verdict(text)
    if leg1 == "NOSUMMARY":
        return "NOSUMMARY", "no UVM summary and no VCS completion banner", \
            None
    sva = scan_text(text, baseline=baseline)
    reasons = []
    if leg1 == "FAIL":
        reasons.append("sim FAIL (UVM error counts / VCS error lines)")
    if sva.failed:
        reasons.append(sva.reason())
    elif cfg.sva_enforce and not sva.has_native_summary:
        reasons.append("no VCS assertion summary line ('-assert verbose' "
                       "missing?) — cannot prove zero SVA failures; "
                       "fail-closed (set \"sva_enforce\": false only for "
                       "legacy flows)")
    if reasons:
        return "FAIL", "; ".join(reasons), sva
    return "PASS", "", sva


def main():
    """Batch retro-scan: python3 scripts/svacheck.py [-q] [--no-baseline]
    <log>... Exit 0 = all clean; 1 = at least one log with assertion
    failures / baseline violations."""
    ap = argparse.ArgumentParser(
        description="SVA assertion failure / baseline retro-scan")
    ap.add_argument("logs", nargs="+")
    ap.add_argument("-q", "--quiet", action="store_true",
                    help="print failures only")
    ap.add_argument("--no-baseline", action="store_true",
                    help="skip the layer-3 floor (older builds naturally "
                         "sit below the current baseline)")
    args = ap.parse_args()

    cfg = load_config()
    baseline = None if args.no_baseline else load_baseline(cfg)
    if baseline and not args.quiet:
        print("# baseline: total_min=%d attempted_min=%d (%s)"
              % (baseline["total_min"], baseline["attempted_min"],
                 cfg.sva_baseline))

    n_bad = 0
    for a in args.logs:
        p = Path(a)
        if not p.exists():
            print("MISSING   %s" % a)
            continue
        r = scan_text(p.read_text(encoding="utf-8", errors="replace"),
                      baseline=baseline)
        if r.failed:
            n_bad += 1
            print("SVA_FAIL  %s  %s" % (a, r.reason()))
            for line in r.detail_lines():
                print(line)
        elif not args.quiet:
            notes = []
            if not r.has_native_summary:
                notes.append("no native summary: log lacks -assert verbose")
            if r.multi_summary:
                notes.append("%d Summary lines" % len(r.summaries))
            print("CLEAN     %s%s"
                  % (a, "  [%s]" % "; ".join(notes) if notes else ""))
    print("\nscanned %d log(s), %d with assertion failures/baseline "
          "violations" % (len(args.logs), n_bad))
    sys.exit(1 if n_bad else 0)


if __name__ == "__main__":
    main()
