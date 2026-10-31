# Vehicle modelling and shape revisions

Use for original cars/vans and body-shape edits. Sourcing/acquisition remains
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

## Verified worked example: Volga (2026-10-31)

The staged workflow was executed in
`../godot-worktrees/volga-gaz24-model/art/models/volga/`. Read its `README.md`
and task report to locate the current source; after integration, prefer the
corresponding asset record in the main checkout. Do not assume the worktree
has been merged or that its game export is the version currently used in town.

- `build_volga.py`: shared helpers, assembly and studio.
- `build_body_shell.py`: crowned bonnet/boot, rolled shoulders and wheel cuts.
- `build_upper_body.py`: coordinated roof, curved glass and rounded frames.
- `finish_volga.py`: three surfaces, atlas baking and fitting reduction.
- `export_volga.py`: selected-asset export and actual GLB measurements.
- `preview_volga.py` / `preview_volga.gd`: matched comparisons / Godot frames.

The user positively reviewed the curved upper-body direction before requesting
bonnet/boot rounding. The last checked deck revision exported 7,775 triangles,
three materials and four embedded 1024px maps, with successful Godot import and
visual inspection. The user also positively reviewed the rounded deck result
before asking to preserve this workflow. These are verified example results,
not promised costs or automatic settings for a UAZ.
