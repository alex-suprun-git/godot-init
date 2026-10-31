extends Node3D

const BODY_PAINT := Color("d7d2c4")
const GLASS := Color("263b48")
const RUBBER := Color("17191b")


func _ready() -> void:
	_build_car()


func _build_car() -> void:
	var paint := _material(BODY_PAINT, 0.22, 0.42)
	var dark_trim := _material(Color("292b2a"), 0.15, 0.48)
	var window_material := _material(GLASS, 0.18, 0.23)
	var rubber := _material(RUBBER, 0.0, 0.92)
	var hub_material := _material(Color("999991"), 0.5, 0.4)
	var lamp_material := _material(Color("f1dfaa"), 0.05, 0.22)
	var signal_material := _material(Color("bf6337"), 0.05, 0.4)
	var rear_lamp_material := _material(Color("9c3f31"), 0.05, 0.36)

	# The body is split into simple volumes so its boxy 1980s sedan silhouette reads clearly.
	_box("LowerBody", Vector3(1.82, 0.48, 4.12), Vector3(0.0, 0.68, 0.0), paint)
	_box("Hood", Vector3(1.76, 0.18, 1.25), Vector3(0.0, 0.94, 1.28), paint)
	_box("Trunk", Vector3(1.74, 0.18, 0.78), Vector3(0.0, 0.94, -1.55), paint)

	# Cabin side profile: low at the hood and trunk, higher across the roof.
	for side in [-1.0, 1.0]:
		var x: float = 0.75 * side
		_add_quad("CabinSide", [
			Vector3(x, 1.0, 1.0), Vector3(x, 1.73, 0.38),
			Vector3(x, 1.73, -0.66), Vector3(x, 1.0, -1.12),
		], paint)

	_add_quad("Roof", [
		Vector3(-0.75, 1.73, 0.38), Vector3(0.75, 1.73, 0.38),
		Vector3(0.75, 1.73, -0.66), Vector3(-0.75, 1.73, -0.66),
	], paint)
	_add_quad("Windshield", [
		Vector3(-0.68, 1.08, 0.94), Vector3(0.68, 1.08, 0.94),
		Vector3(0.62, 1.67, 0.43), Vector3(-0.62, 1.67, 0.43),
	], window_material)
	_add_quad("RearWindow", [
		Vector3(-0.62, 1.67, -0.7), Vector3(0.62, 1.67, -0.7),
		Vector3(0.67, 1.08, -1.06), Vector3(-0.67, 1.08, -1.06),
	], window_material)

	for side in [-1.0, 1.0]:
		var x: float = 0.758 * side
		_add_quad("FrontSideWindow", [
			Vector3(x, 1.13, 0.79), Vector3(x, 1.13, -0.24),
			Vector3(x, 1.59, -0.26), Vector3(x, 1.59, 0.32),
		], window_material)
		_add_quad("RearSideWindow", [
			Vector3(x, 1.13, -0.32), Vector3(x, 1.13, -0.96),
			Vector3(x, 1.59, -0.69), Vector3(x, 1.59, -0.37),
		], window_material)
		_box("B-Pillar", Vector3(0.055, 0.53, 0.07), Vector3(x, 1.36, -0.3), dark_trim)
		_box("DoorHandle", Vector3(0.045, 0.055, 0.22), Vector3(0.91 * side, 1.0, -0.12), dark_trim)
		_box("SideMirror", Vector3(0.18, 0.12, 0.22), Vector3(0.88 * side, 1.14, 0.72), dark_trim)
		_box("SideTrim", Vector3(0.035, 0.045, 1.72), Vector3(0.91 * side, 0.76, -0.05), hub_material)

	# Front and rear bumpers, grille and lights. The car faces +Z.
	_box("FrontBumper", Vector3(1.98, 0.18, 0.2), Vector3(0.0, 0.48, 2.14), dark_trim)
	_box("RearBumper", Vector3(1.96, 0.18, 0.2), Vector3(0.0, 0.48, -2.13), dark_trim)
	_box("FrontGrille", Vector3(0.62, 0.32, 0.045), Vector3(0.0, 0.78, 2.08), dark_trim)
	for side in [-1.0, 1.0]:
		_box("Headlight", Vector3(0.42, 0.23, 0.055), Vector3(0.63 * side, 0.81, 2.08), lamp_material)
		_box("FrontIndicator", Vector3(0.12, 0.19, 0.06), Vector3(0.91 * side, 0.79, 2.07), signal_material)
		_box("TailLight", Vector3(0.2, 0.34, 0.06), Vector3(0.79 * side, 0.77, -2.08), rear_lamp_material)

	# Four wheels are their own meshes and can be replaced by detailed assets later.
	for side in [-1.0, 1.0]:
		for axle in [-1.28, 1.28]:
			var wheel_pos := Vector3(0.92 * side, 0.4, axle)
			_cylinder("Tire", 0.39, 0.22, wheel_pos, Vector3(0.0, 0.0, PI / 2.0), rubber)
			_cylinder("SteelWheel", 0.22, 0.235, wheel_pos, Vector3(0.0, 0.0, PI / 2.0), hub_material)
			_cylinder("HubCap", 0.105, 0.245, wheel_pos, Vector3(0.0, 0.0, PI / 2.0), dark_trim)


func _box(node_name: String, size: Vector3, position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	add_child(instance)
	return instance


func _cylinder(node_name: String, radius: float, height: float, position: Vector3, rotation: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = material
	add_child(instance)
	return instance


func _add_quad(node_name: String, points: Array[Vector3], material: Material) -> void:
	var vertices := PackedVector3Array([points[0], points[1], points[2], points[3]])
	var normal := (points[1] - points[0]).cross(points[2] - points[0]).normalized()
	var normals := PackedVector3Array([normal, normal, normal, normal])
	var uvs := PackedVector2Array([
		Vector2(0.0, 1.0), Vector2(1.0, 1.0),
		Vector2(1.0, 0.0), Vector2(0.0, 0.0),
	])
	var indices := PackedInt32Array([0, 1, 2, 0, 2, 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	add_child(instance)


func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result
