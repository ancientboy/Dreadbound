#!/usr/bin/env python3
"""Build aligned four-direction skins for the shared humanoid skeleton.

The input is a transparent four-panel turnaround ordered front, left, right,
back. Every source is normalized onto the same 256x420 canvas before fixed
anatomical masks are applied. This keeps profession art subordinate to the
skeleton instead of deriving a new skeleton from every illustration.
"""

from __future__ import annotations

import argparse
from collections import deque
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


FRAME_SIZE = (256, 420)
BODY_TOP = 10
BODY_BOTTOM = 410
DIRECTIONS = ("front", "left", "right", "back")
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
    "coat_far",
    "coat_near",
)
PART_JOINTS = {
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
    "coat_far": "hips",
    "coat_near": "hips",
}


def front_joints() -> dict[str, list[float]]:
    return {
        "root": [128.0, 420.0],
        "hips": [128.0, 230.0],
        "torso": [128.0, 230.0],
        "head": [128.0, 82.0],
        # Anatomical left is on the viewer's right in the front view.
        "left_shoulder": [174.0, 105.0],
        "left_elbow": [188.0, 171.0],
        "left_hand": [194.0, 238.0],
        "right_shoulder": [82.0, 105.0],
        "right_elbow": [68.0, 171.0],
        "right_hand": [62.0, 238.0],
        "left_hip": [145.0, 230.0],
        "left_knee": [149.0, 322.0],
        "left_foot": [149.0, 410.0],
        "right_hip": [111.0, 230.0],
        "right_knee": [107.0, 322.0],
        "right_foot": [107.0, 410.0],
        "coat_left": [145.0, 224.0],
        "coat_right": [111.0, 224.0],
    }


def back_joints() -> dict[str, list[float]]:
    joints = front_joints()
    for left_name, right_name in (
        ("left_shoulder", "right_shoulder"),
        ("left_elbow", "right_elbow"),
        ("left_hand", "right_hand"),
        ("left_hip", "right_hip"),
        ("left_knee", "right_knee"),
        ("left_foot", "right_foot"),
        ("coat_left", "coat_right"),
    ):
        joints[left_name], joints[right_name] = joints[right_name], joints[left_name]
    return joints


def left_joints() -> dict[str, list[float]]:
    return {
        "root": [128.0, 420.0],
        "hips": [128.0, 230.0],
        "torso": [128.0, 230.0],
        "head": [128.0, 82.0],
        # The anatomical left side is nearest when the character faces left.
        "left_shoulder": [126.0, 105.0],
        "left_elbow": [137.0, 171.0],
        "left_hand": [141.0, 238.0],
        "right_shoulder": [132.0, 107.0],
        "right_elbow": [142.0, 173.0],
        "right_hand": [146.0, 240.0],
        "left_hip": [126.0, 230.0],
        "left_knee": [133.0, 322.0],
        "left_foot": [128.0, 410.0],
        "right_hip": [132.0, 232.0],
        "right_knee": [137.0, 324.0],
        "right_foot": [132.0, 410.0],
        "coat_left": [125.0, 224.0],
        "coat_right": [133.0, 226.0],
    }


def right_joints() -> dict[str, list[float]]:
    source = left_joints()
    result: dict[str, list[float]] = {}
    swaps = {
        "left_shoulder": "right_shoulder",
        "left_elbow": "right_elbow",
        "left_hand": "right_hand",
        "left_hip": "right_hip",
        "left_knee": "right_knee",
        "left_foot": "right_foot",
        "coat_left": "coat_right",
        "right_shoulder": "left_shoulder",
        "right_elbow": "left_elbow",
        "right_hand": "left_hand",
        "right_hip": "left_hip",
        "right_knee": "left_knee",
        "right_foot": "left_foot",
        "coat_right": "coat_left",
    }
    for name, value in source.items():
        target_name = swaps.get(name, name)
        result[target_name] = [FRAME_SIZE[0] - float(value[0]), float(value[1])]
    return result


STANDARD_JOINTS = {
    "front": front_joints(),
    "left": left_joints(),
    "right": right_joints(),
    "back": back_joints(),
}


