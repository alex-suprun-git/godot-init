# Bus stops along the routes the ambient buses already drive (city loops: north street, avenue, south
# street, west street and village street; residential loops: housing spine and cross path).
# Placement logic:
#  - a stop serves a destination people walk to (department store, administration, housing blocks,
#    dormitory, village) and sits on the pavement, never on a junction or zebra (>= 25 m away);
#  - never beside a zebra: every shelter centre is at least MIN_CROSSWALK_GAP from every crosswalk centre
#    (checked by scripts/dev/check_data.gd), so the shelter, its sign and a waiting queue stay clear of it;
#  - the two directions are staggered (the stop for the opposite side stands a few metres further on),
#    so two buses never block each other and the pair does not read as one wide building;
#  - `at` is the shelter centre on the pavement, `along` the road axis ("x" or "z"), `back` the unit
#    vector from the open side to the back wall (pointing away from the carriageway).
# The station forecourt keeps its own two shelters (StationHub3D) and is not listed here.
extends RefCounted

const MIN_CROSSWALK_GAP := 15.0

const STOPS := [
	# Civic avenue (pavements at x = -18.25 and 8.25).
	{"id": "avenue_store_east", "road": "axis", "name": "Универмаг", "at": Vector2(8.25, -22.0), "along": "z", "back": Vector2(1, 0)},
	{"id": "avenue_store_west", "road": "axis", "name": "Универмаг", "at": Vector2(-18.25, -18.0), "along": "z", "back": Vector2(-1, 0)},
	{"id": "avenue_admin_east", "road": "axis", "name": "Исполком", "at": Vector2(8.25, 118.0), "along": "z", "back": Vector2(1, 0)},
	{"id": "avenue_admin_west", "road": "axis", "name": "Исполком", "at": Vector2(-18.25, 122.0), "along": "z", "back": Vector2(-1, 0)},
	# Both sides by the square and the executive committee (square z 60-84, entrance walk z 72).
	{"id": "avenue_square_east", "road": "axis", "name": "Площадь", "at": Vector2(8.25, 52.0), "along": "z", "back": Vector2(1, 0)},
	{"id": "avenue_square_west", "road": "axis", "name": "Площадь", "at": Vector2(-18.25, 56.0), "along": "z", "back": Vector2(-1, 0)},
	{"id": "avenue_south_east", "road": "axis", "name": "Южная площадь", "at": Vector2(8.25, 238.0), "along": "z", "back": Vector2(1, 0)},
	{"id": "avenue_south_west", "road": "axis", "name": "Южная площадь", "at": Vector2(-18.25, 244.0), "along": "z", "back": Vector2(-1, 0)},
	# North street (pavements at z = -91.25 and -78.75): the housing blocks.
	{"id": "north_blocks_south", "road": "north_street", "name": "Микрорайон", "at": Vector2(-110.0, -78.75), "along": "x", "back": Vector2(0, 1)},
	{"id": "north_blocks_north", "road": "north_street", "name": "Микрорайон", "at": Vector2(-98.0, -91.25), "along": "x", "back": Vector2(0, -1)},
	# West street (pavements at x = -486.25 and -473.75): the dormitory.
	{"id": "west_dorm_east", "road": "west_street", "name": "Общежитие", "at": Vector2(-473.75, 140.0), "along": "z", "back": Vector2(1, 0)},
	{"id": "west_dorm_west", "road": "west_street", "name": "Общежитие", "at": Vector2(-486.25, 150.0), "along": "z", "back": Vector2(-1, 0)},
	# South street (pavements at z = 298.75 and 311.25): the southern blocks.
	{"id": "south_blocks_north", "road": "south_street", "name": "Южные дома", "at": Vector2(-250.0, 298.75), "along": "x", "back": Vector2(0, -1)},
	{"id": "south_blocks_south", "road": "south_street", "name": "Южные дома", "at": Vector2(-238.0, 311.25), "along": "x", "back": Vector2(0, 1)},
	# Village street (pavements at x = 138.75 and 151.25): the village turn-off.
	{"id": "village_east", "road": "village_street", "name": "Посёлок", "at": Vector2(151.25, 92.0), "along": "z", "back": Vector2(1, 0)},
	{"id": "village_west", "road": "village_street", "name": "Посёлок", "at": Vector2(138.75, 98.0), "along": "z", "back": Vector2(-1, 0)},
]


# Bus routes as ordered stop lists: the stops are the waypoints. A bus drives `bus_point(stop)` to
# `bus_point(next)` along the stop's road and halts at each point; `loop` routes return from the last
# stop to the first. Every consecutive pair must follow the traffic direction (see `heading`),
# which check_data.gd verifies for the stop ids at least. Ambient buses still use the old road loops;
# switching them to these lists is the next step.
const ROUTES := {
	"1": {"name": "Кольцо", "loop": true, "stops": [
		"north_blocks_south", "village_west", "south_blocks_north", "west_dorm_east",
	]},
	"2": {"name": "Проспект", "loop": false, "stops": [
		"avenue_south_east", "avenue_admin_east", "avenue_square_east", "avenue_store_east",
		"avenue_store_west", "avenue_square_west", "avenue_admin_west", "avenue_south_west",
	]},
}
const BUS_LANE_OFFSET := 3.0 # Pavement centre to the kerb lane where the bus halts.


static func stop_by_id(id: String) -> Dictionary:
	for stop in STOPS:
		if stop["id"] == id:
			return stop
	return {}


# Travel direction of the bus that serves this stop: right-hand traffic, the pavement on its right.
static func heading(stop: Dictionary) -> Vector2:
	var back: Vector2 = stop["back"]
	return Vector2(back.y, -back.x)


# Where the bus stands: on the kerb lane in front of the shelter, level with its centre.
static func bus_point(stop: Dictionary) -> Vector2:
	return (stop["at"] as Vector2) - (stop["back"] as Vector2) * BUS_LANE_OFFSET


static func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	var ids := {}
	for stop in STOPS:
		if ids.has(stop["id"]):
			problems.append("bus stop id '%s' is used twice" % stop["id"])
		ids[stop["id"]] = true
	for route in ROUTES:
		var stops: Array = ROUTES[route]["stops"]
		if stops.size() < 2:
			problems.append("bus route '%s' needs at least two stops" % route)
		for id in stops:
			if not ids.has(id):
				problems.append("bus route '%s' names unknown stop '%s'" % [route, id])
	return problems
