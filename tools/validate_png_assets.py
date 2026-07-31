#!/usr/bin/env python3
"""Fail fast when a committed PNG or WebP has invalid container data."""

from __future__ import annotations

import binascii
from pathlib import Path
import struct
import sys
import zlib


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
WEBP_RIFF_SIGNATURE = b"RIFF"
WEBP_SIGNATURE = b"WEBP"
IGNORED_PARTS = {".git", ".godot", "builds", "exports"}


def validate_png(path: Path) -> None:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("invalid PNG signature")

    offset = len(PNG_SIGNATURE)
    chunks: list[bytes] = []
    saw_ihdr = False
    saw_iend = False

    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError("truncated chunk header")

        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        chunk_end = offset + 12 + length
        if chunk_end > len(data):
            raise ValueError(f"truncated {chunk_type.decode('ascii', 'replace')} chunk")

        payload = data[offset + 8 : offset + 8 + length]
        expected_crc = struct.unpack(">I", data[offset + 8 + length : chunk_end])[0]
        actual_crc = binascii.crc32(chunk_type + payload) & 0xFFFFFFFF
        if actual_crc != expected_crc:
            name = chunk_type.decode("ascii", "replace")
            raise ValueError(
                f"{name} CRC mismatch: expected {expected_crc:08x}, got {actual_crc:08x}"
            )

        if chunk_type == b"IHDR":
            if saw_ihdr or length != 13:
                raise ValueError("invalid IHDR chunk")
            saw_ihdr = True
        elif chunk_type == b"IDAT":
            chunks.append(payload)
        elif chunk_type == b"IEND":
            if length != 0:
                raise ValueError("invalid IEND chunk")
            saw_iend = True
            break

        offset = chunk_end

    if not saw_ihdr:
        raise ValueError("missing IHDR chunk")
    if not chunks:
        raise ValueError("missing IDAT data")
    if not saw_iend:
        raise ValueError("missing IEND chunk")

    try:
        zlib.decompress(b"".join(chunks))
    except zlib.error as error:
        raise ValueError(f"invalid IDAT stream: {error}") from error


def validate_webp(path: Path) -> None:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError("truncated WebP header")
    if data[:4] != WEBP_RIFF_SIGNATURE or data[8:12] != WEBP_SIGNATURE:
        raise ValueError("invalid RIFF/WEBP signature")

    declared_size = struct.unpack("<I", data[4:8])[0] + 8
    if declared_size != len(data):
        raise ValueError(
            f"RIFF size mismatch: header declares {declared_size} bytes, "
            f"file contains {len(data)}"
        )

    offset = 12
    chunks = 0
    while offset < len(data):
        if offset + 8 > len(data):
            raise ValueError("truncated WebP chunk header")
        chunk_type = data[offset : offset + 4]
        chunk_size = struct.unpack("<I", data[offset + 4 : offset + 8])[0]
        chunk_end = offset + 8 + chunk_size
        padded_end = chunk_end + (chunk_size & 1)
        if padded_end > len(data):
            name = chunk_type.decode("ascii", "replace")
            raise ValueError(f"truncated {name} chunk")
        offset = padded_end
        chunks += 1

    if chunks == 0:
        raise ValueError("missing WebP image chunks")
    if offset != len(data):
        raise ValueError("invalid WebP chunk alignment")


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    png_paths = sorted(
        path
        for path in root.rglob("*.png")
        if not any(part in IGNORED_PARTS for part in path.relative_to(root).parts)
    )
    webp_paths = sorted(
        path
        for path in root.rglob("*.webp")
        if not any(part in IGNORED_PARTS for part in path.relative_to(root).parts)
    )
    failures: list[str] = []

    for path in png_paths:
        try:
            validate_png(path)
        except (OSError, ValueError) as error:
            failures.append(f"{path.relative_to(root)}: {error}")

    for path in webp_paths:
        try:
            validate_webp(path)
        except (OSError, ValueError) as error:
            failures.append(f"{path.relative_to(root)}: {error}")

    if failures:
        print("Raster asset integrity validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(
        "Raster asset integrity validation passed: "
        f"{len(png_paths)} PNG and {len(webp_paths)} WebP files"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
