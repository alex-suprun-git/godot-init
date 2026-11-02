extends Control

const FILES := ["volga_gaz24", "uaz_police", "raf_ambulance", "bus_paz_3205", "truck_zil_flatbed"]
const CAPTIONS := ["Volga · map scale × 0.90", "UAZ · 3.774 m / 85%", "RAF · 4.310 m / 85%", "PAZ · existing 0.80 scale", "ZIL · previous scale × 1.05"]

func _ready() -> void:
	label_at("SERVICE VEHICLES  /  GODOT EXPORT REVIEW", Vector2(28, 12), 25)
	label_at("Same lighting and camera. Both vans uniformly reduced by 15%; benchmarks use their existing game presentation.", Vector2(28, 47), 17)
	var lineup := viewport_at(Rect2(0, 78, 1600, 390), 12.5, Vector3(12, 13, 22))
	for i in range(5):
		var x: float = -14.0 + i * 7.0
		var model := add_vehicle(lineup, i, Vector3(x, 0, 0), PI / 2.0, true)
		var caption := Label3D.new()
		caption.text = CAPTIONS[i]
		caption.font_size = 34
		caption.pixel_size = 0.008
		caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		caption.no_depth_test = true
		caption.position = Vector3(x, 0.12, 2.5)
		lineup.add_child(caption)
	label_at("UAZ  /  front, side and rear silhouette", Vector2(24, 470), 19)
	label_at("RAF  /  independent body, glazing and medical livery", Vector2(824, 470), 19)
	var uaz := viewport_at(Rect2(0, 503, 800, 345), 6.6, Vector3(9, 6.5, 12))
	var raf := viewport_at(Rect2(800, 503, 800, 345), 6.6, Vector3(9, 6.5, 12))
	add_vehicle(uaz, 1, Vector3(-2.1, 0, 0.5), 0.0, false)
	add_vehicle(uaz, 1, Vector3(2.0, 0, -0.5), PI, false)
	add_vehicle(raf, 2, Vector3(-2.1, 0, 0.5), 0.0, false)
	add_vehicle(raf, 2, Vector3(2.1, 0, -0.5), PI, false)
	label_at("MAP READABILITY  /  100% default zoom, iso 45° / 35.264° · 900 px equivalent · vans at 85%", Vector2(24, 860), 18)
	# Cropped map view: maintain exactly 900 / (350 * 0.573) px per metre.
	var map_view := viewport_at(Rect2(0, 895, 1600, 165), 165.0 * (350.0 * 0.573) / 900.0, Vector3(30, 30, 30))
	for i in range(5):
		var pos := Vector3(-12.0+i*6.0, 0, 12.0-i*6.0)
		add_vehicle(map_view, i, pos, PI / 2.0, true)
	label_at("Isolated engine review; placement at civic buildings is a separate integration step. Left to right: Volga, UAZ, RAF, PAZ, ZIL.", Vector2(24, 1070), 16)
	for frame in range(18):
		await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var path := arg.trim_prefix("--capture=")
			var err := get_viewport().get_texture().get_image().save_png(path)
			print("PREVIEW_CAPTURE ", path, " ", error_string(err))
			get_tree().quit(0 if err == OK else 1)

func label_at(text: String, pos: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("d9e0dc"))
	add_child(label)

func add_vehicle(world: Node3D, index: int, pos: Vector3, yaw: float, presentation: bool) -> Node3D:
	var packed := load("res://models/%s.glb" % FILES[index]) as PackedScene
	var model := packed.instantiate() as Node3D
	world.add_child(model)
	model.position = pos
	model.rotation.y = yaw
	if presentation:
		if index == 0:
			model.scale *= 0.90 * 4.3 / 4.37
		elif index == 3:
			model.scale *= 0.80
		elif index == 4:
			model.scale *= 1.05 * 0.80 * 4.3 / 4.37
	# The administration Volga uses the GLB's original black lacquer, as in-game.
	return model

func viewport_at(rect: Rect2, camera_size: float, eye: Vector3) -> Node3D:
	var holder := SubViewportContainer.new()
	holder.position = rect.position
	holder.size = rect.size
	add_child(holder)
	var vp := SubViewport.new()
	vp.size = Vector2i(rect.size)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	holder.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("384446")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9d7dc")
	env.ambient_light_energy = 0.65
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.3
	sun.light_color = Color("fff1d8")
	sun.shadow_enabled = true
	world.add_child(sun)
	var plane := MeshInstance3D.new()
	var geo := PlaneMesh.new()
	geo.size = Vector2(160, 160)
	plane.mesh = geo
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("515d57")
	mat.roughness = 0.95
	plane.material_override = mat
	plane.position.y = -0.006
	world.add_child(plane)
	var grid := ImmediateMesh.new()
	grid.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(-40, 41):
		grid.surface_add_vertex(Vector3(i, 0.002, -40))
		grid.surface_add_vertex(Vector3(i, 0.002, 40))
		grid.surface_add_vertex(Vector3(-40, 0.002, i))
		grid.surface_add_vertex(Vector3(40, 0.002, i))
	grid.surface_end()
	var grid_node := MeshInstance3D.new()
	grid_node.mesh = grid
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color("657068")
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	grid_node.material_override = grid_mat
	world.add_child(grid_node)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = camera_size
	cam.position = eye
	cam.look_at(Vector3(0, 0.5, 0))
	cam.current = true
	return world
