# School, kindergarten, ZhEK service building, Gusev's kiosks and the mini-football
# pitch, with their yards. Footprints come from art/models/residential_cores/plans.json.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Bench = preload("res://assets/models/civic_center/park_bench.glb")
const Bin = preload("res://assets/models/civic_center/park_bin.glb")
const MODEL_DIR := "res://assets/models/residential_cores/"
# The GLBs carry no UVs, so existing district materials are applied as world-space
# triplanar copies, keyed by the GLB material name: [source .tres, metres per repeat].
const SURFACES := {
	"silicate": ["res://assets/materials/frontier/frontier_silicate_masonry.tres", 2.5],
	"cream": ["res://assets/materials/church_ensemble/warm_lime_plaster.tres", 3.0],
	"ivory": ["res://assets/materials/church_ensemble/warm_lime_plaster.tres", 3.0],
	"roof": ["res://assets/materials/frontier/frontier_roof_felt.tres", 2.0],
	"concrete": ["res://assets/materials/frontier/atp_precast_concrete.tres", 3.0],
	"plinth": ["res://assets/materials/frontier/atp_precast_concrete.tres", 3.0],
}
const MODELS := {
	"school": preload(MODEL_DIR + "school.glb"),
	"football_pitch": preload(MODEL_DIR + "football_pitch.glb"),
	"kindergarten": preload(MODEL_DIR + "kindergarten.glb"),
	"maintenance": preload(MODEL_DIR + "maintenance.glb"),
	"repair": preload(MODEL_DIR + "repair.glb"),
	"kiosk_blue": preload(MODEL_DIR + "kiosk_blue.glb"),
	"kiosk_cream": preload(MODEL_DIR + "kiosk_cream.glb"),
}
const STEEL := Color("536353")
const KERB := Color("a5a090")

var map
var yard_root: Node3D
var origin: Vector2
var paving_height := 0.078
var _surface_materials := {}
var yard_surfaces: Array[Rect2] = []


func build(district_builder) -> void:
	var city_map: Node3D = district_builder.map
	map = city_map
	yard_root = Node3D.new()
	yard_root.name = "ResidentialCores"
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
	_link_to_neighbours(district_builder)
	_place_models()


# Desire-line walks from the doorstep of each surrounding block to the yard's main
# court, so the yards read as part of the housing quarter instead of islands.
func _link_to_neighbours(district_builder) -> void:
	var graph = district_builder.map.sim.graph
	var school: Vector2 = Layout.lot_center("a1_k")
	var kindergarten: Vector2 = Layout.lot_center("b2_k")
	# Both yards are fenced and have exactly one gate, so every walk ends outside it.
	_link_lot("a1", school + Vector2(-14, 44), graph, [Rect2(school + Vector2(-45.5, -39), Vector2(91, 79))])
	_link_lot("b2", kindergarten + Vector2(36, 13), graph, [Rect2(kindergarten + Vector2(-29, -24), Vector2(58, 54))])


func _link_lot(prefix: String, hub: Vector2, graph, avoid: Array[Rect2]) -> void:
	origin = Vector2.ZERO
	for side in ["n", "e", "s", "w"]:
		var door: Vector2 = graph.doorsteps.get("%s_%s" % [prefix, side], Vector2.INF)
		if door == Vector2.INF:
			continue
		var route := _route(door, hub, avoid)
		if route.is_empty():
			continue
		for index in range(route.size() - 1):
			_walk(route[index], route[index + 1])
		# A pair of beds flanks the door end of every walk.
		var along := (route[1] - route[0]).normalized()
		var across := Vector2(-along.y, along.x)
		for flank in [-1.0, 1.0]:
			_flower_bed(route[0] + along * 3.0 + across * flank * 3.2, Vector2(3.2, 1.4) if absf(along.x) < 0.5 else Vector2(1.4, 3.2))


