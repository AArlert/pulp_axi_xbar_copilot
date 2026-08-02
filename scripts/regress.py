#!/usr/bin/env python3
# One-shot regression: read the regression list, `make run` each entry, judge
# each log, write sim/result_summary.txt.
# List format (sim/regress/regress.list): one "<TEST> <SEED>" per line,
# '#' starts a comment.
#
# The verdict is two-legged (svacheck.judge): (1) UVM summary / VCS banner,
# (2) SVA assertion layers. Assertion failures do NOT increment UVM_ERROR —
# a one-legged check waves the whole class through (ppa BUG-014).
# The first column of result_summary.txt keeps its fixed token set
# (PASS/FAIL/NOLOG/NOSUMMARY); new failure causes ride the reason suffix so
# downstream line-counting stays stable.
import os
import subprocess
import sys
from datetime import date

import svacheck
from iverif_config import load_config

USAGE = """usage: regress.py [LIST_FILE] [COV=1] [--wipe]

Run every "<TEST> <SEED>" line in LIST_FILE (default:
sim/regress/regress.list) via `make -C sim run`, judge each log via
svacheck, and write sim/result_summary.txt.

  COV=1     also build/run with coverage instrumentation (make run COV=1).
  --wipe    force `make -C sim clean` before regressing. `clean:` is
            `rm -rf $(OUT)` (sim/Makefile), which destroys the *entire*
            sim/out/ tree in one shot -- every cov.vdb coverage database
            (7 of them: baseline + m0 + cfgA..cfgE) and sim/out/urgText6/.
            None of that has a version-control backup (sim/out/ is
            .gitignore'd) and it is M4 signoff's coverage-evidence base.
            OFF by default (BUG-0066): a bare `make regress` must never
            delete it. Equivalent to setting COV_WIPE=1 in the
            environment. When triggered, the exact list of paths about
            to be deleted is printed before the wipe runs.

Without --wipe/COV_WIPE=1, regress.py runs `make run` directly against
whatever build products already sit under sim/out/, relying on VCS's own
incremental reuse. If a prior build used a *different* option set (e.g. a
previous `make lint`), the incremental database can still get corrupted
(VFS_SDB_ERROR class) -- pass --wipe explicitly to force a clean rebuild
if that happens; it is not something regress.py should risk silently on
every run.
"""


def _wipe_targets(sim):
    """Paths a `make -C sim clean` is about to destroy that regression
    evidence depends on surviving across regress.py invocations (the M4
    coverage-evidence base; see BUG-0066)."""
    out = sim / "out"
    targets = sorted(str(p) for p in out.glob("**/cov.vdb"))
    urg = out / "urgText6"
    if urg.exists():
        targets.append(str(urg))
    return targets


def main():
    if any(a in ("-h", "--help") for a in sys.argv[1:]):
        print(USAGE, end="")
        sys.exit(0)

    cfg = load_config()
    sim = cfg.root / "sim"
    default_list = sim / "regress" / "regress.list"
    summary_path = sim / "result_summary.txt"

    cov = "1" if "COV=1" in sys.argv[1:] else "0"
    wipe = "--wipe" in sys.argv[1:] or os.environ.get("COV_WIPE") == "1"
    pos = [a for a in sys.argv[1:]
           if not a.startswith("COV=") and a != "--wipe"]
    list_file = (cfg.root / pos[0]) if pos else default_list
    entries = []
    for lineno, line in enumerate(
            list_file.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2:
            sys.exit("regression list line %d malformed (expected "
                     "'<TEST> <SEED>'): %s" % (lineno, line))
        entries.append((parts[0], parts[1]))
    if not entries:
        sys.exit("regression list is empty")

    # BUG-0066: a bare `make regress` used to unconditionally `make -C sim
    # clean` here on the theory that VCS's incremental build reuse under
    # out/ (.daidir, csrc, ...) can mix products from different option sets
    # (e.g. a prior `make lint`) and corrupt the build database
    # (VFS_SDB_ERROR class). That is a real failure mode, but `clean:` is
    # `rm -rf $(OUT)` -- it also destroys every cov.vdb coverage database
    # and sim/out/urgText6/, which is M4 signoff's coverage-evidence base
    # and has no version-control backup. Wiping that on every default
    # regression run is a strictly worse trade than the rare VFS_SDB_ERROR
    # it guards against, so the wipe is now opt-in (--wipe / COV_WIPE=1)
    # rather than the default.
    if wipe:
        targets = _wipe_targets(sim)
        print("COV_WIPE=1/--wipe: about to `make -C sim clean` (rm -rf "
              "sim/out/ and friends).", flush=True)
        if targets:
            print("This destroys %d coverage artifact(s) with no "
                  "version-control backup:" % len(targets), flush=True)
            for t in targets:
                print("  - %s" % t, flush=True)
        else:
            print("(no cov.vdb/urgText6 currently present under sim/out/)",
                  flush=True)
        subprocess.run(["make", "-C", str(sim), "clean"], check=True)
    else:
        print("regress.py: skipping `make -C sim clean` (default, "
              "BUG-0066) -- pass --wipe or set COV_WIPE=1 to force a full "
              "rebuild from a clean slate; see --help.", flush=True)

    baseline = svacheck.load_baseline(cfg)
    results = []
    for test, seed in entries:
        print("== regress: %s SEED=%s ==" % (test, seed), flush=True)
        rc = subprocess.run(
            ["make", "-C", str(sim), "run", "TEST=%s" % test,
             "SEED=%s" % seed, "COV=%s" % cov],
        ).returncode
        log = cfg.sim_log_path(test, seed)
        sva = None
        if not log.exists():
            verdict, reason = "NOLOG", ""
        else:
            verdict, reason, sva = svacheck.judge(
                log.read_text(encoding="utf-8", errors="replace"), cfg,
                baseline=baseline)
        if rc != 0 and verdict == "PASS":
            # abnormal sim exit never counts as a pass
            verdict, reason = "FAIL", "sim process exited nonzero"
        if verdict != "PASS":
            print("   -> %s %s" % (verdict, reason), flush=True)
            if sva is not None and sva.failed:
                for line in sva.detail_lines():
                    print(line, flush=True)
        results.append((test, seed, verdict, reason))

    passed = sum(1 for _, _, v, _ in results if v == "PASS")
    n_sva = sum(1 for _, _, _, r in results if "SVA" in r)
    head = ("%s regression  date=%s  passed=%d/%d"
            % (cfg.project, date.today(), passed, len(results)))
    if n_sva:
        head += "  (%d with SVA assertion causes)" % n_sva
    lines = [head]
    lines += ["%-6s %s SEED=%s%s" % (v, t, s, "  [%s]" % r if r else "")
              for t, s, v, r in results]
    summary_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("\n" + "\n".join(lines))
    print("\nsummary written to %s" % summary_path.relative_to(cfg.root))
    sys.exit(0 if passed == len(results) else 1)


if __name__ == "__main__":
    main()
