#!/usr/bin/env python3
"""Build per-item firearm layers from the approved pistol motion.

The body animation and timing stay untouched. Original equipment art is
affine-aligned to the standard pistol silhouette frame by frame. Pixels that
would sit behind the character are removed, while the standard pistol's
visible hand overlap is retained so the grip does not look pasted on top.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
TEMPLATE_DIR = (
    ROOT / "assets/art/weapons/character_layers/standard_service_pistol"
)
BODY_DIR = ROOT / "assets/art/characters/rendered3d/base_drifter"
OUTPUT_ROOT = ROOT / "assets/art/weapons/character_layers"
BASIC_ATLAS = ROOT / "assets/art/weapons/basic_weapons.png"
ADVANCED_ATLAS = ROOT / "assets/art/weapons/advanced_weapons.png"
RAILGUN_ATLAS = ROOT / "assets/art/weapons/conductor_railgun_growth.png"
FRAME_SIZE = 128


@dataclass(frozen=True)
class WeaponSpec:
    item_id: str
    prefix: str
    atlas_path: Path
    cell_size: int
    atlas_index: int
    source_grip: tuple[float, float]
    source_muzzle: tuple[float, float]
    length_scale: float = 1.0
    width_scale: float = 1.0
    visibility_radius: int = 7


WEAPONS = (
    WeaponSpec(
        "balanced_pistol",
        "balanced_pistol",
        BASIC_ATLAS,
        32,
        1,
        (12.5, 18.0),
        (25.5, 4.0),
        1.02,
        1.0,
        7,
    ),
    WeaponSpec(
        "breach_shotgun",
        "breach_shotgun",
        BASIC_ATLAS,
        32,
        2,
        (8.5, 23.0),
        (25.0, 4.0),
        1.78,
        1.12,
        9,
    ),
    WeaponSpec(
        "nullpoint_sidearm",
        "nullpoint_sidearm",
        ADVANCED_ATLAS,
        64,
        2,
        (22.0, 38.0),
        (43.0, 17.0),
        1.10,
        1.05,
        7,
    ),
    WeaponSpec(
        "siege_core",
        "siege_core",
        ADVANCED_ATLAS,
        64,
        3,
        (20.0, 39.0),
        (46.0, 14.0),
        1.72,
        1.16,
        9,
    ),
    WeaponSpec(
        "conductor_railgun",
        "conductor_railgun",
        RAILGUN_ATLAS,
        64,
        0,
        (13.0, 24.0),
        (61.0, 13.0),
        1.72,
        1.08,
        9,
    ),
    WeaponSpec(
        "conductor_railgun_awakened",
        "conductor_railgun_awakened",
        RAILGUN_ATLAS,
        64,
        3,
        (13.0, 24.0),
        (61.0, 13.0),
        1.82,
        1.10,
        9,
    ),
    WeaponSpec(
        "conductor_railgun_final",
        "conductor_railgun_final",
        RAILGUN_ATLAS,
        64,
        5,
        (13.0, 24.0),
        (61.0, 13.0),
        1.92,
        1.14,
        11,
    ),
)


def _opaque_points(image: Image.Image) -> np.ndarray:
    rgba = np.asarray(image.convert("RGBA"))
    ys, xs = np.where(rgba[:, :, 3] > 20)
    if len(xs) < 2:
        raise RuntimeError("Weapon frame has no usable pixels")
    return np.column_stack((xs, ys)).astype(float)


def _perpendicular_span(
    points: np.ndarray,
    origin: np.ndarray,
    normal: np.ndarray,
) -> float:
    projections = (points - origin) @ normal
    return max(2.0, float(projections.max() - projections.min()))


def _source_basis(
    image: Image.Image,
    spec: WeaponSpec,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, float, float]:
    points = _opaque_points(image)
    grip = np.asarray(spec.source_grip, dtype=float)
    muzzle = np.asarray(spec.source_muzzle, dtype=float)
    muzzle_vector = muzzle - grip
    length = max(2.0, float(np.linalg.norm(muzzle_vector)))
    axis = muzzle_vector / length
    normal = np.array([-axis[1], axis[0]])
    width = _perpendicular_span(points, grip, normal)
    return grip, axis, normal, length, width


def _target_basis(
    image: Image.Image,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, float, float]:
    rgba = np.asarray(image.convert("RGBA"))
    points = _opaque_points(image)

    # The approved standard pistol uses a warm brown grip and blue-grey metal.
    # Detecting the grip material gives the frame a semantic hand anchor.
    # PCA alone cannot distinguish muzzle from stock and used to flip the gun
    # by 180 degrees whenever a frame's silhouette changed slightly.
    grip_mask = (
        (rgba[:, :, 3] > 40)
        & (rgba[:, :, 0] > rgba[:, :, 1] * 1.05)
        & (rgba[:, :, 0] > rgba[:, :, 2] * 1.05)
        & (rgba[:, :, 0] > 20)
    )
    grip_ys, grip_xs = np.where(grip_mask)
    if len(grip_xs) == 0:
        raise RuntimeError("Standard pistol frame has no visible grip marker")
    grip = np.array(
        [float(grip_xs.mean()), float(grip_ys.mean())],
        dtype=float,
    )

    distances = np.linalg.norm(points - grip, axis=1)
    farthest = float(distances.max())
    muzzle_points = points[distances >= farthest * 0.84]
    muzzle = muzzle_points.mean(axis=0)
    muzzle_vector = muzzle - grip
    length = max(2.0, float(np.linalg.norm(muzzle_vector)))
    axis = muzzle_vector / length
    normal = np.array([-axis[1], axis[0]])
    width = _perpendicular_span(points, grip, normal)
    return grip, axis, normal, length, width


def _affine_weapon(
    icon: Image.Image,
    reference: Image.Image,
    body: Image.Image,
    spec: WeaponSpec,
) -> Image.Image:
    source_grip, source_axis, source_normal, source_length, source_width = (
        _source_basis(icon, spec)
    )
    target_grip, target_axis, target_normal, target_length, target_width = (
        _target_basis(reference)
    )

    along_scale = target_length * spec.length_scale / source_length
    across_scale = target_width * spec.width_scale / source_width
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
    reference_visibility = reference.getchannel("A").filter(
        ImageFilter.MaxFilter(radius)
    )
    body_alpha = np.asarray(body.getchannel("A"), dtype=np.uint8)
    reference_alpha = np.asarray(reference_visibility, dtype=np.uint8)
    # Outside the body the longer barrel remains visible. Where the new weapon
    # crosses the body, only the approved pistol visibility corridor survives.
    allowed = np.maximum(reference_alpha, np.where(body_alpha < 24, 255, 0))
    transformed_alpha = np.asarray(
        transformed.getchannel("A"),
        dtype=np.uint8,
    )
    transformed.putalpha(
        Image.fromarray(
            np.minimum(transformed_alpha, allowed.astype(np.uint8)),
            mode="L",
        )
    )
    return transformed


def _load_icon(spec: WeaponSpec) -> Image.Image:
    atlas = Image.open(spec.atlas_path).convert("RGBA")
    left = spec.atlas_index * spec.cell_size
    return atlas.crop((left, 0, left + spec.cell_size, spec.cell_size))


def _frame_at(atlas: Image.Image, frame_index: int) -> Image.Image:
    return atlas.crop(
        (
            frame_index * FRAME_SIZE,
            0,
            (frame_index + 1) * FRAME_SIZE,
            FRAME_SIZE,
        )
    )


def build() -> None:
    for spec in WEAPONS:
        icon = _load_icon(spec)
        if icon.getchannel("A").getbbox() is None:
            raise RuntimeError(f"Source icon is empty: {spec.item_id}")
        output_dir = OUTPUT_ROOT / spec.item_id
        output_dir.mkdir(parents=True, exist_ok=True)
        for source_path in sorted(TEMPLATE_DIR.glob("standard_pistol_*.png")):
            animation_direction = source_path.stem.removeprefix("standard_pistol_")
            body_path = BODY_DIR / f"{animation_direction}.png"
            if not body_path.is_file():
                raise RuntimeError(f"Missing body atlas: {body_path}")
            source = Image.open(source_path).convert("RGBA")
            body = Image.open(body_path).convert("RGBA")
            if source.size != body.size:
                raise RuntimeError(
                    f"Layer/body dimensions differ: {source_path.name}"
                )
            frame_count = source.width // FRAME_SIZE
            output = Image.new("RGBA", source.size)
            for frame_index in range(frame_count):
                frame = _frame_at(source, frame_index)
                body_frame = _frame_at(body, frame_index)
                rendered = _affine_weapon(icon, frame, body_frame, spec)
                if rendered.getchannel("A").getbbox() is None:
                    raise RuntimeError(
                        f"Transparent frame: {spec.item_id} "
                        f"{animation_direction}[{frame_index}]"
                    )
                output.alpha_composite(
                    rendered,
                    (frame_index * FRAME_SIZE, 0),
                )
            output.save(
                output_dir / f"{spec.prefix}_{animation_direction}.png",
                "PNG",
                optimize=True,
            )


if __name__ == "__main__":
    build()
