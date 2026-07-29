"""Author the demo-only Armorer outfit on Dreadbound's standard humanoid rig.

Run with the checked-in action source:

    blender --background character_pipeline/dreadbound_weapon_actions.blend \
      --python character_pipeline/author_armorer_skin_blender.py -- \
      --blend-output character_pipeline/dreadbound_armorer_demo.blend \
      --atlas-output assets/art/characters/rendered3d/armorer_demo_v1 \
      --preview-output /tmp/dreadbound-armorer-preview

The script never creates or edits gameplay scenes.  It adds a profession outfit
to the existing 65-bone Armature and reuses the checked-in action library.
Rigid armor components are driven by full-weight vertex groups on that same
Armature; the original mannequin remains the body and fit reference.
"""

from __future__ import annotations

import argparse
import json
import math
import shutil
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

SCRIPT_ROOT = Path(__file__).resolve().parent
if str(SCRIPT_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPT_ROOT))

from render_directional_sprites import DIRECTIONS, configure_scene
from render_bow_shield_layers import pack_grid
from render_standard_melee_weapon import (
    configure_scene as configure_runtime_scene,
    pelvis_heading,
)


COLLECTION_NAME = "Dreadbound Armorer Demo Outfit"
ARMATURE_NAME = "Armature"
BODY_NAME = "Mannequin"
PREVIEW_ACTIONS = {
    "idle": ("Idle_Loop", 1),
    "walk_contact": ("Walk_Loop", 8),
    "melee": ("Sword_Attack", 12),
    "pistol": ("Pistol_Aim_Neutral", 1),
    "staff": ("Dreadbound_spell_idle", 1),
    "bow": ("KayKit_bow_aim", 12),
    "shield": ("KayKit_shield_block", 12),
}
ATLAS_COLUMNS = 28
ATLAS_ACTIONS = {
    "idle": ("Idle_Talking_Loop", 36, 2, True, False),
    "walk": ("Walk_Loop", 17, 2, True, False),
    "attack_melee": ("Sword_Attack", 19, 2, False, True),
    "hit": ("Hit_Chest", 5, 2, False, False),
    "death": ("Death01", 30, 2, False, False),
    "one_hand_melee_idle": ("Sword_Idle", 21, 2, True, False),
    "pistol_idle": ("Pistol_Idle_Loop", 21, 2, True, False),
    "pistol_aim_down": ("Pistol_Aim_Down", 3, 2, False, False),
    "pistol_aim": ("Pistol_Aim_Neutral", 3, 2, False, False),
    "pistol_aim_up": ("Pistol_Aim_Up", 3, 2, False, False),
    "pistol_shoot": ("Pistol_Shoot", 8, 2, False, False),
    "pistol_reload": ("Pistol_Reload", 21, 2, False, False),
    "spell_enter": ("Spell_Simple_Enter", 7, 2, False, False),
    "spell_idle": ("Spell_Simple_Idle_Loop", 26, 2, True, False),
    "spell_shoot": ("Spell_Simple_Shoot", 7, 2, False, False),
    "spell_exit": ("Spell_Simple_Exit", 6, 2, False, False),
    "bow_idle": ("KayKit_bow_idle", 48, 1, True, True),
    "bow_draw": ("KayKit_bow_draw", 41, 1, False, True),
    "bow_aim": ("KayKit_bow_aim", 56, 1, True, True),
    "bow_release": ("KayKit_bow_release", 41, 1, False, True),
    "shield_raise": ("KayKit_shield_raise", 33, 1, False, True),
    "shield_block": ("KayKit_shield_block", 33, 1, True, True),
    "shield_hit": ("KayKit_shield_hit", 33, 1, False, True),
    "shield_bash": ("KayKit_shield_bash", 33, 1, False, True),
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend-output", type=Path, required=True)
    parser.add_argument("--preview-output", type=Path)
    parser.add_argument("--atlas-output", type=Path)
    parser.add_argument(
        "--actions",
        nargs="+",
        choices=tuple(ATLAS_ACTIONS),
        default=list(ATLAS_ACTIONS),
    )
    return parser.parse_args(argv)


def material(
    name: str,
    color: tuple[float, float, float, float],
    metallic: float,
    roughness: float,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    existing = bpy.data.materials.get(name)
    if existing is not None:
        bpy.data.materials.remove(existing)
    result = bpy.data.materials.new(name)
    result.diffuse_color = color
    result.metallic = metallic
    result.roughness = roughness
    result.use_nodes = True
    principled = result.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = color
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if emission_strength > 0.0:
        principled.inputs["Emission Color"].default_value = color
        principled.inputs["Emission Strength"].default_value = emission_strength
    return result


def delete_previous_outfit() -> bpy.types.Collection:
    previous = bpy.data.collections.get(COLLECTION_NAME)
    if previous is not None:
        for obj in list(previous.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(previous)
    collection = bpy.data.collections.new(COLLECTION_NAME)
    bpy.context.scene.collection.children.link(collection)
    return collection


def move_to_collection(
    obj: bpy.types.Object,
    collection: bpy.types.Collection,
) -> None:
    for owner in list(obj.users_collection):
        owner.objects.unlink(obj)
    collection.objects.link(obj)


def apply_scale(obj: bpy.types.Object) -> None:
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.select_set(False)


def add_bevel(obj: bpy.types.Object, width: float, segments: int = 2) -> None:
    modifier = obj.modifiers.new("Armorer bevel", "BEVEL")
    modifier.width = width
    modifier.segments = segments
    modifier.limit_method = "ANGLE"


def rigid_bind(
    obj: bpy.types.Object,
    armature: bpy.types.Object,
    bone_name: str,
) -> None:
    if bone_name not in armature.data.bones:
        raise RuntimeError(f"Missing standard humanoid bone {bone_name!r}")
    world_matrix = obj.matrix_world.copy()
    obj.parent = armature
    obj.parent_type = "BONE"
    obj.parent_bone = bone_name
    obj.matrix_world = world_matrix


def finish_object(
    obj: bpy.types.Object,
    collection: bpy.types.Collection,
    armature: bpy.types.Object,
    bone_name: str,
    mat: bpy.types.Material,
) -> bpy.types.Object:
    obj.data.materials.append(mat)
    move_to_collection(obj, collection)
    rigid_bind(obj, armature, bone_name)
    return obj


def box(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    bone: str,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    armature: bpy.types.Object,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
    bevel: float = 0.018,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    apply_scale(obj)
    add_bevel(obj, bevel)
    return finish_object(obj, collection, armature, bone, mat)


def sphere(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    bone: str,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    armature: bpy.types.Object,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=24,
        ring_count=12,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    apply_scale(obj)
    return finish_object(obj, collection, armature, bone, mat)


def cylinder_between(
    name: str,
    start: Vector,
    end: Vector,
    radius: float,
    bone: str,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    armature: bpy.types.Object,
) -> bpy.types.Object:
    vector = end - start
    midpoint = (start + end) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=16,
        radius=radius,
        depth=vector.length,
        location=midpoint,
    )
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0.0, 0.0, 1.0)).rotation_difference(vector)
    apply_scale(obj)
    add_bevel(obj, radius * 0.16)
    return finish_object(obj, collection, armature, bone, mat)


def torus(
    name: str,
    location: tuple[float, float, float],
    major_radius: float,
    minor_radius: float,
    bone: str,
    mat: bpy.types.Material,
    collection: bpy.types.Collection,
    armature: bpy.types.Object,
    rotation: tuple[float, float, float] = (math.pi / 2.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_radius,
        minor_radius=minor_radius,
        major_segments=32,
        minor_segments=8,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    return finish_object(obj, collection, armature, bone, mat)


def bone_points(
    armature: bpy.types.Object,
    bone_name: str,
    inset: float = 0.0,
) -> tuple[Vector, Vector]:
    bone = armature.data.bones[bone_name]
    start = bone.head_local.copy()
    end = bone.tail_local.copy()
    if inset:
        vector = (end - start).normalized()
        start += vector * inset
        end -= vector * inset
    return start, end


def author_outfit() -> tuple[bpy.types.Object, bpy.types.Object, list[bpy.types.Object]]:
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
    collection = delete_previous_outfit()

    cloth = material("Armorer cloth", (0.055, 0.045, 0.038, 1.0), 0.05, 0.74)
    armor = material("Armorer dark metal", (0.16, 0.13, 0.105, 1.0), 0.72, 0.32)
    edge = material("Armorer bronze", (0.34, 0.22, 0.10, 1.0), 0.82, 0.24)
    olive = material("Armorer field olive", (0.17, 0.19, 0.12, 1.0), 0.22, 0.63)
    glow = material(
        "Armorer reactor",
        (0.95, 0.48, 0.08, 1.0),
        0.5,
        0.2,
        emission_strength=2.2,
    )

    created: list[bpy.types.Object] = []
    created += [
        box(
            "Armorer chest shell",
            (0.0, -0.105, 1.325),
            (0.39, 0.19, 0.34),
            "spine_02",
            armor,
            collection,
            armature,
            bevel=0.035,
        ),
        box(
            "Armorer abdomen plate",
            (0.0, -0.105, 1.105),
            (0.30, 0.16, 0.16),
            "spine_01",
            olive,
            collection,
            armature,
            bevel=0.025,
        ),
        box(
            "Armorer collar",
            (0.0, -0.005, 1.505),
            (0.34, 0.22, 0.105),
            "spine_03",
            cloth,
            collection,
            armature,
            bevel=0.026,
        ),
        torus(
            "Armorer chest reactor rim",
            (0.0, -0.212, 1.36),
            0.068,
            0.014,
            "spine_02",
            edge,
            collection,
            armature,
        ),
        sphere(
            "Armorer chest reactor core",
            (0.0, -0.218, 1.36),
            (0.105, 0.025, 0.105),
            "spine_02",
            glow,
            collection,
            armature,
        ),
        box(
            "Armorer belt",
            (0.0, -0.025, 0.985),
            (0.34, 0.22, 0.08),
            "pelvis",
            edge,
            collection,
            armature,
            bevel=0.018,
        ),
        box(
            "Armorer backpack",
            (0.0, 0.17, 1.31),
            (0.31, 0.17, 0.40),
            "spine_02",
            olive,
            collection,
            armature,
            bevel=0.035,
        ),
        box(
            "Armorer backpack core",
            (0.0, 0.265, 1.33),
            (0.12, 0.05, 0.25),
            "spine_02",
            edge,
            collection,
            armature,
            bevel=0.016,
        ),
        box(
            "Armorer coat left",
            (0.105, 0.035, 0.81),
            (0.16, 0.10, 0.36),
            "pelvis",
            cloth,
            collection,
            armature,
            rotation=(0.0, 0.08, -0.04),
            bevel=0.018,
        ),
        box(
            "Armorer coat right",
            (-0.105, 0.035, 0.81),
            (0.16, 0.10, 0.36),
            "pelvis",
            cloth,
            collection,
            armature,
            rotation=(0.0, -0.08, 0.04),
            bevel=0.018,
        ),
    ]

    # Hood, crown armor and lower respirator preserve the original Armorer's
    # anonymous silhouette without replacing the humanoid body or proportions.
    created += [
        sphere(
            "Armorer hood",
            (0.0, 0.0, 1.68),
            (0.27, 0.25, 0.31),
            "Head",
            cloth,
            collection,
            armature,
        ),
        box(
            "Armorer face plate",
            (0.0, -0.145, 1.64),
            (0.20, 0.055, 0.15),
            "Head",
            armor,
            collection,
            armature,
            bevel=0.025,
        ),
        box(
            "Armorer visor",
            (0.0, -0.178, 1.715),
            (0.14, 0.018, 0.035),
            "Head",
            glow,
            collection,
            armature,
            bevel=0.009,
        ),
        box(
            "Armorer respirator",
            (0.0, -0.178, 1.59),
            (0.12, 0.035, 0.075),
            "Head",
            edge,
            collection,
            armature,
            bevel=0.012,
        ),
    ]

    for side, sign in (("left", 1.0), ("right", -1.0)):
        suffix = "l" if side == "left" else "r"
        upper = f"upperarm_{suffix}"
        lower = f"lowerarm_{suffix}"
        thigh = f"thigh_{suffix}"
        calf = f"calf_{suffix}"
        foot = f"foot_{suffix}"

        upper_start, upper_end = bone_points(armature, upper, 0.035)
        lower_start, lower_end = bone_points(armature, lower, 0.04)
        thigh_start, thigh_end = bone_points(armature, thigh, 0.055)
        calf_start, calf_end = bone_points(armature, calf, 0.055)
        foot_start, foot_end = bone_points(armature, foot, 0.015)

        created += [
            sphere(
                f"Armorer {side} pauldron",
                (0.235 * sign, 0.015, 1.44),
                (0.23, 0.25, 0.20),
                upper,
                armor,
                collection,
                armature,
            ),
            cylinder_between(
                f"Armorer {side} upper arm",
                upper_start,
                upper_end,
                0.075,
                upper,
                olive,
                collection,
                armature,
            ),
            cylinder_between(
                f"Armorer {side} bracer",
                lower_start,
                lower_end,
                0.068,
                lower,
                armor,
                collection,
                armature,
            ),
            cylinder_between(
                f"Armorer {side} thigh plate",
                thigh_start,
                thigh_end,
                0.095,
                thigh,
                olive,
                collection,
                armature,
            ),
            sphere(
                f"Armorer {side} knee",
                tuple(thigh_end),
                (0.18, 0.15, 0.15),
                calf,
                edge,
                collection,
                armature,
            ),
            cylinder_between(
                f"Armorer {side} shin guard",
                calf_start,
                calf_end,
                0.082,
                calf,
                armor,
                collection,
                armature,
            ),
            box(
                f"Armorer {side} boot",
                tuple((foot_start + foot_end) * 0.5),
                (0.14, 0.26, 0.13),
                foot,
                armor,
                collection,
                armature,
                bevel=0.025,
            ),
        ]

    return armature, body, created


def assign_action(armature: bpy.types.Object, action_name: str) -> None:
    action = bpy.data.actions.get(action_name)
    if action is None:
        raise RuntimeError(f"Missing action {action_name!r}")
    armature.animation_data_create()
    armature.animation_data.action = action
    compatible_slots = [
        slot for slot in action.slots if slot.target_id_type == "OBJECT"
    ]
    if len(compatible_slots) == 1:
        armature.animation_data.action_slot = compatible_slots[0]


def pack_top_down(
    frame_paths: list[Path],
    atlas_path: Path,
    columns: int,
) -> tuple[int, int]:
    images = [
        bpy.data.images.load(str(path), check_existing=False)
        for path in frame_paths
    ]
    width, height = images[0].size
    used_columns = min(columns, len(images))
    rows = math.ceil(len(images) / used_columns)
    atlas_width = width * used_columns
    atlas = bpy.data.images.new(
        atlas_path.stem,
        width=atlas_width,
        height=height * rows,
        alpha=True,
    )
    pixels = [0.0] * (atlas_width * height * rows * 4)
    for frame_index, image in enumerate(images):
        source_pixels = list(image.pixels)
        column = frame_index % used_columns
        row = frame_index // used_columns
        target_row = rows - 1 - row
        for y in range(height):
            source = y * width * 4
            target_y = target_row * height + y
            target = (target_y * atlas_width + column * width) * 4
            pixels[target : target + width * 4] = source_pixels[
                source : source + width * 4
            ]
    atlas.pixels.foreach_set(pixels)
    atlas.filepath_raw = str(atlas_path)
    atlas.file_format = "PNG"
    atlas.save()
    bpy.data.images.remove(atlas)
    for image in images:
        bpy.data.images.remove(image)
    return used_columns, rows


def prepare_atlas_scene(
    armature: bpy.types.Object,
    body: bpy.types.Object,
    outfit: list[bpy.types.Object],
) -> None:
    for obj in list(bpy.context.scene.objects):
        if obj.type in {"CAMERA", "LIGHT"}:
            bpy.data.objects.remove(obj, do_unlink=True)
    for obj in bpy.context.scene.objects:
        if obj in outfit or obj in {armature, body}:
            obj.hide_render = False
        elif obj.type not in {"CAMERA", "LIGHT"}:
            obj.hide_render = True
    armature.data.pose_position = "POSE"
    configure_runtime_scene(body)
    scene = bpy.context.scene
    scene.cycles.samples = 4
    scene.render.fps = 30
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.look = "AgX - Medium High Contrast"


def render_atlases(
    output: Path,
    armature: bpy.types.Object,
    body: bpy.types.Object,
    outfit: list[bpy.types.Object],
    selected_actions: list[str],
) -> dict:
    prepare_atlas_scene(armature, body, outfit)
    output.mkdir(parents=True, exist_ok=True)
    temp = output / "_frames"
    scene = bpy.context.scene
    base_matrix = armature.matrix_world.copy()
    manifest_path = output / "manifest.json"
    if manifest_path.exists():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    else:
        manifest = {
            "schema": 1,
            "source": "standard_humanoid_armorer_blender",
            "character_id": "armorer_demo_v1",
            "skeleton_id": "humanoid_v1",
            "frame_size": [128, 128],
            "fps": 30,
            "directions": list(DIRECTIONS),
            "animations": {},
        }
    for logical_name, (
        action_name,
        frame_count,
        step,
        loop,
        stabilize,
    ) in ATLAS_ACTIONS.items():
        if logical_name not in selected_actions:
            continue
        assign_action(armature, action_name)
        frames = [index * step for index in range(frame_count)]
        scene.frame_set(frames[0])
        bpy.context.view_layer.update()
        reference_heading = pelvis_heading(armature) if stabilize else None
        if logical_name == "idle":
            columns = 18
        elif logical_name.startswith(("bow_", "shield_")):
            columns = min(ATLAS_COLUMNS, frame_count)
        else:
            columns = frame_count
        manifest["animations"][logical_name] = {
            "frames": frame_count,
            "columns": columns,
            "loop": loop,
            "source_action": action_name,
            "facing_stabilized": stabilize,
        }
        for direction, yaw in DIRECTIONS.items():
            paths: list[Path] = []
            frame_dir = temp / logical_name / direction
            frame_dir.mkdir(parents=True, exist_ok=True)
            for index, frame in enumerate(frames):
                scene.frame_set(frame)
                bpy.context.view_layer.update()
                correction = (
                    reference_heading - pelvis_heading(armature)
                    if reference_heading is not None
                    else 0.0
                )
                armature.matrix_world = (
                    Matrix.Rotation(
                        math.radians(yaw) + correction,
                        4,
                        "Z",
                    )
                    @ base_matrix
                )
                bpy.context.view_layer.update()
                path = frame_dir / f"{index:03d}.png"
                scene.render.filepath = str(path)
                bpy.ops.render.render(write_still=True)
                paths.append(path)
            atlas_path = output / f"{logical_name}_{direction}.png"
            if logical_name.startswith(("bow_", "shield_")):
                pack_grid(paths, atlas_path, columns)
            else:
                pack_top_down(paths, atlas_path, columns)
        shutil.rmtree(temp / logical_name)
        manifest_path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
    return manifest


def prepare_preview_scene(
    armature: bpy.types.Object,
    body: bpy.types.Object,
    outfit: list[bpy.types.Object],
) -> None:
    armature.data.pose_position = "POSE"
    for obj in bpy.context.scene.objects:
        if obj in outfit or obj in {armature, body}:
            obj.hide_render = False
        elif obj.type not in {"CAMERA", "LIGHT"}:
            obj.hide_render = True
    preset = {
        "frame_size": [256, 256],
        "fps": 30,
        "render_engine": "CYCLES",
        "render_samples": 4,
        "camera": {"elevation_degrees": 12.0, "padding": 1.28},
    }
    configure_scene(preset, [body, *outfit])
    bpy.context.scene.render.image_settings.color_mode = "RGBA"


def render_previews(
    output: Path,
    armature: bpy.types.Object,
    body: bpy.types.Object,
    outfit: list[bpy.types.Object],
) -> None:
    output.mkdir(parents=True, exist_ok=True)
    prepare_preview_scene(armature, body, outfit)
    base_matrix = armature.matrix_world.copy()
    scene = bpy.context.scene
    for logical_name, (action_name, frame) in PREVIEW_ACTIONS.items():
        assign_action(armature, action_name)
        for direction, yaw in DIRECTIONS.items():
            scene.frame_set(frame)
            armature.matrix_world = (
                Matrix.Rotation(math.radians(yaw), 4, "Z") @ base_matrix
            )
            scene.render.filepath = str(output / f"{logical_name}_{direction}.png")
            bpy.ops.render.render(write_still=True)


def main() -> None:
    args = parse_args()
    armature, body, outfit = author_outfit()
    atlas_manifest = None
    if args.atlas_output is not None:
        atlas_manifest = render_atlases(
            args.atlas_output.resolve(),
            armature,
            body,
            outfit,
            args.actions,
        )
    if args.preview_output is not None:
        render_previews(args.preview_output.resolve(), armature, body, outfit)
    armature.data.pose_position = "POSE"
    bpy.ops.wm.save_as_mainfile(filepath=str(args.blend_output.resolve()))
    print(
        json.dumps(
            {
                "status": "ok",
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
