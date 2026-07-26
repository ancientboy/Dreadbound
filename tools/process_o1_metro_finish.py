#!/usr/bin/env python3
"""Convert O1 metro-finish image-generation masters into fixed Godot atlases."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def is_key(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    saturated = (
        red >= 80
        and blue >= 80
        and green <= 125
        and min(red, blue) - green >= 42
        and abs(red - blue) <= 115
    )
    fringe = (
        red >= 38
        and blue >= 42
        and green < min(red, blue) * 0.7
        and abs(red - blue) <= 105
    )
    return saturated or fringe


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
    alpha = resized.getchannel("A").point(lambda value: 0 if value < 48 else value)
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


def build_atlas(
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
                fit_cell(cell, cell_size, margin, bottom_anchor),
                (column * cell_size[0], row * cell_size[1]),
            )
    save_optimized(atlas, output_path)


def build_logo(source_path: Path, output_path: Path) -> None:
    logo = fit_cell(Image.open(source_path), (512, 128), 8, False)
    save_optimized(logo, output_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated-dir", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()
    generated = args.generated_dir
    root = args.project_root

    build_atlas(
        generated / "call_mwCyNyMjvrw9BIjS4Lhkjtld.png",
        root / "assets/art/characters/metro/last_train_conductor_spritesheet.png",
        (6, 4),
        (96, 96),
        2,
        True,
    )
    build_atlas(
        generated / "call_nf7ozctJ4JHeZ5e7ulP9CxLl.png",
        root / "assets/art/weapons/conductor_railgun_growth.png",
        (6, 1),
        (64, 64),
        2,
    )
    build_atlas(
        generated / "call_ualfO3xNym9rjA1gnKzumT5s.png",
        root / "assets/art/vfx/metro_enemy_skills.png",
        (4, 2),
        (128, 128),
        3,
    )
    build_atlas(
        generated / "call_mM6VBIIstcaTD2UV0TVD9YKv.png",
        root / "assets/art/vfx/metro_flood_layers.png",
        (4, 2),
        (128, 128),
        1,
    )
    build_atlas(
        generated / "call_Wj8XddSs36rvK5xBUcxHWKU2.png",
        root / "assets/art/vfx/player_states_lighting.png",
        (4, 2),
        (128, 128),
        3,
    )
    build_logo(
        generated / "call_IX14HT99lA9Sj59NooAsVmIS.png",
        root / "assets/art/brand/dreadbound_logo.png",
    )
    build_atlas(
        generated / "call_KGgoufRDWUhoUC3PGr1DRr1q.png",
        root / "assets/art/ui/mobile_controls.png",
        (4, 2),
        (64, 64),
        2,
    )


if __name__ == "__main__":
    main()
