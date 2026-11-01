# Focused graphical comparison capture; no gameplay assertions.
# Godot --path init --script <absolute path> -- --no-log --hour=12 [--season=winter] [--output=absolute_directory]
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	var output := ProjectSettings.globalize_path("res://../art/sidewalks/after").simplify_path()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	for shot in [
		["avenue", Vector2(-5, 70), 100.0],
		["junction", Vector2(-5, -85), 70.0],
		["residential", Vector2(145, 55), 80.0],
		["overview", Vector2(-80, 70), 430.0],
		["slabs_detail", Vector2(9, -100), 30.0],
		["asphalt_detail", Vector2(152, 55), 30.0],
	]:
		main.map._camera_goal = Vector3(shot[1].x, 0, shot[1].y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[2]
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(shot[0] + ".png"))
		print("sidewalk review: ", shot[0])
	quit()
