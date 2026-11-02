# Early GAZ-2705 panel van

Independent asset requested 2026-11-02. The user chose the all-metal cargo van, requested a 15% reduction followed by another 5% of that reduced size, then a 3% increase of all three variants, softer body forms matching four supplied photographs, and two colours besides white. The user approved the latest size/appearance and requested replacement of part of the moving ZIL fleet. All three colours are now integrated in road traffic.

`gazelle_2705.blend` contains the editable metre-scale source in scene `GAZ_2705`, Blender -Y forward. `build_gazelle.py` builds coordinated body sections, actual wheel apertures, rounded roof shoulders, the early rectangular-lamp front, cargo-door pressings and dual rear tires. It is run in an independent background Blender process, not the shared live MCP scene.

`export_gazelle.py` exports only the merged game copy, with a **0.85 × 0.95 × 1.03 = 0.831725 uniform presentation scale already applied**. Do not apply that reduction twice at integration. Each GLB has 13,300 triangles, one mesh, three surfaces and one embedded palette texture. The white export's fresh round-trip measurement is 4.614 m long, 2.067 m wide including mirrors, and 1.900 m high, grounded at zero. Source length is 5.548 m including the revised bumper, body width about 1.964 m and wheelbase 2.900 m. Full measured report: `glb_inspection.json`.

Reference revision: the longitudinal sections now form a convex bonnet and rounded front roof cap, with a stronger transverse roof crown. Windshield and rounded cab windows sample those same surfaces; side glazing is tessellated to avoid intersecting the shoulder. Three rounded shallow cargo pressings replace the two angular frames. The black bumper wraps around both front corners. Tires are 0.760 m in source diameter, with matching larger arch apertures. The geometry budget is now 14k to preserve these body/glass surfaces.

Exports share identical geometry: `gazelle_2705.glb` (white), `gazelle_2705_blue.glb` (muted blue, sRGB `617F98`) and `gazelle_2705_sand.glb` (sand beige, `B7A989`). Copies under `init/assets/models/vehicles/` are used by the game. Glass, lamps, steel and rubber retain the same palette. No generated raster artwork is used; the embedded 64px palette is a technical material lookup.

## Rebuild and inspect

From the repository root in PowerShell:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --python art/models/gazelle/build_gazelle.py
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --factory-startup --python art/models/gazelle/export_gazelle.py
uv run --no-project python art/models/gazelle/prepare_preview.py
& 'C:\Users\alexe\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path art/models/gazelle/preview_project --import
& 'C:\Users\alexe\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe' --path art/models/gazelle/preview_project
```

The isolated Godot review now shows all three paints under identical cameras and lighting, a benchmark lineup and default map pixel density. Volga uses its current 0.90 presentation factor and ZIL uses 0.80 × 1.05, both with their existing length conversion. Gazelle has its own dimensions and receives no Lada-derived scale. Ignored captures: `previews/shape.png` (initial size/harder corners), `previews/softened-85.png` (previous revision), `previews/colours-8075.png` (before latest enlargement), `previews/colours-831725.png` (current). Previous build script, blend and GLB are preserved in `previews/before-reference-revision/`. Godot import and graphical capture succeeded under installed Godot 4.7.2; sandbox restrictions produced editor-settings/cache/certificate warnings. No automated tests were added or run.

## Moving traffic integration

`init/scripts/map/traffic_vehicle_models.gd` selects moving visuals at initial spawn and gateway re-entry. It delegates existing models to `VehicleModels`, replacing each selected ZIL with a Gazelle at probability 0.5, with equal independent weights for white/blue/sand. KamAZ selection, all class/stream budgets, parked vehicles and coal-event trucks are unchanged. The approved scale is baked into the GLBs and not applied again. CityMap uses this module only for ambient road vehicles.

The existing `traffic_flows.gd` remains the source of truth for 66 slots: through 30 (truck/car/bus 60/35/5%), border 14 (80/20/0%), city 18 (0/80/20%), courtyard 4 (0/100/0%). These are weighted class choices, not exact quotas; the existing bus cap is five. Truck model weights before replacement are thirds; after replacement the expected truck mix is KamAZ 1/3, Gazelle 1/3, each ZIL 1/6. Gateway re-entry can change class/model, and some slots are outside the map or waiting to enter. District fleet profiles are not the active moving-traffic stream budgets.

Focused visual review: `Godot --path init -- --autoplay --only=gazelle --turbo --shots=<absolute output dir> --no-log`. It prints the actual initial class/model counts and captures naturally moving vans on both road axes without adding review-only vehicles. Verified captures: ignored `previews/gazelle_road_x.png` and `previews/gazelle_road_z.png`; wheels sit on asphalt at 0.14 m and the approved scale reads beside existing traffic. The inspected launch had 34 passenger cars, 27 trucks and five buses; the truck visuals were 11 Gazelles, 11 KamAZ and five ZIL. This is one deterministic launch's pool, not a guaranteed visible fleet. No automated tests were run. Sources and acquisition decision are in `SOURCING.md`.
