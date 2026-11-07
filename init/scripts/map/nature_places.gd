# Authored natural landmarks. Named layers reserve room for later event states.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Settings = preload("res://scripts/data/settings.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const VillageGeometry = preload("res://scripts/data/village_geometry.gd")
const POND_ASSETS := {
	"kiosk":preload("res://assets/models/station_hub/kiosk.glb"),
	"bench":preload("res://assets/models/station_hub/bench.glb"),
	"lamp":preload("res://assets/models/station_hub/lamp.glb"),
}
# Overlapping groves keep the outskirts irregular; road/lot clearances are applied below.
const OUTSKIRT_GROVES := [
	{"center": Vector2(-580, -265), "radius": Vector2(140, 65)}, # NW, beyond the highway
	{"center": Vector2(-648, 125), "radius": Vector2(76, 205)}, # extend the western forest
	{"center": Vector2(-560, 350), "radius": Vector2(145, 38)}, # west of the station
	{"center": Vector2(-350, 525), "radius": Vector2(365, 88)}, # beyond the southern rails
	{"center": Vector2(230, 530), "radius": Vector2(240, 90)},
	{"center": Vector2(490, 100), "radius": Vector2(55, 245)}, # beyond the eastern rail embankment
]
var map
var builder
var root: Node3D
var rng := RandomNumberGenerator.new()
var _village_layout := true


func build(district_builder) -> void:
	builder = district_builder
	map = builder.map
	rng.seed = 913
	root = Node3D.new()
	root.name = "NaturePlaces"
	map.add_child(root)
	_pond()
	_pond_commons()
	_village_greens()
	_fill_village_gaps()
	_village_layout = false
	_forest()
	_outskirts()
	_wild_bank_shrubs()


func _pond() -> void:
	var shore := PackedVector2Array([
		Vector2(249, -3), Vector2(264, -11), Vector2(285, -8),
		Vector2(300, 0), Vector2(313, 16), Vector2(308, 33),
		Vector2(293, 46), Vector2(273, 50), Vector2(252, 39),
		Vector2(243, 22), Vector2(247, 10),
	])
	shore = _smooth(shore)
	var center := Vector2(278, 20)
	var bank := PackedVector2Array()
	for point in shore:
		bank.append(center + (point - center) * 1.16)
	_polygon("PondShore", bank, "dirt", 0.045)
	_polygon("PondIce" if Settings.season == "winter" else "PondWater", shore,
		"paving" if Settings.season == "winter" else "water", 0.065,
		Color("b7d0d6") if Settings.season == "winter" else Color("829f91"))
	# Reserve water and shore against generic trees / shrubs.
	map._occupy(VillageGeometry.point(center), Vector2(85, 77)*VillageGeometry.SCALE)
	_path([Vector2(205, -12), Vector2(236, -15), Vector2(265, -15), Vector2(282, -12)], 2.1)
	_path([Vector2(283, -12), Vector2(317, 0), Vector2(326, 37), Vector2(313, 59), Vector2(275, 66), Vector2(239, 50), Vector2(232, 19), Vector2(236, -15)], 1.4)
	# Two modest fishing seats on the accessible northern shore.
	for x in [266.0, 285.0]:
		_box(Vector3(2.2, 0.16, 0.55), Vector3(x, 0.65, -12), Color("81765b"))
		for dx in [-0.8, 0.8]:
			_box(Vector3(0.14, 0.6, 0.45), Vector3(x + dx, 0.3, -12), Color("5b6259"))
	var reeds := Node3D.new()
	reeds.name = "PondReeds"
	root.add_child(reeds)
	for i in range(12, shore.size(), 2):
		var a := shore[i]
		var b := shore[(i + 1) % shore.size()]
		for j in 4:
			var at := a.lerp(b, (j + 0.5) / 4.0)
			for k in 3:
				var height := rng.randf_range(0.7, 1.5)
				map._box(Vector3(0.12, height, 0.12), VillageGeometry.point3(Vector3(at.x + rng.randf_range(-0.6, 0.6), height / 2, at.y + rng.randf_range(-0.6, 0.6))), Color("9c9065"), reeds)


