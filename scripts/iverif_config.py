#!/usr/bin/env python3
# Shared configuration + helpers for the iverif kernel scripts.
# Canonical home: iverif-workflow/kernel/. Project repos carry a hash-pinned
# copy under scripts/ — do not edit the copy; improve the framework and pull.
#
# Every project-specific knob lives in <project-root>/iverif.json. The kernel
# scripts stay byte-identical across projects; only this file's *inputs* vary.
# stdlib-only, Python >= 3.8.
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "iverif.json"

PROFILES = ("learning", "copilot")

# Semantic key -> actual column header in the project's markdown tables.
# "_prefix" keys are matched with startswith() (waiver tables historically use
# suffixed headers like "结论(豁免/修复)").
COLUMN_PRESETS = {
    "en": {
        "tp_id": "id", "tp_milestone": "milestone", "tp_status": "status",
        "tp_evidence": "evidence", "tp_repro": "repro",
        "fm_id": "id", "fm_milestone": "milestone", "fm_module": "module",
        "fm_scenes": "scenes",
        "bug_id": "id", "bug_status": "status", "bug_suspect": "suspect",
        "bug_summary": "summary", "bug_repro": "min_repro",
        "bug_fix_commit": "fix_commit", "bug_verify": "verify_evidence",
        "wv_id": "#", "wv_conclusion_prefix": "conclusion",
        "wv_review_prefix": "review",
        "spec_change_heading": "## Change record",
    },
    "zh": {
        "tp_id": "ID", "tp_milestone": "里程碑", "tp_status": "状态",
        "tp_evidence": "证据", "tp_repro": "复现",
        "fm_id": "编号", "fm_milestone": "里程碑", "fm_module": "模块",
        "fm_scenes": "关联场景",
        "bug_id": "ID", "bug_status": "状态", "bug_suspect": "疑似归属",
        "bug_summary": "现象摘要", "bug_repro": "最小复现",
        "bug_fix_commit": "修复 commit", "bug_verify": "复验证据",
        "wv_id": "#", "wv_conclusion_prefix": "结论",
        "wv_review_prefix": "复核",
        "spec_change_heading": "## 修改记录",
    },
}

LIMIT_DEFAULTS = {
    "status_max_lines": 12, "status_keep": 8, "summary_max_chars": 200,
    "log_max_blocks": 4, "log_keep": 3,
    "bug_done_max": 4, "bug_done_keep": 2,
    "waiver_done_max": 6, "waiver_done_keep": 2,
}

BUG_STATES = ("OPEN", "FIXING", "FIX_READY", "VERIFYING", "CLOSED",
              "TB_BUG", "SPEC_CHANGED", "WONTFIX")
# Terminal = lifecycle over, archivable; active bugs are never archived.
BUG_DONE_STATES = ("CLOSED", "TB_BUG", "SPEC_CHANGED", "WONTFIX")
# Once a bug reaches these states, the fix-commit column must be filled.
BUG_STATES_NEED_COMMIT = ("FIX_READY", "VERIFYING", "CLOSED")

FL_CLASSES = ("TOOL_ENV", "TB_BUG", "CONSTRAINT_BUG", "SPEC_ISSUE", "DUT_BUG")
FL_SECTIONS = ("symptom", "first_anomaly", "taxonomy", "rca", "fix",
               "rerun", "regression_guard", "similar")

STATUS_EMOJIS = ("✅", "❌", "⚠️", "🔲")

_UVM_CNT_RE = re.compile(r"UVM_(ERROR|FATAL)\s*:?\s+(\d+)")
_PLAIN_MARK = "V C S   S i m u l a t i o n"
_PLAIN_BAD_RE = re.compile(r"\s*(Error|Fatal)\b")


def log_verdict(text):
    """Single source of truth for sim-log pass/fail across the kernel.
    UVM logs: report-summary ERROR/FATAL counts must be zero.
    Plain VCS logs (non-UVM TBs): completion banner present, no Error/Fatal
    lines. Returns "PASS" / "FAIL" / "NOSUMMARY"."""
    counts = {k: int(v) for k, v in _UVM_CNT_RE.findall(text)}
    if counts:
        bad = counts.get("ERROR", 0) or counts.get("FATAL", 0)
        return "FAIL" if bad else "PASS"
    lines = text.splitlines()
    if any(_PLAIN_MARK in l for l in lines):
        return "FAIL" if any(_PLAIN_BAD_RE.match(l) for l in lines) else "PASS"
    return "NOSUMMARY"


