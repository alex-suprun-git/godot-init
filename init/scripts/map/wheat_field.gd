# Static cultivated reserve. Ground, tramlines and canopy share the lot bounds.
extends RefCounted

const Settings = preload("res://scripts/data/settings.gd")
const CROP_TEXTURE = preload("res://assets/textures/ground_wheat.png")
const CROP_SHADER = preload("res://assets/shaders/wheat_surface.gdshader")
const HARVEST_SHADER = preload("res://assets/shaders/harvested_field.gdshader")
const VERGE := 3.5
const HEADLAND := 3.0
const CANOPY_HEIGHT := 0.8
const TRAMLINE_SPACING := 24.0
const WHEEL_SPACING := 1.8
const TRACK_WIDTH := 0.36


func build(map, lot: Dictionary) -> void:
	var site: Rect2 = lot["rect"]
	var soil := site.grow(-float(lot.get("verge", VERGE)))
	var crop := soil.grow(-float(lot.get("headland", HEADLAND)))
	map._occupy(crop.get_center(), crop.size)
	var winter := Settings.season == "winter"
	map._ground_quad(soil.get_center(), soil.size, 0.035, map._season["dirt"], 8.0, false, Color.WHITE, winter)
	if Settings.season != "summer":
		_harvested_field(map, crop, winter)
		return
	var material := ShaderMaterial.new()
	material.shader = CROP_SHADER
	material.set_shader_parameter("crop_texture", CROP_TEXTURE)
	var height := CANOPY_HEIGHT
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Three implement passes, each with two real gaps exposing the soil beneath.
	var cursor := crop.position.y
	var pass_z := crop.get_center().y - TRAMLINE_SPACING
	while pass_z < crop.end.y:
		for wheel in [-WHEEL_SPACING / 2.0, WHEEL_SPACING / 2.0]:
			var lo := clampf(pass_z + wheel - TRACK_WIDTH / 2.0, crop.position.y, crop.end.y)
			var hi := clampf(pass_z + wheel + TRACK_WIDTH / 2.0, crop.position.y, crop.end.y)
			if lo > cursor:
				_strip(surface, Rect2(crop.position.x, cursor, crop.size.x, lo - cursor), height)
			cursor = maxf(cursor, hi)
		pass_z += TRAMLINE_SPACING
	if cursor < crop.end.y:
		_strip(surface, Rect2(crop.position.x, cursor, crop.size.x, crop.end.y - cursor), height)
	var instance := MeshInstance3D.new()
	instance.name = "WheatCanopy"
	instance.mesh = surface.commit()
	instance.material_override = material
	map.add_child(instance)


func _harvested_field(map, crop: Rect2, winter: bool) -> void:
	var material := ShaderMaterial.new()
	material.shader = HARVEST_SHADER
	material.set_shader_parameter("soil_texture", map._season["dirt"])
	material.set_shader_parameter("snow_cover", 1.0 if winter else 0.0)
	material.set_shader_parameter("field_center_z", crop.get_center().y)
	var plane := PlaneMesh.new()
	plane.size = crop.size
	plane.subdivide_width = 150
	plane.subdivide_depth = 48
	var ground := MeshInstance3D.new()
	ground.name = "SnowCoveredStubble" if winter else "HarvestedStubble"
	ground.mesh = plane
	ground.material_override = material
	ground.position = Vector3(crop.get_center().x, 0.065, crop.get_center().y)
	map.add_child(ground)
	_stubble(map, crop, winter)


func _stubble(map, crop: Rect2, winter: bool) -> void:
	# A sparse batched detail layer supplements the ground material at map zoom.
	# Both seasons share the same seed/positions: snow buries most of the stalks.
	var rng := RandomNumberGenerator.new()
	rng.seed = 25081997
	var instances: Array[Transform3D] = []
	var colors: Array[Color] = []
	var z := crop.position.y + 0.8
	while z < crop.end.y - 0.5:
		var x := crop.position.x + 0.8
		while x < crop.end.x - 0.5:
			var at := Vector2(x, z) + Vector2(rng.randf_range(-0.55, 0.55), rng.randf_range(-0.55, 0.55))
			var keep := rng.randf()
			var angle := rng.randf_range(0.0, TAU)
			var scale_y := rng.randf_range(0.7, 1.3)
			var tint := rng.randf()
			var pass_distance := absf(fposmod(at.y - crop.get_center().y + TRAMLINE_SPACING / 2.0, TRAMLINE_SPACING) - TRAMLINE_SPACING / 2.0)
			var in_track := absf(pass_distance - WHEEL_SPACING / 2.0) < TRACK_WIDTH / 2.0 + 0.12
			if not in_track and (not winter or keep < 0.18):
				var basis := Basis(Vector3.UP, angle).scaled(Vector3(1.0, scale_y, 1.0))
				instances.append(Transform3D(basis, Vector3(at.x, 0.075, at.y)))
				colors.append(Color("82704b").lerp(Color("bba274"), tint))
			x += 2.0
		z += 2.0
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = _stubble_mesh()
	multi.instance_count = instances.size()
	for i in instances.size():
		multi.set_instance_transform(i, instances[i])
		multi.set_instance_color(i, colors[i])
	var detail := MultiMeshInstance3D.new()
	detail.name = "ExposedWinterStems" if winter else "CutWheatStems"
	detail.multimesh = multi
	detail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	map.add_child(detail)


func _stubble_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Cut stalks have blunt tops and no ripe seed heads. Two planes per stalk.
	for offset in [Vector3(-0.13, 0, 0), Vector3(0.08, 0, 0.11), Vector3(0.0, 0, -0.1)]:
		var top: Vector3 = offset + Vector3(0.04, 0.22, 0.02)
		for across in [Vector3(0.025, 0, 0), Vector3(0, 0, 0.025)]:
			_quad(surface, offset - across, top - across * 0.65, top + across * 0.65, offset + across, Vector3.UP)
	var mesh := surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	mesh.surface_set_material(0, material)
	return mesh


func _strip(surface: SurfaceTool, rect: Rect2, height: float) -> void:
	# Short sections make the crop edge subtly irregular without thousands of props.
	var count := ceili(rect.size.x / 2.0)
	for i in count:
		var x0 := rect.position.x + rect.size.x * i / count
		var x1 := rect.position.x + rect.size.x * (i + 1) / count
		var h0 := height + 0.025 * sin(x0 * 2.7)
		var h1 := height + 0.025 * sin(x1 * 2.7)
		var a := Vector3(x0, h0, rect.position.y)
		var b := Vector3(x0, h0, rect.end.y)
		var c := Vector3(x1, h1, rect.end.y)
		var d := Vector3(x1, h1, rect.position.y)
		_quad(surface, a, b, c, d, Vector3.UP)
		_quad(surface, a, d, Vector3(x1, 0.04, a.z), Vector3(x0, 0.04, a.z), Vector3.FORWARD)
		_quad(surface, c, b, Vector3(x0, 0.04, b.z), Vector3(x1, 0.04, b.z), Vector3.BACK)
		if i == 0:
			_quad(surface, b, a, Vector3(x0, 0.04, a.z), Vector3(x0, 0.04, b.z), Vector3.LEFT)
		if i == count - 1:
			_quad(surface, d, c, Vector3(x1, 0.04, c.z), Vector3(x1, 0.04, d.z), Vector3.RIGHT)


func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for vertex in [a, c, b, a, d, c]:
		surface.set_normal(normal)
		surface.add_vertex(vertex)