def panel_images(sheet: Image.Image) -> dict[str, Image.Image]:
    sheet = sheet.convert("RGBA")
    panels: dict[str, Image.Image] = {}
    for index, direction in enumerate(DIRECTIONS):
        left = round(index * sheet.width / 4)
        right = round((index + 1) * sheet.width / 4)
        panel = keep_largest_component(
            sheet.crop((left, 0, right, sheet.height))
        )
        alpha = panel.getchannel("A")
        bounds = alpha.getbbox()
        if bounds is None:
            raise ValueError(f"{direction} panel has no visible pixels")
        figure = panel.crop(bounds)
        target_height = BODY_BOTTOM - BODY_TOP
        scale = target_height / figure.height
        target_width = max(1, round(figure.width * scale))
        figure = figure.resize(
            (target_width, target_height),
            Image.Resampling.LANCZOS,
        )
        normalized = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
        normalized.alpha_composite(
            figure,
            ((FRAME_SIZE[0] - target_width) // 2, BODY_TOP),
        )
        panels[direction] = normalized
    return panels


def keep_largest_component(panel: Image.Image) -> Image.Image:
    """Discard neighboring-panel fragments and guide-line contamination."""
    alpha = panel.getchannel("A")
    width, height = alpha.size
    # Use an opened silhouette for component discovery so one-pixel crop
    # guides touching the hood or boots cannot join the character component.
    discovery = alpha.filter(ImageFilter.MinFilter(3)).filter(
        ImageFilter.MaxFilter(3)
    )
    opaque = bytes(1 if value >= 48 else 0 for value in discovery.tobytes())
    visited = bytearray(width * height)
    largest: list[int] = []
    for start, value in enumerate(opaque):
        if not value or visited[start]:
            continue
        component: list[int] = []
        queue = deque([start])
        visited[start] = 1
        while queue:
            current = queue.popleft()
            component.append(current)
            x = current % width
            y = current // width
            for neighbor in (
                current - 1 if x > 0 else -1,
                current + 1 if x + 1 < width else -1,
                current - width if y > 0 else -1,
                current + width if y + 1 < height else -1,
            ):
                if (
                    neighbor >= 0
                    and opaque[neighbor]
                    and not visited[neighbor]
                ):
                    visited[neighbor] = 1
                    queue.append(neighbor)
        if len(component) > len(largest):
            largest = component
    if not largest:
        return panel
    keep = bytearray(width * height)
    for index in largest:
        keep[index] = 255
    keep_image = Image.frombytes("L", (width, height), bytes(keep)).filter(
        ImageFilter.MaxFilter(7)
    )
    cleaned = panel.copy()
    cleaned.putalpha(minimum_mask(alpha, keep_image))
    return cleaned


def capsule(
    size: tuple[int, int],
    start: tuple[float, float],
    end: tuple[float, float],
    width: float,
) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    radius = width * 0.5
    draw.line((start, end), fill=255, width=max(1, round(width)))
    for x, y in (start, end):
        draw.ellipse(
            (x - radius, y - radius, x + radius, y + radius),
            fill=255,
        )
    return mask.filter(ImageFilter.GaussianBlur(0.45))


def polygon_mask(
    size: tuple[int, int],
    points: list[tuple[float, float]],
) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask.filter(ImageFilter.GaussianBlur(0.45))


def minimum_mask(left: Image.Image, right: Image.Image) -> Image.Image:
    return Image.frombytes(
        "L",
        left.size,
        bytes(min(a, b) for a, b in zip(left.tobytes(), right.tobytes())),
    )


def sample_color(
    image: Image.Image,
    point: tuple[float, float],
    radius: int = 12,
) -> tuple[int, int, int, int]:
    x0 = max(0, round(point[0] - radius))
    y0 = max(0, round(point[1] - radius))
    x1 = min(image.width, round(point[0] + radius + 1))
    y1 = min(image.height, round(point[1] + radius + 1))
    pixels = [
        pixel
        for pixel in image.crop((x0, y0, x1, y1)).get_flattened_data()
        if pixel[3] >= 180
    ]
    if not pixels:
        return (54, 52, 47, 255)
    pixels.sort(key=lambda value: sum(value[:3]))
    return (*pixels[len(pixels) // 2][:3], 255)


def part_mask(
    direction: str,
    part: str,
    joints: dict[str, list[float]],
    armored: bool,
) -> Image.Image:
    side = direction in ("left", "right")
    arm_width = 46.0 if not armored else 64.0
    leg_width = 56.0 if not armored else 72.0
    if side:
        arm_width *= 0.78
        leg_width *= 0.72
    if part == "head":
        half_width = 48.0 if not side else 34.0
        return polygon_mask(
            FRAME_SIZE,
            [
                (128.0 - half_width, 4.0),
                (128.0 + half_width, 4.0),
                (128.0 + half_width, 94.0),
                (128.0 - half_width, 94.0),
            ],
        )
    if part == "torso":
        half_shoulder = (61.0 if not side else 34.0) + (12.0 if armored else 0.0)
        half_hip = (33.0 if not side else 27.0) + (8.0 if armored else 0.0)
        return polygon_mask(
            FRAME_SIZE,
            [
                (128.0 - half_shoulder, 78.0),
                (128.0 + half_shoulder, 78.0),
                (128.0 + half_hip, 244.0),
                (128.0 - half_hip, 244.0),
            ],
        )
    if part.endswith("upper_arm"):
        prefix = part.removesuffix("_upper_arm")
        return capsule(
            FRAME_SIZE,
            tuple(joints[f"{prefix}_shoulder"]),
            tuple(joints[f"{prefix}_elbow"]),
            arm_width,
        )
    if part.endswith("forearm"):
        prefix = part.removesuffix("_forearm")
        return capsule(
            FRAME_SIZE,
            tuple(joints[f"{prefix}_elbow"]),
            tuple(joints[f"{prefix}_hand"]),
            arm_width * 0.88,
        )
    if part.endswith("thigh"):
        prefix = part.removesuffix("_thigh")
        return capsule(
            FRAME_SIZE,
            tuple(joints[f"{prefix}_hip"]),
            tuple(joints[f"{prefix}_knee"]),
            leg_width,
        )
    if part.endswith("shin"):
        prefix = part.removesuffix("_shin")
        return capsule(
            FRAME_SIZE,
            tuple(joints[f"{prefix}_knee"]),
            tuple(joints[f"{prefix}_foot"]),
            leg_width * 0.82,
        )
    if part == "coat_far":
        if not armored:
            return Image.new("L", FRAME_SIZE, 0)
        return polygon_mask(
            FRAME_SIZE,
            [(76, 195), (128, 195), (128, 282), (74, 282)],
        )
    if part == "coat_near":
        if not armored:
            return Image.new("L", FRAME_SIZE, 0)
        return polygon_mask(
            FRAME_SIZE,
            [(128, 195), (180, 195), (182, 282), (128, 282)],
        )
    raise KeyError(part)


def crop_part(
    source: Image.Image,
    mask: Image.Image,
    pivot: tuple[float, float],
    add_cap: bool,
    darken: bool,
) -> tuple[Image.Image, tuple[float, float]]:
    visible_mask = minimum_mask(mask, source.getchannel("A"))
    bounds = visible_mask.getbbox()
    if bounds is None:
        empty = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
        return empty, (8.0, 8.0)
    padding = 14
    x0 = max(0, bounds[0] - padding)
    y0 = max(0, bounds[1] - padding)
    x1 = min(source.width, bounds[2] + padding)
    y1 = min(source.height, bounds[3] + padding)
    output = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    local_pivot = (pivot[0] - x0, pivot[1] - y0)
    if add_cap:
        radius = 12
        color = sample_color(source, pivot)
        ImageDraw.Draw(output).ellipse(
            (
                local_pivot[0] - radius,
                local_pivot[1] - radius,
                local_pivot[0] + radius,
                local_pivot[1] + radius,
            ),
            fill=color,
        )
    clipped = source.copy()
    clipped.putalpha(visible_mask)
    output.alpha_composite(clipped.crop((x0, y0, x1, y1)))
    if darken:
        alpha = output.getchannel("A")
        output = ImageEnhance.Brightness(output).enhance(0.76)
        output.putalpha(alpha)
    return output, local_pivot


def vector(start: list[float], end: list[float]) -> list[float]:
    return [float(end[0] - start[0]), float(end[1] - start[1])]


def build_skin(
    source_path: Path,
    output_root: Path,
    source_id: str,
    armored: bool,
) -> None:
    panels = panel_images(Image.open(source_path))
    output_root.mkdir(parents=True, exist_ok=True)
    for direction in DIRECTIONS:
        source = panels[direction]
        joints = STANDARD_JOINTS[direction]
        direction_root = output_root / direction
        direction_root.mkdir(parents=True, exist_ok=True)
        manifest = {
            "schema_version": 3,
            "source": "standard_humanoid_skin",
            "source_id": source_id,
            "skeleton_id": "humanoid_v1",
            "frame_size": list(FRAME_SIZE),
            "baseline_y": 410.0,
            "center_x": 128.0,
            "joints": joints,
            "rest_vectors": {
                "left_upper_arm": vector(joints["left_shoulder"], joints["left_elbow"]),
                "left_forearm": vector(joints["left_elbow"], joints["left_hand"]),
                "right_upper_arm": vector(joints["right_shoulder"], joints["right_elbow"]),
                "right_forearm": vector(joints["right_elbow"], joints["right_hand"]),
                "left_thigh": vector(joints["left_hip"], joints["left_knee"]),
                "left_shin": vector(joints["left_knee"], joints["left_foot"]),
                "right_thigh": vector(joints["right_hip"], joints["right_knee"]),
                "right_shin": vector(joints["right_knee"], joints["right_foot"]),
            },
            "parts": {},
        }
        near_side = "left" if direction == "left" else "right" if direction == "right" else ""
        for part in PARTS:
            mask = part_mask(direction, part, joints, armored)
            pivot_name = PART_JOINTS[part]
            pivot = tuple(joints[pivot_name])
            side_name = part.split("_", 1)[0] if part.startswith(("left_", "right_")) else ""
            darken = bool(near_side and side_name and side_name != near_side)
            image, local_pivot = crop_part(
                source,
                mask,
                pivot,
                add_cap=part not in ("torso", "coat_far", "coat_near"),
                darken=darken,
            )
            path = direction_root / f"{part}.webp"
            image.save(path, "WEBP", lossless=True, method=6)
            manifest["parts"][part] = {
                "file": path.name,
                "size": [image.width, image.height],
                "pivot": [local_pivot[0], local_pivot[1]],
            }
        (direction_root / "rig.json").write_text(
            json.dumps(manifest, indent=2) + "\n",
            encoding="utf-8",
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--source-id", required=True)
    parser.add_argument("--armored", action="store_true")
    args = parser.parse_args()
    build_skin(args.source, args.output, args.source_id, args.armored)


if __name__ == "__main__":
    main()
