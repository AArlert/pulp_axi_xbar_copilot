"""Guard tests for docs.py — including the fuse test for the
milestone-signoff bug that drifted once (ppa BUG-011: `any(generator)` is
always truthy, so the signoff-file check silently passed).

F2/F4/F5 + BUG-0053 tool-marker-leak unit tests below (TestF2.. through
TestToolMarkerLeak) migrated from the retired scripts/docsx.py's
scripts/tests/test_docsx.py per doc/fw-feedback.md FB-40 — F1/F3/F7/F10 +
the §12 executor's tests were deleted outright (the checked object no
longer exists), F2/F4/F5/BUG-0053's tests survive, adapted to call docs.py
directly."""
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
import docs as docs_module

from fixture import (make_project, run, set_scenario_green, pin_spec, _table,
                     EN, ZH)


class DocsBase(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="iverif_test_"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        make_project(self.tmp)

    def doc(self, name):
        return self.tmp / "doc" / name


class TestCheck(DocsBase):
    def test_clean_fixture_passes(self):
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertIn("docs-check passed", cp.stdout)

    def test_green_without_evidence_fails(self):
        set_scenario_green(self.tmp, with_evidence=False)
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("evidence file missing", cp.stdout)

    def test_evidence_without_replay_line_fails(self):
        set_scenario_green(self.tmp,
                           evidence_first_line="just some excerpt text")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("not a replay command", cp.stdout)

    def test_ghost_reference_fails(self):
        fm = self.doc("feature-matrix.md")
        fm.write_text("# Feature matrix\n\n" + _table(EN["fm_header"], [
            "| F-001 | M1 | smoke | (all) | M1-99 |"]), encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("ghost reference", cp.stdout)

    def test_closed_bug_without_verify_fails(self):
        bugs = self.doc("bugs.md")
        bugs.write_text("# Bugs\n\n" + _table(EN["bug_header"], [
            "| BUG-001 | CLOSED | TB | x | TEST=t SEED=1 | y | abc123 | - |"]),
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("closure", cp.stdout)

    def test_bad_status_json_fails(self):
        self.doc("status.jsonl").write_text('{"date": broken\n',
                                            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("not valid JSON", cp.stdout)

    def test_spec_sha_mismatch_fails(self):
        spec = self.doc("spec.md")
        spec.write_text(spec.read_text(encoding="utf-8") + "\nsneaky edit\n",
                        encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("pinned sha256", cp.stdout)

    def test_tracked_junk_file_fails(self):
        subprocess.run(["git", "init", "-q", str(self.tmp)], check=True)
        (self.tmp / ".Makefile.swp").write_text("junk", encoding="utf-8")
        subprocess.run(["git", "-C", str(self.tmp), "add", "-f",
                        ".Makefile.swp"], check=True)
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("junk file tracked by git", cp.stdout)

    def test_fl_page_schema_enforced_for_terminal_bug(self):
        set_scenario_green(self.tmp)
        ev_rel = "doc/evidence/v0.1.0/M1-01.log"
        self.doc("bugs.md").write_text(
            "# Bugs\n\n" + _table(EN["bug_header"], [
                "| BUG-001 | CLOSED | TB | see doc/bugs/BUG-001.md | "
                "TEST=t SEED=1 | y | abc123 | %s |" % ev_rel]),
            encoding="utf-8")
        page = self.doc("bugs") / "BUG-001.md"
        page.write_text("# BUG-001\n\n## symptom\nmismatch\n",
                        encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("regression_guard", cp.stdout)
        # A complete chart passes.
        page.write_text(
            "# BUG-001\n"
            "\n## symptom\nmismatch\n"
            "\n## first_anomaly\nsignal: x time: 10ns\n"
            "\n## taxonomy\nTB_BUG\n"
            "\n## rca\nchain\n"
            "\n## fix\ncommit: abc123\n"
            "\n## rerun\n%s\n"
            "\n## regression_guard\ntype: directed_test ref: t\n"
            "\n## similar\nnone searched-on: mismatch\n" % ev_rel,
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout)

    def test_zh_preset_passes(self):
        zh = Path(tempfile.mkdtemp(prefix="iverif_zh_"))
        self.addCleanup(shutil.rmtree, zh, True)
        make_project(zh, columns="zh")
        cp = run(zh, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        set_scenario_green(zh, columns="zh")
        cp = run(zh, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)


class TestSignoffGate(DocsBase):
    """Fuse for the drifted-once bug: with every scenario green and the
    evidence dir existing, `--next` must still demand the signoff file, and
    only report completion once it exists. Under the buggy `any(generator)`
    the first assertion fails — which is exactly the point."""

    def _green_with_regress_summary(self):
        set_scenario_green(self.tmp)
        ev_dir = self.tmp / "doc" / "evidence" / "v0.1.0"
        (ev_dir / "result_summary.txt").write_text(
            "fixture regression passed=1/1\n", encoding="utf-8")
        self.doc("bugs.md").write_text(
            "# Bugs\n\n" + _table(EN["bug_header"], [
                "| KILL-001 | KILL | TB | M1 scoreboard KILL: injected "
                "off-by-one, red->green | - | - | - | - |"]),
            encoding="utf-8")
        return ev_dir

    def test_signoff_missing_is_reported(self):
        self._green_with_regress_summary()
        cp = run(self.tmp, "docs.py", "--next", check=True)
        self.assertIn("still missing", cp.stdout)
        self.assertIn("signoff", cp.stdout)

    def test_signoff_present_completes_milestone(self):
        ev_dir = self._green_with_regress_summary()
        (ev_dir / "signoff-M1.md").write_text("# signoff\nverdict: pass\n",
                                              encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--next", check=True)
        self.assertNotIn("still missing", cp.stdout)
        self.assertIn("three hard conditions met", cp.stdout)

    def test_signoff_command_lists_conditions(self):
        self._green_with_regress_summary()
        cp = run(self.tmp, "docs.py", "--check", "--milestone", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        self.assertIn("[PASS] 1.", cp.stdout)
        self.assertIn("[PASS] 2.", cp.stdout)
        self.assertIn("[PASS] 3.", cp.stdout)
        self.assertIn("[PASS] 4.", cp.stdout)  # kill coverage
        self.assertIn("not yet", cp.stdout)  # signoff file itself

    def test_signoff_command_fails_with_open_scenario(self):
        cp = run(self.tmp, "docs.py", "--check", "--milestone", "1")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("[FAIL] 1.", cp.stdout)
        self.assertIn("M1-01", cp.stdout)

    def test_open_bug_blocks_completion_message(self):
        """BUG-0054: --next's milestone-completion block used to ignore bug
        status entirely — it only checked regress evidence + signoff file
        existence, so it could print "three hard conditions met" with bugs
        still OPEN. Red/green per REV-037 §BUG-0054's prescribed evaluator
        reuse (not string-matching the signoff file's prose verdict)."""
        ev_dir = self._green_with_regress_summary()
        (ev_dir / "signoff-M1.md").write_text("# signoff\nverdict: pass\n",
                                              encoding="utf-8")
        # red: an OPEN bug alongside the existing KILL-001 row must block
        # the completion message even though regress+signoff are in place.
        self.doc("bugs.md").write_text(
            "# Bugs\n\n" + _table(EN["bug_header"], [
                "| KILL-001 | KILL | TB | M1 scoreboard KILL: injected "
                "off-by-one, red->green | - | - | - | - |",
                "| BUG-0001 | OPEN | TB | still open | - | - | - | - |"]),
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--next", check=True)
        self.assertNotIn("three hard conditions met", cp.stdout)
        self.assertIn("still missing", cp.stdout)
        self.assertIn("BUG-0001", cp.stdout)
        # green: closing it out (with a valid replay-command evidence line)
        # restores the completion message.
        (ev_dir / "BUG-0001.log").write_text("CMD: true\nexpect: ok\n",
                                              encoding="utf-8")
        self.doc("bugs.md").write_text(
            "# Bugs\n\n" + _table(EN["bug_header"], [
                "| KILL-001 | KILL | TB | M1 scoreboard KILL: injected "
                "off-by-one, red->green | - | - | - | - |",
                "| BUG-0001 | CLOSED | TB | fixed | - | y | abc123 | "
                "doc/evidence/v0.1.0/BUG-0001.log |"]),
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--next", check=True)
        self.assertIn("three hard conditions met", cp.stdout)

    def test_kill_coverage_with_archived_row(self):
        """Regression for FB-29: check_kill_coverage() must scan both live
        bugs.md and bugs_archive.md (not just live). When a KILL row has been
        archived, it still counts toward the milestone's kill coverage."""
        set_scenario_green(self.tmp)
        ev_dir = self.tmp / "doc" / "evidence" / "v0.1.0"
        (ev_dir / "result_summary.txt").write_text(
            "fixture regression passed=1/1\n", encoding="utf-8")
        # Put KILL row in live bugs.md (empty)
        self.doc("bugs.md").write_text(
            "# Bugs\n\n" + _table(EN["bug_header"]),
            encoding="utf-8")
        # Put KILL row in bugs_archive.md
        (self.tmp / "doc" / "archive" / "bugs-archive.md").write_text(
            "# Bugs archive\n\n" + _table(EN["bug_header"], [
                "| KILL-001 | KILL | TB | M1 scoreboard KILL: injected "
                "off-by-one, red->green | - | - | - | - |"]),
            encoding="utf-8")
        # Verify that kill coverage still passes even with archived KILL row
        cp = run(self.tmp, "docs.py", "--check", "--milestone", "1")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        self.assertIn("[PASS] 4.", cp.stdout)  # kill coverage
        self.assertIn("KILL-001", cp.stdout)  # the archived KILL row is found


class TestArchive(DocsBase):
    def test_archive_roundtrip(self):
        # Inflate log.md to 6 blocks and status.jsonl to 14 lines.
        log = self.doc("log.md")
        blocks = "".join("## [0.1.0] 2026-07-%02d block%d\n\n- x\n\n"
                         % (18 - i, i) for i in range(6))
        log.write_text("# Work log\n\n" + blocks, encoding="utf-8")
        st = self.doc("status.jsonl")
        lines = [json.dumps({"date": "2026-07-01", "version": "0.1.0",
                             "summary": "s%d" % i}) for i in range(14)]
        st.write_text("\n".join(lines) + "\n", encoding="utf-8")

        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("docs-archive", cp.stdout)

        run(self.tmp, "docs.py", "--archive", check=True)
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        # Rolling files trimmed to keep limits; archives newest-first.
        self.assertEqual(len([l for l in st.read_text(encoding="utf-8")
                              .splitlines() if l.strip()]), 8)
        arch = (self.tmp / "doc" / "archive" / "status-archive.jsonl")
        archived = [l for l in arch.read_text(encoding="utf-8").splitlines()
                    if l.strip()]
        self.assertEqual(len(archived), 6)
        self.assertIn("s8", archived[0])

    def test_archive_idempotent(self):
        run(self.tmp, "docs.py", "--archive", check=True)
        cp = run(self.tmp, "docs.py", "--archive", check=True)
        self.assertIn("nothing to archive", cp.stdout)


class TestAcceptedState(DocsBase):
    """FB-17: scheduled debt — neither WONTFIX-as-later nor OPEN-as-decided."""
    def add_bug(self, status, root="REV-002 accepted, do in M2"):
        bugs = self.doc("bugs.md")
        bugs.write_text(bugs.read_text(encoding="utf-8")
                        + "| BUG-0009 | %s | TB | corner x | TEST=x SEED=1 "
                        "| %s | - | - |\n" % (status, root),
                        encoding="utf-8")
        # F5/BUG-0067 (FB-40): every bug row needs a detail page.
        (self.doc("bugs") / "BUG-0009.md").write_text(
            "# BUG-0009\n", encoding="utf-8")

    def test_accepted_unexpired_passes_and_due_surfaces(self):
        self.add_bug("ACCEPTED@M2")   # fixture milestone is M1: unexpired
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        cp = run(self.tmp, "docs.py", "--next", check=True)
        self.assertNotIn("accepted debt due", cp.stdout)

    def test_accepted_due_this_milestone_surfaces_in_next(self):
        self.add_bug("ACCEPTED@M1")   # == current: check ok, next surfaces
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        cp = run(self.tmp, "docs.py", "--next", check=True)
        self.assertIn("accepted debt due", cp.stdout)
        cp = run(self.tmp, "docs.py", "--check", "--milestone", "1")
        self.assertIn("accepted debt due", cp.stdout)

    def test_accepted_overdue_fails_check(self):
        self.add_bug("ACCEPTED@M0")   # < current milestone: expired
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("expired", cp.stdout)

    def test_rubric_and_tool_agree_on_condition3(self):
        # FB-18(a): 0.5.0 updated the tool but not rubric.md — the card's
        # criteria source and the tool gave opposite verdicts on the same
        # gate. Pin both surfaces to the ACCEPTED-aware wording, and pin
        # the accepted-debt rationale spot check (FB-18(b)) on both.
        rubric = (Path(__file__).resolve().parents[2] / "workflow"
                  / "review.md").read_text(encoding="utf-8")
        self.assertIn("ACCEPTED@M<n>", rubric)
        self.assertIn("8. **Accepted debt is real debt.**", rubric)
        self.assertIn("9. **Chain audit answered.**", rubric)
        cp = run(self.tmp, "docs.py", "--check", "--milestone", "1")
        self.assertIn("ACCEPTED-unexpired", cp.stdout)
        self.assertIn("8. accepted debt", cp.stdout)
        # FB-21: the audit was born for signoff yet nothing consumed it —
        # --signoff must surface the full report (visibility, not a gate).
        self.assertIn("9. chain audit answered", cp.stdout)
        self.assertIn("== chain audit ==", cp.stdout)

    def test_accepted_without_rev_reference_fails(self):
        self.add_bug("ACCEPTED@M2", root="just later")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("rev-signed rationale", cp.stdout)


class TestTableStructure(DocsBase):
    def test_unescaped_pipe_row_fails_check(self):
        # pulp FB-14: an unescaped | in a cell shifts later columns and
        # state gates read the wrong cells — docs-check must catch both
        # directions (too many / too few cells).
        bugs = self.doc("bugs.md")
        bugs.write_text(bugs.read_text(encoding="utf-8")
                        + "| BUG-1 | OPEN | TB | full=|cnt busted | r "
                        "| - | - | - |\n", encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("escape literal |", cp.stdout)
        self.assertIn("bugs.md", cp.stdout)


class TestChainAudit(DocsBase):
    def test_dangling_ref_fails(self):
        self.doc("spec.md").write_text("# Spec\n\n## 1. intro\n",
                                       encoding="utf-8")
        (self.doc("testplan.md")).write_text(
            "# Testplan\n\n" + _table(EN["tp_header"], [
                "| M1-01 | M1 | checks SPEC-9.9 | base | 🔲 | - | - |"]),
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("SPEC-9.9", cp.stdout)
        self.assertIn("FAIL", cp.stdout)

    def test_clean_audit_reports_gaps_without_failing(self):
        pin_spec(self.tmp,
                "# Spec\n\n## 1. x\n### 1.1 y\nrule §1.2.3 inline\n")
        (self.doc("testplan.md")).write_text(
            "# Testplan\n\n" + _table(EN["tp_header"], [
                "| M1-01 | M1 | SPEC-1.1 basic | base | 🔲 | - | - |",
                "| M1-02 | M1 | SPEC-1.2.3.4 deep | base | 🔲 | - | - |",
                "| M1-03 | M1 | no ref here | base | 🔲 | - | - |"]),
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        self.assertIn("dangling spec refs (cited, no such section): 0",
                      cp.stdout)
        self.assertIn("citing no spec clause: 1 — M1-03", cp.stdout)
        self.assertIn("M1-02 SPEC-1.2.3.4→§1.2.3", cp.stdout)
        self.assertIn("scenarios in no feature-matrix row: 2", cp.stdout)

    def test_uncited_full_print_numeric_order(self):
        # FB-22: string sort silently truncated the highest-numbered
        # chapters (the next milestone's territory). Numeric order, no cut.
        pin_spec(self.tmp, "# Spec\n\n### 10.1 late\n### 2.1 early\n")
        (self.doc("testplan.md")).write_text(
            "# Testplan\n\n" + _table(EN["tp_header"], [
                "| M1-01 | M1 | no ref | base | 🔲 | - | - |"]),
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        self.assertIn("cited by no scenario: 2 — §2.1, §10.1", cp.stdout)


class TestGuards(DocsBase):
    """FB-40: `--guards` reads doc/guards.md (F4's table), not doc/bugs/
    *.md pages' `## regression_guard` sections (BUG-0015's era) — the
    output *contract* (the "== <bugs> guard (hit: ...) ==" header + "N
    guard(s) matched" trailer every grep-based consumer relies on,
    REV-037 S1-S3 / the dispatch SKILL self-check) is unchanged."""
    def test_guards_query_matches_paths(self):
        # pulp BUG-0015判例 fuse: a guard that names its victim files must
        # surface when those files are about to be touched.
        (self.doc("guards.md")).write_text(
            "# guards\n\n| id | bugs | type | paths | check | note |\n"
            "| --- | --- | --- | --- | --- | --- |\n"
            "| G-0001 | BUG-0001 | checklist | tb/sva/*.sv, sim/Makefile "
            "| - | fold tracked-state reads before property use |\n",
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--guards", "tb/sva/stall_sva.sv",
                 "rtl/core.sv", check=True)
        self.assertIn("BUG-0001", cp.stdout)
        self.assertIn("fold tracked-state reads", cp.stdout)
        self.assertIn("1 guard(s) matched", cp.stdout)
        cp = run(self.tmp, "docs.py", "--guards", "rtl/core.sv", check=True)
        self.assertIn("0 guard(s) matched", cp.stdout)


class TestChainRepro(DocsBase):
    def test_chain_and_repro(self):
        set_scenario_green(self.tmp)
        cp = run(self.tmp, "docs.py", "--check", "--scen", "M1-01", check=True)
        self.assertIn("evidence head", cp.stdout)
        self.assertIn("make run TEST=fixture_test SEED=1", cp.stdout)
        cp = run(self.tmp, "docs.py", "--repro", "M1-01", check=True)
        self.assertEqual(cp.stdout.strip(),
                         "make run TEST=fixture_test SEED=1")

    def test_repro_without_command_fails(self):
        cp = run(self.tmp, "docs.py", "--repro", "M1-01")
        self.assertNotEqual(cp.returncode, 0)


class TestProfiles(DocsBase):
    def test_learning_next_speaks_to_human(self):
        cp = run(self.tmp, "docs.py", "--next", check=True)
        self.assertIn("learning profile", cp.stdout)
        self.assertNotIn("dispatch", cp.stdout.lower())

    def test_next_phrases_override(self):
        # FB-8 (pulp_axi_xbar): `--next` wording carries role assumptions
        # ("dispatch DE card") that a vendored-DUT project cannot correct
        # without editing scripts/. The iverif.json hook remaps a phrase;
        # an unknown key fails loudly instead of silently no-opping.
        ov = Path(self.tmp.parent) / (self.tmp.name + "_np")
        self.addCleanup(shutil.rmtree, ov, True)
        make_project(ov, overrides={"next_phrases_override": {
            "unverified": "OVERRIDDEN %(mod)s -> %(scenes)s"}})
        cp = run(ov, "docs.py", "--next", check=True)
        self.assertIn("OVERRIDDEN (all) -> M1-01", cp.stdout)
        bad = Path(self.tmp.parent) / (self.tmp.name + "_npbad")
        self.addCleanup(shutil.rmtree, bad, True)
        make_project(bad, overrides={"next_phrases_override": {
            "no_such_phrase": "x"}})
        cp = run(bad, "docs.py", "--next")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("no_such_phrase", cp.stderr + cp.stdout)

    def test_copilot_next_derives_deliverable_owner(self):
        # FB-8 root fix (user ruling 2026-07-28): the deliverable-owning
        # role in `--next` copilot wording derives from delivery config the
        # project already declares — tb/-rooted glob → DV (vendored-DUT
        # repos), zero config needed. Explicit delivery.owner overrides.
        def co_project(suffix, cfg_overrides, with_prompt):
            p = Path(self.tmp.parent) / (self.tmp.name + suffix)
            self.addCleanup(shutil.rmtree, p, True)
            make_project(p, profile="copilot", overrides=cfg_overrides)
            (p / "doc" / "feature-matrix.md").write_text(
                "# Feature matrix\n\n" + _table(EN["fm_header"], [
                    "| F-001 | M1 | smoke bring-up | (all) | M1-01 |",
                    "| F-002 | M1 | widget feature | widget | M1-01 |"]),
                encoding="utf-8")
            if with_prompt:
                (p / "doc" / "design-prompt" / "widget.md").write_text(
                    "# widget\n", encoding="utf-8")
            return p

        # fixture glob is tb/{name}.sv → derived owner DV, both phrases
        p = co_project("_dv", {}, with_prompt=True)
        cp = run(p, "docs.py", "--next", check=True)
        self.assertIn("dispatch DV card", cp.stdout)
        p = co_project("_dvp", {}, with_prompt=False)
        cp = run(p, "docs.py", "--next", check=True)
        self.assertIn("rev gate before any DV card", cp.stdout)
        # explicit owner beats the derivation
        p = co_project("_de", {"delivery": {"glob": "tb/{name}.sv",
                                            "owner": "de"}},
                       with_prompt=True)
        cp = run(p, "docs.py", "--next", check=True)
        self.assertIn("dispatch DE card", cp.stdout)
        # invalid owner fails loudly
        p = co_project("_bad", {"delivery": {"glob": "tb/{name}.sv",
                                             "owner": "orch"}},
                       with_prompt=True)
        cp = run(p, "docs.py", "--next")
        self.assertNotEqual(cp.returncode, 0)
        self.assertIn("delivery.owner", cp.stderr + cp.stdout)

    def test_copilot_requires_design_prompt_dir(self):
        co = Path(self.tmp.parent) / (self.tmp.name + "_co")
        self.addCleanup(shutil.rmtree, co, True)
        make_project(co, profile="copilot")
        cp = run(co, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout)
        (co / "doc" / "design-prompt" / "README.md").unlink()
        cp = run(co, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("design-prompt", cp.stdout)


class TestExplore(DocsBase):
    """0.7.1 spec-gap explorer: the frontier is listed on demand and nagged
    at planning time — and ONLY at planning time (a permanent nag would be
    skimmed, the FB-19 shape)."""

    def spec_with_sections(self):
        spec = ("# Spec\n\n## 1.1 handshake\nSPEC-1.1 the DUT shall "
                "smoke.\n\n## 1.2 backpressure\nstall behavior.\n\n"
                "## Change record\n\n"
                + _table("| date | section | change |",
                         ["| 2026-07-19 | all | initial |"]))
        self.doc("spec.md").write_text(spec, encoding="utf-8")

    def test_explore_lists_only_uncited_sections(self):
        self.spec_with_sections()
        # fixture testplan row M1-01 cites SPEC-1.1 via its description
        tp = self.doc("testplan.md")
        tp.write_text(tp.read_text(encoding="utf-8").replace(
            "| M1-01 | M1 | smoke |", "| M1-01 | M1 | smoke SPEC-1.1 |"),
            encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--explore")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertIn("§1.2", cp.stdout)
        self.assertIn("backpressure", cp.stdout)  # heading title carried
        self.assertNotIn("§1.1", cp.stdout)
        self.assertIn("narrowing must be declared", cp.stdout)

    def test_next_nags_explore_only_while_milestone_unplanned(self):
        self.spec_with_sections()
        # move to M2: no M2 rows registered yet → planning-time nag
        (self.tmp / "version.json").write_text(
            '{"version": "0.2.0", "milestone": "M2"}\n', encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--next")
        self.assertIn("make explore", cp.stdout)
        # first M2 row registered → the nag must fall silent
        tp = self.doc("testplan.md")
        tp.write_text(tp.read_text(encoding="utf-8")
                      + "| M2-01 | M2 | bp SPEC-1.2 | baseline | 🔲 | - "
                        "| - |\n", encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--next")
        self.assertNotIn("make explore", cp.stdout)


class TestRiskGradeContract(unittest.TestCase):
    """0.8.0 L0-L3 fuse: the grade table lives in CLAUDE.md now (dispatch/
    SKILL.md and the profile-specific agent cards it named are retired)."""

    def test_claude_md_carries_risk_grades(self):
        fw = Path(__file__).resolve().parents[2]
        text = (fw / "CLAUDE.md").read_text(encoding="utf-8")
        for token in ("L0", "L1", "L2", "L3", "haiku", "sonnet", "opus"):
            self.assertIn(token, text, token)
        arch = (fw / ".claude" / "agents" / "arch.md"
                ).read_text(encoding="utf-8")
        self.assertIn("Spec-gap sweep", arch)
        self.assertIn("make explore", arch)


# ---------------------------------------------------------------------------
# FB-40 migration: F2/F4/F5 + BUG-0053 tool-marker-leak, formerly
# scripts/docsx.py + scripts/tests/test_docsx.py. Per family: at least one
# red_when injection + its green counterpart (doc_mechanization.md §15's
# original rule, still honored for the survivor families).
# ---------------------------------------------------------------------------
def _fake_cfg(root):
    root = Path(root)
    doc = root / "doc"
    return SimpleNamespace(
        root=root, C={"tp_status": "status", "bug_id": "id",
                     "bug_suspect": "suspect"},
        testplan=doc / "testplan.md", bugs=doc / "bugs.md",
        bugs_archive=doc / "archive" / "bugs-archive.md",
        bug_pages=doc / "bugs", evidence_dir=doc / "evidence",
        guards=doc / "guards.md")


class TmpRootBase(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="docs_f2f4f5_test_"))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.cfg = _fake_cfg(self.tmp)


class TestF2Merged(TmpRootBase):
    def test_existing_path_is_green(self):
        (self.tmp / "doc").mkdir()
        (self.tmp / "doc" / "spec.md").write_text("x", encoding="utf-8")
        text = "see `doc/spec.md` for details\n"
        self.assertEqual(docs_module.check_f2_text(self.cfg, "README.md",
                                                    text), [])

    def test_dead_path_is_red(self):
        """red_when (design contract F2): README.md gains a reference to a
        nonexistent workflow/ path."""
        text = "see `workflow/nonexistent.md` for details\n"
        out = docs_module.check_f2_text(self.cfg, "README.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("workflow/nonexistent.md", out[0][1])

    def test_frozen_prefix_reference_does_not_misfire(self):
        """red_when's counter-example: a doc/evidence/ reference must NOT
        turn red even though the target file does not exist (FB-23)."""
        text = "see `doc/evidence/vX/gone.md` for details\n"
        self.assertEqual(docs_module.check_f2_text(self.cfg, "README.md",
                                                    text), [])

    def test_glob_token_with_matches_is_green(self):
        (self.tmp / "doc" / "bugs").mkdir(parents=True)
        (self.tmp / "doc" / "bugs" / "BUG-0001.md").write_text(
            "x", encoding="utf-8")
        text = "see `doc/bugs/*.md`\n"
        self.assertEqual(docs_module.check_f2_text(self.cfg, "README.md",
                                                    text), [])

    def test_glob_token_with_no_matches_is_red(self):
        text = "see `scripts/no_such_dir/*.py`\n"
        out = docs_module.check_f2_text(self.cfg, "README.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("glob", out[0][1])

    def test_fenced_code_block_token_is_exempt(self):
        """FB-40's new F2 exemption channel (replaces the retired F10
        baseline table): a dead path quoted inside a fenced code block is
        a worked example, not a live reference — auto-skipped, no marker
        needed. Same string outside a fence is still red (proves this is
        fence-awareness, not a blanket path-token pass-through)."""
        fenced = "see:\n```\nworkflow/nonexistent.md\n```\n"
        self.assertEqual(docs_module.check_f2_text(self.cfg, "README.md",
                                                    fenced), [])
        unfenced = "see workflow/nonexistent.md\n"
        out = docs_module.check_f2_text(self.cfg, "README.md", unfenced)
        self.assertEqual(len(out), 1)

    def test_docsx_skip_marker_exempts_named_token_file_wide(self):
        """The narrower, budget-capped fallback exemption for a token that
        cannot be fenced (e.g. sits inside a markdown table cell): the
        marker names the exact literal token(s); every occurrence of that
        token in the *same file* is exempt, not the whole file/line."""
        text = ("<!-- docsx:skip workflow/nonexistent.md -->\n"
               "first mention: workflow/nonexistent.md\n"
               "second mention: workflow/nonexistent.md\n")
        self.assertEqual(docs_module.check_f2_text(self.cfg, "README.md",
                                                    text), [])
        # A *different* dead token on the same file is not covered by a
        # marker that named something else.
        text2 = ("<!-- docsx:skip workflow/nonexistent.md -->\n"
                "workflow/other-ghost.md\n")
        out = docs_module.check_f2_text(self.cfg, "README.md", text2)
        self.assertEqual(len(out), 1)
        self.assertIn("other-ghost.md", out[0][1])


class TestF4Merged(TmpRootBase):
    def test_script_row_with_check_present_is_green(self):
        rows = [{"id": "G-0001", "bugs": "BUG-0001", "type": "script",
                "paths": "f.txt", "check": "grep -q hi f.txt",
                "note": "n"}]
        viol, warns = docs_module.check_f4(self.cfg, rows)
        self.assertEqual(viol, {})

    def test_checklist_row_is_not_red_by_default(self):
        """Behavior change from the pre-FB-40 docsx.py rule (red_when there:
        'a new type: checklist row is red unless a baseline row exempts
        it'): that rule was entirely F10-dependent — every checklist row
        was unconditionally 'in violation' until the (now-retired) baseline
        table's cross-reference silenced it. There is no successor
        authorization channel (re-litigating 49 already rev-approved rows
        is out of this migration's scope, doc/fw-feedback.md FB-40) — a
        checklist row is simply legal on its own now, same as `type` being
        any other GUARD_TYPES value."""
        rows = [{"id": "G-0002", "bugs": "BUG-0002", "type": "checklist",
                "paths": "f.txt", "check": "-", "note": "n"}]
        viol, warns = docs_module.check_f4(self.cfg, rows)
        self.assertEqual(viol, {})

    def test_non_ascii_paths_is_red(self):
        """red_when (design contract F4): paths cell with full-width
        parens (BUG-0061's exact pollution shape) -> red."""
        (self.tmp / "f.txt").write_text("hi\n", encoding="utf-8")
        rows = [{"id": "G-0003", "bugs": "BUG-0003", "type": "script",
                "check": "grep -q hi f.txt",
                "paths": "doc/milestone.md（M4/M5 节）", "note": "n"}]
        viol, warns = docs_module.check_f4(self.cfg, rows)
        self.assertIn("doc/guards.md:G-0003:paths", viol)

    def test_script_row_with_empty_check_is_red(self):
        rows = [{"id": "G-0004", "bugs": "BUG-0004", "type": "script",
                "paths": "f.txt", "check": "-", "note": "n"}]
        viol, warns = docs_module.check_f4(self.cfg, rows)
        self.assertIn("doc/guards.md:G-0004:check", viol)

    def test_zero_match_paths_token_is_a_warning_not_an_error(self):
        (self.tmp / "f.txt").write_text("hi\n", encoding="utf-8")
        rows = [{"id": "G-0005", "bugs": "BUG-0005", "type": "script",
                "check": "grep -q hi f.txt", "paths": "no/such/file.sv",
                "note": "n"}]
        viol, warns = docs_module.check_f4(self.cfg, rows)
        self.assertEqual(viol, {})
        self.assertEqual(len(warns), 1)
        self.assertIn("zero matches", warns[0])


class TestF5Merged(TmpRootBase):
    def setUp(self):
        super().setUp()
        (self.tmp / "doc" / "archive").mkdir(parents=True, exist_ok=True)
        (self.tmp / "doc" / "bugs").mkdir(exist_ok=True)
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status | suspect |\n| --- | --- | --- |\n",
            encoding="utf-8")
        (self.tmp / "doc" / "archive" / "bugs-archive.md").write_text(
            "| id | status | suspect |\n| --- | --- | --- |\n",
            encoding="utf-8")
        (self.tmp / "doc" / "testplan.md").write_text("# tp\n",
                                                       encoding="utf-8")

    def test_bug_row_with_page_is_green(self):
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status | suspect |\n| --- | --- | --- |\n"
            "| BUG-0001 | OPEN | TB |\n", encoding="utf-8")
        (self.tmp / "doc" / "bugs" / "BUG-0001.md").write_text(
            "# BUG-0001\n", encoding="utf-8")
        self.assertEqual(docs_module.check_f5_bug_pages(self.cfg), {})

    def test_bug_row_without_page_is_red(self):
        """red_when (design contract F5 == BUG-0067's own defect): a bug
        row with no doc/bugs/<id>.md page."""
        # BUG-9002 (not a real id): the low-numbered ids are deliberately
        # avoided here — they collide with F5_LEGACY_BUG_IDS, the fixed
        # REV-038 §B.1 pre-existing-debt allowlist (see check_f5_bug_pages).
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status | suspect |\n| --- | --- | --- |\n"
            "| BUG-9002 | OPEN | TB |\n", encoding="utf-8")
        viol = docs_module.check_f5_bug_pages(self.cfg)
        self.assertIn("bugs.md:BUG-9002", viol)

    def test_suspect_doc_row_without_page_is_green(self):
        """FB-39's suspect=doc lane (workflow/bugs.md: 'no detail page
        unless the RCA is non-obvious') — F5's row->page requirement does
        not apply to it."""
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status | suspect |\n| --- | --- | --- |\n"
            "| BUG-0003 | CLOSED | doc |\n", encoding="utf-8")
        self.assertEqual(docs_module.check_f5_bug_pages(self.cfg), {})

    def test_evidence_file_referenced_is_green(self):
        ev = self.tmp / "doc" / "evidence" / "v0.1.0"
        ev.mkdir(parents=True)
        (ev / "BUG-0001.log").write_text("log\n", encoding="utf-8")
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status | suspect |\n| --- | --- | --- |\n"
            "| BUG-0001 | CLOSED | TB | doc/evidence/v0.1.0/"
            "BUG-0001.log |\n", encoding="utf-8")
        self.assertEqual(docs_module.check_f5_evidence(self.cfg), {})

    def test_orphan_evidence_file_is_red(self):
        """red_when (design contract F5 == BUG-0060's own defect): a .log
        under doc/evidence/ that no bugs.md/testplan.md row cites."""
        ev = self.tmp / "doc" / "evidence" / "v0.1.0"
        ev.mkdir(parents=True)
        (ev / "orphan.log").write_text("log\n", encoding="utf-8")
        viol = docs_module.check_f5_evidence(self.cfg)
        self.assertIn("evidence:doc/evidence/v0.1.0/orphan.log", viol)

    def test_dangling_evidence_reference_is_red(self):
        (self.tmp / "doc" / "bugs.md").write_text(
            "| id | status | suspect |\n| --- | --- | --- |\n"
            "| BUG-0003 | CLOSED | TB | doc/evidence/v9.9.9/ghost.log |\n",
            encoding="utf-8")
        viol = docs_module.check_f5_evidence(self.cfg)
        self.assertIn("ref:doc/evidence/v9.9.9/ghost.log", viol)


class TestToolMarkerLeak(unittest.TestCase):
    def test_clean_text_is_green(self):
        text = "normal prose, no markers here\n"
        self.assertEqual(docs_module.check_tool_marker_leak("x.md", text),
                         [])

    def test_whole_line_marker_is_red(self):
        """red_when #1 (REV-037/REV-038 §C two-use-case KILL): appending
        the marker as its own whole line -> red."""
        text = "some record text\n</invoke>\n"
        out = docs_module.check_tool_marker_leak("x.md", text)
        self.assertEqual(len(out), 1)
        self.assertIn("</invoke>", out[0])

    def test_marker_inside_fenced_code_block_stays_green(self):
        """red_when #2 (the two-use-case KILL's other half): the exact
        same string, quoted inside a fenced code block, must NOT trip the
        check — substring/example quoting is not a leak."""
        text = "example:\n```\n</invoke>\n```\n"
        self.assertEqual(docs_module.check_tool_marker_leak("x.md", text),
                         [])

    def test_marker_as_substring_not_whole_line_is_green(self):
        text = "the tag `</invoke>` leaked into a record\n"
        self.assertEqual(docs_module.check_tool_marker_leak("x.md", text),
                         [])


class TestGuardPointerFlSchemaCompat(unittest.TestCase):
    """A-c2 carryover: a terminal-status detail page whose `##
    regression_guard` body is nothing but the one-line pointer the F4
    migration writes must still satisfy check_fl_page's "section present
    and non-empty" rule."""

    def test_pointer_only_guard_section_satisfies_fl_schema(self):
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


class TestMergedCheckIntegration(DocsBase):
    """End-to-end `--check` (subprocess) over the standard fixture, proving
    F2/F5's red->green through the real CLI, not just the unit functions."""

    def test_dead_reference_in_readme_fails_and_fix_restores_green(self):
        readme = self.tmp / "README.md"
        readme.write_text(
            "# fixture\n\nsee `workflow/nonexistent.md`\n", encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("workflow/nonexistent.md", cp.stdout)
        readme.write_text("# fixture\n", encoding="utf-8")
        cp2 = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp2.returncode, 0, cp2.stdout + cp2.stderr)

    def test_bug0053_tool_marker_two_use_case_end_to_end(self):
        target = self.doc("some_record.md")
        target.write_text("# a record\n\nnormal text\n", encoding="utf-8")
        cp0 = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp0.returncode, 0, cp0.stdout + cp0.stderr)
        target.write_text("# a record\n\nnormal text\n</invoke>\n",
                          encoding="utf-8")
        cp1 = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp1.returncode, 1)
        self.assertIn("tool-marker leak", cp1.stdout)
        target.write_text(
            "# a record\n\nnormal text\n```\n</invoke>\n```\n",
            encoding="utf-8")
        cp2 = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp2.returncode, 0, cp2.stdout + cp2.stderr)

    def test_orphan_detail_page_fails_and_row_restores_green(self):
        """Merged F5 direction (docs.py's pre-existing orphan-page check,
        now sharing one home with F5's row->page direction — 'two loci in
        the same domain, merged into one' per FB-40)."""
        page = self.doc("bugs") / "BUG-9999.md"
        page.write_text("# BUG-9999\n", encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("orphan detail page", cp.stdout)
        bugs = self.doc("bugs.md")
        bugs.write_text(bugs.read_text(encoding="utf-8")
                        + "| BUG-9999 | OPEN | TB | x | TEST=t SEED=1 | y "
                        "| - | - |\n", encoding="utf-8")
        cp2 = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp2.returncode, 0, cp2.stdout + cp2.stderr)


class TestSuspectDoc(DocsBase):
    """FB-39/FB-40: suspect=doc — the doc-bookkeeping fix-in-passing lane
    workflow/bugs.md already documents (`suspect` in `TB / DUT / spec /
    doc`), mechanized here for the parts docs.py's --check actually gates
    on: no detail page required, and CLOSED still needs verify_evidence."""

    def test_suspect_doc_row_without_detail_page_does_not_fail_check(self):
        bugs = self.doc("bugs.md")
        bugs.write_text(bugs.read_text(encoding="utf-8")
                        + "| BUG-0010 | WONTFIX | doc | stale example path "
                        "fixed in passing | CMD: true | "
                        "n/a | - | - |\n", encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)
        self.assertNotIn("BUG-0010", cp.stdout)

    def test_suspect_doc_row_cmd_form_min_repro_does_not_fail_check(self):
        """min_repro's `CMD: ...` form (workflow/bugs.md: 'suspect=doc
        rows: CMD: form instead' of TEST=/SEED=) is not flagged — docs.py
        does not validate bugs.md's min_repro column format at all (only
        testplan's repro cell is checked for SEED), so this is simply the
        least-surprising behavior: a CMD-form min_repro on a suspect=doc
        row must not become newly red as a side effect of this migration."""
        bugs = self.doc("bugs.md")
        bugs.write_text(bugs.read_text(encoding="utf-8")
                        + "| BUG-0011 | WONTFIX | doc | n/a | "
                        "CMD: make selftest | n/a | - | - |\n",
                        encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 0, cp.stdout + cp.stderr)

    def test_suspect_doc_closed_without_verify_evidence_still_fails(self):
        """CLOSED still requires verify_evidence non-empty regardless of
        suspect — check_evidence() is not suspect-conditional."""
        bugs = self.doc("bugs.md")
        bugs.write_text(bugs.read_text(encoding="utf-8")
                        + "| BUG-0012 | CLOSED | doc | stale link fixed | "
                        "CMD: true | n/a | abc123 | - |\n", encoding="utf-8")
        cp = run(self.tmp, "docs.py", "--check")
        self.assertEqual(cp.returncode, 1)
        self.assertIn("closure", cp.stdout)


if __name__ == "__main__":
    unittest.main()
