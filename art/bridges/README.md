# Bridge surfaces

## Current implementation — 2026-11-01

The user approved a material direction of maintained warm-grey concrete, grey-brown railway ballast and matte grey-blue painted steel, then requested implementation. All three original surfaces were generated with built-in ImageGen, inspected, separately optimized and integrated into the existing procedural geometry. Final in-game appearance awaits user review.

### Assignment

- All three eastern railway overpasses: textured concrete deck sides/abutments; ballast on the previously bare upper deck between and beside existing track strips; 0.7 m concrete maintenance edges, 0.12 m thick.
- Railway river bridge: same concrete for slab/piers; ballast and maintenance edges on flat deck and existing sloped approach; grey-blue steel on the existing truss MultiMesh.
- Road river bridge: concrete on deck structure, parapets and piers, including ramp slabs. Existing asphalt carriageway, lamps and traffic handoff remain.
- Terrain, rail positions, track/sleeper texture, road/tunnel dimensions, bridge heights, navigation and fog boundaries are unchanged. No new guardrails or rivet geometry were added in this texture phase. The small maintenance edges are visual geometry, not simulated walk routes.

### Sources and preparation

Untouched sources and complete exact prompts: `art/source_images/bridges/bridge-{concrete,ballast,steel}-v1.{png,prompt.md}`. Game textures: `init/assets/textures/bridge_{concrete,ballast,steel}.png`. Optimizer reports: `art/optimization_reports/bridge_*.png.json`.

All originals are 1254 × 1254 opaque RGB; prepared images are 1024 × 1024 RGB, surface profile, no cropping or palette quantization. Original bytes: concrete 3,429,425; ballast 4,219,983; steel 2,718,984. Optimized bytes: concrete 2,017,950; ballast 2,442,338; steel 1,535,368. Preparation approval follows the user's explicit approval of this material direction and request to implement it, not a claim of final in-game sign-off.

`district_builder.gd` caches four StandardMaterial3D variants (concrete, darker concrete, ballast and painted steel) with world-space triplanar sampling and anisotropic mip filtering. Concrete repeat 4 m, ballast 3 m, steel 2 m. Ballast albedo multiplier 0.65 separates it from concrete under bright summer light; darker concrete multiplier 0.8. Steel is painted/dielectric with roughness 0.75; other surfaces use 0.95. No new shader or Blender asset is required. Original unrelated market/park work in the same builder file was preserved.

### Verification and evidence

- `before/`: actual Godot baseline for north/highway/south overpasses and both river bridges.
- `after/`: corresponding final summer-day views plus north-overpass close-up.
- `front/`: second camera mode showing both tracks, deck coverage and edge continuity.
- `night/`: pinned 22:00 lighting captures; materials react to existing light without baked highlights.
- `materials.png`: three 6 × 6 m patches rendered with the actual cached materials, showing repetition across both axes. No conspicuous tile boundary was found in this preview or game views. Exact pixel-identical edge matching is not claimed; source tonal patterns can repeat at close viewing distances.

Godot 4.7.1 import and focused graphical capture runs completed with exit 0 and no new script/import errors. The pre-change baseline printed the already known four ObjectDB/two-resource shutdown warning. All three optimized textures, material repeat preview and actual game views were visually inspected. No automated tests or full-week autoplay were added/run. Seasonal snow art for the new ballast is not included; it follows the existing railway's year-round material treatment. No sprite-anchor refresh applies to these 3D surfaces. No commit or push made for this bridge phase.

The approved river mist still veils most of the river spans: this limits in-game inspection of distant steel/pier detail. The visible near-bank truss and isolated material preview were inspected; the far bank was not opened or revealed for this task.

### Reproduce

From repository root:

```sh
Godot --headless --path init --import
Godot --path init --script "$PWD/art/bridges/capture_map.gd" -- --no-log --hour=12 --output="$PWD/art/bridges/after"
Godot --path init --script "$PWD/art/bridges/capture_map.gd" -- --no-log --hour=12 --camera-mode=front --output="$PWD/art/bridges/front"
Godot --path init --script "$PWD/art/bridges/capture_map.gd" -- --no-log --hour=22 --output="$PWD/art/bridges/night"
Godot --path init --script "$PWD/art/bridges/preview_materials.gd" -- --no-log
```

Next action: user appearance review of `after/north_detail.png` and `after/rail_bridge.png`. No required implementation work remains in this texture phase.

## Continuous surfaces and road paint — 2026-11-01

Height-join correction (2026-11-02): the south tunnel at z=305 previously kept a flat 6 m deck while the adjacent embankment was already descending, leaving a 0.9–1.77 m step at the deck ends. The shared `DistrictLayout.embankment_height()` profile now holds full height through the tunnel and starts the southern descent at its landward end, z=311.5; the ramp still reaches ground at z=375. Terrain/track geometry and moving train sampling use the same profile. Actual Godot close-up and ER2 crossing were inspected without script/rendering errors; local evidence: `.local/railway-motion/south-join-{fixed,train}.png`. No automated tests were added or run.

User follow-up requested surfaces through to the fog, including the quay, and asked about the missing road markings. The full eastern embankment crown now shares the bridge ballast material, with a matching +0.015 m surface offset at deck joins. Grass remains on the slopes. The old broad grass gaps between textured bridge decks are gone, including the river-bridge approach.

Quay paving continues from `MapBoundaries.west_far_x()` to `east_far_x()` (currently x=-753..578), past fully opaque haze; its 6 m width, height and world-aligned paving scale remain. Existing six E-W asphalt continuations already reached those bounds. Sidewalk surfaces now follow these visual continuations too. Road markings are separate shader-painted geometry: dashed town centre lines and solid highway double/edge lines now use the extended visual road rectangles while retaining the original 8 m phase and junction exclusions. Navigation, gateway positions and traffic rules are unchanged. No new textures, imports or generated art were required.

Current evidence: `continuous/` (bridge/crown transitions), `edges/` (all six E-W road ends plus east/west quay). Captured and inspected in actual Godot daylight, exit 0, no new script errors; known shutdown resource warnings remain intermittent. Final crown height adjustment removed the light hairline at deck joins. Reproduction: `capture_map.gd -- --no-log --hour=12 --output=<continuous-dir>` and `capture_continuations.gd -- --no-log --hour=12 --output=<edges-dir>`. No automated tests or commits.
