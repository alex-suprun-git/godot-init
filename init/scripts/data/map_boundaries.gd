# Where the playable district ends and the edge haze begins, plus the road and
# rail continuations drawn under that haze. Authored data only.
extends RefCounted

const Layout := preload("res://scripts/data/district_layout.gd")

# Everything inside stays clear; haze rises outside it. The west edge is past the forest.
const INNER := Rect2(-615, -330, 1055, 745) # x -615..440, z -330 (our bank)..415
# Fade widths in metres per side: west, north (river mist), east, south.
const FADE := {"w": 90.0, "n": 35.0, "e": 90.0, "s": 90.0}
const NOISE_AMP := 18.0 # Metres the noisy edge moves in and out.
const NOISE_SCALE := 0.012 # 1 / metres.
const CAR_LENGTH := 10.0
# The three western roads and two southern rails start here; continuations run to it.
const WEST_ROAD_START_X := -450.0
const EAST_ROAD_END_X := 440.0


static func handoff_distance(side: String) -> float:
	return FADE[side] + NOISE_AMP + CAR_LENGTH


# Far end of the western continuations: well inside the opaque haze.
static func west_far_x() -> float:
	return INNER.position.x - handoff_distance("w") - 20.0


# Far end of the eastern continuations.
static func east_far_x() -> float:
	return INNER.end.x + handoff_distance("e") + 20.0


# Road rects that carry the E-W roads on into the west and east haze.
static func road_continuations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for road in Layout.ROADS:
		var rect: Rect2 = road["rect"]
		if rect.size.x <= rect.size.y:
			continue
		if is_equal_approx(rect.position.x, WEST_ROAD_START_X):
			var far := west_far_x()
			result.append({"road": road, "rect": Rect2(far, rect.position.y, WEST_ROAD_START_X - far, rect.size.y)})
		if is_equal_approx(rect.end.x, EAST_ROAD_END_X):
			result.append({"road": road, "rect": Rect2(EAST_ROAD_END_X, rect.position.y, east_far_x() - EAST_ROAD_END_X, rect.size.y)})
	return result


# Rail segments (from, to) that carry the southern tracks west into the haze.
static func rail_continuations() -> Array[Array]:
	var result: Array[Array] = []
	for line in Layout.RAILS:
		var first: Vector2 = line[0]
		var second: Vector2 = line[1]
		if is_equal_approx(first.x, WEST_ROAD_START_X) and is_equal_approx(first.y, second.y):
			result.append([Vector2(west_far_x(), first.y), first])
	return result


# Where ambient cars leave and enter the map. "end" is which end of the road's
# centerline ("lo" = west/north, "hi" = east/south); "side" picks the haze fade.
const GATEWAYS := [
	{"id": "highway_w", "road": "highway", "end": "lo", "side": "w"},
	{"id": "highway_e", "road": "highway", "end": "hi", "side": "e"},
	{"id": "north_street_w", "road": "north_street", "end": "lo", "side": "w"},
	{"id": "north_street_e", "road": "north_street", "end": "hi", "side": "e"},
	{"id": "south_street_w", "road": "south_street", "end": "lo", "side": "w"},
	{"id": "south_street_e", "road": "south_street", "end": "hi", "side": "e"},
	{"id": "border_bridge", "road": "axis", "end": "lo", "side": "n"},
]
const NODE_TOLERANCE := 0.5
const ENTRY_SAMPLE_DISTANCE := 30.0


# Finds each gateway's terminal graph node and the one asphalt edge that leaves it.
# Entries: {id, node, edge, point, out (unit, off-map), leg_length, sample}. A gateway
# that does not resolve cleanly is reported and skipped.
static func resolve(graph) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gateway in GATEWAYS:
		var rect := Rect2()
		var found := false
		for road in Layout.ROADS:
			if road.get("id", "") == gateway["road"]:
				rect = road["rect"]
				found = true
		if not found:
			push_warning("map gateway %s: road %s not found" % [gateway["id"], gateway["road"]])
			continue
		var horizontal := rect.size.x > rect.size.y
		var lo: bool = gateway["end"] == "lo"
		var point: Vector2
		var out: Vector2
		if horizontal:
			point = Vector2(rect.position.x if lo else rect.end.x, rect.get_center().y)
			out = Vector2.LEFT if lo else Vector2.RIGHT
		else:
			point = Vector2(rect.get_center().x, rect.position.y if lo else rect.end.y)
			out = Vector2.UP if lo else Vector2.DOWN
		var node := -1
		for i in graph.points.size():
			if graph.points[i].distance_to(point) <= NODE_TOLERANCE:
				node = i
				break
		if node < 0:
			push_warning("map gateway %s: no graph node near %s" % [gateway["id"], point])
			continue
		var asphalt: Array[int] = []
		for candidate in graph.adjacent_edges(node):
			if graph.edges[candidate]["kind"] == "asphalt":
				asphalt.append(candidate)
		if asphalt.size() != 1:
			push_warning("map gateway %s: %d asphalt edges at the end node (need exactly 1)" % [gateway["id"], asphalt.size()])
			continue
		result.append({
			"id": gateway["id"], "node": node, "edge": asphalt[0], "point": point, "out": out,
			"leg_length": distance_to_clear_edge(point, out) + handoff_distance(gateway["side"]),
			"sample": point - out * ENTRY_SAMPLE_DISTANCE,
		})
	return result


# Metres from a point to the border of the clear area, going along `direction`.
static func distance_to_clear_edge(point: Vector2, direction: Vector2) -> float:
	var edge := INNER.position.x if direction.x < 0.0 else (INNER.end.x if direction.x > 0.0 else (INNER.position.y if direction.y < 0.0 else INNER.end.y))
	var here := point.x if direction.x != 0.0 else point.y
	return maxf((edge - here) * (direction.x if direction.x != 0.0 else direction.y), 0.0)


# Warns about authored content that would sit under the haze.
static func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	for id in Layout.LOTS:
		var rect: Rect2 = Layout.LOTS[id]["rect"]
		if not INNER.encloses(rect):
			problems.append("lot %s is not inside the clear map area" % id)
	for road in Layout.ROADS:
		var rect: Rect2 = road["rect"]
		if not INNER.encloses(rect):
			problems.append("road %s is not inside the clear map area" % road.get("id", str(rect)))
	return problems
