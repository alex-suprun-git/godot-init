# Background pedestrians and cars wandering pavement and road graphs. They are scenery:
# no collisions, no right of way, and they never touch the simulation or its RNG.
# This class only moves agents; CityMap owns their sprites and models.
extends RefCounted

const RoadGraph = preload("res://scripts/map/road_graph.gd")
const DistrictLayout = preload("res://scripts/data/district_layout.gd")

const PedestrianGraph = preload("res://scripts/map/pedestrian_graph.gd")
const WALKER_KINDS := ["pavement"]
const CAR_KINDS := ["asphalt"]
# A district's density of 2.0 at its busiest hour shows every agent standing there; the
# pool is sized so that a typical place (1.0) shows about half of them.
const CROWD_CAP := 2.0
const MIN_DENSITY := 0.02
const VISIBILITY_PER_FRAME := 48
# Fast roads slow to town speed at junctions: full town speed within SLOW_NEAR metres
# of the junction, rising to the road's speed over the next SLOW_RAMP metres.
const JUNCTION_SLOW_NEAR := 12.0
const JUNCTION_SLOW_RAMP := 50.0
const SPEED_EASE_SECONDS := 1.5 # A car takes this long to change between road speed classes.

var agents: Array[Dictionary] = []
var hour := 12.0 # Clock hour, set by the view; decides who is out and about.

var stats := {"exits": {}, "arrivals": {}} # Per gateway id; read by the --traffic-debug print.

var _graph: RoadGraph
var _gateways: Array[Dictionary] = []
var _gateway_at_node := {} # graph node -> index into _gateways
var _foot_graph := PedestrianGraph.new()
var _rng := RandomNumberGenerator.new()
var _cursor := 0


func _init(graph: RoadGraph, seed_value: int, gateways: Array[Dictionary] = []) -> void:
	_graph = graph
	_rng.seed = seed_value
	_gateways = gateways
	for i in gateways.size():
		_gateway_at_node[gateways[i]["node"]] = i
		stats["exits"][gateways[i]["id"]] = 0
		stats["arrivals"][gateways[i]["id"]] = 0


# Agents start on edges picked by length times district density, so crowded districts
# hold more of them. Cars also get a vehicle class from the district's fleet mix.
func add(is_car: bool, speed: float) -> Dictionary:
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
		"speed_scale": 1.0, "threshold": _rng.randf(), "visible": true, "class": _fleet_class(_edge_middle(edge)) if is_car else "",
		# Cars only: "graph" (on the roads), "out" (driving into the haze), "wait" (a slot
		# with no car on the map) or "in" (arriving from the haze). Walkers stay "graph".
		"state": "graph", "gateway": -1, "leg_from": Vector2.ZERO, "leg_dir": Vector2.ZERO,
		"leg_len": 0.0, "wait": 0.0, "respawned": false,
	}
	agents.append(agent)
	_place(agent, 1.0)
	agent["lateral"] = agent["target_lateral"]
	_place(agent, 1.0)
	_update_visibility(agent)
	return agent


func step(delta: float) -> void:
	_refresh_visibility()
	for agent in agents:
		match agent["state"]:
			"wait":
				agent["wait"] -= delta
				if agent["wait"] <= 0.0:
					_enter(agent)
			"out", "in":
				_step_leg(agent, delta)
			_:
				_step_graph(agent, delta)


func _step_graph(agent: Dictionary, delta: float) -> void:
	var graph = agent["graph"]
	var edge: Dictionary = graph.edges[agent["edge"]]
	if agent["is_car"]:
		# Highways run faster than town streets; ease so a turn does not jerk the car.
		agent["speed_scale"] = move_toward(agent["speed_scale"], _wanted_speed(agent), delta / SPEED_EASE_SECONDS)
	agent["along"] += agent["speed"] * agent["speed_scale"] * delta
	while agent["along"] >= edge["length"]:
		agent["along"] -= edge["length"]
		var node: int = graph.other_end(agent["edge"], agent["from"])
		if agent["is_car"] and _gateway_at_node.has(node):
			_begin_exit(agent, _gateway_at_node[node])
			return
		agent["edge"] = _next_edge(agent, node)
		agent["from"] = node
		edge = graph.edges[agent["edge"]]
	_place(agent, delta)


func _road_speed(edge: int) -> float:
	var road: int = _graph.edges[edge]["road"]
	return float(DistrictLayout.ROADS[road].get("speed", 1.0)) if road >= 0 else 1.0


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
	var half: float = _graph.edges[gate["edge"]]["half"]
	var target := clampf(half * 0.35, 1.5, 4.0)
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
	var weights := PackedFloat32Array()
	var total := 0.0
	var other_total := 0.0
	for i in _gateways.size():
		var weight: float = DistrictLayout.crowd_at(_gateways[i]["sample"], int(hour), true)
		weights.append(weight)
		total += weight
		if i != agent["gateway"]:
			other_total += weight
	if other_total > 0.0:
		weights[agent["gateway"]] = 0.0
		total = other_total
	if total <= 0.0:
		agent["wait"] = 1.0
		return
	var roll := _rng.randf() * total
	var chosen := weights.size() - 1
	for i in weights.size():
		roll -= weights[i]
		if roll <= 0.0 and weights[i] > 0.0:
			chosen = i
			break
	var gate: Dictionary = _gateways[chosen]
	agent["gateway"] = chosen
	agent["class"] = _fleet_class(gate["sample"])
	agent["threshold"] = _rng.randf()
	agent["state"] = "in"
	agent["leg_from"] = gate["point"] + gate["out"] * gate["leg_length"]
	agent["leg_dir"] = -gate["out"]
	agent["leg_len"] = gate["leg_length"]
	agent["along"] = 0.0
	agent["speed_scale"] = _road_speed(gate["edge"])
	agent["lateral"] = clampf(float(_graph.edges[gate["edge"]]["half"]) * 0.35, 1.5, 4.0)
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
		target = clampf(half * 0.35, 1.5, 4.0)
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


func _fleet_class(point: Vector2) -> String:
	var fleet: Dictionary = DistrictLayout.profile_at(point)["fleet"]
	var total := 0.0
	for weight in fleet.values():
		total += weight
	var roll := _rng.randf() * total
	for vehicle_class in fleet:
		roll -= fleet[vehicle_class]
		if roll <= 0.0:
			return vehicle_class
	return "car"


# Someone is out if their personal threshold is below the crowd level of the spot they
# are at right now (district density times the hour profile); a vehicle class that the
# district does not run (a truck among panel blocks) stays out of sight.
func _update_visibility(agent: Dictionary) -> void:
	if agent["state"] == "wait":
		agent["visible"] = false
		return
	# On a leg the car is outside the districts: judge it where the gateway meets the map.
	var at: Vector2 = agent["pos"] if agent["state"] == "graph" else _gateways[agent["gateway"]]["sample"]
	var level := DistrictLayout.crowd_at(at, int(hour), agent["is_car"]) / CROWD_CAP
	var shown: bool = agent["threshold"] < level
	if shown and agent["is_car"]:
		var fleet: Dictionary = DistrictLayout.profile_at(at)["fleet"]
		shown = fleet.get(agent["class"], 0.0) > 0.04
	agent["visible"] = shown


# A slice of the pool per frame is plenty: nobody changes district in a frame.
func _refresh_visibility() -> void:
	if agents.is_empty():
		return
	for i in mini(VISIBILITY_PER_FRAME, agents.size()):
		_update_visibility(agents[_cursor % agents.size()])
		_cursor += 1