class Config:
    def __init__(self, raw):
        for key in ("profile", "project_name"):
            if key not in raw:
                sys.exit("iverif.json is missing required key '%s'" % key)
        if raw["profile"] not in PROFILES:
            sys.exit("iverif.json profile must be one of %s, got %r"
                     % ("/".join(PROFILES), raw["profile"]))
        self.profile = raw["profile"]
        self.project = raw["project_name"]
        preset = raw.get("columns_preset", "en")
        if preset not in COLUMN_PRESETS:
            sys.exit("iverif.json columns_preset must be one of %s"
                     % "/".join(sorted(COLUMN_PRESETS)))
        self.C = dict(COLUMN_PRESETS[preset])
        self.C.update(raw.get("columns_override", {}))
        # Advisory-surface hooks, same spirit as columns_override: a project
        # tunes snapshot-script wording/extraction via config, never by
        # editing scripts/. next_phrases_override remaps `--next` phrases
        # whose role assumptions don't fit (e.g. a vendored-DUT project whose
        # feature-matrix deliverables are DV-owned tb code, not DE RTL —
        # pulp_axi_xbar FB-8); key_line_extra is a list of extra regexes for
        # evidence key-line extraction (project-specific summary tags such as
        # a tb's own [FCOV_SUMMARY] — FB-9). Both are validated at use time.
        self.next_phrases_override = raw.get("next_phrases_override", {})
        self.key_line_extra = raw.get("key_line_extra", [])
        self.delivery_glob = raw.get("delivery", {}).get("glob", "rtl/{name}.sv")
        # Who owns feature-matrix deliverables — drives `--next` card wording
        # in the copilot profile. Explicit `delivery.owner` ("de"|"dv") wins;
        # the default derives from the glob the project already declares:
        # tb/-rooted deliverables are DV-owned tb code (vendored-DUT repos),
        # anything else is DE-owned RTL. Zero-config correctness for both
        # ecosystem shapes (pulp_axi_xbar FB-8; user ruling 2026-07-28:
        # turnkey beats per-project wording patches).
        owner = raw.get("delivery", {}).get("owner")
        if owner is None:
            owner = "dv" if self.delivery_glob.startswith("tb/") else "de"
        if owner not in ("de", "dv"):
            sys.exit("iverif.json delivery.owner must be 'de' or 'dv', "
                     "got %r" % owner)
        self.delivery_owner = owner
        self.sim_log = raw.get("sim_log", "sim/out/{test}_{seed}.log")
        self.signoff_glob = raw.get("signoff_glob", "signoff-M{m}*.md")
        self.fl_enforce = raw.get("fl_schema_enforce", True)
        # SVA leg (svacheck.py): assertion failures do NOT increment
        # UVM_ERROR, so they are judged independently of log_verdict.
        # sva_enforce: a log without the native '-assert verbose' Summary
        # line is FAIL (fail-closed); legacy flows set false until they
        # adopt the pinned run pattern. sva_baseline: optional path to a
        # registered total_min/attempted_min floor file (layer 3).
        self.sva_enforce = raw.get("sva_enforce", True)
        self.sva_baseline = raw.get("sva_baseline")
        self.limits = dict(LIMIT_DEFAULTS)
        self.limits.update(raw.get("limits", {}))

        self.root = ROOT
        doc = ROOT / "doc"
        self.doc = doc
        self.version_json = ROOT / "version.json"
        self.status = doc / "status.jsonl"
        self.log = doc / "log.md"
        self.testplan = doc / "testplan.md"
        self.feature_matrix = doc / "feature-matrix.md"
        self.spec = doc / "spec.md"
        self.spec_sha = doc / "spec.sha256"
        self.bugs = doc / "bugs.md"
        self.waivers = doc / "lint-waivers.md"
        self.bug_pages = doc / "bugs"
        self.evidence_dir = doc / "evidence"
        self.review_dir = doc / "review"

        arch = ROOT / raw.get("archive_dir", "doc/archive")
        self.archive_dir = arch
        self.status_archive = arch / "status-archive.jsonl"
        self.log_archive = arch / "log-archive.md"
        self.bugs_archive = arch / "bugs-archive.md"
        self.waivers_archive = arch / "lint-waivers-archive.md"

        self.required_files = [
            self.version_json, self.status, self.status_archive,
            self.log, self.log_archive, self.testplan, self.feature_matrix,
            self.spec, self.spec_sha, self.bugs, self.bugs_archive,
            self.waivers, self.waivers_archive,
            ROOT / "CLAUDE.md", ROOT / "Makefile",
        ]
        if self.profile == "copilot":
            self.required_files.append(doc / "design-prompt" / "README.md")

    def delivered(self, name):
        """Mechanical delivery check: does the file named by delivery.glob
        exist? Non-single-module entries (e.g. "(all)") return None."""
        if not re.fullmatch(r"\w+", name):
            return None
        return (ROOT / self.delivery_glob.format(name=name)).exists()

    def sim_log_path(self, test, seed):
        return ROOT / self.sim_log.format(test=test, seed=seed)


def load_config():
    if not CONFIG_PATH.exists():
        sys.exit("iverif.json not found at project root: %s\n"
                 "New project? Scaffold one with:\n"
                 "  python3 <framework>/kernel/fwsync.py --init <dir> "
                 "--profile learning --columns en" % CONFIG_PATH)
    try:
        raw = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit("iverif.json is not valid JSON: %s" % e)
    return Config(raw)
