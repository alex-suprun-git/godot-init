# Outskirts district layout implementation — 2026-10-31

The v3 layout is now playable. It has 49 fixed lots: 16 housing blocks, four reserved cores, the transport and civic sites, and 12 village plots. Geography uses metres directly. The seven gameplay locations derive their coordinates from those lots. Actor speeds, requests, outcomes, deadlines, and scenario text are unchanged.

## Files

- `init/scripts/data/district_layout.gd`: fixed lots, roads, railway polylines, water, banks, bridges, village area, and lot queries.
- `init/scripts/data/building_catalog.gd`: reusable contents, modular facade dimensions, condition styles, placeholders, and lot-local dressing.
- `init/scripts/map/district_builder.gd`: terrain, infrastructure, building orientation, road/rail clearance, dressing, and hidden review labels.
- `init/scripts/map/city_map.gd`: delegates layout construction; keeps camera, seasons, tokens, pedestrians, overlays, and boiler states. Old hand-placed layout and SVG coordinate transforms are removed. F9 toggles labels. Shared rendering primitives remain available to the scale reference scene.
- `init/scripts/data/week1.gd`: location-to-lot references, one position lookup, and startup reference validation.
- `init/scripts/sim/week_sim.gd`: uses the shared location lookup at initialization, during movement, and for ETA.
- `init/scripts/dev/autoplay.gd`: captures district regions and boiler repairs; optional `--autoplay-unkept` leaves the water promise unfulfilled to show the real picket consequence.
- Godot generated `.uid` companions for the three new scripts.

The concurrently edited map/art briefs and the new routing brief were read but not edited by this implementation. README and art prompts were not edited. No art was generated and no automated tests were added or run. No commit or push was made.

## Travel measurements

Straight-line game hours, measured using `Week1.location_position()` and the unchanged speeds: player 120 m/h; Tolik 400 m/h. Before positions are from commit e55496e. These are gameplay speeds, not real-world walking/driving measurements.

| From office to | Foot before | Foot after | Car before | Car after |
|---|---:|---:|---:|---:|
| Block 5 | 1.38 | 1.65 | 0.42 | 0.49 |
| Boiler house | 2.09 | 4.25 | 0.63 | 1.27 |
| Market | 1.21 | 2.72 | 0.36 | 0.82 |
| Church | 0.57 | 1.65 | 0.17 | 0.49 |
| Fuel depot | 0.56 | 3.70 | 0.17 | 1.11 |
| Wasteland | 1.86 | 3.52 | 0.56 | 1.06 |

## Visual and gameplay verification

Godot headless import completed. The sandbox could not save the user's global editor settings; graphical runs completed without engine/script errors. Graphical autoplay completed the 60-hour week and reached week two. Screenshots were inspected for the river, both bridges, checkpoint lanes, four residential superblocks and their cores, civic axis, village, market/station, two southern tracks and the eastern freight line. The tram and merchant houses are absent.

- Standard before log: `2026-10-31_08-52-04_autoplay.jsonl`.
- Standard after log: `2026-10-31_09-02-34_autoplay.jsonl`.
- Latest broken-promise visual run: `2026-10-31_09-09-33_autoplay.jsonl`.
- Logs live under `~/Library/Application Support/Godot/app_userdata/Init/playtests/`.

| Standard autoplay metric | Before | After |
|---|---:|---:|
| Completed game hours | 60.0 | 60.0 |
| Waiting without an available decision, hours | 58.2 | 57.5 |
| Blocked with requests pending, hours | 1.6 | 2.3 |
| Player utilization | 37% | 47% |
| Tolik utilization | 37% | 47% |
| Mikhalych utilization | 11% | 12% |
| Nina utilization | 3% | 3% |
| Requests expired without an answer | 0 | 0 |

These metrics describe immediate automatic decisions, not a human player's experience. The unkept variant deliberately leaves a promise/request pending; its waiting metric is not comparable to the standard runs. Its week also completes, and the log records `block5:picket` appearing at t=58. The crowd was visually confirmed at the street edge of Block 5. Boiler repair scaffolding/fence/crane appear after the actual transition to week two. A separate working-state screenshot previews chimney smoke without changing simulation state.

## Screenshot paths

Final captures: `/private/tmp/district-final/`.

- `overview.png`: final overall view.
- `labels.png`: F9 review labels.
- `default.png`: initial camera view on the executive committee and housing.
- `checkpoint.png`: checkpoint lanes, booths, barriers, and bridge.
- `0_village.png`, `0_south.png`: village and station/market.
- `5_picket.png`: actual broken-promise consequence.
- `7_boiler_repairing.png`: actual week-two repair state.
- `boiler_working_preview.png`: visual preview of the working state.

Review copies of the main views are saved alongside this chat's visualizations under `~/.codex/visualizations/2026/10/30/01a18ef6-c4d5-76d2-9d19-0fa758a13ec2/`, with filenames beginning `district-layout-`.

## Implementation choices and limits

- The facade assembly clarification arrived during implementation and is included: 3 m storeys, 6×3 m entrance/stair modules every 24 m, dedicated nine-storey tiles, and unique center/wing assemblies. Nine-storey buildings remain plain volumes until their tile exists; they do not stack the five-storey facade.
- Unique facade lengths follow the clarified module rule. Police use 36×14 m and 6 m height (12 m center plus two 12 m wings). The polyclinic uses 30×18 m and the executive committee 30×25 m, both 15 m high and with no wing repeats. A 90 m executive-committee frontage would not fit the fixed lot's 85 m north–south extent. The compact center is the nearest fitting modular length; review this landmark's size before final art.
- Checkpoint booths are intentional traffic islands inside the road corridor, as specified. Other building/prop footprints keep clear of roads and rails. Village buildings can shift locally within their fixed plots to clear dirt roads; plot and gameplay-location coordinates do not change.
- The picket uses the public street side, opposite the inward courtyard entrance, so the nine-storey block does not conceal it.
- Ground/river rendering continues beyond the playable bounds to avoid visible terrain edges. Railway bridge heights and standing trains derive from the infrastructure data rather than duplicate world positions.
- Missing dirt-road, quay, parking and commuter-train art uses existing textures/stock. Oil-specific ground detail awaits its asset. The modular executive-committee front uses the existing administration texture as a temporary center; side walls remain plain until wing art exists.
- Map-token spacing adapts to projected scale so grouped portraits remain separate at distant zoom levels. Camera range and haze are adjusted for the enlarged district.
- Character travel remains straight-line movement. Routing is explicitly a subsequent task and has not been implemented.
