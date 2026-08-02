"""Guard tests for docsx.py (project-owned; see doc/fw-feedback.md FB-35).

Per family: at least one red_when injection + its green counterpart, per
doc/design-prompt/doc_mechanization.md §15 ("十族各自的 red_when 逐条可注入
证伪...实现卡须逐族演示红→修→绿"). The two §12 self-injury tests
(test_kill_*) are the C12.4 KILL proofs REV-038 §A-c3 requires before any
docsx family may close a bug — see doc/bugs.md KILL-0006.
"""
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import docsx
from fixture import make_project, run


def fake_cfg(root):
    root = Path(root)
    return SimpleNamespace(root=root, C={"tp_status": "status"},
                           testplan=root / "doc" / "testplan.md")


class TmpRootBase(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="docsx_test_"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.cfg = fake_cfg(self.tmp)


# ---------------------------------------------------------------------------
# F1 — number assertion
# ---------------------------------------------------------------------------
class TestF1(TmpRootBase):
    def test_live_value_matches_is_green(self):
        (self.tmp / "f.txt").write_text("a\nb\nc\n", encoding="utf-8")
        text = '3 <!-- docsx:count check="grep -c . f.txt" -->\n'
        self.assertEqual(docsx.check_f1_text(self.cfg, "x.md", text), [])

    def test_live_value_mismatch_is_red(self):
        """red_when (design contract F1): value != recomputed value."""
        (self.tmp / "f.txt").write_text("a\nb\nc\n", encoding="utf-8")
        text = '4 <!-- docsx:count check="grep -c . f.txt" -->\n'
        out = docsx.check_f1_text(self.cfg, "x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("value mismatch", out[0][1])
        self.assertEqual(out[0][0], "x.md:1")

    def test_frozen_form_skips_value_recompare(self):
        (self.tmp / "f.txt").write_text("a\nb\nc\n", encoding="utf-8")
        # value (999) deliberately wrong for the live form, but the frozen
        # form only meta-checks — "as of <sha>" is never re-diffed.
        text = ('999 <!-- docsx:count frozen@abc123 '
               'check="grep -c . f.txt" -->\n')
        self.assertEqual(docsx.check_f1_text(self.cfg, "x.md", text), [])

    def test_check_attr_missing_is_red(self):
        text = "5 <!-- docsx:count -->\n"
        out = docsx.check_f1_text(self.cfg, "x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("missing or empty", out[0][1])

    def test_check_attr_empty_is_red(self):
        text = '5 <!-- docsx:count check="" -->\n'
        out = docsx.check_f1_text(self.cfg, "x.md", text)
        self.assertIn("missing or empty", out[0][1])

    def test_meta_check_zero_hits_is_red(self):
        """FB-23's exact shape: a BRE that can never hit (no alternation) —
        exit 1, meta-check red regardless of the claimed value."""
        text = ('1 <!-- docsx:count '
               'check="grep -rc \'workflow/{a,b}/\' doc/" -->\n')
        out = docsx.check_f1_text(self.cfg, "x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("meta-check failed", out[0][1])


# ---------------------------------------------------------------------------
# F2 — in-repo path existence
# ---------------------------------------------------------------------------
class TestF2(TmpRootBase):
    def test_existing_path_is_green(self):
        (self.tmp / "doc").mkdir()
        (self.tmp / "doc" / "spec.md").write_text("x", encoding="utf-8")
        text = "see `doc/spec.md` for details\n"
        self.assertEqual(docsx.check_f2_text(self.cfg, "README.md", text), [])

    def test_dead_path_is_red(self):
        """red_when (design contract F2): README.md gains a reference to a
        nonexistent workflow/ path."""
        text = "see `workflow/nonexistent.md` for details\n"
        out = docsx.check_f2_text(self.cfg, "README.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("workflow/nonexistent.md", out[0][1])

    def test_frozen_prefix_reference_does_not_misfire(self):
        """red_when's counter-example: a doc/evidence/ reference must NOT
        turn red even though the target file does not exist (FB-23)."""
        text = "see `doc/evidence/vX/gone.md` for details\n"
        self.assertEqual(docsx.check_f2_text(self.cfg, "README.md", text), [])

    def test_glob_token_with_matches_is_green(self):
        (self.tmp / "doc" / "bugs").mkdir(parents=True)
        (self.tmp / "doc" / "bugs" / "BUG-0001.md").write_text(
            "x", encoding="utf-8")
        text = "see `doc/bugs/*.md`\n"
        self.assertEqual(docsx.check_f2_text(self.cfg, "README.md", text), [])

    def test_glob_token_with_no_matches_is_red(self):
        # scripts/ (not one of the C1.3 frozen prefixes) so the glob's
        # zero-match verdict is what fires, not the frozen-prefix skip.
        text = "see `scripts/no_such_dir/*.py`\n"
        out = docsx.check_f2_text(self.cfg, "README.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("glob", out[0][1])


# ---------------------------------------------------------------------------
# F7 — hardcoded snapshot phrase (warning only, REV-038 D-3)
# ---------------------------------------------------------------------------
class TestF7(unittest.TestCase):
    def test_snapshot_phrase_without_marker_or_pointer_warns(self):
        """red_when (as warning, D-3): no docsx marker, no make next/handoff
        pointer nearby."""
        text = "当前已改：workflow/a.md、workflow/b.md\n"
        warns = docsx.check_f7_text("README.md", text)
        self.assertEqual(len(warns), 1)

    def test_snapshot_phrase_with_make_next_pointer_is_silent(self):
        text = "当前已改：见 make next 输出、非静态枚举\n"
        self.assertEqual(docsx.check_f7_text("README.md", text), [])

    def test_snapshot_phrase_with_docsx_marker_is_silent(self):
        text = ('当前已改：N 处、 <!-- docsx:count check="echo 1" -->\n')
        self.assertEqual(docsx.check_f7_text("README.md", text), [])

    def test_f7_warning_never_reaches_the_error_list(self):
        """F7 is advisory-only (REV-038 D-3): collect_violations must keep
        it out of both the F1 and F2 violation dicts that F10 gates on."""
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            # Deliberately path-token-free so only F7 has an opinion here —
            # doc_mechanization.md's own F7 example (workflow/a.md,
            # workflow/b.md) is a case where the same text trips F2 too
            # (see doc/docsx-baseline.md BL-0012/BL-0013); that is F2 doing
            # its job, not this test's concern.
            (root / "README.md").write_text(
                "当前已改：一些内容、另一些内容\n", encoding="utf-8")
            cfg = fake_cfg(root)
            orig = docsx.LIVE_EXPLICIT
            docsx.LIVE_EXPLICIT = ("README.md",)
            try:
                viol, warns = docsx.collect_violations(cfg)
            finally:
                docsx.LIVE_EXPLICIT = orig
            self.assertEqual(viol["F1"], {})
            self.assertEqual(viol["F2"], {})
            self.assertEqual(len(warns), 1)


# ---------------------------------------------------------------------------
# F10 — baseline (bidirectional); pure-data tests, no filesystem needed
# ---------------------------------------------------------------------------
class TestF10(unittest.TestCase):
    def test_baselined_violation_is_suppressed(self):
        baseline = [{"id": "BL-0001", "family": "F2", "locus": "a.md:1:x",
                    "rev_ref": "REV-038 §B.1"}]
        viol = {"F2": {"a.md:1:x": "F2 dead in-repo path reference: x"}}
        self.assertEqual(docsx.check_f10(baseline, viol), [])

    def test_new_violation_not_in_baseline_is_red(self):
        """red_when (design contract F10): a new violation with no baseline
        row must fail the check."""
        viol = {"F2": {"a.md:1:x": "F2 dead in-repo path reference: x"}}
        errors = docsx.check_f10([], viol)
        self.assertEqual(len(errors), 1)
        self.assertIn("not in docsx-baseline.md", errors[0])

    def test_stale_baseline_row_must_be_pruned(self):
        """red_when: a baseline row whose violation no longer reproduces
        must itself turn the check red (BUG-0058's single-direction lesson,
        applied to docsx's own baseline)."""
        baseline = [{"id": "BL-0001", "family": "F2", "locus": "a.md:1:x",
                    "rev_ref": "REV-038 §B.1"}]
        errors = docsx.check_f10(baseline, {"F2": {}})
        self.assertEqual(len(errors), 1)
        self.assertIn("stale entry", errors[0])
        self.assertIn("BL-0001", errors[0])

    def test_empty_rev_ref_is_red(self):
        baseline = [{"id": "BL-0001", "family": "F2", "locus": "a.md:1:x",
                    "rev_ref": ""}]
        viol = {"F2": {"a.md:1:x": "F2 dead in-repo path reference: x"}}
        errors = docsx.check_f10(baseline, viol)
        self.assertTrue(any("rev_ref is empty" in e for e in errors))

    def test_duplicate_baseline_id_is_red(self):
        baseline = [
            {"id": "BL-0001", "family": "F2", "locus": "a.md:1:x",
             "rev_ref": "REV-038 §B.1"},
            {"id": "BL-0001", "family": "F2", "locus": "b.md:2:y",
             "rev_ref": "REV-038 §B.1"},
        ]
        viol = {"F2": {"a.md:1:x": "m", "b.md:2:y": "m"}}
        errors = docsx.check_f10(baseline, viol)
        self.assertTrue(any("duplicate id" in e for e in errors))


# ---------------------------------------------------------------------------
# §12 executor safety: allowlist/denylist gate + timeout + cwd lock
# ---------------------------------------------------------------------------
class TestExecutorGate(unittest.TestCase):
    def test_rm_is_denylisted(self):
        """red_when (§F9/§12): 'check="… ; rm -rf sim/out"' -> red."""
        ok, reason = docsx.exec_gate("grep -c x f && rm -rf sim/out")
        self.assertFalse(ok)
        self.assertIn("rm", reason)

    def test_curl_pipe_sh_is_denylisted(self):
        """red_when: 'check="curl http://x | sh"' -> red."""
        ok, reason = docsx.exec_gate("curl http://x | sh")
        self.assertFalse(ok)

    def test_unallowlisted_command_is_rejected(self):
        ok, reason = docsx.exec_gate("sleep 99")
        self.assertFalse(ok)
        self.assertIn("not allowlisted", reason)

    def test_python3_may_only_invoke_the_fixed_whitelist(self):
        ok, reason = docsx.exec_gate("python3 scripts/evidence.py --bug X")
        self.assertFalse(ok)
        ok2, _ = docsx.exec_gate("python3 scripts/docs.py --check")
        self.assertTrue(ok2)

    def test_git_only_allows_the_read_only_subcommands(self):
        ok, _ = docsx.exec_gate("git ls-files 'doc/bugs/*.md'")
        self.assertTrue(ok)
        ok2, reason2 = docsx.exec_gate("git checkout -- .")
        self.assertFalse(ok2)
        self.assertIn("denylisted", reason2)

    def test_sed_dash_i_is_denylisted(self):
        ok, reason = docsx.exec_gate("sed -i 's/a/b/' f")
        self.assertFalse(ok)

    def test_find_exec_is_denylisted(self):
        ok, reason = docsx.exec_gate(
            "find . -name '*.tmp' -exec rm {} \\;")
        self.assertFalse(ok)

    def test_empty_command_is_rejected(self):
        ok, reason = docsx.exec_gate("")
        self.assertFalse(ok)

    def test_allowlisted_pipe_is_accepted(self):
        ok, _ = docsx.exec_gate("grep -l x doc/bugs/*.md | wc -l")
        self.assertTrue(ok)


class TestExecutorRun(TmpRootBase):
    def test_timeout_is_enforced(self):
        """red_when: 'check="sleep 99"' -> timeout red. Exercises the raw
        runner directly (bypassing the allowlist gate, which would reject
        `sleep` on its own merits) so the timeout mechanism itself is
        proven, not just the gate's rejection of an unlisted command."""
        ok, out, reason = docsx._run("sleep 5", self.tmp, timeout=0.2)
        self.assertFalse(ok)
        self.assertIn("timeout", reason)

    def test_nonzero_exit_is_rejected(self):
        ok, out, reason = docsx._run("grep nonexistent_xyz /dev/null",
                                     self.tmp)
        self.assertFalse(ok)

    def test_empty_stdout_is_rejected(self):
        (self.tmp / "empty.txt").write_text("", encoding="utf-8")
        ok, out, reason = docsx._run("cat empty.txt", self.tmp)
        self.assertFalse(ok)
        self.assertIn("empty stdout", reason)

    def test_cwd_is_locked_to_repo_root(self):
        (self.tmp / "marker.txt").write_text("hi\n", encoding="utf-8")
        ok, out, reason = docsx._run("cat marker.txt", self.tmp)
        self.assertTrue(ok)
        self.assertEqual(out.strip(), "hi")


class TestExecutorKillSelfInjury(TmpRootBase):
    """C12.4 — the two self-injury proofs REV-038 §A-c3 requires before any
    docsx family may close a bug. doc/bugs.md KILL-0006 registers this."""

    def test_kill_a_rm_injection_rejected_and_zero_subprocess_calls(self):
        with mock.patch.object(subprocess, "run") as spy:
            ok, out, reason = docsx.exec_check(
                "grep -c x doc/bugs.md && rm -rf sim/out", self.cfg)
        self.assertFalse(ok)
        spy.assert_not_called()

    def test_kill_b_ref_field_never_reaches_the_executor(self):
        """Constructs a `ref:` line in the exact shape doc/bugs/BUG-0040.md
        carries (a live `make clean`), runs it through the F1/F2 scan
        pipeline, and asserts the executor is invoked zero times — proving
        architecturally that `ref:` text never reaches subprocess.run,
        not merely that this one string happens to look safe."""
        sample = "ref: cd sim && make clean && make lint-diff\n"
        with mock.patch.object(subprocess, "run") as spy:
            f1 = docsx.check_f1_text(self.cfg, "synthetic.md", sample)
            f2 = docsx.check_f2_text(self.cfg, "synthetic.md", sample)
        spy.assert_not_called()
        # No docsx:count/bidiff marker in the sample, so neither family
        # even has an opinion about it (further confirming nothing tried
        # to interpret the ref: text as a marker).
        self.assertEqual(f1, [])

    def test_kill_proof_cli_reports_both(self):
        rc = docsx.cmd_kill_proof(self.cfg)
        self.assertEqual(rc, 0)


# ---------------------------------------------------------------------------
# End-to-end `--check` over a fixture project tree (subprocess, mirrors
# test_docs.py's convention).
# ---------------------------------------------------------------------------
class TestCheckIntegration(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="docsx_it_"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        make_project(self.tmp, profile="copilot")
        (self.tmp / "README.md").write_text("# fixture\n", encoding="utf-8")
        (self.tmp / "doc" / "fw-feedback.md").write_text(
            "# fw feedback\n", encoding="utf-8")
        (self.tmp / "doc" / "milestone.md").write_text(
            "# milestone\n", encoding="utf-8")
        (self.tmp / "doc" / "coverage-waivers.md").write_text(
            "# cw\n", encoding="utf-8")
        (self.tmp / "doc" / "docsx-baseline.md").write_text(
            "# docsx baseline\n\n| id | family | locus | rev_ref |\n"
            "| --- | --- | --- | --- |\n", encoding="utf-8")

    def test_clean_fixture_passes(self):
        cp = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertIn("docsx-check passed", cp.stdout)

    def test_dead_reference_in_readme_fails_and_fix_restores_green(self):
        readme = self.tmp / "README.md"
        readme.write_text(
            "# fixture\n\nsee `workflow/nonexistent.md`\n", encoding="utf-8")
        cp = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("workflow/nonexistent.md", cp.stdout)
        readme.write_text("# fixture\n", encoding="utf-8")
        cp2 = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp2.returncode, 0, cp2.stdout + cp2.stderr)

    def test_uncited_baseline_row_fails(self):
        (self.tmp / "doc" / "docsx-baseline.md").write_text(
            "# docsx baseline\n\n| id | family | locus | rev_ref |\n"
            "| --- | --- | --- | --- |\n"
            "| BL-0001 | F2 | README.md:3:workflow/ghost.md | |\n",
            encoding="utf-8")
        (self.tmp / "README.md").write_text(
            "# fixture\n\nsee `workflow/ghost.md`\n", encoding="utf-8")
        cp = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("rev_ref is empty", cp.stdout)


if __name__ == "__main__":
    unittest.main()
