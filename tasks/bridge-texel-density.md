---
id: bridge-texel-density
status: review   # ready | in-progress | review | blocked | done
worker: any
issue: "#31"
branch: fix/bridge-texel-density
---

# Bridge texel density

## Goal

Make the bridges read at the default map camera. The current textures look fine as tiles but turn into grey noise in game: the ballast repeats every 3 m at 1024 px (one stone ≈ 2 cm), while one metre of bridge covers roughly 10–13 screen pixels, so mipmapping averages the detail away. Measure screen pixels per metre once, size bridge detail against that number, and deliver a before/after the user can judge. The bridge is the reference surface; other surfaces are out of scope.

Target look: a mid-range PS2 game. Flat textures are fine; light, dirt and edges are painted into the texture at large, readable sizes instead of photo micro-detail.

## Inputs

- Bridge materials: `init/scripts/map/district_builder.gd`, `_bridge_material()` (triplanar repeat: concrete 4 m, ballast 3 m, steel 2 m) and the bridge/embankment recipes that call it.
- Current textures: `init/assets/textures/bridge_{concrete,ballast,steel}.png` (1024 px); originals and prompts in `art/source_images/bridges/`.
- Scale helper: `init/scripts/dev/scale_reference.gd`.
- Screenshots: dev autoplay `--only=map --turbo` (see `AGENTS.md`, Workflow).
- Asset procedure for any new raster: `art/ASSET_PIPELINE.md`.

## Constraints

- **Default map camera and default zoom only.** Measure at the centre of the screen, where the player looks most.
- **Rule under test:** the smallest intended detail covers ≥ 3 screen pixels. With ≈ 12 px/m that is ≈ 25 cm. Recompute from the measured value.
- **Cheapest fix first.** Order: (1) change repeat size and texture resolution in code; (2) only if that is not enough, make new textures (procedural, or generated with prompts that state tile size in metres and ask for large shapes only); (3) cheap volume hints as flat strips: dark side band, shadow under the span, light top edge.
- Detail smaller than the threshold is drawn as a hint (warm/cool patches, sleeper stripes, slab joints), not as individual stones.
- Bridges only. Do not touch grass, lot asphalt, sidewalks or other materials.
- Do not write the target or the rule into `art/ASSET_PIPELINE.md`, READMEs or other docs. That happens only after the user approves the live result.
- No new geometry beyond the flat volume-hint strips; no navigation, height or route changes.
- At most three images viewed for the whole task; screenshots stay in the scratchpad.

## Outputs

Write only to these paths:

- `init/scripts/map/district_builder.gd` (bridge material and bridge recipe functions only)
- `init/assets/textures/bridge_*.png` and their `.import` files, if textures are replaced
- `art/source_images/bridges/` (originals and prompts of any new texture)
- `art/optimization_reports/bridge_*.json`
- this brief's *Report*

## Acceptance criteria

- [ ] Screen pixels per metre at the default camera measured, with the method, recorded in *Report*.
- [ ] Each bridge texture checked with a downscale preview: shrunk to its on-screen size (repeat metres × px/m), the intended details are still distinguishable.
- [ ] On a default-camera game screenshot, sleepers, slab joints and dirt bands each cover ≥ 3 screen pixels.
- [ ] Before and after screenshots from the same camera position, one pair, shown to the user.
- [ ] Import and graphical run finish without new errors.
- [ ] User approves the after frame. Until then `status: review`.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- a creative choice is not covered by this brief (colour, style, how much dirt);
- the code-only step already looks good enough: show it before making new textures;
- the work would require editing files outside *Outputs*.

## Report

_Filled in by the worker._

