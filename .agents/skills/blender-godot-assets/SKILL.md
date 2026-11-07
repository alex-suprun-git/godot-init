---
name: blender-godot-assets
description: Use when sourcing, modelling, revising, exporting or integrating any 3D asset for this Godot project's city map, including vehicles, buildings, building ensembles and industrial or service sites (kiosks, churches, houses, depots). Covers Blender MCP execution, GLB export, grounding and in-game inspection. Not for HUD/UI elements (use godot-ui-elements) or 2D raster art preparation alone (follow art/ASSET_PIPELINE.md).
---

# Blender to Godot Assets

Run commands from the repository root. `Godot` below is the full binary path from `AGENTS.md` (Workflow). Read `art/PROMPTS.md` and the asset README for its reference, current version and approval state. Approval means what `art/ASSET_PIPELINE.md` ("Visual approval") defines; a line in the asset README is the only evidence of it.

The rules below are the current ones. When the user changes a rule, replace the rule here and move the old reasoning, with its date, into the affected asset README. Do not append a second, dated rule next to the first.

## Compose complete map locations

For building ensembles and industrial/service compounds, read [references/site-composition.md](references/site-composition.md). The approved ATP is the worked example for purposeful site composition, circulation, material finish and landscaping; its dimensions, source stages and remaining limitations are in [the ATP asset record](../../../art/models/industrial_sites/README.md). Its exact dimensions and enclosure are location-specific. Industrial refinement proceeds one location at a time.

## Vehicle benchmarks

The RAF, PAZ and ZIL models are the only benchmarks for new vehicles: for dimensions, proportions, visual finish and map readability. The truck (KamAZ), Volga and Lada are not benchmarks; do not copy their shapes, finish or scale factors.

| Benchmark | Game export | Source and record | Map presentation factor |
| --- | --- | --- | --- |
| RAF-22031 ambulance | `init/assets/models/vehicles/raf_ambulance.glb` | `art/models/raf_ambulance/` (`build_raf.py`, `export_raf.py`, `README.md`) | recorded in its README; the RAF is not yet placed on the map, so compare it in a preview scene |
| PAZ-3205 bus | `init/assets/models/vehicles/bus_paz_3205.glb` | `art/models/public_transport/` (`build_buses.py`, `finish_buses.py`) | `BUS_VISUAL_SCALE` in `init/scripts/map/vehicle_models.gd` |
| ZIL flatbed and food trucks | `truck_zil_flatbed.glb`, `truck_zil_food.glb` | `art/models/traffic/README.md`, `art/models/traffic/upgrade/` | `TRUCK_VISUAL_SCALE` × `ZIL_VISUAL_ADJUSTMENT` in `vehicle_models.gd` |

Read the factors from the code or README at the time of the comparison; do not copy numbers into new docs.

1. Establish the new vehicle's own real dimensions for the chosen variant from a cited source. Record them in its asset README.
2. Compare length, width, height, wheel size and grounding beside the benchmark closest in kind (a van beside the RAF, a bus beside the PAZ, a lorry beside the ZILs) in one Godot frame with identical camera and lighting. Use each benchmark's presentation factor, never raw GLBs at scale 1 next to a reduced one.
   For a class with no close benchmark (cars such as the Lada, tractors, rail vehicles), still match finish and readability to RAF/PAZ/ZIL, but ask the user which scale reference applies before fixing a presentation factor.
3. Propose the new vehicle's presentation factor from that comparison and label it as proposed until the user approves it.
4. Match detail, materials and silhouette readability to the benchmarks, with a budget for the new asset's screen size and instance count.

Before generating a new vehicle reference sheet, open an actual benchmark sheet, not just its README: `art/models/raf_ambulance/references/raf-22031-turnaround-v1.png`, `art/models/uaz_service/references/uaz-police-turnaround-v1.png` or `art/models/public_transport/references/paz-3205-turnaround-v1.png`. Reuse the adjacent prompt and layout from `art/PROMPTS.md` and supply the sheet as a style reference. Their left/right/front/rear/top views, aligned ground baselines, rounded solid surfaces, neutral construction grid and small three-quarter view are the expected layout; the grid is not calibrated. Inspect the actual outputs: matching prompt words do not establish a matching reference family.

Vehicle construction, attachment checks and lessons from rejected silhouettes are in [references/vehicle-modeling.md](references/vehicle-modeling.md). Read it before modelling a vehicle or changing body proportions, lamps or bumpers.

## Find before building

For sourcing an asset or deciding whether to reuse one, read [references/asset-sourcing.md](references/asset-sourcing.md). Search and shortlist within the user's task; a research request alone does not authorize replacing game assets. Record candidates, evidence and a concrete adapt/build decision under `art/models/<asset>/SOURCING.md`. The same reference defines downloaded-model inspection and adaptation, what Codex handles independently, when the user is involved, and the resumable handoff.

