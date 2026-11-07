# Industrial sites — first integrated 3D pass

The user authorized translating all seven existing industrial/service concepts into 3D. Appearance references are the selected sheets in [the district pack](../../source_images/district_visual_pack/README.md), including customs v2 and its circulation SVG. Generated projections are reconciled against the existing map. The compact ATP's actual-game composition was approved on 2026-11-06; the other six sites remain first-pass assemblies awaiting separate refinement/review.

The user reviewed the initial assembly as an acceptable schematic basis, but found materials and internal site detail insufficient. Refinement proceeds one location at a time. The approved ATP below is the first complete worked example; the initial sparse industrial plots are not a finished art target.

## Approved compact ATP compound

The user approved the `compact-v1` actual-game view on 2026-11-06 and requested preserving its decisions in the project skill. The parcel is now 120 x 82 m instead of 140 x 120 m, about 41% less land. The unchanged-size hall moves 39 m toward the highway, with a small eastward adjustment. Released rear paving becomes grass with an irregular tree/shrub belt. `init/scripts/data/district_layout.gd` holds the parcel and matching district subzone; `init/scripts/map/atp_site.gd` is the current placement source.

The ensemble combines the 64 x 24 m hall and attached 12 x 12 m dispatcher with a 14 x 8 m parts store, 10 x 8 m tire workshop and 5 x 4 m gatehouse. The opaque concrete perimeter has an east vehicle entrance, west exit and separate pedestrian wicket. Both vehicle openings connect to the existing highway edge. A U-shaped route links the east collector, rear aisle and west collector, with a front transverse connection to the repair apron. Stored buses occupy marked rear bays; one PAZ stands at the open repair bay. Staff cars align beside the office walk, the delivery truck stands beside the parts store and a car receives tire service. Tire racks, compressor, pallets, drains, lamps and interior planting reinforce those uses. Asphalt circulation, concrete working/pedestrian areas and planted beds have separate surfaces, at approximately the highway's 0.14 m level.

Support assets are built by `atp/build_yard.py`, saved in `atp/yard.blend`, and inspected in `atp/yard_build_report.json` / `atp/yard_export_report.json`. They reuse the prepared ATP materials. The default exporter includes both refined body and yard sources; a focused yard export uses `--source art/models/industrial_sites/atp/yard.blend`. Repeated opaque wall panels and small details are batched. Future site work is guided by `.agents/skills/blender-godot-assets/references/site-composition.md`.

Gate correction: the west opening now uses two 4 m steel leaves swung 80 degrees inward, with visible hinges, reusing `atp_solid_gate.glb`. Driveway ground is registered as occupied beyond the parcel boundary so the highway's automatic lamp no longer appears in this opening. Focused graphical capture: `--gate-review --capture-prefix=gate-fix` with the ATP capture script. The actual-game close-up was inspected: the opening is clear of the street lamp and both leaves are visible; the run exited 0 without script/shader errors.

Scheduled access prototype (2026-11-07): `location_schedules.gd` defines ATP's 06:00 opening and 20:00 closure, while `location_state.gd` holds the current/scheduled/override state. `access_gate.gd` animates individual hinged/sliding leaves, the wicket and both boom arms; static fences remain batched. A fresh scene snaps to the correct initial pose, subsequent changes take two real seconds and reversals continue from the current pose. `CityMap.visual_clock_hour()` supplies the same normal/night-preview/debug clock used by lighting. Future events can call `set_location_state_override("atp", &"closed")` and `clear_location_state_override("atp")`; existing simulation lot-state signals are forwarded to registered controllers. No new fields were added to the parcel dictionary. The corrected `--gate-cycle` graphical scenario advances actual simulation time through 19:59, 20:00 and next-day 06:00, exercises the override hook and captures the west opening; all states were observed without script/shader errors. It suppresses the full-screen day card and restores the camera after normal office-focus events. `--gate-demo` instead loops preview clock values with the gate camera held, without progressing authored requests; closing its window ends the demo. Media stays under ignored `.local/atp-review/gate-cycle-v3*`. Navigation collision, physical access restrictions and autonomous depot visits are outside this prototype.

Approval evidence: `.local/atp-review/compact-v1-context.png` and `compact-v1-near.png`, captured from the actual main scene at standard/permitted-near zoom. The run exited 0 without script/shader errors. These layout-approval frames precede the scheduled-access prototype above. The visible route has 8 m aisles and 9 m centreline turns; swept envelopes remain unvalidated and stored vehicles are stationary scenery. Full night/seasonal appearance was not reviewed. No automated tests were added or run. Continue from this approved composition when refinements are requested; discuss the next industrial location separately.

## ATP materials and architecture revision

The user first authorized developing the ATP body and reviewing it in the actual map. The selected concept and previous frame were inspected together (`.local/atp-review/reference-and-before.jpg`). The hall retains its 64 x 24 m dimensions; a lower 12 x 12 m, two-storey dispatcher attaches to its east end. The approved compact-compound section above supersedes this pass's world placement and yard layout. No other site's geometry or materials were refined in the ATP work.

Built-in ImageGen produced a four-surface atlas: red-brown brick, pale concrete, oxide-painted roof steel and grey-blue door paint. Original atlas, exact prompt and extracted source tiles: `art/source_images/atp/`. The separate preparation step ran `tools/optimize_asset.py` through `uv run` with `--profile surface --approved`, using the existing cached Pillow environment; four prepared copies are under `atp/textures/`, with provenance reports under ignored `art/optimization_reports/`. The flag records the user-authorized material batch; these materials are now part of the approved compact ATP view. Tile alpha is fully opaque and preparation preserved dimensions. Blender authors restrained roughness and normal response and packs the portable maps into the export; these are not scanned PBR measurements. Brick UVs repeat over 2 x 2 m, corresponding to approximately 0.25 m brick lengths and 0.083 m courses.

