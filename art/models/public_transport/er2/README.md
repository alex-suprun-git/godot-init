# ER2 square-cab game model

Built 2026-11-01 on `codex/railway-features`. Original Blender geometry based on the project's generated `../references/er2-square-turnaround-v1.png`, not downloaded geometry. The user requested careful scale relative to the actual game Volga and subsequently chose the handbook's four-car formation, superseding the temporary two-car proposal.

## Current deliverables

- Editable source: `er2.blend`, scenes `ER2_Studio` (separate head/motor cars) and `ER2_Four_Car_Assembly` (linked instances, outward cabs).
- Game copies: `init/assets/models/vehicles/er2_head.glb` and `er2_motor.glb`.
- Interactive Godot review: `res://scenes/dev/er2_3d_demo.tscn`. Left-drag to orbit, wheel to zoom; buttons switch between head car and full four-car formation. The actual game Volga is included at the identical common map factor.
- The user positively reviewed the model and requested the whole train beside the northern village garden on the raised eastern railway. It now appears in normal gameplay on the outer track, x=420, centred at z=15, wheels at y=6.04. Layout placement is authored in `DistrictLayout.COMMUTER_TRAIN`; `er2_train.gd` assembles the four cars and `DistrictBuilder` places them on the embankment surface. The station tracks and port freight stock remain free/unchanged respectively.
- Context capture: `capture_map.gd` now records the actual integrated eastern-embankment placement; it no longer injects a second train. `--keep-open` leaves the live game focused on it after captures.
- Static map placement is implemented and visually checked. No train movement, schedules, passengers, door animation, wheel animation, collision or catenary were added. The head and motor assets are reusable for later railway features.

## Dimensions and scale

The reference image's grid is decorative and its views disagree. Its dark green/cream body, grey crowned roof, opaque blue-grey glass, side doors and square cab guide appearance. Dimensions are independent of those pixels.

