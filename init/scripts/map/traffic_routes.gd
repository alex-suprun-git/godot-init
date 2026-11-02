# Resolve named itineraries against actual graph edges, including entrance splits.
extends RefCounted
const Layout = preload("res://scripts/data/district_layout.gd")
const Flows = preload("res://scripts/data/traffic_flows.gd")
const Rules = preload("res://scripts/map/traffic_rules.gd")
var trips := {}
var _graph
var _roads := {}
var _gates := {}
var _gateway_points := PackedVector2Array()

func _init(graph, gateways: Array[Dictionary]) -> void:
	_graph = graph
	for i in Layout.ROADS.size():
		_roads[Layout.ROADS[i]["id"]] = i
	for i in gateways.size():
		_gates[gateways[i]["id"]] = {"index": i, "point": gateways[i]["point"]}
		_gateway_points.append(gateways[i]["point"])
	var slots := 0
	for stream in Flows.STREAMS:
		var config: Dictionary = Flows.STREAMS[stream]
		slots += config["slots"]
		trips[stream] = []
		for spec in config.get("trips", []):
			var points: Array = [_gates[spec["entry"]]["point"]]
			var roads: Array = spec["roads"]
			for i in roads.size() - 1:
				points.append(_junction(roads[i], roads[i + 1]))
			points.append(_gates[spec["exit"]]["point"])
			trips[stream].append({"path": _path(roads, points), "loop": false,
				"entry": _gates[spec["entry"]]["index"], "exit": _gates[spec["exit"]]["index"]})
		for roads in config.get("loops", []):
			var points: Array = [_junction(roads[-1], roads[0])]
			for i in roads.size():
				points.append(_junction(roads[i], roads[(i + 1) % roads.size()]))
			var path := _path(roads, points)
			trips[stream].append({"path": path, "loop": true, "entry": -1, "exit": -1})
			var reverse: Array[Dictionary] = []
			for i in range(path.size() - 1, -1, -1):
				reverse.append({"edge": path[i]["edge"], "from": _graph.other_end(path[i]["edge"], path[i]["from"])})
			trips[stream].append({"path": reverse, "loop": true, "entry": -1, "exit": -1})
		for trip in trips[stream]:
			_validate_trip(stream, trip)
	assert(slots == Flows.CAR_COUNT, "Traffic stream slots must match the car pool")

func _validate_trip(stream: String, trip: Dictionary) -> void:
	var path: Array = trip["path"]
	if trip["loop"]:
		assert(_graph.other_end(path[-1]["edge"], path[-1]["from"]) == path[0]["from"], "Traffic loop is not closed")
	else:
		assert(_graph.points[path[0]["from"]].is_equal_approx(_gateway_points[trip["entry"]]), "Trip must start at its entry gateway")
		assert(_graph.points[_graph.other_end(path[-1]["edge"], path[-1]["from"])].is_equal_approx(_gateway_points[trip["exit"]]), "Trip must finish at its exit gateway")
	for leg in path:
		var road: Dictionary = Layout.ROADS[_graph.edges[leg["edge"]]["road"]]
		assert(road["kind"] == "asphalt" or (stream == "courtyard" and road.get("traffic", "") == "courtyard"), "Traffic itinerary includes a forbidden road")
		for vehicle in Flows.STREAMS[stream]["fleet"]:
			assert(Rules.can_use_road(vehicle, road), "Traffic fleet violates a road's vehicle restriction")

func stream_for_slot(slot: int) -> String:
	for stream in Flows.STREAMS:
		slot -= int(Flows.STREAMS[stream]["slots"])
		if slot < 0:
			return stream
	return "city"

func _junction(first: String, second: String) -> Vector2:
	var a: Rect2 = Layout.ROADS[_roads[first]]["rect"]
	var b: Rect2 = Layout.ROADS[_roads[second]]["rect"]
	assert((a.size.x > a.size.y) != (b.size.x > b.size.y), "Itinerary needs perpendicular roads")
	return Vector2(b.get_center().x, a.get_center().y) if a.size.x > a.size.y else Vector2(a.get_center().x, b.get_center().y)

func _path(roads: Array, points: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in roads.size():
		var road: int = _roads[roads[i]]
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var direction := (b - a).normalized()
		var length := a.distance_to(b)
		var candidates: Array[Dictionary] = []
		for j in _graph.edges.size():
			var edge: Dictionary = _graph.edges[j]
			if edge["road"] != road:
				continue
			var start: Vector2 = _graph.points[edge["a"]]
			var end: Vector2 = _graph.points[edge["b"]]
			var distance: float = ((start + end) * 0.5 - a).dot(direction)
			if distance > 0.0 and distance < length:
				candidates.append({"edge": j, "from": edge["a"] if (end - start).dot(direction) > 0.0 else edge["b"], "distance": distance})
		candidates.sort_custom(func(left, right): return left["distance"] < right["distance"])
		for leg in candidates:
			if not result.is_empty():
				assert(_graph.other_end(result[-1]["edge"], result[-1]["from"]) == leg["from"], "Disconnected traffic itinerary")
			result.append(leg)
	assert(not result.is_empty(), "Empty traffic itinerary")
	return result
