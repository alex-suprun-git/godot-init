---
id: bridge-texel-density
status: ready   # ready | in-progress | review | blocked | done
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

- **Status summary:**
- **Screen px per metre (method):**
- **Files created or changed:**
- **Measurements / previews:**
- **Open questions:**
- **Requests for the integrator:**

## Review notes

_Filled in after each review round._
