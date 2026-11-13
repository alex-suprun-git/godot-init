extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Bench = preload("res://assets/models/civic_center/park_bench.glb")
const Bin = preload("res://assets/models/civic_center/park_bin.glb")
const STEEL := Color("536353")
const KERB := Color("a5a090")

var map
var yard_root: Node3D
var origin: Vector2
var paving_height := 0.078
var preview_surfaces: Array[Rect2] = []


func build(city_map: Node3D) -> void:
	map = city_map
	yard_root = Node3D.new()
	yard_root.name = "ResidentialCorePreviewYards"
	map.add_child(yard_root)
	var school: Rect2 = Layout.LOTS["a1_k"]["rect"]
	var kindergarten: Rect2 = Layout.LOTS["b2_k"]["rect"]
	var trade := Rect2(-323, 166, 51, 36)
	_clear_old_dressing([school, kindergarten, trade, Rect2(-89, -17, 30, 11)])
	origin = school.get_center()
	_school(school)
	origin = kindergarten.get_center()
	_kindergarten(kindergarten)
	origin = Layout.lot_center("b1_k")
	_maintenance()
	origin = Layout.lot_center("a2_k")
	_trade(trade)
	_plant_between_yards()


func _plant_between_yards() -> void:
	origin = Vector2.ZERO
	# Grass pockets between the buildings, courtyard entrances and street sidewalks.
	var groups: Array[Vector2] = [
		Vector2(-321, -41), Vector2(-266, -43), Vector2(-348, 17),
		Vector2(-238, 62), Vector2(-224, 71), Vector2(-168, 63),
		Vector2(-349, 118), Vector2(-338, 211), Vector2(-258, 218),
		Vector2(-161, 207), Vector2(-64, 214), Vector2(-47, 196),
		Vector2(-332, 253), Vector2(-263, 252), Vector2(-139, 255),
		Vector2(-59, 237), Vector2(-42, 230), Vector2(-29, 219),
		Vector2(-346, 199), Vector2(-330, 205), Vector2(-278, 212),
	]
	for index in groups.size():
		var at := groups[index]
		var tree := "park_poplar" if index % 3 == 1 else "park_deciduous_tree"
		_plant_on_clear_grass(at, tree, 1.06, 3.8)
		_plant_on_clear_grass(at + Vector2(4.0, 3.0), "park_shrub", 1.02, 1.2)
		_plant_on_clear_grass(at + Vector2(-3.5, -2.5), "park_shrub", 0.90, 1.2)


func _plant_on_clear_grass(at: Vector2, kind: String, size: float, clearance: float) -> void:
	if map._is_occupied(at, clearance):
		return
	if preview_surfaces.any(func(rect: Rect2) -> bool: return rect.grow(clearance).has_point(at)):
		return
	_plant(at, kind, size)


func _clear_old_dressing(rects: Array[Rect2]) -> void:
	for node in map.get_children():
		if not node is Node3D:
			continue
		var at := Vector2(node.position.x, node.position.z)
		if not rects.any(func(rect: Rect2) -> bool: return rect.has_point(at)):
			continue
		if node is Sprite3D and node.texture != null and node.texture.resource_path.get_file() in [
			"bench_playground.png", "garbage_pile.png", "carpet_beater_v2.png",
		]:
			node.queue_free()
		elif node.scene_file_path.get_file() in ["park_poplar.glb", "park_deciduous_tree.glb"]:
			node.queue_free()


func _school(lot: Rect2) -> void:
	_lawn(lot)
	_surface(Vector2(-11, 1), Vector2(27, 24), "paving")
	_surface(Vector2(-11, 24), Vector2(4.0, 25), "paving")
	_surface(Vector2(-30, 35), Vector2(39, 3.2), "paving")
	_surface(Vector2(-48, 57), Vector2(3.2, 46.2), "paving")
	_surface(Vector2(9, 18), Vector2(21, 2.8), "paving")
	_surface(Vector2(-25, 0), Vector2(1.5, 23), "paving")
	for at in [Vector2(-36, -17), Vector2(-34, 6), Vector2(-32, 25), Vector2(13, -25), Vector2(35, -23)]:
		_plant(at, "park_deciduous_tree", 0.68)
	_plant(Vector2(-39, -27), "park_poplar", 0.70)
	_plant(Vector2(24, -27), "park_poplar", 0.64)
	_plant(Vector2(39, -16), "park_deciduous_tree", 0.81)
	_plant(Vector2(-37, 14), "park_deciduous_tree", 0.79)
	for at in [Vector2(-28, -10), Vector2(-28, -6), Vector2(-26, -2), Vector2(17, -24), Vector2(20, -25)]:
		_plant(at, "park_shrub", 0.85)
	for at in [Vector2(-39, -8), Vector2(-36, -5), Vector2(-38, 21), Vector2(31, -26), Vector2(37, -12), Vector2(40, -9)]:
		_plant(at, "park_shrub", 1.02)
	_prop(Bench, Vector2(-23, 5), PI / 2.0)
	_prop(Bench, Vector2(-23, 10), PI / 2.0)
	_prop(Bin, Vector2(-22, 12))
	# Two planted beds break up the assembly court without narrowing the approach.
	for at in [Vector2(-19, 6), Vector2(-3, 6)]:
		_box(at, Vector3(2.5, 0.24, 3.8), 0.19, KERB)
		_box(at, Vector3(2.24, 0.035, 3.55), 0.32, Color("77664e"))
		_plant(at, "park_shrub", 0.53, 0.32)


