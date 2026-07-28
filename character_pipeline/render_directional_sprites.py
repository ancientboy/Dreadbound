"""Render one rigged 3D character into deterministic four-direction 2D atlases.

Run with Blender, for example:

    blender --background --python render_directional_sprites.py -- \
      --character UniversalBaseCharacter.glb \
      --output ../../assets/art/characters/rendered3d/base_drifter \
      --preset dreadbound.json

The input may be GLB/GLTF/FBX. All views and frames come from the same mesh,
armature, materials, camera, lighting and animation data.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


DIRECTIONS = {
    "front": 0.0,
    "left": 90.0,
    "back": 180.0,
    "right": 270.0,
}


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", required=True)
    parser.add_argument(
        "--animations",
        required=True,
        help="GLB/GLTF/FBX containing actions for the same humanoid bone names",
    )
    parser.add_argument("--output", required=True)
    parser.add_argument("--preset", required=True)
    parser.add_argument("--armature", default="")
    return parser.parse_args(argv)


def load_preset(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    for key in ("character_id", "frame_size", "camera", "animations"):
        if key not in data:
            raise ValueError(f"Preset is missing {key!r}")
    return data


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in (
        bpy.data.armatures,
        bpy.data.meshes,
        bpy.data.materials,
        bpy.data.cameras,
        bpy.data.lights,
    ):
        for block in list(collection):
            if block.users == 0:
                collection.remove(block)


def import_character(path: Path) -> None:
    suffix = path.suffix.lower()
    temporary_gltf = None
    if suffix == ".gltf":
        document = json.loads(path.read_text(encoding="utf-8"))
        changed = False
        for image in document.get("images", []):
            uri = image.get("uri")
            if not uri or (path.parent / uri).is_file():
                continue
            candidates = []
            if uri.endswith("_png.png"):
                candidates.append(uri.removesuffix("_png.png") + ".png")
            replacement = next(
                (candidate for candidate in candidates if (path.parent / candidate).is_file()),
                None,
            )
            if replacement is None:
                raise FileNotFoundError(path.parent / uri)
            image["uri"] = replacement
            changed = True
        if changed:
            temporary_gltf = path.with_name(f".{path.stem}.dreadbound-import.gltf")
            temporary_gltf.write_text(
                json.dumps(document, ensure_ascii=False),
                encoding="utf-8",
            )
        import_path = temporary_gltf or path
        try:
            bpy.ops.import_scene.gltf(filepath=str(import_path))
        finally:
            if temporary_gltf is not None:
                temporary_gltf.unlink(missing_ok=True)
    elif suffix == ".glb":
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif suffix == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path), automatic_bone_orientation=True)
    else:
        raise ValueError("Character must be .glb, .gltf or .fbx")


def scene_armatures() -> list[bpy.types.Object]:
    return [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]


def find_armature(name: str) -> bpy.types.Object:
    armatures = scene_armatures()
    if name:
        armatures = [obj for obj in armatures if obj.name == name]
    if len(armatures) != 1:
        names = ", ".join(obj.name for obj in armatures) or "none"
        raise RuntimeError(f"Expected exactly one armature, found: {names}")
    return armatures[0]


def import_animation_library(path: Path, character_armature: bpy.types.Object) -> None:
    before_objects = set(bpy.context.scene.objects)
    before_armatures = set(scene_armatures())
    import_character(path)
    imported_objects = [
        obj for obj in bpy.context.scene.objects if obj not in before_objects
    ]
    imported_armatures = [
        obj for obj in scene_armatures() if obj not in before_armatures
    ]
    if len(imported_armatures) != 1:
        names = ", ".join(obj.name for obj in imported_armatures) or "none"
        raise RuntimeError(
            f"Expected one animation armature in {path}, found: {names}"
        )
    animation_armature = imported_armatures[0]
    character_bones = set(character_armature.data.bones.keys())
    animation_bones = set(animation_armature.data.bones.keys())
    required = {
        "root",
        "pelvis",
        "spine_01",
        "spine_02",
        "spine_03",
        "neck_01",
        "Head",
        "upperarm_l",
        "lowerarm_l",
        "hand_l",
        "upperarm_r",
        "lowerarm_r",
        "hand_r",
        "thigh_l",
        "calf_l",
        "foot_l",
        "thigh_r",
        "calf_r",
        "foot_r",
    }
    missing_character = sorted(required - character_bones)
    missing_animation = sorted(required - animation_bones)
    if missing_character or missing_animation:
        raise RuntimeError(
            "Humanoid bone contract mismatch. "
            f"Character missing={missing_character}; "
            f"animation library missing={missing_animation}"
        )
    if not bpy.data.actions:
        raise RuntimeError(f"No actions were imported from {path}")
    for obj in imported_objects:
        bpy.data.objects.remove(obj, do_unlink=True)


def top_level_objects(armature: bpy.types.Object) -> list[bpy.types.Object]:
    result = []
    for obj in bpy.context.scene.objects:
        if obj.type in {"CAMERA", "LIGHT"}:
            continue
        if obj.parent is None:
            result.append(obj)
    if armature not in result and armature.parent is None:
        result.append(armature)
    return result


def bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points = []
    for obj in objects:
        if obj.type != "MESH":
            continue
        points.extend(obj.matrix_world @ Vector(corner) for corner in obj.bound_box)
    if not points:
        raise RuntimeError("Imported character contains no visible mesh")
    low = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    high = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return low, high


def look_at(obj: bpy.types.Object, point: Vector) -> None:
    obj.rotation_euler = (point - obj.location).to_track_quat("-Z", "Y").to_euler()


def configure_scene(preset: dict, objects: list[bpy.types.Object]) -> bpy.types.Object:
    scene = bpy.context.scene
    width, height = preset["frame_size"]
    render_engine = preset.get("render_engine", "BLENDER_WORKBENCH")
    scene.render.engine = render_engine
    if render_engine == "BLENDER_WORKBENCH":
        scene.display.shading.light = "STUDIO"
        scene.display.shading.studio_light = preset.get("studio_light", "paint.sl")
        scene.display.shading.color_type = "MATERIAL"
        scene.display.shading.show_shadows = True
        scene.display.shading.show_cavity = True
        scene.display.shading.cavity_type = "WORLD"
    elif render_engine == "CYCLES":
        scene.cycles.device = "CPU"
        scene.cycles.samples = int(preset.get("render_samples", 8))
        scene.cycles.use_denoising = False
        world = scene.world or bpy.data.worlds.new("DreadboundSpriteWorld")
        scene.world = world
        world.use_nodes = True
        world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35
    else:
        raise ValueError(f"Unsupported render engine: {render_engine}")
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.resolution_x = int(width)
    scene.render.resolution_y = int(height)
    scene.render.resolution_percentage = 100
    scene.render.fps = int(preset.get("fps", 12))

    low, high = bounds(objects)
    center = (low + high) * 0.5
    character_height = max(high.z - low.z, 0.01)
    if render_engine == "CYCLES":
        for name, location, energy, size in (
            (
                "DreadboundKeyLight",
                center + Vector((-character_height * 2.0, -character_height * 3.0, character_height * 3.5)),
                650.0,
                character_height * 2.0,
            ),
            (
                "DreadboundFillLight",
                center + Vector((character_height * 2.5, -character_height * 1.0, character_height * 1.8)),
                250.0,
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
    camera_data = bpy.data.cameras.new("DreadboundSpriteCamera")
    camera = bpy.data.objects.new("DreadboundSpriteCamera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = character_height * float(preset["camera"].get("padding", 1.18))
    elevation = math.radians(float(preset["camera"].get("elevation_degrees", 18.0)))
    distance = character_height * 4.0
    camera.location = center + Vector((0.0, -math.cos(elevation) * distance, math.sin(elevation) * distance))
    look_at(camera, center + Vector((0.0, 0.0, character_height * 0.03)))
    return camera


def match_action(logical_name: str, candidates: list[str]) -> bpy.types.Action:
    actions = list(bpy.data.actions)
    normalized = [(action, action.name.lower().replace(" ", "_")) for action in actions]
    for candidate in candidates:
        needle = candidate.lower().replace(" ", "_")
        for action, name in normalized:
            if name == needle or needle in name:
                return action
    available = ", ".join(action.name for action in actions)
    raise RuntimeError(f"No action matched {logical_name!r}. Available actions: {available}")


def set_yaw(
    objects: list[bpy.types.Object],
    base_matrices: dict[str, Matrix],
    degrees: float,
) -> None:
    radians = math.radians(degrees)
    rotation = Matrix.Rotation(radians, 4, "Z")
    for obj in objects:
        if obj.parent is None:
            obj.matrix_world = rotation @ base_matrices[obj.name]


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


def render(preset: dict, armature: bpy.types.Object, roots: list[bpy.types.Object], output: Path) -> dict:
    scene = bpy.context.scene
    output.mkdir(parents=True, exist_ok=True)
    temp = output / "_frames"
    manifest = {
        "schema": 1,
        "source": "single_3d_rig",
        "character_id": preset["character_id"],
        "frame_size": preset["frame_size"],
        "fps": scene.render.fps,
        "directions": list(DIRECTIONS),
        "animations": {},
    }
    front_offset = float(preset.get("front_yaw_degrees", 0.0))
    base_matrices = {obj.name: obj.matrix_world.copy() for obj in roots}
    for logical_name, spec in preset["animations"].items():
        action = match_action(logical_name, spec["candidates"])
        armature.animation_data_create()
        armature.animation_data.action = action
        compatible_slots = [
            slot for slot in action.slots if slot.target_id_type == "OBJECT"
        ]
        if len(compatible_slots) != 1:
            identifiers = [slot.identifier for slot in compatible_slots]
            raise RuntimeError(
                f"Action {action.name!r} needs exactly one OBJECT slot; "
                f"found {identifiers}"
            )
        armature.animation_data.action_slot = compatible_slots[0]
        start = int(spec.get("start", round(action.frame_range[0])))
        end = int(spec.get("end", round(action.frame_range[1])))
        step = max(1, int(spec.get("step", 1)))
        frames = list(range(start, end + 1, step))
        manifest["animations"][logical_name] = {"frames": len(frames), "loop": bool(spec.get("loop", False))}
        for direction, yaw in DIRECTIONS.items():
            paths = []
            frame_dir = temp / logical_name / direction
            frame_dir.mkdir(parents=True, exist_ok=True)
            for index, frame in enumerate(frames):
                scene.frame_set(frame)
                set_yaw(roots, base_matrices, front_offset + yaw)
                path = frame_dir / f"{index:03d}.png"
                scene.render.filepath = str(path)
                bpy.ops.render.render(write_still=True)
                paths.append(path)
            pack_horizontal(paths, output / f"{logical_name}_{direction}.png")
    with (output / "manifest.json").open("w", encoding="utf-8") as handle:
        json.dump(manifest, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    return manifest


def main() -> None:
    args = parse_args()
    character = Path(args.character).resolve()
    animations = Path(args.animations).resolve()
    output = Path(args.output).resolve()
    preset = load_preset(Path(args.preset).resolve())
    if not character.is_file():
        raise FileNotFoundError(character)
    if not animations.is_file():
        raise FileNotFoundError(animations)
    clear_scene()
    import_character(character)
    armature = find_armature(args.armature)
    import_animation_library(animations, armature)
    roots = top_level_objects(armature)
    configure_scene(preset, list(bpy.context.scene.objects))
    manifest = render(preset, armature, roots, output)
    print(json.dumps({"status": "ok", "output": str(output), "manifest": manifest}))


if __name__ == "__main__":
    main()
