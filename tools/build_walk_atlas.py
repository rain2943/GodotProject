"""Build the game-facing 8-direction walk-only atlas from a sprite-gen run."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path("assets/generated/sprites/cat_8way")
OUT = ROOT / "walk-atlas.png"
REPORT = ROOT / "walk-atlas.qa.json"
MANIFEST = ROOT / "walk-manifest.json"
ORDER = ["down", "down_right", "right", "up_right", "up", "up_left", "left", "down_left"]
CELL = 256


def main() -> None:
    source = Image.open(ROOT / "sprite-sheet-alpha.png").convert("RGBA")
    # sprite-gen places the eight walk rows after the eight idle rows.
    atlas = Image.new("RGBA", (CELL * 4, CELL * len(ORDER)), (0, 0, 0, 0))
    records = []
    for row, direction in enumerate(ORDER):
        nonempty = []
        for index in range(4):
            image = source.crop((index * CELL, (8 + row) * CELL, (index + 1) * CELL, (9 + row) * CELL))
            alpha = image.getchannel("A")
            nonempty.append(alpha.getbbox() is not None)
            atlas.alpha_composite(image, (index * CELL, row * CELL))
        records.append(
            {
                "direction": direction,
                "row": row,
                "frames": 4,
                "fps": 8,
                "phase_order": ["left_forward", "feet_together", "right_forward", "feet_together"],
                "nonempty_frames": nonempty,
            }
        )
    # Front/back views are symmetric enough that the generator can collapse
    # frames 1 and 3. Swap only the lower-body region from a mirrored stance
    # so the required left/right phase is visually unambiguous while the head,
    # torso, backpack, and tail remain untouched.
    for row in (0, 4):
        first = atlas.crop((0, row * CELL, CELL, (row + 1) * CELL))
        third_box = (2 * CELL, row * CELL, 3 * CELL, (row + 1) * CELL)
        third = atlas.crop(third_box)
        region = (35, 150, 220, 242)
        mirrored = first.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        third.paste((0, 0, 0, 0), region)
        third.alpha_composite(mirrored.crop(region), (region[0], region[1]))
        atlas.paste(third, (2 * CELL, row * CELL))
    atlas.save(OUT)
    report = {
        "ok": all(all(item["nonempty_frames"]) for item in records),
        "asset": str(OUT),
        "cell": {"width": CELL, "height": CELL},
        "columns": 4,
        "rows": len(ORDER),
        "directions": ORDER,
        "phase_rule": "left_forward -> feet_together -> right_forward -> feet_together",
        "rows_report": records,
        "note": "Structural QA verifies 32 populated frames; left/right anatomical identity remains an intentional curation rule.",
    }
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    manifest_rows = {}
    animation_rows = {}
    for row, direction in enumerate(ORDER):
        manifest_rows[f"{direction}_walk"] = [
            {"x": index * CELL, "y": row * CELL, "w": CELL, "h": CELL}
            for index in range(4)
        ]
        animation_rows[f"{direction}_walk"] = {"row": row, "frames": 4, "fps": 8, "loop": True, "frame_variant": "pixel"}
    manifest = {
        "characterId": "cat_8way",
        "engine": "component-row",
        "game_input": "walk-atlas.png",
        "degraded_static_fallback": False,
        "cell": {"shape": "square", "width": CELL, "height": CELL, "size": CELL},
        "animation": {"cellWidth": CELL, "cellHeight": CELL, "columns": 4, "rows": animation_rows},
        "frame_layout": {"sheetWidth": CELL * 4, "sheetHeight": CELL * len(ORDER), "cellWidth": CELL, "cellHeight": CELL, "rows": manifest_rows},
        "phase_order": ["left_forward", "feet_together", "right_forward", "feet_together"],
    }
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
