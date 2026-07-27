#!/usr/bin/env python3
"""Render a four-direction walk GIF from an individual humanoid skin."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw


DIRECTIONS = ("front", "left", "right", "back")
JOINTS = {
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


def rotate_vector(vector: tuple[float, float], degrees: float) -> tuple[float, float]:
    radians = math.radians(degrees)
    cosine = math.cos(radians)
    sine = math.sin(radians)
    x, y = vector
    return (x * cosine - y * sine, x * sine + y * cosine)


def add(left: tuple[float, float], right: tuple[float, float]) -> tuple[float, float]:
    return (left[0] + right[0], left[1] + right[1])


def rotate_about(
    point: tuple[float, float],
    origin: tuple[float, float],
    degrees: float,
) -> tuple[float, float]:
    return add(origin, rotate_vector((point[0] - origin[0], point[1] - origin[1]), degrees))


def composite_rotated(
    canvas: Image.Image,
    sprite: Image.Image,
    pivot_in_sprite: tuple[float, float],
    world_pivot: tuple[float, float],
    degrees: float,
) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    position = (
        round(world_pivot[0] - pivot_in_sprite[0]),
        round(world_pivot[1] - pivot_in_sprite[1]),
    )
    layer.alpha_composite(sprite, position)
    if abs(degrees) > 0.001:
        layer = layer.rotate(
            -degrees,
            resample=Image.Resampling.BICUBIC,
            center=(round(world_pivot[0]), round(world_pivot[1])),
        )
    canvas.alpha_composite(layer)


def render_direction(root: Path, direction: str, phase: float) -> Image.Image:
    folder = root / direction
    manifest = json.loads((folder / "rig.json").read_text(encoding="utf-8"))
    sprites = {
        name: Image.open(folder / part["file"]).convert("RGBA")
        for name, part in manifest["parts"].items()
    }
    parts = manifest["parts"]
    joints = {
        name: (float(value[0]) + 22.0, float(value[1]) + 20.0)
        for name, value in manifest["joints"].items()
    }
    frame_width, frame_height = manifest["frame_size"]
    canvas = Image.new(
        "RGBA",
        (int(frame_width + 44), int(frame_height + 44)),
        (14, 21, 34, 255),
    )

    stride = math.sin(phase * math.tau)
    lift = abs(math.sin(phase * math.tau))
    bob = lift * 3.5
    torso_angle = -stride * 2.2
    hips = (joints["hips"][0], joints["hips"][1] + bob)
    torso_pivot = (joints["torso"][0], joints["torso"][1] + bob)
    near = "right" if direction == "right" else "left"
    far = "left" if near == "right" else "right"

    leg_angles = {
        "left": stride * 17.0,
        "right": -stride * 17.0,
    }
    knee_angles = {
        "left": max(0.0, -stride) * 28.0 + lift * 3.0,
        "right": max(0.0, stride) * 28.0 + lift * 3.0,
    }
    arm_angles = {
        "left": -stride * 12.0,
        "right": stride * 12.0,
    }
    elbow_angles = {
        "left": 7.0 + max(0.0, stride) * 9.0,
        "right": -7.0 - max(0.0, -stride) * 9.0,
    }

    def pivot(name: str) -> tuple[float, float]:
        value = parts[name]["pivot"]
        return (float(value[0]), float(value[1]))

    def draw(name: str, world: tuple[float, float], angle: float) -> None:
        composite_rotated(canvas, sprites[name], pivot(name), world, angle)

    coat_far_joint = add(
        hips,
        (
            joints["coat_left"][0] - joints["hips"][0],
            joints["coat_left"][1] - joints["hips"][1],
        ),
    )
    draw("coat_far", coat_far_joint, stride * 3.0)

    leg_data = {}
    for side in (far, near):
        hip = add(
            hips,
            (
                joints[f"{side}_hip"][0] - joints["hips"][0],
                joints[f"{side}_hip"][1] - joints["hips"][1],
            ),
        )
        upper_length = joints[f"{side}_knee"][1] - joints[f"{side}_hip"][1]
        knee = add(hip, rotate_vector((0.0, upper_length), leg_angles[side]))
        leg_data[side] = (hip, knee)
        if side == far:
            draw(f"{side}_thigh", hip, leg_angles[side])
            draw(
                f"{side}_shin",
                knee,
                leg_angles[side] + knee_angles[side],
            )

    shoulder_data = {}
    for side in (far, near):
        shoulder_source = (
            joints[f"{side}_shoulder"][0],
            joints[f"{side}_shoulder"][1] + bob,
        )
        shoulder = rotate_about(shoulder_source, torso_pivot, torso_angle)
        upper_length = (
            joints[f"{side}_elbow"][1] - joints[f"{side}_shoulder"][1]
        )
        upper_angle = torso_angle + arm_angles[side]
        elbow = add(shoulder, rotate_vector((0.0, upper_length), upper_angle))
        shoulder_data[side] = (shoulder, elbow, upper_angle)
        if side == far:
            draw(f"{side}_upper_arm", shoulder, upper_angle)
            draw(
                f"{side}_forearm",
                elbow,
                upper_angle + elbow_angles[side],
            )

    draw("torso", torso_pivot, torso_angle)

    head_source = (joints["head"][0], joints["head"][1] + bob)
    draw("head", rotate_about(head_source, torso_pivot, torso_angle), torso_angle)

    for side in (near,):
        hip, knee = leg_data[side]
        draw(f"{side}_thigh", hip, leg_angles[side])
        draw(f"{side}_shin", knee, leg_angles[side] + knee_angles[side])
        shoulder, elbow, upper_angle = shoulder_data[side]
        draw(f"{side}_upper_arm", shoulder, upper_angle)
        draw(f"{side}_forearm", elbow, upper_angle + elbow_angles[side])

    coat_near_joint = add(
        hips,
        (
            joints["coat_right"][0] - joints["hips"][0],
            joints["coat_right"][1] - joints["hips"][1],
        ),
    )
    draw("coat_near", coat_near_joint, -stride * 4.0)
    return canvas


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("skin_root", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    frames = []
    for frame_index in range(16):
        phase = frame_index / 16.0
        panels = [
            render_direction(args.skin_root, direction, phase)
            for direction in DIRECTIONS
        ]
        margin = 12
        label_height = 24
        sheet = Image.new(
            "RGBA",
            (
                sum(panel.width for panel in panels) + margin * 5,
                max(panel.height for panel in panels) + margin * 2 + label_height,
            ),
            (8, 13, 24, 255),
        )
        draw = ImageDraw.Draw(sheet)
        left = margin
        for direction, panel in zip(DIRECTIONS, panels):
            sheet.alpha_composite(panel, (left, margin + label_height))
            draw.text((left + 6, margin + 4), direction, fill=(235, 242, 255, 255))
            left += panel.width + margin
        preview_size = (
            round(sheet.width * 0.6),
            round(sheet.height * 0.6),
        )
        frames.append(
            sheet.resize(preview_size, Image.Resampling.LANCZOS).convert(
                "P",
                palette=Image.Palette.ADAPTIVE,
                colors=192,
            )
        )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        args.output,
        save_all=True,
        append_images=frames[1:],
        duration=75,
        loop=0,
        optimize=True,
        disposal=2,
    )


if __name__ == "__main__":
    main()
