# Vehicle modelling and shape revisions

Use for original vehicles, including buses, and body-shape edits. The RAF, PAZ and ZIL models are the dimension and visual-quality benchmarks; SKILL.md ("Vehicle benchmarks") defines how to compare against them. Sourcing/acquisition remains
in `asset-sourcing.md`; MCP execution and export scoping remain in `SKILL.md`.

## Establish the vehicle, then its form

Reuse modelling helpers and pipeline stages, not a previous car's cabin shape.
A UAZ should not become a rescaled Volga or Lada. Resolve the actual variant
when it affects the silhouette; do not infer an approved variant or styling
from a different vehicle's brief.

Read the asset record and visual references. Identify wheel centres, body
endpoints, beltline, A/B/C pillars, roof crown, window/door outlines and deck
lengths before adding lamps, handles or grille slats. Use side/front/three-
quarter references to distinguish proportions from perspective distortion.
Reference photographs guide form; establish world dimensions independently.

Inspect a cheap geometry preview before baking. Check the whole silhouette
from side, front, rear and three-quarter, including the intended map angle.
Treat recognisable upper-body shape as part of the initial build, rather than
leaving a generic trapezoid under detailed trim.

## Build connected surfaces

- Model broad curvature with longitudinal/transverse sections or another
  appropriate surface representation. Roof crown, bonnet/boot curvature and
  rolled edges need actual silhouette geometry. Smooth normals alone cannot
  correct a flat roof or box-shaped body; narrow bevels only soften corners.
- Use curvature appropriate to the reference. Rounded sedans and upright vans
  need different profiles. Avoid globally rounding deliberate vehicle edges.
- Coordinate roof, pillars, glass, gutters and door frames from shared surface
  functions/landmarks. Changes to cabin length must move the rear glass, door
  edges, quarterlights, trim and panel gaps coherently.
- Tessellate curved windscreens along their curvature. A sparse triangle fan
  can cut through the underlying crowned shell even when its boundary vertices
  fit. Inspect the actual mesh for intersections from several angles; match
  surface sampling and gasket clearance rather than hiding defects with tint.
- Window corner radii, pillar rake, quarterlights and door outlines can define
  the vehicle more strongly than small decorative details. Inspect these in
  close views as well as at map zoom. Ensure bright trim is visible outside
  seals instead of being enclosed inside a larger rubber tube.
- Sample bonnet/boot seams and cowl details on the revised deck surface.
  Old fixed-height outlines can float or disappear after adding curvature.
- Compare bumper height, depth, endcaps and guards against the reference as a
  group. Reducing just the chrome beam can leave massive surrounding blocks.

## Recover from a rejected silhouette

The 2026-11-04 SUV iterations exposed two distinct failures: a convincing generated reference was reduced to a generic box/loft, and later detail was added without fixing the silhouette. Do not use more fittings or higher triangle counts as evidence that a rejected shape has improved.

- Preserve the last export for comparison. Compare its side/front/top silhouette directly with the actual source sheet or prototype photo. Identify a small set of discrepancies (for example hood rake, cabin taper, rear-wall rake, glass height, wheel exposure and fender shape) and change the shared landmarks/surfaces that cause them.
- Resolve the main masses before finishing. Use a cheap matched before/after engine view to inspect the changed silhouette; retain camera, world scale and lighting. A favourable new camera cannot validate the revision.
- Keep physical dimensions separate from game presentation. Restore embedded scale when comparing real-size assets; use each approved model's actual map factor for the game-scale comparison. Label any proposed factor for a new asset. A real-size car beside a reduced RAF/PAZ/ZIL is a misleading comparison.
- Resolve generated projection inconsistencies rather than blindly tracing them. Use real prototype dimensions for the chosen variant and tyre/track settings; use the sheet to guide coherent form. Record ambiguities such as spare-wheel length conventions. Do not claim that arbitrary landmark adjustments are factory measurements.

## Preserve vehicle identity within the shared style

The sedan/Volga comparison on 2026-11-04 showed that matching overall length, width and height did not preserve W140-like identity: both read as a generic long three-box sedan, while the new car's cabin/glass was more compressed. In that construction, window insets consumed about 0.135 m of a roughly 0.405 m cabin height, leaving only about 0.27 m of glass. Those numbers describe that failed construction, not recommended dimensions.

Use approved fleet assets as finish/material/readability references, not as a universal cabin/body template. Compare the new model against its own prototype/sheet as well as the fleet benchmark. Inspect actual glass openings after seals/insets, pillar thickness, roof crown, belt/deck heights, shoulder sections and front/rear overhangs. Check their ratios in side and front views: bounding-box dimensions alone cannot establish shape accuracy. If changing colour, lamps and grille is doing most of the identity work, revisit the large surfaces before adding detail. Do not claim a new vehicle meets the benchmark merely because it has more geometry or a longer fittings list.

