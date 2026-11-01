# Public transport models

## Current stage (2026-11-01)

Original LiAZ-5256 and PAZ-3205 built through Blender 5.2.3 LTS MCP, detailed,
exported and integrated into ambient traffic and the three ATP parked placements.
No third-party geometry or textures. The user approved the in-game result after
the uniform 20% size reduction and requested a PR on 2026-11-01.
ER2 already exists on main; its independent source of truth is `er2/README.md`.
Generated sheets in `references/` guide the intended bus appearance.

- Initial shape checkpoint: `shape_v1/buses.blend`, scene `PublicTransport_Shape`.
- Current source: `finish_v1/buses.blend`, scene `PublicTransport_Finish`.
- Current exports: `finish_v1/LiAZ_5256.glb`, `finish_v1/PAZ_3205.glb`.
- Game copies: `init/assets/models/vehicles/bus_liaz_5256.glb`, `bus_paz_3205.glb`.
- Comparison scene: `finish_v1/comparison.blend`.
- Measured exported bounds/counts: `finish_v1/glb_inspection.json`.
- Each export has one mesh, eight material surfaces, opaque glass, no interior.
- Metres; Blender -Y forward, Godot +Z forward; tires touch height zero.

## Dimensions and budgets

| Model | Nominal length / body width / roof height (m) | Wheelbase (m) | Exported triangles |
| --- | --- | --- | --- |
| LiAZ-5256 | 11.400 / 2.500 / 3.007 | 5.840 | 9,526 |
| PAZ-3205 | 6.925 / 2.500 / 2.960 | 3.600 | 6,522 |

Shape-stage working budgets: approximately 12k triangles for LiAZ, 8k for PAZ,
eight simple materials, no textures. Finishing should consolidate materials where
useful, guided by the current truck and Volga under the actual map camera.
These budgets are provisional, not measured runtime performance limits.

Actual GLB bounds include bumpers, mirrors and hatches: LiAZ 11.550 m long,
2.850 m across mirrors, 3.030 m high; PAZ 7.075 / 2.850 / 2.983 m.
Do not confuse nominal body dimensions with exported bounds when setting map scale.

Dimension research on 2026-11-01:

