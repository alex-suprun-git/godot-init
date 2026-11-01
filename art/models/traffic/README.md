# Freight truck models

The 2026-11-01 upgrade lives in `upgrade/trucks.blend` (`Freight_Studio`), with one editable mesh per variant. The user positively reviewed the shown visual direction in chat. It replaces the rough 2026-10-31 ZIL/KamAZ geometry; the obsolete source, generator and report have been deleted. Git retains their history. The independent 20 ft port container GLB is unchanged; its source/generator are now `container.blend` / `build_container.py` (source-only by default, `-- --export` opts into export).

## Construction and scale

The generated sheets in `references/` guide the rounded ZIL-130 cab, blue insulated food box, green wooden coal bed/partly withdrawn olive tarp, and beige KamAZ-5410 with a separate blue 40 ft container. These are conceptual turnarounds with inconsistent views, not calibrated engineering drawings. Both ZILs share the same cab construction. No downloaded geometry, generated raster textures, interiors, cargo/door animation or articulated trailer steering were added.

The [ZIL chassis handbook (Kriger, 1973), technical table pp. 4–5](https://ru.djvu.online/file/UAkFMRamG7UvG) supplies the 3.800 m wheelbase and 1.800 m front track. The [KamAZ factory operating manual (1986)](https://djvu.online/file/YLvdcQgyvPxAZ) is the period construction reference; the authored tractor uses 2.840 + 1.320 m axle spacing and a 1.275 m front overhang. These are construction anchors, not a claim of an exact subtype reconstruction. The skeletal trailer, food-box dimensions and tarp/coal construction are game interpretations of the sheets. Standard-height container construction is 12.192 × 2.438 × 2.591 m before stylization.

Like ER2, geometry receives the independently measured actual Volga L/W/H factors (1.036000 / 1.136971 / 1.000000) stored in `../public_transport/er2/volga_measurements.json`; the entire vehicle then receives the common 4.3 / 4.37 map factor. Forward is Blender -Y / Godot +Z, tire bottoms Z=0. Street/lot surface offsets remain the existing map author's offsets. Actual GLB bounds include mirrors and fittings; `upgrade/export_report.json` measures reimported binaries.

| Export | Source length | Map length | Triangles | Surfaces |
| --- | --- | --- | --- | --- |
| `truck_zil_food.glb` | 7.158757 m | 7.044086 m | 5,172 | 4 |
| `truck_zil_flatbed.glb` (coal, compatible ID) | 7.060337 m | 6.947243 m | 6,693 | 4 |
| `truck_kamaz_semi.glb` | 16.985214 m | 16.713140 m | 12,796 | 4 |

Map-use budgets are 8k triangles per ZIL and 14k for the five-axle KamAZ combination. Each export has one mesh and four portable material surfaces (tintable cab, opaque glass, mechanical/trim, cargo). Linear vertex colors carry cargo and fitting colors; `res://scripts/dev/truck_material_import.gd` preserves them on import while leaving cab paint reusable by the existing palette. Glass sits outside its seal to avoid coplanar flicker. Broad cab/bonnet/roof/fender shape has actual section geometry. Wheel tread and wear are simplified for map distance.

`vehicle_models.gd` registers all three variants in traffic and fixes the former passenger-car length applied to trucks. Static parking uses the same map scale; one ZIL parking spot now shows the food box. Existing freight frequency and total vehicle counts are retained. Traffic remains the existing visual simulation; no new collision, trailer articulation or length-aware traffic-spacing system is implemented or verified by this asset change.

## Rebuild and review

Run each stage from the repository root with `/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python <script>`:

1. `upgrade/build_trucks.py -- --blockout` saves the cheap shape checkpoint; `upgrade/preview_trucks.py -- --blockout` renders the four review angles.
2. `upgrade/build_trucks.py` saves the finished source; `upgrade/export_trucks.py` exports only the selected truck from its active scene and reimports each GLB to measure it.
3. `Godot --headless --path init --import`; preserve the three truck `.glb.import` material hooks.
4. `Godot --path init res://scenes/dev/truck_3d_demo.tscn` opens the orbit/zoom viewer with all three variant buttons and the actual Volga at the same scale. Optional `-- --variant=0|1|2 --capture=/absolute/frame.png` saves a frame and closes.
5. `Godot --path init --script "$PWD/art/models/traffic/upgrade/capture_map.gd" -- --no-log` captures the real truck stop at overview and close range. Review captures/logs stay in `/tmp/truck-upgrade/` and are not repository content.

For matched old/new views, archive `truck_zil_flatbed.glb` as `old-zil.glb` and `truck_kamaz_semi.glb` as `old-kamaz.glb` from pre-upgrade revision `450cdcd`, then run `upgrade/compare_trucks.py -- --before-dir=/absolute/archive`. Same side/front/rear/three-quarter camera and one-metre grid, unchanged source scale. Source counts are not substituted for actual export measurements.

Inspected: Blender family blockout, imported KamAZ/Volga comparison, corrected ZIL window layers, and actual game truck-stop placement. Godot imports and viewer/map captures completed without script/import errors. The map capture still prints the previously recorded four-ObjectDB/two-resource shutdown warnings. No automated tests or full-week playthrough were run. Final visual direction was positively reviewed by the user; this does not establish collision, clearance through every junction, or animation behavior. The old 2D KamAZ game sprite is removed, and the coal-event overlay now instantiates the same new 3D ZIL. Its former sprite is preserved only as a reference in `references/zil-coal-original-sprite.png`. Next: use the live variant viewer for any requested shape refinements.

Live city-traffic review (2026-11-01): the actual ambient pool contained 14 new KamAZ, seven coal ZIL and eight food ZIL instances. A visible instance of each moved 52.1 / 53.6 / 28.3 m during the graphical capture, all with common scale 0.983982. The food ZIL road frame was visually inspected. The coal-event overlay resolves to the new coal GLB at the same scale. Captures and telemetry are in `/tmp/truck-upgrade/live-*.png` and `traffic-console.log`; these are local review evidence, not persistent repository assets.
