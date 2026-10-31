# Background pedestrians and cars that wander the road graph. They are scenery:
# no collisions, no right of way, and they never touch the simulation or its RNG.
# This class only moves agents; CityMap owns their sprites and models.
extends RefCounted

const RoadGraph = preload("res://scripts/map/road_graph.gd")

const WALKER_KINDS := ["asphalt", "dirt", "yard"]
const CAR_KINDS := ["asphalt"]

var agents: Array[Dictionary] = []

var _graph: RoadGraph
var _rng := RandomNumberGenerator.new()


func _init(graph: RoadGraph, seed_value: int) -> void:
	_graph = graph
	_rng.seed = seed_value


# `lane` > 0 keeps to the right of travel (cars); walkers pick a side once.
func add(is_car: bool, speed: float) -> Dictionary:
	var kinds: Array = CAR_KINDS if is_car else WALKER_KINDS
	var choices: Array[int] = []
	for i in _graph.edges.size():
		if _usable(is_car, kinds, _graph.edges[i]):
			choices.append(i)
	if choices.is_empty():
		return {}
	var edge: int = choices[_rng.randi() % choices.size()]
	var forward := _rng.randf() < 0.5
	var agent := {
		"kinds": kinds, "is_car": is_car, "speed": speed, "edge": edge,
		"from": _graph.edges[edge]["a"] if forward else _graph.edges[edge]["b"],
		"along": _rng.randf() * _graph.edges[edge]["length"],
		"side": 1.0 if is_car or _rng.randf() < 0.5 else -1.0,
		"lateral": 0.0, "pos": Vector2.ZERO, "heading": Vector2.RIGHT, "visual": null,
	}
	agents.append(agent)
	_place(agent, 1.0)
	agent["lateral"] = agent["target_lateral"]
	_place(agent, 1.0)
	return agent


func step(delta: float) -> void:
	for agent in agents:
		agent["along"] += agent["speed"] * delta
		var edge: Dictionary = _graph.edges[agent["edge"]]
		while agent["along"] >= edge["length"]:
			agent["along"] -= edge["length"]
			var node: int = _graph.other_end(agent["edge"], agent["from"])
			agent["edge"] = _next_edge(agent, node)
			agent["from"] = node
			edge = _graph.edges[agent["edge"]]
		_place(agent, delta)


# Walkers keep to pavements: an asphalt road without one (the highway) is for cars only.
func _usable(is_car: bool, kinds: Array, edge: Dictionary) -> bool:
	return edge["kind"] in kinds and (is_car or edge["kind"] != "asphalt" or edge["walk"] > 0.0)


# Keep going; turn back only at a dead end.
func _next_edge(agent: Dictionary, node: int) -> int:
	var options: Array[int] = []
	for candidate in _graph.adjacent_edges(node):
		if candidate != agent["edge"] and _usable(agent["is_car"], agent["kinds"], _graph.edges[candidate]):
			options.append(candidate)
	if options.is_empty():
		return agent["edge"]
	return options[_rng.randi() % options.size()]


func _place(agent: Dictionary, delta: float) -> void:
	var edge: Dictionary = _graph.edges[agent["edge"]]
	var from: int = agent["from"]
	var start: Vector2 = _graph.points[from]
	var end: Vector2 = _graph.points[_graph.other_end(agent["edge"], from)]
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
