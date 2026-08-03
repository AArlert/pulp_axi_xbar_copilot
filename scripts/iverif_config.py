#!/usr/bin/env python3
# Shared configuration for the scripts/ mechanical layer (docs.py, svacheck.py,
# regress.py). Project knobs live in <root>/iverif.json. stdlib-only, py>=3.8.
# Slimmed in the 0.5.4 reset: profile/delivery/feature-matrix/waiver plumbing
# removed with the process layer they served; git history has the old version.
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG_PATH = ROOT / "iverif.json"

# Semantic key -> actual column header in the project's markdown tables.
COLUMN_PRESETS = {
    "en": {
        "tp_id": "id", "tp_milestone": "milestone", "tp_status": "status",
        "tp_evidence": "evidence", "tp_repro": "repro",
        "bug_id": "id", "bug_class": "class", "bug_status": "status",
        "bug_summary": "summary", "bug_evidence": "evidence",
        "bug_link": "link",
    },
}

LIMIT_DEFAULTS = {
    "status_keep": 8,
    "log_keep": 3,
    "bug_done_keep": 2,
}

BUG_STATES = ("OPEN", "FIXING", "CLOSED", "TB_BUG", "SPEC_CHANGED", "WONTFIX")
# Terminal = lifecycle over, archivable; active bugs are never archived.
BUG_DONE_STATES = ("CLOSED", "TB_BUG", "SPEC_CHANGED", "WONTFIX")

FL_CLASSES = ("TOOL_ENV", "TB_BUG", "CONSTRAINT_BUG", "SPEC_ISSUE", "DUT_BUG")

STATUS_EMOJIS = ("✅", "❌", "⚠️", "🔲")

_UVM_CNT_RE = re.compile(r"UVM_(ERROR|FATAL)\s*:?\s+(\d+)")
_PLAIN_MARK = "V C S   S i m u l a t i o n"
_PLAIN_BAD_RE = re.compile(r"\s*(Error|Fatal)\b")


def log_verdict(text):
    """Single source of truth for sim-log pass/fail across scripts/.
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
        if "project_name" not in raw:
            sys.exit("iverif.json is missing required key 'project_name'")
        self.project = raw["project_name"]
        preset = raw.get("columns_preset", "en")
        if preset not in COLUMN_PRESETS:
            sys.exit("iverif.json columns_preset must be one of %s"
                     % "/".join(sorted(COLUMN_PRESETS)))
        self.C = dict(COLUMN_PRESETS[preset])
        self.C.update(raw.get("columns_override", {}))
        # Extra regexes for evidence key-line extraction (project-specific
        # summary tags such as the tb's [FCOV_SUMMARY]); validated at use.
        self.key_line_extra = raw.get("key_line_extra", [])
        self.sim_log = raw.get("sim_log", "sim/out/{test}_{seed}.log")
        # SVA leg (svacheck.py): assertion failures do NOT increment
        # UVM_ERROR, so they are judged independently of log_verdict.
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
        self.spec = doc / "spec.md"
        self.bugs = doc / "bugs.md"
        self.bug_pages = doc / "bugs"
        self.evidence_dir = doc / "evidence"

        arch = ROOT / raw.get("archive_dir", "doc/archive")
        self.archive_dir = arch
        self.status_archive = arch / "status-archive.jsonl"
        self.log_archive = arch / "log-archive.md"
        self.bugs_archive = arch / "bugs-archive.md"

    def sim_log_path(self, test, seed):
        return ROOT / self.sim_log.format(test=test, seed=seed)


def load_config():
    if not CONFIG_PATH.exists():
        sys.exit("iverif.json not found at project root: %s" % CONFIG_PATH)
    try:
        raw = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
    except json.JSONDecodeError as e:
        sys.exit("iverif.json is not valid JSON: %s" % e)
    return Config(raw)
