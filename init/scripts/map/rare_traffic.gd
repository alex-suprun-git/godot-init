# Sparse scripted traffic on lanes that are not part of the ambient road graph:
# a one-way farm lane beside the western wheat field and the village's dirt roads.
# One car at a time per route, a long random pause between cars, no signals.
# Visual only; it never blocks or is seen by the simulation.
extends Node3D

const Vehicles := preload("res://scripts/map/vehicle_models.gd")
const FADE_METRES := 6.0 # Cars grow in and shrink out over this distance at an open end.
const CORNER_RADIUS := 4.0

# `points` are the lane centre line in map metres (x east, y = world z).
# `fade` marks ends that sit in the open instead of in the haze.
const ROUTES := [
	{
		"name": "FieldLane",
		"speed": 9.0, "wait": Vector2(45.0, 110.0), "first": 12.0,
		"fleet": ["lada", "lada_wagon", "rural_4x4", "zil_flatbed", "lada"],
		# East on the north street from the haze, north up the one-way lane, west on the highway into the haze.
		"points": [Vector2(-600, -82.5), Vector2(-502.5, -82.5), Vector2(-502.5, -192.5), Vector2(-600, -192.5)],
		"fade": [false, false],
	},
	{
		"name": "VillageThrough",
		"speed": 6.5, "wait": Vector2(70.0, 150.0), "first": 25.0,
		"fleet": ["lada", "rural_4x4", "lada_wagon", "zil_food", "lada"],
		"points": [Vector2(150, -45.5), Vector2(201.2, -45.5), Vector2(201.2, 213.5), Vector2(277.2, 213.5), Vector2(277.2, 302)],
		"fade": [true, true],
		"both_ways": true,
	},
]

var _lanes: Array[Dictionary] = []
var _serial := 0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1997
	for config in ROUTES:
		var path := _rounded(config["points"])
		_lanes.append({
			"config": config, "path": path, "length": _length(path), "rng": rng,
			"wait": float(config["first"]), "car": null, "distance": 0.0, "reverse": false,
		})


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	for lane in _lanes:
		if lane["car"] == null:
			lane["wait"] -= delta
			if lane["wait"] <= 0.0:
				_spawn(lane)
		else:
			_drive(lane, delta)


func _spawn(lane: Dictionary) -> void:
	var config: Dictionary = lane["config"]
	var rng: RandomNumberGenerator = lane["rng"]
	_serial += 1
	var fleet: Array = config["fleet"]
	var model: String = fleet[rng.randi() % fleet.size()]
	var car := Vehicles.create(model, Vector3.ZERO, Vehicles.map_length(model), "z", _serial * 7 + 3)
	car.name = "RareTraffic%d" % _serial
	add_child(car)
	lane["car"] = car
	lane["base_scale"] = car.scale
	lane["distance"] = 0.0
	lane["reverse"] = bool(config.get("both_ways", false)) and rng.randf() < 0.5
	_place(lane)


func _drive(lane: Dictionary, delta: float) -> void:
	var config: Dictionary = lane["config"]
	var distance: float = lane["distance"]
	var length: float = lane["length"]
	# Slow through the bends, like a real car on loose surface.
	var speed: float = float(config["speed"])
	lane["distance"] = distance + speed * delta
	if lane["distance"] >= length:
		lane["car"].queue_free()
		lane["car"] = null
		var rng: RandomNumberGenerator = lane["rng"]
		lane["wait"] = rng.randf_range(config["wait"].x, config["wait"].y)
		return
	_place(lane)


func _place(lane: Dictionary) -> void:
	var path: Array = lane["path"]
	var length: float = lane["length"]
	var travelled: float = lane["distance"]
	var along := length - travelled if lane["reverse"] else travelled
	var here := _point_at(path, along)
	var ahead := _point_at(path, along - 0.5 if lane["reverse"] else along + 0.5)
	var heading := ahead - here
	var car: Node3D = lane["car"]
	# Dirt lanes sit at 0.14; the cars follow the same level as parked ones.
	car.position = Vector3(here.x, 0.15, here.y)
	if heading.length_squared() > 0.0001:
		car.rotation.y = atan2(heading.x, heading.y)
	var fade := 1.0
	var fades: Array = lane["config"]["fade"]
	var start_open: bool = fades[1] if lane["reverse"] else fades[0]
	var end_open: bool = fades[0] if lane["reverse"] else fades[1]
	if start_open:
		fade = minf(fade, travelled / FADE_METRES)
	if end_open:
		fade = minf(fade, (length - travelled) / FADE_METRES)
	car.scale = lane["base_scale"] * clampf(fade, 0.02, 1.0)


# Corners get a chamfer of short segments so cars turn instead of pivoting.
func _rounded(points: Array) -> Array[Vector2]:
	var result: Array[Vector2] = [points[0]]
	for i in range(1, points.size() - 1):
		var corner: Vector2 = points[i]
		var back: Vector2 = (points[i - 1] - corner).normalized()
		var forward: Vector2 = (points[i + 1] - corner).normalized()
		var radius := minf(CORNER_RADIUS, minf(corner.distance_to(points[i - 1]), corner.distance_to(points[i + 1])) / 2.0)
		var entry := corner + back * radius
		var exit := corner + forward * radius
		for step in 7:
			var t := float(step) / 6.0
			var a := entry.lerp(corner, t)
			var b := corner.lerp(exit, t)
			result.append(a.lerp(b, t))
	result.append(points[-1])
	return result


func _length(path: Array[Vector2]) -> float:
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
	return total


func _point_at(path: Array, along: float) -> Vector2:
	var remaining := maxf(along, 0.0)
	for i in path.size() - 1:
		var segment: float = path[i].distance_to(path[i + 1])
		if remaining <= segment or i == path.size() - 2:
			return path[i].lerp(path[i + 1], clampf(remaining / maxf(segment, 0.001), 0.0, 1.0))
		remaining -= segment
	return path[-1]
