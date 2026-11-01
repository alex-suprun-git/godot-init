# Dev-only: plays the first week automatically and saves screenshots of each
# phase, so changes can be checked without clicking through by hand.
# Run: Godot --path init -- --autoplay --shots=/absolute/output/dir
extends Node

var main
var shots_dir := ""
var _drive_shot_taken := false
var _day_card_shot_taken := false
var _crisis_handled := false
var _picket_shot_taken := false
var _leave_water_unfixed := false


func _ready() -> void:
	main = get_parent()
	_leave_water_unfixed = OS.get_cmdline_user_args().has("--autoplay-unkept")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.substr("--shots=".length())
	if OS.get_cmdline_user_args().has("--traffic-lights-only"):
		_run_traffic_light_review()
	elif OS.get_cmdline_user_args().has("--crosswalks-only"):
		_run_crosswalk_review()
	elif OS.get_cmdline_user_args().has("--vehicles-only"):
		_run_vehicle_review()
	elif OS.get_cmdline_user_args().has("--render-cost"):
		_run_render_cost()
	else:
		_run()


func _run() -> void:
	await _wait(1.5)
	main.map._zoom = main.map.ZOOM_MAX
	main.map._camera_goal = Vector3(0, 0, -20)
	await _wait(0.5)
	await _shot("0_week_briefing")
	main.hud._continue_to_tasks()
	await _shot("0_week_tasks")
	for tab in range(1, main.hud._week_tabs.get_tab_count()):
		main.hud._week_tabs.current_tab = tab
		await _shot("0_week_tab_%d" % tab)
	main.hud._week_tabs.current_tab = 0
	main.hud._close_week_panel()
	main.hud._show_important_notice(main.hud.Week1.MORNING_NEWS)
	await _shot("0_newspaper")
	main.hud._close_important_notice()
	await _shot("0_overview")
	main.map._lot_labels.visible = true
	await _shot("0_layout_labels")
	main.map._lot_labels.visible = false
	await _map_shot("0_house5_courtyard", main.map.DistrictLayout.lot_center("b1_k"), 280.0)
	await _map_shot("0_heating_house", main.hud.Week1.location_position("block5") + Vector2(25, 8), 100.0)
	await _map_shot("0_heating_boiler", main.hud.Week1.location_position("boiler") + Vector2(10, 5), 125.0)
	await _map_shot("0_housing_compact", Vector2(-205, 85), 620.0)
	await _map_shot("0_forest", Vector2(-520, 120), 390.0)
	await _map_shot("0_pond", Vector2(278, 20), 200.0)
	await _map_shot("0_administration", main.hud.Week1.location_position("office"), 250.0)
	await _map_shot("0_border_bridges", Vector2(120, -320), 880.0)
	await _map_shot("0_north", Vector2(-5, -260), 1000.0)
	await _map_shot("0_village", Vector2(275, 105), 600.0)
	await _map_shot("0_south", Vector2(-15, 350), 650.0)
	main.map._camera_goal = main.map.DEFAULT_TARGET
	main.map._zoom = main.map.ZOOM_DEFAULT
	await _wait(0.5)
	main.hud._show_contact_detail("mikhalych")
	await _shot("0_contact_detail")
	main.hud._close_contact_detail()
	main.map._zoom = main.map.ZOOM_DEFAULT
	await _wait(0.5)
	main.hud.open_card("hot_water")
	await _shot("1_card")
	main.sim.choose("hot_water", "promise")
	main.sim.choose("contractor", "pick_gusev")
	main.hud.open_card("hot_water")
	await _shot("2_card_promised")
	main.hud._close_card()
	await _shot("3_planning")

	main.start_week()
	main.set_speed(4.0)
	var live_shot_taken := false
	while main.phase == "live":
		await get_tree().process_frame
		_play_turn()
		if not _picket_shot_taken and main.map._overlays["block5:picket"].visible:
			_picket_shot_taken = true
			main.set_speed(0.0)
			await _map_shot("5_picket", main.hud.Week1.location_position("block5"), 250.0)
			main.set_speed(4.0)
		var me: Dictionary = main.sim.actors["me"]
		if not _drive_shot_taken and me["state"] == "travel" and me["driver"] and me["path_index"] >= 2:
			_drive_shot_taken = true
			main.set_speed(0.0)
			await _map_shot("5_drive", me["pos"], 120.0)
			main.set_speed(4.0)
		if not live_shot_taken and main.sim.t >= 3.0:
			live_shot_taken = true
			main.set_speed(0.0)
			await _shot("4_live")
			main.audio_debug.visible = true
			await _wait(0.5)
			await _shot("8_audio_panel")
			main.audio_debug.visible = false
			main.set_speed(4.0)
		if main._night:
			# Between days: shoot the first calendar card once the night has passed,
			# then press "Продолжить" and keep the pace.
			if not _day_card_shot_taken:
				_day_card_shot_taken = true
				await _wait(1.4)
				await _shot("5_day_card")
			await _wait(main.hud.DAY_CARD_SECONDS)
			main.hud.continue_day()
			main.set_speed(4.0)
		if main.speed == 0.0:
			# A crisis paused the game: shoot the first one, then answer it.
			if not _crisis_handled:
				_crisis_handled = true
				await _shot("5_crisis")
			_answer_crises()
			main.hud._close_card()
			main.set_speed(4.0)

	await _wait(0.5)
	await _shot("6_summary")
	main.go_to_next_week()
	await _wait(0.5)
	await _shot("7_week2")
	main.hud._overlay_panel.visible = false
	await _map_shot("7_boiler_repairing", main.hud.Week1.location_position("boiler"), 300.0)
	get_tree().quit()


