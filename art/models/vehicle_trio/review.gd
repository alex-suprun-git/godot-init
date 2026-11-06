extends Control

const FILES := ["luxury_suv", "luxury_sedan", "rural_4x4", "volga_gaz24", "truck_zil_flatbed", "raf_ambulance", "bus_paz_3205"]
const NAMES := ["LUXURY SUV / 4 side doors", "LUXURY SEDAN", "RURAL 4x4 / 2 side doors"]

func _ready() -> void:
	label_at("VEHICLE TRIO / REAL PROTOTYPE PROPORTIONS", Vector2(24, 10), 25)
	label_at("G320 long / W140 S500 long / Niva 21213 references. Metre-based wheelbase, track and body landmarks.", Vector2(24, 47), 17)
	for i in range(3):
		label_at(NAMES[i], Vector2(20 + i * 533, 82), 19)
		var world := viewport_at(Rect2(i * 533, 112, 533, 380), 6.6, Vector3(9, 6.5, 12))
		add_vehicle(world, i, Vector3(-2.0, 0, 0.65), 0)
		add_vehicle(world, i, Vector3(2.0, 0, -0.65), PI)
	label_at("REAL SIZE / new SUV, sedan, rural 4x4, RAF, PAZ, ZIL / 1 metre grid", Vector2(24, 496), 18)
	var side := viewport_at(Rect2(0, 526, 1600, 235), 6.4, Vector3(0, 1.3, 20))
	var real_order := [0, 1, 2, 5, 6, 4]
	for i in range(6):
		var index: int = real_order[i]
		var real_model := add_vehicle(side, index, Vector3(-17.5 + i * 7, 0, 0), PI / 2)
		if index == 5:
			real_model.scale /= 0.85
		elif index == 6:
			real_model.scale /= 0.80
		elif index == 4:
			real_model.scale /= 1.05 * 0.80 * 4.3 / 4.37
	label_at("GAME SCALE / new trio x0.85, RAF as exported, PAZ x0.80, ZIL existing map factor", Vector2(24, 772), 18)
	var bench := viewport_at(Rect2(0, 805, 1600, 240), 7.8, Vector3(12, 13, 22))
	var order := [0, 1, 2, 5, 6, 4]
	for i in range(6):
		var offset: float = -15 + i * 6
		var model := add_vehicle(bench, order[i], Vector3(offset * 0.878, 0, -offset * 0.479), PI / 2)
		if order[i] < 3:
			model.scale *= 0.85
	label_at("Top and side: real size. Bottom: proposed 0.85 presentation to match RAF. No scale baked into the new GLBs.", Vector2(24, 1063), 17)
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

func add_vehicle(world: Node3D, index: int, pos: Vector3, yaw: float) -> Node3D:
	var packed := load("res://models/%s.glb" % FILES[index]) as PackedScene
	var model := packed.instantiate() as Node3D
	world.add_child(model)
	model.position = pos
	model.rotation.y = yaw
	if index == 3:
		model.scale *= 0.90 * 4.3 / 4.37
	elif index == 4:
		model.scale *= 1.05 * 0.80 * 4.3 / 4.37
	elif index == 6:
		model.scale *= 0.80
	return model
