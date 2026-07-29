#!/usr/bin/env python3
"""Build per-item melee weapon layers from the approved sword motion.

The body animation and its timing stay untouched. Each original equipment icon
is aligned to the sword's grip/tip axis on every frame, then clipped to the
existing weapon visibility envelope so body/weapon occlusion remains stable.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


SCRIPT_DIR = Path(__file__).resolve().parent
LOCAL_WORKSPACE = (SCRIPT_DIR / "templates").is_dir()
ROOT = SCRIPT_DIR if LOCAL_WORKSPACE else SCRIPT_DIR.parents[0]
TEMPLATE_DIR = ROOT / (
    "templates/assets/art/weapons/character_layers/standard_melee_sword"
    if LOCAL_WORKSPACE
    else "assets/art/weapons/character_layers/standard_melee_sword"
)
OUTPUT_ROOT = ROOT / (
    "generated/assets/art/weapons/character_layers"
    if LOCAL_WORKSPACE
    else "assets/art/weapons/character_layers"
)
ADVANCED_ATLAS = ROOT / (
    "source_assets/advanced.png"
    if LOCAL_WORKSPACE
    else "assets/art/weapons/advanced_weapons.png"
)
DIRECTOR_ATLAS = ROOT / (
    "source_assets/director_reaper_growth.png"
    if LOCAL_WORKSPACE
    else "assets/art/weapons/director_reaper_growth.png"
)
FRAME_SIZE = 128


@dataclass(frozen=True)
class WeaponSpec:
    item_id: str
    prefix: str
    atlas_index: int | None
    length_scale: float = 1.0
    width_scale: float = 1.0
    grip_fraction: float = 0.12
    visibility_radius: int = 3
    director_stage: int | None = None


WEAPONS = (
    WeaponSpec("echo_edge", "echo_edge", 0, 0.98, 1.05, 0.10, 5),
    WeaponSpec("insulated_crowbar", "insulated_crowbar", 1, 1.04, 1.0, 0.16, 3),
    WeaponSpec("volatile_edge", "volatile_edge", 4, 1.02, 1.08, 0.11, 5),
    WeaponSpec(
        "director_reaper",
        "director_reaper",
        None,
        1.22,
        1.0,
        0.15,
        5,
        0,
    ),
    WeaponSpec(
        "director_reaper_awakened",
        "director_reaper_awakened",
        None,
        1.22,
        1.0,
        0.15,
        5,
        3,
    ),
    WeaponSpec(
        "director_reaper_final",
        "director_reaper_final",
        None,
        1.22,
        1.0,
        0.15,
        5,
        5,
    ),
)


def _opaque_points(image: Image.Image) -> np.ndarray:
    rgba = np.asarray(image.convert("RGBA"))
    ys, xs = np.where(rgba[:, :, 3] > 20)
    if len(xs) < 2:
        raise RuntimeError("Weapon frame has no usable pixels")
    return np.column_stack((xs, ys)).astype(float)


def _source_basis(
    image: Image.Image,
    grip_fraction: float,
) -> tuple[np.ndarray, np.ndarray, float]:
    points = _opaque_points(image)
    center = points.mean(axis=0)
    values, vectors = np.linalg.eigh(np.cov((points - center).T))
    axis = vectors[:, int(np.argmax(values))]
    # Equipment atlas icons are authored handle-down. Orient the long axis
    # from the lower grip toward the upper weapon tip.
    if axis[1] > 0.0:
        axis = -axis
    projections = (points - center) @ axis
    low = float(projections.min())
    high = float(projections.max())
    grip = center + axis * (low + (high - low) * grip_fraction)
    return grip, axis, max(1.0, high - low)


def _target_basis(reference: Image.Image) -> tuple[np.ndarray, np.ndarray, float]:
    rgba = np.asarray(reference.convert("RGBA"))
    points = _opaque_points(reference)
    center = points.mean(axis=0)
    values, vectors = np.linalg.eigh(np.cov((points - center).T))
    axis = vectors[:, int(np.argmax(values))]

    red = rgba[:, :, 0]
    green = rgba[:, :, 1]
    blue = rgba[:, :, 2]
    alpha = rgba[:, :, 3]
    hilt = (alpha > 20) & (red > blue * 1.18) & (red > green * 1.04)
    hilt_y, hilt_x = np.where(hilt)
    if len(hilt_x):
        hilt_center = np.array([hilt_x.mean(), hilt_y.mean()])
        if np.dot(hilt_center - center, axis) > 0:
            axis = -axis
    else:
        # On very thin side frames, retain the same general grip/tip ordering.
        if axis[1] > 0.0:
            axis = -axis

    projections = (points - center) @ axis
    low = float(projections.min())
    high = float(projections.max())
    grip = center + axis * low
    return grip, axis, max(8.0, high - low)


def _affine_weapon(
    icon: Image.Image,
    reference: Image.Image,
    spec: WeaponSpec,
) -> Image.Image:
    source_grip, source_axis, source_length = _source_basis(
        icon,
        spec.grip_fraction,
    )
    target_grip, target_axis, target_length = _target_basis(reference)
    source_normal = np.array([-source_axis[1], source_axis[0]])
    target_normal = np.array([-target_axis[1], target_axis[0]])

    along_scale = target_length * spec.length_scale / source_length
    across_scale = along_scale * spec.width_scale
    source_basis = np.column_stack((source_axis, source_normal))
    target_basis = np.column_stack(
        (target_axis * along_scale, target_normal * across_scale)
    )
    forward = target_basis @ source_basis.T
    translation = target_grip - forward @ source_grip
    inverse = np.linalg.inv(forward)
    inverse_translation = -inverse @ translation

    transformed = icon.transform(
        (FRAME_SIZE, FRAME_SIZE),
        Image.Transform.AFFINE,
        (
            float(inverse[0, 0]),
            float(inverse[0, 1]),
            float(inverse_translation[0]),
            float(inverse[1, 0]),
            float(inverse[1, 1]),
            float(inverse_translation[1]),
        ),
        resample=Image.Resampling.BICUBIC,
    )

    radius = spec.visibility_radius
    if radius % 2 == 0:
        radius += 1
    visibility = reference.getchannel("A").filter(ImageFilter.MaxFilter(radius))
    transformed.putalpha(
        Image.fromarray(
            np.minimum(
                np.asarray(transformed.getchannel("A"), dtype=np.uint8),
                np.asarray(visibility, dtype=np.uint8),
            ),
            mode="L",
        )
    )
    return transformed


def _director_reaper_icon() -> Image.Image:
    """Create the base relic silhouette described by the original growth art."""
    scale = 4
    canvas = Image.new("RGBA", (64 * scale, 64 * scale))
    draw = ImageDraw.Draw(canvas)

    def point(x: float, y: float) -> tuple[int, int]:
        return round(x * scale), round(y * scale)

    # Dark wrapped shaft with a cold metal edge.
    draw.line(
        [point(23, 58), point(35, 15)],
        fill=(35, 24, 29, 255),
        width=7 * scale,
    )
    draw.line(
        [point(23, 58), point(35, 15)],
        fill=(104, 77, 75, 255),
        width=4 * scale,
    )
    for offset in range(0, 15, 4):
        draw.line(
            [point(20 + offset * 0.24, 56 - offset), point(27 + offset * 0.24, 58 - offset)],
            fill=(191, 116, 95, 255),
            width=2 * scale,
        )

    # Surgical crescent and the stitched inner spine are the relic's identity.
    blade = [
        point(34, 16),
        point(43, 7),
        point(58, 7),
        point(53, 12),
        point(45, 15),
        point(39, 23),
        point(32, 25),
    ]
    draw.polygon(blade, fill=(42, 27, 31, 255))
    draw.line(
        [point(35, 17), point(45, 10), point(57, 8)],
        fill=(217, 151, 132, 255),
        width=3 * scale,
    )
    draw.line(
        [point(35, 20), point(43, 15), point(51, 13)],
        fill=(112, 219, 222, 230),
        width=1 * scale,
    )
    for x, y in ((39, 17), (44, 14), (49, 12)):
        draw.ellipse(
            [point(x - 1.2, y - 1.2), point(x + 1.2, y + 1.2)],
            fill=(238, 180, 147, 255),
        )
    return canvas.resize((64, 64), Image.Resampling.LANCZOS)


def _load_icon(spec: WeaponSpec) -> Image.Image:
    if spec.atlas_index is None:
        if DIRECTOR_ATLAS.is_file():
            stage = 0 if spec.director_stage is None else spec.director_stage
            left = stage * 64
            return Image.open(DIRECTOR_ATLAS).convert("RGBA").crop(
                (left, 0, left + 64, 64)
            )
        return _director_reaper_icon()
    atlas = Image.open(ADVANCED_ATLAS).convert("RGBA")
    left = spec.atlas_index * 64
    return atlas.crop((left, 0, left + 64, 64))


def build() -> None:
    for spec in WEAPONS:
        icon = _load_icon(spec)
        if icon.getchannel("A").getbbox() is None:
            raise RuntimeError(f"Source icon is empty: {spec.item_id}")
        output_dir = OUTPUT_ROOT / spec.item_id
        output_dir.mkdir(parents=True, exist_ok=True)
        for source_path in sorted(TEMPLATE_DIR.glob("standard_sword_*.png")):
            source = Image.open(source_path).convert("RGBA")
            frame_count = source.width // FRAME_SIZE
            output = Image.new("RGBA", source.size)
            for frame_index in range(frame_count):
                frame = source.crop(
                    (
                        frame_index * FRAME_SIZE,
                        0,
                        (frame_index + 1) * FRAME_SIZE,
                        FRAME_SIZE,
                    )
                )
                output.alpha_composite(
                    _affine_weapon(icon, frame, spec),
                    (frame_index * FRAME_SIZE, 0),
                )
            target_name = source_path.name.replace(
                "standard_sword_",
                f"{spec.prefix}_",
            )
            output.save(output_dir / target_name, "PNG", optimize=True)


if __name__ == "__main__":
    build()
