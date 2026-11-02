# Background pedestrians and route-driven cars. They are scenery:
# no collisions, no right of way, and they never touch the simulation or its RNG.
# This class only moves agents; CityMap owns their sprites and models.
extends RefCounted

const RoadGraph = preload("res://scripts/map/road_graph.gd")
const DistrictLayout = preload("res://scripts/data/district_layout.gd")
const TrafficFlows = preload("res://scripts/data/traffic_flows.gd")
const TrafficRoutes = preload("res://scripts/map/traffic_routes.gd")
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
const SPEED_EASE_SECONDS := 1.5 # A car takes this long to change between road speed classes.
const TURN_SAMPLES := 48
const TURN_APPROACH := 10.0

var agents: Array[Dictionary] = []
var hour := 12.0 # Clock hour, set by the view; decides who is out and about.

var stats := {"exits": {}, "arrivals": {}, "max_step": 0.0, "max_excess": 0.0, "motion_warnings": 0,
	"loops": {"city": 0, "courtyard": 0}}
var _traffic_debug := OS.get_cmdline_user_args().has("--traffic-debug")

var _graph: RoadGraph
var _gateways: Array[Dictionary] = []
var _gateway_at_node := {} # graph node -> index into _gateways
var _foot_graph := PedestrianGraph.new()
var _rng := RandomNumberGenerator.new()
var _cursor := 0
var _car_slots := 0
var _routes: TrafficRoutes


func _init(graph: RoadGraph, seed_value: int, gateways: Array[Dictionary] = []) -> void:
	_graph = graph
	_rng.seed = seed_value
	_gateways = gateways
	for i in gateways.size():
		_gateway_at_node[gateways[i]["node"]] = i
		stats["exits"][gateways[i]["id"]] = 0
		stats["arrivals"][gateways[i]["id"]] = 0
	_routes = TrafficRoutes.new(graph, gateways)


# Agents start on edges picked by length times district density, so crowded districts
# hold more of them. Cars use separately budgeted routes and fleets.
func add(is_car: bool, speed: float) -> Dictionary:
	if is_car:
		return _add_car(speed)
	var graph = _graph if is_car else _foot_graph
	var kinds: Array = CAR_KINDS if is_car else WALKER_KINDS
	var choices: Array[int] = []
	for i in graph.edges.size():
		if _usable(is_car, kinds, graph.edges[i]):
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
	return agent


func _add_car(speed: float) -> Dictionary:
	var stream := _routes.stream_for_slot(_car_slots)
	var choices: Array = _routes.trips[stream]
	# Spread the small local pools over their loops and both directions.
	var trip: Dictionary = choices[_car_slots % choices.size()]
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
	var distance := clampf(position, 0.0, total)
	var cursor := 0
	while cursor < lengths.size() - 1 and distance > lengths[cursor]:
		cursor += 1
	var leg: Dictionary = path[cursor]
	var agent := {"graph": _graph, "kinds": CAR_KINDS, "is_car": true, "speed": speed,
		"edge": leg["edge"], "from": leg["from"], "along": distance - (lengths[cursor - 1] if cursor > 0 else 0.0),
		"side": 1.0, "lateral": 0.0, "pos": Vector2.ZERO, "heading": Vector2.RIGHT, "visual": null,
		"speed_scale": _road_speed(leg["edge"]), "threshold": 0.0, "visible": true, "class": _stream_class(stream),
		"state": "graph", "gateway": trip["entry"], "leg_from": Vector2.ZERO, "leg_dir": Vector2.ZERO,
		"leg_len": 0.0, "wait": 0.0, "respawned": false, "turn": {},
		"stream": stream, "trip": trip, "route_cursor": cursor}
	agents.append(agent)
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
	_refresh_visibility()
	for agent in agents:
		var previous: Vector2 = agent["pos"]
		var previous_state: String = agent["state"]
		var previous_speed: float = agent["speed_scale"]
		match agent["state"]:
			"wait":
				agent["wait"] -= delta
				if agent["wait"] <= 0.0:
					_enter(agent)
			"out", "in":
				_step_leg(agent, delta)
			_:
				_step_graph(agent, delta)
		if _traffic_debug and agent["is_car"] and previous_state != "wait" and agent["state"] != "wait":
			var moved := previous.distance_to(agent["pos"])
			var expected: float = agent["speed"] * maxf(previous_speed, agent["speed_scale"]) * delta
			stats["max_step"] = maxf(stats["max_step"], moved)
			stats["max_excess"] = maxf(stats["max_excess"], moved - expected)
			if moved > expected + 0.05:
				stats["motion_warnings"] += 1
				if stats["motion_warnings"] <= 5:
					print("TRAFFIC MOTION: step=", moved, " expected=", expected, " state=", previous_state, "->", agent["state"], " edge=", agent["edge"])


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
		agent["edge"] = _next_edge(agent, node)
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
	var trim_out := minf(radius, float(outgoing["length"]) * 0.4)
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
	agent["speed_scale"] = move_toward(agent["speed_scale"], wanted, delta / SPEED_EASE_SECONDS)
	var distance: float = agent["speed"] * agent["speed_scale"] * delta
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
			stats["loops"][agent["stream"]] += 1
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
	return float(DistrictLayout.ROADS[road].get("speed", 1.0)) if road >= 0 else 1.0


