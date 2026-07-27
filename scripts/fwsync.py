#!/usr/bin/env python3
# Drift control + project scaffolding for iverif-workflow.
#
# From a FRAMEWORK checkout (this file at <fw>/kernel/fwsync.py):
#   python3 kernel/fwsync.py --gen-manifest
#   python3 kernel/fwsync.py --init <dir> --profile learning [--columns en]
#   python3 kernel/fwsync.py --pull --into <project-dir>
#
# From a PROJECT (vendored copy at <proj>/scripts/fwsync.py):
#   python3 scripts/fwsync.py --check
#   python3 scripts/fwsync.py --pull <path-to-framework-clone>
#
# The vendored snapshot = scripts/ (kernel + make fragments) + workflow/
# (reference docs), hash-recorded in scripts/iverif.manifest.json. Hashes are
# computed over CRLF-normalized bytes so Windows working trees and the Linux
# VM agree. Projects never edit the snapshot: improve the framework, bump,
# re-pull. Emergency local fixes are allowed but keep `--check` red until
# they flow back.
import argparse
import hashlib
import json
import shutil
import stat
import sys
from datetime import date
from pathlib import Path

from iverif_config import COLUMN_PRESETS

HERE = Path(__file__).resolve().parent

VENDOR_REF_DIRS = ("schema", "taxonomy", "dispatch", "signoff")
MANIFEST = "iverif.manifest.json"

# Skills vendored into <proj>/.claude/skills/ (hash-pinned like workflow/).
# dispatch is the orch operating manual — copilot only; a learning repo
# carrying it would invite the main session to start dispatching de/dv
# cards, which is exactly what the learning profile forbids.
SKILLS_COMMON = ("handover", "evidence", "closeout")
SKILLS_COPILOT = ("dispatch",)

# Agent templates rendered per profile: (template name, output name).
AGENT_SETS = {
    "learning": (("rev.learning.md", "rev.md"),),
    "copilot": (("arch.copilot.md", "arch.md"),
                ("de.copilot.md", "de.md"),
                ("dv.copilot.md", "dv.md"),
                ("rev.copilot.md", "rev.md")),
}

# Seed-only column names (used in generated tables but not read by the
# kernel, so they live here rather than in COLUMN_PRESETS).
SEED_EXTRA = {
    "en": {"tp_desc": "description", "tp_config": "config",
           "fm_feature": "feature", "bug_root": "root_cause",
           "wv_file": "file", "wv_line": "line", "wv_rule": "rule"},
    "zh": {"tp_desc": "场景描述", "tp_config": "配置",
           "fm_feature": "功能", "bug_root": "根因/裁决",
           "wv_file": "文件", "wv_line": "行", "wv_rule": "规则"},
}


def die(msg):
    sys.exit("fwsync: %s" % msg)


def is_framework(p):
    return (p / "kernel").is_dir() and (p / "VERSION").exists()


def framework_root(arg=None):
    if arg:
        p = Path(arg).resolve()
        if not is_framework(p):
            die("not a framework checkout (kernel/ + VERSION expected): %s"
                % p)
        return p
    if is_framework(HERE.parent):
        return HERE.parent
    die("run from a framework checkout, or pass the framework path")


def project_root(arg=None):
    p = Path(arg).resolve() if arg else HERE.parent
    if HERE.name == "scripts" and not arg:
        return HERE.parent
    if arg:
        return p
    die("this looks like a framework checkout — pass --into <project-dir>")


def norm_sha(path):
    return hashlib.sha256(
        path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def fw_version(fw):
    return (fw / "VERSION").read_text(encoding="utf-8").strip()


def vendor_pairs(fw, profile=None):
    """(source file, dest path relative to project root) for the snapshot.
    profile "all" = framework-side full manifest; "copilot" adds the
    copilot-only skills; "learning"/None (unknown, e.g. a legacy repo's
    first pull before iverif.json exists) get the common set only."""
    pairs = []
    for py in sorted((fw / "kernel").glob("*.py")):
        pairs.append((py, Path("scripts") / py.name))
    for mk in sorted((fw / "make").glob("*.mk")):
        pairs.append((mk, Path("scripts") / "make" / mk.name))
    for d in VENDOR_REF_DIRS:
        for f in sorted((fw / d).rglob("*.md")):
            pairs.append((f, Path("workflow") / f.relative_to(fw)))
    prof = fw / "docs" / "profiles.md"
    if prof.exists():
        pairs.append((prof, Path("workflow") / "profiles.md"))
    skills = SKILLS_COMMON + (SKILLS_COPILOT
                              if profile in ("all", "copilot") else ())
    for name in skills:
        f = fw / "skills" / name / "SKILL.md"
        if f.exists():
            pairs.append((f, Path(".claude") / "skills" / name / "SKILL.md"))
    return pairs


def rel_key(dest):
    return str(dest).replace("\\", "/")


def render(text, ctx):
    for k, v in ctx.items():
        text = text.replace("{{%s}}" % k, v)
    return text


# ---------------------------------------------------------------- commands

def cmd_gen_manifest():
    fw = framework_root()
    files = {rel_key(dest): norm_sha(src)
             for src, dest in vendor_pairs(fw, profile="all")}
    manifest = {"version": fw_version(fw), "files": files}
    out = fw / "kernel" / "kernel.manifest.json"
    out.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n",
                   encoding="utf-8")
    print("manifest written: %s (%d files, version %s)"
          % (out.relative_to(fw), len(files), manifest["version"]))