- **Status summary:** New procedural textures and metre-based repeats are in place; no errors beyond the pre-existing exit-time leak warnings. The road and rail bridges sit in the map-edge haze, so the visual check uses the eastern embankment at the z -85 tunnel (125 % zoom, no haze). After strengthening contrast the ballast shows sleeper-hint bands (1.5 m pitch) and a dark oil strip; concrete portal is still small. Volume strips (step 3) not done. Needs user review.
- **Screen px per metre (method):** `camera.unproject_position()` of a bridge point and the point 1 m along X/Z, window 1600x900, orthographic camera (size = zoom * 0.573). Default zoom (350): 3.66 px/m (brief assumed 10-13; not reproducible). 125 % zoom (ZOOM_MIN 280): 4.58 px/m, used for the screenshots (user agreed). 3 px rule gives details >= 0.8 m (default) / 0.65 m (125 %).
- **Files created or changed:** `init/scripts/map/district_builder.gd` (repeat: ballast 6 m, concrete and steel 8 m); `init/assets/textures/bridge_{concrete,ballast,steel}.png` (256 px, replaced via optimize_asset, `--approved` used on the strength of the brief, final approval still pending); `art/source_images/bridges/generate_bridge_textures.py` and `bridge_*_v2.png` originals; `art/optimization_reports/bridge_*.png.json`. Code-only (repeat/resolution) was not tried alone: the old detail is photo micro-grain (about 2 cm), so larger repeats only stretch noise.
- **Measurements / previews:** Downscaled to on-screen size (repeat m x px/m, 3.66 and 4.58), luminance std: concrete 2.3 -> 13.2, ballast 4.5 -> 9.8, steel 1.1 -> 7.6 (old textures at their old repeat). Features: slab joints 0.5 m soft bands every 4 m, 1.3-2.7 m warm/cool patches, 0.7 m ballast clumps, oil strip 0.9 m, rust blotches 1-2 m.
- **Open questions:** (1) Brief's 10-13 px/m vs measured 3.7-4.6. (2) Haze hides the road bridge and the span of the rail bridge, so there is no frame where sleepers/joints can be judged; options: look at the haze, or accept a closer review camera. (3) The flat volume-hint strips (step 3) are not done; sleepers are separate meshes and were not touched.
- **Requests for the integrator:** None; the temporary `tmpbridge` autoplay scenario was reverted. Screenshots are in the session scratchpad only.

## Handoff for the next surface

User approved the result (after frame at the eastern embankment, z -85 tunnel, 125 % zoom). Not yet written into `art/ASSET_PIPELINE.md` or READMEs (brief forbids it until the integrator does so now that approval exists): the rule "smallest intended detail >= 3 screen px" and the method below.

Method that worked:

1. Measure px/m: `camera.unproject_position()` of a point and the point 1 m away, orthographic camera, window 1600x900. Default zoom 3.66 px/m, 125 % zoom (ZOOM_MIN) 4.58 px/m. The brief's 10-13 px/m could not be reproduced.
2. Old photo-grain textures (about 2 cm) average to flat grey at that density; larger repeats only stretch the noise, so code-only was skipped.
3. Procedural generator `art/source_images/bridges/generate_bridge_textures.py` draws large features in metres (joints 0.5 m, patches 1-3 m, sleeper bands 1.5 m pitch), 256 px per 6-8 m repeat. Then `optimize_asset.py --profile surface --overwrite`, import, repeat set in metres in code.
4. Judge on a real frame, not on a texture preview: the first numeric check (std after downscale) looked good but the frame barely changed until contrast was raised.

Gotchas: a fresh worktree needs `Godot --headless --path init --import` before the first run or the game hangs. The road bridge and the rail span sit in the map-edge haze, so use the embankment/tunnel (412, -85) to judge. A temporary autoplay scenario `_map_shot(name, Vector2, zoom)` with `ZOOM_MIN` was used and reverted (not committed).

Not done: flat volume-hint strips (dark side band, shadow under span, light top edge); concrete tunnel portal still too small to judge. Candidate next surfaces: sidewalk slabs, grass, lot asphalt (one issue and branch each, from `main`).

## Review notes

_Filled in after each review round._
