---
id: map-edges-traffic
status: review   # ready | in-progress | review | blocked | done
worker: lead-integrator
branch: lead/map-edges-traffic
---

# Conceal the map edges and recycle ambient traffic

## Goal

Roads should appear to continue beyond the playable district: cars drive into haze at the outer road ends and at the near-bank head of the border bridge, then other cars arrive from outside. Implement the user's simple rule: one car exits, one slot waits, one car re-enters (`-1 -> pause -> +1`). Keep the existing district/subzone traffic rules. This is background scenery, with no simulation of vehicles outside the map.

## Decisions (user review, 2026-11-01)

- **The bridge stays closed for now.** Haze sits in front of the road bridge on the near bank and veils the deck and the far bank. Cars hand off into that haze; they do not cross the bridge. The bridge is "opened" (deck traversal, ramp heights, far-bank continuation) in a separate task once part of the far-bank city exists. This keeps the far-bank direction open without building scenery for it now.
- **Haze first.** The riskiest part is whether a world-anchored haze can hide road ends under the orthographic camera at the widest zoom without a dark ring or a wall of smoke. The haze is one full-screen pass that covers every edge at once; review its frames before building the traffic lifecycle.
- **Highway east becomes a gateway.** A third tunnel under the railway embankment at the highway (z -187.5) lets the highway run through to the east haze edge, like the two streets do.
- **Lean verification.** Check a short, representative set of frames (below), not the full season x time x window-shape matrix.

## Ownership and execution

This is queued **lead/integrator work**, recorded using the task template. It changes shared map and traffic scripts, which `tasks/README.md` reserves for the lead. Do not dispatch it with `tools/dispatch_task.sh`: that command starts a worker and does not grant permission to edit shared files. If asset preparation is later delegated, create a separate worker brief with its own permitted outputs and integration requests.

`ready` means the brief is prepared; no implementation or visual review has happened. Do not commit, push, or start a worker merely because this brief exists. Before implementation, re-read the working tree: the planning snapshot below includes changes that were uncommitted when this brief was written.

## Inputs

1. `AGENTS.md`, `tasks/README.md`, `README.md`: City Map, Far-Bank City and Visual Comparison, Starting District Layout.
2. `init/scripts/map/ambient_life.gd`: agent pool, `step()`, `_next_edge()`, `_place()`, `_vehicle_class()`, `_update_visibility()`.
3. `init/scripts/map/road_graph.gd`: graph derived from road rectangles; asphalt edges and the `bridge_road` entrance.
4. `init/scripts/data/district_layout.gd`: `ROADS`, `BRIDGES`, `WATER`, `FOREIGN_BANK`, `profile_at()`, `crowd_at()`, `HOURS`, `DISTRICT_DEFAULTS`.
5. `init/scripts/map/city_map.gd`: camera bounds, both camera modes, atmosphere/daylight, `_build_ambient()`, `_move_ambient()`.
6. `init/scripts/map/district_builder.gd`: ground, roads, bridge geometry and occupied areas; `init/scripts/map/vehicle_models.gd`: model/paint selection and shared materials.
7. `init/scripts/dev/autoplay.gd`: existing visual verification workflow.

## Planning snapshot (inspected 2026-10-31)

- There are 130 ambient car slots and 240 pedestrian slots. `AmbientLife` moves them; `CityMap` owns their visuals. Initialization already weights roads by district density and length, and selects a vehicle class from the local fleet.
- At an asphalt dead end, `_next_edge()` currently returns the same edge, producing a U-turn. There is no exit, delay, or respawn state.
- District density/hour and fleet restrictions set a separate `visible` flag, refreshed in batches. A hidden agent still moves. Consequently, a visibility change is **not** a map exit and must never create a replacement.
- The shared graph derives its road centerlines from `ROADS`. `BRIDGES` is built as geometry; `bridge_road` marks the near-bank entrance, not a traversable asphalt span. Ambient cars do not cross the road bridge, and under this brief they still do not.
- Ambient car rendering writes a fixed world height of `0.14`. That is fine while cars stay off the bridge; fixing it belongs to the later bridge-opening task.
- Ambient movement uses frame `delta` from `CityMap._process()`, independently of week speed/pause. Its recycling delay should use the same clock, preserving the current scenery behavior.
- Existing atmosphere uses global depth fog. Camera target bounds are clamped, but the full viewport can still see beyond them, especially at the widest zoom. Terrain already extends well beyond the authored district.

