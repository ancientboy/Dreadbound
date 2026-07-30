#!/usr/bin/env python3
"""Fail fast when a committed PNG has invalid chunks or compressed data."""

from __future__ import annotations

import binascii
from pathlib import Path
import struct
import sys
import zlib


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
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


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    paths = sorted(
        path
        for path in root.rglob("*.png")
        if not any(part in IGNORED_PARTS for part in path.relative_to(root).parts)
    )
    failures: list[str] = []

    for path in paths:
        try:
            validate_png(path)
        except (OSError, ValueError) as error:
            failures.append(f"{path.relative_to(root)}: {error}")

    if failures:
        print("PNG integrity validation failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(f"PNG integrity validation passed: {len(paths)} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
