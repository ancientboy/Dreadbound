#!/usr/bin/env python3
"""Build the remaining per-item equipment layers for the action demo.

The approved body atlases and their timing are never modified. Each equipment
type uses semantic anchors suited to its actual motion:

* bow: fixed grip plus stable upper/lower limb identity; the animated standard
  string and arrow are retained;
* staff: fixed butt/grip and spell-head identity;
* shield: stable two-axis shield plane with temporal orientation continuity;
Off-hand presentation is intentionally excluded. The demo only renders the
equipment family currently being exercised.
"""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ATLAS = ROOT / "assets/art/weapons/equipment_runtime.png"
BODY_DIR = ROOT / "assets/art/characters/rendered3d/base_drifter"
LAYER_ROOT = ROOT / "assets/art/weapons/character_layers"
FRAME_SIZE = 128
ACTION_FRAMES = {
    "spell_enter": 7,
    "spell_idle": 26,
    "spell_shoot": 7,
    "spell_exit": 6,
    "bow_idle": 48,
    "bow_draw": 41,
    "bow_aim": 56,
    "bow_release": 41,
    "shield_raise": 33,
    "shield_block": 33,
    "shield_hit": 33,
    "shield_bash": 33,
}

DIRECTIONS = ("front", "left", "back", "right")
SPECS = {
    "mourning_bow": {
        "template": "standard_hunter_bow",
        "template_prefix": "standard_bow",
        "prefix": "mourning_bow",
        "source_index": 0,
        "actions": ("bow_idle", "bow_draw", "bow_aim", "bow_release"),
        "kind": "bow",
    },
    "echo_staff": {
        "template": "standard_echo_staff",
        "template_prefix": "standard_staff",
        "prefix": "echo_staff",
        "source_index": 1,
        "actions": ("spell_enter", "spell_idle", "spell_shoot", "spell_exit"),
        "kind": "staff",
    },
    "riot_shield": {
        "template": "standard_guard_shield",
        "template_prefix": "standard_shield",
        "prefix": "riot_shield",
        "source_index": 2,
        "actions": (
            "shield_raise",
            "shield_block",
            "shield_hit",
            "shield_bash",
        ),
        "kind": "shield",
    },
}


def opaque_points(image: Image.Image, threshold: int = 20) -> np.ndarray:
    alpha = np.asarray(image.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > threshold)
    if len(xs) < 2:
        raise RuntimeError("Equipment frame has no usable pixels")
    return np.column_stack((xs, ys)).astype(float)


def oriented_pca(
    points: np.ndarray,
    previous_axis: np.ndarray | None = None,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, float, float]:
    center = points.mean(axis=0)
    values, vectors = np.linalg.eigh(np.cov((points - center).T))
    major = vectors[:, int(np.argmax(values))]
    if previous_axis is not None:
        if float(np.dot(major, previous_axis)) < 0.0:
            major = -major
    elif major[1] < 0.0:
        major = -major
    minor = np.array([-major[1], major[0]])
    major_values = (points - center) @ major
    minor_values = (points - center) @ minor
    return (
        center,
        major,
        minor,
        max(2.0, float(np.ptp(major_values))),
        max(2.0, float(np.ptp(minor_values))),
    )


