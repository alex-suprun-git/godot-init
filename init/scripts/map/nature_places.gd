# Authored natural landmarks. Named layers reserve room for later event states.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Settings = preload("res://scripts/data/settings.gd")
var map
var builder
var root: Node3D
var rng := RandomNumberGenerator.new()


func build(district_builder) -> void:
	builder = district_builder
	map = builder.map
	rng.seed = 913
	root = Node3D.new()
	root.name = "NaturePlaces"
	map.add_child(root)
	_pond()
	_forest()


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
	map._occupy(center, Vector2(85, 77))
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
				map._box(Vector3(0.12, height, 0.12), Vector3(at.x + rng.randf_range(-0.6, 0.6), height / 2, at.y + rng.randf_range(-0.6, 0.6)), Color("9c9065"), reeds)


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
			var tree: Sprite3D = map._tree(map._ground(at))
			tree.reparent(trees)
	# A bench marks the clearing; its centre stays free for event characters.
	_box(Vector3(3.5, 0.16, 0.65), Vector3(clearing.x - 8, 0.65, clearing.y + 8), Color("82735a"))
	_box(Vector3(3.5, 0.5, 0.12), Vector3(clearing.x - 8, 1, clearing.y + 8.3), Color("82735a"))
	for dx in [-1.2, 1.2]:
		_box(Vector3(0.16, 0.6, 0.5), Vector3(clearing.x - 8 + dx, 0.3, clearing.y + 8), Color("535c55"))


func _box(size: Vector3, at: Vector3, color: Color) -> void:
	map._box(size, at, color, root)


func _path(points: Array, width: float) -> void:
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var side := (b - a).normalized().orthogonal() * width / 2
		_polygon("Footpath", PackedVector2Array([a + side, b + side, b - side, a - side]), "dirt", 0.052)
		# Fine occupancy segments avoid blocking entire diagonal bounding boxes.
		var steps := maxi(1, ceili(a.distance_to(b) / 2.0))
		for j in steps + 1:
			map._occupy(a.lerp(b, float(j) / steps), Vector2.ONE * width)


func _polygon(title: String, points: PackedVector2Array, ground: String, height: float, tint := Color.WHITE) -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	for at in points:
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
