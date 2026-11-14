# This class only moves agents; CityMap owns their sprites and models.
extends RefCounted

const RoadGraph = preload("res://scripts/map/road_graph.gd")
const DistrictLayout = preload("res://scripts/data/district_layout.gd")
const TrafficFlows = preload("res://scripts/data/traffic_flows.gd")
const TrafficRoutes = preload("res://scripts/map/traffic_routes.gd")
const SignalController = preload("res://scripts/map/traffic_signal_controller.gd")
const Intersections = preload("res://scripts/data/traffic_intersections.gd")
const Occupancy = preload("res://scripts/map/traffic_occupancy.gd")
const VehicleModels = preload("res://scripts/map/vehicle_models.gd")
const TrafficRules = preload("res://scripts/map/traffic_rules.gd")

const PedestrianGraph = preload("res://scripts/map/pedestrian_graph.gd")
const WALKER_KINDS := ["pavement"]
const CAR_KINDS := ["asphalt", "yard"]
# A district's density of 2.0 at its busiest hour shows every agent standing there; the
# pool is sized so that a typical place (1.0) shows about half of them.
const CROWD_CAP := 2.0
const MIN_DENSITY := 0.02
const VISIBILITY_PER_FRAME := 48
# Cap road-traffic bus slots; parked depot models are outside this pool.
const MAX_BUSES := 5
# Fast roads slow to town speed at junctions: full town speed within SLOW_NEAR metres
# of the junction, rising to the road's speed over the next SLOW_RAMP metres.
const JUNCTION_SLOW_NEAR := 12.0
const JUNCTION_SLOW_RAMP := 50.0
const SERVICE_BRAKE := 3.2 # metres per second squared
const ACCELERATION := 2.6
const FOLLOW_SECONDS := 1.4
const ZEBRA_CLEARANCE := 1.0 # bumper to the near edge of the paint
const TURN_SAMPLES := 48
const TURN_APPROACH := 10.0

var agents: Array[Dictionary] = []
var hour := 12.0 # Clock hour, set by the view; decides who is out and about.

var stats := {"exits": {}, "arrivals": {}, "max_step": 0.0, "max_excess": 0.0, "motion_warnings": 0, "passes_started": 0, "passes_finished": 0, "road_speeds": {},
	"loops": {"city": 0, "residential": 0}}
var _hour_override := -1.0
var _traffic_debug := OS.get_cmdline_user_args().has("--traffic-debug")

var _graph: RoadGraph
var _gateways: Array[Dictionary] = []
var _gateway_at_node := {} # graph node -> index into _gateways
var _foot_graph := PedestrianGraph.new()
var _rng := RandomNumberGenerator.new()
var _workday_rng := RandomNumberGenerator.new()
var _cursor := 0
var _car_slots := 0
var _space := Occupancy.new()
var _highway_node := -1
var _station_node := -1
var signals := {} # registered junction id -> signal controller
var _crossing_signals := {}
var _signal_zebras := {}
var _junctions: Array[Dictionary] = []
var _routes: TrafficRoutes


func _init(graph: RoadGraph, seed_value: int, gateways: Array[Dictionary] = []) -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--traffic-hour="):
			_hour_override = float(arg.trim_prefix("--traffic-hour="))
	_graph = graph
	_rng.seed = seed_value
	_workday_rng.seed = seed_value + 4621
	_gateways = gateways
	for i in gateways.size():
		_gateway_at_node[gateways[i]["node"]] = i
		stats["exits"][gateways[i]["id"]] = 0
		stats["arrivals"][gateways[i]["id"]] = 0
	_routes = TrafficRoutes.new(graph, gateways)
	var crossings := DistrictLayout.crosswalks()
	var controllers := {}
	for id in Intersections.JUNCTIONS:
		var data := Intersections.junction(id)
		var controller := SignalController.new()
		controller.elapsed = float(signals.size() % 4) * 3.0
		_signal_zebras[id] = []
		for crossing in crossings:
			if crossing["id"] in data["crossing_ids"]:
				_signal_zebras[id].append({"pos": crossing["at"], "heading": Vector2.DOWN if crossing["along_z"] else Vector2.RIGHT,
					"class": "", "half_extent": Vector2(float(crossing["width"]) * 0.5, DistrictLayout.CROSSWALK_DEPTH * 0.5)})
		signals[id] = controller
		controllers[data["center"]] = controller
		for crossing_id in data["crossing_ids"]:
			_crossing_signals[crossing_id] = controller
	for node in graph.points.size():
		var controller: SignalController = controllers.get(graph.points[node])
		if controller == signals["axis_station"]:
			_station_node = node
		if controller == signals["axis_highway"]:
			_highway_node = node
		var roads := {}
		var radius := 0.0
		for index in graph.adjacent_edges(node):
			var edge: Dictionary = graph.edges[index]
			if edge["road"] >= 0 and TrafficRules.can_use_road("car", DistrictLayout.ROADS[edge["road"]]):
				roads[DistrictLayout.ROADS[edge["road"]]["id"]] = true
				radius = maxf(radius, edge["half"])
		if roads.size() > 1:
			_junctions.append({"node": node, "center": graph.points[node], "radius": radius + TURN_APPROACH + 2.0, "owner": -1,
				"clear_radius": radius, "signal": controller, "stop_lines": _stop_lines(graph.points[node], roads, crossings)})


# Agents start on edges picked by length times district density, so crowded districts
# hold more of them. Cars use separately budgeted routes and fleets.
# True when the agent's trip drives along the given road id (e.g. "axis").
func trip_uses_road(agent: Dictionary, road_id: String) -> bool:
	for leg: Dictionary in agent["trip"]["path"]:
		var road: int = _graph.edges[leg["edge"]]["road"]
		if road >= 0 and DistrictLayout.ROADS[road]["id"] == road_id:
			return true
	return false