func _lane_offset(agent: Dictionary, edge: Dictionary) -> float:
	var road: Dictionary = DistrictLayout.ROADS[edge["road"]]
	return TrafficRules.lane_offset(agent["class"], edge, road)


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
	return lerpf(1.0, fast, clampf((near - JUNCTION_SLOW_NEAR) / JUNCTION_SLOW_RAMP, 0.0, 1.0))


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
	agent["speed_scale"] = move_toward(agent["speed_scale"], _road_speed(gate["edge"]), delta / SPEED_EASE_SECONDS)
	agent["along"] += agent["speed"] * agent["speed_scale"] * delta
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
	var chosen: int = trip["entry"]
	var gate: Dictionary = _gateways[chosen]
	agent["trip"] = trip
	agent["route_cursor"] = 0
	agent["turn"] = {}
	agent["gateway"] = chosen
	agent["class"] = _stream_class(agent["stream"], agent["class"] == "bus")
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
	return _pick(options, agent["is_car"], false, graph)


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
	# Ease sideways at junctions so the change of lane is not a jump.
	agent["lateral"] = move_toward(agent["lateral"], target, 4.0 * delta)
	var right := Vector2(-heading.y, heading.x)
	agent["pos"] = start.lerp(end, agent["along"] / maxf(edge["length"], 0.001)) + right * agent["lateral"]
	agent["heading"] = heading


func _density(edge: Dictionary, is_car: bool, graph) -> float:
	var middle: Vector2 = (graph.points[edge["a"]] + graph.points[edge["b"]]) / 2.0
	return maxf(DistrictLayout.profile_at(middle)["cars" if is_car else "foot"], MIN_DENSITY)


# Weighted random choice among edges; the weight is the district density, times the
# edge length when picking a spawn point.
func _pick(options: Array[int], is_car: bool, by_length: bool, graph) -> int:
	var weights := PackedFloat32Array()
	var total := 0.0
	for option in options:
		var edge: Dictionary = graph.edges[option]
		var weight: float = _density(edge, is_car, graph) * (float(edge["length"]) if by_length else 1.0)
		weights.append(weight)
		total += weight
	var roll := _rng.randf() * total
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
	var level := DistrictLayout.crowd_at(agent["pos"], int(hour), false) / CROWD_CAP
	agent["visible"] = agent["threshold"] < level

# A slice of the pool per frame is plenty: nobody changes district in a frame.
func _refresh_visibility() -> void:
	if agents.is_empty():
		return
	for i in mini(VISIBILITY_PER_FRAME, agents.size()):
		_update_visibility(agents[_cursor % agents.size()])
		_cursor += 1
