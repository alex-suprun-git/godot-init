# Routing request: characters move along roads

For Codex. **Do not start before `docs/MAP_LAYOUT_REQUEST.md` is done and committed.** This brief depends on `ROADS`, `LOTS` with `facing`, and the location → lot mapping it creates.

This is an implementation brief. The design is decided; do not redesign. If something here conflicts with the code or turns out impossible, stop and report instead of improvising.

## Read first

1. `AGENTS.md`, then `README.md` section "Core Loop" and `docs/MAP_AND_DISTRICT.md` section "Starting District Layout".
2. `docs/adr/0001-data-driven-district-layout.md`.
3. `init/scripts/data/district_layout.gd`, `init/scripts/sim/week_sim.gd`, `init/scripts/map/city_map.gd`, `init/scripts/ui/hud.gd`.

## Problem

Characters walk in a straight line from their position to the target location (`move_toward` in `week_sim.gd`). Travel time is straight-line distance divided by speed. Tokens cross buildings and yards, and travel times ignore the road network.

## Goal

- Characters follow the road network.
- Travel time is the length of the route divided by speed.
- On foot, characters may use yard paths. By car, they use only drivable roads.
- Routes are derived from the layout data and never authored by hand.

## Step 1: road graph from the layout

Create `init/scripts/map/road_graph.gd` (`extends RefCounted`), built once at startup from `DistrictLayout`.

- Every road rect in `ROADS` becomes its centerline segment. Rects wider than deep run east–west; the others run north–south.
- Find every crossing between an east–west and a north–south centerline, including T-junctions and centerlines that end inside the other road's rect (tolerance: half the road width). Each crossing is a node. Split segments at their nodes; the pieces are edges.
- Every edge has a `kind` copied from its road: `asphalt`, `dirt`, or `yard`. Rails are not part of the graph.
- **Entrances:**
  - Every lot that a game location points to gets an entrance node at the midpoint of its `facing` side.
  - Project that point perpendicular onto the nearest centerline. Insert a node there, splitting the edge, and add an edge of kind `access` from the entrance to it.
  - Do the same for the road bridge end on our bank, so the checkpoint and the far bank stay reachable.
- **Two modes over the same graph:**
  - `foot`: all kinds. Cost = length.
  - `car`: `asphalt`, `dirt`, `access` only. Cost = length, × 1.5 for `dirt`.
- Use Godot's `AStar2D`, one instance per mode, with the cost factor applied through `AStar2D` weights or by overriding `_compute_cost`. Positions are in metres, and the heuristic is straight-line distance, which never overestimates.
- Public API:
  - `route(from: Vector2, to_lot: String, mode: String) -> PackedVector2Array`: the full polyline, from the start position to the entrance.
  - `length(path) -> float`.
  - Cache routes per (start node, target lot, mode).
- Startup validation: every location's entrance is connected to the graph in both modes. Report failures with `push_error` naming the location.

## Step 2: movement in the simulation

- Actor state gets `path: PackedVector2Array` and `path_index: int`. Set them when an actor starts travelling, in place of the straight target.
- Mode is `car` when `driver` is set (Tolik drives), otherwise `foot`.
- Each simulation step, the actor gets a budget of `speed * step` metres. Spend it along the path segment by segment, and **carry the remainder over to the next segment**. One step can pass several nodes; at 400 m/h and a 0.25 h step that is 100 m.
- Arrival is reaching the last point of the path. Keep the existing arrival behaviour after that.
- Remaining time (the function around `week_sim.gd:150`) = remaining path length / speed. The HUD must not need changes for this.
- **Starting mid-route:** an actor reassigned while travelling stands somewhere on an edge. Start the new route from the projection of its position onto the nearest edge, as a temporary start point. Do not add permanent nodes, and do not mutate the cached graph.
- Keep the fixed `STEP` and deterministic ordering. The same week must play the same way twice.

## Step 3: map and HUD

- Tokens already follow `actor["pos"]`; check that they now turn at junctions.
- If the HUD draws a line from a token to its target (`hud.gd` around line 216), draw the remaining route polyline instead, projected to the screen.
- Dev toggle `F10`, off by default, draws the graph on the map: edges coloured by kind, nodes as dots, and the active routes. This is essential for checking the work.

## Check before reporting

1. Run the dev autoplay with screenshots (see `AGENTS.md`), once with the `F10` overlay enabled by a temporary code switch that you revert before reporting. Confirm in the PNGs:
   - Tokens stay on roads and yard paths.
   - Cars stay off yard paths.
   - Every location is reached.
2. Print a travel-time table for the routes measured in the map rework: office → block5, office → boiler, office → market, office → church, office → depot, office → wasteland. Give columns for straight line and road route, on foot and by car.
3. Read the newest `_autoplay.jsonl` log and confirm the week completes. Compare its waiting time and contact utilization with the autoplay log from the map rework.
4. Report:
   - Files changed.
   - The table.
   - Screenshot paths.
   - Any place where the graph needed a special case.
   - Every deviation from this brief.

## Do not

- Commit or push.
- Change actor speeds, events, or balance. A slower week from longer routes is expected; report it, do not compensate.
- Use Godot's `NavigationServer` or navigation meshes. The graph is deliberately derived from the layout data so it stays inspectable and deterministic.
- Hand-place nodes, except as a reported special case.
- Add automated tests.

## Later, not in this task

These are user decisions:

- Edges closed or slowed by game state, such as a construction site, a border queue, or a muddy village road in autumn.
- Transport modes beyond `foot` and `car`: bicycle, bus with stops and waiting, taxi, and conditional lifts from the administration driver. See README, "Player Mobility and Personal Money". Build the router so a mode is only a set of allowed edge kinds, a cost factor, and a speed.
- Buses and the passenger train as transport.
