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
