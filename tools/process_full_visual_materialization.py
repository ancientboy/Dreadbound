#!/usr/bin/env python3
"""Build the fixed atlases used by the full O1 visual-materialization pass.

Image-generation masters intentionally live outside the repository.  This tool
splits those masters into deterministic cells, removes the dominant chroma key
per cell, anchors the artwork, limits the palette, and writes only runtime PNGs.
"""

from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


@dataclass(frozen=True)
class AtlasSpec:
    source: str
    target: str
    grid: tuple[int, int]
    cell: tuple[int, int]
    margin: int = 2
    bottom_anchor: bool = False
    cover: bool = False
    remove_dividers: bool = False


SPECS = (
    # P0
    AtlasSpec("exec-f54b94b2-ec5f-45e1-9b61-c1354f06111d.png", "assets/art/vfx/sanatorium_enemy_skills.png", (4, 2), (128, 128), 3),
    AtlasSpec("exec-e0789a75-63a5-483c-9b5a-44c8e168c896.png", "assets/art/weapons/advanced_weapons.png", (5, 1), (64, 64), 2, False, False, True),
    AtlasSpec("exec-76575623-1354-42fb-bfaf-d25ffd083597.png", "assets/art/weapons/boss_evolution_weapons.png", (3, 2), (128, 64), 2),
    AtlasSpec("call_GnvzHxIJOGFbPXriS5gi9xzX.png", "assets/art/vfx/materials_enemy_affixes.png", (5, 2), (64, 64), 1),
    # P1
    AtlasSpec("exec-fcb74375-7798-4325-80c1-9603bc83ec65.png", "assets/art/characters/professions/combat_style_forms_steadfast.png", (4, 4), (128, 128), 2, False, False, True),
    AtlasSpec("exec-b8c16a4e-e416-4ce9-b23f-83711bb5d4fa.png", "assets/art/characters/professions/combat_style_forms_armorer.png", (4, 4), (128, 128), 2, False, False, True),
    AtlasSpec("exec-b8d78bfc-f26f-4d06-885d-c733e55e21c4.png", "assets/art/characters/professions/combat_style_forms_resonant.png", (4, 4), (128, 128), 2, False, False, True),
    AtlasSpec("exec-f5903b01-4202-484e-a7f3-7a6a9fd5ed5d.png", "assets/art/vfx/profession_skills_steadfast.png", (4, 4), (128, 128), 3),
    AtlasSpec("exec-ecb47128-77b4-4ad1-a722-3d6a0633d6a0.png", "assets/art/vfx/profession_skills_armorer.png", (4, 4), (128, 128), 3),
    AtlasSpec("exec-989417dd-8d58-42f8-8479-5539d6b02d74.png", "assets/art/vfx/profession_skills_resonant.png", (4, 4), (128, 128), 3),
    AtlasSpec("exec-752821f6-8aa3-4f8c-964f-30eb6d215264.png", "assets/art/ui/progression_status_icons.png", (6, 3), (32, 32), 1),
    # P2
    AtlasSpec("exec-3059b855-28e7-4095-b46e-335cc09e0efd.png", "assets/art/characters/npcs/story_npc_portraits.png", (3, 2), (192, 192), 2, True),
    AtlasSpec("exec-235db0ae-0c28-4a82-89a9-f2520860dc96.png", "assets/art/worlds/metro/metro_maintenance_atlas.png", (4, 2), (128, 128), 1),
    AtlasSpec("exec-bbcae819-c1be-4c99-9f70-1dd15f64cf0f.png", "assets/art/narrative/archive_illustrations.png", (3, 2), (256, 144), 0, False, True),
    AtlasSpec("exec-13bfd2c4-9b6b-4af3-9692-ae25008346dc.png", "assets/art/vfx/milestone_feedback.png", (4, 1), (192, 192), 3),
)


def _color_distance(a: tuple[int, int, int], b: tuple[int, int, int]) -> float:
    return sum((a[index] - b[index]) ** 2 for index in range(3)) ** 0.5


