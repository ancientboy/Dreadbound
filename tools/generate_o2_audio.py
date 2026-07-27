#!/usr/bin/env python3
"""Generate Dreadbound O2's original synthetic audio source library.

No sampled commercial or third-party material is used.  Each cue is built from
oscillators, filtered noise and envelopes, then long-form loops are encoded to
OGG for Godot/Web delivery.  The deterministic seed makes review reproducible.
"""
from __future__ import annotations

import math
import random
import struct
import subprocess
import wave
from pathlib import Path

RATE = 48000
ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "assets" / "audio"
RNG = random.Random(20260726)


def env(t: float, length: float, attack: float = 0.015, release: float = 0.12) -> float:
    return min(1.0, t / max(attack, 0.001), (length - t) / max(release, 0.001))


def cue(path: str, length: float, base: float, kind: str = "impact") -> None:
    output = AUDIO / path
    output.parent.mkdir(parents=True, exist_ok=True)
    frames = int(length * RATE)
    samples: list[int] = []
    for i in range(frames):
        t = i / RATE
        e = env(t, length, 0.01, length * 0.65)
        noise = RNG.uniform(-1.0, 1.0)
        if kind == "metal":
            value = math.sin(math.tau * base * t) * 0.42 + math.sin(math.tau * base * 2.71 * t) * 0.2 + noise * 0.24
        elif kind == "water":
            value = math.sin(math.tau * base * t) * 0.18 + noise * 0.46 * (0.5 + 0.5 * math.sin(t * 17.0))
        elif kind == "warning":
            pulse = 0.5 + 0.5 * math.sin(math.tau * 4.0 * t)
            value = (math.sin(math.tau * base * t) * 0.58 + math.sin(math.tau * base * 1.5 * t) * 0.16) * pulse
        elif kind == "whoosh":
            sweep = base * (1.0 + 1.8 * t / length)
            value = math.sin(math.tau * sweep * t) * 0.22 + noise * 0.38
        elif kind == "creature":
            value = math.sin(math.tau * base * t + math.sin(t * 8.0) * 1.5) * 0.4 + math.sin(math.tau * base * 0.51 * t) * 0.25 + noise * 0.17
        else:
            value = math.sin(math.tau * base * t) * 0.38 + noise * 0.42
        value *= e * 0.48
        samples.append(max(-32767, min(32767, int(value * 32767))))
    with wave.open(str(output), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(struct.pack("<%dh" % len(samples), *samples))


def loop(path: str, length: float, key: float, mood: str) -> None:
    wav_path = AUDIO / "_masters" / (Path(path).stem + ".wav")
    wav_path.parent.mkdir(parents=True, exist_ok=True)
    frames = int(length * RATE)
    data = bytearray()
    for i in range(frames):
        t = i / RATE
        phase = t / length
        # Seamless: all modulation has an integer cycle count over loop duration.
        drift = math.sin(math.tau * phase * 3.0) * 0.06
        if mood == "metro":
            left = math.sin(math.tau * key * (1 + drift) * t) * 0.18 + math.sin(math.tau * key * 0.5 * t) * 0.16
            right = math.sin(math.tau * key * 1.5 * t) * 0.12 + math.sin(math.tau * key * 0.25 * t) * 0.18
        elif mood == "sanatorium":
            left = math.sin(math.tau * key * t) * 0.16 + math.sin(math.tau * key * 1.189 * t) * 0.08
            right = math.sin(math.tau * key * 0.75 * t) * 0.13 + math.sin(math.tau * key * 2.0 * t) * 0.05
        elif mood == "corridor":
            left = math.sin(math.tau * key * t) * 0.16 + math.sin(math.tau * key * 0.25 * t) * 0.19
            right = math.sin(math.tau * key * 1.5 * t) * 0.08 + math.sin(math.tau * key * 0.5 * t) * 0.14
        else:
            left = math.sin(math.tau * key * t) * 0.13 + math.sin(math.tau * key * 1.25 * t) * 0.07
            right = math.sin(math.tau * key * 0.5 * t) * 0.13 + math.sin(math.tau * key * 1.5 * t) * 0.06
        pulse = 0.72 + 0.28 * math.sin(math.tau * phase * 2.0) ** 2
        data.extend(struct.pack("<hh", int(left * pulse * 32767), int(right * pulse * 32767)))
    with wave.open(str(wav_path), "wb") as f:
        f.setnchannels(2)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)
    output = AUDIO / path
    output.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav_path), "-c:a", "libvorbis", "-q:a", "3", str(output)], check=True)


