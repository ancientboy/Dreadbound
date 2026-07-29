#!/usr/bin/env python3
"""Derive a dedicated service-crowbar layer from the approved melee motion.

The checked-in standard sword layer is the pose/occlusion reference.  This
script replaces its silhouette with the service crowbar described by cell zero
of basic_weapons.png while preserving the exact frame timing, hand alignment,
direction, and body holdout authored by the Blender render.
"""

from __future__ import annotations

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


SCRIPT_DIR = Path(__file__).resolve().parent
LOCAL_WORKSPACE = (SCRIPT_DIR / "templates").is_dir()
ROOT = SCRIPT_DIR if LOCAL_WORKSPACE else SCRIPT_DIR.parents[0]
SOURCE_DIR = (
    ROOT
    / (
        "templates/assets/art/weapons/character_layers/standard_melee_sword"
        if LOCAL_WORKSPACE
        else "assets/art/weapons/character_layers/standard_melee_sword"
    )
)
OUTPUT_DIR = (
    ROOT
    / (
        "generated/assets/art/weapons/character_layers/service_crowbar"
        if LOCAL_WORKSPACE
        else "assets/art/weapons/character_layers/service_crowbar"
    )
)
BASIC_WEAPONS = (
    ROOT / ("templates/assets/art/weapons/basic_weapons.png" if LOCAL_WORKSPACE else "assets/art/weapons/basic_weapons.png")
)
FRAME_SIZE = 128
SUPERSAMPLE = 4


def _principal_axis(rgba: np.ndarray) -> tuple[np.ndarray, np.ndarray, float, float]:
    alpha = rgba[:, :, 3]
    ys, xs = np.where(alpha > 20)
    points = np.column_stack((xs, ys)).astype(float)
    center = points.mean(axis=0)
    covariance = np.cov((points - center).T)
    values, vectors = np.linalg.eigh(covariance)
    axis = vectors[:, int(np.argmax(values))]

    # Brown/orange pixels belong to the hilt. The opposite end is the tool tip.
    red = rgba[:, :, 0]
    green = rgba[:, :, 1]
    blue = rgba[:, :, 2]
    hilt = (alpha > 20) & (red > blue * 1.18) & (red > green * 1.04)
    hilt_y, hilt_x = np.where(hilt)
    if len(hilt_x):
        hilt_center = np.array([hilt_x.mean(), hilt_y.mean()])
        if np.dot(hilt_center - center, axis) > 0:
            axis = -axis

    projection = (points - center) @ axis
    return center, axis, float(projection.min()), float(projection.max())


def _bezier(
    start: np.ndarray,
    control: np.ndarray,
    end: np.ndarray,
    samples: int = 12,
) -> list[tuple[int, int]]:
    result = []
    for index in range(samples + 1):
        ratio = index / samples
        point = (
            (1.0 - ratio) ** 2 * start
            + 2.0 * (1.0 - ratio) * ratio * control
            + ratio**2 * end
        )
        result.append(tuple(np.round(point * SUPERSAMPLE).astype(int)))
    return result


def _line(
    draw: ImageDraw.ImageDraw,
    points: list[np.ndarray] | tuple[np.ndarray, np.ndarray],
    fill: tuple[int, int, int, int],
    width: float,
) -> None:
    draw.line(
        [tuple(np.round(point * SUPERSAMPLE).astype(int)) for point in points],
        fill=fill,
        width=max(1, round(width * SUPERSAMPLE)),
        joint="curve",
    )


