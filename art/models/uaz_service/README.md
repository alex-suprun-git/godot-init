# UAZ service vehicles

## Current checkpoint — 2026-11-02

Police UAZ and RAF ambulance models are built and exported; both were inspected in the isolated Godot comparison. The user positively reviewed the models and requested the recorded size adjustments. Civic map placement/catalog integration remains separate.

- Source: `uaz_police.blend`, scene `UAZ_Police`; build: `vehicle_build.py`; separate export stage: `export_vehicle.py`.
- Export: `init/assets/models/vehicles/uaz_police.glb`; actual GLB inspection: `glb_inspection.json`.
- Real-scale Blender source length/body width/roof height: **4.440 / 1.940 / 2.101 m**; wheelbase **2.300 m**. On 2026-11-02 the user requested both vans 15% smaller. The GLB now embeds uniform **0.85** scale: exported length **3.774 m**, body width **1.649 m**, overall mirror width **1.938 m**, beacon height **1.9397 m**. Ground-centred origin; +Z forward in Godot. Do not apply another 0.85 factor at integration.
- **10,688 triangles**, five meshes (body plus four wheels), seven primitives, three materials, one embedded **64 × 64** palette atlas; no animation, camera, light or collision. This exceeds the initial approximate 8k target but remains below the Lada's 21,261 triangles and texture budget.
- Godot 4.7.2 / Compatibility screenshot: `previews/service-comparison-v6.png` (ignored). Shows the reduced exports beside current Volga, PAZ and ZIL with game scales, including the subsequently requested 10% Volga reduction and 5% ZIL increase, front/rear views and a default-map-zoom readability strip. Volga's preview copy matches the game GLB by SHA-256 (7,775 triangles, three materials); v6 removes an unintended additional black paint multiplier to use its original administration-car material. The first export exposed disabled vertex-albedo use on the shared fittings in Godot; the portable atlas fixes this without runtime overrides.

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

## Rebuild and review

Run `vehicle_build.py` in Blender with its real `__file__`, then run `export_vehicle.py` separately. The helpers follow the Lada precedent for scene isolation, wheels and scoped export; both vans have independent measured shell sections. No expensive paint bake is needed. Sources retain editable vertex colours; export maps them to a portable palette atlas. The UAZ uses a classic horizontal grille, a divided windshield and one right-side forward compartment access door, resolving the generated sheet's contradictory marks. It is a family-level 1997 interpretation rather than an exact documented police conversion.

Run `prepare_preview.py` with Python (or through Blender) to copy both exports and current benchmarks into `preview_project/models/`. Run Godot with `--headless --path art/models/uaz_service/preview_project --import`, then launch the same project normally; `-- --capture=<absolute PNG path>` saves the comparison and exits. `inspect_import.gd` prints actual imported mesh/material/atlas data. Review captures and copied benchmark models are ignored. Actual service-van civic-building placement has not been inspected. Next action: catalog/placement integration in a separate update.

Branch verification: the comparison demo and `--autoplay --only=vehicles --turbo --no-log` were run from the separate `art/civic-service-vehicles` worktree based on refreshed `origin/main`. The game reported 118 vehicle instances, including four Volgas; the captured Volga street frame was inspected. New service vans remain demo-only. No automated tests were added or run. Logs/captures stay in ignored `.local/verification/`; the engine reported a local Windows certificate-store warning without preventing import or capture.

## User review — 2026-11-01

The user approved both the police UAZ and RAF ambulance reference appearances ("both are excellent"). This approves the visual direction of v1, not generated projection accuracy. Resolve the inspection inconsistencies technically before modeling; do not request the same visual-direction approval again. No models exist yet.

## Scale comparison — 2026-11-02

User direction: establish real vehicle sizes, then judge proportions visually beside the current Volga and PAZ in Godot. The [UAZ factory 2002 catalogue](https://xr793.com/wp-content/uploads/2024/01/2002-UAZ-7th-International-Show-MIMS-2002-Moscow-RU.pdf) lists the UAZ-2206 family at 4.440 × 1.940 × 2.101 m; this is a family baseline, not proof of an exact 1997 police conversion. Measure the beacon separately. The [GAZ-24 technical manual](https://long-vehicle.narod.ru/gaz24/book24/24_tech.htm) lists 4.735 × 1.800 × 1.490 m: the UAZ should read shorter, slightly wider and substantially taller than the real Volga. RAF is longer than both; PAZ is the largest.

The engine comparison uses identical camera/lighting: current Volga source length is 4.905458 m with the existing 4.3/4.37 map conversion and a subsequently user-requested 0.90 presentation factor (about 4.344 m displayed); PAZ source length is 7.075 m with its approved 0.80 presentation factor (5.660 m displayed). The user requested uniform 15% reduction for both vans; v6 shows that reduction embedded in the exports, with no extra van preview scaling. Both read shorter than the game Volga; RAF remains longer than UAZ.
