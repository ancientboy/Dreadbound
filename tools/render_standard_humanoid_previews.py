#!/usr/bin/env python3
"""Render aligned neutral, binding, and walk previews for humanoid v1 skins."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw


DIRECTIONS = ("front", "left", "right", "back")
BODY_PARTS = (
    "head",
    "torso",
    "left_upper_arm",
    "left_forearm",
    "right_upper_arm",
    "right_forearm",
    "left_thigh",
    "left_shin",
    "right_thigh",
    "right_shin",
    "coat_far",
    "coat_near",
)


def add(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float]:
    return (a[0] + b[0], a[1] + b[1])


def sub(a: tuple[float, float], b: tuple[float, float]) -> tuple[float, float]:
    return (a[0] - b[0], a[1] - b[1])


def rotate(vector: tuple[float, float], angle: float) -> tuple[float, float]:
    cosine = math.cos(angle)
    sine = math.sin(angle)
    return (
        vector[0] * cosine - vector[1] * sine,
        vector[0] * sine + vector[1] * cosine,
    )


def length(vector: tuple[float, float]) -> float:
    return math.hypot(vector[0], vector[1])


def axis_angle(vector: tuple[float, float]) -> float:
    return math.atan2(vector[1], vector[0]) - math.pi * 0.5


def solve_two_bone(
    root: tuple[float, float],
    target: tuple[float, float],
    upper_length: float,
    lower_length: float,
    bend_sign: float,
) -> tuple[float, float]:
    delta = sub(target, root)
    distance = min(
        max(length(delta), abs(upper_length - lower_length) + 0.001),
        upper_length + lower_length - 0.001,
    )
    target_angle = math.atan2(delta[1], delta[0])
    cosine = max(
        -1.0,
        min(
            1.0,
            (
                upper_length * upper_length
                + distance * distance
                - lower_length * lower_length
            )
            / (2.0 * upper_length * distance),
        ),
    )
    upper_world = target_angle + math.copysign(math.acos(cosine), bend_sign)
    elbow = add(root, (math.cos(upper_world) * upper_length, math.sin(upper_world) * upper_length))
    lower_world = math.atan2(target[1] - elbow[1], target[0] - elbow[0])
    return (upper_world - math.pi * 0.5, lower_world - math.pi * 0.5)


def rotated_point(
    point: tuple[float, float],
    origin: tuple[float, float],
    angle: float,
) -> tuple[float, float]:
    return add(origin, rotate(sub(point, origin), angle))


def composite_part(
    canvas: Image.Image,
    sprite: Image.Image,
    pivot: tuple[float, float],
    world_pivot: tuple[float, float],
    delta_angle: float,
) -> None:
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    layer.alpha_composite(
        sprite,
        (
            round(world_pivot[0] - pivot[0]),
            round(world_pivot[1] - pivot[1]),
        ),
    )
    if abs(delta_angle) > 0.0001:
        layer = layer.rotate(
            -math.degrees(delta_angle),
            resample=Image.Resampling.BICUBIC,
            center=(round(world_pivot[0]), round(world_pivot[1])),
        )
    canvas.alpha_composite(layer)


def load_skin(
    root: Path,
    direction: str,
) -> tuple[dict, dict[str, Image.Image]]:
    folder = root / direction
    manifest = json.loads((folder / "rig.json").read_text(encoding="utf-8"))
    if manifest.get("skeleton_id") != "humanoid_v1":
        raise ValueError(f"{folder} is not a humanoid_v1 skin")
    sprites = {
        name: Image.open(folder / part["file"]).convert("RGBA")
        for name, part in manifest["parts"].items()
    }
    return manifest, sprites


def render_pose(
    root: Path,
    direction: str,
    phase: float | None,
    show_bones: bool = False,
) -> Image.Image:
    manifest, sprites = load_skin(root, direction)
    joints = {
        name: (float(value[0]), float(value[1]))
        for name, value in manifest["joints"].items()
    }
    parts = manifest["parts"]
    canvas = Image.new("RGBA", tuple(manifest["frame_size"]), (14, 21, 34, 255))

    def pivot(name: str) -> tuple[float, float]:
        value = parts[name]["pivot"]
        return (float(value[0]), float(value[1]))

    stride = 0.0 if phase is None else math.sin(phase * math.tau)
    opposite = -stride
    left_lift = max(stride, 0.0)
    right_lift = max(opposite, 0.0)
    side_view = direction in ("left", "right")
    contact = 0.0 if phase is None else abs(math.cos(phase * math.tau)) ** 4
    hips_offset = (
        0.0 if side_view else stride * 2.2,
        contact * 3.4,
    )
    hips = add(joints["hips"], hips_offset)
    torso_delta = opposite * (0.018 if side_view else 0.010)

    travel = 23.0 if side_view else 7.0
    lift = 11.0 if side_view else 7.0
    foot_targets = {
        "left": list(joints["left_foot"]),
        "right": list(joints["right_foot"]),
    }
    if side_view:
        foot_targets["left"][0] += stride * travel
        foot_targets["right"][0] += opposite * travel
    else:
        foot_targets["left"][0] += stride * 2.5
        foot_targets["right"][0] += opposite * 2.5
        foot_targets["left"][1] += stride * travel
        foot_targets["right"][1] += opposite * travel
    foot_targets["left"][1] -= left_lift * lift
    foot_targets["right"][1] -= right_lift * lift

    leg_pose = {}
    for side, lift_value in (("left", left_lift), ("right", right_lift)):
        hip = add(joints[f"{side}_hip"], hips_offset)
        upper_rest = sub(joints[f"{side}_knee"], joints[f"{side}_hip"])
        lower_rest = sub(joints[f"{side}_foot"], joints[f"{side}_knee"])
        horizontal = joints[f"{side}_foot"][0] - joints[f"{side}_hip"][0]
        if abs(horizontal) < 0.5:
            horizontal = -1.0 if direction == "right" else 1.0
        bend = -math.copysign(1.0, horizontal)
        upper_angle, lower_angle = solve_two_bone(
            hip,
            tuple(foot_targets[side]),
            length(upper_rest),
            length(lower_rest),
            bend,
        )
        knee = add(hip, rotate((0.0, length(upper_rest)), upper_angle))
        leg_pose[side] = {
            "hip": hip,
            "knee": knee,
            "upper_delta": upper_angle - axis_angle(upper_rest),
            "lower_delta": lower_angle - axis_angle(lower_rest),
            "foot": tuple(foot_targets[side]),
        }

    arm_pose = {}
    for side, arm_stride, lift_value in (
        ("left", opposite, left_lift),
        ("right", stride, right_lift),
    ):
        shoulder = rotated_point(
            add(joints[f"{side}_shoulder"], hips_offset),
            hips,
            torso_delta,
        )
        upper_rest = sub(joints[f"{side}_elbow"], joints[f"{side}_shoulder"])
        lower_rest = sub(joints[f"{side}_hand"], joints[f"{side}_elbow"])
        arm_delta = arm_stride * (0.23 if side_view else 0.075)
        forearm_delta = (0.10 * lift_value) * (1.0 if side == "left" else -1.0)
        upper_world = axis_angle(upper_rest) + torso_delta + arm_delta
        elbow = add(shoulder, rotate((0.0, length(upper_rest)), upper_world))
        lower_world = axis_angle(lower_rest) + torso_delta + arm_delta + forearm_delta
        arm_pose[side] = {
            "shoulder": shoulder,
            "elbow": elbow,
            "upper_delta": torso_delta + arm_delta,
            "lower_delta": torso_delta + arm_delta + forearm_delta,
            "hand": add(elbow, rotate((0.0, length(lower_rest)), lower_world)),
        }

    near = "left" if direction != "right" else "right"
    far = "right" if near == "left" else "left"

    def draw(name: str, world: tuple[float, float], delta: float) -> None:
        composite_part(canvas, sprites[name], pivot(name), world, delta)

    draw("coat_far", hips, opposite * 0.035)
    draw(f"{far}_thigh", leg_pose[far]["hip"], leg_pose[far]["upper_delta"])
    draw(f"{far}_shin", leg_pose[far]["knee"], leg_pose[far]["lower_delta"])
    draw(f"{far}_upper_arm", arm_pose[far]["shoulder"], arm_pose[far]["upper_delta"])
    draw(f"{far}_forearm", arm_pose[far]["elbow"], arm_pose[far]["lower_delta"])
    draw("torso", hips, torso_delta)
    head_pivot = rotated_point(add(joints["head"], hips_offset), hips, torso_delta)
    if direction == "back":
        draw("head", head_pivot, torso_delta + stride * 0.008)
    draw(f"{near}_thigh", leg_pose[near]["hip"], leg_pose[near]["upper_delta"])
    draw(f"{near}_shin", leg_pose[near]["knee"], leg_pose[near]["lower_delta"])
    draw(f"{near}_upper_arm", arm_pose[near]["shoulder"], arm_pose[near]["upper_delta"])
    draw(f"{near}_forearm", arm_pose[near]["elbow"], arm_pose[near]["lower_delta"])
    draw("coat_near", hips, opposite * 0.048)
    if direction != "back":
        draw("head", head_pivot, torso_delta + stride * 0.008)

    if show_bones:
        overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        pen = ImageDraw.Draw(overlay)
        bone_color = (0, 220, 255, 215)
        joint_color = (255, 190, 63, 240)
        width = 3
        pen.line((hips, head_pivot), fill=bone_color, width=width)
        for side in ("left", "right"):
            pen.line(
                (
                    arm_pose[side]["shoulder"],
                    arm_pose[side]["elbow"],
                    arm_pose[side]["hand"],
                ),
                fill=bone_color,
                width=width,
            )
            pen.line(
                (
                    leg_pose[side]["hip"],
                    leg_pose[side]["knee"],
                    leg_pose[side]["foot"],
                ),
                fill=bone_color,
                width=width,
            )
        points = [hips, head_pivot]
        for side in ("left", "right"):
            points.extend(
                [
                    arm_pose[side]["shoulder"],
                    arm_pose[side]["elbow"],
                    arm_pose[side]["hand"],
                    leg_pose[side]["hip"],
                    leg_pose[side]["knee"],
                    leg_pose[side]["foot"],
                ]
            )
        for x, y in points:
            pen.ellipse((x - 4, y - 4, x + 4, y + 4), fill=joint_color)
        canvas.alpha_composite(overlay)
    return canvas


def make_sheet(
    root: Path,
    output: Path,
    show_bones: bool,
) -> None:
    panels = [render_pose(root, direction, None, show_bones) for direction in DIRECTIONS]
    margin = 14
    label_height = 26
    sheet = Image.new(
        "RGBA",
        (
            len(panels) * panels[0].width + margin * (len(panels) + 1),
            panels[0].height + margin * 2 + label_height,
        ),
        (7, 12, 23, 255),
    )
    draw = ImageDraw.Draw(sheet)
    left = margin
    for direction, panel in zip(DIRECTIONS, panels):
        draw.text((left + 6, margin + 5), direction, fill=(235, 242, 255, 255))
        sheet.alpha_composite(panel, (left, margin + label_height))
        left += panel.width + margin
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(output, quality=94)


def make_walk(root: Path, output: Path) -> None:
    rgb_frames = []
    for frame_index in range(16):
        phase = frame_index / 16.0
        panels = [render_pose(root, direction, phase) for direction in DIRECTIONS]
        margin = 10
        label_height = 22
        sheet = Image.new(
            "RGBA",
            (
                len(panels) * panels[0].width + margin * (len(panels) + 1),
                panels[0].height + margin * 2 + label_height,
            ),
            (7, 12, 23, 255),
        )
        draw = ImageDraw.Draw(sheet)
        left = margin
        for direction, panel in zip(DIRECTIONS, panels):
            draw.text((left + 5, margin + 3), direction, fill=(235, 242, 255, 255))
            sheet.alpha_composite(panel, (left, margin + label_height))
            left += panel.width + margin
        rgb_frames.append(
            sheet.resize(
                (round(sheet.width * 0.54), round(sheet.height * 0.54)),
                Image.Resampling.LANCZOS,
            ).convert("RGB")
        )
    palette = rgb_frames[0].convert(
        "P",
        palette=Image.Palette.ADAPTIVE,
        colors=112,
    )
    frames = [
        frame.quantize(palette=palette, dither=Image.Dither.NONE)
        for frame in rgb_frames
    ]
    output.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output,
        save_all=True,
        append_images=frames[1:],
        duration=80,
        loop=0,
        optimize=True,
        disposal=1,
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_skin", type=Path)
    parser.add_argument("armorer_skin", type=Path)
    parser.add_argument("output_root", type=Path)
    args = parser.parse_args()
    make_sheet(
        args.base_skin,
        args.output_root / "base_humanoid_four_directions.jpg",
        False,
    )
    make_sheet(
        args.base_skin,
        args.output_root / "base_humanoid_binding.jpg",
        True,
    )
    make_walk(
        args.base_skin,
        args.output_root / "base_humanoid_walk.gif",
    )
    make_sheet(
        args.armorer_skin,
        args.output_root / "base_armorer_four_directions.jpg",
        False,
    )
    make_walk(
        args.armorer_skin,
        args.output_root / "base_armorer_walk.gif",
    )


if __name__ == "__main__":
    main()
