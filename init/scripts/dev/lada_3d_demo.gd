extends Node3D

const LADA_MODEL := preload("res://assets/models/vehicles/lada_sedan_v2.glb")

var _orbit: Node3D
var _camera: Camera3D
var _dragging := false


func _ready() -> void:
	_setup_world()
	_build_ground()
	_orbit = Node3D.new()
	_orbit.name = "CameraOrbit"
	add_child(_orbit)
	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.position = Vector3(5.6, 4.1, 7.2)
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 3.8
	_orbit.add_child(_camera)
	_camera.look_at(Vector3(0.0, 0.82, 0.0), Vector3.UP)
	_camera.current = true
	var model: Node3D = LADA_MODEL.instantiate()
	add_child(model)
	DisplayServer.window_set_title("Lada — Blender V2")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			_capture_preview.call_deferred(argument.trim_prefix("--capture="))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.size = clampf(_camera.size * 0.9, 1.4, 10.0)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.size = clampf(_camera.size * 1.1, 1.4, 10.0)
	elif event is InputEventMouseMotion and _dragging:
		_orbit.rotation.y -= event.relative.x * 0.008
		_camera.position.y = clampf(_camera.position.y - event.relative.y * 0.025, 1.5, 8.0)
		_camera.look_at(Vector3(0.0, 0.82, 0.0), Vector3.UP)


func _setup_world() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("343d38")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c9d7dc")
	environment.ambient_light_energy = 0.55
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("8298a7")
	sky_material.sky_horizon_color = Color("ccd2cd")
	sky_material.ground_bottom_color = Color("343e37")
	sky_material.ground_horizon_color = Color("a6afa4")
	var reflection_sky := Sky.new()
	reflection_sky.sky_material = sky_material
	environment.sky = reflection_sky
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_energy = 1.4
	sun.light_color = Color("fff1d8")
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
	fill.light_energy = 0.4
	fill.light_color = Color("c6dbf1")
	add_child(fill)


func _build_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "DisplayGround"
	var plane := PlaneMesh.new()
	plane.size = Vector2(24.0, 24.0)
	ground.mesh = plane
	ground.position.y = -0.008
	ground.material_override = _material(Color("56635b"), 0.0, 0.95)
	add_child(ground)


func _capture_preview(path: String) -> void:
	for frame in range(10):
		await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save Lada preview: %s" % error_string(error))
	get_tree().quit(0 if error == OK else 1)


func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.metallic = metallic
	result.roughness = roughness
	return result
