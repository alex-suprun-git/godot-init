---
id: civic-vehicles
status: review   # Models and comparison demo reviewed; map placement is a follow-up.
worker: codex
issue: "#6"
branch: art/civic-service-vehicles
---

# Service vehicles for the administrative centre: UAZ police van and RAF ambulance

## Goal

Static sprites and placeholder cars at the executive committee, police station and polyclinic were removed because they looked crooked. Replace them with proper 3D models in the project's usual vehicle style: a UAZ-452-family police van and a RAF-22031 ambulance ("Latvija"), both as of 1997. The black administration Volga already exists (`init/assets/models/vehicles/volga_gaz24.glb` with `PAINT_BLACK`) and needs no new work.

## Inputs

1. `.agents/skills/blender-godot-assets/SKILL.md` and its references; `tools/blender_mcp.py`.
2. The precedent brief and results: `tasks/volga-gaz24-model.md`, `art/models/volga/`, and `art/models/lada/README.md` for scale, materials and export rules.
3. `art/models/public_transport/references/README.md` for the generated-turnaround method.
4. `init/scripts/map/vehicle_models.gd`: how models, lengths and paint are used.

## Constraints

- Blender MCP drives one live instance: run only this Blender brief at a time (`tasks/README.md`).
- Distinct real-scale bodies appropriate to 1997: UAZ-452-family police van and RAF-22031 ambulance. Establish each variant's measured dimensions before modeling; do not reuse UAZ proportions for RAF. Police livery: cream/blue with a plain blue beacon. Ambulance: off-white with a restrained red stripe, medical crosses and blue beacon. No lettering. The user selected RAF on 2026-11-01, superseding the UAZ ambulance.
- Budget for the intended map viewing distance: low-poly body with separate glass, wheels and lights; no more than the Lada models in triangle count and texture size.
- Generate the multi-view reference sheet first (stylized-concept, orthographic left, right, front, rear, top, the same prompt style as the transport sheets), inspect it, then model.
- Keep the editable Blender source separate from the game export. Scope the glTF export to the asset only and inspect the exported contents.
- No real lettering or readable plates.

## Outputs

Write only to these paths:

- `art/models/uaz_service/` and `art/models/raf_ambulance/` (references, notes, Blender sources, previews).
- `init/assets/models/vehicles/uaz_police.glb` and `raf_ambulance.glb`.
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

- **Status (2026-11-02):** Both service models and the Godot comparison demo are complete. The user positively reviewed their appearance, requested both vans 15% smaller, Volga 10% smaller and ZIL 5% larger, then approved branch `art/civic-service-vehicles` and requested a PR. The branch starts at refreshed `origin/main` (`ce68b5e`); unrelated facade changes were excluded.
- **Outputs:** Editable sources, build/export scripts, reference records and actual GLB inspection JSONs under `art/models/uaz_service/` and `art/models/raf_ambulance/`; `uaz_police.glb`, `raf_ambulance.glb` and their Godot import/palette files under `init/assets/models/vehicles/`. The standalone demo is `art/models/uaz_service/preview_project/`; run `prepare_preview.py` before its first Godot import. Source dimensions, sourcing and rebuild stages are in the asset READMEs.
- **Measured exports:** UAZ length 3.774 m, overall mirror width 1.938 m, beacon height 1.9397 m; RAF 4.3095 / 1.938 / 1.938 m. Both GLBs embed the user-requested 0.85 scale; editable sources retain measured real dimensions. UAZ has 10,688 triangles, RAF 9,864; each has one scene, six nodes, five meshes, seven primitives, three materials and one embedded 64px palette atlas, without animation or camera. Each remains below the Lada triangle/texture budget.
- **Scope extension:** The user's subsequent scale requests also change the shared `vehicle_models.gd`: Volga uses a 0.90 presentation factor; both ZIL bodies use 1.05 after the previous truck scale. KamAZ and buses retain their factors. No service-vehicle catalog entries or map placements were added.
- **Verification:** In the isolated worktree, Godot 4.7.2 imported both projects, the comparison demo captured successfully, and graphical `--autoplay --only=vehicles --turbo --no-log` completed. Inspected the comparison and a Volga street frame; the game reported 118 vehicles including four Volgas. Logs and screenshots are ignored under `.local/verification/`. No automated tests were added or run. A local Windows certificate-store warning did not prevent import/capture. Final GLB materials use an embedded atlas to avoid the observed vertex-albedo import issue on fittings.
- **Review notes / limitations:** The preview Volga matches the actual game GLB by SHA-256 (7,775 triangles, three materials); its original black material is preserved. These are simplified period exteriors with opaque glazing, without interiors/collisions. New service-vehicle town placements and full-week gameplay were not verified.
- **Next integration:** Register and place the models at police/clinic surfaces in a separate update. Preserve the embedded van scale: use the current measured exported lengths and do not apply an additional 0.85 factor. Review the actual town frame when integrating. Open the isolated demo with `Godot --editor --path art/models/uaz_service/preview_project`; the main worktree project is `init/`.

## Review notes

_Filled in by the lead after each review round._