def _dominant_border_key(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    samples: list[tuple[int, int, int]] = []
    step_x = max(1, rgb.width // 48)
    step_y = max(1, rgb.height // 48)
    for x in range(0, rgb.width, step_x):
        samples.extend((rgb.getpixel((x, 0)), rgb.getpixel((x, rgb.height - 1))))
    for y in range(0, rgb.height, step_y):
        samples.extend((rgb.getpixel((0, y)), rgb.getpixel((rgb.width - 1, y))))
    quantized = [(r // 16 * 16, g // 16 * 16, b // 16 * 16) for r, g, b in samples]
    bucket = Counter(quantized).most_common(1)[0][0]
    candidates = [color for color in samples if _color_distance(color, bucket) <= 28]
    return tuple(sum(color[index] for color in candidates) // len(candidates) for index in range(3))


def _remove_key(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    key = _dominant_border_key(rgba)
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            distance = _color_distance((red, green, blue), key)
            if distance <= 62:
                pixels[x, y] = (0, 0, 0, 0)
            elif distance <= 118:
                matte = int(alpha * (distance - 62) / 56)
                # Despill only the dominant key channel.  This preserves pale
                # cyan and ivory pixels while removing magenta/green fringe.
                channels = [red, green, blue]
                key_channel = max(range(3), key=lambda index: key[index])
                others = [channels[index] for index in range(3) if index != key_channel]
                channels[key_channel] = min(channels[key_channel], max(others))
                pixels[x, y] = (*channels, matte)
    return rgba


def _split_cell(source: Image.Image, column: int, row: int, grid: tuple[int, int]) -> Image.Image:
    columns, rows = grid
    left = round(column * source.width / columns)
    right = round((column + 1) * source.width / columns)
    top = round(row * source.height / rows)
    bottom = round((row + 1) * source.height / rows)
    # Generated masters often include a one-to-three-pixel white gutter.
    inset_x = max(1, round((right - left) * 0.008))
    inset_y = max(1, round((bottom - top) * 0.008))
    return _remove_key(source.crop((left + inset_x, top + inset_y, right - inset_x, bottom - inset_y)))


def _fit(source: Image.Image, spec: AtlasSpec) -> Image.Image:
    alpha = source.getchannel("A")
    bounds = alpha.getbbox()
    if bounds:
        source = source.crop(bounds)
    else:
        source = Image.new("RGBA", (1, 1))
    available = (spec.cell[0] - spec.margin * 2, spec.cell[1] - spec.margin * 2)
    if spec.cover:
        scale = max(available[0] / source.width, available[1] / source.height)
    else:
        scale = min(available[0] / source.width, available[1] / source.height)
    target = (max(1, round(source.width * scale)), max(1, round(source.height * scale)))
    resized = source.resize(target, Image.Resampling.LANCZOS)
    resized.putalpha(resized.getchannel("A").point(lambda value: 0 if value < 52 else value))
    if spec.cover:
        x0 = max(0, (resized.width - spec.cell[0]) // 2)
        y0 = max(0, (resized.height - spec.cell[1]) // 2)
        return resized.crop((x0, y0, x0 + spec.cell[0], y0 + spec.cell[1]))
    output = Image.new("RGBA", spec.cell)
    x = (spec.cell[0] - resized.width) // 2
    y = spec.cell[1] - spec.margin - resized.height if spec.bottom_anchor else (spec.cell[1] - resized.height) // 2
    output.alpha_composite(resized, (x, y))
    return output


def _remove_thin_dividers(image: Image.Image) -> Image.Image:
    """Remove one-to-four-pixel guide rules accidentally emitted by a master."""
    output = image.copy()
    alpha = output.getchannel("A")

    def thin_runs(values: list[int], threshold: int) -> list[tuple[int, int]]:
        runs: list[tuple[int, int]] = []
        start = -1
        for index, value in enumerate(values + [0]):
            if value >= threshold and start < 0:
                start = index
            elif value < threshold and start >= 0:
                if index - start <= 4:
                    runs.append((start, index))
                start = -1
        return runs

    columns = [sum(alpha.getpixel((x, y)) > 40 for y in range(alpha.height)) for x in range(alpha.width)]
    rows = [sum(alpha.getpixel((x, y)) > 40 for x in range(alpha.width)) for y in range(alpha.height)]
    for left, right in thin_runs(columns, round(alpha.height * 0.82)):
        clear_left = max(0, left - 1)
        clear_right = min(alpha.width, right + 1)
        sample_left = max(0, clear_left - 1)
        sample_right = min(alpha.width - 1, clear_right)
        for x in range(clear_left, clear_right):
            for y in range(alpha.height):
                before = image.getpixel((sample_left, y))
                after = image.getpixel((sample_right, y))
                if before[3] > 40 and after[3] > 40:
                    weight = (x - clear_left + 1) / (clear_right - clear_left + 1)
                    output.putpixel((x, y), tuple(round(before[i] * (1.0 - weight) + after[i] * weight) for i in range(4)))
                else:
                    output.putpixel((x, y), (0, 0, 0, 0))
    for top, bottom in thin_runs(rows, round(alpha.width * 0.82)):
        clear_top = max(0, top - 1)
        clear_bottom = min(alpha.height, bottom + 1)
        sample_top = max(0, clear_top - 1)
        sample_bottom = min(alpha.height - 1, clear_bottom)
        for y in range(clear_top, clear_bottom):
            for x in range(alpha.width):
                before = image.getpixel((x, sample_top))
                after = image.getpixel((x, sample_bottom))
                if before[3] > 40 and after[3] > 40:
                    weight = (y - clear_top + 1) / (clear_bottom - clear_top + 1)
                    output.putpixel((x, y), tuple(round(before[i] * (1.0 - weight) + after[i] * weight) for i in range(4)))
                else:
                    output.putpixel((x, y), (0, 0, 0, 0))
    return output


def _save(image: Image.Image, target: Path) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            red, green, blue, alpha = pixels[x, y]
            # Final generated-key guard matches the runtime asset tests.  The
            # authored violet palette stays below this high-red/high-blue band.
            if alpha > 0 and red > 183 and blue > 183 and green < 77:
                pixels[x, y] = (0, 0, 0, 0)
    temporary = target.with_suffix(target.suffix + ".building")
    quantized = image.quantize(
        colors=128,
        method=Image.Quantize.FASTOCTREE,
        dither=Image.Dither.NONE,
    ).convert("RGBA")
    quantized.save(
        temporary,
        format="PNG",
        optimize=True,
    )
    temporary.replace(target)


def build(spec: AtlasSpec, generated: Path, project: Path) -> None:
    source = Image.open(generated / spec.source).convert("RGBA")
    atlas = Image.new("RGBA", (spec.grid[0] * spec.cell[0], spec.grid[1] * spec.cell[1]))
    for row in range(spec.grid[1]):
        for column in range(spec.grid[0]):
            cell = _fit(_split_cell(source, column, row, spec.grid), spec)
            if spec.remove_dividers:
                cell = _remove_thin_dividers(cell)
            atlas.alpha_composite(cell, (column * spec.cell[0], row * spec.cell[1]))
    _save(atlas, project / spec.target)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--generated-dir", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()
    for spec in SPECS:
        build(spec, args.generated_dir, args.project_root)


if __name__ == "__main__":
    main()
