#!/usr/bin/env python3
"""Append Dreadbound-authored weapon actions to the UAL joint-track library."""

from __future__ import annotations

import argparse
import copy
import json
import math
from pathlib import Path


DIRECTIONS = ("front", "left", "back", "right")
SIDES = ("left", "right")


def point(value: list[float]) -> tuple[float, float]:
    return (float(value[0]), float(value[1]))


def add(
    a: tuple[float, float], b: tuple[float, float]
) -> tuple[float, float]:
    return (a[0] + b[0], a[1] + b[1])


def sub(
    a: tuple[float, float], b: tuple[float, float]
) -> tuple[float, float]:
    return (a[0] - b[0], a[1] - b[1])


def length(value: tuple[float, float]) -> float:
    return math.hypot(value[0], value[1])


def lerp(a: float, b: float, weight: float) -> float:
    return a + (b - a) * weight


def lerp_point(
    a: tuple[float, float],
    b: tuple[float, float],
    weight: float,
) -> tuple[float, float]:
    return (lerp(a[0], b[0], weight), lerp(a[1], b[1], weight))


def smooth(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def pulse(value: float) -> float:
    return math.sin(max(0.0, min(1.0, value)) * math.pi)


def solve_elbow(
    shoulder: tuple[float, float],
    target: tuple[float, float],
    upper_length: float,
    lower_length: float,
    bend_sign: float,
) -> tuple[float, float]:
    delta = sub(target, shoulder)
    distance = min(
        max(length(delta), abs(upper_length - lower_length) + 0.001),
        upper_length + lower_length - 0.001,
    )
    target_angle = math.atan2(delta[1], delta[0])
    cosine = max(
        -1.0,
        min(
            1.0,
            (
                upper_length * upper_length
                + distance * distance
                - lower_length * lower_length
            )
            / (2.0 * upper_length * distance),
        ),
    )
    shoulder_angle = target_angle + math.copysign(math.acos(cosine), bend_sign)
    return add(
        shoulder,
        (
            math.cos(shoulder_angle) * upper_length,
            math.sin(shoulder_angle) * upper_length,
        ),
    )


def hand_target(
    direction: str,
    chest: tuple[float, float],
    forward: float,
    up: float,
    lateral: float,
) -> tuple[float, float]:
    if direction in ("left", "right"):
        facing_sign = -1.0 if direction == "left" else 1.0
        return (
            chest[0] + facing_sign * forward,
            chest[1] - up + lateral * 0.08,
        )
    depth_sign = 1.0 if direction == "front" else -1.0
    mirror = 1.0 if direction == "front" else -1.0
    return (
        chest[0] + lateral * mirror,
        chest[1] - up + depth_sign * forward * 0.22,
    )


def action_parameters(
    action_name: str,
    phase: float,
) -> tuple[tuple[float, float, float], tuple[float, float, float], float, float]:
    """Return main target, off target, torso angle and vertical root offset."""
    wave = math.sin(phase * math.tau)
    if action_name == "bow_idle":
        return (18, 24 + wave * 1.5, 34), (56, 27, -38), wave * 0.6, 0
    if action_name == "bow_draw":
        draw = smooth(phase)
        return (lerp(18, -8, draw), lerp(24, 42, draw), lerp(34, 48, draw)), (58, 27, -40), -draw * 3, draw * 2
    if action_name == "bow_release":
        snap = pulse(phase)
        return (lerp(-8, 38, snap), lerp(42, 27, snap), lerp(48, 20, snap)), (lerp(58, 66, snap), 27, -40), snap * 2, -snap * 2
    if action_name == "shield_idle":
        return (18, 10, 24), (42, 42 + wave * 1.2, -35), wave * 0.5, 0
    if action_name == "shield_block":
        guard = smooth(min(1.0, phase * 1.7))
        return (lerp(18, 8, guard), 15, 22), (lerp(42, 58, guard), lerp(42, 54, guard), -34), -guard * 4, guard * 2
    if action_name == "shield_impact":
        impact = pulse(phase)
        return (12, 16, 20), (lerp(58, 42, impact), 54, -34), impact * 6, impact * 5
    if action_name == "two_hand_firearm_idle":
        return (48, 28 + wave, 14), (73, 20, -13), wave * 0.45, 0
    if action_name == "two_hand_firearm_shoot":
        recoil = pulse(phase)
        return (lerp(48, 37, recoil), 28, 14), (lerp(73, 61, recoil), 20, -13), recoil * 2.5, recoil * 1.5
    if action_name == "two_hand_firearm_reload":
        lower = pulse(phase)
        return (lerp(48, 21, lower), lerp(28, 4, lower), 14), (lerp(73, 34, lower), lerp(20, -4, lower), -13), lower * 4, lower * 2
    if action_name == "heavy_two_hand_idle":
        return (35, 3 + wave, 18), (18, 0, -20), wave * 0.55, 0
    if action_name == "heavy_two_hand_windup":
        windup = smooth(phase)
        return (lerp(35, -6, windup), lerp(3, 74, windup), 22), (lerp(18, -18, windup), lerp(0, 60, windup), -18), windup * -9, windup * 3
    if action_name == "heavy_two_hand_attack":
        strike = smooth(min(1.0, phase * 1.45))
        recover = smooth(max(0.0, (phase - 0.72) / 0.28))
        drive = strike * (1.0 - recover)
        return (lerp(-6, 78, drive), lerp(74, -8, drive), 22), (lerp(-18, 52, drive), lerp(60, -5, drive), -18), lerp(-9, 12, drive), -drive * 4
    raise KeyError(action_name)


def normalize(
    joints: dict[str, tuple[float, float]],
    baseline_y: float,
    center_x: float,
    body_height: float,
) -> dict[str, list[float]]:
    return {
        name: [
            round((value[0] - center_x) / body_height, 6),
            round((value[1] - baseline_y) / body_height, 6),
        ]
        for name, value in joints.items()
    }


def build_frame(
    manifest: dict,
    direction: str,
    action_name: str,
    phase: float,
) -> dict[str, list[float]]:
    joints = {
        name: point(value)
        for name, value in manifest["joints"].items()
        if name not in ("root", "coat_left", "coat_right")
    }
    main_spec, off_spec, torso_degrees, root_y = action_parameters(
        action_name, phase
    )
    hips = joints["hips"]
    chest = lerp_point(hips, joints["head"], 0.58)
    torso_angle = math.radians(torso_degrees)
    cosine = math.cos(torso_angle)
    sine = math.sin(torso_angle)
    for name in ("head", "left_shoulder", "right_shoulder"):
        relative = sub(joints[name], hips)
        joints[name] = (
            hips[0] + relative[0] * cosine - relative[1] * sine,
            hips[1] + relative[0] * sine + relative[1] * cosine + root_y,
        )
    joints["hips"] = (hips[0], hips[1] + root_y)
    targets = {
        "right": hand_target(direction, chest, *main_spec),
        "left": hand_target(direction, chest, *off_spec),
    }
    for side in SIDES:
        shoulder = joints[f"{side}_shoulder"]
        upper_length = length(
            sub(
                point(manifest["joints"][f"{side}_elbow"]),
                point(manifest["joints"][f"{side}_shoulder"]),
            )
        )
        lower_length = length(
            sub(
                point(manifest["joints"][f"{side}_hand"]),
                point(manifest["joints"][f"{side}_elbow"]),
            )
        )
        bend = -1.0 if side == "left" else 1.0
        if direction == "right":
            bend *= -1.0
        joints[f"{side}_elbow"] = solve_elbow(
            shoulder,
            targets[side],
            upper_length,
            lower_length,
            bend,
        )
        joints[f"{side}_hand"] = targets[side]
    return normalize(
        joints,
        float(manifest["baseline_y"]),
        float(manifest["center_x"]),
        float(manifest["baseline_y"]) - float(manifest["joints"]["head"][1]),
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tracks", required=True, type=Path)
    parser.add_argument("--config", required=True, type=Path)
    parser.add_argument("--rig-root", required=True, type=Path)
    args = parser.parse_args()
    tracks = json.loads(args.tracks.read_text(encoding="utf-8"))
    config = json.loads(args.config.read_text(encoding="utf-8"))
    frame_count = int(config.get("sample_frames", 8))
    for action_name, spec in config["authored_actions"].items():
        directional = {}
        for direction in DIRECTIONS:
            manifest = json.loads(
                (args.rig_root / direction / "rig.json").read_text(
                    encoding="utf-8"
                )
            )
            directional[direction] = [
                build_frame(
                    copy.deepcopy(manifest),
                    direction,
                    action_name,
                    index / max(1, frame_count - 1),
                )
                for index in range(frame_count)
            ]
        tracks["actions"][action_name] = {
            "source": "Dreadbound_authored",
            "source_action": action_name,
            "family": spec["family"],
            "loop": bool(spec["loop"]),
            "authoring_rig": spec["authoring"],
            "frames": directional,
        }
    tracks["action_count"] = len(tracks["actions"])
    args.tracks.write_text(
        json.dumps(tracks, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    print(
        json.dumps(
            {
                "status": "ok",
                "authored_actions": len(config["authored_actions"]),
                "total_actions": len(tracks["actions"]),
                "tracks": str(args.tracks),
            }
        )
    )


if __name__ == "__main__":
    main()