func _route(from: Vector2, to: Vector2, avoid: Array[Rect2]) -> Array[Vector2]:
	var candidates: Array = [
		[from, Vector2(from.x, to.y), to],
		[from, Vector2(to.x, from.y), to],
	]
	for rect in avoid:
		for lane in [rect.position.x - 3.5, rect.end.x + 3.5]:
			candidates.append([from, Vector2(lane, from.y), Vector2(lane, to.y), to])
		for lane in [rect.position.y - 3.5, rect.end.y + 3.5]:
			candidates.append([from, Vector2(from.x, lane), Vector2(to.x, lane), to])
	for candidate in candidates:
		var clear := true
		for index in range(candidate.size() - 1):
			var segment := Rect2(candidate[index], Vector2.ZERO).expand(candidate[index + 1]).grow(1.2)
			if avoid.any(func(rect: Rect2) -> bool: return rect.intersects(segment)):
				clear = false
				break
		if clear:
			var result: Array[Vector2] = []
			result.assign(candidate)
			return result
	return []


func _walk(from: Vector2, to: Vector2) -> void:
	var rect := Rect2(from, Vector2.ZERO).expand(to).grow(0.9)
	yard_surfaces.append(rect)
	paving_height += 0.0003
	map._path_quad(rect, paving_height, "paving", Color.WHITE)


func _place_models() -> void:
	var school: Vector2 = Layout.lot_center("a1_k")
	var kindergarten: Vector2 = Layout.lot_center("b2_k")
	var maintenance: Vector2 = Layout.lot_center("b1_k")
	var trade: Vector2 = Layout.lot_center("a2_k")
	var placements := {
		"school": school + Vector2(-12, -13),
		"football_pitch": school + Vector2(31, 20),
		"kindergarten": kindergarten + Vector2(0, -8),
		"maintenance": maintenance + Vector2(26, -24),
		"repair": trade + Vector2(-21, 12),
		"kiosk_blue": trade + Vector2(-16, 22),
		"kiosk_cream": trade + Vector2(-11, 22),
	}
	for id in placements:
		var model: Node3D = MODELS[id].instantiate()
		model.name = id
		model.position = Vector3(placements[id].x, 0.09, placements[id].y)
		if id == "football_pitch":
			model.rotation.y = -PI / 2.0
			dress_pitch(model)
		_apply_surfaces(model)
		yard_root.add_child(model)


func _apply_surfaces(model: Node3D) -> void:
	for instance: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for index in instance.mesh.get_surface_count():
			var source := instance.mesh.surface_get_material(index)
			if source != null and SURFACES.has(source.resource_name):
				instance.set_surface_override_material(index, _surface_material(source.resource_name))


func _surface_material(key: String) -> StandardMaterial3D:
	if not _surface_materials.has(key):
		var material: StandardMaterial3D = (load(SURFACES[key][0]) as StandardMaterial3D).duplicate()
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		material.uv1_scale = Vector3.ONE / float(SURFACES[key][1])
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_surface_materials[key] = material
	return _surface_materials[key]


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
	if yard_surfaces.any(func(rect: Rect2) -> bool: return rect.grow(clearance).has_point(at)):
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
	_lawn(lot.grow(9.0))
	_surface(Vector2(-14, 1), Vector2(27, 24), "paving")
	_surface(Vector2(-14, 24), Vector2(4.0, 25), "paving")
	_surface(Vector2(3.25, 20), Vector2(34.5, 2.8), "paving")
	for at in [Vector2(-36, -17), Vector2(-34, 6), Vector2(-32, 25), Vector2(-2, -24), Vector2(35, -23)]:
		_plant(at, "park_deciduous_tree", 0.68)
	_plant(Vector2(-39, -27), "park_poplar", 0.70)
	_plant(Vector2(26, -27), "park_poplar", 0.64)
	_plant(Vector2(39, -16), "park_deciduous_tree", 0.81)
	_plant(Vector2(-37, 14), "park_deciduous_tree", 0.79)
	for at in [Vector2(24, -24), Vector2(27, -25)]:
		_plant(at, "park_shrub", 0.85)
	for at in [Vector2(-38, 21), Vector2(31, -26), Vector2(37, -12), Vector2(40, -9)]:
		_plant(at, "park_shrub", 1.02)
	_prop(Bench, Vector2(-26, 5), PI / 2.0)
	_prop(Bench, Vector2(-26, 10), PI / 2.0)
	_prop(Bin, Vector2(-25, 12))
	# One continuous perimeter fence; the only way in is the south gate, which meets
	# the existing district walk. Everything inside stays reachable through it.
	_fence(Vector2(-45.5, -39), Vector2(45.5, -39))
	_fence(Vector2(-45.5, -39), Vector2(-45.5, 40))
	_fence(Vector2(45.5, -39), Vector2(45.5, 40))
	_fence(Vector2(-45.5, 40), Vector2(-17, 40))
	_fence(Vector2(-11, 40), Vector2(45.5, 40))
	_gate(Vector2(-14, 40), "x", 6.0)
	_surface(Vector2(-14, 40.5), Vector2(4.0, 7.0), "paving")
	_lamp(Vector2(-8.5, 36))
	_lamp(Vector2(-19.5, 36))
	# Two planted beds break up the assembly court without narrowing the approach.
	for at in [Vector2(-22, 6), Vector2(-6, 6)]:
		_box(at, Vector3(2.5, 0.24, 3.8), 0.19, KERB)
		_box(at, Vector3(2.24, 0.035, 3.55), 0.32, Color("77664e"))
		_plant(at, "park_shrub", 0.53, 0.32)


