from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from sprite_gen import export_pngs  # noqa: E402
from sprite_gen.layout import state_frame_total  # noqa: E402


SAMPLE_RUN = ROOT.parent.parent / "assets" / "generated" / "sprites" / "cat_8way"


class SelectedOnlyExportTests(unittest.TestCase):
    def test_default_export_contains_only_curated_sequence(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            out_dir = Path(temp) / "selected"
            result = export_pngs.run(
                run_dir=SAMPLE_RUN,
                state="down_idle",
                out_dir=out_dir,
            )

            self.assertEqual(result, 0)
            self.assertEqual(len(list(out_dir.glob("*.png"))), 4)

    def test_candidates_require_explicit_opt_in(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            out_dir = Path(temp) / "candidates"
            result = export_pngs.run(
                run_dir=SAMPLE_RUN,
                state="down_idle",
                out_dir=out_dir,
                include_candidates=True,
            )

            self.assertEqual(result, 0)
            request = json.loads(
                (SAMPLE_RUN / "sprite-request.json").read_text(encoding="utf-8"))
            self.assertEqual(
                len(list(out_dir.glob("*.png"))),
                state_frame_total(request, "down_idle"),
            )


if __name__ == "__main__":
    unittest.main()
