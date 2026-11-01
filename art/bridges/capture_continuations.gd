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
	var output := ProjectSettings.globalize_path("res://../art/bridges/edges").simplify_path()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	for shot in [
		["west_highway", Vector2(-640, -187.5), 140.0],
		["west_north", Vector2(-640, -85), 140.0],
		["west_south", Vector2(-640, 305), 140.0],
		["east_highway", Vector2(470, -187.5), 140.0],
		["east_north", Vector2(470, -85), 140.0],
		["east_south", Vector2(470, 305), 140.0],
		["quay_east", Vector2(460, -327), 120.0],
		["quay_west", Vector2(-630, -327), 140.0],
	]:
		main.map._camera_goal = Vector3(shot[1].x, 0, shot[1].y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[2]
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(shot[0] + ".png"))
		print("bridge review: ", shot[0])
	quit()
