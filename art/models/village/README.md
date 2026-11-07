# Village overhaul

The user approved the compact neighborhood structure on 2026-11-07, then requested tighter existing street frontages, dense planting in the remaining gaps, matte readable materials and an extra exit to the two-lane street parallel to the railway. The user approved the latest appearance on 2026-11-07.

## Place and scale

Residents use these ordinary family homesteads throughout the day; gardens, garage access, washing and small household storage explain the yards. In1997, newer brick houses coexist with owner-altered plastered houses and rare surviving timber cottages. Two parcels are vacant. Verandas, garages and modest sheds are the informal additions; this is a lived-in neighborhood rather than a ruined village.

There are29 complete parcel prefabs from seven recipes, fitted before placement. Main houses remain9–11m wide and7–10m deep; roofs, windows,3.4m vehicle gates and1m wickets retain their physical dimensions. Typical current sites are about4–6sotki. The village ground area was reduced10% using sqrt(0.9) in each axis, anchored at the western edge. The subsequent frontage packing closes the excessive gaps between existing houses without scaling buildings. Main streets remain, and a new5m gravel exit joins the southern two-lane street at(278,305).

The source of actual parcels and roads is `init/scripts/data/district_layout.gd`. `families.json` defines architectural recipes. `build_sites.py` reads actual rectangles and builds every full enclosure, house, garage, paths, garden and shed. Seasonal tree/shrub/flower markers become shared Godot vegetation. Current positions, access and estimated building/circulation/garden budgets are generated into `init/scripts/data/village_sites.json`. `village_sites.blend` preserves editable components; `export_report.json` records geometry and fitted sizes. `layout_before_compaction.json` and `compact_layout.py` preserve the earlier area-reduction stage; the script deliberately retains the later packed layout rather than resetting it.

New homes occupy previously empty frontage at the north lane and the existing western/eastern village lanes. The pond shore remains public, with paths, seating, a picnic table, lamps, grouped planting and a reused station kiosk about3×2.5m. Remaining gaps are planted with clustered seasonal trees and shrubs, excluding roads, plots, water and paths. The old orchard remains behind the southern homestead. No new shop requests, gate schedules or household simulation were added.

## Materials and rebuild

Untouched nine-surface atlas, exact prompt and extracted sources: `art/source_images/village/`. `prepare_surfaces.py` authors the technical maps; all27 maps passed the standalone optimizer before use. Shared textures/materials live under `init/assets/materials/village/`. Model exports strip embedded textures using `tools/strip_glb_textures.py`; `init/scripts/dev/village_material_import.gd` restores shared materials by name. `build_shared_materials.gd` is the bootstrap utility reused from origin/main; it is not needed for routine geometry rebuilds.

`tune_materials.gd` reproducibly calibrates10 textured and11 flat materials. `village_surface.gdshader` gives plaster, masonry, metal, timber and concrete individual matte responses, limited fine normals and upward-facing winter snow. Roof folds remain geometry. The gravel shader uses subdued aggregate, compacted tracks, irregular edges and junction masks; shared world coordinates keep intersections consistent. Grass is de-tiled, with small dry variations and the existing wear mask at gates. Scene exposure and daylight are unchanged.

From the repository root:

```powershell
& "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python art/models/village/build_sites.py -- build
& "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" --background --factory-startup --python art/models/village/build_sites.py -- export
# Import new geometry with Godot --headless --path init --import, then calibrate materials:
# Godot --headless --path init --script res://../art/models/village/tune_materials.gd
# Graphical review: Godot --path init --script res://../art/models/village/capture_map.gd -- --materials --no-log
```

Actual imported bounds were compared with the church, Volga and PAZ; large-building dimensions were checked against the catalog and fetched origin/main. Standard-camera summer captures at08:00 and12:00 verified the material pass. Inspection confirmed29 scale1 prefabs, no legacy residential sprites and no prefab geometry outside its parcel. Latest packed-frontage/exit capture: `.local/village-rebuild/in-game-village.png`. Captures and logs remain ignored. Winter and night appearance still need visual review; private properties are scenery, not active quest destinations. No automated tests were added or run.
