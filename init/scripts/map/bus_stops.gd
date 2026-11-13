# Basic placeholder shelters for the stops in data/bus_stops.gd: roof slab, back and end panels,
# a bench and a signpost, all boxes. Meant to be replaced by a modelled shelter later; the
# data list and the node names ("BusStop_<id>") stay.
extends RefCounted

const Stops := preload("res://scripts/data/bus_stops.gd")
const LENGTH := 4.0
const DEPTH := 1.5
const HEIGHT := 2.5
const SIDEWALK_Y := 0.15
const FRAME := Color("5d6b66")
const GLASS := Color("8fa09b")
const ROOF := Color("4a4f4c")
const BENCH := Color("8a6a46")
const SIGN := Color("2e5d8e")


func build(map) -> void:
	var root := Node3D.new()
	root.name = "BusStops"
	map.add_child(root)
	for stop in Stops.STOPS:
		var shelter := Node3D.new()
		shelter.name = "BusStop_" + String(stop["id"])
		shelter.set_meta("stop_name", stop["name"])
		shelter.add_to_group("bus_stops")
		var at: Vector2 = stop["at"]
		var back: Vector2 = stop["back"]
		shelter.position = Vector3(at.x, SIDEWALK_Y, at.y)
		# Local +X runs along the road, local +Z points to the back wall.
		shelter.rotation.y = 0.0 if stop["along"] == "x" else PI / 2.0
		if (stop["along"] == "x" and back.y < 0.0) or (stop["along"] == "z" and back.x > 0.0):
			shelter.rotation.y += PI
		root.add_child(shelter)
		_parts(map, shelter)
		map._occupy(at, Vector2(LENGTH + 2.0, DEPTH + 2.0) if stop["along"] == "x" else Vector2(DEPTH + 2.0, LENGTH + 2.0))


func _parts(map, parent: Node3D) -> void:
	map._box(Vector3(LENGTH + 0.4, 0.12, DEPTH + 0.4), Vector3(0, HEIGHT, 0), ROOF, parent)
	map._box(Vector3(LENGTH, HEIGHT - 0.3, 0.08), Vector3(0, (HEIGHT - 0.3) / 2.0, DEPTH / 2.0 - 0.04), GLASS, parent)
	for end in [-1.0, 1.0]:
		map._box(Vector3(0.08, HEIGHT - 0.3, DEPTH), Vector3(end * (LENGTH / 2.0 - 0.04), (HEIGHT - 0.3) / 2.0, 0), GLASS, parent)
		map._box(Vector3(0.1, HEIGHT, 0.1), Vector3(end * (LENGTH / 2.0 - 0.05), HEIGHT / 2.0, -DEPTH / 2.0 + 0.05), FRAME, parent)
	map._box(Vector3(LENGTH * 0.6, 0.08, 0.4), Vector3(0, 0.5, DEPTH / 2.0 - 0.3), BENCH, parent)
	for leg in [-1.0, 1.0]:
		map._box(Vector3(0.08, 0.46, 0.34), Vector3(leg * LENGTH * 0.26, 0.23, DEPTH / 2.0 - 0.3), FRAME, parent)
	# Stop sign at the front end of the shelter, on the carriageway side.
	var pole_at := Vector3(LENGTH / 2.0 + 0.8, 0, -DEPTH / 2.0 + 0.2)
	map._box(Vector3(0.07, 3.0, 0.07), pole_at + Vector3(0, 1.5, 0), FRAME, parent)
	map._box(Vector3(0.55, 0.55, 0.05), pole_at + Vector3(0, 3.1, 0), SIGN, parent)
	map._box(Vector3(0.3, 0.3, 0.06), pole_at + Vector3(0, 3.1, 0), Color("e9e6d6"), parent)
