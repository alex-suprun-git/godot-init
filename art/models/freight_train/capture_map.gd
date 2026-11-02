# Review an actual scheduled freight pass on the outer embankment track.
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
	var traffic = main.map.get_node("RailwayTraffic")
	traffic.set_process(false)
	for tick in range(1200):
		traffic.advance(0.5)
		var state: Dictionary = traffic.snapshot()
		var locomotive: Node3D = traffic.get_child(1).get_child(0)
		if state["trains"][1]["visible"] and state["trains"][1]["direction"] > 0 and locomotive.position.z < -40 and locomotive.position.z > -50:
			break
	for shot in [["godot-freight-map", 15.0, 175.0], ["godot-freight-close", 41.0, 82.0]]:
		main.map._camera_goal = Vector3(410, 6, shot[1])
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[2]
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		var output := ProjectSettings.globalize_path("res://../.local/freight-train/" + shot[0] + ".png")
		root.get_texture().get_image().save_png(output)
		print("Freight map capture: ", output)
	traffic.set_process(true)
	if not OS.get_cmdline_user_args().has("--keep-open"):
		quit()
