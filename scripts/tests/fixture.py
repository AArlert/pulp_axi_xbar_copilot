"""Test fixture: build a minimal valid project tree in a temp dir, with this
repo's scripts/ copied in verbatim. Tests mutate the tree, run the scripts
via subprocess, and assert on exit codes and output — the same surface a
clone sees."""
import hashlib
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent

EN = {
    "tp_header": "| id | milestone | description | config | status | evidence | repro |",
    "fm_header": "| id | milestone | feature | module | scenes |",
    "bug_header": ("| id | status | suspect | summary | min_repro | "
                   "root_cause | fix_commit | verify_evidence |"),
    "wv_header": "| # | file | line | rule | conclusion | review |",
    "spec_heading": "## Change record",
}
ZH = {
    "tp_header": "| ID | 里程碑 | 场景描述 | 配置 | 状态 | 证据 | 复现 |",
    "fm_header": "| 编号 | 里程碑 | 功能 | 模块 | 关联场景 |",
    "bug_header": ("| ID | 状态 | 疑似归属 | 现象摘要 | 最小复现 | "
                   "根因/裁决 | 修复 commit | 复验证据 |"),
    "wv_header": "| # | 文件 | 行 | 规则 | 结论(豁免/修复) | 复核(REV) |",
    "spec_heading": "## 修改记录",
}


def _sep(header):
    return "|" + "|".join(" --- " for _ in header.strip("|").split("|")) + "|"


def _table(header, rows=()):
    return "\n".join([header, _sep(header), *rows]) + "\n"


def pin_spec(root, text):
    """Write doc/spec.md with the given text (auto-appending a '## Change
    record' table if the text doesn't already carry one) and re-pin
    doc/spec.sha256 to match — the shape --check demands of a legal spec."""
    doc = Path(root) / "doc"
    if "## Change record" not in text and "# 修改记录" not in text:
        text = text.rstrip("\n") + ("\n\n## Change record\n\n"
            + _table("| date | section | change |",
                     ["| 2026-07-19 | all | initial |"]))
    (doc / "spec.md").write_text(text, encoding="utf-8")
    sha = hashlib.sha256((doc / "spec.md").read_bytes()).hexdigest()
    (doc / "spec.sha256").write_text(sha + "\n", encoding="utf-8")


def make_project(root, profile="learning", columns="en", overrides=None):
    """Lay down a minimal project that passes docs-check."""
    root = Path(root)
    L = EN if columns == "en" else ZH
    (root / "scripts").mkdir(parents=True, exist_ok=True)
    for py in SCRIPTS.glob("*.py"):
        shutil.copy(py, root / "scripts" / py.name)

    cfg = {"framework": "test", "profile": profile,
           "project_name": "fixture_proj", "columns_preset": columns,
           "delivery": {"glob": "tb/{name}.sv"}}
    if overrides:
        cfg.update(overrides)
    (root / "iverif.json").write_text(json.dumps(cfg), encoding="utf-8")
    (root / "version.json").write_text(
        '{"version": "0.1.0", "milestone": "M1"}\n', encoding="utf-8")
    (root / "CLAUDE.md").write_text("# fixture\n", encoding="utf-8")
    (root / "Makefile").write_text("# fixture\n", encoding="utf-8")

    doc = root / "doc"
    arch = doc / "archive"
    arch.mkdir(parents=True, exist_ok=True)
    (doc / "bugs").mkdir(exist_ok=True)

    (doc / "status.jsonl").write_text(
        '{"date": "2026-07-19", "version": "0.1.0", "summary": "seed"}\n',
        encoding="utf-8")
    (doc / "log.md").write_text(
        "# Work log\n\n## [0.1.0] 2026-07-19 seed\n\n**Done**\n- seed\n\n",
        encoding="utf-8")
    (doc / "testplan.md").write_text(
        "# Testplan\n\n" + _table(L["tp_header"], [
            "| M1-01 | M1 | smoke | baseline | 🔲 | - | - |"]),
        encoding="utf-8")
    (doc / "feature-matrix.md").write_text(
        "# Feature matrix\n\n" + _table(L["fm_header"], [
            "| F-001 | M1 | smoke bring-up | (all) | M1-01 |"]),
        encoding="utf-8")
    (doc / "bugs.md").write_text(
        "# Bugs\n\n" + _table(L["bug_header"]), encoding="utf-8")
    (doc / "lint-waivers.md").write_text(
        "# Lint waivers\n\n" + _table(L["wv_header"]), encoding="utf-8")

    spec = ("# Spec\n\nSPEC-1.1 the DUT shall smoke.\n\n%s\n\n"
            % L["spec_heading"]
            + _table("| date | section | change |",
                     ["| 2026-07-19 | all | initial |"]))
    (doc / "spec.md").write_text(spec, encoding="utf-8")
    sha = hashlib.sha256((doc / "spec.md").read_bytes()).hexdigest()
    (doc / "spec.sha256").write_text(sha + "\n", encoding="utf-8")

    (arch / "status-archive.jsonl").write_text("", encoding="utf-8")
    (arch / "log-archive.md").write_text("# Log archive\n", encoding="utf-8")
    (arch / "bugs-archive.md").write_text(
        "# Bugs archive\n\n" + _table(L["bug_header"]), encoding="utf-8")
    (arch / "lint-waivers-archive.md").write_text(
        "# Waiver archive\n\n" + _table(L["wv_header"]), encoding="utf-8")

    if profile == "copilot":
        dp = doc / "design-prompt"
        dp.mkdir(exist_ok=True)
        (dp / "README.md").write_text("# Design prompts\n", encoding="utf-8")
    return root


