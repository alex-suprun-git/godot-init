# Persistent civic lot assembled from separate meshes and seasonal planting.
extends RefCounted

const VegetationModels = preload("res://scripts/map/vegetation_models.gd")
const Settings = preload("res://scripts/data/settings.gd")
const ASSET_DIR := "res://assets/models/civic_center/"
const PLANTING_RECT := Rect2(9.5, 22, 130.5, 108)
const BUILDING_AT := Vector2(53, 72)
const DOORSTEP := Vector2(40.5, 72)
var builder
var map
var root: Node3D
var scenes := {}
var tree_positions: Array[Vector2] = []


func build(district_builder) -> void:
	builder = district_builder
	map = builder.map
	var random_state: int = map._rng.state
	root = Node3D.new()
	root.name = "CivicCenter"
	map.add_child(root)
	# Clear ceremonial forecourt, open to the avenue sidewalk (x=9.5).
	court(Rect2(9.5, 60, 32, 24))
	paving(Rect2(41.5, 55, 23.5, 42))
	asset("administration_four_storey_review", Vector3(53, 0.16, 72), -PI / 2)
	map._occupy(BUILDING_AT + Vector2(0, 4), Vector2(18, 37))
	map.sim.graph.set_doorstep("ispolkom", DOORSTEP)
	map.wear.add_disc(DOORSTEP, 6.0, 0.65)

	# Secondary memorial court reached from the main forecourt and south path.
	court(Rect2(22, 92, 18, 16))
	asset("transport_founder_monument_study", Vector3(29, 0.17, 98), -PI / 2)
	map._occupy(Vector2(29, 98), Vector2(6, 6))
	seat(Vector2(20, 58.5), 0)
	seat(Vector2(34, 58.5), 0)
	seat(Vector2(20, 85.5), PI)
	seat(Vector2(38, 101), -PI / 2)
	for z in [62.0, 82.0]:
		asset("park_planter_2m", Vector3(39.5, 0.15, z))
		bush(Vector2(39.5, z), 0.40, 2.0)

	# Compact motor court: three garage bays, four marked parking spaces, one entry.
	builder._patch(Rect2(64, 54, 27, 22), "asphalt", 0.14)
	builder._patch(Rect2(87, 48, 53, 4), "asphalt", 0.14)
	builder._patch(Rect2(87, 50, 4, 26), "asphalt", 0.14)
	asset("service_garage_review", Vector3(82, 0.15, 57))
	map._occupy(Vector2(82, 57), Vector2(12, 7))
	parking()
	for z in range(56, 80, 3):
		bush(Vector2(94, z), 0.03, 3.1)
	for x in range(66, 94, 3):
		bush(Vector2(x, 79), 0.03, 3.1)
	tree(Vector2(99, 60))
	tree(Vector2(99, 74))

	# Public garden: two planted rooms around the shared cross path and loop.
	for at in [Vector2(103, 90), Vector2(116, 90), Vector2(103, 113), Vector2(116, 113)]:
		tree(at)
	for at in [Vector2(130, 111), Vector2(130, 118), Vector2(135, 115)]:
		tree(at, "conifer")
	for at in [Vector2(93.3, 94), Vector2(93.3, 113)]:
		seat(at, PI / 2)
	seat(Vector2(125.7, 94), -PI / 2)
	seat(Vector2(111, 122), PI)
	for x in range(101, 120, 3):
		bush(Vector2(x, 87), 0.03, 2.3)
		if x < 108 or x > 114:
			bush(Vector2(x, 122), 0.03, 2.3)

	# Frame the civic spaces with planting; keep the entrance axis open.
	for at in [Vector2(22, 51), Vector2(35, 51), Vector2(17, 99), Vector2(47, 112)]:
		tree(at)
	for x in range(23, 40, 3):
		if x < 33:
			bush(Vector2(x, 89), 0.03, 2.4)
		bush(Vector2(x, 110), 0.03, 2.4)
	for z in [32.0, 52.0, 92.0, 112.0]:
		tree(Vector2(13, z), "poplar")
	for z in range(56, 129, 2):
		if absf(z - 104) < 4:
			continue
		asset("park_railing_2m", Vector3(137, 0.03, z), PI / 2)
	plant_rear_reserve()
	plant_south_buffer()
	# Local planting must not reshuffle the rest of the city's trees and traffic.
	map._rng.state = random_state


func paving(rect: Rect2) -> void:
	if Settings.season == "winter":
		map._path_quad(rect, 0.15, "paving", Color.WHITE)
		return
	map._ground_quad(rect.get_center(), rect.size, 0.15, map._season["paving"], 6.0)


func court(rect: Rect2) -> void:
	paving(rect)
	# Flush stone edging defines the court without obstructing pedestrian routes.
	for z in [rect.position.y + 0.16, rect.end.y - 0.16]:
		map._box(Vector3(rect.size.x, 0.015, 0.32), Vector3(rect.get_center().x, 0.16, z), Color("999789"), root)


func seat(at: Vector2, yaw: float) -> void:
	paving(Rect2(at - Vector2(2.2, 1.5), Vector2(4.4, 3)))
	furniture(Vector3(at.x, 0.16, at.y), yaw)


