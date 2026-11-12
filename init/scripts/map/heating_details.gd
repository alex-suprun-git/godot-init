# A small readable infrastructure pilot. Geometry uses metres; no new art assets.
# Named groups can acquire repair / damage states when authored events need them.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const INSULATION := Color("aaa793")
const STEEL := Color("535d59")
const RUST := Color("825743")
var map
var root: Node3D


func build(city_map) -> void:
	map = city_map
	root = Node3D.new()
	root.name = "HeatingInfrastructure"
	map.add_child(root)
	_house_inlet()
	_boiler_pipes()


func _group(title: String, at: Vector2) -> Node3D:
	var node := Node3D.new()
	node.name = title
	node.position = map._ground(at)
	root.add_child(node)
	return node


func _house_inlet() -> void:
	var center := Layout.lot_center("b1_s")
	var group := _group("House5BasementInlet", center)
	# The street-facing south wall is visible from the default isometric camera.
	# Keep the middle of the facade clear for Nina and the residents' gathering.
	for x in [-28.0, -17.0, 13.0, 22.0]:
		map._box(Vector3(2.2, 0.85, 0.12), Vector3(x, 0.85, 6.08), Color("444e49"), group)
		for dx in [-0.65, 0.0, 0.65]:
			map._box(Vector3(0.09, 0.85, 0.14), Vector3(x + dx, 0.85, 6.17), INSULATION, group)
	map._box(Vector3(7.5, 0.14, 3.2), Vector3(30, 0.08, 8.1), Color("888779"), group)
	for x in [28.0, 29.3]:
		_pipe(Vector3(x, 1.6, 6.1), Vector3(x, 1.6, 8.3), 0.28, INSULATION, group)
		_pipe(Vector3(x, 1.6, 8.3), Vector3(x, 0.35, 8.3), 0.28, INSULATION, group)
		_pipe(Vector3(x, 0.35, 8.3), Vector3(x, 0.35, 9.5), 0.28, STEEL, group)
		_pipe(Vector3(x, 1.6, 7.2), Vector3(x, 1.6, 7.4), 0.34, RUST, group)
		_valve(Vector3(x, 1.6, 7.5), group)
	_hatch(Vector3(32, 0.19, 8.1), group)
	map._occupy(center + Vector2(30, 8.1), Vector2(8, 3.5))
	# A second flush inspection cover marks the buried route within the yard.
	var core := Layout.lot_center("b1_k")
	var inspection := _group("House5HeatInspection", core + Vector2(36, 46.64))
	_hatch(Vector3(0, 0.18, 0), inspection)
	map._occupy(core + Vector2(36, 46.64), Vector2(2.5, 2.5))


func _boiler_pipes() -> void:
	var center := Layout.lot_center("boiler")
	var group := _group("BoilerExternalHeatMain", center)
	var worn := _group("BoilerWornInsulation", center)
	var restored := _group("BoilerRestoredInsulation", center)
	# A short paired main turns beside the boiler and descends underground.
	for z in [4.0, 6.0]:
		var gap_start := 21.0 if z == 4.0 else 24.0
		var gap_end := 28.0 if z == 4.0 else 30.0
		var a := Vector3(gap_start, 2.5, z)
		var b := Vector3(gap_end, 2.5, z)
		_pipe(Vector3(14, 2.5, z), a, 0.48, INSULATION, group)
		_pipe(b, Vector3(34, 2.5, z), 0.48, INSULATION, group)
		_pipe(a, b, 0.29, RUST, worn)
		_pipe(a, b, 0.48, INSULATION, restored)
		for cut in [a, b - Vector3.RIGHT * .16]:
			_pipe(cut, cut + Vector3.RIGHT * .16, .52, STEEL, worn)
		_pipe(Vector3(34, 2.5, z), Vector3(34, 2.5, z + 12), 0.48, INSULATION, group)
		_pipe(Vector3(34, 2.5, z + 12), Vector3(34, 0.4, z + 12), 0.48, RUST, group)
		for x in [18.0, 23.0, 28.0, 32.0]:
			_pipe(Vector3(x, 2.5, z), Vector3(x + 0.18, 2.5, z), 0.55, STEEL, group)
		_valve(Vector3(20, 2.5, z), group)
	for x in [18.0, 28.0]:
		map._box(Vector3(1.3, 1.9, 4.7), Vector3(x, 0.95, 5), Color("777970"), group)
	map._box(Vector3(3.5, 1.9, 1.2), Vector3(34, 0.95, 12), Color("777970"), group)
	_hatch(Vector3(36, 0.19, 21), group)
	map._occupy(center + Vector2(25, 5), Vector2(24, 5))
	map._occupy(center + Vector2(34, 13), Vector2(3, 19))
	map.get_node("Industrial_boiler/BoilerStoryStates").attach_heat_main(worn, restored)


func _pipe(a: Vector3, b: Vector3, radius: float, color: Color, parent: Node3D) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 12
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material(color)
	node.position = (a + b) / 2
	node.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
	parent.add_child(node)


func _hatch(at: Vector3, parent: Node3D) -> void:
	_pipe(at, at + Vector3(0, 0.08, 0), 1.05, Color("8a8473"), parent)
	_pipe(at + Vector3(0, 0.09, 0), at + Vector3(0, 0.14, 0), 0.82, STEEL, parent)
	for z in [-0.4, 0.0, 0.4]:
		map._box(Vector3(1.1, 0.04, 0.07), at + Vector3(0, 0.16, z), RUST, parent)


func _valve(at: Vector3, parent: Node3D) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.27
	mesh.outer_radius = 0.4
	mesh.rings = 16
	mesh.ring_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = _material(Color("984d3c"))
	node.position = at + Vector3(0, 0.65, 0)
	parent.add_child(node)
	_pipe(at, at + Vector3(0, 0.65, 0), 0.07, STEEL, parent)
	for axis in [Vector3.RIGHT, Vector3.BACK]:
		_pipe(node.position - axis * 0.33, node.position + axis * 0.33, 0.045, RUST, parent)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material
