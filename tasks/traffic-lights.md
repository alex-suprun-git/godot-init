# Static 3D traffic lights

status: planned

## Scope

Follow-up to the pedestrian crossings commit; implement as a separate second commit.
Lead/integrator task, not dispatched to a worker. No model or integration exists yet.

- Use `art/concepts/traffic-light-1970s-1980s-turnaround-v1.png` as the period-inspired reference, with separately controllable red, amber and green lens materials.
- Build one reusable modest pole/head model. Preserve editable Blender source under `art/models/traffic_lights/`, export scoped GLB under `init/assets/models/` and inspect actual Godot views.
- Add static fixtures first. No traffic phase cycling, yielding or stopping logic in this task.
- Initial proposed locations: the civic axis at the river highway (map x=-5, z=-187.5), north cross street (x=-5, z=-85) and south station/market street (x=-5, z=305). These are junction centres, not pole positions. Derive poles from actual corners/approach direction; inspect pedestrian clearance and all approaches.
- Courtyard/path entrances remain unsignalized. Other asphalt junctions, including the eastern village street and narrow civic lane, are not automatically signalized simply because they have zebras.
- Add a small intersection registry during integration: stable road/intersection IDs, road references, linked pedestrian crossings and signal-group/approach bindings. Geometry remains derived from `DistrictLayout.ROADS`; avoid a second manually maintained coordinate layout. Future stop lines and signal phases can bind to these IDs.

## Current state and next action

The reference image and full generation prompt are saved. It is a modeling reference, not a dimensionally verified blueprint. The user requested the traffic-light addition as the next task/second commit. First inspect the silhouette and dimensions in Blender, then integrate fixtures and registry together and capture the three junctions in Godot. Follow `.agents/skills/blender-godot-assets/SKILL.md`.
