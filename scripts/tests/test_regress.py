"""BUG-0066: `make regress` (scripts/regress.py) must never destroy the
coverage-evidence base (sim/out/**/cov.vdb, sim/out/urgText6/) by default.
The old unconditional `make -C sim clean` before every regression run wiped
the entire sim/out/ tree (sim/Makefile's `clean:` is `rm -rf $(OUT)`), and
those artifacts have no version-control backup (.gitignore'd) and are M4
signoff's coverage-evidence base. The wipe is now opt-in (--wipe or
COV_WIPE=1); this test exercises the real filesystem effect against a fake
`sim/Makefile` shaped like the real one's run:/clean: targets, not just
regress.py's own argv bookkeeping."""
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

FRAMEWORK = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fixture import UVM_PASS_LOG, make_project, run  # noqa: E402

sys.path.insert(0, str(FRAMEWORK / "scripts"))
import regress as regress_orig  # noqa: E402  (the real, uncopied module)

# Same run:/clean: shape as sim/Makefile (compile+run write a log under
# $(OUT), clean: is `rm -rf $(OUT)`) -- enough to prove the *filesystem*
# effect, not just what argv regress.py happens to build.
FAKE_SIM_MAKEFILE = """\
OUT ?= out
TEST ?= t
SEED ?= 1
COV ?= 0
.PHONY: run clean
run:
\t@mkdir -p $(OUT)
\t@cp fixture_log.txt $(OUT)/$(TEST)_$(SEED).log
clean:
\trm -rf $(OUT)
"""


@unittest.skipUnless(shutil.which("make"), "make not available")
class TestRegressWipeGate(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="iverif_regress_"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        make_project(self.tmp, overrides={"sva_enforce": False})
        sim = self.tmp / "sim"
        sim.mkdir()
        (sim / "Makefile").write_text(FAKE_SIM_MAKEFILE, encoding="utf-8")
        (sim / "fixture_log.txt").write_text(UVM_PASS_LOG, encoding="utf-8")
        (sim / "regress").mkdir()
        self.list_file = sim / "regress" / "regress.list"
        self.list_file.write_text("faketest 1\n", encoding="utf-8")
        # Stand-ins for the two artifact classes BUG-0066 named.
        self.cov = sim / "out" / "cov.vdb"
        self.cov.mkdir(parents=True)
        (self.cov / "marker").write_text("evidence", encoding="utf-8")
        self.urg = sim / "out" / "urgText6"
        self.urg.mkdir(parents=True)
        (self.urg / "marker").write_text("evidence", encoding="utf-8")

    def regress(self, *args):
        return run(self.tmp, "regress.py", "sim/regress/regress.list",
                   *args)

    def test_default_run_preserves_coverage_artifacts(self):
        cp = self.regress()
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertTrue(self.cov.exists(), "default run deleted cov.vdb")
        self.assertTrue(self.urg.exists(), "default run deleted urgText6")
        self.assertIn("skipping", cp.stdout.lower())

    def test_wipe_flag_destroys_and_announces_targets(self):
        cp = self.regress("--wipe")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertFalse(self.cov.exists(), "--wipe left cov.vdb in place")
        self.assertFalse(self.urg.exists(), "--wipe left urgText6 in place")
        self.assertIn(str(self.cov), cp.stdout)
        self.assertIn(str(self.urg), cp.stdout)

    def test_cov_wipe_env_var_equivalent_to_flag(self):
        import os
        env = dict(os.environ)
        env["PYTHONUTF8"] = "1"
        env["COV_WIPE"] = "1"
        cp = subprocess.run(
            [sys.executable, str(self.tmp / "scripts" / "regress.py"),
             "sim/regress/regress.list"],
            capture_output=True, text=True, encoding="utf-8", env=env,
            cwd=str(self.tmp))
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertFalse(self.cov.exists())
        self.assertFalse(self.urg.exists())

    def test_help_documents_wipe_default(self):
        cp = self.regress("--help")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertIn("--wipe", cp.stdout)
        self.assertIn("COV_WIPE", cp.stdout)
        self.assertIn("default", cp.stdout.lower())


class TestWipeTargetsHelper(unittest.TestCase):
    """Pure-function check on the real (uncopied) module: no subprocess, no
    destructive call possible."""

    def test_wipe_targets_lists_every_cov_vdb_and_urgtext6(self):
        tmp = Path(tempfile.mkdtemp(prefix="iverif_regress_wt_"))
        self.addCleanup(shutil.rmtree, tmp, True)
        sim = tmp / "sim"
        for rel in ("out/cov.vdb", "out/m0/cov.vdb", "out/cfgA/cov.vdb"):
            (sim / rel).mkdir(parents=True)
        (sim / "out" / "urgText6").mkdir(parents=True)
        targets = regress_orig._wipe_targets(sim)
        self.assertEqual(len(targets), 4, targets)
        self.assertTrue(any(t.endswith("urgText6") for t in targets))

    def test_wipe_targets_empty_when_nothing_built_yet(self):
        tmp = Path(tempfile.mkdtemp(prefix="iverif_regress_wt2_"))
        self.addCleanup(shutil.rmtree, tmp, True)
        (tmp / "sim" / "out").mkdir(parents=True)
        self.assertEqual(regress_orig._wipe_targets(tmp / "sim"), [])


if __name__ == "__main__":
    unittest.main()
