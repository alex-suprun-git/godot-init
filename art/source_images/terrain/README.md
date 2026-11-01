# Terrain texture candidates — issue #39

## State and review (2026-11-01)

T1–T4 are v1 candidates generated with built-in ImageGen. The user positively approved the summer appearance of T1–T3 and requested an autumn review; T4 remains unapproved. Untouched sources are 1254 × 1254 RGB; exact prompts are adjacent `.prompt.txt` files. Original generation used the pre-shader map as context; the worktree was then fast-forwarded from `f0ed75e` to current main `fd1239f`, including terrain shader #42 and wear mask #46. The complete brief is `tasks/terrain-textures.md`. No game assets, scene bindings or shader sources were changed. No commit or push.

- `grass-v1.png`: fine olive lawn detail without the old conspicuous yellow patches.
- `grass-dry-v1.png`: muted straw/olive counterpart; currently reads as finer, denser dry grass than the brief's sparse wasteland interpretation.
- `dirt-v1.png`: neutral packed soil/fine gravel; lacks the sparse weeds mentioned in the brief.
- `macro-v1.png`: soft broad variation candidate. RGB channels are not exactly equal, and the horizontal wrap difference is greater than an ordinary interior neighbour difference. It is not certified as a seamless grayscale data map. Current main uses procedural macro noise, so this candidate was not bound in the game preview.

Local-only diagnostics (not committed): each source has a `*-repeat-3x3.png` review preview (three repeats on each axis, source downsampled for review only). `review-v1.png` compares those previews at equal scale. Colour candidates show no conspicuous straight seam in that reduced preview; full-resolution/mipmap seam review remains. `inspection-v1.json` records dimensions, mean RGB and diagnostic edge differences. These numbers do not prove seamlessness.

## Actual Godot inspection

Current main with old textures: `/private/tmp/terrain-textures-current/0_overview.png`. Current shader with candidate T1–T3: `/private/tmp/terrain-textures-candidate/0_overview.png`. Both use the default summer map camera and the same main version. The original pre-shader reference remains in `/private/tmp/terrain-textures-baseline/`.

Temporary external SceneTree harness `/private/tmp/terrain-texture-preview.gd` loads originals as ImageTextures, generates mipmaps, and replaces 149 grass/dry-grass/dirt sampler bindings in existing terrain materials at runtime only. It keeps the shader's existing tiling, compensation, seasonal tint, procedural macro noise and wear mask. This is an original-source appearance preview, not optimized integration. Current shader already greatly reduces the old diamond grid; candidate T1–T3 additionally reduce conspicuous yellow mottling but make lawns smoother/greener. No claim that all of #39 is complete.

Graphical map autoplay completed with the candidates. Baseline emitted shutdown resource warnings; candidate run completed without reported script/shader errors. No automated tests, winter/night review or frame-time comparison were performed.

## Next action

Summer appearance is approved; autumn was accepted as tolerable by the user, with no further colour adjustment requested. The same temporary preview harness rendered autumn with `--season=autumn`, at default 07:00 (dark autumn morning) and with lighting pinned using `--hour=12` (daylight). Captures: `/private/tmp/terrain-textures-autumn/` and `/private/tmp/terrain-textures-autumn-noon/`; inspected `0_overview.png` in each. The HUD still says 07:00 because the debug hour overrides lighting only. Existing autumn tint and daylight produce a substantially warmer ochre/olive ground; no separate autumn texture or tint changes were made. The map run completed with the existing shutdown resource warnings. Unrelated Volga import changes were present and left untouched.

T4 was corrected and approved as `macro-v2.png`; see Delivery.

Preparation completed for T1–T3 using the optimizer separately with `--profile surface --approved` for new names `ground_grass_v2.png`, `ground_grass_dry_v2.png`, `ground_dirt_v2.png` and, only if corrected/approved, `ground_macro_variation.png`. Sources stay outside `init/`; leave old and snow textures intact. Wiring is outside this worker brief's Outputs; request integration rather than editing shared scripts.

## Delivery

Approved T1–T3 copies exist under `init/assets/textures/ground_{grass,grass_dry,dirt}_v2.png`, each opaque RGB, 1024 × 1024, prepared with `uv run tools/optimize_asset.py art/source_images/terrain/<source>-v1.png --profile surface --approved --output init/assets/textures/<target>.png`.

T4: `macro-v2.png` is `macro-v1.png` converted to luminance and made periodic with a smoothed linear ramp per row and column (wrap step 3.0 → 0.75 grey levels; an interior step is 0.46). The user approved it from a 3 × 3 repeat on 2026-11-01; optimised to `init/assets/textures/ground_macro_variation.png`.

## Integration

`city_map.gd` loads the v2 grass, dry grass and dirt tiles for summer and autumn (snow set unchanged). The terrain shader samples `ground_macro_variation.png` instead of procedural noise: one tile per 120 m plus a second sample turned and 2.3 × smaller, re-centred on its mean and stretched by `macro_contrast` to the range the noise had. The default summer camera shows no tile grid or yellow mottling; lawns read greener and smoother than before, as in the earlier preview. The user approved summer and autumn in the running game on 2026-11-01; winter is left to #45. Night and frame time were not checked.