## Intended behavior and scope

- Each real boundary departure creates exactly one waiting slot, later reused for exactly one arrival. A different model/paint is allowed. There is no persistent identity or off-map itinerary.
- Use a different eligible gateway when one is available, so an exit does not become an immediate return on the opposite lane. If only one gateway is valid, allow it after the delay.
- Keep `DISTRICTS`, subzone overrides, fleet weights, hourly profiles, initial population and existing local wandering. Do not create a second district or traffic-density system.
- Preserve ordinary internal dead ends, pedestrians, parked vehicles, the administration Volga and contact/player travel. Trains and boats are outside the recycling scope; rail/river ends still need visually coherent edge concealment.
- Soft, world-anchored haze: river mist in front of the road bridge and over the far bank, an atmospheric fade around outer approaches, and short road/landscape continuations under it. Exact color, width and density are tuning proposals for user review. No new generated raster art is required.

## Execution

The plan below is written so a faster model (Sonnet) can implement it phase by phase without design work. Run it **in this checkout** (`init/scripts/data/district_layout.gd`, `vehicle_models.gd` and `README.md` have uncommitted edits that a worktree would not see), with no other session writing map files at the same time. Each phase lists files touched, what "done" means and how to verify. Phase A ends with a hard stop for user review.

Facts checked in the source on 2026-11-01:

- Renderer: Forward+ (`project.godot`), Godot 4.7, so depth is **reverse-Z**.
- Road ends: `highway` x -450..425 at z -187.5; the north street x -450..440 at z -85; the south street x -450..440 at z 305; `axis` north end at (-5, -330), which is also the `bridge_road` entrance node (no access edge there).
- `highway` ends at x 425 **inside the railway embankment** footprint (x 400..430, z -280..375); embankment tunnels exist only at z -85 and 305, all with one shared `gap` of 13 m (too narrow for the 20 m highway). The embankment is at full height at z -187.5. Phase B adds the third tunnel.
- The western forest canopy (`nature_places.gd`, `_forest()`) spans about x -612..-454, z -48..300, i.e. **west of the road ends**. The `forest_clearing` lot is at x -537..-509. A haze edge at x -450 would cover the forest, so the west haze edge sits west of the forest and the three western roads and both southern rail tracks get continuations past it.
- Camera: `BOUNDS` = Rect2(-620, -460, 1070, 880); widest zoom `ZOOM_MAX` = 350 / 0.30 ≈ 1167, orthographic `camera.size` = zoom × 0.573 ≈ 670 m visible height (≈ 1190 m width at 16:9). Ground slabs extend to ±1300; beyond that is sky.
- Other readers of ambient agents: `city_map.gd` (`_build_ambient`, `_move_ambient`) and `scripts/dev/autoplay.gd` (lines ~180, ~205, ~299 read `agent["edge"]`, `agent["visual"]`).

## Implementation plan

### Phase A: haze, continuations and edge frames (then STOP)

**Files:** new `init/scripts/data/map_boundaries.gd`, new `init/assets/shaders/map_edge_haze.gdshader`, new `init/scripts/map/map_edges.gd`, `init/scripts/map/city_map.gd`, `init/scripts/map/district_builder.gd`, `init/scripts/dev/autoplay.gd`.

1. **`map_boundaries.gd`** (`extends RefCounted`, constants only plus static helpers), authored data:
   ```gdscript
   # Everything inside stays clear; haze rises outside it. West edge is past the forest.
   const INNER := Rect2(-615, -330, 1055, 745)   # x -615..440, z -330 (our bank)..415
   # Fade widths in metres per side: west, north (river mist), east, south.
   const FADE := {"w": 90.0, "n": 35.0, "e": 90.0, "s": 90.0}
   const NOISE_AMP := 18.0      # metres the noisy edge moves in and out
   const NOISE_SCALE := 0.012   # 1 / metres
   const CAR_LENGTH := 10.0
   # Road and rail continuations drawn under the haze (and past the forest in the west).
   static func handoff_distance(side: String) -> float:
       return FADE[side] + NOISE_AMP + CAR_LENGTH
   ```
   Add `static func validate() -> PackedStringArray` that warns if any `LOTS` rect or `ROADS` rect is not inside `INNER` (excluding nothing), and call it once from `map_edges.gd` with `push_warning` per entry.
   Road continuations (data, computed in a static func from `ROADS`/`RAILS`, not hard-coded twice): for the three roads whose rect starts at x -450, a rect from `INNER.position.x - handoff_distance("w") - 20` to x -450 with the road's own z and width; for the two southern rail lines, a segment from the same far x to (-450, z). East and bridge need no continuation (the haze edge sits at the road end / bank).

