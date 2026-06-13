"""Build Myket/XWave link banners — English text only (no Persian in raster images)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WP_ROOT = Path(__file__).resolve().parents[1]
LOCALES = ("fa", "en")


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for name in ("segoeui.ttf", "arial.ttf", "calibri.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def banner(out: Path, title: str, subtitle: str, fname: str, *, bg=(24, 32, 48), accent=(0, 150, 136)) -> None:
    icon_path = out / "app-icon-256.webp"
    w, h = 1200, 400
    img = Image.new("RGB", (w, h), bg)
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, h - 8, w, h], fill=accent)

    if icon_path.exists():
        ic = Image.open(icon_path).convert("RGBA").resize((180, 180), Image.Resampling.LANCZOS)
        img.paste(ic, (60, 110), ic)

    draw.text((280, 130), title, fill=(255, 255, 255), font=_font(48))
    draw.text((280, 210), subtitle, fill=(180, 200, 220), font=_font(28))
    img.save(out / fname, "WEBP", quality=85, method=6)


def main() -> None:
    for locale in LOCALES:
        out = WP_ROOT / locale / "images"
        out.mkdir(parents=True, exist_ok=True)
        banner(out, "Audio Stegano", "Download on Myket — ir.ntk.audiowmark.app", "banner-myket-download.webp")
        banner(out, "XWave", "Project website — xwave.ir", "banner-xwave-site.webp", accent=(63, 81, 181))
        print(f"OK {locale}/banners")


if __name__ == "__main__":
    main()
