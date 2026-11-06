# One signal clock per junction, shared by lamps, drivers and pedestrians.
extends RefCounted

enum { EW_GREEN, EW_AMBER, CLEAR_EW, NS_GREEN, NS_AMBER, CLEAR_NS, WALK, CLEAR_WALK }
const SECONDS := [20.0, 3.0, 2.0, 20.0, 3.0, 2.0, 9.0, 2.0]
var phase := EW_GREEN
var elapsed := 0.0
var waiting := {}
var inside := {}
var cleared := 0
var concurrent_peak := 0
var mixed_entries := 0
var cleared_by_approach := {}
var walking := 0
var pedestrian_entries := 0
var crossings_clear := true
var stall_reported := false

func advance(delta: float) -> void:
	elapsed += delta
	if elapsed < SECONDS[phase]:
		return
	if phase in [CLEAR_EW, CLEAR_NS] and not inside.is_empty():
		return
	if phase == CLEAR_NS and not crossings_clear:
		return
	if phase == CLEAR_WALK and walking > 0:
		return
	stall_reported = false
	phase = (phase + 1) % SECONDS.size()
	elapsed = 0.0


func vehicle_color(horizontal: bool) -> String:
	if phase == (EW_GREEN if horizontal else NS_GREEN):
		return "green"
	if phase == (EW_AMBER if horizontal else NS_AMBER):
		return "amber"
	return "red"


func _compatible(a: Dictionary, b: Dictionary) -> bool:
	var direction: Vector2 = a["in"]
	var other: Vector2 = b["in"]
	if direction == other:
		if a["lane"] == b["lane"]:
			return true # A following driver still obeys the bumper gap.
		if a["out"] == b["out"]:
			return a["out"] == direction # Parallel straights, or a conflicting merge.
		# The inner lane may turn left and the outer lane may turn right.
		var inner := a if float(a["lane"]) < float(b["lane"]) else b
		var outer := b if is_same(inner, a) else a
		return direction.cross(inner["out"]) <= 0.0 and direction.cross(outer["out"]) >= 0.0
	if a["out"] == b["out"]:
		return false
	if direction == -other:
		return direction.cross(a["out"]) >= 0.0 and other.cross(b["out"]) >= 0.0
	return direction.cross(a["out"]) > 0.0 and other.cross(b["out"]) > 0.0


func request(slot: int, maneuver: Dictionary, gap: float) -> float:
	waiting[slot] = maneuver
	var direction: Vector2 = maneuver["in"]
	if vehicle_color(direction.x != 0.0) != "green":
		return gap
	for active: Dictionary in inside.values():
		if not _compatible(active, maneuver):
			return maxf(gap, 0.0)
	if gap <= 2.0:
		var straight: bool = maneuver["in"] == maneuver["out"]
		for active: Dictionary in inside.values():
			if straight != (active["in"] == active["out"]):
				mixed_entries += 1
				break
		inside[slot] = maneuver
		waiting.erase(slot)
		concurrent_peak = maxi(concurrent_peak, inside.size())
	return INF


func release(slot: int) -> void:
	var direction: Vector2 = inside[slot]["in"]
	cleared_by_approach[direction] = cleared_by_approach.get(direction, 0) + 1
	inside.erase(slot)
	cleared += 1
