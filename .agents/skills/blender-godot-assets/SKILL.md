---
name: blender-godot-assets
description: Create, revise and integrate Blender 3D assets for this Godot project's city map, including MCP execution, GLB export and visual inspection in the game.
---

# Blender to Godot Assets

Run commands from the repository root. Read `art/PROMPTS.md` and the relevant asset README for its reference, current version and approval state. Existing Lada source scripts are in `art/models/lada/`; reuse a suitable asset before rebuilding it.

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

## Build and export

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
