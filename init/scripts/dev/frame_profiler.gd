# Opt-in rendered benchmark. Wall-clock samples; never use turbo or headless.
# Samples stay in memory until each phase ends so disk I/O is outside measurement.
extends Node

var seconds := 5.0


func run(main, output_dir: String) -> void:
	if DisplayServer.get_name() == "headless" or Engine.time_scale != 1.0:
		push_error("performance requires a rendered window and no --turbo")
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile-seconds="):
			seconds = maxf(1.0, float(arg.trim_prefix("--profile-seconds=")))
	var folder := output_dir if output_dir != "" else "user://performance"
	DirAccess.make_dir_recursive_absolute(folder)
	var file := FileAccess.open(folder.path_join("performance.json"), FileAccess.WRITE)
	if file == null:
		push_error("Cannot write performance report: " + folder)
		return
	var map = main.map
	var viewport := get_viewport()
	var rid := viewport.get_viewport_rid()
	var vsync := DisplayServer.window_get_vsync_mode()
	var cap := Engine.max_fps
	var old_t: float = main.sim.t
	var old_speed: float = main.speed
	var old_zoom: float = map._zoom
	var old_goal: Vector3 = map._camera_goal
	var old_target: Vector3 = map._camera_target
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	main.set_speed(0.0)
	map.profile_ambient = true
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var report := {
		"engine": Engine.get_version_info(), "os": OS.get_name(),
		"cpu": OS.get_processor_name(), "gpu": RenderingServer.get_video_adapter_name(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"viewport": str(viewport.get_visible_rect().size), "seconds_per_phase": seconds,
		"camera": map.Settings.camera_mode, "season": map.Settings.season,
		"vsync_disabled": true, "rows": [],
		"notes": "Paused gameplay clock, moving ambient agents. Hidden keeps CPU updates; off removes both. Counts are density-visible, not camera-visible. GPU zero may mean unavailable. Repeats are sequential, not identical traffic snapshots. Station crowds and parked cars remain in every phase."
	}
	for setup in [[8.0, map.ZOOM_DEFAULT], [12.0, map.ZOOM_DEFAULT], [17.0, map.ZOOM_DEFAULT], [12.0, map.ZOOM_MAX]]:
		main.sim.t = float(setup[0]) - 6.0
		map._zoom = setup[1]
		map._camera_goal = map.DEFAULT_TARGET
		map._camera_target = map.DEFAULT_TARGET
		for mode in ["full", "hidden", "off", "full_repeat"]:
			map.profile_hide_ambient = mode in ["hidden", "off"]
			map.profile_skip_ambient = mode == "off"
			# Hide explicitly before skipping updates (including any just-respawned cars).
			if mode == "off":
				for agent in map._ambient.agents:
					agent["visual"].visible = false
			await get_tree().create_timer(2.0, true, false, true).timeout
			var row := await measure(map, rid)
			row.merge({"hour": setup[0], "zoom": setup[1], "mode": mode})
			report["rows"].append(row)
			file.seek(0)
			file.store_string(JSON.stringify(report, "\t"))
			file.flush()
			print("performance: ", JSON.stringify(row))
			if mode == "full" and setup[0] == 12.0 and setup[1] == map.ZOOM_DEFAULT:
				await RenderingServer.frame_post_draw
				viewport.get_texture().get_image().save_png(folder.path_join("performance.png"))
	map.profile_ambient = false
	map.profile_hide_ambient = false
	map.profile_skip_ambient = false
	main.sim.t = old_t
	main.set_speed(old_speed)
	map._zoom = old_zoom
	map._camera_goal = old_goal
	map._camera_target = old_target
	DisplayServer.window_set_vsync_mode(vsync)
	Engine.max_fps = cap
	RenderingServer.viewport_set_measure_render_time(rid, false)
	file.close()
	print("performance report: ", ProjectSettings.globalize_path(folder.path_join("performance.json")))


func measure(map, rid: RID) -> Dictionary:
	var samples := {"frame_ms": [], "ambient_step_ms": [], "ambient_visual_ms": [], "render_cpu_ms": [], "render_gpu_ms": [], "draw_calls": [], "primitives": []}
	await RenderingServer.frame_post_draw
	var started := Time.get_ticks_usec()
	var previous := started
	while Time.get_ticks_usec() - started < seconds * 1000000.0:
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		samples.frame_ms.append((now - previous) / 1000.0)
		previous = now
		samples.ambient_step_ms.append(map.profile_step_ms)
		samples.ambient_visual_ms.append(map.profile_visual_ms)
		samples.render_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
		samples.render_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		samples.draw_calls.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		samples.primitives.append(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	var row := {"frames": samples.frame_ms.size(), "metrics": {}, "pool_walkers": 0, "pool_cars": 0, "visible_walkers": 0, "visible_cars": 0}
	for agent in map._ambient.agents:
		var kind := "cars" if agent["is_car"] else "walkers"
		row["pool_" + kind] += 1
		if agent["visible"]:
			row["visible_" + kind] += 1
	for key in samples:
		var values: Array = samples[key]
		values.sort()
		var total := 0.0
		for value in values:
			total += float(value)
		row.metrics[key] = {"mean": total / values.size(), "p95": values[int(ceil(values.size() * .95)) - 1], "p99": values[int(ceil(values.size() * .99)) - 1], "max": values.back()}
	row["fps"] = 1000.0 / float(row.metrics.frame_ms.mean)
	row["over_33ms_percent"] = 100.0 * samples.frame_ms.filter(func(v): return v > 33.333).size() / samples.frame_ms.size()
	return row
