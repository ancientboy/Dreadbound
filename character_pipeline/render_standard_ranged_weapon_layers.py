#!/usr/bin/env python3
"""Render synchronized pistol and staff layers for the character action demo.

The weapon meshes are parented to ``hand_r`` in
``dreadbound_weapon_actions.blend``.  The embedded mannequin renders as a
Cycles holdout, so each RGBA atlas keeps correct body occlusion without
duplicating the character pixels.
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
from render_standard_melee_weapon import (
    DIRECTIONS,
    FRAME_SIZE,
    add_box,
    assign_action,
    configure_scene,
    material,
    move_to_collection,
    pack_horizontal,
    set_character_holdout,
)


WEAPON_ACTIONS = {
    "pistol": {
        "weapon_id": "standard_service_pistol",
        "file_prefix": "standard_pistol",
        "animations": {
            "pistol_idle": ("Pistol_Idle_Loop", 0, 40, 2, True),
            "pistol_aim_down": ("Pistol_Aim_Down", 0, 4, 2, False),
            "pistol_aim": ("Pistol_Aim_Neutral", 0, 4, 2, False),
            "pistol_aim_up": ("Pistol_Aim_Up", 0, 4, 2, False),
            "pistol_shoot": ("Pistol_Shoot", 0, 15, 2, False),
            "pistol_reload": ("Pistol_Reload", 0, 40, 2, False),
        },
    },
    "staff": {
        "weapon_id": "standard_echo_staff",
        "file_prefix": "standard_staff",
        "animations": {
            "spell_enter": ("Spell_Simple_Enter", 0, 12, 2, False),
            "spell_idle": ("Spell_Simple_Idle_Loop", 0, 50, 2, True),
            "spell_shoot": ("Spell_Simple_Shoot", 0, 12, 2, False),
            "spell_exit": ("Spell_Simple_Exit", 0, 10, 2, False),
        },
    },
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", required=True, type=Path)
    parser.add_argument("--preview-output", type=Path)
    parser.add_argument("--preview-only", action="store_true")
    parser.add_argument(
        "--families",
        nargs="+",
        choices=tuple(WEAPON_ACTIONS),
        default=list(WEAPON_ACTIONS),
    )
    return parser.parse_args(argv)


def collection_for(name: str) -> bpy.types.Collection:
    old = bpy.data.collections.get(name)
    if old is not None:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old)
    value = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(value)
    return value


def parent_to_hand(
    root: bpy.types.Object,
    armature: bpy.types.Object,
    rotation_degrees: tuple[float, float, float],
    location: tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> None:
    root.parent = armature
    root.parent_type = "BONE"
    root.parent_bone = "hand_r"
    root.location = location
    root.rotation_mode = "XYZ"
    root.rotation_euler = tuple(math.radians(value) for value in rotation_degrees)


def add_cylinder(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    value: bpy.types.Material,
    collection: bpy.types.Collection,
    rotation: tuple[float, float, float] = (math.pi / 2.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(value)
    move_to_collection(obj, collection)
    return obj


def build_pistol(armature: bpy.types.Object) -> tuple[bpy.types.Object, bpy.types.Collection]:
    collection = collection_for("Dreadbound Standard Service Pistol")
    dark = material("Pistol Dark Metal", (0.035, 0.055, 0.075, 1.0), 0.82, 0.25)
    slide = material("Pistol Slide", (0.16, 0.25, 0.31, 1.0), 0.88, 0.19)
    edge = material("Pistol Edge", (0.32, 0.62, 0.70, 1.0), 0.74, 0.2)
    grip = material("Pistol Grip", (0.055, 0.045, 0.04, 1.0), 0.05, 0.78)

    root = bpy.data.objects.new("Standard Service Pistol Root", None)
    collection.objects.link(root)
    pieces = [
        # Local +Y is the muzzle direction; the bone already follows the hand.
        add_box("Pistol Grip", (0.0, -0.035, -0.075), (0.038, 0.052, 0.09), 0.012, grip, collection),
        add_box("Pistol Frame", (0.0, 0.055, 0.018), (0.047, 0.145, 0.052), 0.014, dark, collection),
        add_box("Pistol Slide", (0.0, 0.075, 0.075), (0.052, 0.165, 0.032), 0.009, slide, collection),
        add_box("Pistol Sight", (0.0, 0.02, 0.115), (0.015, 0.018, 0.015), 0.004, edge, collection),
        add_box("Pistol Sight Front", (0.0, 0.215, 0.115), (0.014, 0.014, 0.016), 0.003, edge, collection),
        add_cylinder("Pistol Barrel", (0.0, 0.245, 0.06), 0.026, 0.075, dark, collection),
        add_cylinder("Pistol Muzzle", (0.0, 0.286, 0.06), 0.034, 0.012, edge, collection),
    ]
    for piece in pieces:
        piece.parent = root
    parent_to_hand(root, armature, (0.0, 0.0, 0.0), (0.0, 0.015, 0.0))
    return root, collection


def build_staff(armature: bpy.types.Object) -> tuple[bpy.types.Object, bpy.types.Collection]:
    collection = collection_for("Dreadbound Standard Echo Staff")
    shaft = material("Staff Shaft", (0.10, 0.065, 0.045, 1.0), 0.12, 0.68)
    metal = material("Staff Metal", (0.20, 0.34, 0.42, 1.0), 0.78, 0.22)
    rune = material("Staff Rune", (0.18, 0.68, 0.82, 1.0), 0.25, 0.18)
    rune.use_nodes = True
    rune_shader = rune.node_tree.nodes.get("Principled BSDF")
    rune_shader.inputs["Emission Color"].default_value = (0.03, 0.44, 0.75, 1.0)
    rune_shader.inputs["Emission Strength"].default_value = 3.0

    root = bpy.data.objects.new("Standard Echo Staff Root", None)
    collection.objects.link(root)
    pieces = [
        # Grip is the local origin; +Y rises toward the focus crystal.
        add_cylinder("Staff Shaft", (0.0, 0.28, 0.0), 0.025, 1.50, shaft, collection),
        add_cylinder("Staff Lower Cap", (0.0, -0.49, 0.0), 0.045, 0.09, metal, collection),
        add_cylinder("Staff Upper Collar", (0.0, 1.01, 0.0), 0.055, 0.10, metal, collection),
    ]
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.12, location=(0.0, 1.16, 0.0))
    focus = bpy.context.object
    focus.name = "Staff Echo Crystal"
    focus.scale = (0.78, 1.18, 0.78)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    focus.data.materials.append(rune)
    move_to_collection(focus, collection)
    pieces.append(focus)
    for x_value in (-0.115, 0.115):
        prong = add_box(
            "Staff Focus Prong",
            (x_value, 1.09, 0.0),
            (0.022, 0.16, 0.022),
            0.008,
            metal,
            collection,
        )
        prong.rotation_euler.z = math.radians(-18.0 if x_value < 0.0 else 18.0)
        pieces.append(prong)
    for piece in pieces:
        piece.parent = root
    # Rotate the long local axis across the palm into the staff's upright axis.
    parent_to_hand(root, armature, (90.0, 0.0, -8.0))
    return root, collection


def set_scene_visibility(
    visible_collection: bpy.types.Collection,
    all_weapon_collections: list[bpy.types.Collection],
) -> None:
    keep = {"Armature", "Mannequin"}
    visible_objects = set(visible_collection.objects)
    for obj in bpy.context.scene.objects:
        if obj.name in keep:
            obj.hide_render = False
        elif obj in visible_objects:
            obj.hide_render = False
        elif obj.type not in {"CAMERA", "LIGHT"}:
            obj.hide_render = True
    for collection in all_weapon_collections:
        collection.hide_render = collection != visible_collection


def render_family(
    family: str,
    output_root: Path,
    preview_output: Path | None,
    armature: bpy.types.Object,
    mannequin: bpy.types.Object,
    base_armature_matrix: Matrix,
    collection: bpy.types.Collection,
    all_collections: list[bpy.types.Collection],
    preview_only: bool,
) -> dict:
    spec = WEAPON_ACTIONS[family]
    output = output_root / spec["weapon_id"]
    output.mkdir(parents=True, exist_ok=True)
    temp = output / "_frames"
    manifest = {
        "schema": 1,
        "weapon_id": spec["weapon_id"],
        "source": "bone_parented_blender_weapon_layer",
        "frame_size": list(FRAME_SIZE),
        "fps": bpy.context.scene.render.fps,
        "bone": "hand_r",
        "directions": list(DIRECTIONS),
        "animations": {},
    }
    set_scene_visibility(collection, all_collections)
    for logical_name, action_spec in spec["animations"].items():
        source_action, start, end, step, loop = action_spec
        assign_action(armature, source_action)
        frames = list(range(start, end + 1, step))
        manifest["animations"][logical_name] = {
            "frames": len(frames),
            "loop": loop,
            "source_action": source_action,
        }
        if preview_only:
            continue
        for direction, yaw in DIRECTIONS.items():
            paths: list[Path] = []
            frame_dir = temp / logical_name / direction
            frame_dir.mkdir(parents=True, exist_ok=True)
            for index, frame in enumerate(frames):
                bpy.context.scene.frame_set(frame)
                armature.matrix_world = (
                    Matrix.Rotation(math.radians(yaw), 4, "Z")
                    @ base_armature_matrix
                )
                set_character_holdout(mannequin, True)
                path = frame_dir / f"{index:03d}.png"
                bpy.context.scene.render.filepath = str(path)
                bpy.ops.render.render(write_still=True)
                paths.append(path)
            pack_horizontal(
                paths,
                output / f"{spec['file_prefix']}_{logical_name}_{direction}.png",
            )
    if preview_output is not None:
        preview_output.mkdir(parents=True, exist_ok=True)
        preview_action = (
            spec["animations"]["pistol_aim"]
            if family == "pistol"
            else spec["animations"]["spell_idle"]
        )
        assign_action(armature, preview_action[0])
        preview_frame = preview_action[2] // 2
        for direction, yaw in DIRECTIONS.items():
            bpy.context.scene.frame_set(preview_frame)
            armature.matrix_world = (
                Matrix.Rotation(math.radians(yaw), 4, "Z")
                @ base_armature_matrix
            )
            set_character_holdout(mannequin, False)
            bpy.context.scene.render.filepath = str(
                preview_output / f"{family}_{direction}.png"
            )
            bpy.ops.render.render(write_still=True)
    with (output / "manifest.json").open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    return manifest


def main() -> None:
    args = parse_args()
    armature = bpy.data.objects["Armature"]
    mannequin = bpy.data.objects["Mannequin"]
    configure_scene(mannequin)
    pistol_root, pistol_collection = build_pistol(armature)
    staff_root, staff_collection = build_staff(armature)
    roots = {"pistol": pistol_root, "staff": staff_root}
    collections = {"pistol": pistol_collection, "staff": staff_collection}
    base_armature_matrix = armature.matrix_world.copy()
    manifests = {}
    for family in args.families:
        manifests[family] = render_family(
            family,
            args.output_root.resolve(),
            args.preview_output.resolve() if args.preview_output else None,
            armature,
            mannequin,
            base_armature_matrix,
            collections[family],
            list(collections.values()),
            args.preview_only,
        )
        roots[family].select_set(True)
    print(json.dumps({"status": "ok", "manifests": manifests}))


if __name__ == "__main__":
    main()
