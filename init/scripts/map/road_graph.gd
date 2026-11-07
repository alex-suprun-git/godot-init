# Road network derived from DistrictLayout. Nothing here is authored by hand:
# change ROADS or a lot's rect/facing and the graph, entrances and routes follow.
# Nodes and lengths are in map metres; x is east, the second component is south.
extends RefCounted

const DistrictLayout = preload("res://scripts/data/district_layout.gd")

# A mode is a set of allowed edge kinds plus a cost factor per kind. Speed
# belongs to the actor, not to the mode.
const MODES := {
	"foot": {"kinds": ["asphalt", "dirt", "yard", "access"], "factor": {}},
	# Courtyards are the only way to some doors; a car takes them last, at a premium.
	"car": {"kinds": ["asphalt", "dirt", "yard", "access"], "factor": {"dirt": 1.5, "yard": 3.0}},
}
const SNAP_TOLERANCE := 0.05

var points := PackedVector2Array()
var edges: Array[Dictionary] = [] # {a, b, kind, length, half, road, walk, scale}
var entrances := {} # lot id (or "bridge_road") -> node id
var doorsteps := {} # lot id -> point in front of the building door; the last leg after the entrance

var _adjacent := {} # node id -> Array[int] of edge indices
var _searches := {} # mode -> ModeSearch
var _penalties := {} # road index -> cost multiplier (>= 1)
var _cache := {}
var _node_at := {}


# A* whose edge cost is the straight distance times a per-edge factor. The
# factors live in `scales`, so a penalty never rebuilds the graph.
class ModeSearch extends AStar2D:
	var scales := {} # edge key -> factor

	func _compute_cost(from_id: int, to_id: int) -> float:
		var key := mini(from_id, to_id) * 1000000 + maxi(from_id, to_id)
		return get_point_position(from_id).distance_to(get_point_position(to_id)) * scales.get(key, 1.0)

	func _estimate_cost(from_id: int, end_id: int) -> float:
		# Factors are never below 1, so straight distance never overestimates.
		return get_point_position(from_id).distance_to(get_point_position(end_id))


func _init(lot_ids: Array) -> void:
	var segments := _centerlines()
	_add_crossings(segments)
	var links := _add_entrances(segments, lot_ids)
	_make_edges(segments)
	_make_access_edges(links)
	_make_searches()
	_validate()


# --- Public API --------------------------------------------------------------

func has_entrance(lot: String) -> bool:
	return entrances.has(lot)


func entrance_position(lot: String) -> Vector2:
	return points[entrances[lot]]


# Registers where people stand once they reach a lot's building: the route
# continues from the entrance to this point, and leaving starts by going back.
func set_doorstep(lot: String, point: Vector2) -> void:
	doorsteps[lot] = point
	_cache.clear()


# Full polyline from `from` to the lot's entrance, then on to its doorstep if
# it has one. The first point is `from`.
func route(from: Vector2, to_lot: String, mode: String) -> PackedVector2Array:
	if not entrances.has(to_lot):
		push_error("RoadGraph: no entrance for '%s'" % to_lot)
		return PackedVector2Array([from])
	var key := "%d,%d|%s|%s" % [roundi(from.x * 10.0), roundi(from.y * 10.0), to_lot, mode]
	if not _cache.has(key):
		var door_lot := _doorstep_lot(from)
		if door_lot == to_lot:
			_cache[key] = PackedVector2Array([from])
			return _cache[key]
		# Standing at a doorstep: walk back to the entrance first, then route as usual.
		var origin := entrance_position(door_lot) if door_lot != "" else from
		var path := _compute_route(origin, entrances[to_lot], mode)
		# Cut off for this mode (no road leads there): finish on foot.
		if path.size() < 2 and mode != "foot":
			path = _compute_route(origin, entrances[to_lot], "foot")
		if door_lot != "":
			path = PackedVector2Array([from]) + path
		if doorsteps.has(to_lot):
			path.append(doorsteps[to_lot])
		_cache[key] = path
	return _cache[key]