func _kindergarten(lot: Rect2) -> void:
	_lawn(lot.grow(9.0))
	# The entry court and fence opening line up with the east-side pedestrian approach.
	_surface(Vector2(0, 5), Vector2(10, 21), "paving")
	_surface(Vector2(45, 13), Vector2(88, 2.6), "paving")
	_surface(Vector2(-17, 16), Vector2(18, 13), "dirt", Color("d8ba8d"))
	_surface(Vector2(16, 23), Vector2(16, 8), "dirt", Color("d8ba8d"))
	_fence(Vector2(-29, -24), Vector2(29, -24), "kids")
	_fence(Vector2(-29, -24), Vector2(-29, 30), "kids")
	_fence(Vector2(-29, 30), Vector2(29, 30), "kids")
	_fence(Vector2(29, -24), Vector2(29, 10.5), "kids")
	_fence(Vector2(29, 15.5), Vector2(29, 30), "kids")
	_gate(Vector2(29, 13), "z", 5.0, "kids")
	_sign(Vector2(33, 8.5), KG_COLORS[2])
	_lamp(Vector2(26.5, 9.5))
	_lamp(Vector2(-3, 16))
	_flower_bed(Vector2(-6.5, 12), Vector2(5, 1.8))
	_flower_bed(Vector2(6.5, 12), Vector2(5, 1.8))
	_mushroom(Vector2(-22, 24))
	_mushroom(Vector2(-19.5, 26))
	_rocket(Vector2(7, 24))
	_shelter(Vector2(22, -6))
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
	_surface(Vector2(21, 0.5), Vector2(2, 17), "paving")
	# A working service yard: fenced on three sides, a pedestrian gate on the south
	# walk, a vehicle gate on the east lane, pipe stores, a truck and a smoking bench.
	_fence(Vector2(34.4, -20), Vector2(50.5, -20))
	_fence(Vector2(50.5, -20), Vector2(50.5, -15.5))
	_fence(Vector2(50.5, -10.5), Vector2(50.5, -6))
	_fence(Vector2(15.5, -6), Vector2(19.8, -6))
	_fence(Vector2(23.2, -6), Vector2(50.5, -6))
	_fence(Vector2(15.5, -20), Vector2(15.5, -6))
	_fence(Vector2(15.5, -20), Vector2(17.6, -20))
	_gate(Vector2(50.5, -13), "z", 5.0)
	_gate(Vector2(21.5, -6), "x", 3.4)
	_sign(Vector2(25.5, -3.5), Color("4a6a8a"))
	_lamp(Vector2(34.8, -9))
	_lamp(Vector2(17, -9))
	_surface(Vector2(43, -11), Vector2(10, 4.6), "asphalt")
	var truck_at := _world_xz(Vector2(43, -11))
	map._vehicle("zil_flatbed", map._ground(truck_at) + Vector3.UP * 0.09,
		map.VehicleModels.map_length("zil_flatbed"), "x", yard_root)
	map._occupy(truck_at, Vector2(8, 3))
	# Pipe store: stacked steel and insulated lengths on timber sleepers.
	for row in 3:
		for column in 4 - row:
			_box(Vector2(40.5 + row * 0.5 + column * 0.62, -17.2), Vector3(0.5, 0.5, 6.4), 0.42 + row * 0.44, Color("4b4e4c") if (row + column) % 2 == 0 else Color("cfc9b6"))
	for z in [-19.0, -17.2, -15.4]:
		_box(Vector2(42, z), Vector3(3.2, 0.14, 0.4), 0.07, WOOD_DARK)
	# Cable drums, a sand heap, pallets and green refuse containers.
	for at in [Vector2(36.8, -17.4), Vector2(38.0, -16.2)]:
		_box(at, Vector3(0.12, 1.5, 1.5), 0.78, Color("8c7250"))
		_box(at + Vector2(0.55, 0), Vector3(0.12, 1.5, 1.5), 0.78, Color("8c7250"))
		_box(at + Vector2(0.27, 0), Vector3(0.45, 0.9, 0.9), 0.78, Color("2f2d2b"))
	_box(Vector2(46.5, -8), Vector3(3.6, 0.5, 2.8), 0.28, Color("b3a273"))
	_box(Vector2(46.5, -8), Vector3(2.4, 0.5, 1.8), 0.7, Color("b3a273"))
	_box(Vector2(46.5, -8), Vector3(1.1, 0.4, 0.9), 1.05, Color("b3a273"))
	for index in 3:
		_box(Vector2(20.5, -17.5 + index * 0.18), Vector3(1.2, 0.14, 1.2), 0.1 + index * 0.16, Color("8c7250"))
	for x in [47.0, 48.4]:
		_box(Vector2(x, -18.4), Vector3(1.1, 1.2, 0.9), 0.65, Color("3f6a4a"))
		_box(Vector2(x, -18.4), Vector3(1.2, 0.1, 1.0), 1.27, Color("2f2d2b"))
	# Insulated heating pipes entering the building on concrete supports.
	for z in [-23.0, -24.2]:
		_box(Vector2(11.5, z), Vector3(12.0, 0.45, 0.45), 0.9, Color("d3cdb9"))
	for x in [6.0, 10.0, 14.0]:
		_box(Vector2(x, -23.6), Vector3(0.5, 0.7, 2.2), 0.35, Color("9d988b"))
	# Bench with the shift and a worker by the truck.
	_prop(Bench, Vector2(29.5, -17.8), 0.0)
	_person("person_worker", Vector2(31.2, -16.4), 1.05)
	_person("person_worker", Vector2(46.0, -12.8), 1.05)
	_person("person_pensioner", Vector2(23.5, -4.4), 1.0)
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
	_lawn(trade.grow(6.0))
	_surface(Vector2(-16, 19), Vector2(19, 10), "paving", Color("b9ae9d"))
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
	map._ground_quad(rect.get_center(), rect.size, 0.052, map._season["grass"], 22.0,
		false, tint * map._season["grass_tint"], true)
	var surface: MeshInstance3D = map.get_child(map.get_child_count() - 1)
	if surface.material_override is ShaderMaterial:
		surface.material_override.set_shader_parameter("wear_mask", null)
	return surface


