# Civic centre: administration, square and vegetation

## Current implementation

Normal F5 builds the civic lot from separate GLBs via `building_catalog.gd`, `district_builder.gd` and `civic_center.gd`. It replaces the old administration and flat monument. The office bar is 28 x 14 m with four 3.5 m storeys, beside an 8 x 14 m hall at 18 m. Physical window bays, a square-facing lobby/canopy/stairs, side ramp, clerestory and abstract rail-wheel relief establish the late-Soviet landmark. The public entrance faces west toward the avenue; generated references sometimes reversed it and are not measured plans.

The 32 x 24 m forecourt meets the avenue sidewalk at x=9.5. Two planters and edge seating frame the open approach. A separate 18 x 16 m memorial court contains the worker-founder at `(29,98)`; its eastern path avoids the plinth. The 27 x 22 m service court contains four marked parking spaces, the real shared Volga/Lada and a three-bay garage at `(82,57)`, with one driveway from the village street and shrub screens. The rear garden has a path loop, cross path and connected seating pads. The northern path runs through from the avenue to the village street at z=43. Building and pedestrian arrivals remain `(40.5,72)`, via lot entrance `(25,72)`. Paths are shared data in `DistrictLayout.ROADS` for actors and ambient pedestrians.

The user requested planting the remaining rear ground as an interim reserve, deferring its eventual use. A stable local generator adds 41 trees around buildings, service surfaces, paths, seating and existing trunks. Together with composed planting there are 58 trees and 42 shrubs. The rest of the city retains its sprites; the separate painted `city_park` remains. Inside `PLANTING_RECT`, automatic roadside sprites are suppressed without changing later random draws.

## Sources and rebuilding

- `build_administration.py` / `administration_review.blend`: administration, garage and unused blank flag study. Building budget is approximately 68k triangles and 11 material surfaces; front is Blender -Y, exported as Godot +Z and rotated -90 degrees on the map.
- `build_review.py` / `civic_assets_review.blend`: original furniture, founder sculpture and three original vegetation studies. The founder is a capped worker with rolled plan and track hammer, about 5.1 m overall on a granite base. Original review GLBs remain under `review_exports/`; vegetation rebuilding uses them as input.
- `build_vegetation.py` / `civic_vegetation.blend`: refined deciduous, conifer, shrub and columnar poplar; exports under `vegetation_exports/`, dimensions in `vegetation_report.json`. Each has separate wood, canopy core and leaf-spray meshes. Approximate heights/budgets: deciduous 11.2 m/16.2k triangles, conifer 10.1 m/13.4k, shrub 1.2 m/5.9k, poplar 15.6 m/15.5k. Per-instance scale/yaw variation is deterministic. Four poplars form the avenue row with a gap at the public approach.
- Game copies are twelve GLBs under `init/assets/models/civic_center/`; Godot-extracted texture PNGs/import settings accompany them. Legacy `review`/`study` filenames remain. Rebuild scripts do not automatically replace game exports.
- Generated architecture studies and prompts are preserved under `art/source_images/ispolkom/`; their facade image is not used by the final model. Stone/roof and furniture images are original procedural Blender sources embedded in GLBs. No new generated raster art was integrated. The image optimizer does not apply to GLB exports (`art/ASSET_PIPELINE.md`).

Run each builder with an installed Blender CLI from the repository root, then copy the selected exports and import:

```powershell
& $Blender --background --factory-startup --python art/models/civic_center/build_administration.py
& $Blender --background --factory-startup --python art/models/civic_center/build_review.py
& $Blender --background --factory-startup --python art/models/civic_center/build_vegetation.py
& $Godot --headless --path init --import
& $Godot --path init --script "$PWD/art/models/civic_center/capture_integrated.gd" -- --season=summer --capture-prefix=rear-grove --no-log
```

`capture_integrated.gd` captures the ordinary map without replacing lot visuals. The older `review_in_game.gd` is the historical transient prototype, not the playable integration. On the authoring machine Blender is `C:/Program Files/Blender Foundation/Blender 5.2/blender.exe` and Godot is `C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`.

## Materials, review and limits

`civic_foliage.gdshader` uses vertex colours, broad mottling, fine procedural grain and subdued specular response. These are not authored leaf/bark raster maps. After the initial airy/pale version, denser irregular canopy cores and leaf sprays were positively reviewed by the user. Autumn deciduous foliage is ochre, autumn needles are muted grey-olive, winter deciduous/shrub foliage hides and conifers retain needles. Separate materials are shared per vegetation kind. Stone joints, roof seams and physical facade frames supply building detail.

Godot 4.7.2 import, default-camera and entrance-side captures were inspected, including summer/autumn vegetation and winter branch/needle behaviour. First-week turbo autoplay after the layout/routing update completed through summary and week two. The final through-path/rear-grove capture reports 41 added trees and correct player/doorstep positions with no script/routing errors. Captures/logs stay ignored under `.local/civic-center-review/`; selected PR images are `rear-grove-overview.png` and `rear-grove-entrance.png`. No automated tests were added or run. Blender MCP was unavailable; isolated Blender 5.2.3 CLI completed exports. Local certificate-store and thumbnail-write warnings did not prevent capture/export.

Night presentation, close-up sculpture/bark, wind, LODs and a whole-map performance profile remain unverified or unimplemented. The rear reserve's final use, whole-map vegetation migration, House of Culture, restaurant-casino and village land enclosure are separate follow-ups. Facade floor-pitch correction is described in `art/models/elite_towers/references/README.md`.
