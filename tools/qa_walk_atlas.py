"""Lightweight walk-atlas QA: frame count, populated alpha, and phase differences."""

import json
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path("assets/generated/sprites/cat_8way")
ATLAS = ROOT / "walk-atlas.png"
OUT = ROOT / "walk-atlas.phase-qa.json"
NAMES = ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
CELL = 256


def main() -> None:
    image = Image.open(ATLAS).convert("RGBA")
    rows = []
    for row, name in enumerate(NAMES):
        frames = [image.crop((i * CELL, row * CELL, (i + 1) * CELL, (row + 1) * CELL)) for i in range(4)]
        lower = [frame.crop((0, CELL // 2, CELL, CELL)) for frame in frames]
        diff_01 = sum(1 for px in ImageChops.difference(lower[0], lower[1]).getdata() if px != (0, 0, 0, 0))
        diff_12 = sum(1 for px in ImageChops.difference(lower[1], lower[2]).getdata() if px != (0, 0, 0, 0))
        diff_23 = sum(1 for px in ImageChops.difference(lower[2], lower[3]).getdata() if px != (0, 0, 0, 0))
        populated = [frame.getchannel("A").getbbox() is not None for frame in frames]
        rows.append({"direction": name, "frames": 4, "populated": populated, "lower_diff": [diff_01, diff_12, diff_23]})
    report = {
        "ok": all(all(row["populated"]) and min(row["lower_diff"]) > 0 for row in rows),
        "rule": "left_forward -> feet_together -> right_forward -> feet_together",
        "rows": rows,
        "note": "This automated check catches missing frames and frozen lower-body phases; visual curation still confirms anatomical left/right identity.",
    }
    OUT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
