# Focused graphical review of the seven industrial sites; no gameplay tests.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prefix := "after"
	var selected := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-prefix="):
			prefix = arg.trim_prefix("--capture-prefix=")
		if arg.begins_with("--only="):
			selected = arg.trim_prefix("--only=")
	var output := ProjectSettings.globalize_path("res://../.local/industrial-review")
	DirAccess.make_dir_recursive_absolute(output)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._close_important_notice()
	main.hud._close_week_panel()
	print("Industrial ensembles: ", get_nodes_in_group("industrial_sites").size())
	# Advance the existing ambient traffic, without changing the week or requests.
	for i in 300:
		main.map._move_ambient(.1)
	for shot in [
		["overview", Vector2(-10, -235), 1050.0],
		["west", Vector2(-280, -225), 450.0],
		["border", Vector2(-5, -265), 350.0],
		["east", Vector2(260, -265), 400.0],
		["garages", Vector2(-205, -135), 350.0],
	]:
		if selected != "" and shot[0] not in selected.split(","):
			continue
		main.map._camera_goal = Vector3(shot[1].x, 0, shot[1].y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[2]
		await create_timer(.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(prefix + "-" + shot[0] + ".png"))
		print("Industrial review: ", prefix, " / ", shot[0])
	quit()
