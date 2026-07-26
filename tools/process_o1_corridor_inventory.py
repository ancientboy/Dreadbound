#!/usr/bin/env python3
"""Convert O1 corridor and inventory image-generation masters into Godot assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def is_key(pixel: tuple[int, int, int, int]) -> bool:
    red, green, blue, _alpha = pixel
    saturated_key = (
        red >= 90
        and blue >= 90
        and green <= 125
        and min(red, blue) - green >= 45
        and abs(red - blue) <= 110
    )
    pale_key_gutter = red >= 220 and blue >= 220 and green <= 240 and min(red, blue) - green >= 10
    return saturated_key or pale_key_gutter


def remove_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            if is_key((red, green, blue, alpha)):
                pixels[x, y] = (0, 0, 0, 0)
            elif red > 190 and green > 190 and blue > 190 and max(red, green, blue) - min(red, green, blue) < 24:
                # Generated atlas gutters are white; no production asset uses white.
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


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
    cell = remove_key(image.crop((left, top, right, bottom)))
    bounds = cell.getchannel("A").getbbox()
    return cell.crop(bounds) if bounds else Image.new("RGBA", (1, 1))


def fit_cell(source: Image.Image, size: tuple[int, int], margin: int) -> Image.Image:
    maximum = (size[0] - margin * 2, size[1] - margin * 2)
    scale = min(maximum[0] / source.width, maximum[1] / source.height)
    target = (
        max(1, round(source.width * scale)),
        max(1, round(source.height * scale)),
    )
    resized = remove_key(source.resize(target, Image.Resampling.LANCZOS))
    alpha = resized.getchannel("A").point(lambda value: 0 if value < 52 else value)
    resized.putalpha(alpha)
    output = Image.new("RGBA", size)
    output.alpha_composite(
        resized,
        ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2),
    )
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
) -> None:
    source = Image.open(source_path).convert("RGBA")
    columns, rows = grid
    atlas = Image.new("RGBA", (columns * cell_size[0], rows * cell_size[1]))
    for row in range(rows):
        for column in range(columns):
            cell = split_cell(source, column, row, columns, rows)
            atlas.alpha_composite(
                fit_cell(cell, cell_size, margin),
                (column * cell_size[0], row * cell_size[1]),
            )
    save_optimized(atlas, output_path)


def build_individual_icons(source_path: Path, project_root: Path) -> None:
    source = Image.open(source_path).convert("RGBA")
    targets = [
        "assets/art/icons/equipment/cyan_mark.png",
        "assets/art/icons/equipment/waterproof_pulse.png",
        "assets/art/icons/equipment/station_whistle.png",
        "assets/art/icons/equipment/insulated_crowbar.png",
        "assets/art/icons/equipment/last_ticket.png",
        "assets/art/icons/equipment/nullpoint_sidearm.png",
        "assets/art/icons/equipment/siege_core.png",
        "assets/art/icons/equipment/volatile_edge.png",
        "assets/art/icons/equipment/archive_lens.png",
        "assets/art/icons/unique/linye_pass.png",
        "assets/art/icons/unique/conductor_railgun.png",
        "assets/art/icons/materials/flooded_circuit.png",
        "assets/art/icons/materials/ticket_stub.png",
        "assets/art/icons/materials/conductor_coil.png",
        "assets/art/icons/ui/unknown_equipment.png",
        "assets/art/icons/ui/unknown_material.png",
    ]
    for index, relative_path in enumerate(targets):
        cell = split_cell(source, index % 4, index // 4, 4, 4)
        save_optimized(fit_cell(cell, (32, 32), 1), project_root / relative_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--corridor-master", type=Path, required=True)
    parser.add_argument("--navigation-master", type=Path, required=True)
    parser.add_argument("--inventory-master", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()

    build_atlas(
        args.corridor_master,
        args.project_root / "assets/art/worlds/corridor/corridor_hub_atlas.png",
        (4, 4),
        (128, 128),
        3,
    )
    build_atlas(
        args.navigation_master,
        args.project_root / "assets/art/ui/hub_section_icons.png",
        (7, 1),
        (32, 32),
        1,
    )
    build_individual_icons(args.inventory_master, args.project_root)


if __name__ == "__main__":
    main()
