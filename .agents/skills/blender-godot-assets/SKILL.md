---
name: blender-godot-assets
description: Find and evaluate reusable 3D models, or create, revise and integrate Blender assets for this Godot project's city map, including MCP execution, GLB export and visual inspection in the game.
---

# Blender to Godot Assets

Run commands from the repository root. Read `art/PROMPTS.md` and the relevant asset README for its reference, current version and approval state. Use the current truck and Volga as the project benchmarks for new vehicle models; see the comparison rules below. Reuse suitable existing helpers before rebuilding them.

## Current vehicle benchmarks

User direction updated 2026-11-01: compare new vehicle models, including buses, with the existing truck and Volga for dimensions, proportions, visual finish and map readability.

- Current truck sources and scale: `art/models/traffic/README.md` and `art/models/traffic/upgrade/`; game exports: `truck_kamaz_semi.glb`, `truck_zil_flatbed.glb` and `truck_zil_food.glb` under `init/assets/models/vehicles/`. The old primitive truck generator/source were removed from main. Compare the actual game instances, including the approved 0.80 truck presentation factor, rather than raw GLBs at scale 1.
- Volga game export: `init/assets/models/vehicles/volga_gaz24.glb`; inspect the current asset and its available source record before using older sourcing notes as current status.
- Establish the new vehicle's own real dimensions for the chosen variant. Measure the current GLBs and inspect their actual placement/scaling in `init/scripts/map/vehicle_models.gd` and its callers. Compare length, width, height, wheel size and grounding beside the truck and Volga in a shared Godot frame, with identical camera and lighting.
- Use the truck and Volga as references for compatible detail, materials and silhouette readability, choosing a budget for the new asset's screen size and instance count.
- The Lada is a legacy implementation example, not the benchmark for new models. Its 4.37-to-4.3 m conversion is existing code behavior, not a prescribed scale factor for buses or future assets. Resolve integration scale against the current truck and Volga comparison instead of inheriting that factor automatically.

## Read the existing vehicle reference sheets first

User direction (2026-11-04): newer approved RAF, PAZ and ZIL models are the current vehicle finish benchmarks. Retain the existing dimensional checks, but follow the user's chosen comparison family rather than defaulting to the old Lada or Volga appearance.

Before generating a new vehicle sheet or modelling from one, open an actual existing family reference, not just its README: `art/models/raf_ambulance/references/raf-22031-turnaround-v1.png`, `art/models/uaz_service/references/uaz-police-turnaround-v1.png`, or `art/models/public_transport/references/paz-3205-turnaround-v1.png`. Reuse the appropriate adjacent prompt/layout and supply the sheet as a style reference when generating a matching sheet. Their left/right/front/rear/top views, aligned ground baselines, clear rounded solid surfaces, neutral construction grid and small secondary three-quarter view are useful working examples; the grid is not calibrated. Inspect the actual outputs: matching prompt words alone do not establish a matching reference family.

Vehicle-specific construction, attachment checks and lessons from rejected silhouettes are in [references/vehicle-modeling.md](references/vehicle-modeling.md). Read them before changing body proportions or fitting lamps/bumpers.

## Find before building

For sourcing an asset or deciding whether to reuse one, read [references/asset-sourcing.md](references/asset-sourcing.md). Search and shortlist within the user's task; a research request alone does not authorize replacing game assets. Record candidates, evidence and a concrete adapt/build decision under `art/models/<asset>/SOURCING.md`. The first worked example is `art/models/volga/SOURCING.md`.

Read the same reference for downloaded-model inspection and adaptation: it defines what Codex handles independently, when the user is involved, which previews to produce, and how to preserve a resumable handoff across chats.

## Connect and execute

Prefer native Blender MCP tools when exposed. Otherwise use the persistent project client, which reads the configured `blender` STDIO server from Codex without hardcoding a uv cache or Python installation path:

```sh
uv run --script tools/blender_mcp.py status
uv run --script tools/blender_mcp.py list --tool look
uv run --script tools/blender_mcp.py --user-prompt 'Original user request' run path/to/short_script.py
uv run --script tools/blender_mcp.py --user-prompt 'Original user request' start path/to/long_script.py
uv run --script tools/blender_mcp.py job-status path/to/long_script.job.json
```

Use `call TOOL --json arguments.json` for other MCP operations. Image results are saved under `--output-dir`; inspect the files. `run` and `start` set the real `__file__` so generators can resolve project-relative paths. Pass the user's actual goal to `--user-prompt` without inventing a new request.

Keep short scene queries and edits synchronous. Queue baking/rendering with `start`; scripts can call `job_checkpoint('running', stage='bake')` before an expensive stage. Job completion means that script returned; separately queued child operations need their own completion signal. First-time Cycles Metal compilation took several minutes on this Mac. A client timeout does not cancel Blender: inspect job state and outputs before retrying. If native tool discovery is unavailable, use the client instead of repeatedly restarting apps or clicking UI.

## Vehicle shape and revisions

For original vehicle modelling or body-shape revisions, read
[references/vehicle-modeling.md](references/vehicle-modeling.md). It covers
reference-led body/roof/glazing construction, silhouette-first budgets and
matched before/after inspection, with the verified Volga workflow as an example.
Reuse its helpers and stages without inheriting another vehicle's proportions.

## Build and export

- User direction (2026-11-03): spend modeling/detail budgets on surfaces and silhouettes visible from the standard game camera. Hidden backs need only simple closing geometry; omit occluded interiors and invisible underside detail. Expand this scope only when a requested camera or visible effect requires it.
- Decide the silhouette, intended camera distance, units and geometry/material/texture budgets first. Inspect a cheap multi-angle preview before expensive finishing.
- Preserve unrelated scenes. Use named asset collections and save a `.blend` checkpoint before a long bake. Keep geometry, baking, export and preview stages separate; check whether a script supports rerunning before resuming it.
- Use metres and document the forward axis. Lada uses Blender -Y, which exports as Godot +Z.
- Bake Blender-only procedural paint to portable image textures. Keep editable source detail while reducing only the game copy.
- Export the asset scene/collection explicitly. The working Lada exporter uses `use_selection=True` and `use_active_scene=True`; selection alone also exported the original cube from another scene. Inspect GLB scene/mesh counts and embedded textures.
- Inspect uncertain API names against the installed Blender/Godot version rather than guessing enums or operator arguments.

## Integrate and inspect

Game assets belong under `init/assets/models/`; sources and previews under `art/models/`. Use `init/scripts/map/vehicle_models.gd` for shared vehicle scenes and real axis rotations. Painted-prop mirroring and anchor calibration do not apply to these meshes.

`CityMap._ground()` returns height zero, while street asphalt is at 0.14 m, lot paving at 0.025 m, and the authored courtyard at 0.075 m. Position tires on the actual surface; recheck these heights if layout code changes.

Import with Godot `--headless --path init --import`, then launch the graphical game and inspect grounding, both street orientations and scale beside buildings/people. Use a writable `--log-file` with CLI launches. A successful headless load does not establish visual quality. The vehicle-only autoplay mode captures the courtyard, clinic and perspective view without replaying the whole week:

```sh
Godot --path init -- --autoplay --vehicles-only --shots=/absolute/output/dir --no-log
```

Keep `art/PROMPTS.md` and the asset README current. Show a real in-engine frame when reporting the integration.