func add(is_car: bool, speed: float, appearance_seed: int = -1) -> Dictionary:
	if is_car:
		return _add_car(speed, appearance_seed)
	var graph = _graph if is_car else _foot_graph
	var kinds: Array = CAR_KINDS if is_car else WALKER_KINDS
	var choices: Array[int] = []
	for i in graph.edges.size():
		if _usable(is_car, kinds, graph.edges[i]) and not _crossing_signals.has(graph.edges[i].get("crossing_id", "")):
			choices.append(i)
	if choices.is_empty():
		return {}
	var edge := _pick(choices, is_car, true, graph)
	var forward := _rng.randf() < 0.5
	var agent := {
		"graph": graph, "kinds": kinds, "is_car": is_car, "speed": speed, "edge": edge,
		"from": graph.edges[edge]["a"] if forward else graph.edges[edge]["b"],
		"along": _rng.randf() * graph.edges[edge]["length"],
		"side": 1.0 if is_car or _rng.randf() < 0.5 else -1.0,
		"lateral": 0.0, "pos": Vector2.ZERO, "heading": Vector2.RIGHT, "visual": null,
		"speed_scale": 1.0, "threshold": _rng.randf(), "visible": true, "class": "",
		# Cars only: "graph" (on the roads), "out" (driving into the haze), "wait" (a slot
		# with no car on the map) or "in" (arriving from the haze). Walkers stay "graph".
		"state": "graph", "gateway": -1, "leg_from": Vector2.ZERO, "leg_dir": Vector2.ZERO,
		"leg_len": 0.0, "wait": 0.0, "respawned": false, "turn": {},
	}
	agents.append(agent)
	_place(agent, 1.0)
	agent["lateral"] = agent["target_lateral"]
	_place(agent, 1.0)
	_update_visibility(agent)
	_space.track(agent)
	return agent


func add_workday_walker(original: Dictionary, speed: float) -> Dictionary:
	# One independent extra per base slot avoids saturating the existing visibility cap.
	# Separate RNG and creation after cars preserve all original agents and car choices.
	var agent := original.duplicate()
	agent.erase("traffic_cell")
	agent["visual"] = null
	agent["turn"] = {}
	agent["workday_extra"] = true
	agent["speed"] = speed
	agent["threshold"] = _workday_rng.randf()
	agent["side"] = 1.0 if _workday_rng.randf() < .5 else -1.0
	var edge: Dictionary = agent["graph"].edges[agent["edge"]]
	agent["along"] = fposmod(float(agent["along"]) + _workday_rng.randf_range(4.0, 18.0), float(edge["length"]))
	agents.append(agent)
	_place(agent, 1.0)
	agent["lateral"] = agent["target_lateral"]
	_place(agent, 1.0)
	_update_visibility(agent)
	if agent["visible"] and not _space.clear_pose(agent, _space.nearby(agent["pos"], 10.0)):
		agent["visible"] = false
	_space.track(agent)
	return agent


func _add_car(speed: float, appearance_seed: int) -> Dictionary:
	var stream := _routes.stream_for_slot(_car_slots)
	var choices: Array = _routes.trips[stream]
	# Spread the small local pools over their loops and both directions.
	var trip: Dictionary = choices[_car_slots % choices.size()]
	var vehicle_class := _stream_class(stream)
	if appearance_seed < 0:
		appearance_seed = _rng.randi()
	trip = _routes.for_model(trip, VehicleModels.model_for_class(vehicle_class, appearance_seed))
	if _traffic_debug and trip.get("semi_bypass", false):
		print("SEMI bypass ", _gateways[trip["entry"]]["id"], " -> ", _gateways[trip["exit"]]["id"])
	_car_slots += 1
	var path: Array = trip["path"]
	var lengths: Array[float] = []
	var total := 0.0
	for leg in path:
		total += float(_graph.edges[leg["edge"]]["length"])
		lengths.append(total)
	# Warm-start open trips over their whole length, including the hidden gateway
	# legs, so the first frame is not much denser than the steady-state traffic.
	var entry_length: float = 0.0 if trip["loop"] else _gateways[trip["entry"]]["leg_length"]
	var exit_length: float = 0.0 if trip["loop"] else _gateways[trip["exit"]]["leg_length"]
	var position := _rng.randf() * (entry_length + total + exit_length) - entry_length
	var span := entry_length + total + exit_length
	for attempt in 256:
		var agent := _initial_pose(speed, stream, trip, path, lengths, total, entry_length, position, vehicle_class)
		if _space.clear_pose(agent, _space.nearby(agent["pos"], 18.0)) and _outside_junctions(agent):
			agent["appearance_seed"] = appearance_seed
			agents.append(agent)
			_space.track(agent)
			return agent
		position = fposmod(position + entry_length + span * 0.61803398875, span) - entry_length
	push_warning("No free start on traffic route: " + stream)
	return {}


func _initial_pose(speed: float, stream: String, trip: Dictionary, path: Array, lengths: Array[float],
		total: float, entry_length: float, position: float, vehicle_class: String) -> Dictionary:
	var distance := clampf(position, 0.0, total)
	var cursor := 0
	while cursor < lengths.size() - 1 and distance > lengths[cursor]:
		cursor += 1
	var leg: Dictionary = path[cursor]
	var agent := {"graph": _graph, "kinds": CAR_KINDS, "is_car": true, "base_speed": speed, "speed": speed * (0.85 if vehicle_class == "truck" else 1.0),
		"edge": leg["edge"], "from": leg["from"], "along": distance - (lengths[cursor - 1] if cursor > 0 else 0.0),
		"side": 1.0, "lateral": 0.0, "pos": Vector2.ZERO, "heading": Vector2.RIGHT, "visual": null,
		"speed_scale": _road_speed(leg["edge"]), "threshold": 0.0, "visible": true, "class": vehicle_class, "slot": _car_slots, "passing": false, "limit": INF, "laps": 0,
		"state": "graph", "gateway": trip["entry"], "leg_from": Vector2.ZERO, "leg_dir": Vector2.ZERO,
		"leg_len": 0.0, "wait": 0.0, "respawned": false, "turn": {},
		"stream": stream, "trip": trip, "route_cursor": cursor}
	if position < 0.0 or position > total:
		var arriving := position < 0.0
		var gate: Dictionary = _gateways[trip["entry"] if arriving else trip["exit"]]
		agent["state"] = "in" if arriving else "out"
		agent["gateway"] = trip["entry"] if arriving else trip["exit"]
		agent["leg_from"] = gate["point"] + gate["out"] * gate["leg_length"] if arriving else gate["point"]
		agent["leg_dir"] = -gate["out"] if arriving else gate["out"]
		agent["leg_len"] = gate["leg_length"]
		agent["along"] = entry_length + position if arriving else position - total
		agent["lateral"] = _lane_offset(agent, _graph.edges[gate["edge"]])
		_place_leg(agent, 1.0)
		return agent
	_place(agent, 1.0)
	agent["lateral"] = agent["target_lateral"]
	_place(agent, 1.0)
	return agent


func step(delta: float) -> void:
	if _hour_override >= 0.0:
		hour = _hour_override
	_refresh_visibility()
	while delta > 0.00001:
		var tick := minf(delta, 0.05)
		_tick(tick)
		delta -= tick