- LiAZ working targets: [Lipetsk vehicle record](https://transport.lipetsk.ru/bus/?act=cars&id=liaz5256).
- PAZ length and one passenger door: [Pskov operator record](https://www.pskovbus.ru/?id=3&pag=bus).
  That record lists 2.480 m width and 2.690 m height, differing from the
  2.500 / 2.960 m concept targets and other published records. Current PAZ
  width/height and 3.600 m wheelbase remain provisional pending reconciliation
  against the exact early-1990s variant before final export.

## Rebuild and inspect

Run from the repository root:

```sh
uv run --script tools/blender_mcp.py --user-prompt 'продолжай моделлирование' run art/models/public_transport/build_buses.py
uv run --script tools/blender_mcp.py --user-prompt 'ладно продолжай' run art/models/public_transport/finish_buses.py
uv run --script tools/blender_mcp.py --user-prompt 'продолжай моделлирование' start art/models/public_transport/preview_buses.py
```

On this Windows machine, use `C:/Users/alexe/.local/bin/uv.exe` if uv is absent
from PATH. Check `preview_buses.job.json` before retrying a preview job.
The scripts recreate only their named scenes and preserve unrelated scenes.
The shape source retains separate parts; the finish stage works on a separate
copy and joins its game meshes. Rerun finish from the shape scene, then preview.
Copy the inspected finish GLBs to the game paths above and run Godot --import.

The preview script reimports actual GLBs, measures transformed bounds/counts and
renders front three-quarter, right sides, rear three-quarter and fleet comparison
PNGs under `finish_v1/` when that stage exists, otherwise `shape_v1/`.
The original Blender comparison used the old KamAZ and current Volga exports
at source scale 1:1, identical lighting and a one-metre ground grid.

Front/rear three-quarter, both right-side and fleet renders were visually inspected after corrections.
Earlier side views exposed a door/wheel-arch overlap on PAZ and an incorrect lower
paint assignment; both were corrected and exports regenerated. Rounded window
outlines replaced beveled boxes, reducing geometry. Finish adds wipers, rain
gutters, protection strips, driver-door seams/handle, vents and PAZ emergency-exit
seams. Glass remains opaque; no expensive bake or new raster assets were needed.

## Godot verification and integration

Godot 4.7.2 stable was found and run at:
`C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`.
Both GLBs imported successfully. The manual `preview_buses.gd` script builds the
real district and temporarily places a comparison fleet on a review pad in the
reserve, using the map's lighting and isometric camera angle. It also captures
actual integrated ATP placements and ambient bus instances after hiding the pad.
It makes no saved layout changes and quits after screenshots:

```powershell
& 'C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path init --resolution 1600x1000 --log-file '<absolute output>/godot_review.log' --script '<absolute project>/art/models/public_transport/preview_buses.gd' -- --no-log --hour=12
```

Inspected screenshots under `finish_v1/`: `godot_fleet_z.png`, `godot_fleet_x.png`,
`godot_map_context.png`, `godot_depot.png`, `godot_traffic_bus_liaz.png`,
`godot_traffic_bus_paz.png`. Both orientations, shared scale and grounding were
visually checked. Godot D3D12/Forward+ completed with no script/runtime errors.
The original deterministic scene contained 11 LiAZ and 9 PAZ ambient instances;
the later five-bus cap produces 3 LiAZ and 2 PAZ. ATP has two PAZ and one LiAZ.
See `bus_limit_review.log`. The manual harness freezes the map
for inspection; no full-week autoplay or performance benchmark was run.

`VehicleModels` selects the two bus models deterministically for the existing
`bus` class, preserves their two-tone paint and uses measured export lengths for
an additional uniform `BUS_VISUAL_SCALE = 0.80`, following the user's request to
reduce both buses by 15–20%. It is applied once in `VehicleModels.create()` to
traffic and parked instances; source GLBs remain unchanged. Displayed full lengths
are 9.240 m for LiAZ and 5.660 m for PAZ. The Lada factor is not inherited.
`building_catalog.gd` replaces
the three ATP sprites with 3D buses and correctly oriented footprints. The painted
station/market hub is unchanged. After refreshing from main `f620893`, the new
three truck variants and their approved 0.80 presentation factor are preserved.
The updated Godot comparison uses `VehicleModels.create()` for all six vehicles,
including the actual imported truck materials and map scales. The old comparisons
predate this refresh and are not evidence about the upgraded trucks.

The work was migrated from the outdated `04525bc` checkout to `art/bus-models`
based on `f620893`, preserving the upstream ER2, terrain and truck changes.
Conflicts in vehicle registration and transport notes were resolved; Godot import
and refreshed fleet/depot captures completed without runtime errors. Review frames
and logs are ignored local artifacts. Pre-migration work remains backed up in the
stash named `bus-models-before-main-refresh-2026-11-01`.

Known existing traffic limitation: ambient agents have no collisions/following
distance, so cars can overlap buses. This update does not implement traffic rules,
bus routes, stops, passenger boarding or independently animated wheels/doors.

## Remaining work / next action

1. Reconcile the exact PAZ variant dimensions if stricter historical fidelity is
   needed; current shape dimensions remain documented above. More wear/material
   work is optional after user feedback, not a completed texture bake.
2. ER2 already exists independently; do not rebuild or overwrite it. No external
   truck acquisition is planned: the internet search was a misunderstanding.

The requested five-bus traffic cap is a separate commit `469e5fc`, touching only
`ambient_life.gd` and the project README. Model sources, integration and the
approved 20% presentation reduction are saved separately from that traffic commit.
