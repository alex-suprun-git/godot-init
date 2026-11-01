# Sidewalk material integration

Implemented and visually inspected in Godot 4.7.1 on 2026-11-01; final user appearance review pending. Task: `tasks/sidewalk-textures.md`. Source/provenance record: `art/source_images/sidewalks/README.md`.

## Material assignment

- `ROADS` entry with `id: axis`, south of the `north_street` junction: clean concrete slabs, approximately 50 cm square. Material repeats a measured three-by-three interior slab region every 1.5 m.
- The axis approach north of that junction and every other existing road with a nonzero `DistrictLayout.sidewalk_width()`: pedestrian asphalt, 4 m repeat with restrained world-anchored tone variation (updated after user review). This includes the north/south cross streets, eastern street and narrow civic lane.
- The river highway keeps `walk: 0.0`; yard/dirt roads gain no sidewalks. Widths, road geometry, zebra cuts, heights (0.15 m), navigation and pedestrian graphs are unchanged.
- Shared corners belong to the axis paving first. Already covered rectangles are subtracted from subsequent render strips, preserving the original combined footprint while preventing coplanar material overlap/flicker.
- Both materials use shared world-XZ coordinates; no per-fragment stretching or independently reset texture phase.
- Winter substitutes the existing snow-paving texture on the axis and snow-asphalt elsewhere (4 m repeats), with no new winter art. Summer and autumn use the new sources.
- The aged slab candidate remains unused pending an actual placement need.

## Files and preparation

`city_map.gd` owns binding and strip generation; `sidewalk_surface.gdshader` owns source-region sampling and unwrapped mip derivatives. Two shared materials are created per map, rather than one per sidewalk fragment. No gameplay data or scene file changed.

Prepared game images are `ground_sidewalk_slabs.png` (2,229,131 bytes) and `ground_sidewalk_asphalt.png` (2,282,587 bytes), both 1024px opaque RGB. Each was produced by the separate optimizer step, surface profile, from preserved v1 originals. See matching optimization reports. The v2 ImageGen correction attempt was not selected. Actual rendering of optimized images was inspected for detail loss.

## Visual verification

- `before/`: six baseline actual game frames before integration.
- `after/`: six final summer-day frames: `avenue`, `junction`, `residential` (eastern asphalt street), `overview`, `slabs_detail`, `asphalt_detail`.
- `night/` and `winter/`: matching focused captures of final materials at pinned 22:00 summer and 12:00 winter.
- `materials.png`: isolated Godot material-repeat inspection, four repeats per axis for slabs and 1.5 for asphalt. Sources are rendered directly by the real shader, not image-edited into a mockup.
- `crosswalks/`: existing graphical autoplay scenario, captures of yard/south/highway junctions and a naturally walking pedestrian. Console observed a pedestrian on the zebra near (-0.86, -6.5), 288 walkers and 32 marked crossings. The first run exposed corner overlap; the final run after deduplication is recorded in the log.
- New asset import completed with exit 0. Focused graphical captures and crosswalk autoplay completed with exit 0, no script/shader/import errors. Some runs print the pre-existing shutdown warning about four ObjectDB instances and two resources; the same warning occurred in the pre-change baseline.
- No automated tests were added or run; no full-week playthrough is claimed.

Inspected: material repeat preview; actual summer avenue, junction, residential street, overview and both close-ups; night avenue/residential; winter avenue/residential/overview; all four crosswalk autoplay frames. Thin slab joints remain readable close up, asphalt is smoother and lighter than road surfacing, transitions meet zebra approaches, and winter has no bare summer-material stripes. At wide zoom fine joints deliberately fade; at extreme close-up some source tonal repetition remains. Existing large lot paving and underlying road textures retain their previous scale/style.

## Reproduce

From project root, with the local Godot executable:

```sh
Godot --headless --path init --import
Godot --path init --script "$PWD/art/sidewalks/capture_map.gd" -- --no-log --hour=12 --output="$PWD/art/sidewalks/after"
Godot --path init --script "$PWD/art/sidewalks/capture_map.gd" -- --no-log --hour=22 --output="$PWD/art/sidewalks/night"
Godot --path init --script "$PWD/art/sidewalks/capture_map.gd" -- --no-log --hour=12 --season=winter --output="$PWD/art/sidewalks/winter"
Godot --path init --script "$PWD/art/sidewalks/preview_materials.gd" -- --no-log
Godot --path init -- --autoplay --only=crosswalks --turbo --no-log --hour=12 --shots="$PWD/art/sidewalks/crosswalks"
```

These are graphical capture tools, not automated gameplay tests. No commit or push was made. Next action: user review of `review-v3/junction.png` and `review-v3/avenue.png`; no required implementation work remains.

## User review correction — 2026-11-01

The user reported a strange white building edge and missing-looking sidewalk texture; screenshot preserved as `user-review-v1.png`. The original review had accepted the asphalt too readily: at the actual map distance its fine grain averaged into an almost uniform pale strip.

Corrected implementation:

- Orthographic camera distance is now at least 600 m, independently of `_zoom`; orthographic size still uses `_zoom`. This keeps tall nearby buildings behind the near clipping plane at close zoom without changing the ground framing or magnification. Perspective-camera behaviour is unchanged. The white cut at the building in the same junction view disappears; real roof and walls are visible instead.
- Pedestrian asphalt now repeats every 4 m rather than 2 m, multiplies linear albedo by 0.65, and adds subtle smooth world-anchored tonal variation on a 1.25 m grid (strength 0.22). This makes existing raster grain/variation readable without generating potholes or painting shadows. Slab albedo multiplier is 0.85 to reduce its washed-out appearance. Winter retains brightness 1.0 and zero added mottling.
- Raster sources and optimized copies are unchanged; this revision changes camera placement and rendering parameters only. `preview_materials.gd` now reflects the actual parameters; `materials-v1.png` preserves the old material review.
- Authoritative current summer captures are in `review-v2/`; matching night/winter runs are in `review-v2-night/` and `review-v2-winter/`. Earlier `after/`, `night/`, `winter/` are the first reviewed implementation. Focused graphical runs completed with no script/shader errors; known shutdown resource warnings can still occur. No automated tests were added or run.

## Northern approach correction — 2026-11-01

The user requested two local changes above the shown north junction: remove the median trees and use asphalt rather than slabs on the sidewalks. Both now derive their boundary from `north_street.rect.end.y` (currently z=-80), without a duplicate coordinate layout. The northern median retains its grass/kerbs but no trees; the southern avenue retains slabs and planted median. Sidewalk pieces are already split at the road by the existing intersection cuts. Skipped median trees still consume their deterministic appearance draws, preserving all later tree choices and placement elsewhere.

Latest current frames: `review-v3/junction.png`, `avenue.png`, `overview.png`; focused graphical capture exit 0 with no script errors. Daytime inspection confirms asphalt on the northern approach, empty northern median and preserved southern planting. No source textures, road geometry, navigation or crossing data changed. No automated tests added or run.
