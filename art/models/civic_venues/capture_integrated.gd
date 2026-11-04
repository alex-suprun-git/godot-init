extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(2.0).timeout
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	main.hud.hide()
	main.map._debug_hour = 12.0
	var closeup := OS.get_cmdline_user_args().has("--venue-closeup")
	main.map._camera_goal = Vector3(83, 0, -1) if closeup else Vector3(91, 0, -1)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 145.0 if closeup else 187.0
	main.map._update_camera()
	await create_timer(1).timeout
	main.process_mode = Node.PROCESS_MODE_DISABLED
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://../.local/civic-venues-review/")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir + ("integrated-closeup.png" if closeup else "integrated-overview.png"))
	print("VENUES_CAPTURED: ", dir)
	quit()
