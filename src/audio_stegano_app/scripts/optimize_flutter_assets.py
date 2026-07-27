#!/usr/bin/env python3
"""Subset bundled TTFs and compress branding icons for smaller web/APK payloads.

Run from repo root or audio_stegano_app:
  python scripts/optimize_flutter_assets.py

Keeps full TTFs under assets/fonts/_full_backup/ (gitignored) for re-subset.
"""

from __future__ import annotations

from pathlib import Path

from fontTools.subset import Options, Subsetter, load_font, save_font
from PIL import Image

APP_ROOT = Path(__file__).resolve().parents[1]
FONTS = APP_ROOT / "assets" / "fonts"
BACKUP = FONTS / "_full_backup"
BRANDING = APP_ROOT / "assets" / "branding"
WEB = APP_ROOT / "web"
REPO_ROOT = APP_ROOT.parents[1]
DESKTOP_I18N = (
    REPO_ROOT
    / "src"
    / "audio_stegano_desktop"
    / "src"
    / "AudioStegano.Desktop"
    / "Localization"
)


def _collect_codepoints() -> set[int]:
    used: set[int] = set()
    paths = [
        APP_ROOT / "lib" / "app" / "app_strings.dart",
        APP_ROOT / "lib" / "app" / "metric_help_strings.dart",
        DESKTOP_I18N / "AppStrings.cs",
        DESKTOP_I18N / "MetricHelpStrings.cs",
    ]
    for path in paths:
        if path.is_file():
            used.update(ord(ch) for ch in path.read_text(encoding="utf-8", errors="ignore"))
    for r in (range(0x20, 0x7F), range(0xA0, 0x100), range(0x100, 0x180), range(0x200C, 0x2010)):
        used.update(r)
    used.update((0x2030, 0x20AC, 0x2122, 0x60C, 0x61B, 0x61F))
    return used


def _subset(src: Path, dst: Path, unicodes: list[int]) -> None:
    options = Options()
    options.layout_features = ["*"]
    options.no_hinting = True
    options.desubroutinize = True
    font = load_font(str(src), options)
    subsetter = Subsetter(options=options)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)
    save_font(font, str(dst), options)
    print(f"{dst.name}: {src.stat().st_size / 1024:.1f} -> {dst.stat().st_size / 1024:.1f} KB")


def _ensure_backup(name: str) -> Path:
    BACKUP.mkdir(parents=True, exist_ok=True)
    live = FONTS / name
    bak = BACKUP / name
    if live.is_file() and not bak.is_file():
        bak.write_bytes(live.read_bytes())
    if bak.is_file():
        return bak
    if live.is_file():
        return live
    raise FileNotFoundError(name)


def optimize_fonts() -> None:
    used = _collect_codepoints()
    arabic = sorted(
        u
        for u in used
        if u < 0x0250
        or 0x0600 <= u <= 0x06FF
        or 0x0750 <= u <= 0x077F
        or 0x08A0 <= u <= 0x08FF
        or 0x200C <= u <= 0x200F
    )
    latin = sorted(
        set(u for u in used if u < 0x2500 and not (0x0600 <= u <= 0x06FF))
        | set(range(0x20, 0x7F))
        | set(range(0xA0, 0x180))
        | set(range(0x2000, 0x2070))
    )
    _subset(_ensure_backup("NotoSansArabic-Regular.ttf"), FONTS / "NotoSansArabic-Regular.ttf", arabic)
    _subset(_ensure_backup("Roboto-Regular.ttf"), FONTS / "Roboto-Regular.ttf", latin)
    _subset(_ensure_backup("Roboto-Bold.ttf"), FONTS / "Roboto-Bold.ttf", latin)
    medium = FONTS / "Roboto-Medium.ttf"
    if medium.exists():
        medium.unlink()
        print("removed Roboto-Medium.ttf")
    zip_path = FONTS / "noto-sans-arabic.zip"
    if zip_path.exists():
        zip_path.unlink()
        print("removed noto-sans-arabic.zip")


def _save_png(path: Path, size: int | None = None) -> None:
    if not path.is_file():
        return
    im = Image.open(path).convert("RGBA")
    if size is not None and max(im.size) > size:
        im = im.resize((size, size), Image.Resampling.LANCZOS)
    im.save(path, format="PNG", optimize=True)
    print(f"{path.name}: {path.stat().st_size / 1024:.1f} KB")


def optimize_icons() -> None:
    icon = BRANDING / "app_icon.png"
    if icon.is_file():
        full = BRANDING / "app_icon.full.png"
        if not full.exists():
            full.write_bytes(icon.read_bytes())
        _save_png(icon, 512)
    for name, size in (
        ("Icon-512.png", 512),
        ("Icon-maskable-512.png", 512),
        ("Icon-192.png", 192),
        ("Icon-maskable-192.png", 192),
    ):
        _save_png(WEB / "icons" / name, size)
    _save_png(WEB / "favicon.png", 32)


def remove_obsolete_web_fonts() -> None:
    fonts_dir = WEB / "fonts"
    if fonts_dir.is_dir():
        import shutil

        shutil.rmtree(fonts_dir)
        print("removed web/fonts (pubspec TTF is enough)")


def main() -> None:
    optimize_fonts()
    optimize_icons()
    remove_obsolete_web_fonts()
    total = sum(p.stat().st_size for p in FONTS.glob("*.ttf"))
    print(f"bundled TTF total: {total / 1024:.1f} KB")


if __name__ == "__main__":
    main()