2. **`map_edge_haze.gdshader`**: one full-screen quad that reconstructs world position from depth and fades by distance outside `INNER`.
   ```glsl
   shader_type spatial;
   render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;
   uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;
   uniform vec4 inner;            // x0, z0, x1, z1
   uniform vec4 fade;             // west, north, east, south (metres)
   uniform float noise_amp;
   uniform float noise_scale;
   uniform vec4 haze_color : source_color;
   uniform bool debug_stripes = false;
   void vertex() { POSITION = vec4(VERTEX.xy, 1.0, 1.0); }
   void fragment() {
       float depth = texture(depth_texture, SCREEN_UV).x;
       vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
       view.xyz /= view.w;
       vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz, 1.0)).xyz;
       // ... see below
   }
   ```
   In `fragment()`: `n = (value_noise(world.xz * noise_scale) - 0.5) * 2.0 * noise_amp` (write a small hash-based 2D value noise, two octaves). Per side `t = (distance outside that side + n) / fade_side` (e.g. west: `(inner.x - world.x + n) / fade.x`), `a = smoothstep(0.0, 1.0, clamp(max(max(tw, tn), max(te, ts)), 0.0, 1.0))`. Sky pixels (depth ≈ 0) land far away and get `a = 1`; that is intended. Output `ALBEDO = haze_color.rgb; ALPHA = a * haze_color.a;`. With `debug_stripes` output `ALBEDO = vec3(fract(world.x / 50.0), fract(world.z / 50.0), 0.0); ALPHA = 0.6;` instead.

3. **`map_edges.gd`** (`extends Node3D`): builds a `MeshInstance3D` with a `QuadMesh` of size (2, 2), the shader material, `extra_cull_margin = 16384.0`, `cast_shadow = OFF`, material `render_priority = 100`. Sets `inner`, `fade`, `noise_*` from `MapBoundaries`. Exposes `set_haze_color(color: Color)` and `debug_stripes` (from `--haze-stripes` command-line arg).

4. **`city_map.gd`**:
   - In `setup()`, after `builder.build(self)`, add the `MapEdges` node.
   - In `_update_daylight()` (and wherever `_apply_night` changes light), call `set_haze_color`: start from `_environment.fog_light_color`, darkened by the same night factor that dims the sun/ambient (full night ≈ 0.2 of day brightness, alpha 1). The quad is unshaded, so without this it glows at night.
   - Dev args next to `--hour=` / `--season=`: `--cam=x,z,zoom` sets `_camera_target`, `_camera_goal` and `_zoom` once at setup (zoom in camera distance units, clamped like `zoom_by`); `--camera-mode=iso|front` sets `Settings.camera_mode`.

5. **`district_builder.gd`**: in `_build_ground()`, after the `ROADS` loop, draw each road continuation with the same `_patch(rect, "asphalt", 0.139 / 0.14, tint)` and `map._occupy(...)` the road uses; after the `RAILS` loop, draw each rail continuation with `_rail_segment`. Occupancy is registered before `nature_places.gd` plants the forest, so trees stay off the new strips. No road markings needed.

6. **`autoplay.gd`**: add an `--edges-only` mode beside `--vehicles-only`. It skips the week and takes `_map_shot` frames, in both camera modes (switch `Settings.camera_mode`, restore afterwards):
   - `edge_wide_<mode>_center` at `BOUNDS` centre, zoom `ZOOM_MAX`;
   - `edge_wide_<mode>_<nw|ne|sw|se>` at the four `BOUNDS` corners, zoom `ZOOM_MAX`;
   - `edge_west_road` at (-560, -187.5), zoom 300; `edge_east_road` at (440, -85), zoom 250; `edge_bridge` at (-5, -320), zoom 250; `edge_forest` at (-520, 120), zoom 390.

