#!/usr/bin/env python3
"""Extract an inspectable humanoid skin and add hidden joint coverage."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw


PART_TO_JOINT = {
    "head": "head",
    "torso": "torso",
    "left_upper_arm": "left_shoulder",
    "left_forearm": "left_elbow",
    "right_upper_arm": "right_shoulder",
    "right_forearm": "right_elbow",
    "left_thigh": "left_hip",
    "left_shin": "left_knee",
    "right_thigh": "right_hip",
    "right_shin": "right_knee",
    "coat_far": "coat_left",
    "coat_near": "coat_right",
}

STATIC_LEGACY_KEYS = {
    "head": "head",
    "torso": "torso",
    "left_upper_arm": "left_upper",
    "left_forearm": "left_forearm",
    "right_upper_arm": "right_upper",
    "right_forearm": "right_forearm",
    "coat_far": "coat_far",
    "coat_near": "coat_near",
}

JOINTED_PARTS = {
    "head",
    "left_upper_arm",
    "left_forearm",
    "right_upper_arm",
    "right_forearm",
    "left_thigh",
    "left_shin",
    "right_thigh",
    "right_shin",
}


def legacy_keys(direction: str) -> dict[str, str]:
    keys = dict(STATIC_LEGACY_KEYS)
    if direction == "right":
        keys.update(
            {
                "left_thigh": "thigh_far",
                "left_shin": "shin_far",
                "right_thigh": "thigh_near",
                "right_shin": "shin_near",
            }
        )
    else:
        keys.update(
            {
                "left_thigh": "thigh_near",
                "left_shin": "shin_near",
                "right_thigh": "thigh_far",
                "right_shin": "shin_far",
            }
        )
    return keys


def sample_joint_color(
    image: Image.Image,
    center: tuple[float, float],
    radius: int,
) -> tuple[int, int, int, int]:
    pixels = []
    cx, cy = center
    for y in range(max(0, round(cy - radius)), min(image.height, round(cy + radius + 1))):
        for x in range(max(0, round(cx - radius)), min(image.width, round(cx + radius + 1))):
            red, green, blue, alpha = image.getpixel((x, y))
            if alpha >= 160:
                pixels.append((red, green, blue))
    if not pixels:
        return (58, 55, 47, 255)
    return (
        round(median(pixel[0] for pixel in pixels)),
        round(median(pixel[1] for pixel in pixels)),
        round(median(pixel[2] for pixel in pixels)),
        255,
    )


def add_hidden_joint_cap(
    part: Image.Image,
    pivot: tuple[float, float],
    padding: int,
) -> tuple[Image.Image, tuple[float, float]]:
    padded = Image.new(
        "RGBA",
        (part.width + padding * 2, part.height + padding * 2),
        (0, 0, 0, 0),
    )
    pivot_in_part = (pivot[0], pivot[1])
    cap_radius = max(5, min(14, round(part.width * 0.18)))
    cap_color = sample_joint_color(part, pivot_in_part, cap_radius * 2)
    cap_center = (pivot[0] + padding, pivot[1] + padding)
    draw = ImageDraw.Draw(padded)
    draw.ellipse(
        (
            cap_center[0] - cap_radius,
            cap_center[1] - cap_radius,
            cap_center[0] + cap_radius,
            cap_center[1] + cap_radius,
        ),
        fill=cap_color,
        outline=(
            max(0, cap_color[0] - 24),
            max(0, cap_color[1] - 24),
            max(0, cap_color[2] - 24),
            255,
        ),
        width=2,
    )
    padded.alpha_composite(part, (padding, padding))
    return padded, cap_center


def extract(
    rig_root: Path,
    output_root: Path,
) -> None:
    atlas = Image.open(rig_root / "atlas.webp").convert("RGBA")
    for direction in ("front", "left", "right", "back"):
        legacy_path = rig_root / direction / "rig.json"
        legacy = json.loads(legacy_path.read_text(encoding="utf-8"))
        direction_root = output_root / direction
        direction_root.mkdir(parents=True, exist_ok=True)
        keys = legacy_keys(direction)
        manifest = {
            "schema_version": 2,
            "source": "individual",
            "frame_size": legacy["frame_size"],
            "joints": legacy["joints"],
            "parts": {},
        }
        for name, legacy_name in keys.items():
            legacy_part = legacy["parts"][legacy_name]
            region_x, region_y, region_width, region_height = legacy_part["region"]
            part = atlas.crop(
                (
                    int(region_x),
                    int(region_y),
                    int(region_x + region_width),
                    int(region_y + region_height),
                )
            )
            left, top, _right, _bottom = legacy_part["bounds"]
            joint_x, joint_y = legacy["joints"][PART_TO_JOINT[name]]
            pivot = (float(joint_x) - float(left), float(joint_y) - float(top))
            if name in JOINTED_PARTS:
                part, pivot = add_hidden_joint_cap(part, pivot, padding=10)
            output_path = direction_root / f"{name}.webp"
            part.save(output_path, "WEBP", lossless=True, method=6)
            manifest["parts"][name] = {
                "file": output_path.name,
                "size": [part.width, part.height],
                "pivot": [pivot[0], pivot[1]],
            }
        (direction_root / "rig.json").write_text(
            json.dumps(manifest, indent=2) + "\n",
            encoding="utf-8",
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("rig_root", type=Path)
    parser.add_argument("output_root", type=Path)
    args = parser.parse_args()
    extract(args.rig_root, args.output_root)


if __name__ == "__main__":
    main()
