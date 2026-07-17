#!/usr/bin/env python3
"""Semantic-ish QA gate for a four-phase side-view walk cycle.

This is intentionally stricter than sprite-gen's generic structural inspect:
contact frames must alternate their leading-foot silhouette, gather frames must
keep both feet near the body center, and the two contact frames must not be
near-duplicates. It is a deterministic gate, not a substitute for a human
motion review.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from PIL import Image


def _alpha_stats(path: Path) -> tuple[float, float, float, int]:
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError(f"empty frame: {path}")
    left, top, right, bottom = bbox
    pixels = alpha.load()
    band_top = top + (bottom - top) * 0.78
    xs: list[int] = []
    ys: list[int] = []
    for y in range(int(band_top), bottom):
        for x in range(left, right):
            if pixels[x, y] >= 32:
                xs.append(x)
                ys.append(y)
    if not xs:
        raise ValueError(f"no foot pixels in lower band: {path}")
    center = (left + right) / 2.0
    # Negative means the lower silhouette reaches left of the body center.
    mean_offset = (sum(xs) / len(xs)) - center
    extent_left = min(xs) - center
    extent_right = max(xs) - center
    return mean_offset, extent_left, extent_right, len(xs)


def _contact_distance(left: Path, right: Path) -> float:
    a = Image.open(left).convert("RGBA").resize((64, 64))
    b = Image.open(right).convert("RGBA").resize((64, 64))
    total = 0
    changed = 0
    for pa, pb in zip(a.getdata(), b.getdata()):
        total += 1
        if abs(pa[3] - pb[3]) > 16:
            changed += 1
    return changed / max(1, total)


def _load_files(run_dir: Path, state: str) -> list[Path]:
    manifest = run_dir / "frames" / "frames-manifest.json"
    data = json.loads(manifest.read_text(encoding="utf-8"))
    row = next((entry for entry in data.get("rows", []) if entry.get("state") == state), None)
    if not row:
        raise ValueError(f"state not found in frames-manifest.json: {state}")
    files = [run_dir / rel for rel in row.get("files", [])]
    if len(files) != 4:
        raise ValueError(f"{state}: expected exactly 4 frames, found {len(files)}")
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate alternating feet in a 4-frame left walk.")
    parser.add_argument("--run-dir", required=True, type=Path)
    parser.add_argument("--state", default="left_walk")
    parser.add_argument("--min-contact-difference", type=float, default=0.035)
    parser.add_argument("--min-leading-shift", type=float, default=5.0)
    parser.add_argument("--max-gather-shift", type=float, default=16.0)
    args = parser.parse_args()

    try:
        frames = _load_files(args.run_dir, args.state)
        stats = [_alpha_stats(frame) for frame in frames]
        # Frame 0 and 2 are contact phases. Their lower silhouette must move in
        # opposite directions, otherwise both frames likely use the same leg.
        if stats[0][0] >= -args.min_leading_shift:
            raise ValueError(f"frame 0 is not left-leading enough: offset={stats[0][0]:.2f}")
        if stats[2][0] <= args.min_leading_shift:
            raise ValueError(f"frame 2 is not right-leading enough: offset={stats[2][0]:.2f}")
        if abs(stats[1][0]) > args.max_gather_shift or abs(stats[3][0]) > args.max_gather_shift:
            raise ValueError(
                "gather frame feet are not centered: "
                f"frame1={stats[1][0]:.2f}, frame3={stats[3][0]:.2f}"
            )
        difference = _contact_distance(frames[0], frames[2])
        if difference < args.min_contact_difference:
            raise ValueError(f"contact frames are near-duplicates: alpha difference={difference:.4f}")
        result = {
            "ok": True,
            "kind": "walk-cycle-qa",
            "state": args.state,
            "phase_contract": ["left_lead", "gather", "right_lead", "gather"],
            "frames": [
                {"index": index, "lower_mean_offset": round(item[0], 3), "lower_left": round(item[1], 3), "lower_right": round(item[2], 3)}
                for index, item in enumerate(stats)
            ],
            "contact_alpha_difference": round(difference, 4),
        }
        report = args.run_dir / "walk-cycle-qa.report.json"
        report.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, indent=2))
        return 0
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        result = {"ok": False, "kind": "walk-cycle-qa", "state": args.state, "error": str(exc)}
        (args.run_dir / "walk-cycle-qa.report.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, indent=2))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