`atp/build_atp.py` builds the refined source independently. The facade has actual door openings/reveals, eight framed clerestory bays, pane variation, steel door leaves with panels/hinges/handles/observation glazing, numbered plates, wall lights and conduits. One bay is partially open with a shallow unlit service recess. Physical roof ribs, sheet overlaps, ridge/gable flashing, eaves channels and downpipes replace the pale schematic roof. The dispatcher has its own flat roof, windows, entrance canopy, steps and sign. The replacement mesh is about 17k triangles, 14 materials and 16 packed images, with explicit one-scene/one-mesh GLB inspection.

Focused rebuild/export/capture:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/industrial_sites/atp/build_atp.py
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/industrial_sites/export_assets.py -- --source art/models/industrial_sites/atp/atp.blend --asset atp_hall
# Import with the Godot command below, then:
& 'C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path init --script (Join-Path (Get-Location) 'art/models/industrial_sites/atp/capture_atp.gd') -- --no-log --hour=12
```

The body-only graphical run exited 0 without script/shader errors. Matched before/after frames at standard 350 m and permitted-near 280 m zoom were inspected together with surrounding roads and existing buses. These older captures/comparison remain under ignored `.local/atp-review/`; `compact-v1` is the subsequently approved site version.

## Models and integration

`industrial_sites.blend` contains 23 isolated, metre-sized base asset collections. `build_assets.py` builds the first-pass geometry and portable packed surface maps; `export_assets.py` exports and inspects one collection per GLB into `init/assets/models/industrial_sites/`. The default exporter uses `atp/atp.blend` for the refined hall and includes seven support assets from `atp/yard.blend`, for 30 current models. Coordinates are Godot east/up/south, converted to Blender east/north/up. Ground is local height zero, and building fronts face Godot +Z. Authoring budgets prioritize the standard isometric camera, with simple hidden closures. Existing transport and seasonal vegetation are reused at their current presentation scales. The base models use deterministic material bakes; the ATP revision uses separately prepared ImageGen surfaces.

`init/scripts/map/industrial_sites.gd` replaces the catalog's previous rendering for these lot IDs. ATP's parcel was reduced as described above; catalog entries and existing simulation IDs remain intact:

| Lot | Implemented ensemble |
| --- | --- |
| `atp` | Approved 120 x 82 m compound: hall/dispatcher, parts store, tire workshop, gatehouse, opaque perimeter, separate entry/exit, purposeful parking and planted buffers. |
| `truck_stop` | 32 x12m cafe with glazing, canopy, service fittings and benches; separate truck/car bays, two open entrances and perimeter. |
| `checkpoint` | 30 x18m administration, two direction-specific 40 x24m inspection halls, four control canopies, median booths, raised barriers, waiting pockets and segregated pedestrian pavilion/walks. |
| `port` | Both warehouses (65 x22m and40 x12m), portal crane, low river barge, quay rails/bollards, container and pallet groups, service entrance. |
| `fuel_depot` | 28 x12m warehouse, three storage tanks inside a35 x24m bund, collection manifold/loading stand and water tower. |
| `boiler` | 28 x20m boiler house,34m chimney, coal bay, existing paired heat main and3D repair-state scaffolding/service crane. Existing smoke and state triggers are retained. |
| `garages` | Thirty six-bay21 x6m modules in three rows (180 bays),16m drive aisles, west/east collectors, two south gates and varied doors. |

Repeated fences, garage rows, pallets, lamps and primitive site details use MultiMeshes. Each lot has a named `Industrial_<id>` root, lot metadata and `industrial_sites` group membership. Gameplay locations remain the existing boiler and fuel-depot entries; no requests or simulation locations were added. Doorsteps align to the new visible entrances.

The port siding remains clear between both warehouses. The fuel-tank compound is10m farther south than its raw catalog offset to clear that same siding, matching the clearance formerly supplied by the generic placement helper. Road/rail coordinates and ambient itineraries were not changed. The checkpoint retains the24m four-lane avenue; its control island replaces only the planted median within the parcel. Import travels south on the west side, export north on the east. Waiting pockets return before control; export secondary returns before passport control. Two inspection halls are a first layout interpretation, not final architectural approval. Painted side routes and raised barriers are scenery; no border processing, queuing or inspection routing is simulated. The pedestrian route meets the existing bridge approach; precise bridge walking clearance and17m articulated-vehicle swept paths remain unresolved.

Rebuild from the repository root in separate stages:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/industrial_sites/build_assets.py
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/industrial_sites/atp/build_atp.py
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/industrial_sites/atp/build_yard.py
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python art/models/industrial_sites/export_assets.py
& 'C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --headless --path init --import
& 'C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' --path init --script (Join-Path (Get-Location) 'art/models/industrial_sites/capture_map.gd') -- --no-log --hour=12
```

The initial seven-site graphical run exited 0 with seven industrial roots and no script/shader errors; overview/west/checkpoint/east captures remain in ignored `.local/industrial-review/`. The approved compact ATP uses the later captures above. Other sites still require individual refinement and user review. Repair equipment, night and seasonal variants were not graphically reviewed. No automated tests were added or run.
