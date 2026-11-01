---
id: sidewalk-textures
status: review
worker: lead
---

# Apply sidewalk textures to the district map

## Goal

Replace the plain sidewalk placeholder with readable, period-appropriate surfaces: light concrete slabs on the central civic avenue and lighter, finer asphalt on ordinary sidewalks. Prepare the existing generated candidates, preserve continuous material scale across intersections and inspect the result in the actual game.

This is a lead/integrator task because it edits shared rendering scripts. Do not dispatch it as a normal asset-worker brief. The user authorized lead execution on 2026-11-01; implementation is complete and final appearance review is pending.

## Inputs and current state

- `README.md`: current district and visual direction.
- `art/source_images/sidewalks/README.md`: source inventory, review state and technical limitations.
- `sidewalk-slabs-clean-v1.png`, `sidewalk-slabs-aged-v1.png`, `sidewalk-asphalt-v1.png` in that folder, with adjacent exact generation prompts.
- `art/ASSET_PIPELINE.md`: preserve originals, review, optimization and import workflow.
- `init/scripts/map/city_map.gd`: `_build_sidewalks()`, `_strip_pieces()` and `_ground_quad()`.
- `init/scripts/data/district_layout.gd`: `ROADS`, `sidewalk_width()` and stable `axis` road ID.

Sidewalks currently use an optional `ground_sidewalk.png` with a 4 m repeat, otherwise a flat placeholder colour. Three source textures exist; none has been optimized or integrated. Their exact seam continuity is unverified. The clean slab image has offset/clipped perimeter joints that may create narrow or doubled slabs when repeated.

## Implementation

1. Capture a current Godot view of the civic avenue and an ordinary residential street as the comparison baseline.
2. Inspect repeated patches of all three candidates, including left/right and top/bottom seams. Resolve conspicuous seams before integration, preserving originals and versioning corrected sources. Follow the image-generation skill for generated raster edits. Do not treat a prompt requesting seamlessness as proof.
3. Use clean slabs as the proposed central-avenue material and pedestrian asphalt as the ordinary-road default. The aged slab candidate is optional: do not invent a third district-wide placement rule merely to use every image. Record the exact road/segment assignment and any meaningful creative choice for review.
4. Prepare selected copies with `uv run tools/optimize_asset.py ... --profile surface --approved` after the applicable visual approval, then inspect optimizer reports and prepared images. Do not label unreviewed candidates approved. Existing approval of the material direction applies only within its actual scope.
5. Select sidewalk material through the existing road identity/data, with no parallel hand-maintained coordinate layout. Keep the highway's `walk: 0.0` and existing sidewalk widths, intersection cuts, crossings and pedestrian graph behaviour.
6. Use consistent world-aligned UVs across split strips and both road orientations. The slab design targets four approximately 50 cm slabs per axis in a 2 m texture repeat; reconcile the actual image pattern with that scale rather than reusing the old 4 m repeat blindly. Do not stretch square slabs to fit individual segments.
7. Keep pedestrian asphalt visibly lighter, slightly warmer and less coarse than the road. Tune under actual map lighting and zoom. Preserve restrained colours, modest wear and a maintained city; no widespread cracks, weeds or decay.
8. Import new assets and inspect actual Godot screenshots. Compare overview and close views, joints at road intersections, both strip orientations, zebra connections and daylight/night readability. Check winter behaviour so the new summer materials do not become conspicuously bare stripes against snow; reuse the existing seasonal approach where suitable without expanding into a full seasonal art pack.
9. Update the asset README and campaign documentation with implemented assignments, evidence and any remaining limitations; present actual game frames for review.

## Outputs

Lead-owned scope:

- `init/scripts/map/city_map.gd` (material choice and UV/season handling).
- `init/scripts/data/district_layout.gd` only if a small material selector is needed; preserve road geometry and gameplay data.
- Prepared `init/assets/textures/ground_sidewalk_*.png` and associated import files.
- `init/assets/shaders/sidewalk_surface.gdshader` and its generated UID if needed for world-aligned sampling of a seamless source region.
- Versioned sources, prompts and inspection evidence under `art/source_images/sidewalks/`.
- Matching optimizer reports under `art/optimization_reports/`.
- `art/PROMPTS.md`, `README.md`, this brief and its index entry.
- Godot comparison captures under `art/sidewalks/`.

