#!/usr/bin/env python3
"""Build direction-aware skeletal rig pieces from approved character turnarounds.

The source contract is deliberately strict:

* one transparent image;
* four equally sized columns in front/left/right/back order;
* one equipment-free character per column;
* aligned feet and a neutral, slightly separated rigging pose.

The output uses a shared fourteen-part anatomy contract.  Joint regions overlap
on purpose so rotations never reveal gaps at shoulders, elbows, hips or knees.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from statistics import median
from typing import Iterable

from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = ("front", "left", "right", "back")
TARGET_HEIGHT = 420
ATLAS_WIDTH = 2048
ATLAS_PADDING = 4


def normalized_polygon(
    size: tuple[int, int], points: Iterable[tuple[float, float]]
) -> list[tuple[int, int]]:
    width, height = size
    return [(round(x * width), round(y * height)) for x, y in points]


def masked_piece(
    character: Image.Image,
    points: Iterable[tuple[float, float]],
    *,
    pad: int = 8,
    darken: float = 1.0,
) -> tuple[Image.Image, tuple[int, int, int, int]]:
    mask = Image.new("L", character.size)
    ImageDraw.Draw(mask).polygon(normalized_polygon(character.size, points), fill=255)
    alpha = Image.new("L", character.size)
    alpha.paste(character.getchannel("A"))
    alpha = Image.composite(alpha, Image.new("L", character.size), mask)
    layer = character.copy()
    if darken != 1.0:
        layer = ImageEnhance.Brightness(layer).enhance(darken)
    layer.putalpha(alpha)
    bounds = layer.getbbox()
    if bounds is None:
        raise RuntimeError("Part mask did not intersect the character")
    left, top, right, bottom = bounds
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(layer.width, right + pad)
    bottom = min(layer.height, bottom + pad)
    bounds = (left, top, right, bottom)
    return layer.crop(bounds), bounds


def character_columns(source: Image.Image) -> dict[str, Image.Image]:
    column_width = source.width / 4.0
    characters: dict[str, Image.Image] = {}
    for index, direction in enumerate(DIRECTIONS):
        left = round(index * column_width)
        right = round((index + 1) * column_width)
        column = source.crop((left, 0, right, source.height))
        bounds = column.getbbox()
        if bounds is None:
            raise RuntimeError(f"No character pixels in {direction} column")
        character = column.crop(bounds)
        scale = TARGET_HEIGHT / character.height
        character = character.resize(
            (max(1, round(character.width * scale)), TARGET_HEIGHT),
            Image.Resampling.LANCZOS,
        )
        characters[direction] = character
    return characters


def part_polygons(
    direction: str, center_x: float = 0.5
) -> dict[str, list[tuple[float, float]]]:
    front_back = {
        "head": [(0.29, 0.0), (0.71, 0.0), (0.70, 0.23), (0.30, 0.23)],
        "torso": [(0.25, 0.15), (0.75, 0.15), (0.70, 0.59), (0.30, 0.59)],
        "left_upper": [(0.00, 0.16), (0.28, 0.15), (0.27, 0.40), (0.05, 0.42)],
        "left_forearm": [(0.00, 0.34), (0.25, 0.32), (0.24, 0.61), (0.00, 0.62)],
        "right_upper": [(0.72, 0.15), (1.00, 0.16), (0.95, 0.42), (0.73, 0.40)],
        "right_forearm": [(0.75, 0.32), (1.00, 0.34), (1.00, 0.62), (0.76, 0.61)],
        "thigh_left": [(0.20, 0.49), (0.49, 0.49), (0.48, 0.80), (0.20, 0.80)],
        "shin_left": [(0.22, 0.70), (0.48, 0.70), (0.48, 1.0), (0.18, 1.0)],
        "thigh_right": [(0.51, 0.49), (0.80, 0.49), (0.80, 0.80), (0.52, 0.80)],
        "shin_right": [(0.52, 0.70), (0.78, 0.70), (0.82, 1.0), (0.52, 1.0)],
        "coat_left": [(0.14, 0.40), (0.32, 0.40), (0.34, 0.78), (0.12, 0.78)],
        "coat_right": [(0.68, 0.40), (0.86, 0.40), (0.88, 0.78), (0.66, 0.78)],
    }
    if direction in ("front", "back"):
        return front_back

    # In profile views the far limbs are mostly occluded.  Both masks therefore
    # share a narrow covered strip; the far copy is darkened during export.
    side = {
        "head": [(0.18, 0.0), (0.82, 0.0), (0.80, 0.26), (0.20, 0.26)],
        "torso": [(0.15, 0.15), (0.85, 0.15), (0.79, 0.58), (0.21, 0.58)],
        # Profile limbs use narrow silhouette strips.  The old broad masks
        # captured chunks of the chest and produced visible rectangular tabs.
        "left_upper": [(0.48, 0.17), (0.88, 0.16), (0.83, 0.41), (0.48, 0.42)],
        "left_forearm": [(0.48, 0.33), (0.84, 0.32), (0.78, 0.63), (0.43, 0.64)],
        "right_upper": [(0.40, 0.17), (0.78, 0.16), (0.77, 0.41), (0.40, 0.42)],
        "right_forearm": [(0.40, 0.33), (0.77, 0.32), (0.72, 0.63), (0.37, 0.64)],
        "thigh_left": [(0.20, 0.48), (0.63, 0.48), (0.65, 0.80), (0.19, 0.80)],
        "shin_left": [(0.18, 0.70), (0.65, 0.70), (0.67, 1.0), (0.15, 1.0)],
        "thigh_right": [(0.37, 0.48), (0.82, 0.48), (0.82, 0.80), (0.35, 0.80)],
        "shin_right": [(0.35, 0.70), (0.83, 0.70), (0.86, 1.0), (0.34, 1.0)],
        "coat_left": [(0.12, 0.34), (0.58, 0.34), (0.62, 0.79), (0.10, 0.79)],
        "coat_right": [(0.38, 0.34), (0.88, 0.34), (0.90, 0.79), (0.40, 0.79)],
    }
    if direction == "right":
        side = {
            name: [(1.0 - x, y) for x, y in reversed(points)]
            for name, points in side.items()
        }
    shift = center_x - 0.5
    return {
        name: [(x + shift, y) for x, y in points]
        for name, points in side.items()
    }


def joint_map(
    direction: str, center_x: float = 0.5
) -> dict[str, tuple[float, float]]:
    """Return direction-specific pivots in normalized source coordinates.

    These anchors preserve the approved turnaround's neutral silhouette.  The
    runtime uses the same points as actual Bone2D pivots, so animation starts
    from the source pose instead of guessing joints from crop dimensions.
    """
    if direction in ("front", "back"):
        return {
            "root": (0.50, 1.00),
            "hips": (0.50, 0.54),
            "torso": (0.50, 0.54),
            "head": (0.50, 0.18),
            "left_shoulder": (0.25, 0.22),
            "left_elbow": (0.18, 0.39),
            "left_hand": (0.14, 0.57),
            "right_shoulder": (0.75, 0.22),
            "right_elbow": (0.82, 0.39),
            "right_hand": (0.86, 0.57),
            "left_hip": (0.43, 0.54),
            "left_knee": (0.40, 0.76),
            "left_foot": (0.39, 0.97),
            "right_hip": (0.57, 0.54),
            "right_knee": (0.60, 0.76),
            "right_foot": (0.61, 0.97),
            "coat_left": (0.43, 0.50),
            "coat_right": (0.57, 0.50),
        }
    anchors = {
        "root": (0.50, 1.00),
        "hips": (0.50, 0.54),
        "torso": (0.50, 0.54),
        "head": (0.50, 0.18),
        "left_shoulder": (0.52, 0.22),
        "left_elbow": (0.59, 0.40),
        "left_hand": (0.57, 0.58),
        "right_shoulder": (0.47, 0.22),
        "right_elbow": (0.52, 0.40),
        "right_hand": (0.51, 0.58),
        "left_hip": (0.47, 0.54),
        "left_knee": (0.45, 0.76),
        "left_foot": (0.43, 0.97),
        "right_hip": (0.53, 0.54),
        "right_knee": (0.55, 0.76),
        "right_foot": (0.57, 0.97),
        "coat_left": (0.47, 0.50),
        "coat_right": (0.53, 0.50),
    }
    if direction == "right":
        anchors = {
            name: (1.0 - point[0], point[1])
            for name, point in anchors.items()
        }
    shift = center_x - 0.5
    return {
        name: (point[0] + shift, point[1])
        for name, point in anchors.items()
    }


def silhouette_center(character: Image.Image, direction: str) -> float:
    if direction in ("front", "back"):
        return 0.5
    alpha = character.getchannel("A")
    pixels = alpha.load()
    xs: list[int] = []
    # Sample the main vertical anatomy and ignore the extreme transparent
    # margins introduced by capes or a slightly extended hand.
    for y in range(round(character.height * 0.08), round(character.height * 0.94), 3):
        row = [x for x in range(character.width) if pixels[x, y] > 32]
        if row:
            xs.append(round(median(row)))
    return float(median(xs)) / character.width if xs else 0.5


def build(source_path: Path, style_id: str) -> None:
    source = Image.open(source_path).convert("RGBA")
    output_root = (
        ROOT / "assets/art/characters/professions/rigs" / style_id
    )
    exported: list[tuple[str, str, Image.Image]] = []
    manifests: dict[str, dict] = {}
    for direction, character in character_columns(source).items():
        center_x = silhouette_center(character, direction)
        polygons = part_polygons(direction, center_x)
        direction_root = output_root / direction
        direction_root.mkdir(parents=True, exist_ok=True)
        parts = {
            "head": ("head", 1.0),
            "torso": ("torso", 1.0),
            "left_upper": ("left_upper", 1.0),
            "left_forearm": ("left_forearm", 1.0),
            "right_upper": ("right_upper", 1.0),
            "right_forearm": ("right_forearm", 1.0),
            "thigh_near": ("thigh_left", 1.0),
            "shin_near": ("shin_left", 1.0),
            "thigh_far": ("thigh_right", 0.78),
            "shin_far": ("shin_right", 0.78),
            "coat_near": ("coat_left", 1.0),
            "coat_far": ("coat_right", 0.78),
        }
        if direction == "right":
            parts["thigh_near"], parts["thigh_far"] = (
                parts["thigh_far"],
                parts["thigh_near"],
            )
            parts["shin_near"], parts["shin_far"] = (
                parts["shin_far"],
                parts["shin_near"],
            )
            parts["coat_near"], parts["coat_far"] = (
                parts["coat_far"],
                parts["coat_near"],
            )
        manifest: dict = {
            "frame_size": [character.width, character.height],
            "joints": {
                name: [round(x * character.width, 3), round(y * character.height, 3)]
                for name, (x, y) in joint_map(direction, center_x).items()
            },
            "parts": {},
        }
        for output_name, (mask_name, brightness) in parts.items():
            piece, bounds = masked_piece(
                character, polygons[mask_name], darken=brightness
            )
            exported.append((direction, output_name, piece))
            manifest["parts"][output_name] = {
                "bounds": list(bounds),
                "center": [
                    (bounds[0] + bounds[2]) * 0.5,
                    (bounds[1] + bounds[3]) * 0.5,
                ],
            }
        manifests[direction] = manifest

    atlas_height = _pack_atlas(exported, manifests, output_root)
    for direction, manifest in manifests.items():
        manifest["atlas"] = "../atlas.png"
        manifest["atlas_size"] = [ATLAS_WIDTH, atlas_height]
        direction_root = output_root / direction
        (direction_root / "rig.json").write_text(
            json.dumps(manifest, indent=2) + "\n",
            encoding="utf-8",
        )


def _pack_atlas(
    exported: list[tuple[str, str, Image.Image]],
    manifests: dict[str, dict],
    output_root: Path,
) -> int:
    placements: list[tuple[int, int, str, str, Image.Image]] = []
    x = ATLAS_PADDING
    y = ATLAS_PADDING
    row_height = 0
    for direction, part_name, piece in exported:
        if x + piece.width + ATLAS_PADDING > ATLAS_WIDTH:
            x = ATLAS_PADDING
            y += row_height + ATLAS_PADDING
            row_height = 0
        placements.append((x, y, direction, part_name, piece))
        manifests[direction]["parts"][part_name]["region"] = [
            x,
            y,
            piece.width,
            piece.height,
        ]
        x += piece.width + ATLAS_PADDING
        row_height = max(row_height, piece.height)
    atlas_height = y + row_height + ATLAS_PADDING
    atlas = Image.new("RGBA", (ATLAS_WIDTH, atlas_height))
    for left, top, _direction, _part_name, piece in placements:
        atlas.alpha_composite(piece, (left, top))
    output_root.mkdir(parents=True, exist_ok=True)
    atlas.save(output_root / "atlas.png", optimize=True)
    return atlas_height


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("style_id")
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    build(args.source, args.style_id)


if __name__ == "__main__":
    main()