def cmd_check():
    proj = project_root()
    mpath = proj / "scripts" / MANIFEST
    if not mpath.exists():
        die("no %s — this project has no framework snapshot yet "
            "(run --pull <framework-clone>)" % mpath.relative_to(proj))
    manifest = json.loads(mpath.read_text(encoding="utf-8"))
    missing, modified = [], []
    for rel, sha in sorted(manifest["files"].items()):
        p = proj / rel
        if not p.exists():
            missing.append(rel)
        elif norm_sha(p) != sha:
            modified.append(rel)
    if not missing and not modified:
        print("fw-check passed (framework %s, %d files pinned)"
              % (manifest.get("framework", "?"), len(manifest["files"])))
        return 0
    for f in missing:
        print("[FAIL] vendored file missing: %s" % f)
    for f in modified:
        print("[FAIL] vendored file modified locally: %s" % f)
    print("\nfw-check failed: the framework snapshot must stay pristine.\n"
          "Improve the framework repo instead, then: "
          "python3 scripts/fwsync.py --pull <framework-clone>\n"
          "(emergency local fixes may stay temporarily — flow them back "
          "within a day)")
    return 1


def do_pull(fw, proj):
    ver = fw_version(fw)

    # Profile decides the vendor set and the agent suite, so read the
    # config first (a legacy repo's very first pull may predate it).
    cfg_path = proj / "iverif.json"
    profile = None
    project_name = proj.name
    if cfg_path.exists():
        cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
        cfg["framework"] = ver
        cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2)
                            + "\n", encoding="utf-8")
        profile = cfg.get("profile")
        project_name = cfg.get("project_name", proj.name)

    files = {}
    for src, dest in vendor_pairs(fw, profile=profile):
        target = proj / dest
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(str(src), str(target))
        files[rel_key(dest)] = norm_sha(src)
    (proj / "scripts" / MANIFEST).write_text(
        json.dumps({"framework": ver, "files": files}, indent=2,
                   sort_keys=True) + "\n", encoding="utf-8")

    # Re-render the canonical agent suite from the framework templates.
    # Rendered files are regenerated (and overwritten) on every pull —
    # project-specific rules belong in CLAUDE.md, never in these files.
    for tpl_name, out_name in AGENT_SETS.get(profile, ()):
        tpl = fw / "agents" / tpl_name
        if not tpl.exists():
            continue
        out = proj / ".claude" / "agents" / out_name
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(render(tpl.read_text(encoding="utf-8"),
                              {"PROJECT_NAME": project_name,
                               "FRAMEWORK_VERSION": ver}),
                       encoding="utf-8")
        print("rendered .claude/agents/%s" % out_name)
    if profile is None:
        print("note: no iverif.json yet — pulled the common set only; "
              "create iverif.json (see workflow/profiles.md) and re-pull "
              "to render the agent suite")

    print("pulled framework %s: %d files into scripts/ + workflow/ + "
          ".claude/skills/" % (ver, len(files)))
    print("review the framework CHANGELOG for behavior changes, then run "
          "your project selftest / make docs-check")


