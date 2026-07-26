#!/usr/bin/env python3
"""Convert O1 metro image-generation masters into fixed Godot atlases."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def is_key(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    saturated_key = (
        red >= 80
        and blue >= 80
        and green <= 120
        and min(red, blue) - green >= 45
        and abs(red - blue) <= 110
    )
    dark_key_fringe = (
        red >= 35
        and blue >= 40
        and green < min(red, blue) * 0.72
        and abs(red - blue) <= 100
    )
    return saturated_key or dark_key_fringe


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
    bottom_anchor: bool,
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


def build_tiles(source_path: Path, output_path: Path) -> None:
    source = Image.open(source_path).convert("RGBA")
    atlas = Image.new("RGBA", (256, 256))
    for row in range(8):
        for column in range(8):
            cell = split_cell(source, column, row, 8, 8)
            tile = remove_key(cell.resize((32, 32), Image.Resampling.LANCZOS))
            alpha = tile.getchannel("A").point(lambda value: 0 if value < 48 else value)
            tile.putalpha(alpha)
            atlas.alpha_composite(tile, (column * 32, row * 32))
    save_optimized(atlas, output_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated-dir", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()
    generated = args.generated_dir
    root = args.project_root

    build_tiles(
        generated / "exec-ced03b47-8d9b-422a-902d-960e4b075541.png",
        root / "assets/art/worlds/metro/metro_tileset.png",
    )
    build_atlas(
        generated / "exec-04ebedcd-8fa2-4e04-bee7-d56d10960c92.png",
        root / "assets/art/worlds/metro/metro_props.png",
        (4, 3),
        (128, 128),
        3,
        True,
    )
    build_atlas(
        generated / "exec-98349a6c-18d4-45ad-83d8-76d4529916af.png",
        root / "assets/art/characters/metro/drowned_spritesheet.png",
        (6, 4),
        (48, 64),
        1,
        True,
    )
    build_atlas(
        generated / "exec-83863237-8d3d-4a15-9abd-6c0ea74dfeaa.png",
        root / "assets/art/characters/metro/inspector_spritesheet.png",
        (6, 4),
        (48, 64),
        1,
        True,
    )
    build_atlas(
        generated / "exec-404b2bf3-7568-42e5-95a9-82155f21a306.png",
        root / "assets/art/characters/metro/signal_anchor_spritesheet.png",
        (6, 4),
        (64, 64),
        1,
        True,
    )


if __name__ == "__main__":
    main()
