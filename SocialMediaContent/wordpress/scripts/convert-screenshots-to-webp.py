"""Convert Cafe Bazaar 16:9 PNG screenshots to WebP for WordPress (fa + en)."""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

from PIL import Image

# .../SocialMediaContent/wordpress/scripts/this.py
WP_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = WP_ROOT.parents[1]
SRC16 = REPO_ROOT / "docs" / "cafebazaar" / "screenshots_16x9"
ICON = REPO_ROOT / "src" / "audio_stegano_app" / "assets" / "branding" / "app_icon.png"
LOCALES = ("fa", "en")

MAPPING = {
    "01_16x9.png": "featured-splash-intro.webp",
    "04_16x9.png": "embed-message-input.webp",
    "07_16x9.png": "embed-waveform-metrics.webp",
    "08_16x9.png": "extract-audio-file.webp",
    "09_16x9.png": "extract-recovered-text.webp",
    "10_16x9.png": "settings-theme-language.webp",
    "02_16x9.png": "guide-quick-start.webp",
    "03_16x9.png": "language-selection.webp",
    "06_16x9.png": "embed-message-length-dialog.webp",
}


def to_webp(src: Path, dst: Path, quality: int = 82) -> None:
    img = Image.open(src)
    if img.mode not in ("RGB", "RGBA"):
        img = img.convert("RGBA" if "A" in img.getbands() else "RGB")
    save_kw = {"quality": quality, "method": 6}
    if img.mode == "RGBA":
        img.save(dst, "WEBP", **save_kw)
    else:
        img.convert("RGB").save(dst, "WEBP", **save_kw)


def build_icons(out: Path) -> None:
    icon = Image.open(ICON).convert("RGBA")
    icon.save(out / "app-icon-sot-nehan.webp", "WEBP", quality=90, method=6)
    icon.resize((256, 256), Image.Resampling.LANCZOS).save(
        out / "app-icon-256.webp", "WEBP", quality=88, method=6
    )


def main() -> None:
    for locale in LOCALES:
        out = WP_ROOT / locale / "images"
        out.mkdir(parents=True, exist_ok=True)
        for src_name, dst_name in MAPPING.items():
            to_webp(SRC16 / src_name, out / dst_name)
        build_icons(out)
        print(f"OK {locale}/images")

    banner_script = Path(__file__).with_name("build-link-banners.py")
    subprocess.run([sys.executable, str(banner_script)], check=True)


if __name__ == "__main__":
    main()
