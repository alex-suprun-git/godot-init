# Extra background pedestrians for the busy places: the civic avenue, the department store,
# the House of Culture, the public garden walks, the market surroundings and the station
# platform. Scenery only, like the station crowd it extends: it creates no residents,
# requests or pathfinding agents, and thins out at night.
extends "res://scripts/map/station_crowd.gd"

const Layout = preload("res://scripts/data/district_layout.gd")
const AVENUE_WALKS := [-18.25, 8.25] # Centres of the two avenue pavements (road edge +- 1.25 m).
const AVENUE_FROM := -165.0
const AVENUE_TO := 292.0
const PLATFORM_FLOOR := 1.29


func build(city_map) -> void:
	map = city_map
	name = "StreetCrowd"
	_rng.seed = 19971987
	_avenue()
	_civic_walks()
	_entrance_groups()
	_market_surroundings()
	_platform()
	_bus_stop_queues()
	print("Street crowd: ", _people.size(), " ambient people")


# Short back-and-forth beats spread along both pavements, with a few standing pairs.
func _avenue() -> void:
	for x in AVENUE_WALKS:
		var z := AVENUE_FROM + _rng.randf_range(0.0, 8.0)
		while z < AVENUE_TO:
			var length := _rng.randf_range(10.0, 26.0)
			var lane: float = x + _rng.randf_range(-0.55, 0.55)
			var a := Vector2(lane, z)
			var b := Vector2(lane + _rng.randf_range(-0.2, 0.2), z + length)
			if _rng.randf() < 0.28:
				_person(a, map._ground(a).y)
				_person(a + Vector2(0.0, 0.9), map._ground(a).y)
			else:
				_walk(a, b)
			z += length + _rng.randf_range(4.0, 11.0)


# Public walks beside the store, the culture house and the administration garden.
func _civic_walks() -> void:
	for road in Layout.ROADS:
		var id: String = road["id"]
		if road["kind"] != "yard" or not (id.begins_with("civic_") or id.begins_with("culture_")):
			continue
		var rect: Rect2 = road["rect"]
		var along_x := rect.size.x > rect.size.y
		var length := maxf(rect.size.x, rect.size.y)
		var centre := rect.get_center()
		var count := clampi(int(length / 18.0), 1, 7)
		for i in count:
			var start := (float(i) + _rng.randf()) / count * length - length / 2.0
			var span := minf(_rng.randf_range(8.0, 22.0), length - 1.0)
			start = clampf(start, -length / 2.0, length / 2.0 - span)
			var jitter := _rng.randf_range(-0.6, 0.6)
			var a := centre + (Vector2(start, jitter) if along_x else Vector2(jitter, start))
			var b := a + (Vector2(span, 0.0) if along_x else Vector2(0.0, span))
			_walk(a, b)
		if length > 24.0:
			var spot := centre + (Vector2(_rng.randf_range(-length / 3.0, length / 3.0), 0.0) if along_x else Vector2(0.0, _rng.randf_range(-length / 3.0, length / 3.0)))
			_person(spot, map._ground(spot).y)


# Queues and loiterers at the doors people actually use.
func _entrance_groups() -> void:
	# Department store (west-facing), House of Culture and the administration steps.
	for spot in [Vector2(6.8, 13.0), Vector2(7.6, 16.5), Vector2(6.4, 19.5), Vector2(8.0, 8.5), Vector2(7.2, 24.0)]:
		_person(spot + Vector2(_rng.randf_range(-.3, .3), _rng.randf_range(-.3, .3)), map._ground(spot).y)
	for spot in [Vector2(29.0, -44.0), Vector2(28.0, -41.5), Vector2(31.0, -38.5), Vector2(27.2, -36.0), Vector2(26.0, -46.0)]:
		_person(spot + Vector2(_rng.randf_range(-.3, .3), _rng.randf_range(-.3, .3)), map._ground(spot).y)
	for spot in [Vector2(24.0, 70.0), Vector2(22.0, 73.5), Vector2(26.5, 68.0), Vector2(20.0, 66.5)]:
		_person(spot, map._ground(spot).y)


# South street pavements, the strip along the market lot and the bus-stop forecourt.
func _market_surroundings() -> void:
	for z in [298.8, 311.3]:
		var x := -205.0 + _rng.randf_range(0.0, 6.0)
		while x < 4.0:
			var length := _rng.randf_range(10.0, 24.0)
			var a := Vector2(x, z + _rng.randf_range(-0.4, 0.4))
			_walk(a, a + Vector2(length, _rng.randf_range(-0.15, 0.15)))
			x += length + _rng.randf_range(5.0, 12.0)
	for x in [-150.0, -138.0, -121.0, -100.0, -80.0, -62.0, -44.0, -30.0]:
		var spot := Vector2(x + _rng.randf_range(-1.0, 1.0), 314.2)
		_person(spot, map._ground(spot).y)
	for i in 5:
		var z := 313.4 + i * 0.35
		_walk(Vector2(-152.0, z), Vector2(-26.0, z))


# More waiting commuters on the platform, behind the safety stripe, plus a few strollers.
func _platform() -> void:
	for x in [-137.0, -131.0, -118.0, -112.0, -98.0, -90.0, -72.0, -64.0, -47.0, -41.0]:
		_person(Vector2(x + _rng.randf_range(-.5, .5), 385.4 + _rng.randf_range(-.2, .2)), PLATFORM_FLOOR)
	for x in [-126.0, -86.0, -58.0]:
		_person(Vector2(x, 390.0), PLATFORM_FLOOR)
		_person(Vector2(x + 0.9, 390.1), PLATFORM_FLOOR)
	for i in 3:
		var z := 385.0 + i * 0.35
		_walk(Vector2(-136.0 + i * 7.0, z), Vector2(-60.0 + i * 8.0, z), PLATFORM_FLOOR)


func _walk(from: Vector2, to: Vector2, floor_height := -1.0) -> void:
	var height: float = map._ground(from).y if floor_height < 0.0 else floor_height
	_walker(from, to, height)


# Two or three people waiting in front of every shelter, in the open side of the pavement.
func _bus_stop_queues() -> void:
	for stop in preload("res://scripts/data/bus_stops.gd").STOPS:
		var at: Vector2 = stop["at"]
		var axis := Vector2(1, 0) if stop["along"] == "x" else Vector2(0, 1)
		var front: Vector2 = -stop["back"] * 0.15
		for i in _rng.randi_range(2, 3):
			var spot := at + axis * (i - 1) * 0.9 + front + Vector2(_rng.randf_range(-.2, .2), _rng.randf_range(-.2, .2))
			_person(spot, map._ground(spot).y + 0.0)
