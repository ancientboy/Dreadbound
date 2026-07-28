#!/usr/bin/env python3
"""Render base_humanoid_v2 joint tracks for deterministic visual QA."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw


DIRECTIONS = ("front", "left", "back", "right")
PARTS = (
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
)
SEGMENTS = (
    ("left_upper_arm", "left_shoulder", "left_elbow"),
    ("left_forearm", "left_elbow", "left_hand"),
    ("right_upper_arm", "right_shoulder", "right_elbow"),
    ("right_forearm", "right_elbow", "right_hand"),
    ("left_thigh", "left_hip", "left_knee"),
    ("left_shin", "left_knee", "left_foot"),
    ("right_thigh", "right_hip", "right_knee"),
    ("right_shin", "right_knee", "right_foot"),
)


def point(value) -> tuple[float, float]:
    return (float(value[0]), float(value[1]))


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def length(value):
    return math.hypot(value[0], value[1])


def angle(value):
    return math.atan2(value[1], value[0])


def rotate(value, radians):
    cosine = math.cos(radians)
    sine = math.sin(radians)
    return (
        value[0] * cosine - value[1] * sine,
        value[0] * sine + value[1] * cosine,
    )


def cross(a, b):
    return a[0] * b[1] - a[1] * b[0]


def solve_elbow(root, target, upper_length, lower_length, bend_sign):
    delta = sub(target, root)
    distance = min(
        max(length(delta), abs(upper_length - lower_length) + 0.001),
        upper_length + lower_length - 0.001,
    )
    target_angle = angle(delta)
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
    upper_angle = target_angle + math.copysign(math.acos(cosine), bend_sign)
    return add(
        root,
        (
            math.cos(upper_angle) * upper_length,
            math.sin(upper_angle) * upper_length,
        ),
    )


def composite_part(canvas, sprite, pivot, world_pivot, delta_angle):
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


def load_skin(root, direction):
    folder = root / direction
    manifest = json.loads((folder / "rig.json").read_text(encoding="utf-8"))
    sprites = {
        name: Image.open(folder / spec["file"]).convert("RGBA")
        for name, spec in manifest["parts"].items()
        if name in PARTS
    }
    return manifest, sprites


def denormalize(track, manifest):
    baseline = float(manifest["baseline_y"])
    center = float(manifest["center_x"])
    height = baseline - float(manifest["joints"]["head"][1])
    return {
        name: (center + value[0] * height, baseline + value[1] * height)
        for name, value in track.items()
    }


def retarget(track, manifest):
    rest = {name: point(value) for name, value in manifest["joints"].items()}
    source = denormalize(track, manifest)
    result = dict(rest)
    result["hips"] = source["hips"]
    rest_axis = sub(rest["head"], rest["hips"])
    source_axis = sub(source["head"], source["hips"])
    torso_delta = angle(source_axis) - angle(rest_axis)
    torso_delta = max(math.radians(-38), min(math.radians(38), torso_delta))
    for name in (
        "torso",
        "head",
        "left_shoulder",
        "right_shoulder",
        "left_hip",
        "right_hip",
    ):
        result[name] = add(
            result["hips"],
            rotate(sub(rest[name], rest["hips"]), torso_delta),
        )
    for side in ("left", "right"):
        for root_name, middle_name, end_name in (
            (
                f"{side}_shoulder",
                f"{side}_elbow",
                f"{side}_hand",
            ),
            (f"{side}_hip", f"{side}_knee", f"{side}_foot"),
        ):
            root = result[root_name]
            target = source[end_name]
            upper_length = length(sub(rest[middle_name], rest[root_name]))
            lower_length = length(sub(rest[end_name], rest[middle_name]))
            source_upper = sub(source[middle_name], root)
            source_target = sub(target, root)
            bend = cross(source_target, source_upper)
            if abs(bend) < 0.0001:
                rest_upper = sub(rest[middle_name], rest[root_name])
                rest_target = sub(rest[end_name], rest[root_name])
                bend = cross(rest_target, rest_upper)
            result[middle_name] = solve_elbow(
                root,
                target,
                upper_length,
                lower_length,
                1.0 if bend >= 0.0 else -1.0,
            )
            result[end_name] = target
    return result


def render_frame(skin_root, direction, track, show_bones=False):
    manifest, sprites = load_skin(skin_root, direction)
    rest = {name: point(value) for name, value in manifest["joints"].items()}
    pose = retarget(track, manifest)
    canvas = Image.new("RGBA", tuple(manifest["frame_size"]), (0, 0, 0, 0))
    part_specs = manifest["parts"]

    def pivot(name):
        return point(part_specs[name]["pivot"])

    segment_pose = {}
    for part_name, root_name, end_name in SEGMENTS:
        rest_vector = sub(rest[end_name], rest[root_name])
        pose_vector = sub(pose[end_name], pose[root_name])
        segment_pose[part_name] = (
            pose[root_name],
            angle(pose_vector) - angle(rest_vector),
        )
    rest_axis = sub(rest["head"], rest["hips"])
    pose_axis = sub(pose["head"], pose["hips"])
    torso_delta = angle(pose_axis) - angle(rest_axis)
    head_pivot = pose["head"]
    hips = pose["hips"]
    near = "left" if direction != "right" else "right"
    far = "right" if near == "left" else "left"

    def draw_segment(name):
        world, delta = segment_pose[name]
        composite_part(canvas, sprites[name], pivot(name), world, delta)

    for name in (f"{far}_thigh", f"{far}_shin", f"{far}_upper_arm", f"{far}_forearm"):
        draw_segment(name)
    composite_part(canvas, sprites["torso"], pivot("torso"), hips, torso_delta)
    if direction == "back":
        composite_part(canvas, sprites["head"], pivot("head"), head_pivot, torso_delta)
    for name in (f"{near}_thigh", f"{near}_shin", f"{near}_upper_arm", f"{near}_forearm"):
        draw_segment(name)
    if direction != "back":
        composite_part(canvas, sprites["head"], pivot("head"), head_pivot, torso_delta)

    if show_bones:
        pen = ImageDraw.Draw(canvas)
        for side in ("left", "right"):
            pen.line(
                (
                    pose[f"{side}_shoulder"],
                    pose[f"{side}_elbow"],
                    pose[f"{side}_hand"],
                ),
                fill=(0, 220, 255, 220),
                width=3,
            )
            pen.line(
                (
                    pose[f"{side}_hip"],
                    pose[f"{side}_knee"],
                    pose[f"{side}_foot"],
                ),
                fill=(0, 220, 255, 220),
                width=3,
            )
    return canvas


def make_overview(tracks, skin_root, action_names, output):
    cell_size = (192, 315)
    label_height = 30
    margin = 8
    width = margin * 5 + cell_size[0] * 4
    height = margin * (len(action_names) + 1) + (cell_size[1] + label_height) * len(action_names)
    sheet = Image.new("RGB", (width, height), (7, 12, 23))
    pen = ImageDraw.Draw(sheet)
    for row, action_name in enumerate(action_names):
        action = tracks["actions"][action_name]
        top = margin + row * (cell_size[1] + label_height + margin)
        pen.text(
            (margin + 4, top + 7),
            f"{action_name} · {action['source']}:{action['source_action']}",
            fill=(235, 242, 255),
        )
        for column, direction in enumerate(DIRECTIONS):
            frames = action["frames"][direction]
            frame = render_frame(
                skin_root,
                direction,
                frames[len(frames) // 2],
                show_bones=True,
            )
            frame.thumbnail(cell_size, Image.Resampling.LANCZOS)
            left = margin + column * (cell_size[0] + margin)
            panel = Image.new("RGBA", cell_size, (14, 21, 34, 255))
            panel.alpha_composite(
                frame,
                ((cell_size[0] - frame.width) // 2, cell_size[1] - frame.height),
            )
            sheet.paste(panel.convert("RGB"), (left, top + label_height))
            pen.text((left + 5, top + label_height + 5), direction, fill=(255, 190, 63))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=92)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tracks", required=True, type=Path)
    parser.add_argument("--skin-root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--actions", nargs="+", required=True)
    args = parser.parse_args()
    tracks = json.loads(args.tracks.read_text(encoding="utf-8"))
    missing = [name for name in args.actions if name not in tracks["actions"]]
    if missing:
        raise ValueError(f"Unknown actions: {missing}")
    make_overview(tracks, args.skin_root, args.actions, args.output)
    print(
        json.dumps(
            {
                "status": "ok",
                "actions": len(args.actions),
                "output": str(args.output),
            }
        )
    )


if __name__ == "__main__":
    main()