func _doorstep_lot(point: Vector2) -> String:
	for lot in doorsteps:
		if doorsteps[lot].distance_to(point) < 0.5:
			return lot
	return ""


# Remaining length of a polyline from `from`, starting at path[index].
static func length(path: PackedVector2Array, from: Vector2 = Vector2.INF, index: int = 1) -> float:
	var total := 0.0
	var last := from if from != Vector2.INF else (path[0] if path.size() > 0 else Vector2.ZERO)
	for i in range(index, path.size()):
		total += last.distance_to(path[i])
		last = path[i]
	return total


# Makes every edge of a road costlier (e.g. 1000.0 behaves like a closure) and
# drops cached routes. This is the hook for roadworks, queues and mud.
# Sideways shift from the centerline for someone travelling along `heading`: a
# walker keeps to the pavement of the asphalt road under them, a car to its lane,
# both on the right-hand side. Zero off asphalt and on roads without a pavement.
func lane_shift(point: Vector2, heading: Vector2, is_car: bool) -> Vector2:
	if heading.length_squared() < 0.0001:
		return Vector2.ZERO
	var best := INF
	var edge := {}
	for candidate in edges:
		if candidate["kind"] != "asphalt":
			continue
		var gap := point.distance_to(Geometry2D.get_closest_point_to_segment(point, points[candidate["a"]], points[candidate["b"]]))
		if gap < best:
			best = gap
			edge = candidate
	if edge.is_empty() or best > edge["half"] + 1.0:
		return Vector2.ZERO
	var right := Vector2(-heading.y, heading.x).normalized()
	if is_car:
		return right * clampf(edge["half"] * 0.35, 1.5, 4.0)
	if edge["walk"] <= 0.0:
		return Vector2.ZERO
	return right * (edge["half"] + edge["walk"] / 2.0)


func set_road_penalty(road: int, factor: float) -> void:
	_penalties[road] = maxf(factor, 1.0)
	_refresh_scales()
	_cache.clear()


func adjacent_edges(node: int) -> Array:
	return _adjacent.get(node, [])


func other_end(edge: int, node: int) -> int:
	return edges[edge]["b"] if edges[edge]["a"] == node else edges[edge]["a"]


# --- Construction ------------------------------------------------------------

# Each road rect becomes one centerline; wider than deep runs east-west.
func _centerlines() -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	for i in DistrictLayout.ROADS.size():
		var road: Dictionary = DistrictLayout.ROADS[i]
		var rect: Rect2 = road["rect"]
		var horizontal := rect.size.x > rect.size.y
		var center := rect.get_center()
		segments.append({
			"horizontal": horizontal, "kind": road["kind"], "road": i,
			"half": (rect.size.y if horizontal else rect.size.x) / 2.0,
			"walk": DistrictLayout.sidewalk_width(road),
			# lo/hi are coordinates along the running axis; `fixed` is the other one.
			"fixed": center.y if horizontal else center.x,
			"lo": rect.position.x if horizontal else rect.position.y,
			"hi": rect.end.x if horizontal else rect.end.y,
			"cuts": [],
		})
	return segments


# Crossings include T-junctions and centerlines that end inside the other
# road's rect, so a segment may grow slightly to reach the crossing.
func _add_crossings(segments: Array[Dictionary]) -> void:
	for h in segments:
		if not h["horizontal"]:
			continue
		for v in segments:
			if v["horizontal"]:
				continue
			var x: float = v["fixed"]
			var y: float = h["fixed"]
			var reach_x: float = v["half"] + 1.0
			var reach_y: float = h["half"] + 1.0
			if x >= h["lo"] - reach_x and x <= h["hi"] + reach_x and y >= v["lo"] - reach_y and y <= v["hi"] + reach_y:
				h["cuts"].append(x)
				v["cuts"].append(y)


func _point_of(segment: Dictionary, along: float) -> Vector2:
	return Vector2(along, segment["fixed"]) if segment["horizontal"] else Vector2(segment["fixed"], along)


