# Static 3D traffic lights

status: done

## Scope

Follow-up to the pedestrian crossings commit; implement as a separate second commit.
Lead/integrator task, not dispatched to a worker. Implemented in the follow-up commit.

- Use `art/concepts/traffic-light-1970s-1980s-turnaround-v1.png` as the period-inspired reference, with separately controllable red, amber and green lens materials.
- Build one reusable modest pole/head model. Preserve editable Blender source under `art/models/traffic_lights/`, export scoped GLB under `init/assets/models/` and inspect actual Godot views.
- Add static fixtures first. No traffic phase cycling, yielding or stopping logic in this task.
- Initial proposed locations: the civic axis at the river highway (map x=-5, z=-187.5), north cross street (x=-5, z=-85) and south station/market street (x=-5, z=305). These are junction centres, not pole positions. Derive poles from actual corners/approach direction; inspect pedestrian clearance and all approaches.
- Courtyard/path entrances remain unsignalized. Other asphalt junctions, including the eastern village street and narrow civic lane, are not automatically signalized simply because they have zebras.
- Add a small intersection registry during integration: stable road/intersection IDs, road references, linked pedestrian crossings and signal-group/approach bindings. Geometry remains derived from `DistrictLayout.ROADS`; avoid a second manually maintained coordinate layout. Future stop lines and signal phases can bind to these IDs.

## Report

- Updated the task base by starting from `origin/main` at `83154a2` in `/private/tmp/godot-traffic-lights` (branch `feat/traffic-lights`) and cherry-picking the first crossing commit as `2ccae8e`; unrelated active edits remain in the original checkout.
- Built one 1,416-triangle original Blender model with three independently named lens meshes. Source, generator, export metadata and reviewed front/rear previews: `art/models/traffic_lights/`.
- Exported and inspected `init/assets/models/street/traffic_light_v1.glb`; integrated 11 fixtures on the three specified junctions. Stable road, junction, approach, signal-group and zebra IDs are linked in the registry.
- Signals remain off during normal play. The public visual API and focused dev review demonstrate separate lens emission without implementing traffic phases or vehicle reactions.
- Inspected Godot placement, grounding, orientations, normal player zoom, alternate camera and day/night lens previews. Kept roadside trees clear of nearby heads. Representative screenshots: `docs/pr-assets/traffic-lights/`.
- Known pre-existing shutdown issue: four audio objects associated with `city_outskirts.ogg` remain in use; verbose output identified no traffic-light resource leaks. No automated tests were added or run.
- Further work: a future traffic-simulation task can bind controllers, lanes, stop lines and pedestrian permissions to this registry. No automatic cycling or stopping is claimed here. Asset details and exact review command: `art/models/traffic_lights/README.md`.