func _surface(at: Vector2, size: Vector2, ground: String, tint := Color.WHITE) -> void:
	var rect := Rect2(origin + at - size * 0.5, size)
	yard_surfaces.append(rect)
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


const KG_COLORS := [Color("c8553d"), Color("e0b23a"), Color("3f7fa8"), Color("5f9a55")]
const CONCRETE := Color("b4afa2")
const WOOD_DARK := Color("5f4b36")


# Axis-aligned run: concrete plinth, square posts every 3 m, two rails and pickets.
# style "steel" has uniform dark pickets; "kids" alternates painted panels.
func _fence(from: Vector2, to: Vector2, style := "steel") -> void:
	var span := (to - from).abs()
	var bays := maxi(1, ceili(span.length() / 3.0))
	_box((from + to) * 0.5, Vector3(span.x + 0.22, 0.34, span.y + 0.22), 0.17, CONCRETE)
	for i in range(bays + 1):
		_box(from.lerp(to, float(i) / bays), Vector3(0.20, 1.75, 0.20), 0.93, CONCRETE if style == "kids" else STEEL)
	for height in [0.62, 1.55]:
		_box((from + to) * 0.5, Vector3(span.x + 0.1, 0.09, span.y + 0.1), height, STEEL)
	var pickets := bays * 5
	for i in range(1, pickets):
		if i % 5 == 0:
			continue
		var color := STEEL
		if style == "kids":
			color = KG_COLORS[(i / 5) % KG_COLORS.size()]
		_box(from.lerp(to, float(i) / pickets), Vector3(0.07, 1.1, 0.07), 1.0, color)


