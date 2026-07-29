#!/usr/bin/env python3
# Version management: 0.M.P (M = milestone; P = iteration within it).
# Usage: bump.py            -> patch +1 (polish within the milestone)
#        bump.py minor      -> next milestone (0.M+1.0)
#        bump.py 0.3.2      -> explicit
# After bumping, TODO skeletons are inserted at the top of status.jsonl and
# log.md (date/version written by the script, semantics left to the author;
# docs-check blocks unfilled TODOs) — mechanics to scripts, semantics to
# humans/agents.
import json
import re
import sys
from datetime import date

from iverif_config import load_config

SEMVER_RE = re.compile(r"^0\.(\d+)\.(\d+)$")

LOG_SKELETON = """## [{ver}] {today} TODO (one-line title)

**Done**
- TODO

**Not done**
- TODO

**Next**
- TODO

**How verified**
- TODO

"""


def insert_skeletons(cfg, ver):
    today = date.today().isoformat()
    # status.jsonl: insert a skeleton first line (skip if line 1 already has
    # this version).
    lines = [l for l in cfg.status.read_text(encoding="utf-8").splitlines()
             if l.strip()]
    if not lines or json.loads(lines[0]).get("version") != ver:
        rec = {"date": today, "version": ver, "summary": "TODO"}
        lines.insert(0, json.dumps(rec, ensure_ascii=False))
        cfg.status.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print("status.jsonl: skeleton line inserted (summary to fill)")
    # log.md: insert the skeleton block after the file head, before the first
    # block (block headers are only recognized at line start as '## [').
    text = cfg.log.read_text(encoding="utf-8")
    if not re.search(r"^## \[%s\]" % re.escape(ver), text, flags=re.M):
        block = LOG_SKELETON.format(ver=ver, today=today)
        m = re.search(r"^## \[", text, flags=re.M)
        text = (text[:m.start()] + block + text[m.start():] if m
                else text.rstrip() + "\n\n" + block)
        cfg.log.write_text(text, encoding="utf-8")
        print("log.md: skeleton block inserted (four questions to fill)")


def main():
    cfg = load_config()
    data = json.loads(cfg.version_json.read_text(encoding="utf-8"))
    cur = data["version"]
    m = SEMVER_RE.match(cur)
    if not m:
        sys.exit("current version is invalid: %s" % cur)
    major, patch = int(m.group(1)), int(m.group(2))

    arg = sys.argv[1] if len(sys.argv) > 1 else "patch"
    if arg == "patch":
        new = "0.%d.%d" % (major, patch + 1)
    elif arg == "minor":
        new = "0.%d.0" % (major + 1)
    elif SEMVER_RE.match(arg):
        new = arg
    else:
        sys.exit("invalid argument: %s (use: patch / minor / 0.M.P)" % arg)

    new_m = SEMVER_RE.match(new)
    data["version"] = new
    data["milestone"] = "M%s" % new_m.group(1)
    cfg.version_json.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")
    print("%s -> %s (%s)" % (cur, new, data["milestone"]))
    insert_skeletons(cfg, new)
    print("Reminder: fill the skeletons, then make check; on milestone "
          "completion tag: git tag v" + new)
    print("Reminder: workflow/ files are upstream — if it has been a while, "
          "spot-check known downstream forks for drift (see DESIGN.md).")


if __name__ == "__main__":
    main()