UVM_PASS_LOG = """\
UVM_INFO @ 0: reporter [RNTST] Running test fixture_test...
UVM_INFO scoreboard compare ok id=7
UVM_INFO uvm_report_server @ 345000: reporter [UVM/REPORT/SERVER]
--- UVM Report Summary ---

** Report counts by severity
UVM_INFO :    5
UVM_WARNING :    0
UVM_ERROR :    0
UVM_FATAL :    0
Summary: 12 assertions, 12 with attempts, 0 with failures
"""

UVM_FAIL_LOG = UVM_PASS_LOG.replace("UVM_ERROR :    0", "UVM_ERROR :    2")

# The BUG-014 shape: UVM side spotless (UVM_ERROR : 0) while the SVA engine
# reports a failed assertion — $error in an action block never reaches the
# UVM report server. Includes the real-world same-line tail form.
UVM_SVA_FAIL_LOG = UVM_PASS_LOG.replace(
    "Summary: 12 assertions, 12 with attempts, 0 with failures",
    '"../tb/sva/fixture_sva.sv", 45: tb_top.dut.a_done_hold: '
    "started at 155000ps failed at 165000ps  Offending 'done_o'\n"
    "Summary: 12 assertions, 12 with attempts, 1 with failures")

# A log produced without `-assert verbose`: clean UVM summary, no native
# assertion Summary line — unprovable, rejected under sva_enforce.
UVM_NOSVA_LOG = UVM_PASS_LOG.replace(
    "Summary: 12 assertions, 12 with attempts, 0 with failures\n", "")

PLAIN_PASS_LOG = """\
some tb output
final checks: 128 compare ok
Summary: 4 assertions, 4 with attempts, 0 with failures
$finish called
           V C S   S i m u l a t i o n   R e p o r t
Time: 12000 ns
CPU Time: 1.2 seconds
"""

PLAIN_FAIL_LOG = "Error: mismatch at 300ns\n" + PLAIN_PASS_LOG

# Non-UVM tb (ucli `run;exit`-driven `$stop`, e.g. upstream `tb_axi_xbar`)
# shape: the scoreboard verdict ("Simulation has ended!" / "Tests Failed: 0")
# prints well before the VCS completion banner, with unrelated tb noise in
# between — real-world shape that motivated FB-6 (pulp_axi_xbar).
PLAIN_NONUVM_VERDICT_LOG = """\
4098918000ns > Master 3: Got last R with id: 01110
Info: "../vendor/axi/test/tb_axi_xbar_pkg.sv", 73986: tb_axi_xbar_pkg: at time 4098928000 ps
Simulation has ended!
Tests Expected:                178296
Tests Conducted:               178296
Tests Failed:                       0
tb_axi_xbar.sv, 261 :           $stop();
noise line 1
noise line 2
noise line 3
noise line 4
noise line 5
noise line 6
Summary: 4 assertions, 4 with attempts, 0 with failures
           V C S   S i m u l a t i o n   R e p o r t
Time: 12000 ns
CPU Time: 1.2 seconds
"""


def run(root, script, *args, check=False):
    """Run a copied scripts/ script; returns CompletedProcess with utf-8
    captured output (emoji-safe on Windows consoles)."""
    env = dict(os.environ)
    env["PYTHONUTF8"] = "1"
    cp = subprocess.run(
        [sys.executable, str(Path(root) / "scripts" / script), *args],
        capture_output=True, text=True, encoding="utf-8", env=env,
        cwd=str(root))
    if check and cp.returncode != 0:
        raise AssertionError("%s %s failed (%d):\n%s\n%s"
                             % (script, " ".join(args), cp.returncode,
                                cp.stdout, cp.stderr))
    return cp


def set_scenario_green(root, columns="en", with_evidence=True,
                       evidence_first_line="make run TEST=fixture_test SEED=1"):
    """Flip M1-01 to ✅, optionally creating a well-formed evidence file."""
    L = EN if columns == "en" else ZH
    doc = Path(root) / "doc"
    ev_rel = "doc/evidence/v0.1.0/M1-01.log"
    if with_evidence:
        ev = Path(root) / ev_rel
        ev.parent.mkdir(parents=True, exist_ok=True)
        ev.write_text(evidence_first_line
                      + "\n# Generated by scripts/evidence.py (fixture)\n",
                      encoding="utf-8")
    row = ("| M1-01 | M1 | smoke | baseline | ✅ | %s | "
           "`make run TEST=fixture_test SEED=1` |" % ev_rel)
    (doc / "testplan.md").write_text(
        "# Testplan\n\n" + _table(L["tp_header"], [row]), encoding="utf-8")
