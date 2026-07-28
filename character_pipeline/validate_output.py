"""Validate atlases produced by render_directional_sprites.py."""

from __future__ import annotations

import json
import math
import struct
import sys
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
WEB_SAFE_TEXTURE_LIMIT = 4096


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) != 24 or header[:8] != PNG_SIGNATURE or header[12:16] != b"IHDR":
        raise ValueError(f"{path} is not a valid PNG")
    return struct.unpack(">II", header[16:24])


def main() -> None:
    root = Path(sys.argv[1]).resolve()
    manifest_path = root / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if manifest.get("source") != "single_3d_rig":
        raise ValueError("manifest source must be single_3d_rig")
    frame_width, frame_height = manifest["frame_size"]
    expected_directions = {"front", "back", "left", "right"}
    if set(manifest["directions"]) != expected_directions:
        raise ValueError("manifest must contain exactly four directions")
    for animation, spec in manifest["animations"].items():
        frame_count = int(spec["frames"])
        if frame_count <= 0:
            raise ValueError(f"{animation} has no frames")
        columns = int(spec.get("columns", frame_count))
        if columns <= 0 or columns > frame_count:
            raise ValueError(f"{animation} has invalid atlas columns: {columns}")
        rows = math.ceil(frame_count / columns)
        for direction in expected_directions:
            atlas = root / f"{animation}_{direction}.png"
            width, height = png_size(atlas)
            expected = (frame_width * columns, frame_height * rows)
            if (width, height) != expected:
                raise ValueError(f"{atlas}: got {(width, height)}, expected {expected}")
            if width > WEB_SAFE_TEXTURE_LIMIT or height > WEB_SAFE_TEXTURE_LIMIT:
                raise ValueError(
                    f"{atlas}: {(width, height)} exceeds mobile WebGL texture limit "
                    f"{WEB_SAFE_TEXTURE_LIMIT}"
                )
    print(f"Validated {manifest['character_id']}: {len(manifest['animations'])} animations x 4 directions")


if __name__ == "__main__":
    main()
