# UAZ service vehicles

## Current checkpoint — 2026-11-01

The user requested this sequence: generated multi-view references first, then a UAZ police model reusing existing vehicle modeling components, then the ambulance. The police reference sheet v1 is generated and visually inspected; it is presented for creative review. No Blender model, GLB, bake or Godot integration exists yet. The user subsequently chose RAF-22031 instead of a UAZ ambulance and requested its reference now; see `../raf_ambulance/README.md`. Neither model exists yet.

- Reference: `references/uaz-police-turnaround-v1.png` (untouched built-in ImageGen output).
- Exact prompt: `references/uaz-police-turnaround-v1.prompt.md`.
- Six views: left, right, front, rear, top, front three-quarter.
- These are conceptual views, not measured blueprints. The background grid is not calibrated. No raster optimization/import is needed for this modeling-only reference outside `init/`.

## Inspection

The rounded cab-over silhouette, cream-and-blue scheme, small single blue beacon, divided windshield and rear double doors are readable. Left/right door asymmetry is shown. All requested views are complete, with no lettering on the vehicle.

Resolve these generated inconsistencies before modeling:

- The side passenger door is shown at the middle compartment window, whereas the prompt requested the first compartment position. Establish one consistent actual door/window layout rather than blindly tracing the sheet.
- The front grille is a rounded trapezoid, despite the prompt requesting a small horizontal grille. Confirm the intended classic front treatment against period references before building the face.
- Side and three-quarter views differ slightly in apparent window widths and nose curvature. Use one shared set of landmarks for every surface.
- The image shows seat silhouettes through the glass and finer surface detail than needed. Follow the existing game models' opaque blue-gray glazing and budget; no interior is required.
- Sheet dimensions and projections are uncalibrated; establish body dimensions and wheelbase independently before using it as a tracing guide.

## Next stages

1. User visual feedback on the police reference; record any requested changes here.
2. Resolve period-specific form and dimensions, then build a cheap multi-angle police silhouette in Blender. Reuse Lada/Volga wheel, material and export helpers, not sedan body proportions. Main-checkout Lada sources are under `art/models/lada/`; latest Volga source stages remain in `../godot-worktrees/volga-gaz24-model/art/models/volga/`.
3. Inspect the silhouette before detailing/baking. Working target: approximately 8k triangles, three materials and at most 1024px atlases, to be measured on actual GLB; metres, Blender -Y / Godot +Z, origin at ground centre. These are proposed technical budgets, not measured outputs.
4. Finish/export police model and inspect it at actual map viewing distance in Godot.
5. After the police model, build the separately selected RAF-22031 ambulance from its own reference and proportions; see `../raf_ambulance/README.md`. The RAF reference sheet already exists. The earlier common-UAZ-body ambulance plan is superseded.

Use the resumable build/finish/export/preview stages from the project Blender skill. Preserve unrelated Blender scenes. No commits or pushes are authorized.

## User review — 2026-11-01

The user approved both the police UAZ and RAF ambulance reference appearances ("both are excellent"). This approves the visual direction of v1, not generated projection accuracy. Resolve the inspection inconsistencies technically before modeling; do not request the same visual-direction approval again. No models exist yet.
