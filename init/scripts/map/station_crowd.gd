# Local ambient scenery: deliberately confined to pedestrian areas of the hub.
# It does not create simulation residents, requests or pathfinding agents.
extends Node3D

var map
var _people: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

func build(city_map) -> void:
	map = city_map
	name = "StationLocalCrowd"
	_rng.seed = 19970825
	# Shoppers stop beside counters; walking lanes remain a little further out.
	for row in range(4):
		for column in range(0, 14, 2):
			var at := Vector2(-147 + column * 3.9 + _rng.randf_range(-.45, .45),
				354.5 + row * 7.0 + _rng.randf_range(1.8, 2.1))
			_person(at, .052)
		for i in range(3):
			var z := 357.7 + row * 7.0 + i * .16
			_walker(Vector2(-149, z), Vector2(-94, z), .052)
	# Two small waiting groups, on the island and behind the bus boarding kerb.
	for x in [-104.0, -80.0]:
		for i in range(5):
			_person(Vector2(x - 1.8 + i * .85, 339.0 + _rng.randf_range(-.22, .22)), .25)
	# Meet-and-greet groups on the apron, clear of the central stair/through path.
	for x in [-79.0, -75.0, -71.5, -58.0, -54.0, -49.5]:
		_person(Vector2(x, 364.5 + _rng.randf_range(-.6, .6)), .19)
	_person(Vector2(-77, 366.4), .19)
	_person(Vector2(-52, 366.4), .19)
	# Stay well behind the safety stripe; never wander onto either track.
	for x in [-125.0, -107.0, -79.0, -53.0]:
		_person(Vector2(x, 388.0 + _rng.randf_range(-.3, .3)), 1.29)
	for i in range(4):
		var z := 386.7 + i * .32
		_walker(Vector2(-132, z), Vector2(-44, z), 1.29)
	print("Station local crowd: ", _people.size(), " ambient people")

# `kind` picks a look from map.PEOPLE (-1: random); `hours` limits when the person is out (x..y, clock hours).
func _person(at: Vector2, floor_height: float, kind := -1, hours := Vector2.ZERO) -> Dictionary:
	var look: Dictionary = map.PEOPLE[_rng.randi_range(0, map.PEOPLE.size() - 1) if kind < 0 else kind]
	var sprite: Sprite3D = map._sprite(look["texture"], Vector3(at.x, floor_height, at.y),
		look["width"], self, _rng.randf() < .5)
	var person := {"sprite": sprite, "from": at, "to": at, "floor": floor_height,
		"progress": 0.0, "speed": _rng.randf_range(.55, .95), "wait": _rng.randf_range(2, 12),
		"threshold": _rng.randf(), "anchor": map._anchor_of(look["texture"]), "hours": hours}
	_people.append(person)
	return person

func _walker(from: Vector2, to: Vector2, floor_height: float, kind := -1, hours := Vector2.ZERO) -> void:
	var person := _person(from, floor_height, kind, hours)
	person["to"] = to
	person["progress"] = _rng.randf()
	person["wait"] = _rng.randf_range(0, 3)
	_place(person)

func _process(delta: float) -> void:
	if map == null or map.sim == null:
		return
	delta *= map.ambient_motion_scale
	var hour: float = map._debug_hour if map._debug_hour >= 0.0 else map.sim.clock_hour() # --hour pins it for checks
	if map._debug_hour < 0.0 and not map.scenario_traffic.is_empty():
		hour = map.visual_clock_hour()
	var density := .25 if hour < 6.0 or hour >= 22.0 else 1.0
	density *= float(map.scenario_traffic.get("station_crowd", 1.0))
	for person in _people:
		var sprite: Sprite3D = person["sprite"]
		var hours: Vector2 = person.get("hours", Vector2.ZERO)
		var in_hours := hours == Vector2.ZERO or (hour >= hours.x and hour < hours.y)
		sprite.visible = in_hours and float(person["threshold"]) < density
		if person["from"] == person["to"]:
			continue
		if float(person["wait"]) > 0:
			person["wait"] -= delta
			continue
		var length: float = person["from"].distance_to(person["to"])
		person["progress"] += delta * float(person["speed"]) / maxf(length, .01)
		if float(person["progress"]) >= 1.0:
			var previous: Vector2 = person["from"]
			person["from"] = person["to"]
			person["to"] = previous
			person["progress"] = 0.0
			person["wait"] = _rng.randf_range(3, 14)
		_place(person)

func _place(person: Dictionary) -> void:
	var at: Vector2 = person["from"].lerp(person["to"], float(person["progress"]))
	var sprite: Sprite3D = person["sprite"]
	sprite.position = Vector3(at.x, person["floor"], at.y)
	var heading: Vector2 = person["to"] - person["from"]
	var right: Vector3 = map._view_right()
	sprite.flip_h = heading.x * right.x + heading.y * right.z < 0
	var anchor: Vector2 = person["anchor"]
	var anchor_x := 1.0 - anchor.x if sprite.flip_h else anchor.x
	sprite.offset.x = -anchor_x * sprite.texture.get_width()
