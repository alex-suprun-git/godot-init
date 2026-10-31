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
	if OS.get_cmdline_user_args().has("--vehicles-only"):
		_run_vehicle_review()
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
	var courtyard: Vector2 = main.map.DistrictLayout.lot_center("b1_k") + Vector2(25, -55) * main.map.DistrictLayout.HOUSING_SPACING
	await _map_shot("lada_courtyard", courtyard, 65.0)
	await _map_shot("lada_street_x", Vector2(-350, -184.2), 60.0)
	await _map_shot("lada_street_z", Vector2(147.2, 20), 60.0)
	var previous_view: String = main.map.Settings.camera_mode
	main.map.Settings.camera_mode = "front"
	var clinic: Vector2 = main.map.DistrictLayout.lot_center("polyclinic") + Vector2(-30, -10)
	await _map_shot("lada_clinic_perspective", clinic, 65.0)
	main.map.Settings.camera_mode = previous_view
	if OS.get_cmdline_user_args().has("--keep-open"):
		main.map._camera_goal = Vector3(courtyard.x, 0, courtyard.y)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = main.map.ZOOM_MIN
		return
	get_tree().quit()


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
