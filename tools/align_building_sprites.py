from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def _solve_linear(matrix: list[list[float]], values: list[float]) -> list[float]:
    size = len(values)
    augmented = [matrix[row][:] + [values[row]] for row in range(size)]
    for column in range(size):
        pivot = max(range(column, size), key=lambda row: abs(augmented[row][column]))
        augmented[column], augmented[pivot] = augmented[pivot], augmented[column]
        divisor = augmented[column][column]
        if abs(divisor) < 1.0e-9:
            raise ValueError("Footprint corners do not define a valid perspective transform")
        augmented[column] = [value / divisor for value in augmented[column]]
        for row in range(size):
            if row == column:
                continue
            factor = augmented[row][column]
            augmented[row] = [
                augmented[row][index] - factor * augmented[column][index]
                for index in range(size + 1)
            ]
    return [augmented[row][-1] for row in range(size)]


def rectify_footprint(
    image: Image.Image,
    source: list[tuple[float, float]],
    destination: list[tuple[float, float]],
) -> Image.Image:
    matrix: list[list[float]] = []
    values: list[float] = []
    for (x, y), (u, v) in zip(destination, source):
        matrix.append([x, y, 1.0, 0.0, 0.0, 0.0, -u * x, -u * y])
        values.append(u)
        matrix.append([0.0, 0.0, 0.0, x, y, 1.0, -v * x, -v * y])
        values.append(v)
    coefficients = _solve_linear(matrix, values)
    return image.transform(
        image.size,
        Image.Transform.PERSPECTIVE,
        coefficients,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )


def align_sprite(
    source: Path,
    output: Path,
    corners: list[tuple[float, float]],
    target_slope: float,
    fit_scale: float,
    rectify: bool,
) -> list[tuple[int, int]]:
    image = Image.open(source).convert("RGBA")
    p0, p1, p2, _p3 = corners
    front_slope = (p2[1] - p1[1]) / (p2[0] - p1[0])
    side_slope = (p0[1] - p1[1]) / (p0[0] - p1[0])
    vertical_scale_ratio = (2.0 * target_slope) / (front_slope - side_slope)
    vertical_shear_ratio = target_slope - vertical_scale_ratio * front_slope

    scale_x = (1.0 / vertical_scale_ratio) * fit_scale
    shear_y = scale_x * vertical_shear_ratio
    scale_y = fit_scale
    center_x = image.width * 0.5
    center_y = image.height * 0.5
    translate_x = center_x - scale_x * center_x
    translate_y = center_y - shear_y * center_x - scale_y * center_y

    determinant = scale_x * scale_y
    inverse = (
        scale_y / determinant,
        0.0,
        -translate_x * scale_y / determinant,
        -shear_y / determinant,
        scale_x / determinant,
        (shear_y * translate_x - scale_x * translate_y) / determinant,
    )
    aligned = image.transform(
        image.size,
        Image.Transform.AFFINE,
        inverse,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    transformed = []
    for x, y in corners:
        new_x = scale_x * x + translate_x
        new_y = shear_y * x + scale_y * y + translate_y
        transformed.append((round(new_x), round(new_y)))
    if rectify:
        left, top, right, _bottom = transformed
        target_bottom = (
            left[0] + right[0] - top[0],
            left[1] + right[1] - top[1],
        )
        destination = [left, top, right, target_bottom]
        aligned = rectify_footprint(aligned, transformed, destination)
        transformed = destination
    output.parent.mkdir(parents=True, exist_ok=True)
    aligned.save(output, optimize=True)
    return transformed


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Align an isometric sprite footprint to the project's +/-26.565 degree road axes."
    )
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument(
        "--corners",
        type=float,
        nargs=8,
        metavar=("LX", "LY", "TX", "TY", "RX", "RY", "BX", "BY"),
        required=True,
        help="Footprint corners in left, top, right, bottom order.",
    )
    parser.add_argument("--target-slope", type=float, default=0.5)
    parser.add_argument("--fit-scale", type=float, default=1.0)
    parser.add_argument(
        "--rectify-footprint",
        action="store_true",
        help="Project the four footprint corners onto an exact parallelogram.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    points = list(zip(args.corners[0::2], args.corners[1::2]))
    aligned_corners = align_sprite(
        args.source,
        args.output,
        points,
        args.target_slope,
        args.fit_scale,
        args.rectify_footprint,
    )
    print("aligned_corners=" + repr(aligned_corners))