def main() -> None:
    short = {
        "sfx/ui/ui_hover_01.wav": (0.10, 680, "metal"), "sfx/ui/ui_confirm_01.wav": (0.18, 920, "metal"),
        "sfx/ui/ui_cancel_01.wav": (0.16, 300, "metal"), "sfx/ui/ui_error_01.wav": (0.25, 170, "warning"), "sfx/ui/ui_tab_01.wav": (0.12, 520, "metal"),
        "sfx/player/combat/player_melee_swing_01.wav": (0.28, 145, "whoosh"), "sfx/player/combat/player_pistol_fire_01.wav": (0.18, 310, "impact"),
        "sfx/player/combat/player_shotgun_fire_01.wav": (0.32, 92, "impact"), "sfx/player/combat/player_hit_01.wav": (0.24, 75, "impact"),
        "sfx/player/combat/player_death_01.wav": (0.72, 55, "creature"), "sfx/player/combat/player_heal_01.wav": (0.48, 430, "metal"), "sfx/player/combat/player_switch_01.wav": (0.18, 280, "metal"),
        "sfx/world/pickup/world_pickup_01.wav": (0.22, 600, "metal"), "sfx/world/pickup/world_pickup_rare_01.wav": (0.42, 770, "metal"),
        "sfx/world/objective/world_interact_01.wav": (0.21, 255, "metal"), "sfx/world/objective/world_objective_01.wav": (0.55, 340, "warning"),
        "sfx/world/objective/world_warning_01.wav": (0.42, 190, "warning"), "sfx/world/objective/world_success_01.wav": (0.65, 480, "metal"), "sfx/world/objective/world_extract_01.wav": (0.85, 125, "warning"),
        "sfx/creatures/sanatorium/patient_windup_01.wav": (0.34, 88, "creature"), "sfx/creatures/sanatorium/patient_attack_01.wav": (0.28, 160, "creature"),
        "sfx/creatures/sanatorium/crawler_windup_01.wav": (0.32, 135, "creature"), "sfx/creatures/sanatorium/crawler_attack_01.wav": (0.25, 200, "creature"),
        "sfx/creatures/sanatorium/orderly_attack_01.wav": (0.35, 72, "metal"), "sfx/creatures/sanatorium/director_windup_01.wav": (0.52, 64, "creature"),
        "sfx/creatures/sanatorium/director_attack_01.wav": (0.48, 100, "metal"), "sfx/creatures/metro/drowned_attack_01.wav": (0.35, 108, "water"),
        "sfx/creatures/metro/conductor_windup_01.wav": (0.44, 210, "warning"), "sfx/creatures/metro/conductor_attack_01.wav": (0.38, 150, "metal"),
    }
    variants = {
        "sfx/player/combat/player_melee_swing_01.wav", "sfx/player/combat/player_hit_01.wav",
        "sfx/world/pickup/world_pickup_01.wav", "sfx/creatures/sanatorium/patient_attack_01.wav",
        "sfx/creatures/sanatorium/crawler_attack_01.wav", "sfx/creatures/metro/drowned_attack_01.wav",
    }
    for path, spec in short.items():
        cue(path, *spec)
        if path in variants:
            for index in range(2, 5):
                cue(path.replace("_01.wav", "_%02d.wav" % index), *spec)
    styles = {
        "barrier_counter": (0.48, 170, "metal"), "last_stand": (0.46, 82, "warning"),
        "sacrifice_medic": (0.58, 460, "metal"), "choke_control": (0.44, 126, "whoosh"),
        "weakpoint_sniper": (0.35, 670, "warning"), "heavy_suppression": (0.52, 108, "impact"),
        "demolition_traps": (0.64, 76, "impact"), "relic_engineer": (0.44, 390, "metal"),
        "psychic_sense": (0.62, 250, "warning"), "anomaly_ingestion": (0.66, 66, "creature"),
        "echo_summoner": (0.72, 330, "metal"), "aberrant_form": (0.76, 58, "creature"),
    }
    for style, spec in styles.items():
        cue("sfx/skills/skill_%s_01.wav" % style, *spec)
    loops = {
        "music/music_home_threshold_loop.ogg": (24, 48, "home"), "music/music_corridor_idle_loop.ogg": (24, 42, "corridor"),
        "music/music_sanatorium_explore_loop.ogg": (28, 53, "sanatorium"), "music/music_sanatorium_boss_loop.ogg": (22, 67, "sanatorium"),
        "music/music_metro_explore_loop.ogg": (28, 46, "metro"), "music/music_metro_boss_loop.ogg": (22, 59, "metro"),
        "ambience/amb_corridor_structure_loop.ogg": (24, 28, "corridor"), "ambience/amb_sanatorium_ward_loop.ogg": (24, 33, "sanatorium"),
        "ambience/amb_sanatorium_basement_loop.ogg": (24, 24, "sanatorium"), "ambience/amb_metro_platform_loop.ogg": (24, 30, "metro"), "ambience/amb_metro_flood_loop.ogg": (24, 20, "metro"),
    }
    for path, spec in loops.items():
        loop(path, *spec)


if __name__ == "__main__":
    main()
