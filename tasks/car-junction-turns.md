---
id: car-junction-turns
status: ready   # ready | in-progress | review | blocked | done
worker: lead-integrator
branch: lead/car-junction-turns
---

# Smooth ambient car turns at junctions

## Goal

Ambient cars currently jerk sideways at junctions: they jump several metres when they change road edge, cut or overshoot corners, and the body turns late. Make turns look like a car following a curve: no teleport, a smooth arc that stays in the right-hand lane, a heading that follows the path, and a short slowdown while turning. This is background scenery; no collisions, right of way or traffic lights.

## Cause (diagnosed 2026-11-01, `init/scripts/map/ambient_life.gd`, `_place()`)

1. Position is the edge centreline point plus `right(heading) * lateral` (1.5-4 m). When the car moves to the next edge, `right` rotates instantly (up to 90 degrees), so the lane offset jumps by roughly 3-5 m. Only the offset's magnitude is eased (`move_toward(lateral, target, 4 * delta)`), not its direction.
2. The path is two straight lines meeting at the junction centre: a right turn cuts the inside corner, a left turn swings outside. There is no arc.
3. `city_map.gd` `_move_ambient` smooths the body with `lerp_angle(rotation.y, atan2(...), delta * 6.0)` while the position has already jumped, so the body lags about 0.2 s and looks snapped.
4. Speed does not drop for turns.

## Inputs

- `init/scripts/map/ambient_life.gd`: `_step_graph()`, `_place()`, `_place_leg()`, `_wanted_speed()`, `_next_edge()`.
- `init/scripts/map/city_map.gd`: `_move_ambient()` (rotation smoothing), `_respawn_car()`.
- `init/scripts/map/road_graph.gd`: edge `half`, node positions; `tasks/map-edges-traffic.md` for the car states (`graph/out/wait/in`) that must keep working.

## Constraints

- Cars only; pedestrians keep their current movement.
- Keep the car states, gateway legs, the slot invariant (`graph + out + wait + in = 130`) and the highway/junction speed rules.
- Keep the right-hand lane offset (`clampf(half * 0.35, 1.5, 4.0)`); an arc must start and end exactly on the lane position of the incoming and outgoing edge, so exits and gateway joins stay continuous.
- Suggested approach (change it if a simpler one works): when a car reaches the end of an edge, build a short quadratic Bezier from the incoming lane point (a few metres before the node) through the lane-offset corner to the outgoing lane point (a few metres after the node), and advance the car along the arc by length; heading is the arc tangent, so the body rotation needs no lerp (or only a very light one). Straight-through and U-turns at dead ends must stay valid (a U-turn can stay a simple swing or reverse in place; no visible teleport).
- Scale the car's speed during an arc by turn angle (about 0.5 of its current speed for a 90 degree turn, easing back out afterwards).
- No automated tests. No commits or pushes.

## Outputs

Lead/integrator edits:

- `init/scripts/map/ambient_life.gd`
- `init/scripts/map/city_map.gd` (only the rotation handling in `_move_ambient` if needed)
- This brief's Report; frames under `/private/tmp/car-junction-turns-shots/`.

## Acceptance criteria

- [ ] Frames of a right turn, a left turn and a highway-to-axis turn at a large junction (zoom about 60, `--cam=x,z,zoom`), read, show the car on a smooth arc in its lane with the body aligned to its path. Take several frames of one turn, a fraction of a second apart.
- [ ] A numeric check with `--traffic-debug` (or a temporary dev print, removed afterwards): the maximum frame-to-frame position jump of any car at a junction is below about speed x frame time plus a small tolerance; no jump larger than 1 m for any car in a 120 s run.
- [ ] Gateway exits and re-entries are still continuous; the slot invariant never breaks; `--autoplay --only=map,week --turbo=10 --traffic-debug` runs with no new errors.
- [ ] Pedestrians are unchanged.

## Stop and ask

Ask the user if the fix would need real lane or intersection data (a junction registry), or changes to the road graph beyond reading it. Resolve tuning (arc size, turn speed) independently.

## Report

_Filled in after implementation._

- **Status summary:**
- **Files created or changed:**
- **Measurements / previews:**
- **Open questions:**
- **Requests for the integrator:**

## Review notes

_Filled in by the lead after review._
