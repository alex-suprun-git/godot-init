# Railway texture refresh — 2026-11-01

The user requested refreshing the existing 2D track artwork and expressed uncertainty about adding 3D rails at this stage. This revision retains the existing flat textured track geometry and material setup.

## Current asset

- Built-in ImageGen edit: `art/source_images/railway/ground-rail-v2.png`; exact prompt and input roles: adjacent `ground-rail-v2.prompt.md`.
- Previous game texture preserved verbatim as `art/source_images/railway/ground-rail-v1.png`.
- References: previous track texture (layout), existing `bridge_ballast.png` (material family), and current Godot capture `before-north-detail.png` (map context).
- Intact wooden sleepers, reduced oxidation with clearer steel running surfaces, almost no vegetation, neutral grey-brown aggregate. This applies the established maintained-city direction to the user's requested refresh. The new source was visually inspected before processing; final user appearance review remains pending. No claim of pixel-exact layout preservation or exact seamlessness is made.
- Separately prepared with `uv run tools/optimize_asset.py art/source_images/railway/ground-rail-v2.png --profile surface --output init/assets/textures/ground_rail.png --approved --overwrite`. Preparation approval uses the already agreed maintained-city direction and explicit refresh request, not a claim of final appearance sign-off.
- Original 1254 × 1254 opaque RGB, 3,919,388 bytes; game copy 1024 × 1024 RGB, 2,363,790 bytes. No cropping or palette quantization. Report: `art/optimization_reports/ground_rail.png.json`.

## Inspection

Godot 4.7.1 asset import and focused graphical capture completed with exit 0. The optimized texture and actual game close-ups on the northern overpass and beside the station were inspected. Rails and sleepers read more clearly and less overgrown. `before-*` and `after-*` captures are real Godot frames; moving traffic and lighting differ slightly between runs. The inherited shutdown warnings about four ObjectDB instances/two resources remain; no new script or import errors occurred. No automated tests were added or run.

The lighter track strip still has a hard boundary against the darker, finer surrounding embankment ballast. That separate material/edge treatment was not changed by this texture refresh. Flatness at shallow angles remains a limitation of the existing 2D approach. No sprite-anchor recalibration applies to a ground material texture. Winter continues using the existing year-round railway texture.

Reproduce:

```sh
Godot --path init --script "$PWD/art/railway/capture_map.gd" -- --no-log --hour=12 --output="$PWD/art/railway"
```

Next: user appearance review of `after-north-detail.png` and `after-station-detail.png`; any further ballast blending is a separate visual iteration. No commit or push made.
