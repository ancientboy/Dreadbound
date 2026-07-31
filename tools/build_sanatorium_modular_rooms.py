#!/usr/bin/env python3
"""Build the authored sanatorium rooms from genuinely independent art layers.

The standard combat room is the architectural source of truth.  Larger room
shapes extend its floor, wall and foreground modules, while room furniture is
composited from an alpha-only prop atlas.  Runtime doors remain separate and
are never baked into any output produced here.
"""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ART_ROOT = ROOT / "assets/art/worlds/map_demo/dungeon1_sanatorium_v2"

STANDARD_FLOOR = ART_ROOT / "standard_combat_floor_v1.png"
STANDARD_WALL = ART_ROOT / "standard_combat_wall_shell_v1.png"
STANDARD_FOREGROUND = ART_ROOT / "standard_combat_foreground_v1.png"
PROP_ATLAS = ART_ROOT / "sanatorium_modular_props_v2.webp"
ELITE_EMPTY_ARCHITECTURE = ART_ROOT / "l_elite_empty_architecture_v2.webp"

LONG_SIZE = (2048, 1024)
ELITE_SIZE = (2048, 1536)


@dataclass(frozen=True)
class Placement:
    crop: tuple[int, int, int, int]
    position: tuple[int, int]
    scale: float = 1.0
    rotation: float = 0.0