func _along_of(segment: Dictionary, point: Vector2) -> float:
	return point.x if segment["horizontal"] else point.y


func _range_of(segment: Dictionary) -> Vector2:
	var lo: float = segment["lo"]
	var hi: float = segment["hi"]
	for cut in segment["cuts"]:
		lo = minf(lo, cut)
		hi = maxf(hi, cut)
	return Vector2(lo, hi)


# Entrance = midpoint of the lot's facing side, hooked to the nearest centerline
# by a perpendicular `access` edge.
func _add_entrances(segments: Array[Dictionary], lot_ids: Array) -> Array[Dictionary]:
	var wanted := {}
	for id in lot_ids:
		wanted[id] = _facing_point(id)
	for bridge in DistrictLayout.BRIDGES:
		if bridge["kind"] == "road":
			var rect: Rect2 = bridge["rect"]
			# The end on our bank is the southern one.
			wanted[bridge.get("entrance_id", bridge["id"])] = Vector2(rect.get_center().x, rect.end.y)
	var links: Array[Dictionary] = []
	for id in wanted:
		var entrance: Vector2 = wanted[id]
		var best := -1
		var best_distance := INF
		var best_along := 0.0
		for i in segments.size():
			var span := _range_of(segments[i])
			var along := clampf(_along_of(segments[i], entrance), span.x, span.y)
			var distance := entrance.distance_to(_point_of(segments[i], along))
			if distance < best_distance:
				best = i
				best_distance = distance
				best_along = along
		segments[best]["cuts"].append(best_along)
		links.append({"id": id, "entrance": entrance, "hook": _point_of(segments[best], best_along)})
	return links


func _facing_point(lot_id: String) -> Vector2:
	if DistrictLayout.LOTS[lot_id]["type"] == "D":
		return preload("res://scripts/data/village_sites.gd").point(lot_id,"entrance")
	if DistrictLayout.LOTS[lot_id].has("entrance"):
		return DistrictLayout.LOTS[lot_id]["entrance"]
	var lot: Dictionary = DistrictLayout.LOTS[lot_id]
	if lot.has("entrance"):
		return lot["entrance"]
	var rect: Rect2 = lot["rect"]
	var center := rect.get_center()
	match lot["facing"]:
		"n": return Vector2(center.x, rect.position.y)
		"s": return Vector2(center.x, rect.end.y)
		"e": return Vector2(rect.end.x, center.y)
	return Vector2(rect.position.x, center.y)


func _make_edges(segments: Array[Dictionary]) -> void:
	for segment in segments:
		var stops: Array[float] = [segment["lo"], segment["hi"]]
		for cut in segment["cuts"]:
			stops.append(cut)
		stops.sort()
		for i in stops.size() - 1:
			if stops[i + 1] - stops[i] > 0.01:
				_add_edge(_node(_point_of(segment, stops[i])), _node(_point_of(segment, stops[i + 1])),
					segment["kind"], segment["half"], segment["road"], segment["walk"])


func _make_access_edges(links: Array[Dictionary]) -> void:
	for link in links:
		var hook := _node(link["hook"])
		if link["entrance"].distance_to(link["hook"]) <= SNAP_TOLERANCE:
			entrances[link["id"]] = hook
			continue
		var node := _node(link["entrance"])
		_add_edge(node, hook, "access", 1.0, -1, 0.0)
		entrances[link["id"]] = node


func _node(point: Vector2) -> int:
	var key := Vector2i(roundi(point.x * 10.0), roundi(point.y * 10.0))
	if not _node_at.has(key):
		_node_at[key] = points.size()
		points.append(point)
	return _node_at[key]


func _add_edge(a: int, b: int, kind: String, half: float, road: int, walk: float) -> void:
	edges.append({"a": a, "b": b, "kind": kind, "half": half, "road": road, "walk": walk,
		"length": points[a].distance_to(points[b]), "scale": 1.0})
	var index := edges.size() - 1
	for node in [a, b]:
		if not _adjacent.has(node):
			_adjacent[node] = []
		_adjacent[node].append(index)


