"""Token-budget gate: the whole must-read surface (CLAUDE.md + workflow/'s
4 contracts) stays under one aggregate cap. This replaces 0.7.x's per-file
budget table (one row per pinned doc, cross-checked against fwsync's
pinning list) — that whole mechanism (fwsync, the pinning concept, the
per-file rows) is retired in 0.8.0. What survives is the point of the test:
"CLAUDE.md + 4 contracts, small enough to read in one sitting" is this
repo's central claim, and a claim worth making is worth a test that can
fail. Over budget? Trim, or move the story to CHANGELOG.md / DESIGN.md —
raising the cap is a reviewed decision, not a fix."""
import unittest
from pathlib import Path

FRAMEWORK = Path(__file__).resolve().parents[2]

# ~12% headroom over the size at 0.8.0's cut (35249 bytes), same margin
# convention as the retired per-file table used.
TOTAL_BUDGET = 39500


class TestSnapshotBudgets(unittest.TestCase):
    def test_must_read_surface_within_budget(self):
        paths = [FRAMEWORK / "CLAUDE.md"] + sorted(
            (FRAMEWORK / "workflow").glob("*.md"))
        self.assertTrue(paths, "workflow/*.md not found")
        total = sum(p.stat().st_size for p in paths)
        detail = "\n".join("  %s: %d" % (p.relative_to(FRAMEWORK), p.stat().st_size)
                           for p in paths)
        self.assertLessEqual(
            total, TOTAL_BUDGET,
            "must-read surface over budget (%d > %d) — trim, or move prose "
            "to CHANGELOG.md/DESIGN.md; raising the cap is a reviewed "
            "decision:\n%s" % (total, TOTAL_BUDGET, detail))


if __name__ == "__main__":
    unittest.main()
