# Distinct surfaces, real kerbs and coping for the station area.
extends RefCounted

const SHADER := preload("res://assets/shaders/station_ground.gdshader")
const Settings := preload("res://scripts/data/settings.gd")
const GRAIN := preload("res://assets/textures/ground_asphalt.png")

static func surface(parent: Node3D, rect: Rect2, y: float, kind: int) -> void:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("grain_texture", GRAIN)
	material.set_shader_parameter("surface_kind", kind)
	material.set_shader_parameter("site_rect", Vector4(rect.position.x, rect.position.y, rect.end.x, rect.end.y))
	material.set_shader_parameter("winter", Settings.season == "winter")
	var quad := QuadMesh.new()
	quad.size = rect.size
	var node := MeshInstance3D.new()
	node.name = ["PlatformAsphalt", "SquareConcreteSlabs", "MarketWornAsphalt"][kind]
	node.mesh = quad
	node.material_override = material
	node.rotation.x = -PI / 2.0
	node.position = Vector3(rect.get_center().x, y, rect.get_center().y)
	parent.add_child(node)

static func concrete_batch(parent: Node3D, size: Vector3, positions: Array[Vector3], name: String, base_tone := .56) -> void:
	if positions.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = size
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = positions.size()
	for i in range(positions.size()):
		multi.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
		var tone: float = base_tone + sin(float(i) * 19.3) * .025
		multi.set_instance_color(i, Color(tone, tone * .99, tone * .91))
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = .98
	var node := MultiMeshInstance3D.new()
	node.name = name
	node.multimesh = multi
	node.material_override = material
	parent.add_child(node)

static func kerb(parent: Node3D, rect: Rect2, top: float, openings: Array[Rect2] = []) -> void:
	var along_x: Array[Vector3] = []
	var along_z: Array[Vector3] = []
	for side in [rect.position.y, rect.end.y]:
		for i in range(int(rect.size.x)):
			var at := Vector2(rect.position.x + i + .5, side)
			if _open(at, openings):
				continue
			along_x.append(Vector3(at.x, top - .085, at.y))
	for side in [rect.position.x, rect.end.x]:
		for i in range(int(rect.size.y)):
			var at := Vector2(side, rect.position.y + i + .5)
			if _open(at, openings):
				continue
			along_z.append(Vector3(at.x, top - .085, at.y))
	concrete_batch(parent, Vector3(.985, .21, .16), along_x, "KerbsAlongX")
	concrete_batch(parent, Vector3(.16, .21, .985), along_z, "KerbsAlongZ")

static func _open(at: Vector2, openings: Array[Rect2]) -> bool:
	for opening in openings:
		if opening.has_point(at):
			return true
	return false
