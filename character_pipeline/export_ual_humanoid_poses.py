"""Export selected UAL actions as direction-neutral joint tracks.

The output contains projected, normalized joints rather than rendered pixels.
That lets Dreadbound retarget one action to the authored base_humanoid_v2
split-parts body and every compatible clothing skin.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


DIRECTIONS = {
    "front": 0.0,
    "left": 270.0,
    "back": 180.0,
    "right": 90.0,
}
JOINT_BONES = {
    "hips": ("pelvis", "head"),
    "torso": ("spine_03", "head"),
    "head": ("Head", "tail"),
    "left_shoulder": ("upperarm_l", "head"),
    "left_elbow": ("lowerarm_l", "head"),
    "left_hand": ("hand_l", "head"),
    "right_shoulder": ("upperarm_r", "head"),
    "right_elbow": ("lowerarm_r", "head"),
    "right_hand": ("hand_r", "head"),
    "left_hip": ("thigh_l", "head"),
    "left_knee": ("calf_l", "head"),
    "left_foot": ("foot_l", "tail"),
    "right_hip": ("thigh_r", "head"),
    "right_knee": ("calf_r", "head"),
    "right_foot": ("foot_r", "tail"),
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--animations", required=True, type=Path)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args(argv)


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (bpy.data.armatures, bpy.data.meshes, bpy.data.materials):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def import_glb(path: Path) -> bpy.types.Object:
    bpy.ops.import_scene.gltf(filepath=str(path))
    armatures = [
        obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"
    ]
    if len(armatures) != 1:
        raise RuntimeError(
            f"Expected one animation armature, found {[obj.name for obj in armatures]}"
        )
    return armatures[0]


def action_by_name(name: str) -> bpy.types.Action:
    for action in bpy.data.actions:
        if action.name == name:
            return action
    partial_matches = [
        action for action in bpy.data.actions if name in action.name
    ]
    if len(partial_matches) == 1:
        return partial_matches[0]
    if partial_matches:
        raise KeyError(
            f"Ambiguous action {name}; matches={[a.name for a in partial_matches]}"
        )
    for action in bpy.data.actions:
        if name.casefold() == action.name.casefold():
            return action
    raise KeyError(f"Missing action {name}; available={[a.name for a in bpy.data.actions]}")


def assign_action(armature: bpy.types.Object, action: bpy.types.Action) -> None:
    armature.animation_data_create()
    armature.animation_data.action = action
    compatible = [
        slot for slot in action.slots if slot.target_id_type == "OBJECT"
    ]
    if len(compatible) != 1:
        raise RuntimeError(
            f"Action {action.name} needs one OBJECT slot, found "
            f"{[slot.identifier for slot in compatible]}"
        )
    armature.animation_data.action_slot = compatible[0]


def projected_joint(
    armature: bpy.types.Object,
    bone_name: str,
    endpoint: str,
    yaw: Matrix,
) -> Vector:
    bone = armature.pose.bones[bone_name]
    point = bone.head if endpoint == "head" else bone.tail
    world = yaw @ armature.matrix_world @ point
    return Vector((world.x, -world.z))


def sample_pose(
    armature: bpy.types.Object,
    yaw_degrees: float,
) -> dict[str, list[float]]:
    yaw = Matrix.Rotation(math.radians(yaw_degrees), 4, "Z")
    projected = {
        name: projected_joint(armature, bone, endpoint, yaw)
        for name, (bone, endpoint) in JOINT_BONES.items()
    }
    feet_y = (projected["left_foot"].y + projected["right_foot"].y) * 0.5
    body_height = max(0.001, feet_y - projected["head"].y)
    center_x = (projected["left_hip"].x + projected["right_hip"].x) * 0.5
    return {
        name: [
            round((point.x - center_x) / body_height, 6),
            round((point.y - feet_y) / body_height, 6),
        ]
        for name, point in projected.items()
    }


def source_keyframes(action: bpy.types.Action) -> list[float]:
    """Return the exact baked source sample positions.

    The Quaternius GLB is sampled at 30 Hz. Blender imports those timestamps
    into its 24 FPS scene as 0.8-frame increments, so rounding to integer
    Blender frames or resampling to a fixed count changes both the pose count
    and the original animation timing.
    """
    return sorted(
        {
            round(float(key.co.x), 6)
            for curve in action.fcurves
            for key in curve.keyframe_points
        }
    )


def source_fps(frame_positions: list[float], scene_fps: float) -> float:
    deltas = [
        current - previous
        for previous, current in zip(frame_positions, frame_positions[1:])
        if current - previous > 0.000001
    ]
    if not deltas:
        return scene_fps
    measured = scene_fps / min(deltas)
    nearest_integer = round(measured)
    return (
        float(nearest_integer)
        if abs(measured - nearest_integer) < 0.001
        else measured
    )


def set_scene_frame(scene: bpy.types.Scene, frame: float) -> None:
    whole = math.floor(frame)
    scene.frame_set(whole, subframe=frame - whole)


def main() -> None:
    args = parse_args()
    config = json.loads(args.config.read_text(encoding="utf-8"))
    clear_scene()
    armature = import_glb(args.animations.resolve())
    scene = bpy.context.scene
    result = {
        "schema_version": 1,
        "skeleton_id": config["skeleton_id"],
        "coordinate_space": "normalized_projected_joints",
        "directions": list(DIRECTIONS),
        "actions": {},
    }
    for logical_name, spec in config["reuse_actions"].items():
        action = action_by_name(spec["source"])
        assign_action(armature, action)
        frames = source_keyframes(action)
        fps = source_fps(frames, float(scene.render.fps) / scene.render.fps_base)
        tracks = {direction: [] for direction in DIRECTIONS}
        for frame in frames:
            set_scene_frame(scene, frame)
            bpy.context.view_layer.update()
            for direction, yaw in DIRECTIONS.items():
                tracks[direction].append(sample_pose(armature, yaw))
        duration_seconds = (
            (frames[-1] - frames[0])
            / (float(scene.render.fps) / scene.render.fps_base)
            if len(frames) > 1
            else 0.0
        )
        result["actions"][logical_name] = {
            "source": "UAL1_Standard",
            "source_action": spec["source"],
            "family": spec["family"],
            "loop": bool(spec["loop"]),
            "fps": round(fps, 6),
            "frame_count": len(frames),
            "duration_seconds": round(duration_seconds, 6),
            "frames": tracks,
        }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "status": "ok",
                "actions": len(result["actions"]),
                "directions": len(DIRECTIONS),
                "timing_policy": "preserve_source_keyframes",
                "output": str(args.output),
            }
        )
    )


if __name__ == "__main__":
    main()
