#!/usr/bin/env python3
"""Validate the downloaded Quaternius character and animation source pair."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path


REQUIRED_BONES = {
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


def load_gltf(path: Path) -> dict:
    if path.suffix.lower() == ".gltf":
        return json.loads(path.read_text(encoding="utf-8"))
    if path.suffix.lower() != ".glb":
        raise ValueError(f"Unsupported source: {path}")
    with path.open("rb") as handle:
        magic, version, _total = struct.unpack("<4sII", handle.read(12))
        if magic != b"glTF" or version != 2:
            raise ValueError(f"{path} is not a glTF 2 GLB")
        length, chunk_type = struct.unpack("<I4s", handle.read(8))
        if chunk_type != b"JSON":
            raise ValueError(f"{path} has no leading JSON chunk")
        return json.loads(handle.read(length))


def names(document: dict) -> set[str]:
    return {
        str(node["name"])
        for node in document.get("nodes", [])
        if node.get("name")
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--character", required=True, type=Path)
    parser.add_argument("--animations", required=True, type=Path)
    parser.add_argument("--preset", required=True, type=Path)
    args = parser.parse_args()

    character = load_gltf(args.character)
    animations = load_gltf(args.animations)
    preset = json.loads(args.preset.read_text(encoding="utf-8"))
    character_names = names(character)
    animation_names = names(animations)
    missing_character = sorted(REQUIRED_BONES - character_names)
    missing_animations = sorted(REQUIRED_BONES - animation_names)
    if missing_character or missing_animations:
        raise ValueError(
            "Humanoid bone contract mismatch: "
            f"character missing={missing_character}; "
            f"animations missing={missing_animations}"
        )

    available_actions = {
        str(action.get("name", ""))
        for action in animations.get("animations", [])
        if action.get("name")
    }
    selected: dict[str, str] = {}
    for logical_name, spec in preset["animations"].items():
        match = next(
            (candidate for candidate in spec["candidates"] if candidate in available_actions),
            None,
        )
        if match is None:
            raise ValueError(
                f"No animation for {logical_name}; "
                f"candidates={spec['candidates']}"
            )
        selected[logical_name] = match

    result = {
        "status": "ok",
        "character": args.character.name,
        "animation_library": args.animations.name,
        "character_nodes": len(character.get("nodes", [])),
        "animation_nodes": len(animations.get("nodes", [])),
        "available_actions": len(available_actions),
        "selected_actions": selected,
        "root_motion": args.animations.stem.endswith("_RM"),
    }
    if result["root_motion"]:
        raise ValueError("Use the non-root-motion animation library for 2D atlases")
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