## Attach fittings to the revised shell

The 2026-11-04 SUV's headlamp/front panel floated because the shell ended behind separately positioned face geometry. Three-quarter reviews missed the visible side gap. Similar independent offsets can detach bumper corners, lens housings, indicators and trim after a body edit.

- Define a shared body/end surface or attachment frame. Derive housing backs, bumper returns and mounting points from that surface; derive lens faces from their housings. Do not maintain unrelated world-coordinate offsets for these layers.
- Build the visible connecting geometry: rear/side walls of lamp pods, the panel between face and shell, and bumper returns or brackets where the reference exposes them. Joining disconnected objects into one mesh does not fill the gap. Separate meshes are fine when their actual geometry seats correctly.
- Check each attachment's inward face against the local shell, accounting for curved/tapered corners and rolled edges. Use a deliberate seated overlap or a modelled recess; reserve a small outward offset for surface trim and lenses. Do not hide a centimetre-scale gap with a thicker decorative surround.
- After changes to length, nose slope, bumper depth or panel curvature, recompute those attachments together. Inspect a strict side and top view of the actual export in addition to the usual three-quarter view. Look specifically for daylight behind lamps, hovering indicators, open gaps behind bumper corners, buried lenses and doubled/floating trim. A broad overview alone is insufficient.
- Treat a visible disconnected fitting as an unfinished model, not a lighting issue or an acceptable simplification at map scale. Fix the attachment before further decorative work or a completion claim. These are construction/visual checks, not a request to add automated tests.

## Spend geometry on the silhouette

Choose budgets for the asset's screen size and number of visible instances.
The Volga brief used approximately 8k triangles / three materials for cars
6–24 px long among more than 100 vehicles; this is a worked brief, not a fixed
budget for every future vehicle or viewing distance.

Preserve reviewed body/glass geometry first; simplify small fittings and bake
panel seams, grille/vent detail and other suitable marks into atlases. Do not
blindly decimate the entire car and flatten the newly approved curvature.
A section-built curved panel can be cheaper than a heavily bevelled box;
measure rather than estimating cost from how smooth it looks.

A verified Volga export uses body/paint, opaque glass and chrome/rubber atlas
materials, with base-colour and packed roughness/metallic maps. Preserve the
material naming expected by the tint system (`paint` in paint names). Choose
opacity/interior treatment from the asset brief and established style rather
than making windows transparent into an empty shell.

Measure the actual GLB's transformed vertex bounds, index triangle counts,
materials, primitives and embedded images. Build-script constants and source
counts do not prove the game export fits. If adapting fitting reduction to the
remaining budget, retain an integer margin and inspect the resulting shapes.

## Make revisions comparable and resumable

Keep body, cabin/glazing, fittings, bake, export and preview as separable stages
where useful. Keep their geometry parameters in asset-owned scripts. Archive
the relevant previous GLB and build state before a substantial revision so
accepted proportions can be compared or recovered without rebuilding history.

Render old/new GLBs in the same scene, at unchanged scale and identical camera/
lighting; include side views on a 1 m grid and the map-camera view. Label or
record which version is which. A new flattering angle is not a shape comparison.

Read the generated images, then inspect the imported GLB in Godot. An isolated
engine preview is useful for asset review; a city-map integration still needs
an actual game frame for grounding and contextual scale. Distinguish these
checks and record which was performed.

Bumper/deck edits may change total bounds while the body/wheelbase stays fixed.
When integrating, update source length and requested map length consistently
so correcting a bumper does not rescale the whole car unintentionally.

Keep current measurements, rebuild commands, inspected preview paths, accepted
visual directions and remaining review points in the asset README/task report.
Do not claim a generic inspector or a universal vehicle generator exists.

## Worked examples in the repository

Use the RAF and PAZ sources as the staged workflow to copy: body build,
finish/bake, export with GLB measurements and a matched Godot preview.

- `art/models/raf_ambulance/`: `build_raf.py`, `export_raf.py`,
  `glb_inspection.json`, `raf_ambulance.blend` and the asset README.
- `art/models/public_transport/`: `build_buses.py`, `finish_buses.py`,
  `preview_buses.py`, `preview_buses.gd` and the asset README.

The Volga's editable sources (`build_volga.py` and its stage scripts) were
kept only in a worktree and are lost; only `volga_gaz24.glb` remains. Do not
look for them or describe them as available. The Volga figures above (about
8k triangles, three atlas materials) remain a useful budget data point, not a
benchmark.
