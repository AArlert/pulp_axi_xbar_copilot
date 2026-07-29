"""Make-fragment fuses (skipped when `make` is unavailable)."""
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

FRAMEWORK = Path(__file__).resolve().parents[2]


class TestVcs2018Fragment(unittest.TestCase):
    @unittest.skipUnless(shutil.which("make"), "make not available")
    def test_ld_library_path_no_trailing_empty_element(self):
        # pulp BUG-0030: a trailing ':' (empty element) from concatenating
        # an unset parent LD_LIBRARY_PATH makes NPI-based tools (xdebug)
        # refuse to initialize — and any project calling them from a make
        # environment inherits it.
        tmp = Path(tempfile.mkdtemp(prefix="iverif_mk_"))
        self.addCleanup(shutil.rmtree, tmp, True)
        mk = tmp / "t.mk"
        mk.write_text(
            "include %s\nprint-ld:\n\t@echo '[$(LD_LIBRARY_PATH)]'\n"
            % (FRAMEWORK / "scripts" / "make" / "vcs-2018.mk"),
            encoding="utf-8")
        env = dict(os.environ)
        env.pop("LD_LIBRARY_PATH", None)
        cp = subprocess.run(["make", "-s", "-f", str(mk), "print-ld"],
                            capture_output=True, text=True, env=env)
        self.assertEqual(cp.returncode, 0, cp.stderr)
        val = cp.stdout.strip().strip("[]")
        self.assertTrue(val)                       # PLI dir still exported
        self.assertFalse(val.endswith(":"), val)   # no trailing empty element
        self.assertNotIn("::", val)


if __name__ == "__main__":
    unittest.main()
