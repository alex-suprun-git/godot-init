# Ambient foot traffic uses pavement centre lines and explicit zebra crossings.
# Split their intersections into a planar graph, removing unmarked road crossings.
extends RefCounted

const DistrictLayout = preload("res://scripts/data/district_layout.gd")
var points := PackedVector2Array()
var edges: Array[Dictionary] = []
var _nodes := {}
var _adjacent := {}


func _init() -> void:
	var lines: Array[Dictionary] = []
	for road in DistrictLayout.ROADS:
		var rect: Rect2 = road["rect"]
		var horizontal := rect.size.x > rect.size.y
		var a := Vector2(rect.position.x, rect.get_center().y) if horizontal else Vector2(rect.get_center().x, rect.position.y)
		var b := Vector2(rect.end.x, a.y) if horizontal else Vector2(a.x, rect.end.y)
		if road["kind"] == "asphalt":
			var walk := DistrictLayout.sidewalk_width(road)
			if walk <= 0.0:
				continue
			var half := (rect.size.y if horizontal else rect.size.x) / 2.0 + walk / 2.0
			for side in [-1.0, 1.0]:
				var shift := Vector2(0, half * side) if horizontal else Vector2(half * side, 0)
				lines.append(_line(a + shift, b + shift))
		else:
			lines.append(_line(a, b))
	for crossing in DistrictLayout.crosswalks():
		lines.append(_line(crossing["a"], crossing["b"], true))
	for line in lines:
		for other in lines:
			var hit = Geometry2D.segment_intersects_segment(line["a"], line["b"], other["a"], other["b"])
			if hit != null:
				line["cuts"].append(hit)
			# Collinear paths can overlap a zebra; their endpoints must split both.
			for point: Vector2 in [other["a"], other["b"]]:
				if point.distance_to(Geometry2D.get_closest_point_to_segment(point, line["a"], line["b"])) < 0.01:
					line["cuts"].append(point)
		var cuts: Array = line["cuts"]
		cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return line["a"].distance_squared_to(a) < line["a"].distance_squared_to(b))
		for i in cuts.size() - 1:
			var a: Vector2 = cuts[i]
			var b: Vector2 = cuts[i + 1]
			if a.distance_to(b) < 0.01 or (not line["crossing"] and _on_road((a + b) / 2.0)):
				continue
			_add_edge(a, b, line["crossing"])


func _line(a: Vector2, b: Vector2, crossing: bool = false) -> Dictionary:
	return {"a": a, "b": b, "cuts": [a, b], "crossing": crossing}


func _on_road(point: Vector2) -> bool:
	for road in DistrictLayout.ROADS:
		if road["kind"] == "asphalt" and road["rect"].has_point(point):
			return true
	return false


func _node(point: Vector2) -> int:
	var key := Vector2i(roundi(point.x * 100.0), roundi(point.y * 100.0))
	if not _nodes.has(key):
		_nodes[key] = points.size()
		points.append(point)
	return _nodes[key]


func _add_edge(a: Vector2, b: Vector2, crossing: bool) -> void:
	var from := _node(a)
	var to := _node(b)
	for index in adjacent_edges(from):
		if other_end(index, from) == to:
			return
	var index := edges.size()
	edges.append({"a": from, "b": to, "kind": "pavement", "crossing": crossing, "half": 0.0, "walk": 0.0, "length": a.distance_to(b)})
	for node in [from, to]:
		if not _adjacent.has(node):
			_adjacent[node] = []
		_adjacent[node].append(index)


func adjacent_edges(node: int) -> Array:
	return _adjacent.get(node, [])


func other_end(edge: int, node: int) -> int:
	return edges[edge]["b"] if edges[edge]["a"] == node else edges[edge]["a"]