func _pond_commons() -> void:
	# A common shore, not private back gardens. Routes use the gaps between new roadside plots.
	_path([Vector2(326,37),Vector2(338,25),Vector2(382,25)],1.8)
	_path([Vector2(338,25),Vector2(338,29.8)],1.2)
	_path([Vector2(279,65),Vector2(279,61)],1.5)
	_path([Vector2(310,64),Vector2(310,77)],1.6)
	for surface in [[Vector2(277,61),Vector2(14,6)],[Vector2(338,25),Vector2(8,5)],[Vector2(310,72.75),Vector2(7,8.5)]]:
		var size: Vector2 = surface[1]*VillageGeometry.SCALE
		var center := VillageGeometry.point(surface[0])
		preload("res://scripts/map/village_surfaces.gd").road(map,Rect2(center-size/2.0,size),.074,false)
	for at in [Vector3(272,.08,62),Vector3(281,.08,62)]:
		_pond_asset("bench",at,PI)
	for at in [Vector3(340,.08,23),Vector3(340,.08,27)]:
		_pond_asset("bench",at,PI/2)
	_pond_asset("kiosk",Vector3(310,.08,71.2))
	_pond_asset("bench",Vector3(306.9,.08,74.8),PI/2)
	for at in [Vector3(266,.08,63),Vector3(346,.08,25),Vector3(314,.08,75)]:
		_pond_asset("lamp",at)
	# Small bins beside seating and shop; the native forms are interim site furniture.
	for at in [Vector2(285,62),Vector2(340,29),Vector2(313,74)]:
		_box(Vector3(.40,.65,.40),Vector3(at.x,.40,at.y),Color("566253"))
		_box(Vector3(.45,.07,.45),Vector3(at.x,.76,at.y),Color("414b42"))
	# One modest picnic table makes the eastern grassy pocket useful.
	_box(Vector3(2.0,.08,.85),Vector3(338,.78,31),Color("877254"))
	for x in [337.3,338.7]:
		_box(Vector3(.10,.72,.60),Vector3(x,.38,31),Color("596052"))
	for z in [30.2,31.8]:
		_box(Vector3(2.0,.08,.32),Vector3(338,.46,z),Color("877254"))
		for x in [337.3,338.7]:
			_box(Vector3(.10,.44,.30),Vector3(x,.23,z),Color("596052"))
	var groups := [
		Vector2(239,5),Vector2(239,37),Vector2(264,60),Vector2(291,61),
		Vector2(329,9),Vector2(336,7),Vector2(342,11),Vector2(339,40),
		Vector2(344,44),Vector2(334,46),Vector2(330,60),Vector2(338,61),Vector2(343,65),
		Vector2(332,2),Vector2(346,6),Vector2(346,15),Vector2(334,39),
		Vector2(347,42),Vector2(346,49),Vector2(332,64),Vector2(346,68),
	]
	for i in groups.size():
		_commons_tree(groups[i],7.5+float(i%4)*.6,i%5 == 0)
	print("Pond commons: shared shore, two small seating pockets, existing 3x2.5m kiosk, roadside access retained")


func _village_greens() -> void:
	# Reclaimed back-land remains planted. New dwellings are confined to empty street frontage.
	for at in [Vector2(162,15),Vector2(165,43),Vector2(165,80),Vector2(164,121),Vector2(165,165),Vector2(162,205),Vector2(363,104),Vector2(363,155),Vector2(363,196)]:
		_commons_tree(at,6.2,false)
	# The older deep farmstead's orchard survives behind its compact residential yard.
	for x in [251.0,261.0,273.0]:
		for z in [145.0,159.0,174.0,188.0]:
			_commons_tree(Vector2(x+rng.randf_range(-1.2,1.2),z+rng.randf_range(-1,1)),4.2,false)
	_path([Vector2(240,135),Vector2(240,183),Vector2(250,192),Vector2(262,192),Vector2(262,197)],1.0)


