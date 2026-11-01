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
	camera.size = 12.0
	camera.position = Vector3(0, 10, 0)
	scene.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.FORWARD)
	camera.current = true
	var builder = load("res://scripts/map/district_builder.gd").new()
	var index := 0
	for surface in ["concrete", "ballast", "steel"]:
		var mesh := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(6, 6)
		mesh.mesh = quad
		mesh.material_override = builder._bridge_material(surface)
		mesh.rotation.x = -PI / 2.0
		mesh.position.x = (index - 1) * 6.6
		scene.add_child(mesh)
		var label := Label.new()
		label.text = surface.capitalize() + " — 6 m patch"
		label.position = Vector2(100 + index * 500, 50)
		root.add_child(label)
		index += 1
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../art/bridges/materials.png")
	quit()
