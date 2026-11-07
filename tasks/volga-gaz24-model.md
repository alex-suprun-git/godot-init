---
id: volga-gaz24-model
status: done   # ready | in-progress | review | blocked | done
worker: codex
branch: task/volga-gaz24-model
---

# Black GAZ-24 Volga game model, derived from the Lada

## Goal

Produce a game-ready GLB of the administration's clean black GAZ-24 Volga that reads as a long, low, dignified car under the actual map camera and matches the existing Lada in style, scale and finish. Build it as an original procedural model derived from the project's own Lada scripts, the same way the Lada wagon was derived from the sedan. No downloaded models: this keeps the licence clean and the conventions identical. Integration into the city map is not part of this brief.

## Inputs

- `art/models/lada/`: `build_lada.py`, `finish_lada.py`, `export_lada.py` and the wagon variants as the worked example of deriving a body (`build_lada_wagon.py` etc.); `README.md` for conventions.
- **Primary visual reference:** `init/assets/sprites/car_volga_black_v3.png`, the approved map sprite. The Lada model was built from its sibling `car_lada_v3.png` the same way, so matching this sprite keeps the two cars in one style. Proportions come from the real car (below), the look from the sprite.
- `art/PROMPTS.md`: the Volga brief (GAZ-24, clean black) and the V3 proportion pass notes.
- `init/scripts/data/prop_dimensions.gd`: the sprites are calibrated at 4.3 m (Lada) and 5.0 m (Volga).
- `.agents/skills/blender-godot-assets/SKILL.md`: MCP execution, staged build/bake/export and previews.
- `art/models/volga/SOURCING.md`: superseded decision (download and adapt); update it to record the switch to a Lada-derived original build.

## Constraints

- Subject: GAZ-24 only, not the GAZ-3102. The read at map zoom matters most: longer and lower than the Lada, long flat bonnet and boot, chrome grille and bumpers, black paint.
- **Dimensions.** The Lada source model is a stylised VAZ-2107, not a 1:1 copy. Apply the same stylisation factors to the real GAZ-24 so both cars share one scale:

  | | Real VAZ-2107 | Lada model (measured) | Factor | Real GAZ-24 | Volga target (bounding box) |
  |---|---|---|---|---|---|
  | Length | 4.145 m | 4.37 m | ×1.054 | 4.735 m | **≈ 4.99 m** |
  | Width | 1.62 m | 1.85 m | ×1.14 | 1.80 m | **≈ 2.05 m** |
  | Height | 1.44 m | 1.44 m | ×1.00 | 1.49 m | **≈ 1.49 m** |

  Tolerance ±3 %. Wheelbase and wheel size scale by the length factor (GAZ-24 wheelbase 2.80 m → ≈ 2.95 m). If the targets conflict with the sprite's silhouette, keep the dimensions and report the conflict.
- Copy the Lada scripts to `build_volga.py`, `finish_volga.py` and `export_volga.py`; do not edit the Lada scripts.
- Same conventions as the Lada: metres, front is Blender -Y (Godot +Z), tires at height zero, export only the asset collection.
- Render-cost requirement: cars are 6–24 px long on screen and the map shows over 100 vehicles. Target at most about 8k triangles and **no more than 3 materials** (paint/body atlas, glass, chrome/rubber) for the game copy; bake details into the paint texture instead of separate surfaces. The paint material name must contain `paint` so `vehicle_models.gd` can tint it, even though the default colour is black.
- Keep the editable `.blend` source separate from the game export.
- Blender is a shared resource: no other Blender brief may run at the same time.

## Outputs

Write only to these paths:

- `art/models/volga/` (scripts, README, `.blend` source, previews, `SOURCING.md` update)
- `init/assets/models/vehicles/volga_gaz24.glb` and its textures and `.import` files
- this brief (`tasks/volga-gaz24-model.md`)

## Acceptance criteria

- [ ] `art/models/volga/README.md` documents the build stages, dimensions, triangle, material and texture counts, and how to rebuild.
- [ ] Measured bounding box of the exported GLB (read from the file, not from the script's constants) within ±3 % of the dimension targets, written to the README next to the Lada's measured box.
- [ ] Multi-angle previews, including one at the map camera angle (isometric, orthographic) with the Lada GLB placed beside it in the same Blender scene at unchanged scale, and one side view with both cars over a 1 m grid, under `art/models/volga/previews/`.
- [ ] Game copy within the render-cost requirement above.
- [ ] `volga_gaz24.glb` imports in Godot without errors (`Godot --headless --path init --import` in the worktree) and contains only the car.
- [ ] `SOURCING.md` records the switch away from downloaded candidates.

## Stop and ask

Stop with `status: blocked` and explain in the report when:

- a visual choice beyond "clean black GAZ-24" comes up (tint, chrome amount, damage, colour variants);
- the render-cost requirement cannot be met without losing the silhouette;
- the work would require editing files outside *Outputs*.

## Report

- **Status summary (audit 2026-11-01):** The model is built and integrated, not awaiting production. Keep this brief in review because the source README explicitly leaves the final rounded bonnet/boot revision awaiting user review.
- **Files created or changed:** Main checkout contains `init/assets/models/vehicles/volga_gaz24.glb`, extracted textures, vehicle loading/repainting and the black administration car. Editable source, build scripts, detailed README and export report exist in `../godot-worktrees/volga-gaz24-model/art/models/volga/`; they have not been consolidated into the main checkout. Preserve that worktree.
- **Measurements / previews:** Source README reports 4.905458 × 2.046548 × 1.490000 m, 7,775 triangles and three materials, within the brief's budgets. Its `previews/` and `validation/` contain model review evidence. Main-checkout `art/models/volga/SOURCING.md` records successful import and traffic review; `traffic_review/` contains Godot frames and a log. This audit inspected files and documentation; it did not rerun Blender or Godot.
- **Open questions:** Final visual review of the rounded bonnet/boot. No new model build is required.
- **Requests for the integrator:** Finish visual review and consolidate editable sources/documentation from the asset worktree before retiring it. Model integration and measured source-length handling already exist in `vehicle_models.gd`.

## Review notes

_Filled in by the lead after each review round._

- Integration note for the lead: `VehicleModels.create()` scales every model to the length passed by the caller, and `city_map.gd` passes 4.3 for all cars. A Volga placed that way would be shrunk to Lada length. Add its source length to `LENGTHS` and place it at ≈ 4.91 m (4.99 × the Lada's 4.3 / 4.37 map factor).

- Audit 2026-11-01: the integration note above predates the current implementation; source-length handling is already present.

- 2026-11-07: the asset worktree no longer exists, and the editable sources, build scripts and source README were never committed, so the consolidation requested above can no longer happen. They are recorded as lost in `art/models/volga/SOURCING.md`; only the game GLB and textures remain. The Volga is no longer a vehicle benchmark (see the Blender skill).