## Connect and execute

Prefer native Blender MCP tools when exposed. Otherwise use the project client. It reads the `blender` STDIO server from the Codex config (`%USERPROFILE%\.codex\config.toml`, or `.codex/config.toml` in the repository):

```sh
uv run --script tools/blender_mcp.py status
uv run --script tools/blender_mcp.py list --tool look
uv run --script tools/blender_mcp.py --user-prompt 'Original user request' run path/to/short_script.py
uv run --script tools/blender_mcp.py --user-prompt 'Original user request' start path/to/long_script.py
uv run --script tools/blender_mcp.py job-status path/to/long_script.job.json
```

`status` reporting "Could not connect to Blender" means Blender is not running or its MCP addon is not started. Ask the user to start Blender with the addon; do not restart applications or click through UI yourself.

Build, finish and export scripts that need no live scene can run without MCP in background mode, as the ATP record shows:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python <script.py>
```

Use `call TOOL --json arguments.json` for other MCP operations. Image results are saved under `--output-dir`; inspect the files. `run` and `start` set the real `__file__` so generators can resolve project-relative paths. Pass the user's actual goal to `--user-prompt` without inventing a new request.

Keep short scene queries and edits synchronous. Queue baking and rendering with `start`; scripts can call `job_checkpoint('running', stage='bake')` before an expensive stage. Job completion means that script returned; separately queued child operations need their own completion signal. A first Cycles shader compilation can take several minutes. A client timeout does not cancel Blender: inspect job state and outputs before retrying.

## Reusable helpers

Start from an existing asset's scripts instead of writing a generator from scratch. Copy them into the new asset's folder and adapt them; do not import across asset folders.

- Vehicle body, finish and export: `art/models/raf_ambulance/build_raf.py`, `export_raf.py`; `art/models/public_transport/build_buses.py`, `finish_buses.py`.
- Godot comparison previews: `art/models/public_transport/preview_buses.gd` and `preview_buses.py`.
- Sites and buildings: the scripts listed in `art/models/industrial_sites/README.md`.

Reuse the stages and helpers, not another vehicle's proportions.

## Build and export

- Spend modelling and detail budgets on surfaces and silhouettes visible from the standard game camera. Hidden backs need only simple closing geometry; omit occluded interiors and invisible underside detail unless a requested camera or visible effect needs them.
- Decide the silhouette, intended camera distance, units and geometry/material/texture budgets first. Inspect a cheap multi-angle preview before expensive finishing.
- Preserve unrelated scenes. Use named asset collections and save a `.blend` checkpoint before a long bake. Keep geometry, baking, export and preview stages separate; check whether a script supports rerunning before resuming it.
- Use metres. Model with the vehicle's front towards Blender -Y, which exports as Godot +Z (the forward axis `vehicle_models.gd` expects), and record the axis in the asset README.
- Bake Blender-only procedural paint to portable image textures. Keep editable source detail while reducing only the game copy.
- Export the asset scene/collection explicitly with `use_selection=True` and `use_active_scene=True`; selection alone once exported a cube from another scene. Inspect GLB scene/mesh counts and embedded textures.
- Keep the editable `.blend` and build scripts inside the repository under `art/models/<asset>/` (where the license permits). Sources kept only in a worktree or outside the repository have been lost before.
- Inspect uncertain API names against the installed Blender/Godot version rather than guessing enums or operator arguments.

## Integrate and inspect

Game assets belong under `init/assets/models/`; sources and previews under `art/models/`. Use `init/scripts/map/vehicle_models.gd` for shared vehicle scenes and real axis rotations. Painted-prop mirroring and anchor calibration do not apply to these meshes.

Ground height: `CityMap._ground(at)` returns the terrain height at a point via `_bridge_height`: zero everywhere except on road bridges (decks and their ramps); railway spans do not raise it. Surfaces sit above it: street asphalt at 0.14 m (highway patches 0.139 m, yards 0.135 m, see `district_builder.gd`), lot paving at 0.025 m, the residential courtyard at 0.075 m. Place tyres on the actual surface under the vehicle, and recheck these values in the code if layout changes.

Run the import and the CI checks from `AGENTS.md`, then launch the graphical game and inspect grounding, both street orientations and scale beside buildings and people. Use a writable `--log-file` with CLI launches. A successful headless load does not establish visual quality. The vehicle review scenario captures vehicle frames and prints vehicle counts without replaying the whole week:

```sh
Godot --path init -- --autoplay --only=vehicles --no-log --shots=<absolute output dir>
```

Keep `art/PROMPTS.md` and the asset README current. Show a real in-engine frame when reporting the integration.
