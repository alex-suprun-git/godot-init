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

var agents: Array[Dictionary] = []
var hour := 12.0 # Clock hour, set by the view; decides who is out and about.

var _graph: RoadGraph
var _foot_graph := PedestrianGraph.new()
var _rng := RandomNumberGenerator.new()
var _cursor := 0


func _init(graph: RoadGraph, seed_value: int) -> void:
	_graph = graph
	_rng.seed = seed_value


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
		"threshold": _rng.randf(), "visible": true, "class": _vehicle_class(edge) if is_car else "",
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
		var graph = agent["graph"]
		agent["along"] += agent["speed"] * delta
		var edge: Dictionary = graph.edges[agent["edge"]]
		while agent["along"] >= edge["length"]:
			agent["along"] -= edge["length"]
			var node: int = graph.other_end(agent["edge"], agent["from"])
			agent["edge"] = _next_edge(agent, node)
			agent["from"] = node
			edge = graph.edges[agent["edge"]]
		_place(agent, delta)


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


func _vehicle_class(edge: int) -> String:
	var graph = _graph
	var middle: Vector2 = (graph.points[graph.edges[edge]["a"]] + graph.points[graph.edges[edge]["b"]]) / 2.0
	var fleet: Dictionary = DistrictLayout.profile_at(middle)["fleet"]
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
	var level := DistrictLayout.crowd_at(agent["pos"], int(hour), agent["is_car"]) / CROWD_CAP
	var shown: bool = agent["threshold"] < level
	if shown and agent["is_car"]:
		var fleet: Dictionary = DistrictLayout.profile_at(agent["pos"])["fleet"]
		shown = fleet.get(agent["class"], 0.0) > 0.04
	agent["visible"] = shown


# A slice of the pool per frame is plenty: nobody changes district in a frame.
func _refresh_visibility() -> void:
	if agents.is_empty():
		return
	for i in mini(VISIBILITY_PER_FRAME, agents.size()):
		_update_visibility(agents[_cursor % agents.size()])
		_cursor += 1
