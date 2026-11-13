# Furnishing of the polyclinic territory: entrance plaza with seating and lanterns, a small
# patient car park behind its own gate, planting, a gate signboard and a service corner.
# Offsets are metres from the building origin (dx east/front, dz south), see civic_services.gd.
extends RefCounted

const VegetationModels = preload("res://scripts/map/vegetation_models.gd")
const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const ASSET_DIR := "res://assets/models/civic_center/"
const SURFACE := 0.045

var map
var root: Node3D
var origin: Vector2
var _scenes := {}


func build(city_map, builder, rect: Rect2, building_origin: Vector2) -> void:
	map = city_map
	origin = building_origin
	root = Node3D.new()
	root.name = "ClinicYard"
	map.add_child(root)
	var east := rect.end.x - building_origin.x - 0.3 # dx of the inner east fence face
	# Entrance plaza in front of the steps, flush stone edging like the civic court.
	_surface(_rect(11.8, -6.5, 8.2, 13.0), "paving", 6.0)
	for dz in [-6.5, 6.5]:
		map._box(Vector3(8.2, 0.015, 0.3), _y(_p(15.9, dz), SURFACE + 0.012), Color("999789"), root)
	# Patient car park: its own gate on the north side of the front yard.
	_surface(_rect(east - 9.8, -22.0, 9.8, 12.0), "asphalt", 12.0)
	for dz in [-22.0 + 0.1, -10.1]:
		map._box(Vector3(9.4, 0.012, 0.1), _y(_p(east - 5.0, dz), SURFACE + 0.012), Color("e4e2d8"), root)
	for dz in [-19.7, -12.3]:
		map._vehicle("lada", _y(_p(east - 7.5, dz), 0.05), map.VehicleModels.map_length("lada"), "x", root, 2 if dz < -15.0 else 5)
	for dz in [-17.8, -14.2]:
		map._box(Vector3(4.6, 0.012, 0.09), _y(_p(east - 7.5, dz), SURFACE + 0.012), Color("e4e2d8"), root)
	# Seating along the entrance path.
	_seat(_p(14.0, -4.4), 0.0)
	_seat(_p(14.0, 4.4), PI)
	for dz in [-1.9, 1.9]:
		_asset("park_lantern", _y(_p(17.5, dz), SURFACE))
		map._lamp_light(_y(_p(17.5, dz), SURFACE), 3.4, 0.45)
	for dz in [-3.6, 3.6]:
		_asset("park_planter_2m", _y(_p(19.0, dz), SURFACE), PI / 2.0)
		_bush(_p(19.0, dz), 0.4, 2.0)
	# Hedges just inside the north and south fence runs.
	for dx in range(13, int(east) - 1, 3):
		_bush(_p(dx, -25.0), 0.03, 2.2)
		_bush(_p(dx, 25.0), 0.03, 2.2)
	# Lawn trees in the front yard; poplars close to the street fence.
	for at in [Vector2(19.5, -7.6), Vector2(15.0, 22.5)]:
		_tree(_p(at.x, at.y), "deciduous")
	for dz in [-8.0, 24.0]:
		_tree(_p(east - 1.2, dz), "poplar")
	# Rear and side yards: poplar screen, service corner.
	for dz in range(-20, 21, 8):
		_tree(_p(-8.0, dz), "poplar")
	_tree(_p(-3.0, -23.0), "deciduous")
	_service_corner(_p(-3.5, 23.2))
	_shed(_p(-6.0, -23.2))


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
	var id: String = {"deciduous": "park_deciduous_tree", "conifer": "park_conifer", "poplar": "park_poplar"}[kind]
	var node := VegetationModels.create(id, Vector3(at.x, 0.03, at.y))
	root.add_child(node)
	var seed_value := int(at.x * 31 + at.y * 17)
	node.rotation.y = fposmod(seed_value * 2.399, TAU)
	node.scale = Vector3.ONE * (0.90 + posmod(seed_value, 7) * 0.035)


func _signboard(at: Vector2) -> void:
	var post := Color(0.33, 0.35, 0.35)
	for dz in [-2.0, 2.0]:
		map._box(Vector3(0.18, 3.1, 0.18), _y(at + Vector2(0, dz), SURFACE + 1.55), post, root)
	map._box(Vector3(0.16, 1.1, 4.8), _y(at, SURFACE + 2.5), Color("f1efe6"), root)
	map._box(Vector3(0.18, 0.14, 4.9), _y(at, SURFACE + 3.1), Color(0.60, 0.12, 0.10), root)
	var label := Label3D.new()
	label.text = "ПОЛИКЛИНИКА"
	label.font = OfficeTheme.BODY_FONT
	label.font_size = 96
	label.pixel_size = 0.0075
	label.modulate = Color(0.60, 0.12, 0.10)
	label.outline_size = 0
	label.position = _y(at, SURFACE + 2.45) + Vector3(0.1, 0, 0)
	label.rotation.y = PI / 2.0
	root.add_child(label)


# Concrete bin enclosure with three green containers.
func _service_corner(at: Vector2) -> void:
	var wall := Color(0.60, 0.59, 0.55)
	map._box(Vector3(4.0, 0.015, 3.0), _y(at, SURFACE + 0.008), Color(0.46, 0.46, 0.44), root)
	map._box(Vector3(4.0, 1.7, 0.2), _y(at + Vector2(0, 1.4), SURFACE + 0.85), wall, root)
	for dx in [-1.9, 1.9]:
		map._box(Vector3(0.2, 1.7, 3.0), _y(at + Vector2(dx, 0), SURFACE + 0.85), wall, root)
	for dx in [-1.2, 0.0, 1.2]:
		map._box(Vector3(0.8, 1.1, 0.7), _y(at + Vector2(dx, 0.6), SURFACE + 0.55), Color(0.14, 0.30, 0.18), root)
		map._box(Vector3(0.86, 0.08, 0.76), _y(at + Vector2(dx, 0.6), SURFACE + 1.14), Color(0.10, 0.20, 0.13), root)


# Utility shed (boiler-room extension / stores).
func _shed(at: Vector2) -> void:
	map._box(Vector3(4.2, 2.6, 3.0), _y(at, SURFACE + 1.3), Color(0.66, 0.62, 0.54), root)
	map._box(Vector3(4.6, 0.18, 3.4), _y(at, SURFACE + 2.7), Color(0.12, 0.12, 0.13), root)
	map._box(Vector3(1.0, 2.0, 0.08), _y(at + Vector2(0, 1.52), SURFACE + 1.0), Color(0.18, 0.2, 0.2), root)
