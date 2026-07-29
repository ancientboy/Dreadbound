#!/usr/bin/env python3
"""Render a standard one-hand sword as synchronized transparent weapon atlases.

Open ``dreadbound_weapon_actions.blend`` before running this script.  The
embedded mannequin remains in the render as a Cycles holdout so the resulting
RGBA layer already contains correct body occlusion while the character itself
stays transparent.
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
FRAME_SIZE = (128, 128)
SWORD_ACTIONS = {
    "one_hand_melee_idle": {
        "source": "Sword_Idle",
        "start": 0,
        "end": 40,
        "step": 2,
        "loop": True,
    },
    "attack_melee": {
        "source": "Sword_Attack",
        "start": 0,
        "end": 36,
        "step": 2,
        "loop": False,
    },
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--preview-output", type=Path)
    return parser.parse_args(argv)


def material(
    name: str,
    base_color: tuple[float, float, float, float],
    metallic: float,
    roughness: float,
) -> bpy.types.Material:
    value = bpy.data.materials.new(name)
    value.diffuse_color = base_color
    value.use_nodes = True
    shader = value.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = base_color
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return value


def move_to_collection(
    obj: bpy.types.Object,
    collection: bpy.types.Collection,
) -> None:
    for current in list(obj.users_collection):
        current.objects.unlink(obj)
    collection.objects.link(obj)


def add_box(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    bevel: float,
    value: bpy.types.Material,
    collection: bpy.types.Collection,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("Soft weapon edges", "BEVEL")
    modifier.width = bevel
    modifier.segments = 2
    obj.data.materials.append(value)
    move_to_collection(obj, collection)
    return obj


def build_standard_sword(armature: bpy.types.Object) -> bpy.types.Object:
    existing = bpy.data.objects.get("Standard Melee Sword Root")
    if existing is not None:
        bpy.data.objects.remove(existing, do_unlink=True)
    collection = bpy.data.collections.new("Dreadbound Standard Melee Sword")
    bpy.context.scene.collection.children.link(collection)
    blade_mat = material("Standard Sword Blade", (0.38, 0.52, 0.62, 1.0), 0.82, 0.23)
    edge_mat = material("Standard Sword Edge", (0.72, 0.88, 0.94, 1.0), 0.9, 0.16)
    guard_mat = material("Standard Sword Guard", (0.55, 0.30, 0.08, 1.0), 0.65, 0.3)
    grip_mat = material("Standard Sword Grip", (0.07, 0.045, 0.035, 1.0), 0.05, 0.72)

    root = bpy.data.objects.new("Standard Melee Sword Root", None)
    collection.objects.link(root)
    # Local +Y is the weapon's long axis. The grip origin sits in hand_r.
    pieces = [
        add_box("Sword Grip", (0.0, 0.0, 0.0), (0.026, 0.105, 0.026), 0.008, grip_mat, collection),
        add_box("Sword Guard", (0.0, 0.125, 0.0), (0.135, 0.025, 0.035), 0.012, guard_mat, collection),
        add_box("Sword Blade", (0.0, 0.49, 0.0), (0.048, 0.34, 0.016), 0.009, blade_mat, collection),
        add_box("Sword Edge", (0.0, 0.49, -0.018), (0.036, 0.34, 0.006), 0.004, edge_mat, collection),
    ]
    bpy.ops.mesh.primitive_cone_add(
        vertices=4,
        radius1=0.068,
        radius2=0.0,
        depth=0.18,
        location=(0.0, 0.92, 0.0),
        rotation=(math.pi / 2.0, 0.0, 0.0),
    )
    tip = bpy.context.object
    tip.name = "Sword Tip"
    tip.data.materials.append(blade_mat)
    move_to_collection(tip, collection)
    pieces.append(tip)
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=16,
        ring_count=8,
        radius=0.045,
        location=(0.0, -0.135, 0.0),
    )
    pommel = bpy.context.object
    pommel.name = "Sword Pommel"
    pommel.scale = (1.0, 0.65, 0.72)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    pommel.data.materials.append(guard_mat)
    move_to_collection(pommel, collection)
    pieces.append(pommel)
    for piece in pieces:
        piece.parent = root

    root.parent = armature
    root.parent_type = "BONE"
    root.parent_bone = "hand_r"
    root.location = (0.0, 0.0, 0.0)
    # UAL hand bones point down the fingers. Rotate the hilt across the palm.
    root.rotation_mode = "XYZ"
    root.rotation_euler = (math.radians(90.0), 0.0, math.radians(-12.0))
    return root


def bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    low = Vector(tuple(min(point[index] for point in points) for index in range(3)))
    high = Vector(tuple(max(point[index] for point in points) for index in range(3)))
    return low, high


def look_at(obj: bpy.types.Object, point: Vector) -> None:
    obj.rotation_euler = (point - obj.location).to_track_quat("-Z", "Y").to_euler()


def configure_scene(mannequin: bpy.types.Object) -> None:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 8
    scene.cycles.use_denoising = False
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_x = FRAME_SIZE[0]
    scene.render.resolution_y = FRAME_SIZE[1]
    scene.render.resolution_percentage = 100
    scene.render.fps = 12
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.look = "AgX - Medium High Contrast"

    low, high = bounds(mannequin)
    center = (low + high) * 0.5
    character_height = max(high.z - low.z, 0.01)
    camera_data = bpy.data.cameras.new("Dreadbound Weapon Layer Camera")
    camera = bpy.data.objects.new("Dreadbound Weapon Layer Camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera_data.type = "ORTHO"
    # The embedded animation mannequin is taller than the clothed base_drifter
    # render source. These calibrated values align the same UAL hand/foot
    # joints to the published 128x128 base_drifter atlases.
    camera_data.ortho_scale = character_height * 2.12625
    camera_data.shift_x = -0.034
    camera_data.shift_y = -0.113
    elevation = math.radians(18.0)
    distance = character_height * 4.0
    camera.location = center + Vector(
        (0.0, -math.cos(elevation) * distance, math.sin(elevation) * distance)
    )
    look_at(camera, center + Vector((0.0, 0.0, character_height * 0.03)))

    world = scene.world or bpy.data.worlds.new("Dreadbound Weapon Layer World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (
        0.018,
        0.028,
        0.045,
        1.0,
    )
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35
    for name, location, energy, size in (
        (
            "Weapon Key Light",
            center + Vector((-character_height * 2.0, -character_height * 3.0, character_height * 3.5)),
            780.0,
            character_height * 2.0,
        ),
        (
            "Weapon Fill Light",
            center + Vector((character_height * 2.5, -character_height, character_height * 1.8)),
            320.0,
            character_height * 2.5,
        ),
    ):
        light_data = bpy.data.lights.new(name, type="AREA")
        light_data.energy = energy
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        scene.collection.objects.link(light)
        light.location = location
        look_at(light, center)


def assign_action(armature: bpy.types.Object, name: str) -> None:
    action = bpy.data.actions.get(name)
    if action is None:
        raise RuntimeError(f"Missing action {name!r}")
    armature.animation_data_create()
    armature.animation_data.action = action
    slots = [slot for slot in action.slots if slot.target_id_type == "OBJECT"]
    if slots:
        armature.animation_data.action_slot = slots[0]


def set_character_holdout(mannequin: bpy.types.Object, enabled: bool) -> None:
    mannequin.is_holdout = enabled
    mannequin.hide_render = False


def sword_parts() -> list[bpy.types.Object]:
    return list(
        bpy.data.collections["Dreadbound Standard Melee Sword"].objects
    )


def set_sword_visibility(visible: bool) -> None:
    for part in sword_parts():
        part.hide_render = not visible


def pelvis_heading(armature: bpy.types.Object) -> float:
    """Return the actor heading encoded by the pelvis, in armature space.

    Sword_Attack turns the pelvis roughly 70 degrees midway through the take.
    That is useful in a free-camera 3D animation, but in a four-direction
    sprite it crosses the side-view silhouette and makes the actor appear to
    attack backwards.  Pelvis local X is the stable horizontal facing axis for
    this UAL rig.
    """

    facing = armature.pose.bones["pelvis"].matrix.to_3x3().col[0]
    return math.atan2(facing.x, -facing.y)


def stabilized_world_matrix(
    armature: bpy.types.Object,
    base_matrix: Matrix,
    direction_yaw: float,
    reference_heading: float | None,
) -> Matrix:
    correction = 0.0
    if reference_heading is not None:
        correction = reference_heading - pelvis_heading(armature)
    return (
        Matrix.Rotation(math.radians(direction_yaw) + correction, 4, "Z")
        @ base_matrix
    )


def set_reference_visibility() -> None:
    keep = {"Armature", "Mannequin", "Standard Melee Sword Root"}
    for obj in bpy.context.scene.objects:
        if obj.name in keep or obj.name.startswith("Sword "):
            continue
        if obj.type in {"CAMERA", "LIGHT"}:
            continue
        obj.hide_render = True


def pack_horizontal(frame_paths: list[Path], atlas_path: Path) -> None:
    images = [bpy.data.images.load(str(path), check_existing=False) for path in frame_paths]
    width, height = images[0].size
    atlas = bpy.data.images.new(
        atlas_path.stem,
        width=width * len(images),
        height=height,
        alpha=True,
    )
    atlas_pixels = [0.0] * (width * len(images) * height * 4)
    for frame_index, image in enumerate(images):
        pixels = list(image.pixels)
        for y in range(height):
            source = y * width * 4
            target = (y * width * len(images) + frame_index * width) * 4
            atlas_pixels[target : target + width * 4] = pixels[source : source + width * 4]
    atlas.pixels.foreach_set(atlas_pixels)
    atlas.filepath_raw = str(atlas_path)
    atlas.file_format = "PNG"
    atlas.save()
    bpy.data.images.remove(atlas)
    for image in images:
        bpy.data.images.remove(image)


def render(
    output: Path,
    preview_output: Path | None,
) -> dict:
    scene = bpy.context.scene
    armature = bpy.data.objects["Armature"]
    mannequin = bpy.data.objects["Mannequin"]
    sword = build_standard_sword(armature)
    configure_scene(mannequin)
    set_reference_visibility()
    output.mkdir(parents=True, exist_ok=True)
    temp = output / "_frames"
    base_armature_matrix = armature.matrix_world.copy()
    manifest = {
        "schema": 1,
        "weapon_id": "standard_melee_sword",
        "source": "bone_parented_blender_weapon_layer",
        "frame_size": list(FRAME_SIZE),
        "fps": scene.render.fps,
        "bone": "hand_r",
        "directions": list(DIRECTIONS),
        "animations": {},
    }
    for logical_name, spec in SWORD_ACTIONS.items():
        assign_action(armature, spec["source"])
        frames = list(range(spec["start"], spec["end"] + 1, spec["step"]))
        scene.frame_set(frames[0])
        reference_heading = (
            pelvis_heading(armature)
            if logical_name == "attack_melee"
            else None
        )
        manifest["animations"][logical_name] = {
            "frames": len(frames),
            "loop": spec["loop"],
            "source_action": spec["source"],
            "facing_stabilized": reference_heading is not None,
        }
        for direction, yaw in DIRECTIONS.items():
            paths = []
            frame_dir = temp / logical_name / direction
            frame_dir.mkdir(parents=True, exist_ok=True)
            for index, frame in enumerate(frames):
                scene.frame_set(frame)
                armature.matrix_world = stabilized_world_matrix(
                    armature,
                    base_armature_matrix,
                    yaw,
                    reference_heading,
                )
                set_character_holdout(mannequin, True)
                set_sword_visibility(True)
                path = frame_dir / f"{index:03d}.png"
                scene.render.filepath = str(path)
                bpy.ops.render.render(write_still=True)
                paths.append(path)
            pack_horizontal(
                paths,
                output / f"standard_sword_{logical_name}_{direction}.png",
            )
    if preview_output is not None:
        preview_output.mkdir(parents=True, exist_ok=True)
        assign_action(armature, "Sword_Idle")
        for direction, yaw in DIRECTIONS.items():
            scene.frame_set(10)
            armature.matrix_world = (
                Matrix.Rotation(math.radians(yaw), 4, "Z") @ base_armature_matrix
            )
            set_character_holdout(mannequin, False)
            set_sword_visibility(True)
            path = preview_output / f"standard_sword_idle_{direction}.png"
            scene.render.filepath = str(path)
            bpy.ops.render.render(write_still=True)
            set_sword_visibility(False)
            scene.render.filepath = str(
                preview_output / f"mannequin_idle_{direction}.png"
            )
            bpy.ops.render.render(write_still=True)
            set_sword_visibility(True)
    with (output / "manifest.json").open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    sword.select_set(True)
    return manifest


def main() -> None:
    args = parse_args()
    manifest = render(
        args.output.resolve(),
        args.preview_output.resolve() if args.preview_output else None,
    )
    print(json.dumps({"status": "ok", "manifest": manifest}))


if __name__ == "__main__":
    main()
