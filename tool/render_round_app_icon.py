#!/usr/bin/env python3
"""Build circular launcher assets from app_icon_source.png.

- Replaces near-white fringe with the same dark green sampled from the artwork.
- Writes adaptive foreground (transparent outside circle) + legacy square (green outside circle).
- Updates assets/branding/app_icon_source.png for iOS/web icon regeneration.

Run from repo root: python tool/render_round_app_icon.py
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image


def _repo_root() -> str:
    return os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def _sample_dark_green(rgb: np.ndarray) -> np.ndarray:
    """rgb: (N,3) uint8 — pick typical dark green from non-white edge pixels."""
    if rgb.size == 0:
        return np.array([12, 28, 18], dtype=np.uint8)
    lum = 0.299 * rgb[:, 0] + 0.587 * rgb[:, 1] + 0.114 * rgb[:, 2]
    mask = lum < 120
    pool = rgb[mask] if mask.any() else rgb
    return np.clip(pool.mean(axis=0), 0, 255).astype(np.uint8)


def _replace_white(arr: np.ndarray, green: np.ndarray) -> np.ndarray:
    """RGBA array; replace near-white pixels with green (opaque)."""
    out = arr.copy()
    r, g, b, a = out[:, :, 0], out[:, :, 1], out[:, :, 2], out[:, :, 3]
    white = (r.astype(np.int32) + g.astype(np.int32) + b.astype(np.int32) > 680) & (
        np.minimum(np.minimum(r, g), b) > 225
    )
    out[white, 0] = green[0]
    out[white, 1] = green[1]
    out[white, 2] = green[2]
    out[white, 3] = 255
    return out


def main() -> int:
    root = _repo_root()
    src_path = os.path.join(root, "assets", "branding", "app_icon_source.png")
    if not os.path.isfile(src_path):
        print(f"Missing {src_path}", file=sys.stderr)
        return 1

    img = Image.open(src_path).convert("RGBA")
    # Square canvas
    w, h = img.size
    side = max(w, h)
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(img, ((side - w) // 2, (side - h) // 2))
    arr = np.array(canvas, dtype=np.uint8)

    # Edge samples for green (exclude white)
    e = np.concatenate(
        [arr[0, :, :3], arr[-1, :, :3], arr[:, 0, :3], arr[:, -1, :3]], axis=0
    )
    green = _sample_dark_green(e)
    fixed = _replace_white(arr, green)

    yy, xx = np.ogrid[: side, : side]
    cy = cx = (side - 1) / 2.0
    radius = side * 0.46
    inside = (xx - cx) ** 2 + (yy - cy) ** 2 <= radius**2

    # Adaptive foreground: inside circle = art, outside = transparent
    fg = np.zeros_like(fixed)
    fg[:, :, :3] = fixed[:, :, :3]
    fg[:, :, 3] = np.where(inside, fixed[:, :, 3], 0).astype(np.uint8)
    # Premultiply-ish: zero RGB outside for cleaner edges
    fg[~inside, :3] = 0

    # Legacy square icon: outside circle = solid green, inside = art
    legacy = np.zeros_like(fixed)
    legacy[:, :, 0] = green[0]
    legacy[:, :, 1] = green[1]
    legacy[:, :, 2] = green[2]
    legacy[:, :, 3] = 255
    legacy[inside] = fixed[inside]

    nodpi = os.path.join(root, "android", "app", "src", "main", "res", "drawable-nodpi")
    os.makedirs(nodpi, exist_ok=True)

    fg_path = os.path.join(nodpi, "ic_brand_launcher_fg.png")
    Image.fromarray(fg).save(fg_path, optimize=True)

    legacy_rgb = Image.fromarray(legacy).convert("RGB")
    for folder, px in (
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ):
        out_dir = os.path.join(root, "android", "app", "src", "main", "res", folder)
        os.makedirs(out_dir, exist_ok=True)
        legacy_rgb.resize((px, px), Image.Resampling.LANCZOS).save(
            os.path.join(out_dir, "ic_brand_launcher.png"), optimize=True
        )
    print("  wrote mipmap-*/ic_brand_launcher.png (legacy round-composition)")

    # Master asset for flutter_launcher_icons (iOS / web): same as legacy square
    Image.fromarray(legacy).save(src_path, optimize=True)

    # iOS launch screen (storyboard still references LaunchImage).
    ios_set = os.path.join(root, "ios", "Runner", "Assets.xcassets", "LaunchImage.imageset")
    if os.path.isdir(ios_set):
        im_legacy = Image.fromarray(legacy).convert("RGB")
        for name, size in (
            ("LaunchImage.png", 256),
            ("LaunchImage@2x.png", 512),
            ("LaunchImage@3x.png", 768),
        ):
            im_legacy.resize((size, size), Image.Resampling.LANCZOS).save(
                os.path.join(ios_set, name), optimize=True
            )
        print(f"  updated iOS LaunchImage.imageset (3 sizes)")

    values_dir = os.path.join(root, "android", "app", "src", "main", "res", "values")
    os.makedirs(values_dir, exist_ok=True)
    colors_path = os.path.join(values_dir, "brand_icon_colors.xml")
    with open(colors_path, "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n')
        f.write(
            f'    <color name="brand_icon_dark_green">#{int(green[0]):02x}{int(green[1]):02x}{int(green[2]):02x}</color>\n'
        )
        f.write("</resources>\n")

    hex_g = "#{:02x}{:02x}{:02x}".format(int(green[0]), int(green[1]), int(green[2]))
    print(f"OK sampled green {hex_g}")
    print(f"  wrote {fg_path}")
    print(f"  wrote {colors_path}")
    print(f"  updated {src_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