func _tick(delta: float) -> void:
	for id in signals:
		var signal_controller: SignalController = signals[id]
		if signal_controller.phase == SignalController.CLEAR_NS:
			signal_controller.crossings_clear = _crossings_clear(id)
		signal_controller.advance(delta)
		if signal_controller.phase in [SignalController.CLEAR_EW, SignalController.CLEAR_NS] and signal_controller.elapsed > 20.0 and not signal_controller.stall_reported:
			_save_stall(id, signal_controller)
			signal_controller.stall_reported = true
	for agent in agents:
		if agent["state"] == "wait":
			agent["wait"] -= delta
			if agent["wait"] <= 0.0:
				_enter(agent)
			continue
		var old_crossing: String = agent.get("walk_permit", "")
		if not agent["visible"]:
			_step_graph(agent, delta)
			_record_crossing(agent, old_crossing)
			continue
		var neighbors := _space.nearby(agent["pos"], 90.0 if agent["is_car"] else 9.0, not agent["is_car"])
		if agent["is_car"]:
			_drive(agent, neighbors, delta)
		else:
			_walk(agent, neighbors, delta)
			_record_crossing(agent, old_crossing)
		_space.track(agent)


# Keep the actual state of a long clearance pause from normal play for diagnosis.
func _save_stall(id: String, controller: SignalController) -> void:
	var snapshot := {"junction": id, "phase": controller.phase, "elapsed": controller.elapsed,
		"inside": controller.inside, "waiting": controller.waiting, "agents": [], "locks": []}
	for agent in agents:
		if not agent["visible"]:
			continue
		var record := {}
		for key in ["slot", "class", "state", "edge", "from", "along", "speed", "speed_scale", "limit", "route_cursor", "pending_edge", "walk_permit", "stop_reason", "blocked_by"]:
			if agent.has(key):
				record[key] = agent[key]
		var point: Vector2 = agent["pos"]
		var heading: Vector2 = agent["heading"]
		record["pos"] = [point.x, point.y]
		record["heading"] = [heading.x, heading.y]
		record["turn"] = agent["turn"]
		snapshot["agents"].append(record)
	for junction in _junctions:
		snapshot["locks"].append({"node": junction["node"], "owner": junction["owner"]})
	var file := FileAccess.open("user://traffic_stall.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(snapshot, "  "))


func _crossings_clear(id: String) -> bool:
	for zebra: Dictionary in _signal_zebras[id]:
		for car in _space.nearby(zebra["pos"], 25.0, true):
			if Occupancy.overlaps(zebra, car):
				return false
	return true


func _record_crossing(agent: Dictionary, old_id: String) -> void:
	var new_id: String = _foot_graph.edges[agent["edge"]]["crossing_id"]
	if agent.get("pending_edge", -1) >= 0:
		new_id = "" # Already on the curb, waiting for the next crossing.
	if old_id == new_id:
		return
	agent["walk_permit"] = new_id
	if _crossing_signals.has(old_id):
		_crossing_signals[old_id].walking -= 1
	if _crossing_signals.has(new_id):
		_crossing_signals[new_id].walking += 1
		_crossing_signals[new_id].pedestrian_entries += 1


# A walker already beside a stopped vehicle can walk around its nearest end.
# Preserve route progress during the detour and ease back to the pavement line.
func _walk(agent: Dictionary, cars: Array, delta: float) -> void:
	var detour: Vector2 = agent.get("detour", Vector2.ZERO)
	if cars.is_empty() and detour == Vector2.ZERO:
		_step_graph(agent, delta)
		return
	var before := agent.duplicate()
	_step_graph(agent, delta)
	# Keep the bypass while alongside the vehicle; merging immediately can trap
	# a walker oscillating against the same bumper on consecutive frames.
	if cars.is_empty():
		detour = detour.move_toward(Vector2.ZERO, float(agent["speed"]) * delta * 0.5)
	agent["pos"] += detour
	agent["detour"] = detour
	for car in cars:
		if not Occupancy.overlaps(agent, car):
			continue
		agent.merge(before, true)
		var heading: Vector2 = car["heading"]
		var side := heading.orthogonal()
		var offset: Vector2 = agent["pos"] - car["pos"]
		var forward := offset.dot(heading)
		var tangent := heading if forward >= 0.0 else -heading
		# Across the road, keep sidestepping towards the same bumper until the
		# crossing path is clear. Along the road, move out towards the verge.
		var walking: Vector2 = before["heading"]
		if absf(walking.dot(heading)) > 0.7:
			tangent = side if offset.dot(side) >= 0.0 else -side
		var step_aside := tangent * float(agent["speed"]) * delta
		var next_detour: Vector2 = before.get("detour", Vector2.ZERO) + step_aside
		if next_detour.length() <= Occupancy.half_length(car) + 2.0:
			agent["pos"] += step_aside
			if _space.clear_pose(agent, cars):
				agent["detour"] = next_detour
				return
		agent["pos"] = before["pos"]
		agent["detour"] = before.get("detour", Vector2.ZERO)
		return


# Store the near painted edge for each incoming arm, measured from the junction.
func _stop_lines(center: Vector2, roads: Dictionary, crossings: Array) -> Dictionary:
	var lines := {}
	for crossing in crossings:
		if not roads.has(crossing["road_id"]) or not roads.has(crossing["joining_road_id"]):
			continue
		var axis := Vector2.DOWN if crossing["along_z"] else Vector2.RIGHT
		var offset: Vector2 = crossing["at"] - center
		for direction: Vector2 in [axis, -axis]:
			var setback := -offset.dot(direction)
			if setback >= 0.0:
				lines[direction] = setback + DistrictLayout.CROSSWALK_DEPTH * 0.5
	return lines


func _stop_gap(agent: Dictionary, junction: Dictionary, direction: Vector2) -> float:
	var toward: Vector2 = junction["center"] - agent["pos"]
	var bumper := Occupancy.half_length(agent)
	var edge: float = junction["stop_lines"].get(direction, junction["clear_radius"])
	return maxf(0.0, toward.dot(direction) - bumper - edge - ZEBRA_CLEARANCE)


func _junction_gap(agent: Dictionary, junction: Dictionary) -> float:
	var offset: Vector2 = agent["pos"] - junction["center"]
	return maxf(absf(offset.x), absf(offset.y)) - float(junction["radius"]) - Occupancy.half_length(agent)


func _outside_junctions(agent: Dictionary) -> bool:
	for junction in _junctions:
		if _junction_gap(agent, junction) <= 1.5:
			return false
	return true


# Braking only starts well inside this distance (sqrt(2 * SERVICE_BRAKE * 120 m) is far
# above any car speed), so junctions farther away cannot change the result unless the
# car owns them or is inside their signal group and must still release them.
const FAR_JUNCTION := 120.0


func _junction_limit(agent: Dictionary, neighbors: Array) -> float:
	var limit := INF
	var position: Vector2 = agent["pos"]
	var slot: int = agent["slot"]
	for junction in _junctions:
		var center: Vector2 = junction["center"]
		if absf(position.x - center.x) > FAR_JUNCTION or absf(position.y - center.y) > FAR_JUNCTION:
			var signal_group: SignalController = junction["signal"]
			if junction["owner"] != slot and (signal_group == null or not signal_group.inside.has(slot)):
				continue
		var gap := _junction_gap(agent, junction)
		if junction["signal"] != null:
			limit = minf(limit, _group_limit(junction["signal"], agent, junction, gap, neighbors))
			continue
		if junction["owner"] == agent["slot"]:
			var away: Vector2 = agent["pos"] - junction["center"]
			# The approach leaves turning room for a long body. Release after the
			# rear actually clears the intersecting road, so nearby nodes can drain.
			if gap > -TURN_APPROACH and away.dot(agent["heading"]) > 0.0:
				junction["owner"] = -1
			continue
		# A diagonal body tangent during a turn can point at another nearby
		# junction. Only the junction actually ahead on this route may stop us.
		var incoming := _incoming_cursor(agent, junction["node"])
		if incoming < 0:
			continue
		var leg: Dictionary = agent["trip"]["path"][incoming]
		var approach: Vector2 = (junction["center"] - _graph.points[leg["from"]]).normalized()
		var toward: Vector2 = junction["center"] - agent["pos"]
		var heading: Vector2 = agent["heading"]
		if toward.dot(heading) < 0.0 or absf(toward.cross(heading)) > float(junction["radius"]):
			continue
		var stop_gap := _stop_gap(agent, junction, approach)
		if junction["owner"] != -1:
			limit = minf(limit, stop_gap)
		elif stop_gap <= 1.25:
			junction["owner"] = agent["slot"]
	return limit


func _incoming_cursor(agent: Dictionary, node: int) -> int:
	if agent["state"] != "graph":
		return -1
	var path: Array = agent["trip"]["path"]
	var cursor: int = agent["route_cursor"]
	var road: int = _graph.edges[agent["edge"]]["road"]
	while true:
		var leg: Dictionary = path[cursor]
		if _graph.other_end(leg["edge"], leg["from"]) == node:
			return cursor
		cursor += 1
		if cursor == path.size():
			if not agent["trip"]["loop"]:
				return -1
			cursor = 0
		if cursor == agent["route_cursor"] or _graph.edges[path[cursor]["edge"]]["road"] != road:
			return -1
	return -1


func _group_limit(group: SignalController, agent: Dictionary, junction: Dictionary, gap: float, neighbors: Array) -> float:
	var slot: int = agent["slot"]
	if group.inside.has(slot):
		var away: Vector2 = agent["pos"] - junction["center"]
		var exit: Vector2 = group.inside[slot]["out"]
		var heading: Vector2 = agent["heading"]
		var rear := away.dot(exit) - absf(heading.dot(exit)) * Occupancy.half_length(agent) - absf(heading.cross(exit)) * Occupancy.half_width(agent)
		# Release the carriageway when the rear clears the intersecting road.
		# The pedestrian phase separately waits for every zebra to be empty.
		if rear > float(junction["clear_radius"]) + 0.25:
			group.release(slot)
		return INF
	if gap > 22.0 or agent["state"] != "graph":
		return INF
	var path: Array = agent["trip"]["path"]
	var cursor := _incoming_cursor(agent, junction["node"])
	if cursor < 0:
		return INF
	var inbound: Dictionary = path[cursor]
	var next: Dictionary = path[(cursor + 1) % path.size()]
	var center: Vector2 = junction["center"]
	var direction := (center - _graph.points[inbound["from"]]).normalized()
	var exit := (_graph.points[_graph.other_end(next["edge"], junction["node"])] - center).normalized()
	var exit_lane := _lane_offset(agent, _graph.edges[next["edge"]])
	if not _exit_has_room(agent, neighbors, junction, exit, exit_lane):
		group.waiting.erase(slot)
		return _stop_gap(agent, junction, direction)
	var lane := _lane_offset(agent, _graph.edges[agent["edge"]])
	# Reserve only at the physical stop line. A follower behind a waiting
	# leader cannot claim the junction while the leader still needs to enter.
	return group.request(slot, {"in": direction, "out": exit, "lane": lane}, _stop_gap(agent, junction, direction))


# A queue can spill back from the station driveway into the avenue junction.
# Before entering, leave room for this entire vehicle beyond the crossing.
func _exit_has_room(agent: Dictionary, neighbors: Array, junction: Dictionary, direction: Vector2, lane: float) -> bool:
	var right := Vector2(-direction.y, direction.x)
	var exit_edge := float(junction["stop_lines"].get(-direction, float(junction["clear_radius"])))
	var clearance := exit_edge + ZEBRA_CLEARANCE + 2.0 * Occupancy.half_length(agent) + 1.3
	for other in neighbors:
		if is_same(agent, other) or not other["is_car"] or direction.dot(other["heading"]) < 0.8:
			continue
		var offset: Vector2 = other["pos"] - junction["center"]
		var ahead := offset.dot(direction)
		if ahead <= 0.0 or ahead - Occupancy.half_length(other) >= clearance:
			continue
		if absf(offset.dot(right) - lane) < Occupancy.half_width(other) + Occupancy.half_width(agent):
			return false
	return true


func _drive(agent: Dictionary, neighbors: Array, delta: float) -> void:
	agent.erase("blocked_by")
	var heading: Vector2 = agent["heading"]
	if agent.get("changing_lane", false):
		# Keep checking the road ahead while the body is angled across the lane.
		var center: Vector2 = _graph.points[_graph.other_end(agent["edge"], agent["from"])]
		heading = (center - _graph.points[agent["from"]]).normalized()
	var headway := INF
	var leader: Dictionary = {}
	for other in neighbors:
		if is_same(agent, other):
			continue
		# A walker waiting on the curb for green is not moving into the lane.
		# The final footprint check still protects their actual position.
		if not other["is_car"] and other.get("pending_edge", -1) >= 0:
			continue
		var offset: Vector2 = other["pos"] - agent["pos"]
		var ahead := offset.dot(heading)
		var other_heading: Vector2 = other["heading"]
		var width := Occupancy.half_width(agent) + Occupancy.half_width(other)
		var side := offset.cross(heading)
		# Treat a committed merge as occupying the space through to its target.
		# Drivers in both lanes must see it before the bodies are alongside.
		var lane_distance := absf(side)
		if other["is_car"] and other_heading.dot(heading) > 0.8:
			var final_side := side
			if other.get("changing_lane", false):
				final_side -= float(other["target_lateral"]) - float(other["lateral"])
			if agent.get("changing_lane", false):
				final_side += float(agent["target_lateral"]) - float(agent["lateral"])
			lane_distance = 0.0 if side * final_side <= 0.0 else minf(lane_distance, absf(final_side))
		var approaching_crossing := false
		if not other["is_car"] and side * other_heading.cross(heading) < 0.0:
			var zebra: bool = _foot_graph.edges[other["edge"]]["crossing"]
			approaching_crossing = absf(side) < width + (25.0 if zebra else float(other["speed"]))
		if ahead <= 0.0 or (lane_distance > width + 0.1 and not approaching_crossing):
			continue
		if not other["is_car"] and ahead < Occupancy.half_length(agent) and absf(offset.cross(heading)) >= width:
			continue # The walker beside the body can cross after the rear clears.
		if other["is_car"] and other_heading.dot(heading) < 0.75:
			continue
		var turn: Dictionary = agent["turn"]
		if other["is_car"] and float(turn.get("distance", 0.0)) > 0.0:
			var other_turn: Dictionary = other["turn"]
			var same_turn: bool = other_turn.get("node", -1) == turn["node"] and other_turn.get("edge", -1) == turn["edge"]
			var on_exit: bool = other["edge"] == turn["edge"] and other["from"] == turn["node"]
			if not same_turn and not on_exit:
				continue # The body tangent can point at a queue on another arm.
		var gap := ahead - Occupancy.half_length(agent) - Occupancy.half_length(other) - 1.3
		if gap < headway:
			headway = gap
			leader = other
	_choose_lane(agent, neighbors, leader, headway)
	agent["following_gap"] = INF
	if not leader.is_empty() and leader["is_car"]:
		agent["following_gap"] = maxf(headway, 0.0)
	var junction_limit := _junction_limit(agent, neighbors)
	agent["limit"] = minf(junction_limit, maxf(0.0, headway))
	if _traffic_debug:
		agent["stop_reason"] = "junction" if junction_limit < headway else str("leader ", leader.get("slot","walker"))
		agent["junction_limit"] = junction_limit
	var before := agent.duplicate()
	if not agent["turn"].is_empty():
		before["turn"] = agent["turn"].duplicate()
	if agent["state"] == "graph":
		_step_car(agent, delta)
	else:
		_step_leg(agent, delta)
	if agent["visible"] and not _space.clear_pose(agent, neighbors):
		if _traffic_debug:
			for other in neighbors:
				if not is_same(agent, other) and Occupancy.overlaps(agent, other):
					before["blocked_by"] = str(other.get("slot", "walker"), " at ", other["pos"])
					break
		agent.merge(before, true)
		agent["speed_scale"] = 0.0
	if agent["laps"] > before["laps"]:
		stats["loops"][agent["stream"]] += 1
	if _traffic_debug and agent["visible"]:
		if agent.get("returning", false) and absf(float(agent["lateral"]) - float(agent["target_lateral"])) < 0.05:
			stats["passes_finished"] += 1
			agent.erase("returning")
		var edge_index: int = agent["edge"] if agent["state"] == "graph" else _gateways[agent["gateway"]]["edge"]
		var road: Dictionary = DistrictLayout.ROADS[_graph.edges[edge_index]["road"]]
		var limits: Dictionary = stats["road_speeds"]
		limits[road["id"]] = maxf(limits.get(road["id"], 0.0), float(agent["speed_scale"]))
		var previous: Vector2 = before["pos"]
		var moved := previous.distance_to(agent["pos"])
		var forward: float = agent["speed"] * maxf(before["speed_scale"], agent["speed_scale"]) * delta
		var side := absf(float(agent["lateral"]) - float(before["lateral"])) if before["turn"].get("distance", 0.0) == 0.0 else 0.0
		var expected := Vector2(forward, side).length()
		stats["max_step"] = maxf(stats["max_step"], moved)
		stats["max_excess"] = maxf(stats["max_excess"], moved - expected)
		if moved > expected + 0.05:
			stats["motion_warnings"] += 1


func _choose_lane(agent: Dictionary, neighbors: Array, leader: Dictionary, gap: float) -> void:
	if agent["state"] != "graph" or agent["class"] == "bus" or agent.get("changing_lane", false):
		return
	var edge: Dictionary = _graph.edges[agent["edge"]]
	var road: Dictionary = DistrictLayout.ROADS[edge["road"]]
	if int(road.get("lanes_per_direction", 1)) < 2:
		agent["passing"] = false
		return
	if float(edge["length"]) - float(agent["along"]) < 48.0 or absf(float(agent["lateral"]) - _lane_offset(agent, edge)) > 0.1:
		return
	var passing: bool = agent["passing"]
	if not passing and (leader.is_empty() or not leader["is_car"] or gap > 20.0 or float(leader["speed"]) >= float(agent["speed"]) - 0.4):
		return
	if passing:
		for other in neighbors:
			if other.get("slot", -1) == agent.get("pass_slot", -2):
				var separation: Vector2 = agent["pos"] - other["pos"]
				if separation.dot(agent["heading"]) < Occupancy.half_length(agent) + Occupancy.half_length(other) + 2.0:
					return
	var change_length := clampf(float(agent["speed"]) * float(agent["speed_scale"]) * 2.0, 25.0, 32.0)
	var target := TrafficRules.lane_offset(agent["class"], edge, road, not passing)
	var heading: Vector2 = agent["heading"]
	var right := Vector2(-heading.y, heading.x)
	var center: Vector2 = agent["pos"] + right * (target - float(agent["lateral"]))
	for other in neighbors:
		if is_same(agent, other):
			continue
		var offset: Vector2 = other["pos"] - center
		var lateral := offset.dot(right)
		var intent := lateral
		if other["is_car"] and heading.dot(other["heading"]) > 0.9:
			intent += float(other.get("target_lateral", other["lateral"])) - float(other["lateral"])
		if minf(absf(lateral), absf(intent)) > Occupancy.half_width(agent) + Occupancy.half_width(other) + 0.3 and lateral * intent > 0.0:
			continue
		var buffer := Occupancy.half_length(agent) + Occupancy.half_length(other) + 2.0
		var behind := offset.dot(heading) < 0.0
		var follower: Dictionary = other if behind else agent
		var pace: float = follower["speed"] * maxf(1.0, follower["speed_scale"])
		buffer += maxf(change_length, pace * 1.8)
		if absf(offset.dot(heading)) < buffer:
			return
	if not _outside_junctions(agent):
		return
	if _traffic_debug:
		if passing:
			agent["returning"] = true
		else:
			stats["passes_started"] += 1
	if not passing:
		agent["pass_slot"] = leader["slot"]
	agent["changing_lane"] = true
	agent["change_start"] = agent["along"]
	agent["change_from"] = agent["lateral"]
	agent["change_length"] = change_length
	agent["passing"] = not passing
	agent["target_lateral"] = target
	agent["turn"] = {}


func _drive_distance(agent: Dictionary, wanted: float, delta: float) -> float:
	var gap: float = agent["limit"]
	var speed: float = agent["speed"] * agent["speed_scale"]
	var target: float = wanted * agent["speed"]
	if is_finite(gap):
		# Start slowing at braking distance, then match the queue with a time gap.
		target = minf(target, sqrt(2.0 * SERVICE_BRAKE * gap))
	target = minf(target, float(agent.get("following_gap", INF)) / FOLLOW_SECONDS)
	var next := move_toward(speed, target, (SERVICE_BRAKE if target < speed else ACCELERATION) * delta)
	var distance := minf(gap, (speed + next) * 0.5 * delta)
	if delta > 0.0 and distance >= gap:
		next = 0.0
	agent["speed_scale"] = next / float(agent["speed"])
	return distance


func _step_graph(agent: Dictionary, delta: float) -> void:
	if agent["is_car"]:
		_step_car(agent, delta)
		return
	var graph = agent["graph"]
	var edge: Dictionary = graph.edges[agent["edge"]]
	agent["along"] += agent["speed"] * agent["speed_scale"] * delta
	while agent["along"] >= edge["length"]:
		agent["along"] -= edge["length"]
		var node: int = graph.other_end(agent["edge"], agent["from"])
		var next_edge: int = agent.get("pending_edge", -1)
		if next_edge < 0:
			next_edge = _next_edge(agent, node)
		var crossing_id: String = graph.edges[next_edge]["crossing_id"]
		var entering: bool = crossing_id != agent.get("walk_permit", "") or next_edge == agent["edge"]
		if _crossing_signals.has(crossing_id) and entering:
			if _crossing_signals[crossing_id].phase != SignalController.WALK:
				agent["pending_edge"] = next_edge
				agent["along"] = edge["length"]
				break
		agent["pending_edge"] = -1
		agent["edge"] = next_edge
		agent["from"] = node
		edge = graph.edges[agent["edge"]]
	_place(agent, delta)


# Each transition is planned before reaching the node. The curve replaces the end
# of the incoming edge and the beginning of the outgoing edge; it never changes
# the road graph or adds a fifth traffic state. Short edges reserve at most 40%
# at either end so adjacent turns cannot overlap.
func _plan_turn(agent: Dictionary) -> void:
	var edge: Dictionary = _graph.edges[agent["edge"]]
	var node: int = _graph.other_end(agent["edge"], agent["from"])
	if _gateway_at_node.has(node):
		return
	var path: Array = agent["trip"]["path"]
	var next_cursor := (int(agent["route_cursor"]) + 1) % path.size()
	var next: int = path[next_cursor]["edge"]
	var outgoing: Dictionary = _graph.edges[next]
	var center: Vector2 = _graph.points[node]
	var incoming_dir: Vector2 = (center - _graph.points[agent["from"]]).normalized()
	var outgoing_dir: Vector2 = (_graph.points[_graph.other_end(next, node)] - center).normalized()
	var lane_in := _lane_offset(agent, edge)
	var lane_out := _lane_offset(agent, outgoing)
	var angle := absf(incoming_dir.angle_to(outgoing_dir))
	var radius := maxf(float(edge["half"]), float(outgoing["half"])) + 3.0
	# Collinear edges still need a short continuous lane merge if widths differ.
	if angle < 0.01:
		radius = 4.0
	var trim_in := minf(radius, float(edge["length"]) * 0.4)
	trim_in = minf(trim_in, maxf(0.0, float(edge["length"]) - float(agent["along"])))
	var exit_radius := radius
	if angle > 0.01:
		exit_radius = maxf(lane_in + 2.0, radius - Occupancy.half_length(agent))
	var trim_out := minf(exit_radius, float(outgoing["length"]) * 0.4)
	var start := center - incoming_dir * trim_in + Vector2(-incoming_dir.y, incoming_dir.x) * lane_in
	var finish := center + outgoing_dir * trim_out + Vector2(-outgoing_dir.y, outgoing_dir.x) * lane_out
	# Intersect the lane tangents. A quadratic through that corner has exact
	# incoming/outgoing tangents; represent it as a cubic for U-turns and merges.
	var handle_in := start.distance_to(finish) / 3.0
	var handle_out := handle_in
	var cross := incoming_dir.cross(outgoing_dir)
	if absf(cross) > 0.01:
		var separation := finish - start
		handle_in = maxf(0.01, separation.cross(outgoing_dir) / cross) * 2.0 / 3.0
		handle_out = maxf(0.01, incoming_dir.cross(separation) / cross) * 2.0 / 3.0
	elif incoming_dir.dot(outgoing_dir) < -0.99:
		# A smooth swing between opposite lanes at a dead end.
		handle_in = maxf(trim_in, trim_out) + (lane_in + lane_out) * 0.67
		handle_out = handle_in
	var p1 := start + incoming_dir * handle_in
	var p2 := finish - outgoing_dir * handle_out
	var lengths := PackedFloat32Array([0.0])
	var previous := start
	for i in range(1, TURN_SAMPLES + 1):
		var point := start.bezier_interpolate(p1, p2, finish, float(i) / TURN_SAMPLES)
		lengths.append(lengths[-1] + previous.distance_to(point))
		previous = point
	agent["turn"] = {"node": node, "edge": next, "start": float(edge["length"]) - trim_in,
		"route_cursor": next_cursor,
		"exit": trim_out, "lane": lane_out, "p0": start, "p1": p1, "p2": p2, "p3": finish,
		"lengths": lengths, "distance": 0.0, "speed": lerpf(1.0, 0.5, minf(angle / (PI / 2.0), 1.0))}


func _step_car(agent: Dictionary, delta: float) -> void:
	if agent["turn"].is_empty():
		_plan_turn(agent)
	var turn: Dictionary = agent["turn"]
	var wanted := _wanted_speed(agent)
	if not turn.is_empty():
		var approach := clampf((float(turn["start"]) - float(agent["along"])) / TURN_APPROACH, 0.0, 1.0)
		wanted *= lerpf(float(turn["speed"]), 1.0, smoothstep(0.0, 1.0, approach))
	var distance := _drive_distance(agent, wanted, delta)
	# Consume leftover distance across every boundary, including under --turbo.
	while true:
		turn = agent["turn"]
		if turn.is_empty():
			var edge: Dictionary = _graph.edges[agent["edge"]]
			agent["along"] += distance
			if agent["along"] >= edge["length"]:
				agent["along"] -= edge["length"]
				_begin_exit(agent, _gateway_at_node[_graph.other_end(agent["edge"], agent["from"])])
			else:
				_place(agent, delta)
			return
		var remaining := maxf(0.0, float(turn["start"]) - float(agent["along"]))
		if distance < remaining:
			agent["along"] += distance
			_place(agent, delta)
			return
		agent["along"] = turn["start"]
		distance -= remaining
		var lengths: PackedFloat32Array = turn["lengths"]
		var advance := minf(distance, lengths[-1] - float(turn["distance"]))
		turn["distance"] += advance
		distance -= advance
		_place_turn(agent)
		if float(turn["distance"]) < lengths[-1]:
			return
		agent["edge"] = turn["edge"]
		agent["route_cursor"] = turn["route_cursor"]
		if agent["trip"]["loop"] and agent["route_cursor"] == 0:
			agent["laps"] += 1
		agent["from"] = turn["node"]
		agent["along"] = turn["exit"]
		agent["lateral"] = turn["lane"]
		agent["target_lateral"] = turn["lane"]
		agent["turn"] = {}
		_plan_turn(agent)
		if distance <= 0.0:
			return


# Map travelled metres back to the Bezier parameter, then use its exact tangent
# for the body heading. Parameter stepping alone would speed up mid-corner.
func _place_turn(agent: Dictionary) -> void:
	var turn: Dictionary = agent["turn"]
	var lengths: PackedFloat32Array = turn["lengths"]
	var segment := 1
	while segment < TURN_SAMPLES and lengths[segment] < float(turn["distance"]):
		segment += 1
	var fraction := clampf((float(turn["distance"]) - lengths[segment - 1]) / maxf(lengths[segment] - lengths[segment - 1], 0.0001), 0.0, 1.0)
	var t := (segment - 1 + fraction) / TURN_SAMPLES
	var start: Vector2 = turn["p0"]
	agent["pos"] = start.bezier_interpolate(turn["p1"], turn["p2"], turn["p3"], t)
	agent["heading"] = start.bezier_derivative(turn["p1"], turn["p2"], turn["p3"], t).normalized()


func _road_speed(edge: int) -> float:
	var road: int = _graph.edges[edge]["road"]
	if road < 0:
		return TrafficRules.CITY_SPEED
	var data: Dictionary = DistrictLayout.ROADS[road]
	var limit := float(data.get("speed", 1.0))
	if data["kind"] == "asphalt" and data.get("look", "") != "highway":
		limit *= TrafficRules.CITY_SPEED
	return limit


func _lane_offset(agent: Dictionary, edge: Dictionary) -> float:
	var road: Dictionary = DistrictLayout.ROADS[edge["road"]]
	var lane := TrafficRules.lane_offset(agent["class"], edge, road, agent["passing"])
	if edge["kind"] == "yard":
		# On a four-metre access road, allow opposing mirrors to clear each other.
		lane = maxf(lane, Occupancy.half_width(agent) + 0.08)
	return lane


# The road's speed, eased down to town speed approaching or leaving a junction; the
# open ends of a road (gateways) keep the full speed.
func _wanted_speed(agent: Dictionary) -> float:
	var fast := _road_speed(agent["edge"])
	if fast <= 1.0:
		return fast
	var edge: Dictionary = _graph.edges[agent["edge"]]
	var to_start: float = agent["along"]
	var to_end: float = float(edge["length"]) - to_start
	var near := INF
	for end in [[edge["a"], to_start if agent["from"] == edge["a"] else to_end], [edge["b"], to_end if agent["from"] == edge["a"] else to_start]]:
		if not _gateway_at_node.has(end[0]):
			near = minf(near, end[1])
	if near == INF:
		return fast
	return lerpf(TrafficRules.CITY_SPEED, fast, clampf((near - JUNCTION_SLOW_NEAR) / JUNCTION_SLOW_RAMP, 0.0, 1.0))


# The car reached the map edge: it carries on in a straight line into the haze.
func _begin_exit(agent: Dictionary, gateway: int) -> void:
	var gate: Dictionary = _gateways[gateway]
	agent["state"] = "out"
	agent["gateway"] = gateway
	agent["leg_from"] = gate["point"]
	agent["leg_dir"] = gate["out"]
	agent["leg_len"] = gate["leg_length"]
	_place_leg(agent, 1.0)


func _step_leg(agent: Dictionary, delta: float) -> void:
	var gate: Dictionary = _gateways[agent["gateway"]]
	agent["along"] += _drive_distance(agent, _road_speed(gate["edge"]), delta)
	if agent["along"] < agent["leg_len"]:
		_place_leg(agent, delta)
		return
	if agent["state"] == "out":
		_park(agent)
		return
	# Arrived: join the graph at the gateway, heading into town.
	agent["along"] -= agent["leg_len"]
	agent["state"] = "graph"
	agent["edge"] = gate["edge"]
	agent["from"] = gate["node"]
	_step_graph(agent, 0.0)


# Position along the straight leg; the car keeps to its right-hand lane, so the join
# with the road graph is continuous.
func _place_leg(agent: Dictionary, delta: float) -> void:
	var gate: Dictionary = _gateways[agent["gateway"]]
	var target := _lane_offset(agent, _graph.edges[gate["edge"]])
	agent["target_lateral"] = target
	agent["lateral"] = move_toward(agent["lateral"], target, 4.0 * delta)
	var heading: Vector2 = agent["leg_dir"]
	var right := Vector2(-heading.y, heading.x)
	agent["pos"] = agent["leg_from"] + heading * agent["along"] + right * agent["lateral"]
	agent["heading"] = heading


# The slot is empty now: nothing exists until it is reused.
func _park(agent: Dictionary) -> void:
	agent["state"] = "wait"
	agent["visible"] = false
	agent["wait"] = _rng.randf_range(2.0, 5.0)
	stats["exits"][_gateways[agent["gateway"]]["id"]] += 1


# A car arrives from the haze through a gateway that is busy at this hour, preferably
# not the one the previous car left by.
func _enter(agent: Dictionary) -> void:
	var choices: Array = _routes.trips[agent["stream"]]
	var trip: Dictionary = choices[_rng.randi_range(0, choices.size() - 1)]
	var vehicle_class := _stream_class(agent["stream"], agent["class"] == "bus")
	var appearance_seed := _rng.randi()
	trip = _routes.for_model(trip, VehicleModels.model_for_class(vehicle_class, appearance_seed))
	if _traffic_debug and trip.get("semi_bypass", false):
		print("SEMI bypass ", _gateways[trip["entry"]]["id"], " -> ", _gateways[trip["exit"]]["id"])
	var chosen: int = trip["entry"]
	var gate: Dictionary = _gateways[chosen]
	var spawn: Vector2 = gate["point"] + gate["out"] * gate["leg_length"]
	if not _space.nearby(spawn, 18.0).is_empty():
		agent["wait"] = 0.5
		return
	agent.erase("half_extent")
	agent.erase("returning")
	agent["changing_lane"] = false
	agent["passing"] = false
	agent["trip"] = trip
	agent["route_cursor"] = 0
	agent["turn"] = {}
	agent["gateway"] = chosen
	agent["class"] = vehicle_class
	agent["appearance_seed"] = appearance_seed
	agent["speed"] = float(agent["base_speed"]) * (0.85 if agent["class"] == "truck" else 1.0)
	agent["state"] = "in"
	agent["leg_from"] = gate["point"] + gate["out"] * gate["leg_length"]
	agent["leg_dir"] = -gate["out"]
	agent["leg_len"] = gate["leg_length"]
	agent["along"] = 0.0
	agent["speed_scale"] = _road_speed(gate["edge"])
	agent["lateral"] = _lane_offset(agent, _graph.edges[gate["edge"]])
	agent["respawned"] = true
	stats["arrivals"][gate["id"]] += 1
	_place_leg(agent, 1.0)
	_update_visibility(agent)
	_space.track(agent)

# Each pool stays on its own network: pavements/crossings for walkers, asphalt for cars.
func _usable(_is_car: bool, kinds: Array, edge: Dictionary) -> bool:
	return edge["kind"] in kinds


# Keep going; turn back only at a dead end.
func _next_edge(agent: Dictionary, node: int) -> int:
	var graph = agent["graph"]
	var options: Array[int] = []
	for candidate in graph.adjacent_edges(node):
		if candidate != agent["edge"] and _usable(agent["is_car"], agent["kinds"], graph.edges[candidate]):
			options.append(candidate)
	if options.is_empty():
		return agent["edge"]
	return _pick(options, agent["is_car"], false, graph, _workday_rng if agent.get("workday_extra", false) else null)


func _place(agent: Dictionary, delta: float) -> void:
	var graph = agent["graph"]
	var edge: Dictionary = graph.edges[agent["edge"]]
	var from: int = agent["from"]
	var start: Vector2 = graph.points[from]
	var end: Vector2 = graph.points[graph.other_end(agent["edge"], from)]
	var heading := (end - start).normalized()
	var half: float = edge["half"]
	var target: float
	if agent["is_car"]:
		target = _lane_offset(agent, edge)
	else:
		target = agent["side"] * (half + edge["walk"] / 2.0 if edge["kind"] == "asphalt" else half * 0.6)
	agent["target_lateral"] = target
	var right := Vector2(-heading.y, heading.x)
	var tangent := heading
	if agent.get("changing_lane", false):
		# The slope of this S-curve gives the actual body heading. Progress uses
		# metres travelled, so braking or stopping cannot slide the car sideways.
		var length: float = agent["change_length"]
		var t := clampf((float(agent["along"]) - float(agent["change_start"])) / length, 0.0, 1.0)
		var offset: float = target - float(agent["change_from"])
		agent["lateral"] = float(agent["change_from"]) + offset * smoothstep(0.0, 1.0, t)
		tangent = (heading + right * (offset * 6.0 * t * (1.0 - t) / length)).normalized()
		if t >= 1.0:
			agent["changing_lane"] = false
	else:
		agent["lateral"] = move_toward(agent["lateral"], target, 4.0 * delta)
	agent["pos"] = start.lerp(end, agent["along"] / maxf(edge["length"], 0.001)) + right * agent["lateral"]
	agent["heading"] = tangent


func _density(edge: Dictionary, is_car: bool, graph) -> float:
	var middle: Vector2 = (graph.points[edge["a"]] + graph.points[edge["b"]]) / 2.0
	return maxf(DistrictLayout.profile_at(middle)["cars" if is_car else "foot"], MIN_DENSITY)


# Weighted random choice among edges; the weight is the district density, times the
# edge length when picking a spawn point.
func _pick(options: Array[int], is_car: bool, by_length: bool, graph, rng: RandomNumberGenerator = null) -> int:
	var weights := PackedFloat32Array()
	var total := 0.0
	for option in options:
		var edge: Dictionary = graph.edges[option]
		var weight: float = _density(edge, is_car, graph) * (float(edge["length"]) if by_length else 1.0)
		weights.append(weight)
		total += weight
	var roll := (_rng if rng == null else rng).randf() * total
	for i in options.size():
		roll -= weights[i]
		if roll <= 0.0:
			return options[i]
	return options[options.size() - 1]


func _edge_middle(edge: int) -> Vector2:
	return (_graph.points[_graph.edges[edge]["a"]] + _graph.points[_graph.edges[edge]["b"]]) / 2.0


func _stream_class(stream: String, replacing_bus: bool = false) -> String:
	var fleet: Dictionary = TrafficFlows.STREAMS[stream]["fleet"]
	var total := 0.0
	for weight in fleet.values():
		total += weight
	var roll := _rng.randf() * total
	for vehicle_class in fleet:
		roll -= fleet[vehicle_class]
		if roll <= 0.0:
			if vehicle_class == "bus":
				# Exclude the old bus when this same slot re-enters the map.
				var bus_count := -1 if replacing_bus else 0
				for agent in agents:
					if agent["is_car"] and agent["class"] == "bus":
						bus_count += 1
				return "bus" if bus_count < MAX_BUSES else "car"
			return vehicle_class
	return "car"


# Cars stay visible for a complete trip or loop. Only gateway waiting hides them;
# pedestrian district/hour visibility is independent and retains its old behavior.
func _update_visibility(agent: Dictionary) -> void:
	if agent["is_car"]:
		agent["visible"] = agent["state"] != "wait"
		return
	if agent.get("workday_extra", false) and not DistrictLayout.workday_pedestrians_at(agent["pos"], int(hour)):
		agent["visible"] = false
		return
	var level := DistrictLayout.crowd_at(agent["pos"], int(hour), false) / CROWD_CAP
	agent["visible"] = agent["threshold"] < level

# A slice of the pool per frame is plenty: nobody changes district in a frame.
func _refresh_visibility() -> void:
	if agents.is_empty():
		return
	for i in mini(VISIBILITY_PER_FRAME, agents.size()):
		var agent := agents[_cursor % agents.size()]
		var was_visible: bool = agent["visible"]
		_update_visibility(agent)
		if not was_visible and agent["visible"] and not _space.clear_pose(agent, _space.nearby(agent["pos"], 10.0)):
			agent["visible"] = false
		_space.track(agent)
		_cursor += 1
