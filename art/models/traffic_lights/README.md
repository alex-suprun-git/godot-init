# Traffic light v1

Original period-inspired municipal vehicle signal, based on `art/concepts/traffic-light-1970s-1980s-turnaround-v1.png`. Not a certified replica of a named historical model.

## Asset and budget

- Editable source: `traffic_light_v1.blend`; reproducible generator: `build_traffic_light.py`.
- Game export: `init/assets/models/street/traffic_light_v1.glb`.
- Metres, 3.4625 m overall height, 0.244 m lens diameter. Blender front -Y, Godot front +Z. Place the root at the supporting surface height (0.15 m on pavements, 0 m on the highway grass shoulder).
- 1,416 triangles against a 2,500-triangle budget; four mesh objects (one structure, three independent lens meshes), six simple PBR materials, no textures or external assets. Repeated instances share meshes/materials. Body has three material surfaces.
- The restrained geometry targets the existing strategy camera. Short visors retain the period silhouette while exposing the lenses from above. No screws, glass normal maps, LED arrays or decorative wear.
- Front/rear Blender previews: `previews/`; export inspected to contain one asset root, four mesh nodes and no cameras/lights/default cube.

## Rebuild

Run from this checkout:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python art/models/traffic_lights/build_traffic_light.py
/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot --headless --path init --import
```

The native Blender MCP was unavailable during this task. The installed Blender 5.2.3 LTS CLI built the model in a separate process; it did not change an open user scene. The generator creates an isolated asset scene, saves its editable checkpoint, exports only selected asset objects from that active scene, then renders inexpensive Workbench silhouette previews. No baking is required for these solid materials.

## Godot integration

- `traffic_intersections.gd` explicitly registers `axis_highway`, `axis_north` and `axis_station`. Positions come from named road geometry. Their incoming approaches have 4, 4 and 3 fixtures respectively; the station is a T-junction.
- Each fixture binds a stable intersection ID, incoming road/approach, nearest zebra ID, travel direction and future signal group. Other intersections and courtyard entrances remain unsignalized.
- `traffic_light.gd` instantiates the GLB and exposes `set_signal("off" | "red" | "red_amber" | "amber" | "green")`. Shared cached materials provide independent emission without per-fixture point lights. A future controller can use this API; it is not a traffic simulation.
- Normal play starts every signal off. Only the dev review demonstrates green and red/amber, restoring off afterwards. Cars and pedestrians currently ignore signals.
- Roadside tree placement leaves 8 m around fixture bases clear of new trees so nearby crowns do not cover the heads. Mast positions stay toward the outside of the pavements, away from the pedestrian centre lines.

## Visual verification

```sh
mkdir -p /tmp/traffic-light-shots
/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot --path init -- --autoplay --traffic-lights-only --shots=/tmp/traffic-light-shots --no-log
```

Inspected actual game frames at all three junctions, normal closest player zoom, enlarged lens views, the alternative camera and nighttime. Green and red/amber emission were inspected in the dev preview. At the normal strategy zoom these are small street fixtures; lens-state close-ups deliberately use a closer developer camera. Representative JPEGs are under `docs/pr-assets/traffic-lights/`.

Shutdown reports four leaked objects associated with the existing `city_outskirts.ogg` ambience stream, as identified in a verbose run; no traffic-light resources appeared in that report. This audio shutdown issue was left outside the asset task. Automated tests were not added or run.