def write_doc_seed(proj, columns, project_name, profile):
    C = COLUMN_PRESETS[columns]
    X = SEED_EXTRA[columns]
    today = date.today().isoformat()

    def table(cols):
        return ("| " + " | ".join(cols) + " |\n"
                + "|" + "|".join(" --- " for _ in cols) + "|\n")

    doc = proj / "doc"
    arch = doc / "archive"
    for d in (arch, doc / "bugs", doc / "evidence", doc / "review"):
        d.mkdir(parents=True, exist_ok=True)

    (proj / "version.json").write_text(
        '{\n  "version": "0.0.0",\n  "milestone": "M0"\n}\n',
        encoding="utf-8")
    (doc / "status.jsonl").write_text(
        json.dumps({"date": today, "version": "0.0.0",
                    "summary": "repo scaffolded by fwsync --init"},
                   ensure_ascii=False) + "\n", encoding="utf-8")
    (doc / "log.md").write_text(
        "# Work log\n\nNewest block first; capped by docs-check — overflow "
        "moves to doc/archive/.\n\n"
        "## [0.0.0] %s scaffolded\n\n"
        "**Done**\n- fwsync --init (framework snapshot + doc seeds)\n\n"
        "**Not done**\n- everything else\n\n"
        "**Next**\n- M0 bring-up: vendor/flists/sim Makefile, spec v0\n\n"
        "**How verified**\n- make docs-check\n\n" % today,
        encoding="utf-8")

    tp_cols = [C["tp_id"], C["tp_milestone"], X["tp_desc"], X["tp_config"],
               C["tp_status"], C["tp_evidence"], C["tp_repro"]]
    (doc / "testplan.md").write_text(
        "# Testplan\n\nScenario truth table — contract: "
        "workflow/schema/testplan_entry.md. Register rows BEFORE coding; "
        "✅/evidence/repro are script-owned.\n\n" + table(tp_cols),
        encoding="utf-8")

    fm_cols = [C["fm_id"], C["fm_milestone"], X["fm_feature"],
               C["fm_module"], C["fm_scenes"]]
    (doc / "feature-matrix.md").write_text(
        "# Feature matrix\n\nfeature → deliverable → testplan scenarios. "
        "Delivery/verification are computed live by the scripts, never "
        "stored. Every feature maps to ≥1 existing scenario id "
        "(ghost references fail docs-check).\n\n" + table(fm_cols),
        encoding="utf-8")

    bug_cols = [C["bug_id"], C["bug_status"], C["bug_suspect"],
                C["bug_summary"], C["bug_repro"], X["bug_root"],
                C["bug_fix_commit"], C["bug_verify"]]
    (doc / "bugs.md").write_text(
        "# Bugs\n\nStates: OPEN/FIXING/FIX_READY/VERIFYING/CLOSED/TB_BUG/"
        "SPEC_CHANGED/WONTFIX. Debug stories longer than one line get a "
        "detail page doc/bugs/<ID>.md — contract: "
        "workflow/schema/failure_record.md.\n\n" + table(bug_cols),
        encoding="utf-8")

    wv_cols = [C["wv_id"], X["wv_file"], X["wv_line"], X["wv_rule"],
               C["wv_conclusion_prefix"], C["wv_review_prefix"]]
    (doc / "lint-waivers.md").write_text(
        "# Lint waivers\n\nA waiver counts only after rev review fills the "
        "review column.\n\n" + table(wv_cols), encoding="utf-8")

    spec = ("# %s specification\n\n"
            "Single source of expected behavior. Checkers and assertions "
            "derive from THIS document, never from the RTL under test. "
            "Editing it requires a change-record row, then re-pin: "
            "python3 scripts/docs.py --pin-spec\n\n"
            "SPEC-0.1 TODO — distill from the upstream sources.\n\n"
            "%s\n\n" % (project_name, C["spec_change_heading"])
            + table(["date", "section", "change"])
            + "| %s | all | initial skeleton |\n" % today)
    (doc / "spec.md").write_text(spec, encoding="utf-8")
    (doc / "spec.sha256").write_text(
        hashlib.sha256((doc / "spec.md").read_bytes()).hexdigest() + "\n",
        encoding="utf-8")

    (arch / "status-archive.jsonl").write_text("", encoding="utf-8")
    (arch / "log-archive.md").write_text("# Work log archive\n",
                                         encoding="utf-8")
    (arch / "bugs-archive.md").write_text(
        "# Bugs archive\n\n" + table(bug_cols), encoding="utf-8")
    (arch / "lint-waivers-archive.md").write_text(
        "# Lint waiver archive\n\n" + table(wv_cols), encoding="utf-8")

    if profile == "copilot":
        dp = doc / "design-prompt"
        dp.mkdir(exist_ok=True)
        (dp / "README.md").write_text(
            "# Design prompts\n\nOne file per module; every constraint "
            "cites its spec section. rev-gated before any DE card.\n",
            encoding="utf-8")