def _render_crowbar(reference: Image.Image, direction: str) -> Image.Image:
    rgba = np.asarray(reference.convert("RGBA"))
    center, axis, low, high = _principal_axis(rgba)
    normal = np.array([-axis[1], axis[0]])
    # Low projection is the sword hilt; high projection is its tip.
    grip = center + axis * low
    tip = center + axis * high
    length = max(8.0, float(np.linalg.norm(tip - grip)))

    canvas = Image.new(
        "RGBA",
        (FRAME_SIZE * SUPERSAMPLE, FRAME_SIZE * SUPERSAMPLE),
    )
    draw = ImageDraw.Draw(canvas)

    # A crowbar is held around the wrapped lower third, not by the flat pry
    # tip. Keep a short tail behind the hand while the hook remains outward.
    pry_tip = grip - axis * length * 0.14
    hook_tip = grip + axis * length * 0.86
    shaft_start = pry_tip + axis * min(2.0, length * 0.06)
    hook_base = hook_tip - axis * min(4.0, length * 0.12)
    # Keep the hook's handedness stable across the four orthographic views.
    hook_sign = -1.0 if direction in {"back", "right"} else 1.0
    hook_normal = normal * hook_sign
    hook_control = hook_tip + axis * 1.5 + hook_normal * min(6.0, length * 0.22)
    hook_end = hook_tip - axis * min(5.5, length * 0.19) + hook_normal * min(
        7.5,
        length * 0.27,
    )

    # Dark outline, oxidized iron body, then a cool edge highlight.
    _line(draw, (shaft_start, hook_base), (22, 22, 20, 255), 6.0)
    _line(draw, (shaft_start, hook_base), (78, 69, 57, 255), 3.7)
    hook_points = _bezier(hook_base, hook_control, hook_end)
    draw.line(
        hook_points,
        fill=(20, 20, 18, 255),
        width=round(6.0 * SUPERSAMPLE),
        joint="curve",
    )
    draw.line(
        hook_points,
        fill=(66, 59, 50, 255),
        width=round(3.7 * SUPERSAMPLE),
        joint="curve",
    )
    _line(
        draw,
        (shaft_start - normal * 0.7, hook_base - normal * 0.7),
        (142, 138, 124, 210),
        0.9,
    )

    # The source crowbar has a worn brass grip wrap.
    wrap_start = grip - axis * length * 0.08
    for band in range(4):
        along = wrap_start + axis * band * 2.2
        _line(
            draw,
            (along - normal * 2.8, along + normal * 2.8),
            (126, 81, 40, 255) if band % 2 == 0 else (88, 55, 29, 255),
            1.5,
        )

    # Flat pry end at the handle, matching the pale lower tip in the source art.
    pry_center = pry_tip
    _line(
        draw,
        (
            pry_center - normal * 3.5 - axis * 1.5,
            pry_center + normal * 3.5 + axis * 1.5,
        ),
        (150, 142, 122, 255),
        2.2,
    )

    canvas = canvas.resize((FRAME_SIZE, FRAME_SIZE), Image.Resampling.LANCZOS)

    # The sword layer already contains the Blender mannequin holdout. Expanding
    # that visibility envelope lets the curved hook differ from the sword tip
    # without bringing weapon pixels back through the character.
    reference_alpha = reference.getchannel("A")
    # Only a tiny antialiasing allowance is needed. The previous 15-pixel
    # expansion exposed weapon pixels that the Blender body had occluded.
    visibility = reference_alpha.filter(ImageFilter.MaxFilter(3))
    crowbar_alpha = canvas.getchannel("A")
    masked_alpha = Image.fromarray(
        np.minimum(
            np.asarray(crowbar_alpha, dtype=np.uint8),
            np.asarray(visibility, dtype=np.uint8),
        ),
        mode="L",
    )
    canvas.putalpha(masked_alpha)
    return canvas


def build() -> None:
    reference = Image.open(BASIC_WEAPONS).convert("RGBA").crop((0, 0, 32, 32))
    if reference.getchannel("A").getbbox() is None:
        raise RuntimeError("The service crowbar reference cell is empty")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for source_path in sorted(SOURCE_DIR.glob("standard_sword_*.png")):
        source = Image.open(source_path).convert("RGBA")
        frame_count = source.width // FRAME_SIZE
        direction = source_path.stem.rsplit("_", 1)[-1]
        output = Image.new("RGBA", source.size)
        for frame_index in range(frame_count):
            box = (
                frame_index * FRAME_SIZE,
                0,
                (frame_index + 1) * FRAME_SIZE,
                FRAME_SIZE,
            )
            frame = source.crop(box)
            output.alpha_composite(
                _render_crowbar(frame, direction),
                (frame_index * FRAME_SIZE, 0),
            )
        target_name = source_path.name.replace(
            "standard_sword_",
            "service_crowbar_",
        )
        output.save(OUTPUT_DIR / target_name, "PNG", optimize=True)


if __name__ == "__main__":
    build()