func _make_searches() -> void:
	for mode in MODES:
		var search := ModeSearch.new()
		for i in points.size():
			search.add_point(i, points[i])
		for edge in edges:
			if edge["kind"] in MODES[mode]["kinds"]:
				search.connect_points(edge["a"], edge["b"], true)
		_searches[mode] = search
	_refresh_scales()


func _refresh_scales() -> void:
	for mode in _searches:
		var scales: Dictionary = _searches[mode].scales
		for edge in edges:
			var factor: float = MODES[mode]["factor"].get(edge["kind"], 1.0) * _penalties.get(edge["road"], 1.0)
			scales[_key(edge["a"], edge["b"])] = factor


func _key(a: int, b: int) -> int:
	return mini(a, b) * 1000000 + maxi(a, b)


# Everything must be reachable on foot (an error); by car a lot may be cut off,
# for example a clearing that only a yard path leads to (a warning: `route`
# then falls back to walking).
func _validate() -> void:
	for mode in MODES:
		var root := -1
		var most := -1
		for id in entrances:
			var reached := 0
			for other in entrances:
				if not _searches[mode].get_id_path(entrances[id], entrances[other]).is_empty():
					reached += 1
			if reached > most:
				most = reached
				root = entrances[id]
		for id in entrances:
			if _searches[mode].get_id_path(root, entrances[id]).is_empty():
				var message := "RoadGraph: '%s' is not reachable in mode '%s'" % [id, mode]
				if mode == "foot":
					push_error(message)
				else:
					push_warning(message)


# --- Routing -----------------------------------------------------------------

func _compute_route(from: Vector2, target: int, mode: String) -> PackedVector2Array:
	var search: ModeSearch = _searches[mode]
	var snap := _snap(from, mode)
	if snap.is_empty():
		return PackedVector2Array([from])
	var best_ids: PackedInt64Array
	var best_cost := INF
	var best_start := Vector2.ZERO
	for node in snap["nodes"]:
		var ids := search.get_id_path(node, target)
		if ids.is_empty():
			continue
		var cost: float = snap["point"].distance_to(points[node]) * snap["scale"] + _cost(search, ids)
		if cost < best_cost:
			best_cost = cost
			best_ids = ids
			best_start = snap["point"]
	var path := PackedVector2Array([from])
	if best_cost == INF:
		push_warning("RoadGraph: no %s route from %s" % [mode, from])
		return path
	if best_start.distance_to(from) > SNAP_TOLERANCE:
		path.append(best_start)
	for id in best_ids:
		if path[path.size() - 1].distance_to(points[id]) > SNAP_TOLERANCE:
			path.append(points[id])
	return path


# Nearest point on any edge this mode may use. A temporary start: the cached
# graph is never changed. Returns the node(s) the walker may leave through.
func _snap(from: Vector2, mode: String) -> Dictionary:
	var best_distance := INF
	var best := {}
	for i in edges.size():
		var edge: Dictionary = edges[i]
		if not (edge["kind"] in MODES[mode]["kinds"]):
			continue
		var a := points[edge["a"]]
		var b := points[edge["b"]]
		var projected := Geometry2D.get_closest_point_to_segment(from, a, b)
		var distance := from.distance_to(projected)
		if distance < best_distance:
			best_distance = distance
			var nodes: Array[int] = [edge["a"], edge["b"]]
			if projected.distance_to(a) <= SNAP_TOLERANCE:
				nodes = [edge["a"]]
			elif projected.distance_to(b) <= SNAP_TOLERANCE:
				nodes = [edge["b"]]
			best = {"point": projected, "nodes": nodes,
				"scale": _searches[mode].scales.get(_key(edge["a"], edge["b"]), 1.0)}
	return best


func _cost(search: ModeSearch, ids: PackedInt64Array) -> float:
	var total := 0.0
	for i in ids.size() - 1:
		total += search._compute_cost(ids[i], ids[i + 1])
	return total
