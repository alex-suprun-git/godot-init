# Focused visual inspection of actual game assets; no automated gameplay tests.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var output := ProjectSettings.globalize_path("res://../.local/station-hub-3d")
	DirAccess.make_dir_recursive_absolute(output)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	# Existing formations only; freeze a useful train comparison beside the platform.
	var trains = main.map.get_node("RailwayTraffic")
	trains.set_process(false)
	for i in range(trains._fleet.size()):
		var train: Dictionary = trains._fleet[i]
		train["direction"] = 1
		train["model"].visible = true
		train["distance"] = train["route"].distance_near(Vector3(-89 if i == 0 else 60, .19, 395 if i == 0 else 405))
		trains._pose(train)
	# Advance the existing traffic normally in small increments to inspect entries.
	for i in range(300):
		main.map._move_ambient(.1)
	for shot in [
		["overview", Vector2(-100, 310), 350.0],
		["detail", Vector2(-100, 356), 190.0],
	]:
		if shot[0] == "detail":
			# Expose the entire platform surface/facing for material inspection.
			var commuter: Dictionary = trains._fleet[0]
			commuter["distance"] = commuter["route"].distance_near(Vector3(180, .19, 395))
			trains._pose(commuter)
		main.map._camera_goal = Vector3(shot[1].x, 0, shot[1].y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[2]
		await create_timer(.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(shot[0] + ".png"))
		print("station hub review: ", shot[0])
	print("Hub traffic entrances: ", main.map.sim.graph.entrance_position("market"))
	var bridge_ids := PackedStringArray()
	for bridge in get_nodes_in_group("map_bridges"):
		bridge_ids.append(str(bridge.get_meta("bridge_id")))
	print("Registered bridge nodes: ", bridge_ids)
	var parked_on_bridges := 0
	for vehicle in get_nodes_in_group("parked_vehicles"):
		var at: Vector3 = vehicle.global_position
		if not main.map.DistrictLayout.parking_allowed(Vector2(at.x, at.z), vehicle.get_meta("parking_footprint")):
			parked_on_bridges += 1
	print("Parked vehicles overlapping bridge/ramp footprints: ", parked_on_bridges)
	quit()