func _fill_village_gaps() -> void:
	# Current map coordinates: pack green groups around the fitted plots and keep access open.
	var scatter := RandomNumberGenerator.new()
	scatter.seed = 7112026
	var planted := 0
	for x in range(158,381,7):
		for z in range(-35,267,7):
			var at := Vector2(x,z)+Vector2(scatter.randf_range(-2,2),scatter.randf_range(-2,2))
			if map._is_occupied(at,3.2):
				continue
			var blocked := false
			for road in Layout.ROADS:
				var rect: Rect2 = road["rect"]
				if rect.grow(3.0).has_point(at):
					blocked = true
			for lot in Layout.LOTS.values():
				var rect: Rect2 = lot["rect"]
				if rect.grow(2.0).has_point(at):
					blocked = true
			if blocked:
				continue
			var poplar := scatter.randf() < .18
			var id := "park_poplar" if poplar else "park_deciduous_tree"
			var tree := Vegetation.create(id,Vector3(at.x,.04,at.y))
			tree.scale = Vector3.ONE*scatter.randf_range(7.0,10.5)/float(Vegetation.HEIGHTS[id])
			tree.rotation.y = scatter.randf_range(-PI,PI)
			root.add_child(tree)
			map._occupy(at,Vector2(3,3))
			for offset in [Vector2(-1.7,1),Vector2(1.4,1.6),Vector2(.6,-1.4)]:
				var shrub := Vegetation.create("park_shrub",Vector3(at.x+offset.x,.04,at.y+offset.y))
				shrub.scale *= scatter.randf_range(.3,.5)
				root.add_child(shrub)
			planted += 1
	print("Village planted gaps: ",planted," tree/shrub groups; roads and parcel access clear")


func _commons_tree(at: Vector2, height: float, poplar: bool) -> void:
	if _village_layout:
		at = VillageGeometry.point(at)
	var id := "park_poplar" if poplar else "park_deciduous_tree"
	var tree := Vegetation.create(id,Vector3(at.x,.04,at.y))
	tree.scale *= height/float(Vegetation.HEIGHTS[id])
	tree.rotation.y = rng.randf_range(-PI,PI)
	root.add_child(tree)
	map._occupy(at,Vector2(2,2))
	for offset in [Vector2(-1.8,1),Vector2(1.5,1.5),Vector2(.5,-1.8)]:
		var spot: Vector2 = at+offset
		var shrub := Vegetation.create("park_shrub",Vector3(spot.x,.04,spot.y))
		shrub.scale *= rng.randf_range(.22,.38)
		root.add_child(shrub)


func _pond_asset(id: String, at: Vector3, yaw := .0) -> void:
	if _village_layout:
		at = VillageGeometry.point3(at)
	var node: Node3D = POND_ASSETS[id].instantiate()
	node.name = "Pond_"+id
	node.position = at
	node.rotation.y = yaw
	root.add_child(node)
	map._occupy(Vector2(at.x,at.z),Vector2(3.5,3.0) if id == "kiosk" else Vector2(2,1))


func _forest() -> void:
	var clearing: Vector2 = Layout.lot_center("forest_clearing")
	_path([Layout.lot_center("a1_w") + Vector2(-8, 0), Vector2(-484,15), Vector2(-510,38), clearing], 2.2)
	_path([clearing, Vector2(-522,213), Layout.lot_center("a2_w") + Vector2(-8, 0)], 1.6)
	var clearing_edge := PackedVector2Array()
	for i in 20:
		var angle := TAU * i / 20.0
		clearing_edge.append(clearing + Vector2(cos(angle) * 17, sin(angle) * 14))
	_polygon("ForestClearing", clearing_edge, "grass_dry", 0.055)
	map._occupy(clearing, Vector2(34, 30))
	var trees := Node3D.new()
	trees.name = "ForestCanopy"
	root.add_child(trees)
	# A jittered grid makes a continuous grove with an irregular boundary.
	for x in range(-629, -490, 8):
		for z in range(-35, 290, 8):
			var at := Vector2(x + rng.randf_range(-3, 3), z + rng.randf_range(-3, 3))
			var edge := pow((at.x + 563) / 79.0, 2) + pow((at.y - 126) / 174.0, 2)
			if edge > rng.randf_range(0.86, 1.12) or map._is_occupied(at, 3.0):
				continue
			var tree: Node3D = map._tree(map._ground(at))
			tree.reparent(trees)
	# A bench marks the clearing; its centre stays free for event characters.
	_box(Vector3(3.5, 0.16, 0.65), Vector3(clearing.x - 8, 0.65, clearing.y + 8), Color("82735a"))
	_box(Vector3(3.5, 0.5, 0.12), Vector3(clearing.x - 8, 1, clearing.y + 8.3), Color("82735a"))
	for dx in [-1.2, 1.2]:
		_box(Vector3(0.16, 0.6, 0.5), Vector3(clearing.x - 8 + dx, 0.3, clearing.y + 8), Color("535c55"))


