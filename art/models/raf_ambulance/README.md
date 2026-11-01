# RAF-22031 ambulance

## Current checkpoint — 2026-11-01

The user selected a RAF ambulance instead of the previously planned UAZ ambulance and requested the same reference-first process as the police UAZ. RAF-22031 turnaround v1 was generated with built-in ImageGen, visually inspected and presented for user review. No Blender model, GLB, bake or Godot integration exists.

- Untouched original: `references/raf-22031-turnaround-v1.png`.
- Exact prompt: `references/raf-22031-turnaround-v1.prompt.md`.
- Views: orthographic left, right, front, rear and top, plus front three-quarter.
- Modeling-only reference outside `init/`; no raster optimization/import was performed or needed.
- Vehicle choice: RAF-22031 medical variant of RAF-2203; standard-roof appearance is the current generated proposal, not a separately approved detailed specification.
- Historical identification source consulted during selection: https://t.mos.ru/mostrans/all_news/124000 (transport museum account of a RAF-22031-01 ambulance).

## Visual inspection

All six complete views are present. The sloping cab, rectangular headlights, long low van body, off-white/red medical livery and blue beacon are readable. Vehicle surfaces contain no lettering or readable plates; panel labels stay outside the vehicle. Appearance remains for user review.

Resolve before modeling:

- Right-side medical access appears as a broad door area with multiple handles/seams; the exact door mechanism/layout must be resolved against actual RAF references, not inferred from generated marks.
- Side window divisions, frost boundaries and apparent spacing vary slightly in the three-quarter view. Choose one shared landmark layout.
- Roof vent shape/detail differs between side and top panels; rear view does not clearly show the beacon. Resolve consistent fittings and placement.
- Grid spacing, apparent dimensions and projections are uncalibrated. Establish real body bounds, wheelbase and variant details independently before tracing geometry.
- Rendering is more detailed than the intended game mesh. Retain silhouette; simplify seams/fittings and use established opaque cab glazing without a detailed interior.

## Next action and modeling plan

Collect visual feedback, resolve period references and dimensions, then build a cheap multi-angle body preview before detailing or baking. Reuse suitable Lada/Volga wheel, material and export helpers, while building the RAF-specific shell and cab. Police UAZ remains a separate asset under `art/models/uaz_service/`; RAF is not a UAZ recolour or shared-body derivative.

Proposed technical target: approximately 8k triangles, three materials, atlases no larger than 1024px; measure actual exported GLB. Metres, ground-centred origin, Blender -Y / Godot +Z forward. Keep build, finish/bake, export and preview resumable. Intended export: `init/assets/models/vehicles/raf_ambulance.glb`. No export exists yet. Actual Godot map-distance inspection is required after model production.

## User review — 2026-11-01

The user approved both the police UAZ and RAF ambulance reference appearances ("both are excellent"). This approves the visual direction of v1, not generated projection accuracy. Resolve the inspection inconsistencies technically before modeling; do not request the same visual-direction approval again. No models exist yet.