**Verify with** (stripe check first, then real frames; read every PNG):
```sh
G=/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot
$G --headless --path init --import
$G --path init -- --edges-only --haze-stripes --shots=/private/tmp/map-edges-traffic-shots/stripes --no-log
$G --path init -- --edges-only --shots=/private/tmp/map-edges-traffic-shots/summer --no-log
$G --path init -- --edges-only --season=winter --hour=22 --shots=/private/tmp/map-edges-traffic-shots/winter_night --no-log
$G --path init -- --autoplay --shots=/private/tmp/map-edges-traffic-shots/autoplay --no-log
```
Stripes must stay glued to the ground (same stripe under the same building in every frame, both modes). If they slide or curve, the depth reconstruction is wrong: fix it before tuning anything.

**Done when:** stripes are stable; no road, rail or ground end and no hard line is visible in any wide frame; the forest, pond, customs and station tracks are clear; night haze is dark, not glowing; autoplay finishes with no new errors.

**STOP: report the frame paths and a short description to the user and wait. Do not start Phase B.** Tuning `FADE`, `NOISE_*` and colour after feedback is part of Phase A.

### Phase B: gateways and vehicle height

**Files:** `map_boundaries.gd`, `district_layout.gd` (ids, the highway's east end and the third tunnel, per-road speed), `road_graph.gd` (road speed on edges, only if needed), `district_builder.gd` (per-tunnel gap), `ambient_life.gd`, `city_map.gd`.

0. **Third tunnel.** In `district_layout.gd`:
   - `highway` rect becomes `Rect2(-450, -197.5, 890, 20)` (east end 425 → 440, matching the two streets);
   - `EMBANKMENT["tunnels"]` becomes `[-187.5, -85.0, 305.0]` and gets `"gaps": {-187.5: 28.0}` (others keep the shared `gap` of 13).
   In `district_builder.gd` `_build_embankment()`, read the gap per tunnel: `var g: float = e.get("gaps", {}).get(z, gap)` inside the `for z in e["tunnels"]` loop. Nothing else reads `tunnels`. Check with an autoplay frame at (420, -187.5), zoom 120, in both camera modes: the highway passes under a concrete deck, no earth over the road, no rail gap.
1. In `district_layout.gd` add `"id": "north_street"` and `"id": "south_street"` to the two untagged E-W roads (`Rect2(-450, -90, 890, 10)` and `Rect2(-450, 300, 890, 10)`). Nothing else changes.
2. In `map_boundaries.gd`:
   ```gdscript
   # end: which end of the road's centerline ("lo" = west/north, "hi" = east/south).
   const GATEWAYS := [
       {"id": "highway_w", "road": "highway", "end": "lo", "side": "w"},
       {"id": "highway_e", "road": "highway", "end": "hi", "side": "e"},
       {"id": "north_street_w", "road": "north_street", "end": "lo", "side": "w"},
       {"id": "north_street_e", "road": "north_street", "end": "hi", "side": "e"},
       {"id": "south_street_w", "road": "south_street", "end": "lo", "side": "w"},
       {"id": "south_street_e", "road": "south_street", "end": "hi", "side": "e"},
       {"id": "border_bridge", "road": "axis", "end": "lo", "side": "n"},
   ]
   ```
   `static func resolve(graph) -> Array[Dictionary]`: for each gateway compute the centerline end point from the road rect (horizontal: `(rect.position.x or rect.end.x, center.y)`; vertical: `(center.x, rect.position.y or rect.end.y)`), find the graph node within 0.5 m by scanning `graph.points`, and check that exactly one adjacent edge has kind `"asphalt"`. On failure `push_warning("map gateway <id>: ...")` and skip it. Each resolved entry: `{id, node, edge, point, out: Vector2 (unit, pointing off-map), leg_length, sample: point - out * 30.0}`. `leg_length` = distance from `point` to the haze edge on that side (for the west roads, 165 m to x -615; zero elsewhere) + `handoff_distance(side)`. `road_graph.gd` is not changed.
3. In `city_map.gd` `_move_ambient()`: car height becomes `_ground(at).y + 0.14` instead of the literal `0.14` (the bridge leg climbs the ramp).
4. With `--traffic-debug`, print the resolved inventory once at startup.

5. **Parking rules** (user request, 2026-11-01). Parked cars come from `CityMap._build_traffic()` (one every 100 m at the kerb of every asphalt road). Change it so that:
   - roads with `"look": "highway"` get **no** parked cars at all;
   - no parked car sits within `PARKING_CLEARANCE` (start at 25 m, constant in `map_boundaries.gd` or `district_layout.gd`) of a junction: skip a slot if its centre is within that distance of the centre of any crossing road rect (reuse the junction test from `DistrictLayout.crosswalks()`, `rect.intersects(junction.grow(0.1))`), measured along the road;
   - the same slot grid is kept otherwise, so existing frames stay comparable. Check with a frame at a junction (e.g. the axis x highway crossing and the north street x axis).
6. **Road speeds.** Ambient cars currently get one speed for life (`randf_range(7.0, 12.0)` m/s in `_build_ambient`). Add a per-road speed class: `DistrictLayout` road dicts get an optional `"speed"` multiplier (default 1.0; highway about 2.0, i.e. roughly 14-24 m/s against 7-12 in town; tune after looking). `AmbientLife.step()` multiplies `agent["speed"]` by the current edge's factor (needs the road id or look on each graph edge from `road_graph.gd`; if the edge dict lacks it, add it there, which lifts the "do not touch" rule for this one field). Ease the factor over about 1.5 s when changing roads, so cars do not jump in speed at the junction. Gateways on the highway then also hand off faster, so `leg_length` timing in Phase C uses the highway factor on the outward/inward legs.

**Done when:** the tunnel frame looks right; seven gateways resolve with no warnings; no parked car on the highway or within the clearance of a junction; highway cars are visibly faster than town cars; otherwise autoplay unchanged.

### Phase C: slot lifecycle

**Files:** `ambient_life.gd`, `city_map.gd`, `autoplay.gd` (guards only).

Agent fields (cars only; walkers keep `state = "graph"` forever):
`state` ∈ `"graph" | "out" | "wait" | "in"`, `gateway` (index into resolved gateways), `leg_from: Vector2`, `leg_dir: Vector2`, `leg_len: float`, `wait: float`, `respawned: bool`.

1. `AmbientLife._init` gets the resolved gateways (`MapBoundaries.resolve(graph)`), keeps `_gateway_at_node: Dictionary` (node → gateway index), and `stats := {"exits": {}, "arrivals": {}}`.
2. `step(delta)`: per agent, branch on `state` **before** touching `graph.edges`:
   - `"wait"`: `wait -= delta`; when ≤ 0, call `_enter(agent)`; continue.
   - `"out"` / `"in"`: `along += speed * delta`; if `along >= leg_len`: `"out"` → `_park(agent)`; `"in"` → join the graph (`edge = gateway.edge`, `from = gateway.node`, `along -= leg_len`, `state = "graph"`); then `_place_leg` or `_place`.
   - `"graph"`: the existing loop, but when the reached `node` is in `_gateway_at_node` and the agent is a car, start the outward leg: `state = "out"`, `leg_from = gateway.point`, `leg_dir = gateway.out`, `leg_len = gateway.leg_length`, `along = leftover`, then `break` out of the while loop (do not call `_next_edge`).
3. `_place_leg(agent, delta)`: `pos = leg_from + leg_dir * along + right(leg_dir) * lateral`, where `right(h) = Vector2(-h.y, h.x)` and lateral eases to the same car target as `_place` (`clampf(half * 0.35, 1.5, 4.0)` with the gateway edge's `half`); `heading = leg_dir`. For `"in"`, `leg_from` is the far end and `leg_dir = -gateway.out`, so the car arrives in its right-hand lane and the join is continuous.
4. `_park(agent)`: `state = "wait"`, `visible = false`, `wait = _rng.randf_range(2.0, 5.0)`, `stats.exits[id] += 1`.
5. `_enter(agent)`: weights per gateway = `DistrictLayout.crowd_at(gateway.sample, int(hour), true)`; drop the exit gateway if another has weight > 0. If total is 0, `wait = 1.0` and return (retry later without a new random delay). Otherwise pick weighted, set `class = _fleet_class(gateway.sample)`, `state = "in"`, `leg_from = gateway.point + gateway.out * gateway.leg_length`, `leg_dir = -gateway.out`, `leg_len = gateway.leg_length`, `along = 0`, `lateral = target`, `respawned = true`, `stats.arrivals[id] += 1`, then `_update_visibility(agent)` immediately.
6. Refactor `_vehicle_class(edge)` into `_fleet_class(point: Vector2)`; `add()` calls it with the edge midpoint (same result as today).
7. `_update_visibility`: return early with `visible = false` when `state == "wait"`.
8. `city_map.gd`: keep a member `_traffic_look := RandomNumberGenerator.new()` seeded in `_build_ambient` (the current `look` RNG is local). In `_move_ambient`, when `agent["respawned"]`: free the old car node, create a new one with `VehicleModels.model_for_class(agent["class"], _traffic_look.randi())` via `_vehicle(...)`, set `rotation.y = atan2(heading.x, heading.y)` directly (no lerp), clear the flag.
9. `autoplay.gd`: wherever it reads `agent["edge"]` or `agent["visual"]` for cars, skip agents whose `state != "graph"`.
10. With `--traffic-debug`, every 10 s of ambient time print: exits and arrivals per gateway, count of `graph/out/wait/in`, and assert `graph + out + wait + in == AMBIENT_CARS` (print `TRAFFIC INVARIANT BROKEN` if not).

**Verify with:**
```sh
$G --path init -- --cam=-560,-187.5,300 --traffic-debug --no-log   # watch a west gateway live
$G --path init -- --autoplay --traffic-debug --shots=/private/tmp/map-edges-traffic-shots/traffic --no-log
$G --path init -- --autoplay --hour=22 --traffic-debug --shots=/private/tmp/map-edges-traffic-shots/traffic_night --no-log
```
**Done when:** console shows exits and arrivals at ≥ 2 gateways repeatedly, the invariant holds every print, no car is seen on the bridge deck beyond the mist, and no new script errors.

### Phase D: report

Fill in Report below (resolved gateway inventory, counter excerpts, frame paths, remaining defects), and update the README line on traffic/edges to say what is implemented versus still proposed. Ask the user to review the final frames.

## Constraints

- Preserve current district layout (except the highway tunnel above), vehicle palette and model selection; no traffic AI, collisions, overtaking, new transport models, persistent vehicle identities or gameplay border control.
- No bridge traversal, ramp heights or far-bank road in this task.
- Do not fix unrelated zone-boundary visibility popping; distinguish it from lifecycle visibility, which must work correctly.
- Reuse current resources and procedural rendering. If generated raster art becomes necessary, use a separate asset brief and `art/ASSET_PIPELINE.md`.
- Obtain user review of actual Godot frames; do not report the appearance as approved before review.
- Shared files are lead-owned. Preserve unrelated work in the checkout; no automated tests, commits or pushes unless requested.

## Outputs

These are **lead/integrator** outputs, not a worker allowlist:

- `init/scripts/data/map_boundaries.gd` and its `.uid`.
- `init/scripts/map/map_edges.gd` and its `.uid`.
- `init/assets/shaders/map_edge_haze.gdshader` and its `.uid`, if the prototype needs a shader.
- `init/scripts/map/ambient_life.gd` (approaches, waiting slots, entry selection).
- `init/scripts/map/city_map.gd` (edge setup, haze colour, vehicle height, lifecycle-aware visuals, `--cam` / `--camera-mode` / `--traffic-debug` dev args).
- `init/scripts/map/district_builder.gd` (road and rail continuations and their occupancy; per-tunnel gap).
- `init/scripts/data/district_layout.gd` (stable IDs for the two E-W streets, the highway's east end at x 440, the third embankment tunnel).
- `init/scripts/dev/autoplay.gd` (`--edges-only` frames and guards for non-graph agents).
- `README.md` (update planned/implemented state after integration).
- Report and Review notes in this brief; evidence under `/private/tmp/map-edges-traffic-shots/`.

## Acceptance criteria

- [ ] Phase A haze frames reviewed by the user before Phase B starts.
- [ ] The highway passes under the embankment through the third tunnel; all seven gateways resolve to asphalt terminal nodes; internal ends keep their old behavior. Report the resolved inventory.
- [ ] Cars at the bridge drive into the mist at the near-bank head; none appear on the deck, in the water, or turn back visibly.
- [ ] At an exit exactly one slot becomes waiting; after the delay exactly one slot re-enters, preferably at a different gateway. Console counters show repeated recycling across at least two gateways, `active + waiting = N` throughout, and no arrivals caused by district visibility toggles.
- [ ] Entry class/model follows the entry road's profile/defaults; fleet restrictions and hourly density still apply after re-entry (one day and one night observation).
- [ ] Frames from `--edges-only` (summer day and winter night): widest zoom in both camera modes at the centre and four corners, the west and east road ends, the bridge and the forest. Handoffs and road/rail ends are hidden; customs, inhabited lots, the pond and the western forest stay readable and reachable.
- [ ] Existing autoplay completes without new script errors; screenshots are read. No automated tests were added or run.
- [ ] README distinguishes implemented/approved results from remaining proposals. All edits stay within lead Outputs.

## Stop and ask

Ask the user if concealment would require removing playable content, materially reducing camera access, or hiding customs. Resolve routine rendering, data and delay tuning independently.

If a parallel worker is accidentally given this brief, do not edit shared scripts or scenes. Record the ownership conflict in Report and return it to the lead.

## Follow-up (separate task, not part of this brief)

Open the road bridge when part of the far-bank city exists: traversable deck, ramp heights for ambient cars (replace the fixed `0.14`), a far-bank road continuation, and move the `border_bridge` handoff beyond the far end.

## Report

- **Status summary (Phase A, 2026-11-01):** Phase A implemented and rendered; stopped for user review. Phase B/C not started. The later review note below records user approval; Phase B is ready to start.
- **Files created or changed:** new `init/scripts/data/map_boundaries.gd`, `init/assets/shaders/map_edge_haze.gdshader`, `init/scripts/map/map_edges.gd`; edited `city_map.gd` (MapEdges node, haze colour from `look["fog_color"]` darkened by `0.55 * night`, `--cam=x,z,zoom`, `--camera-mode=iso|front`), `district_builder.gd` (road/rail continuations with occupancy), `autoplay.gd` (`--edges-only`). Godot generated `.uid` files for the new scripts/shader.
- **Deviations from the plan:** (1) The verify commands need `--autoplay` as well (`main.gd` only attaches the autoplay node with it): `--autoplay --edges-only ...`. (2) The east road ends at x 440 were visibly cut off at the haze start (alpha ~0 there), so I also added **east continuations** for the two streets ending at x 440 (to x ~598); the highway still ends at x 425 inside the embankment (Phase B). (3) Haze noise uses two octaves (0.65/0.35).
- **Measurements / previews:** Stripe check passed: the world-grid stripes stay glued to the ground in both iso and front modes (reverse-Z depth reconstruction correct, no tuning needed); tall objects show stripes smeared up their faces, which is expected for a world-XZ pattern. Frames in `/private/tmp/map-edges-traffic-shots/`: `stripes/` (14), `summer/` (14), `winter_night/` (14), `autoplay/` (33, finished with exit 0, no new errors/warnings; only the usual exit-time leak notice). Each of summer / winter_night holds `edge_wide_{iso,front}_{center,nw,ne,sw,se}`, `edge_west_road`, `edge_east_road`, `edge_bridge`, `edge_forest`. Current values: `INNER = Rect2(-615,-330,1055,745)`, `FADE = {w 90, n 35, e 90, s 90}`, `NOISE_AMP 18`, `NOISE_SCALE 0.012`. Haze colour is the daylight fog colour (summer day ~ light grey, matches the sky); at night it is dark and does not glow.
- **What the frames show:** Wide frames: the district reads as a clear island fading into pale haze, no ground slab edge or road end visible; west roads and the two southern rails run into the haze past the forest; forest, pond, customs and station tracks stay clear; the bridge deck and far bank dissolve into river mist (the mist begins right at the near bank, so the deck is only visible for a few metres). Night: dark haze merging with the sky.
- **Remaining defects / judgement calls for the user:** (a) At the widest iso zoom the clear area is a diamond floating in a pale void; this is the intended trade-off but is the main look to approve (a narrower/softer fade or a tinted lower haze are tuning options). (b) The east embankment/rail lines north of the river still show faintly through the north mist. (c) The bridge deck is hidden within ~35 m of the bank; a longer north FADE would veil more but starts eating the customs yard. (d) Zone-boundary pop of ambient agents is untouched.
- **Phase B (2026-11-01, user approved the haze and asked to proceed):** implemented steps 0-6. `district_layout.gd`: highway rect now x -450..440, ids `north_street` / `south_street`, third embankment tunnel at z -187.5 with `"gaps": {-187.5: 28.0}`, highway road dict has `"speed": 2.0`. `district_builder.gd`: per-tunnel gap. `map_boundaries.gd`: `GATEWAYS`, `resolve(graph)` (no `road_graph.gd` change needed; graph edges already carry the road index, so speed is read from `ROADS[edge.road]`). `city_map.gd`: car height `_ground(at).y + 0.14`, gateways resolved in `_build_ambient` and printed with `--traffic-debug`, `PARKING_CLEARANCE = 25 m`, no parked cars on the highway or near junctions. `ambient_life.gd`: per-agent `speed_scale` eased over 1.5 s toward the road's `speed` multiplier (highway about 14-24 m/s vs 7-12). `autoplay.gd` edges scenario gained `edge_highway_tunnel_{iso,front}`, `edge_parking_highway`, `edge_parking_junction`.
- **Resolved gateway inventory (all 7, no warnings):** highway_w node 0 edge 0 (-450,-187.5) leg 283 m; highway_e node 3 edge 2 (440,-187.5) leg 118; north_street_w node 4 edge 3 leg 283; north_street_e node 9 edge 7 leg 118; south_street_w node 10 edge 8 leg 283; south_street_e node 15 edge 12 leg 118; border_bridge node 16 edge 13 (-5,-330) leg 63. Frames in `/private/tmp/map-edges-traffic-shots/phase_b/` (tunnel in both cameras reads correctly: highway passes under a concrete deck, no earth over the road; parking frames show no parked cars on the highway or at the north-street/x 140 junction).
- **Phase C (2026-11-01):** implemented. `ambient_life.gd`: car states `graph/out/wait/in`, `stats`, `_begin_exit`, `_step_leg`, `_place_leg`, `_park` (2-5 s wait), `_enter` (weighted by `crowd_at(sample)`, previous gateway excluded when another is open, new class/threshold, retry after 1 s if all closed), `_fleet_class(point)`, visibility judged at the gateway sample while on a leg and false while waiting. `city_map.gd`: `_traffic_look` (seed 7070), `_respawn_car` (new model, heading set without lerp), `--traffic-debug` prints every 10 s with the `TRAFFIC INVARIANT BROKEN` check. `autoplay.gd`: guards for `state != "graph"`.
- **Phase C evidence:** `--autoplay --only=map,week --turbo=10 --traffic-debug` (day) and the same with `--hour=22` (11 prints each): the invariant graph+out+wait+in = 130 never broke, no script errors. Day counters after ~100 s of ambient time: exits per gateway 16/12/14/19/12/10/19 (highway_w, highway_e, north_w, north_e, south_w, south_e, bridge), arrivals 9/12/21/11/15/10/20, i.e. all seven gateways recycle repeatedly. Frames: `/private/tmp/map-edges-traffic-shots/traffic_edges/` (cars drive into the haze on the west road and east street) and `traffic/`, `traffic_night/` (autoplay sets). Note `--hour=22` only pins the light; ambient density follows the sim clock, so a true night-density observation still needs a manual look.
- **Remaining Phase C observations:** ~25% of the 130 car slots are on an off-map leg or waiting at any moment (legs are 118-283 m long at town speed), so visible town traffic is a bit thinner than before; shorten `leg_length` (smaller `handoff_distance`) or reduce the wait if that shows. Highway speed difference and the bridge leg were seen only in aggregate, not filmed.
- **Open questions:** Approve haze look (FADE/NOISE/colour) before Phase B.
- **Requests for the integrator:** Lead-owned work; do not dispatch as a worker brief. README untouched in this phase.

## Review notes

- 2026-11-01, Phase A: lead reviewed the `summer/` and `winter_night/` frames; the user approved the haze look as is (current `INNER`, `FADE`, `NOISE_*`, colour), including the short river mist at the bridge. Next: Phase B.
