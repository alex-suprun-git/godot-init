#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["Pillow==12.0.0", "numpy"]
# ///
"""Procedural bridge textures sized for the default map camera (see tasks/bridge-texel-density.md).

Every feature is large in metres so that it still covers >= 3 screen pixels at
about 4 px per metre; anything finer is a soft hint, never a single stone.
Run: uv run art/source_images/bridges/generate_bridge_textures.py
"""
from pathlib import Path

import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parent
SIZE = 256


def noise(rng, cells, size=SIZE):
    """Tileable smooth noise in 0..1 with `cells` features across the tile."""
    grid = rng.random((cells, cells))
    xs = np.arange(size) / size * cells
    i0 = np.floor(xs).astype(int) % cells
    i1 = (i0 + 1) % cells
    t = xs - np.floor(xs)
    t = t * t * (3 - 2 * t)
    rows = grid[i0][:, :] * (1 - t)[:, None] + grid[i1][:, :] * t[:, None]  # blend along y
    return rows[:, i0] * (1 - t)[None, :] + rows[:, i1] * t[None, :]


def to_image(rgb):
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def band(size, metres_per_tile, centre_m, width_m, soft_m):
    """1 inside a band of `width_m` around `centre_m` (wraps), soft edges."""
    p = (np.arange(size) / size * metres_per_tile - centre_m + metres_per_tile / 2) % metres_per_tile - metres_per_tile / 2
    return np.clip((width_m / 2 + soft_m - np.abs(p)) / soft_m, 0, 1)


def concrete(rng):
    tile_m = 8.0  # two 4 m slabs per repeat
    base = np.array([134.0, 129.0, 119.0])
    patch = noise(rng, 3) * 0.6 + noise(rng, 6) * 0.4  # 1.3-2.7 m patches
    warm = noise(rng, 4)
    img = base[None, None, :] * (0.82 + 0.36 * patch[..., None])
    img += (warm[..., None] - 0.5) * np.array([10.0, 2.0, -9.0])  # warm/cool drift
    # Slab joints: 0.6 m dark soft bands every 4 m, both directions.
    joint = np.zeros((SIZE, SIZE))
    for c in (0.0, 4.0):
        joint = np.maximum(joint, band(SIZE, tile_m, c, 0.5, 0.25)[:, None])
        joint = np.maximum(joint, band(SIZE, tile_m, c, 0.5, 0.25)[None, :])
    img *= (1 - 0.38 * joint)[..., None]
    # Dirt: darker streaks running along one axis, ~1.5 m wide.
    dirt = noise(rng, 5)
    img *= (1 - 0.12 * np.clip((dirt - 0.5) * 3, 0, 1))[..., None]
    return to_image(img)


def ballast(rng):
    tile_m = 6.0
    base = np.array([113.0, 107.0, 100.0])
    patch = noise(rng, 3) * 0.5 + noise(rng, 6) * 0.5
    chunk = noise(rng, 9)  # ~0.7 m lighter/darker clumps: the smallest stone hint
    img = base[None, None, :] * (0.72 + 0.56 * patch[..., None]) * (0.85 + 0.30 * chunk[..., None])
    warm = noise(rng, 4)
    img += (warm[..., None] - 0.5) * np.array([14.0, 3.0, -12.0])
    # Oily dark strip along the track axis (v direction) with soft sides.
    img *= (1 - 0.35 * band(SIZE, tile_m, 3.0, 1.2, 0.7)[None, :, None])
    # Sleeper hint: dark bands across the track (along z = rows) every 1.5 m, 0.6 m wide.
    stripes = np.zeros(SIZE)
    for c in np.arange(0.0, tile_m, 1.5):
        stripes = np.maximum(stripes, band(SIZE, tile_m, c, 0.6, 0.2))
    img *= (1 - 0.30 * stripes)[:, None, None]
    return to_image(img)


def steel(rng):
    tile_m = 8.0
    base = np.array([104.0, 119.0, 123.0])
    patch = noise(rng, 4) * 0.6 + noise(rng, 8) * 0.4
    img = base[None, None, :] * (0.92 + 0.16 * patch[..., None])
    rust = np.clip((noise(rng, 5) - 0.55) * 3.0, 0, 1)  # 1-2 m rust blotches
    img = img * (1 - rust[..., None]) + np.array([112.0, 84.0, 66.0]) * rust[..., None]
    return to_image(img)


if __name__ == "__main__":
    for name, fn, seed in (("concrete", concrete, 11), ("ballast", ballast, 12), ("steel", steel, 13)):
        fn(np.random.default_rng(seed)).save(OUT / f"bridge_{name}_v2.png")
        print("wrote", f"bridge_{name}_v2.png")