func _kindergarten(lot: Rect2) -> void:
	_lawn(lot)
	# The entry court and fence opening line up with the east-side pedestrian approach.
	_surface(Vector2(0, 5), Vector2(10, 21), "paving")
	_surface(Vector2(45, 13), Vector2(88, 2.6), "paving")
	_surface(Vector2(-17, 16), Vector2(18, 13), "dirt", Color("d8ba8d"))
	_surface(Vector2(16, 23), Vector2(16, 8), "dirt", Color("d8ba8d"))
	_fence(Vector2(-29, -24), Vector2(29, -24))
	_fence(Vector2(-29, -24), Vector2(-29, 30))
	_fence(Vector2(-29, 30), Vector2(29, 30))
	_fence(Vector2(29, -24), Vector2(29, 11.5))
	_fence(Vector2(29, 14.5), Vector2(29, 30))
	for at in [Vector2(-25, -17), Vector2(23, -17), Vector2(24, 23), Vector2(-23, 26)]:
		_plant(at, "park_deciduous_tree", 0.58)
	_plant(Vector2(-35, -23), "park_poplar", 0.70)
	_plant(Vector2(-34, -12), "park_deciduous_tree", 0.83)
	_plant(Vector2(32, -22), "park_deciduous_tree", 0.75)
	_plant(Vector2(35, 24), "park_deciduous_tree", 0.70)
	for at in [Vector2(-26, 2), Vector2(-26, 5), Vector2(25, 5), Vector2(25, 8), Vector2(-9, 26), Vector2(-5, 26)]:
		_plant(at, "park_shrub", 0.66)
	for at in [Vector2(-31, -17), Vector2(-32, -9), Vector2(-34, 7), Vector2(32, -14), Vector2(33, -11), Vector2(29, 25), Vector2(32, 27)]:
		_plant(at, "park_shrub", 0.92)
	_shelter(Vector2(-17, 17))
	_sandbox(Vector2(17, 23))
	_swing(Vector2(13, 22))
	_prop(Bench, Vector2(-6, 20))


func _maintenance() -> void:
	_surface(Vector2(33, -14), Vector2(35, 12), "paving", Color("b7b1a3"))
	_surface(Vector2(54, -13), Vector2(8, 3.8), "asphalt")
	_surface(Vector2(21, -7), Vector2(2, 7), "paving")
	_fence(Vector2(48, -19), Vector2(48, -15))
	_fence(Vector2(48, -11), Vector2(48, -8))
	_box(Vector2(42, -17), Vector3(3.2, 0.12, 1.8), 0.16, KERB)
	for x in [41.0, 42.6]:
		_box(Vector2(x, -17), Vector3(1.15, 1.1, 1.1), 0.76, STEEL)
	_prop(Bin, Vector2(25, -9))
	for at in [Vector2(17, -19), Vector2(15, -16), Vector2(43, -20)]:
		_plant(at, "park_shrub", 0.8)
	_plant(Vector2(13, -33), "park_deciduous_tree", 0.77)
	_plant(Vector2(39, -32), "park_poplar", 0.65)
	_plant(Vector2(46, -29), "park_deciduous_tree", 0.68)
	for at in [Vector2(14, -26), Vector2(9, -30), Vector2(41, -27), Vector2(45, -25), Vector2(39, -5), Vector2(43, -5)]:
		_plant(at, "park_shrub", 0.91)


func _trade(trade: Rect2) -> void:
	_lawn(trade)
	_surface(Vector2(-16, 18), Vector2(19, 8), "paving", Color("b9ae9d"))
	_surface(Vector2(-2, 25), Vector2(42, 3.2), "paving")
	_surface(Vector2(17, 11), Vector2(2.6, 29), "paving")
	_surface(Vector2(31, -3), Vector2(30, 2.6), "paving")
	_surface(Vector2(46, -46), Vector2(2.5, 90.2), "paving")
	_fence(Vector2(-26, 9), Vector2(-8, 9))
	_prop(Bin, Vector2(-6, 24))
	_prop(Bench, Vector2(1, 21), PI)
	for at in [Vector2(-28, 2), Vector2(-25, 6), Vector2(-7, 10), Vector2(12, 20)]:
		_plant(at, "park_shrub", 0.82)
	_plant(Vector2(-35, 2), "park_deciduous_tree", 0.76)
	_plant(Vector2(-33, 14), "park_deciduous_tree", 0.69)
	_plant(Vector2(-5, -1), "park_poplar", 0.68)
	_plant(Vector2(7, 8), "park_deciduous_tree", 0.70)
	for at in [Vector2(-31, 5), Vector2(-31, 8), Vector2(-12, 1), Vector2(-9, 3), Vector2(4, 12), Vector2(8, 14)]:
		_plant(at, "park_shrub", 0.94)


