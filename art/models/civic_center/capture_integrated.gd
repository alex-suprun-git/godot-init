# Focused visual inspection of the normal map; does not replace any lot visuals.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	main.map._debug_hour = 12.0
	main.map._camera_goal = Vector3(72, 0, 76)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 220.0
	main.map._update_camera()
	await create_timer(1).timeout
	main.process_mode = Node.PROCESS_MODE_DISABLED
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://../.local/civic-center-review/")
	var prefix := "integrated"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-prefix="):
			prefix = arg.trim_prefix("--capture-prefix=")
	root.get_texture().get_image().save_png(dir + prefix + "-overview.png")
	print("Civic arrival: ", main.sim.graph.doorsteps.get("ispolkom"))
	print("Player position: ", main.sim.actors["me"]["pos"])
	main.map.camera.position = Vector3(-280, 300, 430)
	main.map.camera.look_at(Vector3(53, 5, 72))
	main.map.camera.size = 85
	await create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(dir + prefix + "-entrance.png")
	if not OS.get_cmdline_user_args().has("--keep-open"):
		quit()