Technical reference: P. V. Tsukalo and N. G. Eroshkin, *Electric Trains ER2 and ER2R*, 1986, technical table pp. 7–8, available as [book transcription/scan](https://djvu.online/file/qLbFtWlOJRrBx) and [table transcription](https://scbist.com/scb/uploaded/elektropoezda/er2r_2.html). Nominal construction anchors: 19.600 m car body, 3.522 m corrugated width, 4.253 m roof above rail, 13.300 m bogie-centre spacing; head-car bogie wheelbase 2.400 m and wheels 0.950 m, motor-car values 2.600 m / 1.050 m. The pantograph is represented in a low pose at 5.486 m above rail. These define a game interpretation, not a certified engineering reconstruction; exact cab fittings, roof wiring and glazing divisions are simplified from the generated sheet.

`measure_volga.py` imports the actual main-checkout GLB and measures transformed vertices. Results: `volga_measurements.json`. The historical task's nominal real GAZ-24 basis is 4.735 × 1.800 × 1.490 m; measured game source is 4.905458 × 2.046548 × 1.490000 m. Rather than match the train to the car's entire length, apply the same deliberate vehicle stylization factors independently:

| Axis | Volga-derived factor | ER2 body target |
| --- | --- | --- |
| Length | 4.905458 / 4.735 = 1.036000 | 19.600 × factor = 20.305593 m |
| Width | 2.046548 / 1.800 = 1.136971 | 3.522 × factor = 4.004413 m |
| Height | 1.490000 / 1.490 = 1.000000 | 4.253 m roof |

This intentionally inherits the broader stylized vehicles; it is not uniform real-world scaling. A body is 4.14 actual Volga lengths. The existing shared map factor **4.3 / 4.37 = 0.9839816934** is then applied uniformly to both complete models. Never fit the complete train into an old 60 m sprite footprint or independently stretch it to the platform.

## Export measurements

Measured by re-importing the binary GLBs, not just reporting build constants. See `export_report.json`. Units below are Blender source metres; wheels touch Z=0, forward is Blender -Y / Godot +Z.

| Game copy | Length including couplers | Max width including fittings | Max height | Triangles | Materials |
| --- | --- | --- | --- | --- | --- |
| Head | 20.906473 | 4.076042 | 4.310000 | 6,783 | 3 |
| Motor | 20.906473 | 4.076042 | 5.486000 with pantograph | 6,708 | 3 |

Body target and complete bounds differ because of couplers, window/door frames and roof fittings. Construction coupler pitch is a nominal 20.18 m before the Volga length factor. Four cars total **83.625893 source m / 82.286347 map m**, 26,982 triangles, two unique meshes reused twice each. The budget was approximately 8k triangles and three material surfaces per car for map-distance use, without an interior. Actual costs satisfy this budget. Each GLB has one mesh object, three primitives and no camera, light, floor or Volga.

Appearance uses three ordinary portable materials plus linear vertex colors (body/livery/roof, opaque glass, mechanical/trim); there are no generated raster textures or Blender-only procedural shaders to bake. Thus raster preparation and sprite-anchor measurement do not apply. Godot initially disabled vertex-color albedo on the body surface despite `COLOR_0` being present. The two `.glb.import` files now use `res://scripts/dev/er2_material_import.gd`, explicitly enabling the stored colors on each surface. Preserve this hook on re-import. It does not affect other assets.

## Stages and reproduction

Run from repository root. Each stage is synchronous and resumable; Blender MCP was disconnected during this task, so the installed Blender 5.2.3 CLI was used. Scripts create their own named asset scenes; the actual game export explicitly selects only one car and its active scene.

```sh
Blender --background --factory-startup --python art/models/public_transport/er2/measure_volga.py
Blender --background --factory-startup --python art/models/public_transport/er2/build_er2.py -- --blockout
Blender --background --factory-startup --python art/models/public_transport/er2/preview_er2.py -- --blockout
Blender --background --factory-startup --python art/models/public_transport/er2/build_er2.py
Blender --background --factory-startup --python art/models/public_transport/er2/export_er2.py
Blender --background --factory-startup --python art/models/public_transport/er2/preview_er2.py
Godot --headless --path init --import
Godot --path init res://scenes/dev/er2_3d_demo.tscn
Godot --path init --script "$PWD/art/models/public_transport/er2/capture_map.gd" -- --no-log
```

Installed binaries: `/Applications/Blender.app/Contents/MacOS/Blender` and `/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot`. Add a writable `--log-file` for CLI Godot runs when needed. Viewer supports `-- --consist` and `--capture=<absolute.png>`; capture closes the viewer after saving.

## Inspected evidence and limitations

- `previews/blockout-*`: side/front/rear/three-quarter silhouette before final fittings, beside unchanged Volga over a one-metre grid.
- `previews/side.png`, `front.png`, `rear.png`, `three-quarter.png`: finished Blender source views with the same calibration.
- `previews/godot-volga-comparison.png`: actual imported GLB beside actual game Volga, same map factor.
- `previews/godot-four-car-comparison.png`: full head–motor–motor–head formation with two outward cabs and two pantographs.
- `previews/godot-station*.png`: historical temporary station placement, inspected for scale, rail centering and wheel grounding at track surface Y=0.192; the train is not parked there in gameplay.
- `previews/godot-embankment*.png`: current actual gameplay placement beside the village on the raised outer track. Both full-consist and close views were inspected for wheel contact, track centring, orientation and clearance from the nearby overpass. Track surface Y=6.04; the 82.3 m consist stays on the level plateau, clear of ramps and tunnels. Godot capture exited 0 without script errors.

The current combined market/station painting contains people oversized relative to the shared 3D vehicle scale; they look larger than train details in the map captures. This existing painting mismatch was not compensated by enlarging the ER2. The nearby platform/fence is also a static painting, so these captures do not establish door alignment or boarding clearances. The texture-only tracks are flat and have no physical railheads. Roof details and front fittings are simplified, with no text/numbering; opaque glazing has no modeled interior.

Final Godot 4.7.1 import and both viewer modes completed with exit 0 and no remaining script/import errors after correcting a typed variable in the import hook. The earlier station capture printed the pre-existing four-ObjectDB/two-resource shutdown warnings. No automated tests or full-week autoplay were added/run. No commit or push was made for ER2 production/integration. Next: user review of the requested live map placement; train behavior remains a separate feature step.
