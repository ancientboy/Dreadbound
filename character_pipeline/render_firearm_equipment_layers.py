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
    length_scale: float = 1.0
    width_scale: float = 1.0
    grip_fraction: float = 0.24
    visibility_radius: int = 7


WEAPONS = (
    WeaponSpec(
        "balanced_pistol",
        "balanced_pistol",
        BASIC_ATLAS,
        32,
        1,
        1.02,
        1.0,
        0.28,
        7,
    ),
    WeaponSpec(
        "breach_shotgun",
        "breach_shotgun",
        BASIC_ATLAS,
        32,
        2,
        1.78,
        1.12,
        0.20,
        9,
    ),
    WeaponSpec(
        "nullpoint_sidearm",
        "nullpoint_sidearm",
        ADVANCED_ATLAS,
        64,
        2,
        1.10,
        1.05,
        0.28,
        7,
    ),
    WeaponSpec(
        "siege_core",
        "siege_core",
        ADVANCED_ATLAS,
        64,
        3,
        1.72,
        1.16,
        0.22,
        9,
    ),
    WeaponSpec(
        "conductor_railgun",
        "conductor_railgun",
        RAILGUN_ATLAS,
        64,
        0,
        1.72,
        1.08,
        0.18,
        9,
    ),
    WeaponSpec(
        "conductor_railgun_awakened",
        "conductor_railgun_awakened",
        RAILGUN_ATLAS,
        64,
        3,
        1.82,
        1.10,
        0.18,
        9,
    ),
    WeaponSpec(
        "conductor_railgun_final",
        "conductor_railgun_final",
        RAILGUN_ATLAS,
        64,
        5,
        1.92,
        1.14,
        0.18,
        11,
    ),
)


def _opaque_points(image: Image.Image) -> np.ndarray:
    rgba = np.asarray(image.convert("RGBA"))
    ys, xs = np.where(rgba[:, :, 3] > 20)
    if len(xs) < 2:
        raise RuntimeError("Weapon frame has no usable pixels")
    return np.column_stack((xs, ys)).astype(float)


def _basis(
    image: Image.Image,
    grip_fraction: float,
    prefer_right: bool,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, float, float]:
    points = _opaque_points(image)
    center = points.mean(axis=0)
    _values, vectors = np.linalg.eigh(np.cov((points - center).T))
    axis = vectors[:, 1]
    if prefer_right and axis[0] < 0.0:
        axis = -axis

    projections = (points - center) @ axis
    low = float(projections.min())
    high = float(projections.max())
    length = max(2.0, high - low)

    normal = np.array([-axis[1], axis[0]])
    normal_projections = (points - center) @ normal
    # The grip is the stronger branch away from the barrel. Keep the normal
    # direction stable by pointing it toward the larger silhouette extent.
    if abs(float(normal_projections.min())) > abs(float(normal_projections.max())):
        normal = -normal
        normal_projections = -normal_projections
    width = max(2.0, float(normal_projections.max() - normal_projections.min()))

    along = low + length * grip_fraction
    band = np.abs(projections - along) <= max(1.5, length * 0.16)
    band_points = points[band]
    band_normals = normal_projections[band]
    if len(band_points):
        farthest = band_points[int(np.argmax(band_normals))]
        # Anchor inside the wrapped grip, not at its exposed lower tip.
        grip = center + axis * along
        grip += normal * float(np.dot(farthest - grip, normal)) * 0.42
    else:
        grip = center + axis * along
    return grip, axis, normal, length, width


def _affine_weapon(
    icon: Image.Image,
    reference: Image.Image,
    body: Image.Image,
    spec: WeaponSpec,
) -> Image.Image:
    source_grip, source_axis, source_normal, source_length, source_width = _basis(
        icon,
        spec.grip_fraction,
        True,
    )
    target_grip, target_axis, target_normal, target_length, target_width = _basis(
        reference,
        0.26,
        False,
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
