#!/usr/bin/env python3
"""Build the 128px martial-artist demo atlases from approved chroma masters."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path

from PIL import Image


FRAME_SIZE = 128
FRAME_COUNT = 6
ART_TOP = 13
GROUND_Y = 85
MAX_ART_HEIGHT = GROUND_Y - ART_TOP
MAX_ART_WIDTH = 112


def _dominant_border_key(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    samples: list[tuple[int, int, int]] = []
    step_x = max(1, rgb.width // 64)
    step_y = max(1, rgb.height // 64)
    for x in range(0, rgb.width, step_x):
        samples.extend((rgb.getpixel((x, 0)), rgb.getpixel((x, rgb.height - 1))))
    for y in range(0, rgb.height, step_y):
        samples.extend((rgb.getpixel((0, y)), rgb.getpixel((rgb.width - 1, y))))
    buckets = [(r // 8 * 8, g // 8 * 8, b // 8 * 8) for r, g, b in samples]
    return Counter(buckets).most_common(1)[0][0]


def _remove_chroma(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    key = _dominant_border_key(rgba)
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            distance = sum(
                (channel - key[index]) ** 2
                for index, channel in enumerate((red, green, blue))
            ) ** 0.5
            if distance <= 54:
                pixels[x, y] = (0, 0, 0, 0)
            elif distance <= 112:
                matte = round(alpha * (distance - 54) / 58)
                green = min(green, max(red, blue))
                pixels[x, y] = (red, green, blue, matte)
    return rgba


def _source_cell(source: Image.Image, column: int, row: int, rows: int) -> Image.Image:
    left = round(column * source.width / FRAME_COUNT)
    right = round((column + 1) * source.width / FRAME_COUNT)
    top = round(row * source.height / rows)
    bottom = round((row + 1) * source.height / rows)
    inset_x = max(2, round((right - left) * 0.015))
    inset_y = max(2, round((bottom - top) * 0.015))
    return _keep_largest_component(_remove_chroma(
        source.crop((left + inset_x, top + inset_y, right - inset_x, bottom - inset_y))
    ))


def _keep_largest_component(image: Image.Image) -> Image.Image:
    """Drop feet/hair fragments leaking across generated grid boundaries."""
    alpha = image.getchannel("A")
    width, height = image.size
    visible = {
        (x, y)
        for y in range(height)
        for x in range(width)
        if alpha.getpixel((x, y)) >= 28
    }
    components: list[set[tuple[int, int]]] = []
    while visible:
        seed = visible.pop()
        component = {seed}
        pending = [seed]
        while pending:
            x, y = pending.pop()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in visible:
                    visible.remove(neighbor)
                    component.add(neighbor)
                    pending.append(neighbor)
        components.append(component)
    if not components:
        return image
    keep = max(components, key=len)
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            if (x, y) not in keep:
                pixels[x, y] = (0, 0, 0, 0)
    return image


def _normalize_frame(source: Image.Image) -> Image.Image:
    bounds = source.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("Generated source cell has no visible character")
    art = source.crop(bounds)
    scale = min(MAX_ART_WIDTH / art.width, MAX_ART_HEIGHT / art.height)
    size = (max(1, round(art.width * scale)), max(1, round(art.height * scale)))
    art = art.resize(size, Image.Resampling.LANCZOS)
    alpha = art.getchannel("A").point(lambda value: 0 if value < 28 else value)
    art.putalpha(alpha)
    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
    frame.alpha_composite(art, ((FRAME_SIZE - art.width) // 2, GROUND_Y - art.height))
    return frame


def _write_row(
    source: Image.Image,
    row: int,
    rows: int,
    output_path: Path,
) -> None:
    atlas = Image.new("RGBA", (FRAME_SIZE * FRAME_COUNT, FRAME_SIZE))
    for column in range(FRAME_COUNT):
        frame = _normalize_frame(_source_cell(source, column, row, rows))
        atlas.alpha_composite(frame, (column * FRAME_SIZE, 0))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output_path, "PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--back-source", type=Path, required=True)
    parser.add_argument("--attack-source", type=Path, required=True)
    parser.add_argument("--project-root", type=Path, required=True)
    args = parser.parse_args()

    target = (
        args.project_root
        / "assets/art/characters/rendered3d/martial_artist_trial"
    )
    back = Image.open(args.back_source)
    attack = Image.open(args.attack_source)
    _write_row(back, 0, 2, target / "idle_back.png")
    _write_row(back, 1, 2, target / "walk_back.png")
    _write_row(attack, 0, 3, target / "attack_front.png")
    _write_row(attack, 1, 3, target / "attack_back.png")
    _write_row(attack, 2, 3, target / "attack_left.png")


if __name__ == "__main__":
    main()
