extends Control

func _ready() -> void:
	label_at("SUV SHAPE REWORK / SAME SCALE, CAMERAS AND LIGHTING", Vector2(24, 10), 24)
	label_at("BEFORE / v5", Vector2(24, 54), 21)
	label_at("AFTER / fresh reference v3, model v6", Vector2(824, 54), 21)
	for index in range(2):
		var file := "luxury_suv_before" if index == 0 else "luxury_suv"
		var world := viewport_at(Rect2(index * 800, 90, 800, 360), 4.1, Vector3(9, 6.5, 12))
		vehicle(world, file, 0.0)
		var side := viewport_at(Rect2(index * 800, 480, 800, 235), 3.0, Vector3(0, 0.6, 20))
		vehicle(side, file, PI / 2)
	label_at("Side silhouette / unchanged wheelbase and overall height", Vector2(24, 453), 18)
	label_at("New front / round lamps, square pods, raised bonnet and angular flares", Vector2(24, 724), 18)
	var front := viewport_at(Rect2(0, 756, 800, 300), 3.5, Vector3(0, 3.8, 14))
	vehicle(front, "luxury_suv", 0.0)
	var rear := viewport_at(Rect2(800, 756, 800, 300), 3.5, Vector3(9, 6.5, -12))
	vehicle(rear, "luxury_suv", 0.0)
	label_at("Actual GLB exports in Godot. New shape proposal; not yet integrated into city traffic.", Vector2(24, 1064), 17)
	for frame in range(18):
		await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var path := arg.trim_prefix("--capture=")
			var err := get_viewport().get_texture().get_image().save_png(path)
			print("SUV_CAPTURE ", path, " ", error_string(err))
			get_tree().quit(0 if err == OK else 1)

func vehicle(world: Node3D, file: String, yaw: float) -> void:
	var packed := load("res://models/%s.glb" % file) as PackedScene
	var model := packed.instantiate() as Node3D
	world.add_child(model)
	model.rotation.y = yaw

func label_at(text: String, pos: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("d9e0dc"))
	add_child(label)
