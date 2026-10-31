---
id: civic-vehicles
status: ready   # draft | ready | in-progress | review | blocked | done
worker: codex
branch: task/civic-vehicles
---

# Service vehicles for the administrative centre: UAZ police van and ambulance

## Goal

Static sprites and placeholder cars at the executive committee, police station and polyclinic were removed because they looked crooked. Replace them with proper 3D models in the project's usual vehicle style: a UAZ-452 police van and a UAZ-452 ambulance ("tabletka"), both as of 1997. The black administration Volga already exists (`init/assets/models/vehicles/volga_gaz24.glb` with `PAINT_BLACK`) and needs no new work.

## Inputs

1. `.agents/skills/blender-godot-assets/SKILL.md` and its references; `tools/blender_mcp.py`.
2. The precedent brief and results: `tasks/volga-gaz24-model.md`, `art/models/volga/`, and `art/models/lada/README.md` for scale, materials and export rules.
3. `art/models/public_transport/references/README.md` for the generated-turnaround method.
4. `init/scripts/map/vehicle_models.gd`: how models, lengths and paint are used.

## Constraints

- Blender MCP drives one live instance: run only this Blender brief at a time (`tasks/README.md`).
- Real-scale proportions of the UAZ-452 (about 4.4 m long, 2.1 m wide, 2.1 m high), 1997 appearance. The police van: cream-and-blue period livery, a plain roof beacon; the ambulance: off-white body with a restrained red-cross band (a vehicle stripe, not a readable sign).
- Budget for the intended map viewing distance: low-poly body with separate glass, wheels and lights; no more than the Lada models in triangle count and texture size.
- Generate the multi-view reference sheet first (stylized-concept, orthographic left, right, front, rear, top, the same prompt style as the transport sheets), inspect it, then model.
- Keep the editable Blender source separate from the game export. Scope the glTF export to the asset only and inspect the exported contents.
- No real lettering or readable plates.

## Outputs

Write only to these paths:

- `art/models/uaz_service/` (references, notes, Blender source, previews).
- `init/assets/models/vehicles/uaz_police.glb` and `uaz_ambulance.glb`.
- the Report section of this brief.

## Acceptance criteria

- [ ] Two GLBs exist, real scale (lengths measured and stated), origin at the ground centre, +Z forward, consistent with the Lada and Volga models.
- [ ] A Godot frame (`init/scripts/dev` tooling or a minimal scene saved outside `init/scripts`) shows both models at the map's camera distance; attach the preview and describe any defect.
- [ ] Exported GLB contents are inspected and listed in the report.
- [ ] Nothing outside *Outputs* is edited; integration into the catalog is requested from the integrator.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- Blender MCP is unreachable or already busy with another brief;
- the generated references cannot be made consistent;
- the work would require editing files outside *Outputs*.

## Report

_Filled in by the worker._

- **Status summary:**
- **Files created or changed:**
- **Measurements / previews:**
- **Open questions:**
- **Requests for the integrator:** (the `LENGTHS` entries and catalog dressing to add)

## Review notes

_Filled in by the lead after each review round._
