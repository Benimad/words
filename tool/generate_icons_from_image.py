"""Generates all Android launcher icons from a single source artwork.

Usage:
    python tool/generate_icons_from_image.py assets/Puzzle.png

Outputs:
  * mipmap-<density>/ic_launcher.png            legacy square icons (API < 26)
  * mipmap-<density>/ic_launcher_foreground.png adaptive foreground, artwork
                                                inset into the 66% safe zone
  * values/ic_launcher_background.xml           adaptive background colour
  * store/play_store_icon_512.png               Play Console listing icon
  * store/feature_graphic_1024x500.png          Play Console feature graphic

Adaptive icons are 108x108dp but launchers only guarantee the centre 72x72dp
is visible, so the artwork is scaled to ~72dp and centred on a colour sampled
from the source image. That way no mask shape (circle, squircle, teardrop)
can ever clip the logo.
"""

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

# Android launcher icon sizes, in px, per density bucket.
LEGACY_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# Adaptive layers are 108dp; same buckets, scaled by 108/48.
ADAPTIVE_SIZES = {name: round(size * 108 / 48) for name, size in LEGACY_SIZES.items()}

# Fraction of the 108dp canvas the artwork occupies. 0.67 keeps it inside the
# guaranteed-visible 72dp circle with a hair of margin.
SAFE_ZONE_RATIO = 0.67

RES = Path("android/app/src/main/res")
STORE = Path("store")


def round_corners(img: Image.Image, radius_ratio: float = 0.215) -> Image.Image:
    """Makes the artwork's corners transparent.

    Pre-made app icons are usually exported as a rounded plate on an opaque
    (often black) square. Left alone that square shows up as a hard black box
    behind every launcher mask and in the store graphics, so the corners are
    cut to alpha 0 along a radius matching the artwork's own rounded frame.
    """
    size = img.size[0]
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1),
        radius=int(size * radius_ratio),
        fill=255,
    )

    out = img.copy()
    # Combine with any alpha the source already had, so genuinely
    # transparent regions stay transparent.
    existing = out.getchannel("A")
    out.putalpha(Image.composite(existing, Image.new("L", img.size, 0), mask))
    return out


def dominant_border_color(img: Image.Image) -> tuple:
    """Samples the artwork's outer frame for the adaptive background colour.

    Sampling the frame (rather than averaging the whole image) picks up the
    icon's surrounding plate, so the adaptive background reads as a natural
    extension of the artwork instead of an unrelated block of colour.

    Two guards matter here: fully/partly transparent pixels are skipped (the
    rounded corners of a pre-made icon are transparent, and averaging them in
    drags the result toward grey), and so are near-white pixels, which on this
    kind of artwork belong to the letter tiles rather than the frame.
    """
    rgba = img.convert("RGBA")
    w, h = rgba.size
    inset = max(1, int(min(w, h) * 0.03))  # on the frame, outside the tiles

    samples = []

    def probe(x: int, y: int) -> None:
        r, g, b, a = rgba.getpixel((x, y))
        if a < 250:
            return  # transparent corner
        if r > 235 and g > 235 and b > 235:
            return  # a letter tile, not the frame
        samples.append((r, g, b))

    for x in range(inset, w - inset, max(1, w // 120)):
        probe(x, inset)
        probe(x, h - inset - 1)
    for y in range(inset, h - inset, max(1, h // 120)):
        probe(inset, y)
        probe(w - inset - 1, y)

    if not samples:  # pathological artwork: fall back to the brand violet
        return (0x6C, 0x4C, 0xF1)

    n = len(samples)
    return (
        sum(s[0] for s in samples) // n,
        sum(s[1] for s in samples) // n,
        sum(s[2] for s in samples) // n,
    )


def main() -> None:
    source_path = Path(sys.argv[1] if len(sys.argv) > 1 else "assets/Puzzle.png")
    source = Image.open(source_path).convert("RGBA")

    # Square-crop from the centre if the artwork is not already square.
    if source.width != source.height:
        side = min(source.width, source.height)
        left = (source.width - side) // 2
        top = (source.height - side) // 2
        source = source.crop((left, top, left + side, top + side))

    # Cut the opaque square backing off the artwork before anything else uses it.
    source = round_corners(source)

    bg = dominant_border_color(source)
    print(f"source: {source_path} ({source.width}x{source.height})")
    print(f"adaptive background sampled as #{bg[0]:02X}{bg[1]:02X}{bg[2]:02X}")

    # --- Legacy square icons -------------------------------------------
    for density, size in LEGACY_SIZES.items():
        out_dir = RES / f"mipmap-{density}"
        out_dir.mkdir(parents=True, exist_ok=True)
        source.resize((size, size), Image.LANCZOS).save(out_dir / "ic_launcher.png")
        print(f"  wrote mipmap-{density}/ic_launcher.png ({size}px)")

    # --- Adaptive foreground -------------------------------------------
    for density, canvas_size in ADAPTIVE_SIZES.items():
        out_dir = RES / f"mipmap-{density}"
        out_dir.mkdir(parents=True, exist_ok=True)

        art_size = round(canvas_size * SAFE_ZONE_RATIO)
        art = source.resize((art_size, art_size), Image.LANCZOS)

        canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
        offset = (canvas_size - art_size) // 2
        canvas.paste(art, (offset, offset), art)
        canvas.save(out_dir / "ic_launcher_foreground.png")
        print(
            f"  wrote mipmap-{density}/ic_launcher_foreground.png "
            f"({canvas_size}px canvas, {art_size}px art)"
        )

    # --- Adaptive background colour ------------------------------------
    (RES / "values").mkdir(parents=True, exist_ok=True)
    (RES / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<!-- Sampled from the launcher artwork by "
        "tool/generate_icons_from_image.py -->\n"
        "<resources>\n"
        f'    <color name="ic_launcher_background">'
        f"#{bg[0]:02X}{bg[1]:02X}{bg[2]:02X}</color>\n"
        "</resources>\n",
        encoding="utf-8",
    )
    print("  wrote values/ic_launcher_background.xml")

    # --- Play Store listing icon (512x512, no alpha allowed) -----------
    STORE.mkdir(parents=True, exist_ok=True)
    listing = Image.new("RGB", (512, 512), bg)
    art = source.resize((512, 512), Image.LANCZOS)
    listing.paste(art, (0, 0), art)
    listing.save(STORE / "play_store_icon_512.png")
    print("  wrote store/play_store_icon_512.png")

    # --- Feature graphic (1024x500) ------------------------------------
    # A blurred, enlarged copy of the artwork makes the backdrop, with the
    # crisp icon centred on top — a standard, quick-to-read listing banner.
    feature = Image.new("RGB", (1024, 500), bg)
    backdrop = source.resize((1024, 1024), Image.LANCZOS).filter(
        ImageFilter.GaussianBlur(48)
    )
    feature.paste(backdrop.crop((0, 262, 1024, 762)).convert("RGB"), (0, 0))

    badge_size = 380
    badge = source.resize((badge_size, badge_size), Image.LANCZOS)
    feature.paste(badge, ((1024 - badge_size) // 2, (500 - badge_size) // 2), badge)
    feature.save(STORE / "feature_graphic_1024x500.png")
    print("  wrote store/feature_graphic_1024x500.png")

    print("\nDone.")


if __name__ == "__main__":
    main()
