#!/usr/bin/env python3
"""Build the 64px runtime atlas for bow, staff, shield and codex."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


CELL_SIZE = 64
CELL_COUNT = 4
VISIBLE_SIZE = 58


def _remove_green(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            green_bias = green - max(red, blue)
            if green_bias >= 72 and green >= 120:
                pixels[x, y] = (0, 0, 0, 0)
            elif green_bias >= 24 and green >= 90:
                matte = round(alpha * (72 - green_bias) / 48)
                pixels[x, y] = (red, min(green, max(red, blue)), blue, matte)
    return rgba


def _keep_components(image: Image.Image) -> Image.Image:
    """Remove tiny generator flecks while preserving disconnected bow strings."""
    alpha = image.getchannel("A")
    width, height = image.size
    visible = {
        (x, y)
        for y in range(height)
        for x in range(width)
        if alpha.getpixel((x, y)) >= 24
    }
    components: list[set[tuple[int, int]]] = []
    while visible:
        seed = visible.pop()
        component = {seed}
        pending = deque([seed])
        while pending:
            x, y = pending.popleft()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in visible:
                    visible.remove(neighbor)
                    component.add(neighbor)
                    pending.append(neighbor)
        components.append(component)
    if not components:
        return image
    largest = max(len(component) for component in components)
    keep = set().union(
        *(component for component in components if len(component) >= max(24, largest // 120))
    )
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            if (x, y) not in keep:
                pixels[x, y] = (0, 0, 0, 0)
    return image


def _normalize(cell: Image.Image) -> Image.Image:
    cleaned = _keep_components(_remove_green(cell))
    bounds = cleaned.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("Generated equipment cell has no visible pixels")
    art = cleaned.crop(bounds)
    scale = min(VISIBLE_SIZE / art.width, VISIBLE_SIZE / art.height)
    size = (
        max(1, round(art.width * scale)),
        max(1, round(art.height * scale)),
    )
    art = art.resize(size, Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (CELL_SIZE, CELL_SIZE))
    frame.alpha_composite(
        art,
        ((CELL_SIZE - art.width) // 2, (CELL_SIZE - art.height) // 2),
    )
    return frame


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    source = Image.open(args.source)
    atlas = Image.new("RGBA", (CELL_SIZE * CELL_COUNT, CELL_SIZE))
    for index in range(CELL_COUNT):
        left = round(index * source.width / CELL_COUNT)
        right = round((index + 1) * source.width / CELL_COUNT)
        cell = source.crop((left, 0, right, source.height))
        atlas.alpha_composite(_normalize(cell), (index * CELL_SIZE, 0))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(args.output, "PNG", optimize=True)


if __name__ == "__main__":
    main()
