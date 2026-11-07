# Matched actual-game ATP views, retaining the standard camera and live vehicles.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var prefix := "after"
	var gate_review := OS.get_cmdline_user_args().has("--gate-review")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-prefix="):
			prefix = arg.trim_prefix("--capture-prefix=")
	var output := ProjectSettings.globalize_path("res://../.local/atp-review")
	DirAccess.make_dir_recursive_absolute(output)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._close_important_notice()
	main.hud._close_week_panel()
	if OS.get_cmdline_user_args().has("--gate-demo"):
		await _gate_demo(main)
		return
	if OS.get_cmdline_user_args().has("--gate-cycle"):
		await _gate_cycle(main,output,prefix)
		quit()
		return
	var shots := [["gate",100.0]] if gate_review else [["context",350.0],["near",280.0]]
	for shot in shots:
		main.map._camera_goal = Vector3(-412,0,-201) if gate_review else Vector3(-373,0,-282)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = shot[1]
		await create_timer(.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(prefix+"-"+shot[0]+".png"))
		print("ATP review: ",prefix," / ",shot[0])
	quit()

func _gate_demo(main) -> void:
	# Interactive visual demo: preview the simulation clock without advancing
	# authored requests. Normal F5 play uses the unmodified simulation driver.
	DisplayServer.window_set_title("АТП — демо ворот: 19:59 → 20:00 → 06:00")
	main.map._debug_hour = -1.0
	while true:
		for step in [[19.99,2.5],[20.0,4.0],[6.0,4.0]]:
			main.sim.t = step[0]-main.sim.Week1.DAY_START_HOUR
			main.sim.overtime_hours = 0.0
			main.sim.time_changed.emit()
			_lock_gate_camera(main)
			await create_timer(step[1]).timeout

func _gate_cycle(main, output: String, prefix: String) -> void:
	# A graphical playthrough driven by the actual simulation clock. Suppress
	# only the full-screen next-day card/camera jump for these close-up captures.
	main.sim.day_started.disconnect(main._on_day_started)
	main.map._debug_hour = -1.0
	main.map._camera_goal = Vector3(-412,0,-201)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 100.0
	_advance_to(main,19.99)
	main.hud._close_important_notice()
	main.hud._close_week_panel()
	_lock_gate_camera(main)
	await create_timer(.2).timeout
	await _save(output,prefix+"-1959-open")
	print("ATP before close: ",main.sim.clock_text()," / ",main.map.location_state("atp"))
	_advance_to(main,20.0)
	_lock_gate_camera(main)
	await process_frame
	await _capture_motion(output,prefix+"-closing")
	await _save(output,prefix+"-2000-closed")
	print("ATP after close: ",main.sim.clock_text()," / ",main.map.location_state("atp"))
	# Let the same simulation return home and advance into the next day.
	for i in 30:
		if main.sim.day_index()>0:
			break
		main.sim.advance(.5)
	main.hud._close_important_notice()
	main.hud._close_week_panel()
	_lock_gate_camera(main)
	await process_frame
	await _capture_motion(output,prefix+"-opening")
	await _save(output,prefix+"-0600-open")
	print("ATP next morning: ",main.sim.clock_text()," / ",main.map.location_state("atp"))
	# Exercise the event hook without adding an authored gameplay event.
	main.map.set_location_state_override("atp",&"closed",false)
	print("ATP event override: ",main.map.location_state("atp"))
	main.map.clear_location_state_override("atp",false)
	print("ATP schedule restored: ",main.map.location_state("atp"))

func _lock_gate_camera(main) -> void:
	# Advancing through 08:00 triggers the normal office-focus event. Restore
	# both goal and current camera position after clock/scene events have run.
	main.map._camera_goal = Vector3(-412,0,-201)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 100.0
	main.map._update_camera()

func _advance_to(main, hour: float) -> void:
	for i in 80:
		var remaining: float = hour-main.sim.clock_hour()
		if remaining<=.000001:
			return
		main.sim.advance(minf(.5,remaining))

func _capture_motion(output: String, prefix: String) -> void:
	# Write PNGs after the motion; compression must not stall tween sampling.
	var frames: Array[Image] = []
	for i in 17:
		await create_timer(.125).timeout
		await RenderingServer.frame_post_draw
		frames.append(root.get_texture().get_image())
	for i in frames.size():
		frames[i].save_png(output.path_join(prefix+"-%02d.png"%i))

func _save(output: String, filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(filename+".png"))
