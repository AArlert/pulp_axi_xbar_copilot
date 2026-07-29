"""Four-quadrant tests for evidence.py: {UVM, plain-VCS} x {PASS, FAIL},
plus backfill behavior, the spec_ref header, and the SVA leg (assertion
failures never increment UVM_ERROR — they need their own judgment)."""
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from fixture import (PLAIN_FAIL_LOG, PLAIN_NONUVM_VERDICT_LOG,
                     PLAIN_PASS_LOG, UVM_FAIL_LOG, UVM_NOSVA_LOG,
                     UVM_PASS_LOG, UVM_SVA_FAIL_LOG, make_project, run)


class EvidenceBase(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="iverif_ev_"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        make_project(self.tmp)
        self.out = self.tmp / "sim" / "out"
        self.out.mkdir(parents=True)

    def write_log(self, content, test="fixture_test", seed="1"):
        p = self.out / ("%s_%s.log" % (test, seed))
        p.write_text(content, encoding="utf-8")
        return p

    def evidence(self, *args):
        return run(self.tmp, "evidence.py", *args)


class TestCmdEvidence(unittest.TestCase):
    """FB-16: non-sim re-verification (lint/compile/tool criteria)."""
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="iverif_cmd_"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        make_project(self.tmp, overrides={"fl_schema_enforce": False})
        bugs = self.tmp / "doc" / "bugs.md"
        bugs.write_text(bugs.read_text(encoding="utf-8")
                        + "| BUG-0001 | VERIFYING | TB | lint flag gone | "
                        "TEST=x SEED=1 | flags | abc1234 | - |\n",
                        encoding="utf-8")

    def ev(self, *args):
        return run(self.tmp, "evidence.py", *args)

    def test_cmd_pass_with_signature_closes_bug(self):
        cp = self.ev("--bug", "BUG-0001", "--cmd",
                     "echo 'Lint-clean: 0 errors'", "--expect", "Lint-clean")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = (self.tmp / "doc" / "evidence" / "v0.1.0"
              / "BUG-0001.log").read_text(encoding="utf-8")
        self.assertTrue(ev.startswith("CMD: echo"))
        self.assertIn("Lint-clean: 0 errors", ev)
        self.assertIn("CLOSED",
                      (self.tmp / "doc" / "bugs.md")
                      .read_text(encoding="utf-8"))

    def test_cmd_nonzero_exit_refused(self):
        cp = self.ev("--bug", "BUG-0001", "--cmd", "false",
                     "--expect", "x")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("never evidence", cp.stderr + cp.stdout)
        self.assertIn("VERIFYING",
                      (self.tmp / "doc" / "bugs.md")
                      .read_text(encoding="utf-8"))

    def test_cmd_missing_signature_refused(self):
        cp = self.ev("--bug", "BUG-0001", "--cmd", "echo ran fine",
                     "--expect", "Lint-clean")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("no signature, no evidence", cp.stderr + cp.stdout)

    def test_cmd_without_expect_refused(self):
        cp = self.ev("--bug", "BUG-0001", "--cmd", "true")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("--expect", cp.stderr + cp.stdout)


class TestFourQuadrants(EvidenceBase):
    def test_uvm_pass_registers_and_backfills(self):
        self.write_log(UVM_PASS_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = self.tmp / "doc" / "evidence" / "v0.1.0" / "M1-01.log"
        self.assertTrue(ev.exists())
        first = ev.read_text(encoding="utf-8").splitlines()[0]
        self.assertEqual(first, "make run TEST=fixture_test SEED=1")
        tp = (self.tmp / "doc" / "testplan.md").read_text(encoding="utf-8")
        self.assertIn("✅", tp)
        self.assertIn("doc/evidence/v0.1.0/M1-01.log", tp)
        # evidence.py chains into docs-check, which must have passed
        self.assertIn("docs-check passed", cp.stdout)

    def test_uvm_fail_rejected(self):
        self.write_log(UVM_FAIL_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("FAIL logs are never evidence", cp.stderr + cp.stdout)
        self.assertFalse(
            (self.tmp / "doc" / "evidence" / "v0.1.0" / "M1-01.log").exists())

    def test_plain_pass_registers(self):
        self.write_log(PLAIN_PASS_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = self.tmp / "doc" / "evidence" / "v0.1.0" / "M1-01.log"
        self.assertIn("V C S   S i m u l a t i o n",
                      ev.read_text(encoding="utf-8"))

    def test_plain_nonuvm_verdict_line_captured(self):
        # FB-6: a non-UVM tb's scoreboard verdict ("Tests Failed: 0") prints
        # well above the old 2-line summary window and matched none of the
        # old KEY_LINE_RE patterns, leaving `## Key check lines` empty even
        # though the log judges PASS. Both the widened window and the new
        # KEY_LINE_RE patterns must surface it.
        self.write_log(PLAIN_NONUVM_VERDICT_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = (self.tmp / "doc" / "evidence" / "v0.1.0"
              / "M1-01.log").read_text(encoding="utf-8")
        report_summary, _, key_lines = ev.partition("## Key check lines")
        self.assertIn("Tests Failed:", report_summary)  # widened window
        self.assertIn("Tests Failed:", key_lines)        # KEY_LINE_RE hit
        self.assertIn("Simulation has ended!", key_lines)

    def test_fcov_summary_lines_are_canon(self):
        # FB-9 (pulp_axi_xbar) + user ruling 2026-07-28: `[FCOV_SUMMARY]`
        # per-covergroup lines (workflow/records.md field contract) are the
        # canon convention — captured into `## Key check lines` with ZERO
        # project config, so coverage numbers live in the evidence itself
        # and signoff never re-opens source logs. (0.3.2 briefly pinned the
        # opposite — hook-only capture — before the ruling that adopting
        # projects must be correct out of the box.)
        fcov = ("UVM_INFO fcov.sv(9) @ 345000: [FCOV_SUMMARY] cg_tx_limit "
                "samples=60 inst_cov=80.00\n")
        self.write_log(fcov + UVM_PASS_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = (self.tmp / "doc" / "evidence" / "v0.1.0"
              / "M1-01.log").read_text(encoding="utf-8")
        _, _, keys = ev.partition("## Key check lines")
        self.assertIn("[FCOV_SUMMARY] cg_tx_limit samples=60", keys)

    def test_key_line_extra_captures_project_labels(self):
        # The escape hatch for tags beyond the canon convention: a
        # project-invented [MYCOV] tag stays out of the excerpt by default
        # (canon must not silently widen), rides in via the iverif.json
        # `key_line_extra` hook, and a bad regex fails loudly.
        mycov = ("UVM_INFO cov.sv(3) @ 345000: [MYCOV] region_hits "
                 "count=42\n")
        log = mycov + UVM_PASS_LOG
        self.write_log(log)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = (self.tmp / "doc" / "evidence" / "v0.1.0"
              / "M1-01.log").read_text(encoding="utf-8")
        self.assertNotIn("MYCOV", ev)            # canon stays canon

        hooked = Path(self.tmp.parent) / (self.tmp.name + "_mycov")
        self.addCleanup(shutil.rmtree, hooked, True)
        make_project(hooked, overrides={"key_line_extra": [r"\[MYCOV\]"]})
        out = hooked / "sim" / "out"
        out.mkdir(parents=True)
        (out / "fixture_test_1.log").write_text(log, encoding="utf-8")
        cp = run(hooked, "evidence.py", "--scen", "M1-01", "--test",
                 "fixture_test", "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = (hooked / "doc" / "evidence" / "v0.1.0"
              / "M1-01.log").read_text(encoding="utf-8")
        _, _, keys = ev.partition("## Key check lines")
        self.assertIn("[MYCOV] region_hits count=42", keys)

        badp = Path(self.tmp.parent) / (self.tmp.name + "_badre")
        self.addCleanup(shutil.rmtree, badp, True)
        make_project(badp, overrides={"key_line_extra": ["[unclosed"]})
        out = badp / "sim" / "out"
        out.mkdir(parents=True)
        (out / "fixture_test_1.log").write_text(log, encoding="utf-8")
        cp = run(badp, "evidence.py", "--scen", "M1-01", "--test",
                 "fixture_test", "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("key_line_extra", cp.stderr + cp.stdout)

    def test_sva_detail_lines_aggregated_and_truncation_visible(self):
        # pulp FB-13: hundreds of -assert verbose per-assertion lines ate
        # the 30-line cap as an arbitrary prefix. They must aggregate per
        # source file; overflow of real key lines must be visible.
        details = "".join(
            '"../tb/sva/a_sva.sv", %d: tb.a.p%d: 12 attempts, 12 match\n'
            % (10 + i, i) for i in range(20)) + "".join(
            '"../tb/sva/b_sva.sv", %d: tb.b.c%d: 9 attempts, 7 match\n'
            % (10 + i, i) for i in range(15))
        noise = "".join("scoreboard compare ok id=%d\n" % i
                        for i in range(40))
        self.write_log(details + noise + UVM_PASS_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = (self.tmp / "doc" / "evidence" / "v0.1.0"
              / "M1-01.log").read_text(encoding="utf-8")
        self.assertIn("a_sva.sv: 20 properties/covers, 240 attempts, "
                      "240 match", ev)
        self.assertIn("b_sva.sv: 15 properties/covers, 135 attempts, "
                      "105 match", ev)
        self.assertNotIn("tb.a.p3:", ev)          # raw flood stays out
        self.assertIn("more key lines truncated", ev)

    def test_plain_fail_rejected(self):
        self.write_log(PLAIN_FAIL_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)

    def test_gibberish_log_rejected(self):
        self.write_log("neither uvm nor vcs\n")
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("cannot judge", cp.stderr + cp.stdout)

    def test_missing_log_rejected(self):
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("no log, no evidence", cp.stderr + cp.stdout)


class TestSvaLeg(EvidenceBase):
    """The BUG-014 fuse: `UVM_ERROR : 0` proves nothing about assertions."""

    def test_sva_failure_rejected_despite_clean_uvm(self):
        self.write_log(UVM_SVA_FAIL_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        out = cp.stderr + cp.stdout
        self.assertIn("SVA failures", out)
        self.assertIn("a_done_hold", out)  # detail names the assertion
        self.assertFalse(
            (self.tmp / "doc" / "evidence" / "v0.1.0" / "M1-01.log").exists())

    def test_missing_native_summary_rejected_by_default(self):
        self.write_log(UVM_NOSVA_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("-assert verbose", cp.stderr + cp.stdout)

    def test_missing_summary_tolerated_when_enforce_off(self):
        # Legacy flows predating -assert verbose set "sva_enforce": false.
        cfg_path = self.tmp / "iverif.json"
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
        cfg["sva_enforce"] = False
        cfg_path.write_text(json.dumps(cfg), encoding="utf-8")
        self.write_log(UVM_NOSVA_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = self.tmp / "doc" / "evidence" / "v0.1.0" / "M1-01.log"
        self.assertIn("sva_enforce off", ev.read_text(encoding="utf-8"))

    def test_enforce_off_still_rejects_visible_sva_failure(self):
        # enforce=false relaxes only the missing-summary case; a detected
        # engine failure line stays fatal.
        cfg_path = self.tmp / "iverif.json"
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
        cfg["sva_enforce"] = False
        cfg_path.write_text(json.dumps(cfg), encoding="utf-8")
        self.write_log(UVM_SVA_FAIL_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("SVA failures", cp.stderr + cp.stdout)

    def test_baseline_floor_violation_rejected(self):
        # $assertoff / dropped-sva-file bypass: failures stays 0 while
        # total/attempted sink below the registered floor.
        cfg_path = self.tmp / "iverif.json"
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
        cfg["sva_baseline"] = "sim/regress/sva_baseline.json"
        cfg_path.write_text(json.dumps(cfg), encoding="utf-8")
        bl = self.tmp / "sim" / "regress" / "sva_baseline.json"
        bl.parent.mkdir(parents=True, exist_ok=True)
        bl.write_text('{"total_min": 12, "attempted_min": 12}',
                      encoding="utf-8")
        self.write_log(UVM_PASS_LOG.replace(
            "Summary: 12 assertions, 12 with attempts, 0 with failures",
            "Summary: 12 assertions, 3 with attempts, 0 with failures"))
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("baseline", (cp.stderr + cp.stdout).lower())

    def test_configured_baseline_missing_is_fail_closed(self):
        cfg_path = self.tmp / "iverif.json"
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
        cfg["sva_baseline"] = "sim/regress/sva_baseline.json"
        cfg_path.write_text(json.dumps(cfg), encoding="utf-8")
        self.write_log(UVM_PASS_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("fail-closed", cp.stderr + cp.stdout)


class TestBackfillDetails(EvidenceBase):
    def test_spec_ref_header(self):
        self.write_log(UVM_PASS_LOG)
        cp = self.evidence("--scen", "M1-01", "--test", "fixture_test",
                           "--seed", "1", "--spec-ref", "SPEC-1.1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        ev = self.tmp / "doc" / "evidence" / "v0.1.0" / "M1-01.log"
        self.assertIn("# spec_ref: SPEC-1.1",
                      ev.read_text(encoding="utf-8").splitlines()[2])

    def test_bug_closure_backfill(self):
        from fixture import EN, _table
        (self.tmp / "doc" / "bugs.md").write_text(
            "# Bugs\n\n" + _table(EN["bug_header"], [
                "| BUG-001 | VERIFYING | TB | mismatch | TEST=fixture_test "
                "SEED=1 | bad expect | abc123 | - |"]), encoding="utf-8")
        self.write_log(UVM_PASS_LOG)
        cp = self.evidence("--bug", "BUG-001", "--test", "fixture_test",
                           "--seed", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        bugs = (self.tmp / "doc" / "bugs.md").read_text(encoding="utf-8")
        self.assertIn("CLOSED", bugs)
        self.assertIn("doc/evidence/v0.1.0/BUG-001.log", bugs)
        self.assertIn("closer ≠ fixer", cp.stdout)

    def test_unknown_scenario_id_rejected(self):
        self.write_log(UVM_PASS_LOG)
        cp = self.evidence("--scen", "M9-99", "--test", "fixture_test",
                           "--seed", "1")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("no row with id", cp.stderr + cp.stdout)


if __name__ == "__main__":
    unittest.main()
