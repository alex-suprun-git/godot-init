# Connected public garden around the DK, department store and administration.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Surfaces = preload("res://scripts/map/station_surfaces.gd")
const BENCH = preload("res://assets/models/civic_center/park_bench.glb")
const LAMP = preload("res://assets/models/civic_center/park_lantern.glb")
const WALK_IDS := ["store_north_walk", "store_south_walk", "civic_public_spine", "culture_garden_walk", "civic_garden_crosswalk", "civic_east_garden_walk", "culture_walk"]

var map
var root: Node3D


func build(city_map) -> void:
	map = city_map
	root = Node3D.new()
	root.name = "CivicPublicGarden"
	map.add_child(root)
	for road in Layout.ROADS:
		if road["id"] in WALK_IDS:
			Surfaces.surface(root, road["rect"], .15, 1)
	_seating()
	_planting()


func _seating() -> void:
	for z in [-13.0, 20.0, 36.0]:
		var pad := Rect2(47, z - 1.8, 6, 3.6)
		Surfaces.surface(root, pad, .15, 1)
		map._occupy(pad.get_center(), pad.size)
		var bench: Node3D = BENCH.instantiate()
		bench.position = Vector3(50.5, .15, z)
		bench.rotation.y = -PI / 2.0
		root.add_child(bench)
		var lamp: Node3D = LAMP.instantiate()
		lamp.position = Vector3(49.5, .15, z - 2.8)
		root.add_child(lamp)
	for at in [Vector2(69, -19), Vector2(71, 14), Vector2(18, -4)]:
		var lamp: Node3D = LAMP.instantiate()
		lamp.position = Vector3(at.x, .15, at.y)
		root.add_child(lamp)


func _planting() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 311130
	var paths: Array[Rect2] = []
	for road in Layout.ROADS:
		paths.append(road["rect"].grow(3.0))
	# The composed DK forecourt/service surfaces are also kept open.
	paths.append(Rect2(28, -58, 10, 34).grow(2.0))
	paths.append(Rect2(62, -57, 8, 32).grow(2.0))
	var planted: Array[Vector2] = []
	for row in 14:
		for column in 9:
			var at := Vector2(16 + column * 8.0 + (3.0 if row % 2 else 0.0), -73 + row * 8.0)
			at += Vector2(rng.randf_range(-.65, .65), rng.randf_range(-.65, .65))
			if at.x > 82 or at.y > 36:
				continue
			if paths.any(func(rect: Rect2) -> bool: return rect.has_point(at)) or map._is_occupied(at, 3.2):
				continue
			var evergreen := rng.randf() < .16
			var tree := Vegetation.create("park_conifer" if evergreen else "park_deciduous_tree", Vector3(at.x, .04, at.y))
			tree.scale *= rng.randf_range(.67, .82)
			tree.rotation.y = rng.randf_range(0, TAU)
			root.add_child(tree)
			map._occupy(at, Vector2(3, 3))
			planted.append(at)
	# Low planting edges reinforce the walks without closing sight lines to entrances.
	for at in [Vector2(42, 6), Vector2(42, 14), Vector2(42, 23), Vector2(54, -17), Vector2(62, -17), Vector2(72, -17), Vector2(58, 6), Vector2(66, 6), Vector2(75, 6), Vector2(58, 17), Vector2(66, 17), Vector2(75, 17)]:
		var bush := Vegetation.create("park_shrub", Vector3(at.x, .04, at.y))
		bush.scale *= .65
		root.add_child(bush)
	print("Civic public garden: ", planted.size(), " additional trees; department store at ", Layout.lot_center("department_store"))
