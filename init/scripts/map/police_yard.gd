# Furnishing of the police station territory: vehicle yard behind the gate with the chief's car,
# a gate booth, an entrance walk with lanterns and an information stand, rear parking in front of
# the garage doors, planting and a bin enclosure. Offsets are metres from the building origin
# (dx east/front, dz south), see civic_services.gd.
extends RefCounted

const VegetationModels = preload("res://scripts/map/vegetation_models.gd")
const ASSET_DIR := "res://assets/models/civic_center/"
const SURFACE := 0.045

var map
var root: Node3D
var origin: Vector2
var _scenes := {}


func build(city_map, rect: Rect2, building_origin: Vector2) -> void:
	map = city_map
	origin = building_origin
	root = Node3D.new()
	root.name = "PoliceYard"
	map.add_child(root)
	var east := rect.end.x - building_origin.x - 0.3 # dx of the inner east fence face
	var lines := Color("e4e2d8")
	# Vehicle yard at the gate: asphalt, bay lines for the van, the chief's black car north of the walk.
	_surface(_rect(10.0, 6.8, east - 10.0, 9.4), "asphalt", 12.0)
	# The van parks beside the gate lane (dz 8.8..13.2), never across it.
	for dz in [6.2, 8.6]:
		map._box(Vector3(4.6, 0.012, 0.09), _y(_p(east - 3.2, dz), SURFACE + 0.012), lines, root)
	map._vehicle("volga", _y(_p(east - 2.2, -8.0), 0.05), map.VehicleModels.map_length("volga"), "z", root, map.VehicleModels.PAINT_BLACK)
	# Entrance walk, lanterns and an information stand with wanted notices.
	map._box(Vector3(east - 8.2, 0.02, 2.4), _y(_p((east + 8.2) / 2.0, 0.0), SURFACE + 0.012), Color(0.72, 0.71, 0.68), root)
	for dz in [-2.4, 2.4]:
		_asset("park_lantern", _y(_p(12.5, dz), SURFACE))
		map._lamp_light(_y(_p(12.5, dz), SURFACE), 3.4, 0.45)
	_stand(_p(10.6, -6.0))
	_seat(_p(10.8, 5.6), PI)
	# Gate booth beside the vehicle gate.
	_booth(_p(east - 1.4, 15.3))
	# Planting along the side fences and by the entrance.
	for dx in range(10, int(east) - 1, 3):
		_bush(_p(dx, -15.7), 0.03, 2.0)
	for at in [Vector2(11.5, -13.2), Vector2(14.5, -14.6)]:
		_tree(_p(at.x, at.y), "deciduous")
	# Rear yard: parking in front of the garage doors, poplar screen, bin enclosure.
	_surface(_rect(-18.6, -15.0, 7.3, 15.4), "asphalt", 12.0)
	for dz in [-12.6, -8.4, -4.2]:
		map._box(Vector3(0.09, 0.012, 3.2), _y(_p(-18.2, dz), SURFACE + 0.012), lines, root)
	for dz in [-24.0, 4.0, 9.0, 14.0]:
		_tree(_p(-17.9, dz), "poplar")
	_service_corner(_p(-14.5, 13.8))


func _p(dx: float, dz: float) -> Vector2:
	return Vector2(origin.x + dx, origin.y + dz)


func _y(at: Vector2, y: float) -> Vector3:
	return Vector3(at.x, y, at.y)


func _rect(dx: float, dz: float, w: float, h: float) -> Rect2:
	return Rect2(_p(dx, dz), Vector2(w, h))


func _surface(rect: Rect2, ground: String, tile: float) -> void:
	map._ground_quad(rect.get_center(), rect.size, SURFACE, map._season[ground], tile)


func _asset(id: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	if not _scenes.has(id):
		_scenes[id] = load(ASSET_DIR + id + ".glb")
	var node: Node3D = _scenes[id].instantiate()
	root.add_child(node)
	node.position = at
	node.rotation.y = yaw
	return node


func _seat(at: Vector2, yaw: float) -> void:
	_asset("park_bench", _y(at, SURFACE), yaw)
	_asset("park_bin", _y(at + Vector2(1.5, 0).rotated(-yaw), SURFACE))


func _bush(at: Vector2, height: float, width: float) -> void:
	var node := VegetationModels.create("park_shrub", Vector3(at.x, height, at.y))
	root.add_child(node)
	node.scale = Vector3.ONE * width / 2.14


func _tree(at: Vector2, kind: String) -> void:
	var id: String = {"deciduous": "park_deciduous_tree", "poplar": "park_poplar"}[kind]
	var node := VegetationModels.create(id, Vector3(at.x, 0.03, at.y))
	root.add_child(node)
	var seed_value := int(at.x * 31 + at.y * 17)
	node.rotation.y = fposmod(seed_value * 2.399, TAU)
	node.scale = Vector3.ONE * (0.90 + posmod(seed_value, 7) * 0.035)


# Glass-fronted notice stand on two posts, facing the walk.
func _stand(at: Vector2) -> void:
	var post := Color(0.30, 0.32, 0.32)
	for dz in [-0.9, 0.9]:
		map._box(Vector3(0.12, 2.1, 0.12), _y(at + Vector2(0, dz), SURFACE + 1.05), post, root)
	map._box(Vector3(0.1, 1.3, 2.2), _y(at, SURFACE + 1.5), Color(0.10, 0.22, 0.42), root)
	for dz in [-0.55, 0.55]:
		map._box(Vector3(0.12, 0.8, 0.8), _y(at + Vector2(0.01, dz), SURFACE + 1.5), Color(0.86, 0.85, 0.78), root)


# Small gate booth with a window towards the yard and a flat roof.
func _booth(at: Vector2) -> void:
	map._box(Vector3(1.7, 2.5, 1.7), _y(at, SURFACE + 1.25), Color(0.58, 0.57, 0.52), root)
	map._box(Vector3(1.95, 0.1, 1.95), _y(at, SURFACE + 2.55), Color(0.55, 0.54, 0.50), root)
	map._box(Vector3(0.06, 0.9, 1.1), _y(at + Vector2(0.88, 0), SURFACE + 1.5), Color(0.12, 0.17, 0.2), root)
	map._box(Vector3(0.06, 1.8, 0.7), _y(at + Vector2(-0.88, 0), SURFACE + 0.9), Color(0.18, 0.2, 0.2), root)


# Concrete bin enclosure with three green containers.
func _service_corner(at: Vector2) -> void:
	var wall := Color(0.60, 0.59, 0.55)
	map._box(Vector3(3.2, 0.015, 3.0), _y(at, SURFACE + 0.008), Color(0.46, 0.46, 0.44), root)
	map._box(Vector3(0.2, 1.7, 3.0), _y(at + Vector2(-1.5, 0), SURFACE + 0.85), wall, root)
	for dz in [-1.4, 1.4]:
		map._box(Vector3(3.2, 1.7, 0.2), _y(at + Vector2(0, dz), SURFACE + 0.85), wall, root)
	for dz in [-0.9, 0.0, 0.9]:
		map._box(Vector3(0.7, 1.1, 0.8), _y(at + Vector2(-0.8, dz), SURFACE + 0.55), Color(0.14, 0.30, 0.18), root)
