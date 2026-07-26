#!/usr/bin/env python3
"""Build fixed Godot atlases for professions, combat styles, skills and story NPCs."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


PROFESSION_SOURCES = {
    "steadfast": "exec-2ea25469-e1bd-4965-ada7-85e1e23f3df1.png",
    "armorer": "exec-4deb8d82-3cd0-4efa-b3ca-f646b53de4d3.png",
    "resonant": "exec-2e52ff2b-871b-432c-86a7-1a31cd65c3e7.png",
}
NPC_SOURCE = "exec-ad8321f2-fbbb-49fd-a31a-0424d0dacda8.png"
FORM_SOURCE = "exec-11757dc7-b33c-4a6d-869b-c92e43f28957.png"
SKILL_SOURCE = "exec-50a5040b-e49a-4046-b564-3f413cfd5cc1.png"


def remove_magenta(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, _alpha = pixels[x, y]
            # Generated masters use a very bright magenta field. Restrict the
            # key to bright pixels so authored violet character/VFX pixels stay.
            key_distance = ((255 - red) ** 2 + green**2 + (255 - blue) ** 2) ** 0.5
            if (key_distance <= 92 and green <= 105) or (
                red > 183 and blue > 183 and green < 77
            ):
                pixels[x, y] = (0, 0, 0, 0)
            elif key_distance <= 145 and green <= 125:
                alpha = round(255 * (key_distance - 92) / 53)
                pixels[x, y] = (red, min(green, blue), blue, alpha)
    return rgba


def trim(image: Image.Image) -> Image.Image:
    rgba = remove_magenta(image)
    bounds = rgba.getchannel("A").getbbox()
    return rgba.crop(bounds) if bounds else Image.new("RGBA", (1, 1))


def split_cell(
    source: Image.Image, column: int, row: int, columns: int, rows: int
) -> Image.Image:
    left = round(column * source.width / columns)
    right = round((column + 1) * source.width / columns)
    top = round(row * source.height / rows)
    bottom = round((row + 1) * source.height / rows)
    return trim(source.crop((left, top, right, bottom)))


def fit(
    source: Image.Image,
    size: tuple[int, int],
    margin: int,
    bottom_anchor: bool = False,
) -> Image.Image:
    source = trim(source)
    available = (size[0] - margin * 2, size[1] - margin * 2)
    scale = min(available[0] / source.width, available[1] / source.height)
    target = (
        max(1, round(source.width * scale)),
        max(1, round(source.height * scale)),
    )
    resized = source.resize(target, Image.Resampling.LANCZOS)
    alpha = resized.getchannel("A").point(lambda value: 0 if value < 85 else value)
    resized.putalpha(alpha)
    output = Image.new("RGBA", size)
    x = (size[0] - resized.width) // 2
    y = size[1] - margin - resized.height if bottom_anchor else (size[1] - resized.height) // 2
    output.alpha_composite(resized, (x, y))
    return output


def save_optimized(image: Image.Image, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.quantize(
        colors=128,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.NONE,
    ).save(output_path, optimize=True)


def build_grid(
    source_path: Path,
    output_path: Path,
    grid: tuple[int, int],
    cell_size: tuple[int, int],
    margin: int,
    bottom_anchor: bool = False,
) -> None:
    source = Image.open(source_path).convert("RGBA")
    columns, rows = grid
    atlas = Image.new("RGBA", (columns * cell_size[0], rows * cell_size[1]))
    for row in range(rows):
        for column in range(columns):
            cell = split_cell(source, column, row, columns, rows)
            atlas.alpha_composite(
                fit(cell, cell_size, margin, bottom_anchor),
                (column * cell_size[0], row * cell_size[1]),
            )
    save_optimized(atlas, output_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated-dir", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()

    for profession, source_name in PROFESSION_SOURCES.items():
        build_grid(
            args.generated_dir / source_name,
            args.project_root
            / f"assets/art/characters/professions/{profession}_spritesheet.png",
            (6, 4),
            (48, 64),
            1,
            True,
        )
    build_grid(
        args.generated_dir / NPC_SOURCE,
        args.project_root / "assets/art/characters/npcs/story_npcs_idle.png",
        (6, 5),
        (64, 96),
        2,
        True,
    )
    build_grid(
        args.generated_dir / FORM_SOURCE,
        args.project_root / "assets/art/characters/professions/combat_style_forms.png",
        (4, 3),
        (128, 128),
        2,
    )
    build_grid(
        args.generated_dir / SKILL_SOURCE,
        args.project_root / "assets/art/vfx/profession_skills.png",
        (4, 3),
        (128, 128),
        2,
    )


if __name__ == "__main__":
    main()