# Two concrete piers with caps and two open leaves; `along` is the fence axis.
func _gate(at: Vector2, along: String, width: float, style := "steel") -> void:
	var half := width * 0.5
	var axis := Vector2(1, 0) if along == "x" else Vector2(0, 1)
	for side in [-1.0, 1.0]:
		var pier: Vector2 = at + axis * half * side
		_box(pier, Vector3(0.7, 2.3, 0.7), 1.2, CONCRETE)
		_box(pier, Vector3(0.9, 0.16, 0.9), 2.4, KERB)
		# Open leaf swung 90 degrees into the yard (-> perpendicular to the fence).
		var leaf_dir := Vector2(axis.y, axis.x)
		var leaf_centre: Vector2 = pier + leaf_dir * -(width * 0.25)
		var leaf_size := Vector3(width * 0.5, 1.5, 0.08) if along == "z" else Vector3(0.08, 1.5, width * 0.5)
		_box(leaf_centre, leaf_size, 0.95, KG_COLORS[2] if style == "kids" else STEEL)
	_box(at, Vector3(0.8 if along == "z" else width, 0.05, width if along == "z" else 0.8), 0.07, Color("8a8576"))


func _world_xz(at: Vector2) -> Vector2:
	return origin + at


func _person(sprite: String, at: Vector2, width: float) -> void:
	var texture: Texture2D = load("res://assets/sprites/%s.png" % sprite)
	var node: Node3D = map._sprite(texture, map._ground(origin + at), width)
	node.reparent(yard_root)


func _lamp(at: Vector2) -> void:
	_box(at, Vector3(0.16, 4.6, 0.16), 2.35, STEEL)
	_box(at + Vector2(0.45, 0), Vector3(1.0, 0.14, 0.3), 4.6, STEEL)
	_box(at + Vector2(0.9, 0), Vector3(0.4, 0.14, 0.4), 4.5, Color("e6d9a8"))


func _sign(at: Vector2, color: Color) -> void:
	for x in [-1.1, 1.1]:
		_box(at + Vector2(x, 0), Vector3(0.14, 2.3, 0.14), 1.2, STEEL)
	_box(at, Vector3(2.6, 0.9, 0.12), 2.0, color)
	_box(at, Vector3(2.4, 0.08, 0.14), 1.62, Color("e7e0c8"))


func _mushroom(at: Vector2) -> void:
	_box(at, Vector3(0.3, 1.0, 0.3), 0.56, Color("e7e0c8"))
	_box(at, Vector3(1.5, 0.22, 1.5), 1.1, KG_COLORS[0])
	_box(at, Vector3(0.9, 0.2, 0.9), 1.28, KG_COLORS[0])


func _rocket(at: Vector2) -> void:
	_box(at, Vector3(1.4, 0.2, 1.4), 0.2, Color("b7a47b"))
	_box(at, Vector3(0.9, 2.6, 0.9), 1.5, KG_COLORS[3])
	_box(at, Vector3(0.6, 0.8, 0.6), 3.2, KG_COLORS[0])
	for side in [-1.0, 1.0]:
		_box(at + Vector2(side * 0.7, 0), Vector3(0.5, 1.3, 0.12), 0.85, KG_COLORS[1])
		_box(at + Vector2(0, side * 0.7), Vector3(0.12, 1.3, 0.5), 0.85, KG_COLORS[1])
	_box(at + Vector2(0, 1.4), Vector3(0.12, 2.2, 0.12), 1.2, STEEL)


func _flower_bed(at: Vector2, size: Vector2) -> void:
	_box(at, Vector3(size.x, 0.26, size.y), 0.18, KERB)
	_box(at, Vector3(size.x - 0.3, 0.05, size.y - 0.3), 0.32, Color("6b5a44"))
	for i in 4:
		_box(at + Vector2((i - 1.5) * size.x / 4.5, 0), Vector3(0.45, 0.4, 0.45), 0.5, KG_COLORS[i % 4].lightened(0.1))


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