func asset(id: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	if not scenes.has(id):
		scenes[id] = load(ASSET_DIR + id + ".glb")
	var node: Node3D = scenes[id].instantiate()
	root.add_child(node)
	node.position = at
	node.rotation.y = yaw
	return node


func bush(at: Vector2, height: float, width: float) -> void:
	var node := vegetation("park_shrub", Vector3(at.x, height, at.y))
	node.scale = Vector3.ONE * width / 2.14


func tree(at: Vector2, kind: String = "deciduous") -> void:
	var id: String = {"deciduous": "park_deciduous_tree", "conifer": "park_conifer", "poplar": "park_poplar"}[kind]
	var node := vegetation(id, Vector3(at.x, 0.03, at.y))
	# Stable local variation, independent of the whole-city random sequence.
	var seed_value := int(at.x * 31 + at.y * 17)
	node.rotation.y = fposmod(seed_value * 2.399, TAU)
	node.scale = Vector3.ONE * (0.90 + posmod(seed_value, 7) * 0.035)
	map._occupy(at, Vector2(3, 3))
	tree_positions.append(at)


func plant_rear_reserve() -> void:
	# Interim grove requested by the user; detailed uses remain undecided.
	# A local generator fills the free ground without touching city-wide randomness.
	var rng := RandomNumberGenerator.new()
	rng.seed = 224218
	var layout = preload("res://scripts/data/district_layout.gd")
	var protected := [Rect2(61, 51, 34, 31), Rect2(87, 48, 53, 4).grow(2.5)]
	for road in layout.ROADS:
		protected.append(road["rect"].grow(2.5))
	for point in [Vector2(93.3, 94), Vector2(93.3, 113), Vector2(125.7, 94), Vector2(111, 122)]:
		protected.append(Rect2(point - Vector2(4, 3), Vector2(8, 6)))
	var count := 0
	for row in 13:
		for column in 9:
			var at := Vector2(68 + column * 7.8 + (3.9 if row % 2 else 0.0), 26 + row * 7.8)
			at += Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.7, 0.7))
			if at.x > 135 or at.y > 128:
				continue
			if protected.any(func(rect: Rect2) -> bool: return rect.has_point(at)):
				continue
			if tree_positions.any(func(point: Vector2) -> bool: return point.distance_to(at) < 7.2):
				continue
			if map._is_occupied(at, 2.2):
				continue
			tree(at, "conifer" if rng.randf() < 0.18 else "deciduous")
			count += 1
	print("Civic rear reserve: ", count, " additional trees")


func plant_south_buffer() -> void:
	# Fill the lawn between the memorial/square and the southern tower row.
	# Existing paths, seating, trunks and the monument court remain clear.
	var rng := RandomNumberGenerator.new()
	rng.seed = 311126
	var layout = preload("res://scripts/data/district_layout.gd")
	var protected := [Rect2(22, 92, 18, 16).grow(3.0)]
	for road in layout.ROADS:
		protected.append(road["rect"].grow(3.0))
	var count := 0
	for row in 3:
		for column in 9:
			var at := Vector2(18 + column * 8.5 + (3.5 if row % 2 else 0.0), 111.5 + row * 8.5)
			at += Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.6, 0.6))
			if protected.any(func(rect: Rect2) -> bool: return rect.has_point(at)):
				continue
			if tree_positions.any(func(point: Vector2) -> bool: return point.distance_to(at) < 7.2):
				continue
			if map._is_occupied(at, 3.0):
				continue
			tree(at, "conifer" if rng.randf() < 0.15 else "deciduous")
			count += 1
	print("Civic southern buffer: ", count, " additional trees")


func vegetation(id: String, at: Vector3) -> Node3D:
	var node := VegetationModels.create(id, at)
	root.add_child(node)
	return node


func furniture(at: Vector3, yaw: float) -> void:
	asset("park_bench", at, yaw)
	asset("park_bin", at + Vector3(1.5, 0, 0).rotated(Vector3.UP, yaw))
	var lamp_at := at + Vector3(-2.8, 0, 0).rotated(Vector3.UP, yaw)
	asset("park_lantern", lamp_at)
	map._lamp_light(lamp_at)


func parking() -> void:
	var paint := Color("b7b5a6")
	for z in [63.0, 66.0, 69.0, 72.0, 75.0]:
		map._box(Vector3(5.4, 0.012, 0.09), Vector3(71, 0.151, z), paint, root)
	map._box(Vector3(0.09, 0.012, 12), Vector3(68.3, 0.151, 69), paint, root)
	# Use the same shared factory and presentation scale as the moving vehicles.
	map._vehicle("volga", Vector3(71, 0.14, 64.5), map.VehicleModels.map_length("volga"), "x", root, map.VehicleModels.PAINT_BLACK)
	map._vehicle("lada", Vector3(71, 0.14, 70.5), map.VehicleModels.map_length("lada"), "x", root, 3)
	# A low curb closes the parking edge while keeping the north access clear.
	map._box(Vector3(0.3, 0.18, 20), Vector3(91.2, 0.23, 66), Color("9d9a8c"), root)
