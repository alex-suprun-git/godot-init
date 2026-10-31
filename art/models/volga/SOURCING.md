# Current implementation checkpoint (2026-10-31)

The download research below is historical and superseded. The project now uses
an original procedural GAZ-24 derived from the Lada workflow. Editable sources
and build documentation remain in
`../godot-worktrees/volga-gaz24-model/art/models/volga/README.md`.

The latest rounded-body GLB (7,775 triangles, three materials) is copied into
the main project's `init/assets/models/vehicles/volga_gaz24.glb` and loaded by
`vehicle_models.gd`. Civilian ambient/parked selection is approximately 1/15;
six shared colour variants replace only the black lacquer through
`vehicle_paint.gdshader`. The administration car retains the original black.
The updated palette excludes burgundy/red and uses bottle green instead of olive, with light/mid-tone colours weighted at 85% and dark colours at 15%. See root README for the agreed traffic palette. Do not overwrite these game
changes when integrating the earlier asset worktree's scripts.

Godot import and the graphical vehicle autoplay completed successfully.
The current deterministic scene selected 3 Volgas among 60 moving cars;
1/15 is a probability, not an exact quota for each small sample. Grey and ivory
variants were inspected on actual streets. Screenshots/log: `traffic_review/`.
No automated tests were added or run; no commit or push was made.

---

# Volga sourcing review

Checked: 2026-10-31. Stage: metadata research only. No model has been downloaded, visually approved or integrated.

## Brief

`art/PROMPTS.md` specifies the administration's clean black GAZ-24 sedan, approximately 4.7 m long, 1.8 m wide and 1.5 m tall. It should read as a long, low, dignified car in the painted 1997 city. Match the existing Blender Lada under the actual map camera. The GAZ-3102 and other variants are not interchangeable with the current brief.

Provisional game-copy target: roughly 5–25k triangles, few materials and 1–2K textures where sufficient. These are working budgets, not acceptance thresholds; retain a lighter candidate if its silhouette and finish hold up at the intended zoom. Detailed interiors are a lower priority than body shape, chrome, windows and wheels.

## Candidates

| Candidate and author | Listing evidence | Disposition |
| --- | --- | --- |
| [GAZ-24 Volga Black — eightismore](https://sketchfab.com/3d-models/gaz-24-volga-black-ac19841adca7495586838a0f8d52e209) | Indexed author listing advertises download, approximately 4k triangles / 2.1k vertices and CC Attribution. Exact license version, archive formats and textures not verified. | First candidate for acquisition and visual inspection: exact black GAZ-24 subject and a light mesh. Material quality and body detail remain unknown. |
| [Gaz 24 Volga — assg709](https://sketchfab.com/3d-models/gaz-24-volga-6e87cb4fa6aa4a85b6afd4623a0c2dfb) | Indexed author listing advertises download, approximately 71k triangles / 39.2k vertices and CC Attribution. Formats and exact license version not verified. | Backup if the lighter model's shape/detail is insufficient; evaluate simplification rather than assuming the heavier mesh is better. |
| [1971 GAZ-24 Volga (LP) — KrStolorz](https://krsto.artstation.com/projects/4brmVW) | Author portfolio describes free download and two updated textured versions with corrected topology, last changed May 15, 2026. Reuse license and triangle count not verified. | Further lead if needed; "free download" alone is insufficient for selection. |
| [Gaz 24 Volga — korchevskytea](https://sketchfab.com/3d-models/gaz-24-volga-e608a61a15de4eb4b1667eb811b1744a) | Indexed listing states CC Attribution-NonCommercial and about 64k triangles. | Exclude from the default reusable game asset path due to NC terms. |
| [Volga GAZ-24 — car-b-uncle](https://free3d.com/3d-model/volga-gaz-24-88347.html) | Direct listing states Personal Use License and `.blend`; lacks useful geometry/material metadata. | Exclude from the default reusable game asset path. |

Search routes included Sketchfab vehicle listings, the author's ArtStation portfolio, Free3D and a targeted GitHub search. No suitable author-maintained Volga asset repository was identified in this search. Sketchfab direct page fetches returned HTTP 403 in the research tool; the two shortlisted listings' metadata comes from search-indexed author pages, not inspection of downloaded files. Current download access, price and exact terms must be rechecked at acquisition.

## Decision

**Investigate adapting eightismore's black GAZ-24 before building another original car.** It matches the subject and is economical enough to justify a quick inspection. This is a technical sourcing recommendation, not a claim that the model's visual quality is accepted.

Next, when model implementation is requested: acquire through the normal download flow; retain the exact license and attribution; verify materials, silhouette, wheels and actual counts in Blender; compare with the approved Lada in Godot. Use assg709's model as the backup. Build an original model if acquisition/terms fail or adaptation cannot meet the visual target economically.

## Handoff checkpoint

- The latest request is to preserve the working agreement in documentation; downloading or integrating the Volga has not yet been requested.
- No archive, Blender inspection report, Volga-specific scripts, previews or GLB exist from this sourcing task. The reusable Blender MCP execution client already exists at `tools/blender_mcp.py`; a generic downloaded-model inspection script has not been implemented.
- On an implementation request, first attempt to acquire eightismore's model independently. Ask for help only if the normal download requires user login/purchase or remains inaccessible. Research-tool HTTP 403 does not establish whether the normal browser download works.
- The current brief remains a clean black GAZ-24. Recolouring, glass/tint changes, simple interior work and simplification are supported adaptation options discussed with the user, not approved specific changes to this model.
- Follow `.agents/skills/blender-godot-assets/references/asset-sourcing.md` for the agreed inspection, preview, adaptation and review process. Create and retain the asset-specific scripts during implementation so later variants can reuse them.
