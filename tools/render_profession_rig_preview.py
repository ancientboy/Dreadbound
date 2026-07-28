#!/usr/bin/env python3
"""Render rest-pose contact sheets using the formal generic rig layout.

This is a deterministic visual QA helper.  It mirrors the joint placement in
ProfessionSkeletonCharacter without starting Godot, making severed joints,
bad overlap masks and direction-order mistakes visible in one image.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = ("front", "left", "right", "back")
SKIN_ROOT = ROOT / "assets/art/characters/professions/skins"

SKIN_JOINTS = {
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


def load_parts(style_id: str, direction: str) -> dict[str, Image.Image]:
    folder = (
        ROOT / "assets/art/characters/professions/rigs" / style_id / direction
    )
    manifest = json.loads((folder / "rig.json").read_text(encoding="utf-8"))
    atlas = Image.open(folder.parent / "atlas.png").convert("RGBA")
    return {
        name: atlas.crop(
            (
                int(part["region"][0]),
                int(part["region"][1]),
                int(part["region"][0] + part["region"][2]),
                int(part["region"][1] + part["region"][3]),
            )
        )
        for name, part in manifest["parts"].items()
    }


def paste_center(
    canvas: Image.Image,
    image: Image.Image,
    center: tuple[float, float],
) -> None:
    x = round(center[0] - image.width * 0.5)
    y = round(center[1] - image.height * 0.5)
    canvas.alpha_composite(image, (x, y))


def render(style_id: str, direction: str) -> Image.Image:
    skin_folder = SKIN_ROOT / style_id / direction
    if skin_folder.is_dir():
        return render_skin(style_id, direction)
    p = load_parts(style_id, direction)
    canvas = Image.new("RGBA", (440, 580), (17, 24, 39, 255))
    folder = (
        ROOT / "assets/art/characters/professions/rigs" / style_id / direction
    )
    manifest = json.loads((folder / "rig.json").read_text(encoding="utf-8"))
    frame_width, frame_height = manifest["frame_size"]
    offset = ((canvas.width - frame_width) // 2, canvas.height - frame_height - 30)
    order = [
        "coat_far",
        "thigh_far",
        "shin_far",
        "left_upper",
        "right_upper",
        "torso",
        "left_forearm",
        "right_forearm",
        "coat_near",
        "thigh_near",
        "shin_near",
        "head",
    ]
    for part_name in order:
        left, top, _right, _bottom = manifest["parts"][part_name]["bounds"]
        canvas.alpha_composite(
            p[part_name],
            (round(offset[0] + left), round(offset[1] + top)),
        )
    return canvas


def render_skin(style_id: str, direction: str) -> Image.Image:
    folder = SKIN_ROOT / style_id / direction
    manifest = json.loads((folder / "rig.json").read_text(encoding="utf-8"))
    parts = {
        name: Image.open(folder / part["file"]).convert("RGBA")
        for name, part in manifest["parts"].items()
    }
    frame_width, frame_height = manifest["frame_size"]
    canvas = Image.new("RGBA", (440, 580), (17, 24, 39, 255))
    offset = ((canvas.width - frame_width) // 2, canvas.height - frame_height - 30)
    near = "right" if direction == "right" else "left"
    far = "left" if near == "right" else "right"
    order = [
        "coat_far",
        f"{far}_thigh",
        f"{far}_shin",
        f"{far}_upper_arm",
        f"{far}_forearm",
        "torso",
        f"{near}_thigh",
        f"{near}_shin",
        f"{near}_upper_arm",
        f"{near}_forearm",
        "coat_near",
        "head",
    ]
    for name in order:
        part = manifest["parts"][name]
        joint_x, joint_y = manifest["joints"][SKIN_JOINTS[name]]
        pivot_x, pivot_y = part["pivot"]
        canvas.alpha_composite(
            parts[name],
            (
                round(offset[0] + joint_x - pivot_x),
                round(offset[1] + joint_y - pivot_y),
            ),
        )
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("styles", nargs="+")
    args = parser.parse_args()
    margin = 18
    label_height = 30
    cell_width, cell_height = 440, 580
    sheet = Image.new(
        "RGBA",
        (
            cell_width * 4 + margin * 5,
            (cell_height + label_height) * len(args.styles)
            + margin * (len(args.styles) + 1),
        ),
        (8, 13, 24, 255),
    )
    draw = ImageDraw.Draw(sheet)
    for row, style_id in enumerate(args.styles):
        top = margin + row * (cell_height + label_height + margin)
        for column, direction in enumerate(DIRECTIONS):
            left = margin + column * (cell_width + margin)
            sheet.alpha_composite(render(style_id, direction), (left, top))
            draw.text(
                (left + 8, top + cell_height + 6),
                f"{style_id} · {direction}",
                fill=(238, 244, 255, 255),
            )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(args.output, quality=91)


if __name__ == "__main__":
    main()
