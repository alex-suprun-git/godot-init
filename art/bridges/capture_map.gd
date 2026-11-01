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
	var output := ProjectSettings.globalize_path("res://../art/bridges/after").simplify_path()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	for shot in [
		["north_overpass", Vector2(415, -85), 100.0],
		["north_detail", Vector2(415, -85), 55.0],
		["highway_overpass", Vector2(415, -187.5), 115.0],
		["south_overpass", Vector2(415, 305), 100.0],
		["rail_bridge", Vector2(415, -310), 125.0],
		["road_bridge", Vector2(-5, -330), 140.0],
	]:
		main.map._camera_goal = Vector3(shot[1].x, 0, shot[1].y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[2]
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(shot[0] + ".png"))
		print("bridge review: ", shot[0])
	quit()