def cmd_init(target, profile, columns, project_name):
    fw = framework_root()
    proj = Path(target).resolve()
    if proj.exists() and any(p.name != ".git" for p in proj.iterdir()):
        die("target exists and is not empty: %s" % proj)
    proj.mkdir(parents=True, exist_ok=True)
    name = project_name or proj.name
    ver = fw_version(fw)

    cfg = {"framework": ver, "profile": profile, "project_name": name,
           "columns_preset": columns,
           "delivery": {"glob": "tb/{name}.sv"},
           "sim_log": "sim/out/{test}_{seed}.log",
           "fl_schema_enforce": True,
           "sva_enforce": True}
    (proj / "iverif.json").write_text(
        json.dumps(cfg, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")

    write_doc_seed(proj, columns, name, profile)
    do_pull(fw, proj)

    ctx = {"PROJECT_NAME": name, "FRAMEWORK_VERSION": ver,
           "PROFILE": profile}
    tpl = fw / "templates"
    (proj / "Makefile").write_text(
        render((tpl / "Makefile.project").read_text(encoding="utf-8"), ctx),
        encoding="utf-8")
    (proj / "CLAUDE.md").write_text(
        render((tpl / ("CLAUDE.project.%s.md" % profile))
               .read_text(encoding="utf-8"), ctx),
        encoding="utf-8")
    (proj / ".gitignore").write_text(
        (tpl / "gitignore").read_text(encoding="utf-8"), encoding="utf-8")
    (proj / ".gitattributes").write_text(
        (tpl / "gitattributes").read_text(encoding="utf-8"),
        encoding="utf-8")
    hooks = proj / ".githooks"
    hooks.mkdir(exist_ok=True)
    hook = hooks / "pre-commit"
    hook.write_text((tpl / "pre-commit").read_text(encoding="utf-8"),
                    encoding="utf-8")
    try:
        hook.chmod(hook.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP
                   | stat.S_IXOTH)
    except OSError:
        pass
    wf = proj / ".github" / "workflows"
    wf.mkdir(parents=True, exist_ok=True)
    (wf / "ci.yml").write_text((tpl / "ci.yml").read_text(encoding="utf-8"),
                               encoding="utf-8")

    sim = proj / "sim"
    (sim / "regress").mkdir(parents=True, exist_ok=True)
    (sim / "flist").mkdir(exist_ok=True)
    (sim / "regress" / "regress.list").write_text(
        "# one \"<TEST> <SEED>\" per line; every closed bug's failing seed "
        "joins permanently\n", encoding="utf-8")
    (sim / "Makefile").write_text(
        "# %s sim entry — fill flists/top, then: make smoke\n"
        "include ../scripts/make/vcs-2018.mk\n\n"
        "TEST ?= smoke_test\nSEED ?= 1\n\n"
        "# TODO: FLISTS := -f flist/vendor.f -f flist/dut.f -f flist/tb.f\n"
        "# TODO: TOP := <tb_top>\n"
        "# Rule patterns: see the tail of scripts/make/vcs-2018.mk\n" % name,
        encoding="utf-8")

    print("\nproject scaffolded: %s (profile=%s, columns=%s, framework %s)"
          % (proj, profile, columns, ver))
    print("next steps:")
    print("  cd %s" % proj)
    print("  git init && git config core.hooksPath .githooks")
    print("  make docs-check      # should pass on the seed")
    print("  make handover        # see the starting state")
    print("  fill sim/ flists + top, then in the VM: make smoke")


def main():
    ap = argparse.ArgumentParser(description="iverif drift control + "
                                             "project scaffolding")
    ap.add_argument("--gen-manifest", action="store_true",
                    help="(framework) regenerate kernel.manifest.json")
    ap.add_argument("--check", action="store_true",
                    help="(project) verify the vendored snapshot hashes")
    ap.add_argument("--pull", nargs="?", const="", metavar="FW",
                    help="refresh the snapshot (from a project: pass the "
                         "framework clone path)")
    ap.add_argument("--into", metavar="DIR",
                    help="project dir for --pull when run from the framework")
    ap.add_argument("--init", metavar="DIR",
                    help="(framework) scaffold a new project")
    ap.add_argument("--profile", choices=("learning", "copilot"),
                    default="learning")
    ap.add_argument("--columns", choices=("en", "zh"), default="en")
    ap.add_argument("--project", help="project name (default: dir name)")
    args = ap.parse_args()

    if args.gen_manifest:
        cmd_gen_manifest()
    elif args.check:
        sys.exit(cmd_check())
    elif args.pull is not None:
        fw = framework_root(args.pull or None)
        proj = project_root(args.into)
        if not (proj / "iverif.json").exists() and HERE.name != "scripts":
            die("target has no iverif.json — for a brand-new project use "
                "--init")
        do_pull(fw, proj)
    elif args.init:
        cmd_init(args.init, args.profile, args.columns, args.project)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
