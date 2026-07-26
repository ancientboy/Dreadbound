#!/usr/bin/env python3
"""Convert O1 batch 4 image-generation masters into fixed Godot assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def is_key(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    return (
        red >= 80
        and blue >= 80
        and green <= 115
        and min(red, blue) - green >= 45
        and abs(red - blue) <= 105
    )


def remove_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            if is_key(pixels[x, y]):
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def trimmed(image: Image.Image) -> Image.Image:
    rgba = remove_key(image)
    bounds = rgba.getchannel("A").getbbox()
    return rgba.crop(bounds) if bounds else Image.new("RGBA", (1, 1))


def split_cell(
    image: Image.Image,
    column: int,
    row: int,
    columns: int,
    rows: int,
) -> Image.Image:
    left = round(column * image.width / columns)
    right = round((column + 1) * image.width / columns)
    top = round(row * image.height / rows)
    bottom = round((row + 1) * image.height / rows)
    return trimmed(image.crop((left, top, right, bottom)))


def fit_cell(
    source: Image.Image,
    size: tuple[int, int],
    margin: int,
    bottom_anchor: bool,
) -> Image.Image:
    source = trimmed(source)
    maximum = (size[0] - margin * 2, size[1] - margin * 2)
    scale = min(maximum[0] / source.width, maximum[1] / source.height)
    target = (
        max(1, round(source.width * scale)),
        max(1, round(source.height * scale)),
    )
    resized = remove_key(source.resize(target, Image.Resampling.LANCZOS))
    alpha = resized.getchannel("A")
    alpha = alpha.point(lambda value: 0 if value < 48 else value)
    resized.putalpha(alpha)
    output = Image.new("RGBA", size)
    x = (size[0] - resized.width) // 2
    y = size[1] - margin - resized.height if bottom_anchor else (size[1] - resized.height) // 2
    output.alpha_composite(resized, (x, y))
    return output


def save_optimized(image: Image.Image, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    indexed = image.quantize(
        colors=128,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.NONE,
    )
    indexed.save(output_path, optimize=True)


def clear_purple_fringe(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha and red >= 55 and blue >= 60 and green < min(red, blue) * 0.72:
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def build_atlas(
    source_path: Path,
    output_path: Path,
    grid: tuple[int, int],
    cell_size: tuple[int, int],
    margin: int,
    bottom_anchor: bool,
) -> None:
    source = Image.open(source_path).convert("RGBA")
    columns, rows = grid
    atlas = Image.new(
        "RGBA",
        (columns * cell_size[0], rows * cell_size[1]),
    )
    for row in range(rows):
        for column in range(columns):
            cell = split_cell(source, column, row, columns, rows)
            atlas.alpha_composite(
                fit_cell(cell, cell_size, margin, bottom_anchor),
                (column * cell_size[0], row * cell_size[1]),
            )
    save_optimized(atlas, output_path)


def build_icon_set(source_path: Path, root: Path) -> None:
    source = Image.open(source_path).convert("RGBA")
    targets = [
        ("assets/art/icons/equipment/echo_edge.png", 0),
        ("assets/art/icons/equipment/medical_tag.png", 1),
        ("assets/art/icons/equipment/calming_coil.png", 2),
        ("assets/art/icons/equipment/ward_echo.png", 3),
        ("assets/art/icons/unique/director_reaper.png", 4),
        ("assets/art/icons/materials/tissue_sample.png", 5),
        ("assets/art/icons/materials/medical_record.png", 6),
        ("assets/art/icons/materials/stitch_core.png", 7),
    ]
    for relative_path, index in targets:
        cell = split_cell(source, index % 3, index // 3, 3, 3)
        save_optimized(
            fit_cell(cell, (32, 32), 1, False),
            root / relative_path,
        )
    chest = split_cell(source, 2, 2, 3, 3)
    save_optimized(
        fit_cell(chest, (64, 64), 2, True),
        root / "assets/art/worlds/global/reward_chest.png",
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated-dir", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()
    generated = args.generated_dir
    root = args.project_root

    build_atlas(
        generated / "call_PcraFb5g7pDM38JeYdcs4vOW.png",
        root / "assets/art/characters/sanatorium/stitch_director_spritesheet.png",
        (6, 4),
        (96, 96),
        2,
        True,
    )
    build_atlas(
        generated / "call_fo3BbzosE8nZgYZkYL7xndPM.png",
        root / "assets/art/weapons/director_reaper_growth.png",
        (6, 1),
        (64, 64),
        2,
        False,
    )
    build_icon_set(
        generated / "call_cgrroWOgZKltYtkym83oKfIg.png",
        root,
    )
    build_atlas(
        generated / "call_9wUbNURLuvGBAMzrmPZt94gU.png",
        root / "assets/art/vfx/world_feedback.png",
        (4, 2),
        (64, 64),
        3,
        False,
    )
    build_atlas(
        generated / "call_EG9orZmSD2PwyNJc38sOMbvr.png",
        root / "assets/art/vfx/sanatorium_objective_lighting.png",
        (4, 2),
        (128, 128),
        3,
        False,
    )
    lighting_path = root / "assets/art/vfx/sanatorium_objective_lighting.png"
    save_optimized(clear_purple_fringe(Image.open(lighting_path)), lighting_path)


if __name__ == "__main__":
    main()
