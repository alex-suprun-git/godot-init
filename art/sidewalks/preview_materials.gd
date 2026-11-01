# Visual material-repeat inspection, not a gameplay test.
# Godot --path init --script <absolute path to this file> -- --no-log
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := Node3D.new()
	root.add_child(scene)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("35383b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 1.0
	scene.add_child(environment)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	camera.position = Vector3(0, 10, 0)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	camera.current = true
	var shader = load("res://assets/shaders/sidewalk_surface.gdshader")
	for slabs in [true, false]:
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("surface_texture", load("res://assets/textures/ground_sidewalk_%s.png" % ("slabs" if slabs else "asphalt")))
		material.set_shader_parameter("repeat_metres", 1.5 if slabs else 4.0)
		material.set_shader_parameter("surface_brightness", 0.85 if slabs else 0.65)
		material.set_shader_parameter("mottle_strength", 0.0 if slabs else 0.22)
		if slabs:
			material.set_shader_parameter("source_region", Vector4(12.0 / 1024.0, 36.0 / 1024.0, 755.0 / 1024.0, 760.0 / 1024.0))
		var mesh := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(6, 6)
		mesh.mesh = quad
		mesh.material_override = material
		mesh.rotation.x = -PI / 2
		mesh.position.x = -3.3 if slabs else 3.3
		scene.add_child(mesh)
		var label := Label.new()
		label.text = "Slabs: 4 x 4 repeats / 50 cm slabs" if slabs else "Asphalt: 1.5 x 1.5 repeats / fine grain + soft mottling"
		label.position = Vector2(100 if slabs else 880, 30)
		root.add_child(label)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../art/sidewalks/materials.png")
	quit()
