from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image


SOURCE = Path(r"C:\Users\rain2\Downloads\character-9-pngs\curated")
UP_RIGHT_SHEET = Path(
    r"C:\Users\rain2\AppData\Local\Temp\codex-clipboard-c2fe8656-a5a2-4346-93b7-3087d2039b5a.png"
)
OUTPUT = Path("assets/enemies/rocket_boss")
DIRECTIONS = (
    "down",
    "down_left",
    "left",
    "up_left",
    "up",
    "up_right",
    "right",
    "down_right",
)


def find_frame(direction: str, motion: str, frame: int) -> Path:
    direct = SOURCE / f"{direction}_{motion}-frame-{frame}.png"
    if direct.exists():
        return direct
    matches = sorted(SOURCE.glob(f"{direction}_{motion}-studio-*#{frame}.png"))
    if len(matches) != 1:
        raise FileNotFoundError(f"Missing unique frame: {direction} {motion} {frame}")
    return matches[0]


def normalize(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Sprite frame is fully transparent")
    sprite = image.crop(bounds)
    max_width, max_height = 246, 250
    scale = min(max_width / sprite.width, max_height / sprite.height, 1.0)
    if scale < 1.0:
        sprite = sprite.resize(
            (max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
            Image.Resampling.LANCZOS,
        )
    canvas = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    x = (256 - sprite.width) // 2
    y = 252 - sprite.height
    canvas.alpha_composite(sprite, (x, y))
    return canvas


def remove_magenta(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            # The supplied sheet uses a saturated magenta studio backdrop.
            magenta_score = min(red, blue) - green
            if red > 170 and blue > 130 and magenta_score > 70:
                edge_alpha = max(0, min(255, round((magenta_score - 70) * 3.2)))
                pixels[x, y] = (red, green, blue, min(alpha, 255 - edge_alpha))
    return image


def build() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for direction in DIRECTIONS:
        for motion in ("idle", "walk"):
            if direction == "up_right" and motion == "walk":
                continue
            for frame in range(4):
                source = find_frame(direction, motion, frame)
                with Image.open(source) as image:
                    normalize(image).save(OUTPUT / f"{direction}_{motion}_{frame}.png")

    with Image.open(UP_RIGHT_SHEET) as sheet:
        sheet = sheet.convert("RGBA")
        cell_width = sheet.width // 4
        for frame in range(4):
            left = frame * cell_width
            right = sheet.width if frame == 3 else (frame + 1) * cell_width
            cell = sheet.crop((left, 0, right, sheet.height))
            normalize(remove_magenta(cell)).save(OUTPUT / f"up_right_walk_{frame}.png")

    readme = OUTPUT / "README.md"
    readme.write_text(
        "Rocket boss frames normalized from character-9. "
        "up_right_walk is extracted from the user-provided replacement sheet.\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    build()
