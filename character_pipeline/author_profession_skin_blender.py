"""Author the Steadfast and Resonant demo skins on the standard humanoid rig.

Both outfits reuse the rendering and action-atlas contract established by the
Armorer demo skin.  Only profession geometry and materials differ; gameplay
scenes and the locked 65-bone action library are never modified.

Example:

    blender --background character_pipeline/dreadbound_weapon_actions.blend \
      --python character_pipeline/author_profession_skin_blender.py -- \
      --profession steadfast \
      --blend-output character_pipeline/dreadbound_steadfast_demo.blend \
      --preview-output /tmp/dreadbound-steadfast-preview
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

SCRIPT_ROOT = Path(__file__).resolve().parent
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

import author_armorer_skin_blender as shared


PROFESSIONS = ("steadfast", "resonant")
ARMATURE_NAME = shared.ARMATURE_NAME
BODY_NAME = shared.BODY_NAME


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--profession", choices=PROFESSIONS, required=True)
    parser.add_argument("--blend-output", type=Path, required=True)
    parser.add_argument("--preview-output", type=Path)
    parser.add_argument("--atlas-output", type=Path)
    parser.add_argument(
        "--actions",
        nargs="+",
        choices=tuple(shared.ATLAS_ACTIONS),
        default=list(shared.ATLAS_ACTIONS),
    )
    return parser.parse_args(argv)


def begin_outfit(profession: str):
    armature = bpy.data.objects.get(ARMATURE_NAME)
    body = bpy.data.objects.get(BODY_NAME)
    if armature is None or armature.type != "ARMATURE":
        raise RuntimeError("The standard Dreadbound Armature is missing")
    if body is None or body.type != "MESH":
        raise RuntimeError("The standard Dreadbound mannequin is missing")
    if len(armature.data.bones) != 65:
        raise RuntimeError(
            f"Expected the locked 65-bone rig, found {len(armature.data.bones)} bones"
        )
    armature.data.pose_position = "REST"
    armature.animation_data_clear()
    shared.COLLECTION_NAME = f"Dreadbound {profession.title()} Demo Outfit"
    collection = shared.delete_previous_outfit()
    return armature, body, collection


def add_cross(
    name: str,
    location: tuple[float, float, float],
    scale: float,
    depth: float,
    bone: str,
    mat,
    collection,
    armature,
    rear: bool = False,
):
    y = location[1]
    rotation = (math.pi / 2.0, 0.0, 0.0) if rear else (0.0, 0.0, 0.0)
    # Crosses face the camera from front/back.  Their small depth keeps the
    # mark legible at 128 px without becoming a bulky piece of armor.
    horizontal = shared.box(
        f"{name} horizontal",
        (location[0], y, location[2]),
        (scale, depth, scale * 0.34),
        bone,
        mat,
        collection,
        armature,
        rotation=rotation,
        bevel=scale * 0.04,
    )
    vertical = shared.box(
        f"{name} vertical",
        (location[0], y - (0.002 if rear else 0.0), location[2]),
        (scale * 0.34, depth, scale),
        bone,
        mat,
        collection,
        armature,
        rotation=rotation,
        bevel=scale * 0.04,
    )
    return [horizontal, vertical]


def limb_shells(
    prefix: str,
    armature,
    collection,
    upper_mat,
    lower_mat,
    leg_mat,
    boot_mat,
    upper_radius: float,
    lower_radius: float,
):
    created = []
    for side, sign in (("left", 1.0), ("right", -1.0)):
        suffix = "l" if side == "left" else "r"
        upper = f"upperarm_{suffix}"
        lower = f"lowerarm_{suffix}"
        thigh = f"thigh_{suffix}"
        calf = f"calf_{suffix}"
        foot = f"foot_{suffix}"
        upper_start, upper_end = shared.bone_points(armature, upper, 0.035)
        lower_start, lower_end = shared.bone_points(armature, lower, 0.04)
        thigh_start, thigh_end = shared.bone_points(armature, thigh, 0.055)
        calf_start, calf_end = shared.bone_points(armature, calf, 0.055)
        foot_start, foot_end = shared.bone_points(armature, foot, 0.015)
        created += [
            shared.cylinder_between(
                f"{prefix} {side} upper sleeve",
                upper_start,
                upper_end,
                upper_radius,
                upper,
                upper_mat,
                collection,
                armature,
            ),
            shared.cylinder_between(
                f"{prefix} {side} bracer",
                lower_start,
                lower_end,
                lower_radius,
                lower,
                lower_mat,
                collection,
                armature,
            ),
            shared.cylinder_between(
                f"{prefix} {side} trouser",
                thigh_start,
                thigh_end,
                upper_radius + 0.018,
                thigh,
                leg_mat,
                collection,
                armature,
            ),
            shared.cylinder_between(
                f"{prefix} {side} shin",
                calf_start,
                calf_end,
                lower_radius + 0.012,
                calf,
                lower_mat,
                collection,
                armature,
            ),
            shared.box(
                f"{prefix} {side} boot",
                tuple((foot_start + foot_end) * 0.5),
                (0.14, 0.27, 0.13),
                foot,
                boot_mat,
                collection,
                armature,
                bevel=0.025,
            ),
        ]
    return created


def author_steadfast():
    armature, body, collection = begin_outfit("steadfast")
    cloth = shared.material("Steadfast field cloth", (0.12, 0.145, 0.115, 1.0), 0.02, 0.82)
    cloth_dark = shared.material("Steadfast dark cloth", (0.045, 0.055, 0.047, 1.0), 0.03, 0.88)
    armor = shared.material("Steadfast ceramic armor", (0.48, 0.49, 0.43, 1.0), 0.18, 0.50)
    metal = shared.material("Steadfast hardware", (0.10, 0.095, 0.082, 1.0), 0.68, 0.31)
    medic = shared.material("Steadfast medic mark", (0.66, 0.76, 0.67, 1.0), 0.05, 0.47)
    teal = shared.material(
        "Steadfast diagnostic glow",
        (0.20, 0.93, 0.78, 1.0),
        0.22,
        0.22,
        emission_strength=1.8,
    )
    lens = shared.material("Steadfast mask lens", (0.055, 0.075, 0.06, 1.0), 0.75, 0.14)
    # The source mannequin uses an orange diagnostic material.  It remains the
    # deforming under-suit, but its visible hands and joint gaps must match the
    # approved profession palette.
    body.data.materials.clear()
    body.data.materials.append(cloth_dark)

    created = [
        shared.box(
            "Steadfast padded torso",
            (0.0, -0.045, 1.27),
            (0.39, 0.22, 0.48),
            "spine_02",
            cloth,
            collection,
            armature,
            bevel=0.055,
        ),
        shared.box(
            "Steadfast chest carrier",
            (0.0, -0.174, 1.35),
            (0.27, 0.065, 0.24),
            "spine_02",
            metal,
            collection,
            armature,
            bevel=0.025,
        ),
        shared.box(
            "Steadfast utility belt",
            (0.0, -0.035, 0.98),
            (0.37, 0.23, 0.09),
            "pelvis",
            metal,
            collection,
            armature,
            bevel=0.018,
        ),
        shared.box(
            "Steadfast left coat tail",
            (0.105, 0.01, 0.80),
            (0.18, 0.11, 0.40),
            "thigh_l",
            cloth,
            collection,
            armature,
            rotation=(0.0, 0.055, -0.025),
            bevel=0.025,
        ),
        shared.box(
            "Steadfast right coat tail",
            (-0.105, 0.01, 0.80),
            (0.18, 0.11, 0.40),
            "thigh_r",
            cloth,
            collection,
            armature,
            rotation=(0.0, -0.055, 0.025),
            bevel=0.025,
        ),
        shared.box(
            "Steadfast survival pack",
            (0.0, 0.22, 1.30),
            (0.37, 0.22, 0.49),
            "spine_02",
            cloth_dark,
            collection,
            armature,
            bevel=0.045,
        ),
        shared.box(
            "Steadfast bedroll",
            (0.0, 0.25, 1.61),
            (0.36, 0.19, 0.14),
            "spine_03",
            cloth,
            collection,
            armature,
            bevel=0.05,
        ),
        shared.sphere(
            "Steadfast hood",
            (0.0, 0.01, 1.69),
            (0.29, 0.28, 0.34),
            "Head",
            cloth,
            collection,
            armature,
        ),
        shared.box(
            "Steadfast respirator",
            (0.0, -0.158, 1.64),
            (0.20, 0.075, 0.18),
            "Head",
            metal,
            collection,
            armature,
            bevel=0.045,
        ),
        shared.sphere(
            "Steadfast left goggle",
            (0.065, -0.204, 1.72),
            (0.072, 0.027, 0.072),
            "Head",
            lens,
            collection,
            armature,
        ),
        shared.sphere(
            "Steadfast right goggle",
            (-0.065, -0.204, 1.72),
            (0.072, 0.027, 0.072),
            "Head",
            lens,
            collection,
            armature,
        ),
        shared.sphere(
            "Steadfast filter",
            (0.0, -0.212, 1.59),
            (0.09, 0.035, 0.09),
            "Head",
            metal,
            collection,
            armature,
        ),
        shared.box(
            "Steadfast diagnostic vial",
            (-0.145, -0.20, 1.27),
            (0.045, 0.045, 0.15),
            "spine_02",
            teal,
            collection,
            armature,
            bevel=0.012,
        ),
    ]
    created += add_cross(
        "Steadfast chest cross",
        (0.0, -0.214, 1.36),
        0.13,
        0.025,
        "spine_02",
        medic,
        collection,
        armature,
    )
    created += add_cross(
        "Steadfast pack cross",
        (0.0, 0.342, 1.32),
        0.16,
        0.022,
        "spine_02",
        medic,
        collection,
        armature,
        rear=True,
    )
    for side, sign in (("left", 1.0), ("right", -1.0)):
        suffix = "l" if side == "left" else "r"
        upper = f"upperarm_{suffix}"
        created.append(
            shared.sphere(
                f"Steadfast {side} shoulder shell",
                (0.235 * sign, 0.005, 1.44),
                (0.235, 0.25, 0.205),
                upper,
                armor,
                collection,
                armature,
            )
        )
        created += add_cross(
            f"Steadfast {side} shoulder cross",
            (0.235 * sign, -0.135, 1.44),
            0.08,
            0.02,
            upper,
            teal,
            collection,
            armature,
        )
        # Side pack canisters preserve the asymmetric survival silhouette.
        created.append(
            shared.box(
                f"Steadfast {side} pack canister",
                (0.215 * sign, 0.255, 1.27),
                (0.095, 0.095, 0.29),
                "spine_02",
                metal,
                collection,
                armature,
                bevel=0.025,
            )
        )
    created += limb_shells(
        "Steadfast",
        armature,
        collection,
        cloth,
        armor,
        cloth,
        metal,
        0.082,
        0.074,
    )
    return armature, body, created


def author_resonant():
    armature, body, collection = begin_outfit("resonant")
    cloth = shared.material("Resonant black cloth", (0.035, 0.025, 0.052, 1.0), 0.02, 0.86)
    cloth_mid = shared.material("Resonant violet cloth", (0.075, 0.045, 0.11, 1.0), 0.02, 0.78)
    armor = shared.material("Resonant dark hardware", (0.09, 0.07, 0.12, 1.0), 0.58, 0.32)
    trim = shared.material("Resonant silver trim", (0.36, 0.32, 0.40, 1.0), 0.70, 0.24)
    glow = shared.material(
        "Resonant violet energy",
        (0.49, 0.10, 1.0, 1.0),
        0.18,
        0.16,
        emission_strength=3.2,
    )
    core = shared.material(
        "Resonant core",
        (0.70, 0.31, 1.0, 1.0),
        0.35,
        0.12,
        emission_strength=4.5,
    )
    void = shared.material("Resonant void face", (0.003, 0.002, 0.008, 1.0), 0.0, 1.0)
    body.data.materials.clear()
    body.data.materials.append(cloth)

    created = [
        shared.box(
            "Resonant fitted torso",
            (0.0, -0.035, 1.29),
            (0.32, 0.19, 0.46),
            "spine_02",
            cloth,
            collection,
            armature,
            bevel=0.04,
        ),
        shared.box(
            "Resonant layered collar",
            (0.0, -0.02, 1.51),
            (0.35, 0.22, 0.13),
            "spine_03",
            armor,
            collection,
            armature,
            bevel=0.035,
        ),
        shared.box(
            "Resonant waist harness",
            (0.0, -0.045, 1.00),
            (0.32, 0.20, 0.09),
            "pelvis",
            trim,
            collection,
            armature,
            bevel=0.016,
        ),
        shared.sphere(
            "Resonant hood",
            (0.0, 0.005, 1.70),
            (0.30, 0.27, 0.36),
            "Head",
            cloth_mid,
            collection,
            armature,
        ),
        shared.box(
            "Resonant void face",
            (0.0, -0.161, 1.675),
            (0.19, 0.035, 0.18),
            "Head",
            void,
            collection,
            armature,
            bevel=0.06,
        ),
        shared.sphere(
            "Resonant face glow",
            (0.0, -0.186, 1.63),
            (0.09, 0.018, 0.045),
            "Head",
            glow,
            collection,
            armature,
        ),
        shared.torus(
            "Resonant back core outer",
            (0.0, 0.19, 1.36),
            0.14,
            0.022,
            "spine_02",
            trim,
            collection,
            armature,
            rotation=(math.pi / 2.0, 0.0, 0.0),
        ),
        shared.torus(
            "Resonant back core energy ring",
            (0.0, 0.215, 1.36),
            0.095,
            0.014,
            "spine_02",
            glow,
            collection,
            armature,
            rotation=(math.pi / 2.0, 0.0, 0.0),
        ),
        shared.sphere(
            "Resonant back core",
            (0.0, 0.235, 1.36),
            (0.09, 0.025, 0.09),
            "spine_02",
            core,
            collection,
            armature,
        ),
    ]

    # Four long panels are bound to the thighs so the silhouette follows
    # locomotion without requiring a new cloth simulation or new animations.
    for side, sign in (("left", 1.0), ("right", -1.0)):
        suffix = "l" if side == "left" else "r"
        thigh = f"thigh_{suffix}"
        upper = f"upperarm_{suffix}"
        lower = f"lowerarm_{suffix}"
        created += [
            shared.box(
                f"Resonant {side} front coat",
                (0.095 * sign, -0.075, 0.72),
                (0.16, 0.075, 0.66),
                thigh,
                cloth_mid,
                collection,
                armature,
                rotation=(0.0, 0.065 * sign, -0.025 * sign),
                bevel=0.02,
            ),
            shared.box(
                f"Resonant {side} rear coat",
                (0.115 * sign, 0.075, 0.75),
                (0.13, 0.07, 0.58),
                thigh,
                cloth,
                collection,
                armature,
                rotation=(0.0, -0.045 * sign, 0.035 * sign),
                bevel=0.018,
            ),
            shared.sphere(
                f"Resonant {side} shoulder mantle",
                (0.225 * sign, 0.02, 1.45),
                (0.20, 0.22, 0.16),
                upper,
                armor,
                collection,
                armature,
            ),
            shared.torus(
                f"Resonant {side} bracer rune",
                (0.285 * sign, -0.02, 1.05),
                0.052,
                0.010,
                lower,
                glow,
                collection,
                armature,
                rotation=(math.pi / 2.0, 0.0, 0.0),
            ),
        ]
        # Large rune rails read as two deliberate light strokes at game size.
        created += [
            shared.box(
                f"Resonant {side} chest rune",
                (0.075 * sign, -0.145, 1.28),
                (0.018, 0.018, 0.29),
                "spine_02",
                glow,
                collection,
                armature,
                rotation=(0.0, 0.0, 0.12 * sign),
                bevel=0.006,
            ),
            shared.box(
                f"Resonant {side} coat rune",
                (0.055 * sign, -0.118, 0.73),
                (0.018, 0.018, 0.42),
                thigh,
                glow,
                collection,
                armature,
                rotation=(0.0, 0.0, 0.08 * sign),
                bevel=0.006,
            ),
        ]
    created += limb_shells(
        "Resonant",
        armature,
        collection,
        cloth,
        armor,
        cloth,
        armor,
        0.066,
        0.060,
    )
    return armature, body, created


def main() -> None:
    args = parse_args()
    if args.profession == "steadfast":
        armature, body, outfit = author_steadfast()
    else:
        armature, body, outfit = author_resonant()

    atlas_manifest = None
    if args.atlas_output is not None:
        original_source = None
        manifest_path = args.atlas_output.resolve() / "manifest.json"
        if manifest_path.exists():
            original_source = manifest_path.read_text(encoding="utf-8")
        atlas_manifest = shared.render_atlases(
            args.atlas_output.resolve(),
            armature,
            body,
            outfit,
            args.actions,
        )
        atlas_manifest["source"] = f"standard_humanoid_{args.profession}_blender"
        atlas_manifest["character_id"] = f"{args.profession}_demo_v1"
        manifest_path.write_text(
            json.dumps(atlas_manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        del original_source
    if args.preview_output is not None:
        shared.render_previews(
            args.preview_output.resolve(),
            armature,
            body,
            outfit,
        )
    armature.data.pose_position = "POSE"
    bpy.ops.wm.save_as_mainfile(filepath=str(args.blend_output.resolve()))
    print(
        json.dumps(
            {
                "status": "ok",
                "profession": args.profession,
                "blend_output": str(args.blend_output.resolve()),
                "outfit_objects": len(outfit),
                "armature_bones": len(armature.data.bones),
                "actions": len(bpy.data.actions),
                "atlas_animations": (
                    len(atlas_manifest["animations"])
                    if atlas_manifest is not None
                    else 0
                ),
            }
        )
    )


if __name__ == "__main__":
    main()
