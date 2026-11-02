# Current scheduled pass on the inner eastern embankment track.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	var traffic = main.map.get_node("RailwayTraffic")
	traffic.set_process(false)
	for tick in range(240):
		traffic.advance(0.5)
		var state: Dictionary = traffic.snapshot()
		var head: Node3D = traffic.get_child(0).get_child(0)
		if state["trains"][0]["visible"] and head.position.z > 40 and head.position.z < 50:
			break
	var output := ProjectSettings.globalize_path("res://../art/models/public_transport/er2/previews")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output)
	for shot in [
		["godot-embankment", Vector2(400, 15), 155.0],
		["godot-embankment-close", Vector2(410, 38), 65.0],
	]:
		main.map._camera_goal = Vector3(shot[1].x, 6.0, shot[1].y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[2]
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(shot[0] + ".png"))
		print("ER2 context capture: ", shot[0])
	traffic.set_process(true)
	if OS.get_cmdline_user_args().has("--keep-open"):
		main.map._camera_goal = Vector3(400, 6.0, 15)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = 155.0
		return
	quit()
