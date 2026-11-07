# Church and cemetery ensemble

First integrated 3D pass, 2026-11-07. The user accepted the [contextual composition](../../source_images/district_visual_pack/church-cemetery-ensemble-v1.png) and [church architecture](../../source_images/district_visual_pack/church-v1.png), requiring real dimensions and relative proportions. The user approved the integrated summer appearance and requested a commit and PR on 2026-11-07.

## Measured implementation

The canonical site record is `init/scripts/data/church_site.json`. Map X is east and Z south; Blender X is east, Y north and Z up. Units are metres; all three building instances use scale 1. The west entrance and east apse are modeled explicitly, irrespective of which side the default camera shows.

| Element | Nominal dimensions |
|---|---|
| Church masonry footprint | 18 × 12 m |
| Church maximum height, including cross | 18.5 m |
| Parish house footprint | 9 × 7 m |
| Utility shed footprint | 5 × 4 m |
| Vehicle / pedestrian gate clear width | 3.6 m / 1 m |
| Ordinary grave / grave enclosure | about 1 × 2 m / 1.4 × 2.44 m |
| Bench | 2 m long, seat about 0.51 m above ground |
| Site trees | 5.4–6.8 m high, reused seasonal vegetation |

The church's complete export envelope is approximately 20.07 × 12.79 × 18.5 m, including steps, roof overhangs and drainage; this is distinct from the masonry footprint. There is no image-derived stretching or presentation multiplier. The church has about 14,500 triangles against a 30,000 budget; each support asset is below 6,000. Exact mesh bounds, triangles and material/image counts: `export_report.json`.

Village compaction reduced the ground layout by 10% in area while preserving building dimensions. The church parcel is now approximately 56.9 × 47.4 m and the original cemetery parcel 33.2 × 43.6 m; both share one stepped perimeter without an internal fence. The north wicket aligns with the graph entrance at (257.2012,75.1766) and doorstep at (257.2012,95.763). The concept's extra southern gate is omitted.

The user requested denser graves and purposeful planting on 2026-11-07. Seventy-seven graves now extend east into the formerly empty strip west of the church, served by a second 1.3 m longitudinal aisle and the existing cross-path. Their roughly 3.0 m column spacing and 3.6 m row spacing retain access around the full-size modules. Nine benches face adjoining paths from small gravel pads. Twenty seasonal trees and 271 low shrubs frame path edges and the perimeter, with gaps around seating, graves and the gate. The church approach remains open. Grave modules, perimeter panels, benches and small planting details use MultiMeshes; flower heads disappear in winter. Positions and grave grids are stored in the canonical JSON in current world coordinates.

## Sources and resumable stages

- `build_assets.py`: original measured geometry, editable-source build, independent GLB export and a cheap two-angle shape review. Only asset collections are exported; each GLB was inspected for one scene and one mesh. A background Blender process is used because the live MCP endpoint was unavailable; no interactive scene was modified.
- `church_ensemble.blend`: editable meshes with packed prepared materials, saved before game-copy joins.
- `prepare_surfaces.py`: extracts the four ImageGen albedo tiles and authors subtle portable normal/roughness response. The untouched atlas and exact prompt are under `art/source_images/church_ensemble/`. Each of twelve surface maps was separately prepared with `tools/optimize_asset.py --profile surface --approved`, under the accepted material direction, before Blender integration. The two-metre UV repeat and modeled roof folds avoid oversized painted detail. Do not bypass preparation when revising them.
- `art/models/church_ensemble/textures/`: the twelve prepared surface maps that Blender reads (not part of the Godot project).
- `init/assets/models/church_ensemble/`: ten game GLBs without embedded textures and their import resources.
- `init/assets/materials/church_ensemble/`: the maps the game actually uses, once each (11 distinct images, VRAM-compressed), and four `<material_slug>.tres` files. `build_assets.py export` runs `tools/strip_glb_textures.py` on every GLB; `init/scripts/dev/church_material_import.gd` (set as `import_script/path` in each `.glb.import`) swaps the shared material back in by name. The roughness maps here are the ones Blender exported, which differ from the prepared inputs; `art/models/church_ensemble/build_shared_materials.gd` built the library from the previously extracted copies. Before: 25.7 MB of GLBs plus 63 extracted PNGs holding 15 distinct images; after: 1.0 MB of GLBs, all resolved materials identical, and 24.9 MB less texture memory at the church camera (1030.4 to 1005.5 MB, `RENDER_TEXTURE_MEM_USED`).
- `init/scripts/map/church_ensemble.gd`: composition, paths, landscaping and repeated modules; replaces the church sprite and old procedural cemetery through `district_builder.gd`. The catalog footprint and graph entrances now describe the actual model/site.

Run from the repository root with the installed Blender executable:

```powershell
& "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python art/models/church_ensemble/prepare_surfaces.py
# Separately prepare each plaster/green_metal/limestone/wood map and its _normal/_roughness maps:
uv run tools/optimize_asset.py art/source_images/church_ensemble/plaster.png --profile surface --output art/models/church_ensemble/textures/plaster.png --approved
& "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python art/models/church_ensemble/build_assets.py -- blockout
& "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python art/models/church_ensemble/build_assets.py -- build
& "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python art/models/church_ensemble/build_assets.py -- export
```

The optimizer refuses existing outputs unless `--overwrite` is supplied intentionally. On this sandboxed Windows host, uv needed a workspace-local `UV_CACHE_DIR` and the installed Blender Python; Pillow is now cached there.

## Actual Godot review and limits

Ran the normal game through `capture_map.gd` with the standard isometric view and noon lighting; inspected both neighborhood and close site captures. The updated `.local/church-ensemble/in-game-ensemble.png` shows the extended burial rows, secondary aisle, seating beside paths and planted edges. Runtime output confirms scale 1 for all buildings, 77 graves and the entrance/doorstep coordinates above. The HUD retains the paused planning clock because only the development lighting hour was overridden.

```powershell
& "C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --headless --path init --import --log-file "C:/Users/alexe/.codex/worktrees/19f5/godot-init/.local/church-ensemble/import.log"
& "C:/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe" --path init --script res://../art/models/church_ensemble/capture_map.gd --log-file "C:/Users/alexe/.codex/worktrees/19f5/godot-init/.local/church-ensemble/game.log" -- --no-log
```

No automated tests were added or run. The local sandbox reports unavailable user shader-cache/editor-settings storage and certificate-store access; graphical rendering and capture completed without game script errors. Seasonal roof/snow finishing, night appearance and a complete playable visit have not been reviewed. Gate leaves are static scenery, without operating hours or access restrictions. Surrounding private houses are now complete 3D parcels; see `../village/README.md`. The user approved the latest planting and grave-density revision in game on 2026-11-07.
