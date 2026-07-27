#!/usr/bin/env python3
"""Build playable 48x64 directional animation sheets from approved style art.

Each source is a four-character lineup on a flat chroma key.  This tool removes
the key, normalizes every character to the Player sprite baseline, then creates
the exact 6 columns x 4 rows layout consumed by Player.BodySprite.
"""
from pathlib import Path
from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "steadfast": ROOT.parent / "generated_images" / "exec-1e667d25-5306-45ff-9535-8346cbe995fd.png",
    "armorer": ROOT.parent / "generated_images" / "exec-2855107f-dc68-47a5-b244-2c4ff3038904.png",
    "resonant": ROOT.parent / "generated_images" / "exec-6492882e-5146-4d08-b48c-f31ec1c64f7e.png",
}
STYLES = {
    "steadfast": ["barrier_counter", "last_stand", "sacrifice_medic", "choke_control"],
    "armorer": ["weakpoint_sniper", "heavy_suppression", "demolition_traps", "relic_engineer"],
    "resonant": ["psychic_sense", "anomaly_ingestion", "echo_summoner", "aberrant_form"],
}


def keyed_to_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = pixels[x, y]
            # Remove the hard key and its antialiased edge.  The designs use
            # cyan, amber, violet and red accents, never this pure green.
            if g > 105 and g > r * 1.25 and g > b * 1.25:
                pixels[x, y] = (r, g, b, 0)
    return rgba


def character_from_quadrant(source: Image.Image, index: int) -> Image.Image:
    half_w, half_h = source.width // 2, source.height // 2
    x = (index % 2) * half_w
    y = (index // 2) * half_h
    quad = keyed_to_alpha(source.crop((x, y, x + half_w, y + half_h)))
    box = quad.getbbox()
    if box is None:
        raise RuntimeError("No visible character found in generated source")
    # Keep a little breathing room for protruding weapons and sleeves.
    return quad.crop(box)


def cell(character: Image.Image, direction: int, frame: int) -> Image.Image:
    # The generated designs are authored at a readable 3/4 angle.  Mirroring
    # provides the lateral direction, and a darker rear view retains a clear
    # directional read at the small in-game scale.
    art = character
    if direction in (1, 3):
        art = art.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if direction == 3:
        art = ImageEnhance.Brightness(art).enhance(0.69)
        art = ImageEnhance.Color(art).enhance(0.78)
    max_h, max_w = 56, 44
    scale = min(max_w / art.width, max_h / art.height)
    size = (max(1, round(art.width * scale)), max(1, round(art.height * scale)))
    art = art.resize(size, Image.Resampling.LANCZOS)
    output = Image.new("RGBA", (48, 64))
    bob = (0, 1, 1, 0, -1, -1)[frame]
    output.alpha_composite(art, ((48 - art.width) // 2, 61 - art.height + bob))
    # Downsampling can retain nearly transparent key-colored pixels at the
    # outline.  Remove only that invisible fringe, not the character edge.
    pixels = output.load()
    for y in range(output.height):
        for x in range(output.width):
            r, g, b, a = pixels[x, y]
            if a < 32:
                pixels[x, y] = (r, g, b, 0)
    return output


def write_sheet(character: Image.Image, target: Path) -> None:
    sheet = Image.new("RGBA", (288, 256))
    for direction in range(4):
        for frame in range(6):
            sheet.alpha_composite(cell(character, direction, frame), (frame * 48, direction * 64))
    sheet.save(target, "PNG", optimize=True)


def main() -> None:
    target_dir = ROOT / "assets/art/characters/professions/styles"
    target_dir.mkdir(parents=True, exist_ok=True)
    for pathway, source_path in SOURCES.items():
        if not source_path.exists():
            raise FileNotFoundError(source_path)
        source = Image.open(source_path)
        for index, style in enumerate(STYLES[pathway]):
            write_sheet(character_from_quadrant(source, index), target_dir / f"{style}_spritesheet.png")


if __name__ == "__main__":
    main()