func dress_pitch(model: Node3D) -> void:
	var sample := _lawn(Rect2(0, 0, 1, 1), Color("c2b990"))
	for instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for index in instance.mesh.get_surface_count():
			if instance.mesh.surface_get_material(index).resource_name == "grass":
				instance.set_surface_override_material(index, sample.material_override)
	sample.queue_free()


func _lawn(rect: Rect2, tint := Color.WHITE) -> MeshInstance3D:
	map._ground_quad(rect.get_center(), rect.size, 0.052, map._season["grass"], 12.0,
		false, tint * map._season["grass_tint"], true)
	var surface: MeshInstance3D = map.get_child(map.get_child_count() - 1)
	if surface.material_override is ShaderMaterial:
		surface.material_override.set_shader_parameter("wear_mask", null)
	return surface


func _surface(at: Vector2, size: Vector2, ground: String, tint := Color.WHITE) -> void:
	var rect := Rect2(origin + at - size * 0.5, size)
	preview_surfaces.append(rect)
	# The district path shader uses the newer slab and compacted-earth textures.
	if ground == "asphalt":
		map._asphalt_quad(rect, 0.080, tint)
	else:
		paving_height += 0.0003
		map._path_quad(rect, paving_height if ground == "paving" else 0.073, ground, tint)


func _prop(scene: PackedScene, at: Vector2, yaw := 0.0) -> void:
	var prop := scene.instantiate() as Node3D
	prop.position = _world(at, 0.086)
	prop.rotation.y = yaw
	yard_root.add_child(prop)


func _plant(at: Vector2, kind: String, size: float, height := 0.055) -> void:
	var plant := Vegetation.create(kind, _world(at, height))
	plant.scale *= size
	plant.rotation.y = fposmod(at.x * 0.28 + at.y * 0.17, TAU)
	yard_root.add_child(plant)


func _world(at: Vector2, height: float) -> Vector3:
	return Vector3(origin.x + at.x, height, origin.y + at.y)


func _box(at: Vector2, size: Vector3, height: float, color: Color) -> void:
	map._box(size, _world(at, height), color, yard_root)


func _fence(from: Vector2, to: Vector2) -> void:
	var span := (to - from).abs()
	var bays := maxi(1, ceili(span.length() / 3.5))
	for i in range(bays + 1):
		_box(from.lerp(to, float(i) / bays), Vector3(0.10, 1.45, 0.10), 0.78, STEEL)
	for height in [0.48, 1.33]:
		_box((from + to) * 0.5, Vector3(span.x + 0.07, 0.06, span.y + 0.07), height, STEEL)
	for i in range(1, bays * 4):
		if i % 4 != 0:
			_box(from.lerp(to, float(i) / (bays * 4)), Vector3(0.035, 0.85, 0.035), 0.90, STEEL)


func _shelter(at: Vector2) -> void:
	var wood := Color("8c7250")
	_box(at, Vector3(5.4, 0.18, 3.8), 2.65, Color("72624d"))
	_box(at, Vector3(5.1, 0.15, 3.5), 0.15, KERB)
	for x in [-2.3, 2.3]:
		for z in [-1.55, 1.55]:
			_box(at + Vector2(x, z), Vector3(0.16, 2.5, 0.16), 1.36, wood)
	_box(at + Vector2(0, -1.4), Vector3(4.8, 0.9, 0.14), 0.66, wood)


func _sandbox(at: Vector2) -> void:
	_box(at, Vector3(3.0, 0.15, 3.0), 0.16, Color("b7a47b"))
	for side in [-1.0, 1.0]:
		_box(at + Vector2(side * 1.5, 0), Vector3(0.16, 0.27, 3.15), 0.23, Color("926d48"))
		_box(at + Vector2(0, side * 1.5), Vector3(3.0, 0.27, 0.16), 0.23, Color("926d48"))


func _swing(at: Vector2) -> void:
	var paint := Color("8a5b44")
	_box(at, Vector3(2.8, 0.09, 0.09), 2.37, paint)
	for x in [-1.3, 1.3]:
		_box(at + Vector2(x, 0), Vector3(0.09, 2.3, 0.09), 1.23, paint)
	for x in [-0.25, 0.25]:
		_box(at + Vector2(x, 0), Vector3(0.035, 1.69, 0.035), 1.51, STEEL)
	_box(at, Vector3(0.61, 0.08, 0.34), 0.65, Color("695a47"))
