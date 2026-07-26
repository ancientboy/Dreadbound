#!/usr/bin/env python3
"""Convert O1 batch 3 image-generation masters into fixed Godot atlases."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def save_optimized(image: Image.Image, output_path: Path) -> None:
    # Indexed PNG keeps per-palette transparency while sharply reducing Web
    # transfer size and reinforces the locked low-resolution color language.
    indexed = image.quantize(colors=128, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
    indexed.save(output_path, optimize=True)


def is_key(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    # Generated pixel masters antialias the flat magenta into a darker purple
    # fringe. Dreadbound's production palette contains no purple, so remove the
    # whole key family instead of leaving a neon outline after downscaling.
    return (
        red >= 80
        and blue >= 80
        and green <= 110
        and min(red, blue) - green >= 50
        and abs(red - blue) <= 100
    )


def remove_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            if is_key(pixels[x, y]):
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def clear_translucent_key_fringe(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha < 48:
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def split_cell(image: Image.Image, column: int, row: int, columns: int, rows: int) -> Image.Image:
    left = round(column * image.width / columns)
    right = round((column + 1) * image.width / columns)
    top = round(row * image.height / rows)
    bottom = round((row + 1) * image.height / rows)
    return remove_key(image.crop((left, top, right, bottom)))


def trimmed(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    return image.crop(bounds) if bounds else Image.new("RGBA", (1, 1))


def fit_cell(source: Image.Image, size: tuple[int, int], margin: int, bottom_anchor: bool = True) -> Image.Image:
    source = trimmed(source)
    maximum = (size[0] - margin * 2, size[1] - margin * 2)
    scale = min(maximum[0] / source.width, maximum[1] / source.height)
    target_size = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
    resized = clear_translucent_key_fringe(remove_key(source.resize(target_size, Image.Resampling.LANCZOS)))
    output = Image.new("RGBA", size)
    x = (size[0] - resized.width) // 2
    y = size[1] - margin - resized.height if bottom_anchor else (size[1] - resized.height) // 2
    output.alpha_composite(resized, (x, y))
    return output


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
            fitted = fit_cell(cell, cell_size, margin, bottom_anchor)
            atlas.alpha_composite(fitted, (column * cell_size[0], row * cell_size[1]))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    save_optimized(atlas, output_path)


def build_tiles(source_path: Path, output_path: Path) -> None:
    source = Image.open(source_path).convert("RGBA")
    atlas = Image.new("RGBA", (256, 256))
    for row in range(8):
        for column in range(8):
            cell = trimmed(split_cell(source, column, row, 8, 8))
            tile = clear_translucent_key_fringe(remove_key(cell.resize((32, 32), Image.Resampling.LANCZOS)))
            pixels = tile.load()
            for y in range(tile.height):
                for x in range(tile.width):
                    red, green, blue, alpha = pixels[x, y]
                    if alpha and green >= 105 and green > red * 1.55 and green > blue * 1.45:
                        pixels[x, y] = (0, 0, 0, 0)
            atlas.alpha_composite(tile, (column * 32, row * 32))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    save_optimized(atlas, output_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated-dir", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()
    generated = args.generated_dir
    root = args.project_root

    build_atlas(
        generated / "call_z2D181vZjGO9ChB3UZpS6brR.png",
        root / "assets/art/characters/sanatorium/crawler_spritesheet.png",
        (6, 4),
        (64, 48),
        1,
        True,
    )
    build_atlas(
        generated / "call_sa62GhFMwaK5pZrkhZhFtxCb.png",
        root / "assets/art/characters/sanatorium/orderly_spritesheet.png",
        (6, 4),
        (48, 64),
        1,
        True,
    )
    build_atlas(
        generated / "call_U9XVzIkqK9If0XGdlYnBJpdx.png",
        root / "assets/art/characters/corridor/threshold_curator_spritesheet.png",
        (6, 4),
        (96, 96),
        2,
        True,
    )
    build_atlas(
        generated / "call_DfZz6smsP7yw5YTXLJJeCA1d.png",
        root / "assets/art/worlds/sanatorium/sanatorium_props.png",
        (4, 3),
        (128, 128),
        3,
        True,
    )
    build_tiles(
        generated / "call_2iDXhMF78B1dkp3eFiRabPKG.png",
        root / "assets/art/worlds/sanatorium/sanatorium_tileset.png",
    )


if __name__ == "__main__":
    main()
