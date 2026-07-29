#!/usr/bin/env python3
"""Retarget CC0 KayKit bow and shield actions to Dreadbound's UAL armature.

KayKit's mannequin is used only as an offline motion source.  The resulting
actions are baked onto the checked-in Quaternius-compatible armature so the
published character model, materials, proportions, and camera remain intact.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion

sys.path.insert(0, str(Path(__file__).resolve().parent))
from export_ual_humanoid_poses import assign_action, set_scene_frame, source_keyframes


ACTION_SPECS = {
    "bow_idle": ("ranged", "Ranged_Bow_Idle", True),
    "bow_draw": ("ranged", "Ranged_Bow_Draw", False),
    "bow_aim": ("ranged", "Ranged_Bow_Aiming_Idle", True),
    "bow_release": ("ranged", "Ranged_Bow_Release", False),
    "shield_raise": ("melee", "Melee_Block", False),
    "shield_block": ("melee", "Melee_Blocking", True),
    "shield_hit": ("melee", "Melee_Block_Hit", False),
    "shield_bash": ("melee", "Melee_Block_Attack", False),
}

# Parent-first target order.  Global rest-to-pose rotation deltas make the
# transfer independent of the two rigs' different bone roll conventions.
BONE_MAP = (
    ("pelvis", "hips", 1.0),
    ("spine_01", "spine", 0.45),
    ("spine_02", "spine", 1.0),
    ("spine_03", "chest", 1.0),
    ("neck_01", "head", 0.45),
    ("Head", "head", 1.0),
    ("upperarm_l", "upperarm.l", 1.0),
    ("lowerarm_l", "lowerarm.l", 1.0),
    ("hand_l", "hand.l", 1.0),
    ("upperarm_r", "upperarm.r", 1.0),
    ("lowerarm_r", "lowerarm.r", 1.0),
    ("hand_r", "hand.r", 1.0),
    ("thigh_l", "upperleg.l", 1.0),
    ("calf_l", "lowerleg.l", 1.0),
    ("foot_l", "foot.l", 1.0),
    ("thigh_r", "upperleg.r", 1.0),
    ("calf_r", "lowerleg.r", 1.0),
    ("foot_r", "foot.r", 1.0),
)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--ranged", required=True, type=Path)
    parser.add_argument("--melee", required=True, type=Path)
    parser.add_argument("--blend-output", required=True, type=Path)
    parser.add_argument("--manifest-output", required=True, type=Path)
    return parser.parse_args(argv)


def import_library(
    path: Path,
    label: str,
) -> tuple[bpy.types.Object, dict[str, bpy.types.Action], list[bpy.types.Object]]:
    before_objects = set(bpy.context.scene.objects)
    before_actions = set(bpy.data.actions)
    bpy.ops.import_scene.gltf(filepath=str(path.resolve()))
    armatures = [
        obj
        for obj in bpy.context.scene.objects
        if obj not in before_objects and obj.type == "ARMATURE"
    ]
    if len(armatures) != 1:
        raise RuntimeError(f"{label}: expected one armature, found {[obj.name for obj in armatures]}")
    actions = {
        action.name: action
        for action in bpy.data.actions
        if action not in before_actions
    }
    imported_objects = [
        obj for obj in bpy.context.scene.objects if obj not in before_objects
    ]
    return armatures[0], actions, imported_objects


def clear_action_keys(action: bpy.types.Action) -> None:
    for curve in action.fcurves:
        curve.keyframe_points.clear()


def reset_pose(armature: bpy.types.Object) -> None:
    for bone in armature.pose.bones:
        bone.matrix_basis = Matrix.Identity(4)


def rotation_delta(
    source: bpy.types.Object,
    source_bone: str,
    influence: float,
) -> Quaternion:
    rest = source.data.bones[source_bone].matrix_local.to_quaternion()
    posed = source.pose.bones[source_bone].matrix.to_quaternion()
    delta = posed @ rest.inverted()
    if influence < 0.999999:
        delta = Quaternion().slerp(delta, influence)
    return delta


def apply_retarget_pose(
    target: bpy.types.Object,
    source: bpy.types.Object,
) -> None:
    reset_pose(target)
    bpy.context.view_layer.update()
    for target_name, source_name, influence in BONE_MAP:
        target_bone = target.pose.bones[target_name]
        delta = rotation_delta(source, source_name, influence)
        desired_rotation = delta @ target.data.bones[target_name].matrix_local.to_quaternion()
        desired = target_bone.matrix.copy()
        desired.translation = target_bone.head
        desired @= Matrix.Identity(4)
        desired = Matrix.Translation(target_bone.head) @ desired_rotation.to_matrix().to_4x4()
        target_bone.matrix = desired
        bpy.context.view_layer.update()


def bake_action(
    target: bpy.types.Object,
    source: bpy.types.Object,
    source_action: bpy.types.Action,
    logical_name: str,
) -> tuple[bpy.types.Action, list[float]]:
    source_frames = source_keyframes(source_action)
    if not source_frames:
        raise RuntimeError(f"{source_action.name}: no source keyframes")
    template = bpy.data.actions["A_TPose"]
    baked = template.copy()
    baked.name = f"KayKit_{logical_name}"
    baked.use_fake_user = True
    clear_action_keys(baked)
    assign_action(source, source_action)
    assign_action(target, baked)
    target_bones = [bone.name for bone in target.pose.bones]
    for output_frame, source_frame in enumerate(source_frames):
        set_scene_frame(bpy.context.scene, source_frame)
        bpy.context.view_layer.update()
        apply_retarget_pose(target, source)
        for bone_name in target_bones:
            bone = target.pose.bones[bone_name]
            bone.rotation_mode = "QUATERNION"
            bone.keyframe_insert("location", frame=output_frame, group=bone_name)
            bone.keyframe_insert("rotation_quaternion", frame=output_frame, group=bone_name)
            bone.keyframe_insert("scale", frame=output_frame, group=bone_name)
    return baked, source_frames


def main() -> None:
    args = parse_args()
    target = bpy.data.objects["Armature"]
    ranged_rig, ranged_actions, ranged_objects = import_library(args.ranged, "ranged")
    melee_rig, melee_actions, melee_objects = import_library(args.melee, "melee")
    libraries = {
        "ranged": (ranged_rig, ranged_actions),
        "melee": (melee_rig, melee_actions),
    }
    manifest = {
        "schema": 1,
        "source": "KayKit Character Animations 1.1",
        "license": "CC0-1.0",
        "source_pages": {
            "animations": "https://kaylousberg.itch.io/kaykit-character-animations",
            "equipment": "https://kaylousberg.itch.io/kaykit-adventurers",
        },
        "archives": {
            "KayKit_Character_Animations_1.1.zip": {
                "sha256": "65882f31f905ad2e953819648a59287cdeab8f623908d5ef701971d3758be20f",
            },
            "KayKit_Adventurers_2.0_FREE.zip": {
                "sha256": "abe48f4763fba0896bab486ee9e6d08ca6b5b3884b9601f235c8847ae94dc479",
            },
        },
        "source_fps": 30,
        "target_armature": target.name,
        "actions": {},
    }
    for logical_name, (library_name, source_name, loop) in ACTION_SPECS.items():
        source_rig, actions = libraries[library_name]
        if source_name not in actions:
            raise RuntimeError(f"Missing KayKit action {source_name}; available={sorted(actions)}")
        baked, source_frames = bake_action(
            target,
            source_rig,
            actions[source_name],
            logical_name,
        )
        manifest["actions"][logical_name] = {
            "source_action": source_name,
            "target_action": baked.name,
            "frames": len(source_frames),
            "loop": loop,
            "duration_seconds": round((len(source_frames) - 1) / 30.0, 6),
        }
    for obj in ranged_objects + melee_objects:
        if obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)
    for action in list(ranged_actions.values()) + list(melee_actions.values()):
        if action.name in bpy.data.actions and action.users == 0:
            bpy.data.actions.remove(action)
    assign_action(target, bpy.data.actions["KayKit_bow_idle"])
    bpy.context.scene.render.fps = 30
    args.blend_output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.blend_output.resolve()), compress=True)
    args.manifest_output.parent.mkdir(parents=True, exist_ok=True)
    args.manifest_output.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps({"status": "ok", "manifest": manifest}))


if __name__ == "__main__":
    main()
