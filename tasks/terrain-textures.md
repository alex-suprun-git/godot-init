---
id: terrain-textures
status: done    # ready | in-progress | review | blocked | done
worker: codex
issue: "#39"
branch: task/terrain-textures
---

# Terrain textures: grass, dry grass, dirt and macro variation

## Goal

The whole map ground currently reads as a flat green wash with a visible repeating diamond grid (see the lawn left of the 5-storey blocks in the default camera). Produce a small, coherent set of new or improved seamless ground textures that a custom terrain shader (integrator's job, not part of this brief) can blend and de-tile. Quality target: the lawns, bare earth and worn paths of a late-August Soviet-era housing estate, matching the existing facade/sidewalk/bridge painted style.

## Inputs

- `art/PROMPTS.md`, ground rules and items G1 (grass), G2 (dry grass), G5 (dirt), G8 (courtyard): top-down, orthographic, shadowless, seamless in both directions, late August.
- Current textures to inspect first: `init/assets/textures/ground_grass.png`, `ground_grass_dry.png`, `ground_dirt.png`, `ground_courtyard.png` (all 1254 x 1254 RGB). Judge them at 22 m per tile, which is how the map uses them (`init/scripts/map/city_map.gd`, `_ground_quad`; `district_builder.gd`, `_patch`).
- A current Godot screenshot as the camera/scale reference: `Godot --path init -- --autoplay --only=map --turbo --shots=<dir>` (Godot at `/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot`; keep captures outside the repo).
- `art/ASSET_PIPELINE.md` and `tools/asset_profiles.json` (`surface` profile, max edge 1024).
- Related style work to match: `art/source_images/sidewalks/README.md`, `art/source_images/bridges/`.

## What the shader will do with them (design constraints)

The integrator will sample the base texture twice at different rotation/scale and blend with noise, multiply a large-scale variation map, and cross-fade grass to dirt through a blend mask. So the textures must be:

1. **Tonally even**: no large light or dark blobs, no single memorable feature (a puddle, a boulder, a big leaf) that would visibly repeat when the tile is sampled twice. Variation at the 5 to 50 cm scale only.
2. **Truly seamless** in both directions. Verify by tiling 3 x 3 and inspecting the joints; do not trust a prompt that says "seamless".
3. **Mid-valued and neutral-ish**: the engine tints grass per season (`grass_tint`), so avoid baked-in strong colour casts or shadows.
4. **Consistent scale across the set**: a blade of grass, a pebble and a leaf have the same size in grass, dry grass and dirt, so blending between them looks natural.

## Deliverables (all seamless squares)

| Id | Content | Notes |
| --- | --- | --- |
| T1 | Grass, new version of G1 | Tired late-August lawn: mixed blade lengths, clover, a few dry stalks, tiny bare spots. Less saturated and less regular than now. |
| T2 | Dry grass / wasteland, new version of G2 | Same scale and palette family as T1, drier, more bare earth and fine gravel. |
| T3 | Dirt, new version of G5 | Packed earth with fine gravel, sparse weeds, faint trampling texture. Tyre tracks only if they stay subtle and non-directional. |
| T4 | Macro variation map | Grayscale, large-scale (the tile covers about 120 m), soft blotches of lush/dry/yellowed tone. Seamless. Optional: a second grayscale detail map (stalks and pebbles) for close zoom. |
| T5 | Optional clutter | A transparent sheet of 6 to 10 small fallen leaves / grass tufts for decals. Only if T1 to T4 are approved. |

If the existing G1/G2/G5 are judged good enough after inspection, optimise instead of regenerating and say so in the report. Keep `ground_courtyard.png` out of scope unless it visibly clashes with the new set.

## Constraints

- Generate with the Codex image model. Save untouched originals under `art/source_images/terrain/` with the prompt next to each image (`README.md` there) and record the prompts in `art/PROMPTS.md`. Never generate into `init/assets/`.
- Present the originals for approval before optimisation. After approval run `uv run tools/optimize_asset.py ... --profile surface --approved` and write to `init/assets/textures/` under new names (`ground_grass_v2.png`, `ground_grass_dry_v2.png`, `ground_dirt_v2.png`, `ground_macro_variation.png`); do not overwrite the current files and do not touch the `ground_snow_*` set.
- Style: painted, photographic-leaning, restrained colours, no cartoon outlines, no text, no objects with a shadow.

## Outputs

Write only to these paths:

- `art/source_images/terrain/` (originals, prompts, README)
- `art/optimization_reports/` (optimizer reports)
- `init/assets/textures/ground_grass_v2.png`, `ground_grass_dry_v2.png`, `ground_dirt_v2.png`, `ground_macro_variation.png` (+ optional detail/clutter)
- `art/PROMPTS.md` (append the new prompts only)

## Acceptance criteria

- [ ] The current textures were inspected at map scale; the report says what exactly looks wrong (tiling grid, flat colour, scale) and how each new texture fixes it.
- [ ] Each new texture is shown tiled 3 x 3 (preview PNG in `art/source_images/terrain/`); no visible seams or repeating hot spots.
- [ ] T1, T2, T3 placed side by side at equal scale look like one family.
- [ ] Optimised copies exist, reports recorded, sizes within the `surface` budget.
- [ ] The user approved the originals before optimisation.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- a creative choice is not covered by this brief (for example a clearly different season or palette);
- seamlessness cannot be reached without cropping or manual seam repair that changes the look;
- the work would require editing files outside *Outputs*.

## Report

_Filled in by the worker._

- **Status summary:**
- **Files created or changed:**
- **Measurements / previews:**
- **Open questions:**
- **Requests for the integrator:** wire the shader (`terrain_ground.gdshader`) into `_ground_quad`/`_patch`, add the blend mask and refresh seasonal variants.

## Review notes

_Filled in by the lead after each review round._
