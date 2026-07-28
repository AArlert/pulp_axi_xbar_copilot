#!/usr/bin/env python3
"""lint 基线差分（BUG-0021 转 WONTFIX 后的里程碑守卫，见 doc/lint-baseline.md）。

用法: python3 lintdiff.py <lint.log> <lint-baseline.md>

只做比较、绝不改写基线（守卫约束「不得直接更新基线了事」）。
执行证明不在这里——本脚本由 `make lint-diff` 经 `lint-run` 调用，那一步已
逐文件核对过本次确实分析了 ../tb/ 全部源文件（BUG-0022）。
站点 = 类别 × 文件 × 行；新类别或新站点即退出 1。
"""
import re
import sys

SITE_ROW = re.compile(r"^\|\s*`(Lint-\[[^\]]+\])`\s*\|\s*`([^`]+\.sv)`\s*\|\s*(\d+)\s*\|")
LINT_HEAD = re.compile(r"^(Lint-\[[^\]]+\])")
LINT_SITE = re.compile(r"^(\.\./tb/\S+), (\d+)")


def norm(path):
    """两侧路径归一到相对 tb/ 根：日志给 '../tb/sva/x.sv'，基线给 'tb/tb/sva/x.sv'。"""
    path = path.lstrip("./")
    while path.startswith("tb/"):
        path = path[3:]
    return path


def from_log(path):
    lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    sites = set()
    for i, line in enumerate(lines[:-1]):
        head = LINT_HEAD.match(line)
        if not head:
            continue
        site = LINT_SITE.match(lines[i + 1])
        if site:  # 非 ../tb/ 的告警不在判定范围内（vendor / UVM 库）
            sites.add((head.group(1), norm(site.group(1)), int(site.group(2))))
    return sites


def from_baseline(path):
    sites = set()
    for line in open(path, encoding="utf-8").read().splitlines():
        row = SITE_ROW.match(line)
        if row:
            sites.add((row.group(1), norm(row.group(2)), int(row.group(3))))
    return sites


def main():
    log, baseline = sys.argv[1], sys.argv[2]
    cur, base = from_log(log), from_baseline(baseline)
    if not base:
        sys.exit("[LINT-DIFF][FAIL] 基线一条站点都没解析出来: %s" % baseline)
    new = sorted(cur - base)
    gone = sorted(base - cur)
    new_cat = sorted({c for c, _, _ in new} - {c for c, _, _ in base})

    print("[LINT-DIFF] 本次 %d 站点 / 基线 %d 站点 (%s)" % (len(cur), len(base), baseline))
    for c, f, ln in gone:
        print("[LINT-DIFF] 已消失（不阻塞，可在分诊后并入基线）: %s tb/%s:%d" % (c, f, ln))
    if new_cat:
        print("[LINT-DIFF] 新类别: %s" % ", ".join(new_cat))
    for c, f, ln in new:
        print("[LINT-DIFF] 新站点: %s tb/%s:%d" % (c, f, ln))
    if new:
        sys.exit("[LINT-DIFF][FAIL] %d 个新站点须分诊；判为风格才可并入基线，"
                 "判为真缺陷另开 bug 行" % len(new))
    print("[LINT-DIFF] PASS：无新类别、无新站点")


if __name__ == "__main__":
    main()
