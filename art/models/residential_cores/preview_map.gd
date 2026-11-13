extends SceneTree

const EXPORT_DIR := "res://../art/models/residential_cores/exports"
const OUTPUT := "res://../.local/residential-cores/yards.png"
const Yards = preload("preview_yards.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var headless := DisplayServer.get_name() == "headless"
	var main = null
	var yards := Yards.new()
	if not headless:
		main = load("res://main.tscn").instantiate()
		root.add_child(main)
		main.hud._close_important_notice()
		main.hud._close_week_panel()
		yards.build(main.map)
	var layout = load("res://scripts/data/district_layout.gd")
	var school: Vector2 = layout.lot_center("a1_k")
	var kindergarten: Vector2 = layout.lot_center("b2_k")
	var maintenance: Vector2 = layout.lot_center("b1_k")
	var trade: Vector2 = layout.lot_center("a2_k")
	var placements := {
		"school": school + Vector2(-9, -13),
		"football_pitch": school + Vector2(29, 18),
		"kindergarten": kindergarten + Vector2(0, -8),
		"maintenance": maintenance + Vector2(26, -24),
		"repair": trade + Vector2(-21, 12),
		"kiosk_blue": trade + Vector2(-16, 22),
		"kiosk_cream": trade + Vector2(-11, 22),
	}
	var models := Node3D.new()
	(root if headless else main.map).add_child(models)
	for id in placements:
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var path := ProjectSettings.globalize_path(EXPORT_DIR.path_join(id + ".glb"))
		var result := document.append_from_file(path, state)
		if result != OK:
			push_error("Could not load %s (%d)" % [id, result])
			quit(1)
			return
		var model := document.generate_scene(state) as Node3D
		if model == null or model.find_children("*", "MeshInstance3D", true, false).is_empty():
			push_error("No mesh in %s" % id)
			quit(1)
			return
		models.add_child(model)
		var at: Vector2 = placements[id]
		model.position = Vector3(at.x, 0.09, at.y)
		if id == "football_pitch":
			model.rotation.y = -PI / 2.0
			if not headless:
				yards.dress_pitch(model)
		print("residential core loaded: ", id)
	if headless:
		quit()
		return
	var target := Vector3(-205, 0, 85)
	main.map._camera_goal = target
	main.map._camera_target = target
	main.map._zoom = 620.0
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	quit(0 if root.get_texture().get_image().save_png(output) == OK else 1)