def affine_equipment(
    icon: Image.Image,
    source_center: np.ndarray,
    source_major: np.ndarray,
    source_minor: np.ndarray,
    source_major_span: float,
    source_minor_span: float,
    target_center: np.ndarray,
    target_major: np.ndarray,
    target_minor: np.ndarray,
    target_major_span: float,
    target_minor_span: float,
) -> Image.Image:
    source_basis = np.column_stack((source_major, source_minor))
    target_basis = np.column_stack(
        (
            target_major * target_major_span / source_major_span,
            target_minor * target_minor_span / source_minor_span,
        )
    )
    forward = target_basis @ source_basis.T
    translation = target_center - forward @ source_center
    inverse = np.linalg.inv(forward)
    inverse_translation = -inverse @ translation
    return icon.transform(
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


def visibility_clip(
    transformed: Image.Image,
    reference: Image.Image,
    body: Image.Image,
    radius: int,
) -> Image.Image:
    if radius % 2 == 0:
        radius += 1
    reference_alpha = np.asarray(
        reference.getchannel("A").filter(ImageFilter.MaxFilter(radius)),
        dtype=np.uint8,
    )
    body_alpha = np.asarray(body.getchannel("A"), dtype=np.uint8)
    allowed = np.maximum(reference_alpha, np.where(body_alpha < 24, 255, 0))
    alpha = np.asarray(transformed.getchannel("A"), dtype=np.uint8)
    transformed.putalpha(
        Image.fromarray(np.minimum(alpha, allowed).astype(np.uint8), mode="L")
    )
    return transformed


def source_icon(index: int) -> Image.Image:
    atlas = Image.open(SOURCE_ATLAS).convert("RGBA")
    return atlas.crop((index * 64, 0, (index + 1) * 64, 64))


def frame_at(
    atlas: Image.Image,
    index: int,
    columns: int,
    bottom_up: bool = False,
) -> Image.Image:
    x = (index % columns) * FRAME_SIZE
    row = index // columns
    if bottom_up:
        row = atlas.height // FRAME_SIZE - 1 - row
    y = row * FRAME_SIZE
    return atlas.crop((x, y, x + FRAME_SIZE, y + FRAME_SIZE))


def paste_frame(
    atlas: Image.Image,
    frame: Image.Image,
    index: int,
    columns: int,
    bottom_up: bool = False,
) -> None:
    row = index // columns
    if bottom_up:
        row = atlas.height // FRAME_SIZE - 1 - row
    atlas.alpha_composite(
        frame,
        ((index % columns) * FRAME_SIZE, row * FRAME_SIZE),
    )


def bow_source(icon: Image.Image) -> tuple[Image.Image, tuple]:
    rgba = np.asarray(icon)
    # Remove the inventory-icon string. The approved action layer supplies a
    # properly animated string and arrow for draw, aim, and release.
    cool = (
        (rgba[:, :, 3] > 20)
        & (rgba[:, :, 2] > rgba[:, :, 0] * 1.12)
        & (rgba[:, :, 1] > rgba[:, :, 0] * 0.82)
    )
    cleaned = rgba.copy()
    cleaned[cool, 3] = 0
    image = Image.fromarray(cleaned, mode="RGBA")
    points = opaque_points(image)
    return image, oriented_pca(points)


def bow_target(
    reference: Image.Image,
    previous_axis: np.ndarray | None,
) -> tuple[tuple, Image.Image]:
    rgba = np.asarray(reference)
    warm = (
        (rgba[:, :, 3] > 20)
        & (rgba[:, :, 0] > rgba[:, :, 2] * 1.16)
        & (rgba[:, :, 0] > rgba[:, :, 1] * 0.92)
    )
    ys, xs = np.where(warm)
    points = (
        np.column_stack((xs, ys)).astype(float)
        if len(xs) >= 2
        else opaque_points(reference)
    )
    basis = oriented_pca(points, previous_axis)

    # Retain only the cool string, arrow, and grip markers from the approved
    # bow action. The old generic wooden limbs must not leak into the new bow.
    cool = (
        (rgba[:, :, 3] > 20)
        & (rgba[:, :, 2] >= rgba[:, :, 0] * 0.88)
        & (rgba[:, :, 1] >= rgba[:, :, 0] * 0.72)
    )
    retained = np.zeros_like(rgba)
    retained[cool] = rgba[cool]
    return basis, Image.fromarray(retained, mode="RGBA")


def render_bow(
    icon: Image.Image,
    reference: Image.Image,
    body: Image.Image,
    previous_axis: np.ndarray | None,
    direction: str,
) -> tuple[Image.Image, np.ndarray]:
    cleaned, source = bow_source(icon)
    target, retained = bow_target(reference, previous_axis)
    source = list(source)
    # The inventory icon is painted from one side. When the character faces
    # right its limb curvature must be mirrored around the grip axis so the
    # string remains on the archer side and the bow belly faces the target.
    if direction == "right":
        source[2] = -source[2]
    transformed = affine_equipment(
        cleaned,
        *source,
        target[0],
        target[1],
        target[2],
        target[3] * 1.02,
        max(5.0, target[4] * 1.08),
    )
    transformed = visibility_clip(transformed, reference, body, 9)
    output = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
    output.alpha_composite(transformed)
    output.alpha_composite(retained)
    target_center = target[0]
    # The grip can be fully hidden by the palm/torso in back-facing frames.
    # A wider contact corridor still catches a detached bow while respecting
    # the approved body occlusion.
    if float(np.linalg.norm(opaque_points(output) - target_center, axis=1).min()) > 18.0:
        raise RuntimeError("Bow grip detached from the approved hand region")
    return output, target[1]


def staff_basis(
    image: Image.Image,
    source: bool,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, float, float]:
    rgba = np.asarray(image)
    points = opaque_points(image)
    if source:
        butt = np.array([14.0, 60.0])
        head = np.array([44.0, 5.0])
    else:
        bright = (
            (rgba[:, :, 3] > 20)
            & (rgba[:, :, 2] > 110)
            & (rgba[:, :, 1] > 95)
            & (rgba[:, :, :3].mean(axis=2) > 85)
        )
        ys, xs = np.where(bright)
        if len(xs) < 2:
            raise RuntimeError("Standard staff frame has no spell-head marker")
        # Both ends may contain a cool highlight. The spell head is the
        # largest connected bright component, while the butt marker is tiny.
        remaining = {(int(x), int(y)) for x, y in zip(xs, ys)}
        components: list[list[tuple[int, int]]] = []
        while remaining:
            seed = remaining.pop()
            component = [seed]
            stack = [seed]
            while stack:
                x, y = stack.pop()
                for neighbor in (
                    (x - 1, y),
                    (x + 1, y),
                    (x, y - 1),
                    (x, y + 1),
                ):
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        component.append(neighbor)
                        stack.append(neighbor)
            components.append(component)
        head_component = max(components, key=len)
        head = np.array(
            [
                float(np.mean([point[0] for point in head_component])),
                float(np.mean([point[1] for point in head_component])),
            ]
        )
        distances = np.linalg.norm(points - head, axis=1)
        butt_points = points[distances >= float(distances.max()) * 0.88]
        butt = butt_points.mean(axis=0)
    # The authored standard staff's hand origin is 30% of the way from the
    # lower cap to the focus crystal. Matching that semantic grip prevents the
    # source icon's butt from being mistaken for the character's hand.
    grip = butt + (head - butt) * 0.30
    vector = head - grip
    length = max(2.0, float(np.linalg.norm(vector)))
    major = vector / length
    minor = np.array([-major[1], major[0]])
    width = max(2.0, float(np.ptp((points - grip) @ minor)))
    return grip, major, minor, length, width


def render_staff(
    icon: Image.Image,
    reference: Image.Image,
    body: Image.Image,
    direction: str,
) -> Image.Image:
    source = list(staff_basis(icon, True))
    target = staff_basis(reference, False)
    # Preserve head/butt identity while mirroring the asymmetric spell-head
    # ornament for the left view. Reversing the major axis would put the focus
    # behind the character, so only the cross-shaft handedness is changed.
    if direction == "left":
        source[2] = -source[2]
    transformed = affine_equipment(
        icon,
        *source,
        target[0],
        target[1],
        target[2],
        target[3] * 1.04,
        target[4] * 1.08,
    )
    raw_points = opaque_points(transformed)
    if (
        float(((raw_points - target[0]) @ target[1]).max())
        <= max(1.0, target[3] * 0.25)
    ):
        raise RuntimeError("Staff head no longer extends from the grip")
    transformed = visibility_clip(transformed, reference, body, 7)
    points = opaque_points(transformed)
    if float(np.linalg.norm(points - target[0], axis=1).min()) > 12.0:
        raise RuntimeError("Staff butt/grip detached from hand anchor")
    return transformed


def render_shield(
    icon: Image.Image,
    reference: Image.Image,
    body: Image.Image,
    previous_axis: np.ndarray | None,
    direction: str,
) -> tuple[Image.Image, np.ndarray]:
    source = oriented_pca(opaque_points(icon))
    target = oriented_pca(opaque_points(reference), previous_axis)
    transformed = affine_equipment(
        icon,
        *source,
        target[0],
        target[1],
        target[2],
        target[3] * 1.14,
        target[4] * 1.12,
    )
    if direction == "back":
        # A rear-facing character exposes the inside of the shield to the
        # camera. Repaint the transformed face as a subdued inner plate and
        # add two clipped grip straps instead of showing the exterior emblem.
        rgba = np.asarray(transformed).copy()
        alpha = rgba[:, :, 3]
        luminance = rgba[:, :, :3].mean(axis=2)
        rgba[:, :, 0] = np.where(alpha > 0, 34 + luminance * 0.18, 0)
        rgba[:, :, 1] = np.where(alpha > 0, 37 + luminance * 0.16, 0)
        rgba[:, :, 2] = np.where(alpha > 0, 40 + luminance * 0.14, 0)
        transformed = Image.fromarray(rgba.astype(np.uint8), mode="RGBA")
        straps = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE))
        draw = ImageDraw.Draw(straps)
        for offset in (-target[3] * 0.16, target[3] * 0.13):
            strap_center = target[0] + target[1] * offset
            start = strap_center - target[2] * target[4] * 0.28
            end = strap_center + target[2] * target[4] * 0.28
            draw.line(
                (tuple(start), tuple(end)),
                fill=(91, 72, 55, 235),
                width=3,
            )
        strap_alpha = np.minimum(
            np.asarray(straps.getchannel("A"), dtype=np.uint8),
            alpha,
        )
        straps.putalpha(Image.fromarray(strap_alpha, mode="L"))
        transformed.alpha_composite(straps)
    transformed = visibility_clip(transformed, reference, body, 13)
    if direction == "back":
        # In the rear view the forearm and hand sit between the camera and the
        # shield interior. Keep body pixels in front instead of letting the
        # equipment layer cover the head/arm as the old exterior layer did.
        body_alpha = np.asarray(body.getchannel("A"), dtype=np.uint8)
        alpha = np.asarray(transformed.getchannel("A"), dtype=np.uint8)
        transformed.putalpha(
            Image.fromarray(
                np.where(body_alpha < 24, alpha, 0).astype(np.uint8),
                mode="L",
            )
        )
    points = opaque_points(transformed)
    if float(np.linalg.norm(points.mean(axis=0) - target[0])) > 5.0:
        raise RuntimeError("Shield plane detached from the left-hand guard")
    return transformed, target[1]