func _outskirts() -> void:
	# Independent placement/appearance RNG leaves existing district trees unchanged.
	var scatter := RandomNumberGenerator.new()
	scatter.seed = 6111997
	var trees := Node3D.new()
	trees.name = "OutskirtsForest"
	root.add_child(trees)
	for x in range(-720, 550, 14):
		for z in range(-325, 625, 14):
			var at := Vector2(x, z) + Vector2(scatter.randf_range(-4, 4), scatter.randf_range(-4, 4))
			var edge := INF
			for grove in OUTSKIRT_GROVES:
				var offset: Vector2 = (at - grove["center"]) / grove["radius"]
				edge = minf(edge, offset.length_squared())
			if edge > scatter.randf_range(0.85, 1.12):
				continue
			# The original grove already owns this canopy and its event clearing.
			var original_edge := pow((at.x + 563) / 79.0, 2) + pow((at.y - 126) / 174.0, 2)
			if (at.x >= -632 and at.x <= -484 and at.y >= -38 and at.y <= 292 and original_edge < 1.2) or map._is_occupied(at, 7.0):
				continue
			var in_lot := false
			for lot in Layout.LOTS.values():
				var rect: Rect2 = lot["rect"]
				if rect.grow(7.0).has_point(at):
					in_lot = true
					break
			if in_lot:
				continue
			var poplar := scatter.randf() < 0.18
			var id := "park_poplar" if poplar else "park_deciduous_tree"
			var height := scatter.randf_range(13, 18) if poplar else scatter.randf_range(9, 13)
			var tree := Vegetation.create(id, map._ground(at))
			tree.scale = Vector3.ONE * height / float(Vegetation.HEIGHTS[id])
			tree.rotation.y = scatter.randf_range(0, TAU)
			trees.add_child(tree)


func _wild_bank_shrubs() -> void:
	var scatter := RandomNumberGenerator.new()
	scatter.seed = 3301997
	var shrubs := Node3D.new()
	shrubs.name = "WildBankShrubs"
	root.add_child(shrubs)
	for x in range(-780, -462, 17):
		var shrub := Vegetation.create("park_shrub", Vector3(x + scatter.randf_range(-4, 4), 0.03, -327 + scatter.randf_range(-1.5, 2.0)))
		shrub.scale = Vector3.ONE * scatter.randf_range(0.7, 1.3)
		shrub.rotation.y = scatter.randf_range(0, TAU)
		shrubs.add_child(shrub)


func _box(size: Vector3, at: Vector3, color: Color) -> void:
	if _village_layout:
		at = VillageGeometry.point3(at)
	map._box(size, at, color, root)


func _path(points: Array, width: float) -> void:
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		if _village_layout:
			a = VillageGeometry.point(a)
			b = VillageGeometry.point(b)
		var side := (b - a).normalized().orthogonal() * width / 2
		_polygon("Footpath", PackedVector2Array([a + side, b + side, b - side, a - side]), "dirt", 0.052, Color.WHITE, true)
		# Fine occupancy segments avoid blocking entire diagonal bounding boxes.
		var steps := maxi(1, ceili(a.distance_to(b) / 2.0))
		for j in steps + 1:
			map._occupy(a.lerp(b, float(j) / steps), Vector2.ONE * width)


func _polygon(title: String, points: PackedVector2Array, ground: String, height: float, tint := Color.WHITE, mapped := false) -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	for at in points:
		if _village_layout and not mapped:
			at = VillageGeometry.point(at)
		vertices.append(Vector3(at.x, height, at.y))
		uvs.append(at / 18.0)
		normals.append(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = Geometry2D.triangulate_polygon(points)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_texture = null if title == "PondIce" else map._season[ground]
	material.albedo_color = tint * (map._season["grass_tint"] if ground == "grass_dry" else Color.WHITE)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.95
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = material
	if _village_layout and ground == "dirt":
		node.material_override = preload("res://scripts/map/village_surfaces.gd").path_material(map,Rect2(),false,.35 if title == "PondShore" else .0)
	root.add_child(node)


func _smooth(points: PackedVector2Array) -> PackedVector2Array:
	# Corner cutting retains an irregular silhouette without hard polygon edges.
	for iteration in 2:
		var result := PackedVector2Array()
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			result.append(a.lerp(b, 0.25))
			result.append(a.lerp(b, 0.75))
		points = result
	return points