def _load(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def _resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.resize(size, Image.Resampling.LANCZOS)


def _fit_with_padding(
    image: Image.Image,
    size: tuple[int, int],
) -> Image.Image:
    scale = min(size[0] / image.width, size[1] / image.height)
    fitted_size = (round(image.width * scale), round(image.height * scale))
    fitted = _resize(image, fitted_size)
    output = Image.new("RGBA", size)
    output.alpha_composite(
        fitted,
        ((size[0] - fitted.width) // 2, (size[1] - fitted.height) // 2),
    )
    return output


def _erase(image: Image.Image, box: tuple[int, int, int, int]) -> None:
    image.paste((0, 0, 0, 0), box)


def _trim(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("prop crop contains no visible pixels")
    return image.crop(bbox)


def _place_props(
    atlas: Image.Image,
    size: tuple[int, int],
    placements: list[Placement],
) -> Image.Image:
    output = Image.new("RGBA", size)
    for placement in placements:
        prop = _trim(atlas.crop(placement.crop))
        if placement.scale != 1.0:
            prop = _resize(
                prop,
                (
                    max(1, round(prop.width * placement.scale)),
                    max(1, round(prop.height * placement.scale)),
                ),
            )
        if placement.rotation:
            prop = prop.rotate(
                placement.rotation,
                resample=Image.Resampling.BICUBIC,
                expand=True,
            )
        output.alpha_composite(prop, placement.position)
    return output


def _save_webp(image: Image.Image, path: Path) -> None:
    # High-quality WebP keeps the authored texture detail while keeping every
    # binary blob small enough for connector-backed atomic GitHub uploads.
    image.save(path, "WEBP", quality=94, method=6, exact=True)


def _transparent_connected_black(image: Image.Image) -> Image.Image:
    """Remove only near-black pixels connected to the image boundary."""
    rgba = image.convert("RGBA")
    width, height = rgba.size
    pixels = rgba.load()
    outside = Image.new("L", rgba.size)
    outside_pixels = outside.load()
    queue: deque[tuple[int, int]] = deque()

    def enqueue_if_background(x: int, y: int) -> None:
        if outside_pixels[x, y]:
            return
        red, green, blue, _alpha = pixels[x, y]
        if max(red, green, blue) <= 12:
            outside_pixels[x, y] = 255
            queue.append((x, y))

    for x in range(width):
        enqueue_if_background(x, 0)
        enqueue_if_background(x, height - 1)
    for y in range(height):
        enqueue_if_background(0, y)
        enqueue_if_background(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x:
            enqueue_if_background(x - 1, y)
        if x + 1 < width:
            enqueue_if_background(x + 1, y)
        if y:
            enqueue_if_background(x, y - 1)
        if y + 1 < height:
            enqueue_if_background(x, y + 1)

    rgba.putalpha(ImageChops.invert(outside))
    return rgba


def _build_long_ward(
    floor_source: Image.Image,
    wall_source: Image.Image,
    foreground_source: Image.Image,
    atlas: Image.Image,
) -> None:
    # Architecture is a horizontal extension of the approved standard room.
    # Since each source is already a pure layer, resizing cannot bake props or
    # door leaves into the output.
    floor = _resize(floor_source, LONG_SIZE)
    wall = _resize(wall_source, LONG_SIZE)
    foreground = _resize(foreground_source, LONG_SIZE)

    # The west/east runtime door leaves use their own atlas.  Keep generous
    # transparent recesses around both sockets so an open door is visually and
    # physically unobstructed.
    _erase(wall, (0, 350, 292, 650))
    _erase(wall, (1756, 350, 2048, 650))
    _erase(foreground, (0, 350, 292, 650))
    _erase(foreground, (1756, 350, 2048, 650))

    # Three beds sit against the north wall instead of across the west doorway.
    # The entire y=420..640 cross-room route is intentionally prop-free.
    props = _place_props(
        atlas,
        LONG_SIZE,
        [
            Placement((65, 35, 260, 345), (350, 130), 0.66),
            Placement((350, 40, 550, 345), (570, 130), 0.66),
            Placement((610, 45, 800, 345), (790, 135), 0.66),
            Placement((55, 365, 270, 620), (372, 315), 0.55),
            Placement((320, 365, 560, 620), (602, 315), 0.55),
            Placement((595, 365, 890, 620), (818, 315), 0.50),
            Placement((930, 340, 1435, 640), (985, 165), 0.62),
            Placement((55, 620, 270, 945), (1510, 125), 0.68),
            Placement((275, 620, 520, 945), (1740, 125), 0.68),
            Placement((930, 650, 1150, 950), (1410, 675), 0.62),
            Placement((520, 660, 700, 950), (1650, 720), 0.56),
        ],
    )

    _save_webp(floor, ART_ROOT / "long_ward_floor_v1.webp")
    _save_webp(wall, ART_ROOT / "long_ward_wall_shell_v1.webp")
    _save_webp(props, ART_ROOT / "long_ward_props_v1.webp")
    _save_webp(foreground, ART_ROOT / "long_ward_foreground_v1.webp")


def _build_l_elite(
    empty_architecture: Image.Image,
    atlas: Image.Image,
) -> None:
    # The empty base has no furniture or door leaves.  Split it by the inner
    # walkable contour so the floor and architecture remain truly independent.
    base = _transparent_connected_black(empty_architecture)
    base_alpha = base.getchannel("A")

    floor_mask = Image.new("L", base.size)
    ImageDraw.Draw(floor_mask).polygon(
        [
            (96, 188),
            (735, 188),
            (790, 168),
            (1110, 168),
            (1190, 230),
            (1190, 805),
            (1130, 850),
            (815, 850),
            (770, 805),
            (770, 340),
            (730, 294),
            (96, 294),
        ],
        fill=255,
    )

    foreground_mask = Image.new("L", base.size)
    foreground_draw = ImageDraw.Draw(foreground_mask)
    foreground_draw.polygon(
        [(60, 286), (720, 286), (780, 326), (780, 360), (60, 326)],
        fill=255,
    )
    foreground_draw.rectangle((700, 820, 1230, 980), fill=255)

    floor = base.copy()
    floor.putalpha(ImageChops.multiply(base_alpha, floor_mask))

    foreground = base.copy()
    foreground.putalpha(ImageChops.multiply(base_alpha, foreground_mask))

    architecture_mask = ImageChops.multiply(
        ImageChops.invert(floor_mask),
        ImageChops.invert(foreground_mask),
    )
    wall = base.copy()
    wall.putalpha(ImageChops.multiply(base_alpha, architecture_mask))

    floor = _fit_with_padding(floor, ELITE_SIZE)
    wall = _fit_with_padding(wall, ELITE_SIZE)
    foreground = _fit_with_padding(foreground, ELITE_SIZE)

    props = _place_props(
        atlas,
        ELITE_SIZE,
        [
            # Observation console and screen at the blind corner.
            Placement((930, 650, 1150, 955), (1040, 300), 0.64),
            Placement((595, 365, 890, 620), (1210, 330), 0.44),
            # Two genuinely independent containment pods.
            Placement((55, 620, 270, 945), (1085, 690), 0.82),
            Placement((275, 620, 520, 945), (1515, 690), 0.82),
            Placement((520, 660, 700, 950), (1010, 1040), 0.58),
            Placement((700, 660, 875, 950), (1720, 1040), 0.58),
            Placement((1140, 690, 1250, 950), (1315, 610), 0.70),
        ],
    )

    _save_webp(floor, ART_ROOT / "l_elite_floor_v1.webp")
    _save_webp(wall, ART_ROOT / "l_elite_wall_shell_v1.webp")
    _save_webp(props, ART_ROOT / "l_elite_props_v1.webp")
    _save_webp(foreground, ART_ROOT / "l_elite_foreground_v1.webp")


def main() -> int:
    floor_source = _load(STANDARD_FLOOR)
    wall_source = _load(STANDARD_WALL)
    foreground_source = _load(STANDARD_FOREGROUND)
    atlas = _load(PROP_ATLAS)
    elite_empty_architecture = _load(ELITE_EMPTY_ARCHITECTURE)

    _build_long_ward(floor_source, wall_source, foreground_source, atlas)
    _build_l_elite(elite_empty_architecture, atlas)
    print("Built modular long ward and L-shaped elite room layers.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
