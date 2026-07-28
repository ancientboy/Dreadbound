#!/usr/bin/env python3
"""Author Dreadbound weapon actions on the UAL armature inside Blender.

This script is intentionally Blender-only. It imports the original UAL GLB,
builds dimensioned bow/staff/shield reference props, poses the original
armature with two-bone IK, bakes each approved weapon action one at a time,
and appends projected joint tracks to the Godot runtime library.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
from export_ual_humanoid_poses import (
    DIRECTIONS,
    action_by_name,
    assign_action,
    clear_scene,
    import_glb,
    sample_pose,
    set_scene_frame,
    source_fps,
    source_keyframes,
)


AUTHORING_RIG = "blender_weapon_rig_v1"
ARM_BONES = (
    "clavicle_l",
    "upperarm_l",
    "lowerarm_l",
    "hand_l",
    "clavicle_r",
    "upperarm_r",
    "lowerarm_r",
    "hand_r",
)

# Explicit armature-space wrist targets. Blender interpolates between these
# hand-authored contact poses; no runtime joint formula generates the motion.
ACTION_CONTACTS = {
    "bow_idle": {
        "left": [(0.0, (0.34, -0.35, 1.35)), (0.5, (0.35, -0.36, 1.36)), (1.0, (0.34, -0.35, 1.35))],
        "right": [(0.0, (-0.03, -0.17, 1.31)), (0.5, (-0.02, -0.18, 1.32)), (1.0, (-0.03, -0.17, 1.31))],
    },
    "bow_draw": {
        "left": [(0.0, (0.28, -0.25, 1.27)), (0.35, (0.35, -0.42, 1.39)), (1.0, (0.35, -0.47, 1.43))],
        "right": [(0.0, (-0.01, -0.16, 1.28)), (0.35, (0.05, -0.30, 1.39)), (1.0, (-0.13, -0.06, 1.47))],
    },
    "bow_release": {
        "left": [(0.0, (0.28, -0.25, 1.27)), (0.30, (0.35, -0.43, 1.40)), (0.72, (0.35, -0.47, 1.43)), (1.0, (0.30, -0.29, 1.31))],
        "right": [(0.0, (-0.01, -0.16, 1.28)), (0.30, (0.04, -0.29, 1.39)), (0.56, (-0.13, -0.06, 1.47)), (0.72, (-0.17, -0.01, 1.48)), (1.0, (-0.02, -0.16, 1.30))],
    },
    "shield_idle": {
        "left": [(0.0, (0.23, -0.31, 1.28)), (0.5, (0.24, -0.32, 1.29)), (1.0, (0.23, -0.31, 1.28))],
    },
    "shield_block": {
        "left": [(0.0, (0.23, -0.31, 1.28)), (0.28, (0.10, -0.45, 1.40)), (0.72, (0.07, -0.48, 1.44)), (1.0, (0.23, -0.31, 1.28))],
    },
    "spell_enter": {
        "right": [(0.0, (-0.13, -0.10, 1.22)), (0.55, (-0.23, -0.18, 1.12)), (1.0, (-0.25, -0.20, 1.10))],
    },
    "spell_idle": {
        "right": [(0.0, (-0.25, -0.20, 1.10)), (0.5, (-0.24, -0.21, 1.12)), (1.0, (-0.25, -0.20, 1.10))],
    },
    "spell_shoot": {
        "right": [(0.0, (-0.25, -0.20, 1.10)), (0.42, (-0.29, -0.34, 1.24)), (0.72, (-0.30, -0.38, 1.27)), (1.0, (-0.25, -0.20, 1.10))],
    },
    "spell_exit": {
        "right": [(0.0, (-0.25, -0.20, 1.10)), (0.45, (-0.21, -0.16, 1.16)), (1.0, (-0.13, -0.10, 1.22))],
    },
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--animations", required=True, type=Path)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--tracks", required=True, type=Path)
    parser.add_argument("--blend-output", required=True, type=Path)
    return parser.parse_args(argv)


def add_material(name: str, color: tuple[float, float, float, float]):
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    return material


def add_cylinder_between(
    name: str,
    start: Vector,
    end: Vector,
    radius: float,
    material,
    collection,
):
    delta = end - start
    bpy.ops.mesh.primitive_cylinder_add(vertices=16, radius=radius, depth=delta.length)
    obj = bpy.context.object
    obj.name = name
    obj.location = (start + end) * 0.5
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(delta.normalized())
    obj.data.materials.append(material)
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def add_marker(name: str, location: Vector, material, collection):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=0.025, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    collection.objects.link(obj)
    return obj


def build_reference_weapons():
    collection = bpy.data.collections.new("Dreadbound Reference Weapons")
    bpy.context.scene.collection.children.link(collection)
    bow_mat = add_material("Bow Reference", (0.12, 0.55, 0.75, 1.0))
    string_mat = add_material("Bow String", (0.8, 0.9, 1.0, 1.0))
    staff_mat = add_material("Staff Reference", (0.5, 0.2, 0.8, 1.0))
    shield_mat = add_material("Shield Reference", (0.15, 0.35, 0.55, 1.0))
    marker_mat = add_material("Contact Markers", (1.0, 0.25, 0.05, 1.0))

    # Bow: 1.25 m total height, centered grip, explicit string and nock points.
    bow_points = [
        Vector((0.0, 0.0, -0.625)),
        Vector((0.10, 0.0, -0.34)),
        Vector((0.13, 0.0, 0.0)),
        Vector((0.10, 0.0, 0.34)),
        Vector((0.0, 0.0, 0.625)),
    ]
    for index, (start, end) in enumerate(zip(bow_points, bow_points[1:])):
        add_cylinder_between(f"Bow Limb {index + 1}", start, end, 0.016, bow_mat, collection)
    add_cylinder_between("Bow String Lower", bow_points[0], Vector((0.13, 0.0, 0.0)), 0.004, string_mat, collection)
    add_cylinder_between("Bow String Upper", Vector((0.13, 0.0, 0.0)), bow_points[-1], 0.004, string_mat, collection)
    add_marker("Bow Grip", Vector((0.13, 0.0, 0.0)), marker_mat, collection)
    add_marker("Bow String Point", Vector((0.13, 0.0, 0.0)), marker_mat, collection)
    add_marker("Arrow Nock Point", Vector((0.13, 0.0, 0.0)), marker_mat, collection)

    # Staff: 1.65 m with a marked right-hand grip 0.42 m from the lower end.
    add_cylinder_between("Standard Staff", Vector((1.1, 0.0, -0.825)), Vector((1.1, 0.0, 0.825)), 0.025, staff_mat, collection)
    add_marker("Staff Grip", Vector((1.1, 0.0, -0.405)), marker_mat, collection)

    # Shield: 0.62 x 0.78 m, centered hand grip.
    bpy.ops.mesh.primitive_cube_add(location=(-1.0, 0.0, 0.0), scale=(0.31, 0.035, 0.39))
    shield = bpy.context.object
    shield.name = "Standard Shield"
    shield.data.materials.append(shield_mat)
    for current in list(shield.users_collection):
        current.objects.unlink(shield)
    collection.objects.link(shield)
    add_marker("Shield Grip", Vector((-1.0, -0.055, 0.0)), marker_mat, collection)
    return collection


def interpolate_contacts(points, phase: float) -> Vector:
    if phase <= points[0][0]:
        return Vector(points[0][1])
    for (start_phase, start), (end_phase, end) in zip(points, points[1:]):
        if phase <= end_phase:
            weight = (phase - start_phase) / max(0.000001, end_phase - start_phase)
            # Smoothstep is Blender's equivalent of easing between authored keys.
            weight = weight * weight * (3.0 - 2.0 * weight)
            return Vector(start).lerp(Vector(end), weight)
    return Vector(points[-1][1])


def create_ik_target(name: str, location: Vector, collection):
    target = bpy.data.objects.new(name, None)
    target.empty_display_type = "SPHERE"
    target.empty_display_size = 0.06
    target.location = location
    collection.objects.link(target)
    return target


def apply_arm_ik(armature, action_name: str, phase: float, controls):
    contacts = ACTION_CONTACTS[action_name]
    for side, points in contacts.items():
        target = controls[side]
        target.location = interpolate_contacts(points, phase)
        lowerarm = armature.pose.bones[f"lowerarm_{side[0]}"]
        constraint = lowerarm.constraints.get(f"Dreadbound {side.title()} Hand IK")
        if constraint is None:
            constraint = lowerarm.constraints.new("IK")
            constraint.name = f"Dreadbound {side.title()} Hand IK"
            constraint.target = target
            constraint.chain_count = 2
            constraint.use_tail = True
            constraint.influence = 1.0


def clear_arm_ik(armature):
    for side in ("l", "r"):
        lowerarm = armature.pose.bones[f"lowerarm_{side}"]
        for constraint in list(lowerarm.constraints):
            if constraint.name.startswith("Dreadbound "):
                lowerarm.constraints.remove(constraint)


def bake_authored_action(
    armature,
    logical_name: str,
    pose_action,
    target_frames,
    controls,
):
    source_action = action_by_name(pose_action["source_action"])
    source_frames = source_keyframes(source_action)
    working_action = source_action.copy()
    working_action.name = f"Dreadbound_{logical_name}"
    working_action.use_fake_user = True
    assign_action(armature, working_action)

    sampled_matrices = []
    for index, target_frame in enumerate(target_frames):
        phase = index / max(1, len(target_frames) - 1)
        pose_frame = source_frames[0] + phase * (source_frames[-1] - source_frames[0])
        set_scene_frame(bpy.context.scene, pose_frame)
        apply_arm_ik(armature, logical_name, phase, controls)
        bpy.context.view_layer.update()
        sampled_matrices.append(
            {bone_name: armature.pose.bones[bone_name].matrix.copy() for bone_name in ARM_BONES}
        )

    clear_arm_ik(armature)
    assign_action(armature, working_action)
    for frame, matrices in zip(target_frames, sampled_matrices):
        set_scene_frame(bpy.context.scene, frame)
        for bone_name, matrix in matrices.items():
            bone = armature.pose.bones[bone_name]
            bone.matrix = matrix
            bone.rotation_mode = "QUATERNION"
            bone.keyframe_insert("location", frame=frame, group=bone_name)
            bone.keyframe_insert("rotation_quaternion", frame=frame, group=bone_name)
            bone.keyframe_insert("scale", frame=frame, group=bone_name)
    return working_action


def main() -> None:
    args = parse_args()
    config = json.loads(args.config.read_text(encoding="utf-8"))
    tracks = json.loads(args.tracks.read_text(encoding="utf-8"))
    clear_scene()
    armature = import_glb(args.animations.resolve())
    build_reference_weapons()

    control_collection = bpy.data.collections.new("Dreadbound Weapon IK Controls")
    bpy.context.scene.collection.children.link(control_collection)
    controls = {
        "left": create_ik_target("Left Hand IK", Vector((0.3, -0.3, 1.3)), control_collection),
        "right": create_ik_target("Right Hand IK", Vector((-0.1, -0.2, 1.3)), control_collection),
    }

    action_specs = {
        **config["authored_actions"],
        **config["blender_calibrated_actions"],
    }
    for logical_name, spec in action_specs.items():
        if spec["authoring"] != AUTHORING_RIG:
            raise RuntimeError(f"{logical_name} is not assigned to {AUTHORING_RIG}")
        timing = tracks["actions"][spec["timing_action"]]
        pose = tracks["actions"][spec["pose_action"]]
        timing_source = action_by_name(timing["source_action"])
        frames = source_keyframes(timing_source)
        action = bake_authored_action(
            armature,
            logical_name,
            pose,
            frames,
            controls,
        )
        assign_action(armature, action)
        directional = {direction: [] for direction in DIRECTIONS}
        for frame in frames:
            set_scene_frame(bpy.context.scene, frame)
            bpy.context.view_layer.update()
            for direction, yaw in DIRECTIONS.items():
                directional[direction].append(sample_pose(armature, yaw))
        fps = source_fps(
            frames,
            float(bpy.context.scene.render.fps) / bpy.context.scene.render.fps_base,
        )
        tracks["actions"][logical_name] = {
            "source": "Dreadbound_Blender",
            "source_action": action.name,
            "family": spec["family"],
            "loop": bool(spec.get("loop", timing["loop"])),
            "authoring_rig": AUTHORING_RIG,
            "reference_weapon": spec["reference_weapon"],
            "pose_action": spec["pose_action"],
            "timing_action": spec["timing_action"],
            "fps": round(fps, 6),
            "frame_count": len(frames),
            "duration_seconds": timing["duration_seconds"],
            "frames": directional,
        }

    tracks["action_count"] = len(tracks["actions"])
    args.tracks.write_text(
        json.dumps(tracks, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    args.blend_output.parent.mkdir(parents=True, exist_ok=True)
    assign_action(armature, bpy.data.actions["Dreadbound_bow_release"])
    bpy.context.scene.frame_set(8)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.blend_output), compress=True)
    print(
        json.dumps(
            {
                "status": "ok",
                "authored_actions": list(config["authored_actions"]),
                "calibrated_actions": list(config["blender_calibrated_actions"]),
                "total_actions": tracks["action_count"],
                "blend": str(args.blend_output),
                "tracks": str(args.tracks),
            }
        )
    )


if __name__ == "__main__":
    main()