# Simple player: takes the first option that is possible for every open
# request except promises and crises, which get their own handling.
func _play_turn() -> void:
	var sim = main.sim
	for id in sim.request_order:
		if _leave_water_unfixed and id == "hot_water":
			continue
		var request: Dictionary = sim.requests[id]
		if request["status"] != "open" or request["data"]["type"] == "crisis":
			continue
		_choose_first_possible(id)


# Answer every open crisis with the first option that can be chosen.
func _answer_crises() -> void:
	for id in main.sim.request_order:
		var request: Dictionary = main.sim.requests[id]
		if request["status"] == "open" and request["data"]["type"] == "crisis":
			_choose_first_possible(id)


func _choose_first_possible(id: String) -> void:
	var request: Dictionary = main.sim.requests[id]
	for option in request["data"]["options"]:
		if option["actor"] == "promise":
			continue
		if main.sim.option_block_reason(id, option) == "":
			main.sim.choose(id, option["id"])
			return


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# Focused art review; preserves the normal week autoplay and planning state.
func _run_vehicle_review() -> void:
	await _wait(1.5)
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	print("3D Lada instances: ", get_tree().get_nodes_in_group("vehicle_lada").size())
	print("3D vehicles by model: total ", get_tree().get_nodes_in_group("vehicle_models").size(), ", lada ", get_tree().get_nodes_in_group("vehicle_lada").size(), ", wagon ", get_tree().get_nodes_in_group("vehicle_lada_wagon").size(), ", volga ", get_tree().get_nodes_in_group("vehicle_volga").size(), " (real mesh: ", main.map.VehicleModels.has_volga_model(), ")")
	var moving_cars := 0
	var moving_volgas := 0
	for agent in main.map._ambient.agents:
		if not agent["is_car"]:
			continue
		moving_cars += 1
		if agent["visual"].is_in_group("vehicle_volga"):
			moving_volgas += 1
	print("Moving civilian Volgas: ", moving_volgas, " / ", moving_cars, " (target share 1/15)")
	for key in main.map.VehicleModels._paint_materials:
		if str(key).begins_with("volga|"):
			print("Civilian Volga paint variant: ", key)
	var courtyard: Vector2 = main.map.DistrictLayout.lot_center("b1_k") + Vector2(25, -55) * main.map.DistrictLayout.HOUSING_SPACING
	await _map_shot("lada_courtyard", courtyard, 65.0)
	await _map_shot("lada_street_x", Vector2(-350, -184.2), 60.0)
	await _map_shot("lada_street_z", Vector2(147.2, 20), 60.0)
	var previous_view: String = main.map.Settings.camera_mode
	main.map.Settings.camera_mode = "front"
	var clinic: Vector2 = main.map.DistrictLayout.lot_center("polyclinic") + Vector2(-30, -10)
	await _map_shot("lada_clinic_perspective", clinic, 65.0)
	var volgas := get_tree().get_nodes_in_group("vehicle_volga")
	if not volgas.is_empty():
		var v: Node3D = volgas[0]
		main.map.Settings.camera_mode = previous_view
		await _map_shot("volga_first", Vector2(v.position.x, v.position.z), 45.0)
	# Capture real moving Volgas, rather than relying on a parked-car view.
	var volga_shots := 0
	for agent in main.map._ambient.agents:
		if not agent["is_car"] or not agent["visual"].is_in_group("vehicle_volga"):
			continue
		var at: Vector2 = agent["pos"]
		await _map_shot("volga_traffic_%d" % volga_shots, at, 35.0)
		volga_shots += 1
		if volga_shots >= 3:
			break
	main.map.Settings.camera_mode = previous_view
	if OS.get_cmdline_user_args().has("--keep-open"):
		main.map._camera_goal = Vector3(courtyard.x, 0, courtyard.y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = main.map.ZOOM_MIN
		return
	get_tree().quit()


# Prints what the 3D vehicles cost per frame at the closest, default and widest
# zoom: with automatic mesh LOD, with LOD off, and with the vehicles hidden.
func _run_render_cost() -> void:
	await _wait(1.5)
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	var vehicles := get_tree().get_nodes_in_group("vehicle_models")
	print("render-cost: vehicle instances ", vehicles.size())
	var viewport := get_viewport()
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)
	var default_threshold := viewport.mesh_lod_threshold
	for zoom in [main.map.ZOOM_MIN, main.map.ZOOM_DEFAULT, main.map.ZOOM_MAX]:
		main.map._camera_goal = main.map.DEFAULT_TARGET
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = zoom
		await _wait(0.5)
		var rows := {}
		for mode in ["lod", "no_lod", "hidden"]:
			viewport.mesh_lod_threshold = 0.0 if mode == "no_lod" else default_threshold
			for vehicle in vehicles:
				vehicle.visible = mode != "hidden"
			await _wait(0.3)
			rows[mode] = await _render_info()
		await _shot("render_cost_%d" % int(zoom))
		print("render-cost zoom %d: %s" % [int(zoom), JSON.stringify(rows)])
	viewport.mesh_lod_threshold = default_threshold
	get_tree().quit()


