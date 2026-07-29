#!/usr/bin/env python3
"""Render KayKit-motion bow/shield actions on Dreadbound's existing character.

The script opens ``dreadbound_weapon_actions.blend`` (via Blender's CLI),
imports the approved Quaternius character only for the final body render, and
imports KayKit's CC0 bow/arrow/shield meshes as synchronized transparent
equipment layers.  KayKit's mannequin is never rendered.
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
from export_ual_humanoid_poses import assign_action
from render_directional_sprites import (
    DIRECTIONS,
    configure_scene,
    import_character,
    load_preset,
)
from render_standard_melee_weapon import pelvis_heading


FRAME_SIZE = (128, 128)
ATLAS_COLUMNS = 28
ACTION_SPECS = {
    "bow_idle": {"frames": 48, "loop": True, "family": "bow"},
    "bow_draw": {"frames": 41, "loop": False, "family": "bow"},
    "bow_aim": {"frames": 56, "loop": True, "family": "bow"},
    "bow_release": {"frames": 41, "loop": False, "family": "bow"},
    "shield_raise": {"frames": 33, "loop": False, "family": "shield"},
    "shield_block": {"frames": 33, "loop": True, "family": "shield"},
    "shield_hit": {"frames": 33, "loop": False, "family": "shield"},
    "shield_bash": {"frames": 33, "loop": False, "family": "shield"},
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", required=True, type=Path)
    parser.add_argument("--preset", required=True, type=Path)
    parser.add_argument("--bow", required=True, type=Path)
    parser.add_argument("--arrow", required=True, type=Path)
    parser.add_argument("--shield", required=True, type=Path)
    parser.add_argument("--kaykit-rig", required=True, type=Path)
    parser.add_argument("--body-output", required=True, type=Path)
    parser.add_argument("--weapon-output-root", required=True, type=Path)
    parser.add_argument("--preview-output", type=Path)
    parser.add_argument("--preview-only", action="store_true")
    return parser.parse_args(argv)


def imported_objects(path: Path) -> list[bpy.types.Object]:
    before = set(bpy.context.scene.objects)
    import_character(path.resolve())
    return [obj for obj in bpy.context.scene.objects if obj not in before]


def only_armature(objects: list[bpy.types.Object]) -> bpy.types.Object:
    armatures = [obj for obj in objects if obj.type == "ARMATURE"]
    if len(armatures) != 1:
        raise RuntimeError(f"Expected one imported armature, found {[obj.name for obj in armatures]}")
    return armatures[0]


def import_mesh(path: Path, name: str) -> tuple[bpy.types.Object, list[bpy.types.Object]]:
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(path.resolve()))
    objects = [obj for obj in bpy.context.scene.objects if obj not in before]
    meshes = [obj for obj in objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError(f"No mesh imported from {path}")
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for obj in meshes:
        obj.parent = root
    return root, meshes


def remove_object_tree(objects: list[bpy.types.Object]) -> None:
    for obj in objects:
        if obj.name in bpy.data.objects:
            bpy.data.objects.remove(obj, do_unlink=True)


def kaykit_slot_rotation(
    target: bpy.types.Object,
    source_path: Path,
    target_bone: str,
    source_slot: str,
) -> Matrix:
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(source_path.resolve()))
    imported = [obj for obj in bpy.context.scene.objects if obj not in before]
    source = only_armature(imported)
    target_rotation = target.data.bones[target_bone].matrix_local.to_quaternion()
    source_rotation = source.data.bones[source_slot].matrix_local.to_quaternion()
    calibration = target_rotation.inverted() @ source_rotation
    remove_object_tree(imported)
    return calibration.to_matrix().to_4x4()


def world_bone_point(
    armature: bpy.types.Object,
    bone_name: str,
    endpoint: str = "center",
) -> Vector:
    bone = armature.pose.bones[bone_name]
    if endpoint == "head":
        point = bone.head
    elif endpoint == "tail":
        point = bone.tail
    else:
        point = (bone.head + bone.tail) * 0.5
    return armature.matrix_world @ point


def basis_matrix(x_axis: Vector, y_axis: Vector, z_axis: Vector) -> Matrix:
    return Matrix(
        (
            (x_axis.x, y_axis.x, z_axis.x, 0.0),
            (x_axis.y, y_axis.y, z_axis.y, 0.0),
            (x_axis.z, y_axis.z, z_axis.z, 0.0),
            (0.0, 0.0, 0.0, 1.0),
        )
    )


def update_equipment_roots(
    family: str,
    armature: bpy.types.Object,
    bow_root: bpy.types.Object,
    shield_root: bpy.types.Object,
) -> None:
    up = Vector((0.0, 0.0, 1.0))
    left_hand = world_bone_point(armature, "hand_l")
    left_elbow = world_bone_point(armature, "lowerarm_l", "head")
    if family == "bow":
        right_hand = world_bone_point(armature, "hand_r")
        shot = left_hand - right_hand
        shot.z = 0.0
        if shot.length < 0.0001:
            shot = Vector((0.0, -1.0, 0.0))
        shot.normalize()
        side = shot.cross(up).normalized()
        bow_root.matrix_world = (
            Matrix.Translation(left_hand)
            @ basis_matrix(shot, up, side)
            @ Matrix.Diagonal((0.72, 0.72, 0.72, 1.0))
        )
    else:
        normal = left_hand - left_elbow
        normal.z = 0.0
        if normal.length < 0.0001:
            normal = Vector((0.0, -1.0, 0.0))
        normal.normalize()
        horizontal = normal.cross(up).normalized()
        shield_root.matrix_world = (
            Matrix.Translation(left_hand + normal * 0.075)
            @ basis_matrix(horizontal, normal, up)
            @ Matrix.Diagonal((0.72, 0.72, 0.72, 1.0))
        )


def make_string_piece(name: str) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(vertices=8, radius=0.006, depth=1.0)
    obj = bpy.context.object
    obj.name = name
    material = bpy.data.materials.get("Dreadbound Bow String")
    if material is None:
        material = bpy.data.materials.new("Dreadbound Bow String")
        material.diffuse_color = (0.18, 0.72, 0.82, 1.0)
        material.use_nodes = True
        shader = material.node_tree.nodes.get("Principled BSDF")
        shader.inputs["Base Color"].default_value = (0.025, 0.35, 0.48, 1.0)
        shader.inputs["Roughness"].default_value = 0.35
        shader.inputs["Emission Color"].default_value = (0.01, 0.16, 0.24, 1.0)
        shader.inputs["Emission Strength"].default_value = 1.2
    obj.data.materials.append(material)
    return obj


def place_between(obj: bpy.types.Object, start: Vector, end: Vector) -> None:
    delta = end - start
    obj.location = (start + end) * 0.5
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(delta.normalized())
    obj.scale = Vector((1.0, 1.0, delta.length))


def pack_grid(frame_paths: list[Path], atlas_path: Path, columns: int) -> tuple[int, int]:
    images = [bpy.data.images.load(str(path), check_existing=False) for path in frame_paths]
    width, height = images[0].size
    used_columns = min(columns, len(images))
    rows = math.ceil(len(images) / used_columns)
    atlas = bpy.data.images.new(
        atlas_path.stem,
        width=width * used_columns,
        height=height * rows,
        alpha=True,
    )
    atlas_pixels = [0.0] * (width * used_columns * height * rows * 4)
    atlas_width = width * used_columns
    for frame_index, image in enumerate(images):
        pixels = list(image.pixels)
        column = frame_index % used_columns
        row = frame_index // used_columns
        for y in range(height):
            source = y * width * 4
            target_y = row * height + y
            target = (target_y * atlas_width + column * width) * 4
            atlas_pixels[target : target + width * 4] = pixels[source : source + width * 4]
    atlas.pixels.foreach_set(atlas_pixels)
    atlas.filepath_raw = str(atlas_path)
    atlas.file_format = "PNG"
    atlas.save()
    bpy.data.images.remove(atlas)
    for image in images:
        bpy.data.images.remove(image)
    return used_columns, rows


def set_body_holdout(body_meshes: list[bpy.types.Object], enabled: bool) -> None:
    for obj in body_meshes:
        obj.hide_render = False
        obj.is_holdout = enabled


def set_family_visibility(
    family: str,
    bow_meshes: list[bpy.types.Object],
    shield_meshes: list[bpy.types.Object],
    strings: list[bpy.types.Object],
    arrow_meshes: list[bpy.types.Object],
    arrow_visible: bool,
) -> None:
    for obj in bow_meshes + strings:
        obj.hide_render = family != "bow"
    for obj in arrow_meshes:
        obj.hide_render = family != "bow" or not arrow_visible
    for obj in shield_meshes:
        obj.hide_render = family != "shield"


def update_bow_accessories(
    logical_name: str,
    frame: int,
    frame_count: int,
    bow_root: bpy.types.Object,
    armature: bpy.types.Object,
    strings: list[bpy.types.Object],
    arrow_root: bpy.types.Object,
) -> bool:
    phase = frame / max(1, frame_count - 1)
    lower_tip = bow_root.matrix_world @ Vector((0.0, -0.99185, 0.0))
    upper_tip = bow_root.matrix_world @ Vector((0.0, 0.99185, 0.0))
    resting_nock = bow_root.matrix_world @ Vector((0.128, 0.0, 0.0))
    hand = armature.pose.bones["hand_r"]
    hand_point = armature.matrix_world @ ((hand.head + hand.tail) * 0.5)
    drawn = logical_name in {"bow_draw", "bow_aim", "bow_release"}
    released = logical_name == "bow_release" and phase >= 0.56
    nock = resting_nock if not drawn or released else hand_point
    place_between(strings[0], lower_tip, nock)
    place_between(strings[1], nock, upper_tip)
    arrow_visible = drawn and not released
    if arrow_visible:
        grip = bow_root.matrix_world @ Vector((0.0, 0.0, 0.0))
        direction = (grip - nock).normalized()
        arrow_length = 1.26146 * 0.56
        arrow_root.location = nock + direction * (arrow_length * 0.5)
        arrow_root.rotation_mode = "QUATERNION"
        arrow_root.rotation_quaternion = Vector((0.0, 1.0, 0.0)).rotation_difference(direction)
        arrow_root.scale = Vector((0.56, 0.56, 0.56))
    return arrow_visible


def stabilized_matrix(
    armature: bpy.types.Object,
    base: Matrix,
    yaw: float,
    reference_heading: float,
) -> Matrix:
    correction = reference_heading - pelvis_heading(armature)
    return Matrix.Rotation(math.radians(yaw) + correction, 4, "Z") @ base


def render(args: argparse.Namespace) -> dict:
    source_armature = bpy.data.objects["Armature"]
    body_objects = imported_objects(args.character)
    body_armature = only_armature(body_objects)
    body_meshes = [obj for obj in body_objects if obj.type == "MESH"]
    for action_name in [f"KayKit_{name}" for name in ACTION_SPECS]:
        if action_name not in bpy.data.actions:
            raise RuntimeError(f"Missing retargeted action {action_name}")

    for obj in bpy.context.scene.objects:
        if obj not in body_objects and obj.type not in {"CAMERA", "LIGHT"}:
            obj.hide_render = True
    for obj in list(bpy.context.scene.objects):
        if obj.type in {"CAMERA", "LIGHT"}:
            bpy.data.objects.remove(obj, do_unlink=True)
    preset = load_preset(args.preset)
    configure_scene(preset, body_objects)
    bpy.context.scene.render.fps = 30
    bpy.context.scene.view_settings.look = "AgX - Medium High Contrast"

    bow_root, bow_meshes = import_mesh(args.bow, "Dreadbound KayKit Bow")
    arrow_root, arrow_meshes = import_mesh(args.arrow, "Dreadbound KayKit Arrow")
    shield_root, shield_meshes = import_mesh(args.shield, "Dreadbound KayKit Shield")
    strings = [make_string_piece("Bow String Lower"), make_string_piece("Bow String Upper")]
    equipment = bow_meshes + arrow_meshes + shield_meshes + strings
    for obj in equipment:
        obj.hide_render = False

    body_output = args.body_output.resolve()
    bow_output = args.weapon_output_root.resolve() / "standard_hunter_bow"
    shield_output = args.weapon_output_root.resolve() / "standard_guard_shield"
    for directory in (body_output, bow_output, shield_output):
        directory.mkdir(parents=True, exist_ok=True)
    temp = args.weapon_output_root.resolve() / "_bow_shield_frames"
    manifests = {
        "bow": {
            "schema": 1,
            "weapon_id": "standard_hunter_bow",
            "source": "KayKit Adventurers 2.0 FREE",
            "license": "CC0-1.0",
            "frame_size": list(FRAME_SIZE),
            "fps": 30,
            "bone": "hand_l",
            "directions": list(DIRECTIONS),
            "animations": {},
        },
        "shield": {
            "schema": 1,
            "weapon_id": "standard_guard_shield",
            "source": "KayKit Adventurers 2.0 FREE",
            "license": "CC0-1.0",
            "frame_size": list(FRAME_SIZE),
            "fps": 30,
            "bone": "hand_l",
            "directions": list(DIRECTIONS),
            "animations": {},
        },
    }
    base_matrix = body_armature.matrix_world.copy()
    for logical_name, spec in ACTION_SPECS.items():
        family = spec["family"]
        frame_count = spec["frames"]
        action = bpy.data.actions[f"KayKit_{logical_name}"]
        assign_action(body_armature, action)
        bpy.context.scene.frame_set(0)
        bpy.context.view_layer.update()
        reference_heading = pelvis_heading(body_armature)
        output_directory = bow_output if family == "bow" else shield_output
        prefix = "standard_bow" if family == "bow" else "standard_shield"
        manifests[family]["animations"][logical_name] = {
            "frames": frame_count,
            "columns": min(ATLAS_COLUMNS, frame_count),
            "loop": spec["loop"],
            "source_action": action.name,
            "facing_stabilized": True,
        }
        for direction, yaw in DIRECTIONS.items():
            body_paths: list[Path] = []
            weapon_paths: list[Path] = []
            for frame in range(frame_count):
                bpy.context.scene.frame_set(frame)
                body_armature.matrix_world = stabilized_matrix(
                    body_armature,
                    base_matrix,
                    yaw,
                    reference_heading,
                )
                bpy.context.view_layer.update()
                update_equipment_roots(
                    family,
                    body_armature,
                    bow_root,
                    shield_root,
                )
                bpy.context.view_layer.update()
                arrow_visible = False
                if family == "bow":
                    arrow_visible = update_bow_accessories(
                        logical_name,
                        frame,
                        frame_count,
                        bow_root,
                        body_armature,
                        strings,
                        arrow_root,
                    )
                set_family_visibility(
                    family,
                    bow_meshes,
                    shield_meshes,
                    strings,
                    arrow_meshes,
                    arrow_visible,
                )
                if not args.preview_only:
                    body_frame = temp / "body" / logical_name / direction / f"{frame:03d}.png"
                    body_frame.parent.mkdir(parents=True, exist_ok=True)
                    set_body_holdout(body_meshes, False)
                    for obj in equipment:
                        obj.hide_render = True
                    bpy.context.scene.render.filepath = str(body_frame)
                    bpy.ops.render.render(write_still=True)
                    body_paths.append(body_frame)

                    weapon_frame = temp / "weapon" / logical_name / direction / f"{frame:03d}.png"
                    weapon_frame.parent.mkdir(parents=True, exist_ok=True)
                    set_body_holdout(body_meshes, True)
                    set_family_visibility(
                        family,
                        bow_meshes,
                        shield_meshes,
                        strings,
                        arrow_meshes,
                        arrow_visible,
                    )
                    bpy.context.scene.render.filepath = str(weapon_frame)
                    bpy.ops.render.render(write_still=True)
                    weapon_paths.append(weapon_frame)
            if not args.preview_only:
                pack_grid(
                    body_paths,
                    body_output / f"{logical_name}_{direction}.png",
                    ATLAS_COLUMNS,
                )
                pack_grid(
                    weapon_paths,
                    output_directory / f"{prefix}_{logical_name}_{direction}.png",
                    ATLAS_COLUMNS,
                )
            if args.preview_output is not None:
                preview = args.preview_output.resolve()
                preview.mkdir(parents=True, exist_ok=True)
                sample_frame = frame_count // 2
                bpy.context.scene.frame_set(sample_frame)
                body_armature.matrix_world = stabilized_matrix(
                    body_armature,
                    base_matrix,
                    yaw,
                    reference_heading,
                )
                bpy.context.view_layer.update()
                update_equipment_roots(
                    family,
                    body_armature,
                    bow_root,
                    shield_root,
                )
                bpy.context.view_layer.update()
                arrow_visible = False
                if family == "bow":
                    arrow_visible = update_bow_accessories(
                        logical_name,
                        sample_frame,
                        frame_count,
                        bow_root,
                        body_armature,
                        strings,
                        arrow_root,
                    )
                set_body_holdout(body_meshes, False)
                set_family_visibility(
                    family,
                    bow_meshes,
                    shield_meshes,
                    strings,
                    arrow_meshes,
                    arrow_visible,
                )
                bpy.context.scene.render.filepath = str(
                    preview / f"{logical_name}_{direction}.png"
                )
                bpy.ops.render.render(write_still=True)
    if not args.preview_only:
        for family, output_directory in (("bow", bow_output), ("shield", shield_output)):
            (output_directory / "manifest.json").write_text(
                json.dumps(manifests[family], ensure_ascii=False, indent=2) + "\n",
                encoding="utf-8",
            )
    return manifests


def main() -> None:
    args = parse_args()
    manifests = render(args)
    print(json.dumps({"status": "ok", "manifests": manifests}))


if __name__ == "__main__":
    main()
