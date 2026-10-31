# Lada Sedan V2

An original procedural 3D interpretation of `init/assets/sprites/car_lada_v3.png`, created in Blender 5.2.3 through the local MCP connection. Integrated into the existing Lada placements on streets, at the polyclinic and in the House 5 courtyard. Visual direction remains open to review.

- Editable source and studio: `lada_sedan_v2.blend`, scene `Lada_Studio_V2`.
- Game asset: `init/assets/models/vehicles/lada_sedan_v2.glb`.
- Baked paint: `init/assets/models/vehicles/lada_paint_v2.png`.
- Preview: `previews/lada_front_v2.png`.
- Geometry: 21,261 triangles in five meshes: body and four wheels. The Blender source retains the detailed geometry.
- Scale: metres; front is Blender -Y and Godot +Z. The tires rest at height zero.
- Materials: ivory paint with subtle lower-body wear, blue-grey opaque glass, rubber, steel, chrome and lamp lenses. The car has no interior, collision shape or driving logic yet.

## View in Godot

Run the game normally to see the parked cars on the city map. `scripts/map/vehicle_models.gd` shares the imported scene and scales the 4.37 m source to a 4.3 m map length. The map passes each surface's actual height and rotates +Z forward onto the road axis.

For an isolated view, open `res://scenes/dev/lada_3d_demo.tscn` and run the current scene (Cmd+R on macOS). Drag with the left mouse button to orbit; scroll to zoom. The earlier primitive model remains in `lada_3d_model.tscn` for comparison.

For focused in-game screenshots, use `-- --autoplay --vehicles-only --shots=/absolute/output/dir --no-log`. Add `--keep-open` to return to the courtyard in the playable planning phase after the captures.

## Rebuild

Run `build_lada.py` in Blender, then `finish_lada.py`. The first script recreates only the generated studio scene; the second unwraps and bakes the paint, calls `export_lada.py`, saves the blend file and queues a render. Existing unrelated scenes are preserved. Run `export_lada.py` alone after geometry edits that do not require repainting.

Use the persistent client in `tools/blender_mcp.py` when native MCP tools are unavailable. For example: `uv run --python 3.11 --script tools/blender_mcp.py status`. The project skill at `.agents/skills/blender-godot-assets/SKILL.md` describes short calls, queued jobs and visual inspection.

When executing a script through MCP, supply its real filename as `__file__`, for example:

```python
from pathlib import Path
p = Path('/absolute/project/path/art/models/lada/build_lada.py')
exec(compile(p.read_text(), str(p), 'exec'), {'__name__': '__main__', '__file__': str(p)})
```

The first Cycles Metal bake can spend several minutes compiling shaders. An MCP timeout does not cancel Blender's operation; check the output files before retrying. `finish_lada.py` writes `render_status.json` while producing the studio preview.

## Wagon variant (2026-10-31)

A station-wagon body derived from the V2 sedan by copying its scripts: `build_lada_wagon.py` (longer roof, vertical tailgate glass, roof rails, one-piece rear side window), `finish_lada_wagon.py` (paint bake + export) and `export_lada_wagon.py`. Source: `lada_wagon.blend` (scene `Lada_Studio_Wagon`); game asset `init/assets/models/vehicles/lada_wagon.glb` (21.5k triangles, paint atlas `lada_wagon_paint.png`); report `asset_report_wagon.json`. Run build, then finish, exactly like the sedan. Used for roughly one in three background and parked cars via `VehicleModels.traffic_model`. Verified in Blender previews (side and rear) only; not yet inspected in a Godot frame next to the sedan.
