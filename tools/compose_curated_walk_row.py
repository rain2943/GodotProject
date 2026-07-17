#!/usr/bin/env python3
"""Bake a reviewed replacement pose back into a four-frame chroma row.

This is deliberately deterministic: existing extracted frames are preserved,
one replacement frame is fitted to the same cell footprint and baseline, and
the row is rebuilt on the request's chroma color before re-running extraction
and semantic QA.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def _bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("replacement frame has no visible pixels")
    return bbox


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--state", default="left_walk")
    parser.add_argument("--replacement-frame", required=True, type=Path)
    parser.add_argument("--replace-index", type=int, default=2)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    request = json.loads((args.run_dir / "sprite-request.json").read_text(encoding="utf-8"))
    cell = request.get("cell", {})
    width = int(cell.get("width", cell.get("size", 256)))
    height = int(cell.get("height", cell.get("size", 256)))
    key = tuple(request.get("chroma_key", {}).get("rgb", [255, 0, 255]))

    manifest = json.loads((args.run_dir / "frames" / "frames-manifest.json").read_text(encoding="utf-8"))
    row = next(item for item in manifest["rows"] if item.get("state") == args.state)
    frame_paths = [args.run_dir / rel for rel in row["files"]]
    if len(frame_paths) != 4:
        raise SystemExit(f"expected 4 frames, found {len(frame_paths)}")

    frames = [Image.open(path).convert("RGBA") for path in frame_paths]
    bboxes = [_bbox(frame) for frame in frames]
    baseline = max(bbox[3] for bbox in bboxes)
    target_height = sorted(bbox[3] - bbox[1] for bbox in bboxes)[2]
    target_center = sum((bbox[0] + bbox[2]) / 2 for bbox in bboxes) / len(bboxes)

    replacement = Image.open(args.replacement_frame).convert("RGBA")
    crop = replacement.crop(_bbox(replacement))
    scale = target_height / max(1, crop.height)
    crop = crop.resize((max(1, round(crop.width * scale)), max(1, round(crop.height * scale))), Image.Resampling.NEAREST)
    replacement_cell = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    x = round(target_center - crop.width / 2)
    y = baseline - crop.height
    replacement_cell.alpha_composite(crop, (x, y))
    frames[args.replace_index] = replacement_cell

    sheet = Image.new("RGBA", (width * 4, height), (*key, 255))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * width, 0))
    args.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.out, format="PNG")
    print(json.dumps({"ok": True, "out": str(args.out), "replace_index": args.replace_index, "cell": [width, height]}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