## Acceptance criteria

- [x] Central-avenue and ordinary-road sidewalks have the intended distinct materials; exact assignment is documented.
- [x] Selected originals are preserved; prepared game copies and optimizer provenance reports exist.
- [x] Repetition inspected on both axes: no conspicuous joins, doubled edge joints or obvious repeating signature defects.
- [x] Slabs remain square at the documented world scale; split strips maintain UV continuity in both orientations.
- [x] Existing widths, junction cuts, crossing approaches and pedestrian connectivity are preserved; roads and lot surfaces are not inadvertently replaced.
- [x] Actual Godot overview/close-up comparison frames are read; road/sidewalk separation, daytime/nighttime and winter behaviour are recorded.
- [x] Relevant graphical run has no new script/import errors. No automated tests added or run.
- [x] Documentation distinguishes inspected implementation from pending user approval. No commit or push unless separately requested.

## Review boundaries

Resolve routine material binding, UV corrections and technical preparation independently. Ask only for material/placement choices that materially depart from the discussed central-slabs/ordinary-asphalt direction. Preserve unrelated uncommitted work. An asset worker given this task should return it to the lead instead of editing shared scripts.

## Report

- **Status summary:** Implemented and visually inspected on 2026-11-01. Ready for final appearance review; no required implementation work remains.
- **Files created or changed:** Shared sidewalk binding/strip rendering in `city_map.gd`; `sidewalk_surface.gdshader` and UID; two optimized textures/imports and matching provenance reports; preserved v2 correction attempt/prompt; source/campaign/prompt documentation; task index and captures/reproduction helpers under `art/sidewalks/`. Existing unrelated UI/traffic work was preserved. No layout data, navigation, scenes or sprite anchors changed.
- **Measurements / previews:** Both game images are opaque 1024px RGB. Slab sampling: joint centres (12,36)..(767,796), three slabs in 1.5 m; ordinary asphalt repeat 4 m after user review, with restrained metre-scale tone variation; winter uses existing snow textures with 4 m repeat. Actual Godot repeat preview and before/after/day/night/winter frames are saved under `art/sidewalks/`. Corner render overlaps were removed after initial graphical review. Full evidence and commands: `art/sidewalks/README.md`.
- **Verification:** Import, graphical captures and focused crosswalk autoplay exit 0; no new script/shader/import errors. Existing shutdown resource warnings also occur in the baseline. Pedestrians were observed crossing via the existing graph; no automated tests added/run or full-week playthrough performed.
- **Open questions:** Final user appearance review. Aged slabs were deliberately left as an unused candidate; no new placement decision is required for this implementation. Slight source tonal repetition remains at extreme close-up.
- **Next action:** Review `art/sidewalks/review-v2/junction.png` and `asphalt_detail.png`; archive the brief after final visual acceptance. No commit or push made.

## User review follow-up

2026-11-01: User screenshot exposed an almost uniform-looking asphalt strip and a white camera-clipped building edge. Corrected shader brightness/texture scale and added subtle world-anchored tone variation; camera distance is now independent of orthographic magnification and kept at least 600 m from its target. The corresponding junction now shows the full roof/walls rather than the white cut. Sources and game PNGs are unchanged. Current evidence: `art/sidewalks/review-v2/`, `review-v2-night/`, `review-v2-winter/`; details in `art/sidewalks/README.md`. Status stays `review` for the corrected appearance.

2026-11-01, local placement correction: the user requested a treeless median and asphalt sidewalks above the north intersection. Implemented using the `north_street` road's southern edge as the shared boundary; southern slabs/planting remain. Preserve the district RNG sequence when omitting median trees. Current frames: `art/sidewalks/review-v3/`. No navigation, road dimensions or raster assets changed.