func _render_info() -> Dictionary:
	# Average the measured render time over a few frames; single frames are noisy.
	var rid := get_viewport().get_viewport_rid()
	var cpu := 0.0
	var gpu := 0.0
	for i in 20:
		await RenderingServer.frame_post_draw
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	return {
		"cpu_ms": snappedf(cpu / 20.0, 0.01),
		"gpu_ms": snappedf(gpu / 20.0, 0.01),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
	}


func _map_shot(name: String, center: Vector2, zoom: float) -> void:
	main.map._camera_goal = Vector3(center.x, 0, center.y)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = zoom
	await _wait(0.3)
	await _shot(name)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if shots_dir == "":
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png(shots_dir.path_join(name + ".png"))
	print("shot: ", name)


# Focused visual review of the boulevard's yard link and both asphalt junctions.
func _run_crosswalk_review() -> void:
	await _wait(1.5)
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	print("Crosswalk review: ", main.map.AMBIENT_WALKERS, " walkers; ", main.map.DistrictLayout.crosswalks().size(), " marked crossings")
	await _map_shot("crosswalk_yard", Vector2(-5, 87.2), 140.0)
	await _map_shot("crosswalk_south", Vector2(-5, 305), 150.0)
	await _map_shot("crosswalk_highway", Vector2(-5, -187.5), 150.0)
	# Observe naturally moving pedestrians; capture someone actually on a zebra.
	var captured := false
	for i in 120:
		await _wait(0.1)
		for agent in main.map._ambient.agents:
			if agent["is_car"] or not agent["visible"]:
				continue
			var edge: Dictionary = agent["graph"].edges[agent["edge"]]
			if edge["crossing"] and agent["along"] > 2.0 and agent["along"] < edge["length"] - 2.0:
				await _map_shot("crosswalk_walking", agent["pos"], 65.0)
				print("Crosswalk review: observed pedestrian using zebra at ", agent["pos"])
				captured = true
				break
		if captured:
			break
	get_tree().quit()


# Static placement at every registered junction plus a dev-only lens preview.
func _run_traffic_light_review() -> void:
	await _wait(1.5)
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	var registry = main.map.TrafficIntersections
	var lights := get_tree().get_nodes_in_group("traffic_lights")
	print("Traffic light review: ", lights.size(), " fixtures at ", registry.JUNCTIONS.size(), " intersections")
	for id in registry.JUNCTIONS:
		var data: Dictionary = registry.junction(id)
		await _map_shot("signals_" + id, data["center"], 120.0)
		print("Traffic light junction ", id, ": ", registry.fixtures(id).size(), " approaches; crossings ", data["crossing_ids"])
	await _map_shot("signals_play_zoom", registry.junction("axis_north")["center"], main.map.ZOOM_MIN)
	var first = lights[0]
	for light in lights:
		if light.binding["id"] == "axis_north/south":
			first = light
	var at := Vector2(first.position.x, first.position.z)
	await _map_shot("signal_detail_off", at, 28.0)
	first.set_signal("green")
	await _map_shot("signal_detail_green", at, 28.0)
	first.set_signal("red_amber")
	await _map_shot("signal_detail_red_amber", at, 28.0)
	first.set_signal("off")
	var previous: String = main.map.Settings.camera_mode
	main.map.Settings.camera_mode = "front"
	await _map_shot("signals_perspective", registry.junction("axis_north")["center"], 100.0)
	main.map.Settings.camera_mode = previous
	main.map._debug_hour = 22.0
	await _map_shot("signals_night_off", registry.junction("axis_north")["center"], 100.0)
	main.map.Settings.camera_mode = previous
	first.set_signal("red_amber")
	await _map_shot("signal_detail_night_red_amber", at, 28.0)
	first.set_signal("off")
	get_tree().quit()
