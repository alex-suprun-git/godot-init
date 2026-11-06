# Independent real-time shuttles, one reusable formation per dedicated track.
extends Node3D

const Layout := preload("res://scripts/data/district_layout.gd")
const Route := preload("res://scripts/map/railway_route.gd")
const ER2 := preload("res://scripts/map/er2_train.gd")
const Freight := preload("res://scripts/map/freight_train.gd")
const QUIET_WAIT := 10.0
const ER2_SPEED := 20.0
const FREIGHT_SPEED := 14.0
const LENGTH_FACTOR := 1.0359996223651116 * (4.3 / 4.37)

var _fleet: Array[Dictionary] = []
var _clock := 0.0
var _departures := 0


func _ready() -> void:
	_add_train(ER2.create(), Layout.COMMUTER_TRAIN["track_index"], ER2_SPEED, -1, 6.65)
	_add_train(Freight.create(), Layout.FREIGHT_TRAIN["track_index"], FREIGHT_SPEED, 1, 4.6)
	# The city is already alive at startup; later returns use the hidden endpoints.
	var commuter: Dictionary = _fleet[0]
	var x: float = Layout.EMBANKMENT["tracks"][commuter["track"]]
	_start(commuter)
	commuter["distance"] = commuter["route"].distance_near(Vector3(x, 6.04, 15))
	_pose(commuter)


func _add_train(model: Node3D, track: int, speed: float, direction: int, half_bogies: float) -> void:
	for previous in _fleet:
		if previous["track"] == track:
			push_error("Ambient trains require separate dedicated tracks.")
			model.free()
			return
	model.visible = false
	add_child(model)
	var cars: Array[Dictionary] = []
	for child in model.get_children():
		cars.append({"node": child, "offset": child.position.z, "flip": child.rotation.y,
			"scale": child.scale, "bogies": (4.3 if child.name == "Locomotive" else half_bogies) * LENGTH_FACTOR})
	_fleet.append({"model": model, "route": Route.new(track), "speed": speed,
		"direction": direction, "distance": 0.0, "cars": cars, "track": track,
		"running": false, "wait": QUIET_WAIT, "departures": 0, "completed": 0})


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	_clock += delta
	for train in _fleet:
		_advance_train(train, delta)


func _start(train: Dictionary) -> void:
	train["running"] = true
	train["wait"] = 0.0
	train["distance"] = 0.0 if train["direction"] > 0 else train["route"].length
	train["model"].visible = true
	train["departures"] += 1
	_departures += 1
	_pose(train)


func _advance_train(train: Dictionary, delta: float) -> void:
	# Consume transition remainders, including when dev autoplay uses a fast clock.
	var remaining := delta
	while remaining > 0.0:
		if not train["running"]:
			if remaining < float(train["wait"]):
				train["wait"] -= remaining
				return
			remaining -= float(train["wait"])
			_start(train)
		var distance_left: float = train["route"].length - float(train["distance"]) if train["direction"] > 0 else train["distance"]
		var time_left: float = distance_left / float(train["speed"])
		var step := minf(remaining, time_left)
		train["distance"] += step * float(train["speed"]) * int(train["direction"])
		_pose(train)
		remaining -= step
		if step < time_left:
			return
		# The entire train is beyond opaque haze before hiding/reversing it.
		train["model"].visible = false
		train["direction"] = -int(train["direction"])
		train["running"] = false
		train["completed"] += 1
		train["wait"] = QUIET_WAIT


func _pose(train: Dictionary) -> void:
	var route: RefCounted = train["route"]
	var direction: int = train["direction"]
	for car in train["cars"]:
		var center: float = float(train["distance"]) + direction * float(car["offset"])
		var front: Vector3 = route.sample(center + direction * float(car["bogies"]))
		var rear: Vector3 = route.sample(center - direction * float(car["bogies"]))
		var z := (front - rear).normalized()
		var x := Vector3.UP.cross(z).normalized()
		var y := z.cross(x).normalized()
		var basis := Basis(x, y, z) * Basis(Vector3.UP, float(car["flip"]))
		car["node"].transform = Transform3D(basis.scaled(car["scale"]), (front + rear) / 2.0)


func audio_emitters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in _fleet.size():
		var train: Dictionary = _fleet[i]
		var positions: Array[Vector3] = []
		for car in train["cars"]:
			positions.append(car["node"].global_position)
		result.append({"id": "er2" if i == 0 else "freight", "running": train["running"], "positions": positions})
	return result


func snapshot() -> Dictionary:
	var result := {"seconds": _clock, "active_indices": [], "departures": _departures, "trains": []}
	for i in range(_fleet.size()):
		var train: Dictionary = _fleet[i]
		if train["running"]:
			result["active_indices"].append(i)
		result["trains"].append({"name": train["model"].name, "visible": train["model"].visible,
			"track": train["track"], "direction": train["direction"], "distance": train["distance"],
			"route_length": train["route"].length, "cars": train["cars"].size(),
			"wait": train["wait"], "departures": train["departures"], "completed": train["completed"]})
	return result