def build_spec(item_id: str, spec: dict) -> int:
    icon = source_icon(int(spec["source_index"]))
    if icon.getchannel("A").getbbox() is None:
        raise RuntimeError(f"Empty source icon: {item_id}")
    template_dir = LAYER_ROOT / str(spec["template"])
    output_dir = LAYER_ROOT / item_id
    output_dir.mkdir(parents=True, exist_ok=True)
    total_frames = 0

    for action in spec["actions"]:
        for direction in DIRECTIONS:
            stem = f"{action}_{direction}"
            template_path = (
                template_dir / f"{spec['template_prefix']}_{stem}.png"
            )
            body_path = BODY_DIR / f"{stem}.png"
            reference = Image.open(template_path).convert("RGBA")
            body = Image.open(body_path).convert("RGBA")
            if reference.size != body.size:
                raise RuntimeError(f"Layer/body mismatch: {template_path.name}")
            columns = reference.width // FRAME_SIZE
            frame_count = int(ACTION_FRAMES[action])
            bottom_up = spec["kind"] in ("bow", "shield")
            output = Image.new("RGBA", reference.size)
            previous_axis: np.ndarray | None = None
            for frame_index in range(frame_count):
                ref_frame = frame_at(reference, frame_index, columns, bottom_up)
                body_frame = frame_at(body, frame_index, columns, bottom_up)
                if spec["kind"] == "bow":
                    rendered, previous_axis = render_bow(
                        icon, ref_frame, body_frame, previous_axis, direction
                    )
                elif spec["kind"] == "staff":
                    rendered = render_staff(
                        icon,
                        ref_frame,
                        body_frame,
                        direction,
                    )
                elif spec["kind"] == "shield":
                    rendered, previous_axis = render_shield(
                        icon,
                        ref_frame,
                        body_frame,
                        previous_axis,
                        direction,
                    )
                else:
                    raise RuntimeError(f"Unsupported equipment kind: {spec['kind']}")
                if rendered.getchannel("A").getbbox() is None:
                    raise RuntimeError(
                        f"Transparent frame: {item_id} {stem}[{frame_index}]"
                    )
                paste_frame(output, rendered, frame_index, columns, bottom_up)
                total_frames += 1
            output.save(
                output_dir / f"{spec['prefix']}_{stem}.png",
                "PNG",
                optimize=True,
            )
    return total_frames


def build() -> None:
    totals = {item_id: build_spec(item_id, spec) for item_id, spec in SPECS.items()}
    print("remaining equipment frames:", totals)


if __name__ == "__main__":
    build()
