# Dev-only: plays the first week automatically and saves screenshots of each
# phase, so changes can be checked without clicking through by hand.
# Run: Godot --path init -- --autoplay --shots=/absolute/output/dir
# Pick parts with --only=<scenario>[,<scenario>...]; without it the full run
# (office, map, week) plays. See SCENARIOS for the list. --turbo[=N] speeds the
# engine clock up N times (default 10) for quick agent checks.
extends Node

const SCENARIOS := {
	"header": "_run_header_review", # calendar, paused overtime and scale fit
	"press": "_run_press_review", # authored front page and actual next-week retrospective
	"ui-motion": "_run_ui_motion", # left drawer motion, availability and quest pictograms
	"newspaper": "_run_newspaper_review", # front-page layout only
	"ui": "_run_ui_review", # newspaper, modal scroll, assigned markers, contacts drawer
	"office": "_run_office", # briefing, week tasks, newspaper, contact, request card, planning
	"map": "_run_map_tour", # overview, lot labels and the district map tour
	"week": "_run_week", # plays the whole week live, then the summary and week two
	"routine": "_run_routine", # dormitory dawn, office arrival, overtime, rent and monthly salary
	"tokens": "_run_token_review", # portrait feet at home and after a fast personal trip
	"paperwork": "_run_paperwork", # interruption, overnight progress, calls and weekly completion
	"contacts": "_run_contact_availability", # off-map/red after hours, interrupted job and manual reassignment
	"requests": "_run_request_lifecycle", # arrival ends reaction timer/marker; late travel can expire
	"edges": "_run_edges_review",
	"vehicles": "_run_vehicle_review",
	"crosswalks": "_run_crosswalk_review",
	"traffic-lights": "_run_traffic_light_review",
	"render-cost": "_run_render_cost",
	"performance": "_run_performance",
	"performance-camera": "_run_performance_camera",
	"field": "_run_field_review",
	"traffic": "_run_traffic_review",
	"gazelle": "_run_gazelle_review",
	"trains": "_run_train_review",
}
const FULL_RUN := ["office", "map", "week"]

var main
var shots_dir := ""
var _drive_shot_taken := false
var _day_card_shot_taken := false
var _crisis_handled := false
var _picket_shot_taken := false
var _leave_water_unfixed := false
var _week_choices_made := false
var _session_profiler


func _ready() -> void:
	main = get_parent()
	_leave_water_unfixed = OS.get_cmdline_user_args().has("--autoplay-unkept")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.substr("--shots=".length())
		elif arg == "--turbo" or arg.begins_with("--turbo="):
			# Runs the whole engine clock faster: sim, nights, tweens and waits alike.
			# The sim sub-steps each frame, so large frames do not skip events.
			Engine.time_scale = float(arg.trim_prefix("--turbo=")) if "=" in arg else 10.0
			print("autoplay: turbo x", Engine.time_scale)
	_run(_scenarios())


func _scenarios() -> Array:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--only="):
			var picked := Array(arg.trim_prefix("--only=").split(",", false))
			for name in picked:
				if not SCENARIOS.has(name):
					push_error("autoplay: unknown scenario '%s'; known: %s" % [name, ", ".join(SCENARIOS.keys())])
					return []
			return picked
	# Older single-purpose flags.
	for name in ["crosswalks", "edges", "vehicles", "traffic-lights"]:
		if args.has("--%s-only" % name):
			return [name]
	if args.has("--render-cost"):
		return ["render-cost"]
	return FULL_RUN


func _run(scenarios: Array) -> void:
	if OS.get_cmdline_user_args().has("--profile"):
		if Engine.time_scale != 1.0 or DisplayServer.get_name() == "headless" or scenarios.has("performance"):
			push_error("--profile needs a rendered run, no turbo, and no performance ablation scenario")
			get_tree().quit(1)
			return
		_session_profiler = load("res://scripts/dev/session_profiler.gd").new()
		add_child(_session_profiler)
		_session_profiler.start(main, shots_dir)
	await _wait(1.5)
	for name in scenarios:
		print("autoplay: scenario ", name)
		if _session_profiler != null:
			_session_profiler.scenario = name
		await call(SCENARIOS[name])
	if _session_profiler != null:
		_session_profiler.finish()
	# --keep-open leaves the game running where the last scenario stopped.
	if not OS.get_cmdline_user_args().has("--keep-open"):
		get_tree().quit()


# Gets the start-of-week briefing and task panel out of the way, for scenarios
# that only need the map.
func _dismiss_briefing() -> void:
	main.hud._close_important_notice()
	main.hud._close_week_panel()


func _run_routine() -> void:
	_dismiss_briefing()
	await _map_shot("routine_06_dormitory", main.hud.Week1.location_position("dormitory"), 340.0)
	main.start_week()
	main.set_speed(0.0)
	main.sim.advance(2.0)
	print("routine arrival: ", main.sim.clock_text(), " / ", main.sim.actors["me"]["lot"], " / boss=", main.sim.flags.get("boss_briefing_received", false))
	await _shot("routine_08_boss")
	_dismiss_briefing()
	main.sim.advance(13.5) # 21:30: begin an existing three-hour personal visit.
	main.sim.choose("hot_water", "go_myself")
	main.sim.advance(1.0)
	main.hud._close_card()
	print("routine overtime: ", main.sim.clock_text(), " / ", main.sim.actors["me"]["state"], " / work left=", main.sim.actors["me"]["work_left"])
	await _map_shot("routine_overtime", main.sim.actors["me"]["pos"], 340.0)
	main.sim.advance(12.0)
	print("routine next morning: ", main.sim.clock_text(), " / ", main.sim.actors["me"]["lot"], " / last return=", main.sim.last_day_end_hour)
	# Play the remaining days without taking new jobs; normal night cards still run.
	while not main.sim.ended:
		if main._night:
			main.hud.continue_day()
			await _wait(0.5)
		main.set_speed(0.0)
		_dismiss_briefing()
		main.sim.advance(32.0)
	print("routine Friday: money=", main.sim.money, " / rent debt=", main.sim.rent_debt, " / home=", main.sim.actors["me"]["lot"])
	for outcome in main.sim.outcomes:
		if "Документы за неделю не закончены" in outcome["text"]:
			print("routine paperwork penalty: ", outcome["text"])
	await _shot("routine_friday_rent")
	main.go_to_next_week()
	print("routine Monday salary: money=", main.sim.money, " / date=", main.sim.date_text())
	print("routine new weekly quota: ", main.sim.paperwork_hours, " / ended=", main.sim.ended)
	await _shot("routine_monday_salary")


func _run_token_review() -> void:
	_dismiss_briefing()
	await _map_shot("tokens_home", main.sim.actors["me"]["pos"], main.map.ZOOM_DEFAULT)
	print("token home anchor gap (m): ", main.map._tokens["me"].position.distance_to(main.map._ground(main.sim.actors["me"]["pos"])))
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.sim.choose("hot_water", "go_myself")
	main.sim.advance(0.5)
	await _map_shot("tokens_house5", main.sim.actors["me"]["pos"], main.map.ZOOM_DEFAULT)
	print("token work anchor gap (m): ", main.map._tokens["me"].position.distance_to(main.map._ground(main.sim.actors["me"]["pos"])))


func _run_paperwork() -> void:
	_dismiss_briefing()
	main.start_week()
	main.set_speed(0.0)
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.sim.start_paperwork()
	main.sim.advance(4.0)
	print("paperwork personal visit blocked: ", main.sim.option_block_reason("hot_water", main.sim.requests["hot_water"]["data"]["options"][1]))
	main.sim.choose("hot_water", "send_mikhalych")
	print("paperwork after dispatch call: ", main.sim.actors["me"]["state"], " / hours=", main.sim.paperwork_hours)
	main.hud._show_week_panel()
	await _shot("paperwork_progress")
	main.hud._close_week_panel()
	main.sim.pause_paperwork()
	main.sim.advance(1.0)
	print("paperwork after paused hour: ", main.sim.paperwork_hours)
	main.sim.choose("contractor", "pick_gusev")
	main.sim.advance(4.0)
	main.sim.return_to_office()
	main.sim.advance(2.0)
	print("paperwork return to office: ", main.sim.actors["me"]["lot"], " / progress=", main.sim.paperwork_hours)
	main.sim.start_paperwork()
	main.sim.advance(20.0)
	print("paperwork next morning: ", main.sim.clock_text(), " / hours=", main.sim.paperwork_hours, " / home=", main.sim.actors["me"]["lot"])
	# Leave some quota for Friday to inspect a real phone choice alongside paperwork.
	while main.sim.day_index() < 4:
		if main._night:
			main.hud.continue_day()
			await _wait(0.5)
		main.set_speed(0.0)
		_dismiss_briefing()
		main.sim.advance(32.0)
	if main._night:
		main.hud.continue_day()
		await _wait(0.5)
	main.set_speed(0.0)
	_dismiss_briefing()
	main.sim.advance(2.0)
	main.sim.start_paperwork()
	main.sim.advance(1.0)
	main.hud.open_card("journalist")
	await _shot("paperwork_phone")
	main.sim.choose("journalist", "phone")
	print("paperwork after journalist call: ", main.sim.actors["me"]["state"], " / request=", main.sim.requests["journalist"]["status"])
	main.hud._close_card()
	main.sim.advance(main.sim.paperwork_left())
	print("paperwork complete: ", main.sim.paperwork_hours, " / flag=", main.sim.flags.get("paperwork", false), " / state=", main.sim.actors["me"]["state"])
	main.hud._show_week_panel()
	await _shot("paperwork_complete")


func _run_contact_availability() -> void:
	_dismiss_briefing()
	main.start_week()
	main.set_speed(0.0)
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.sim.advance(7.0) # Assign a five-hour repair at 15:00, including travel.
	main.sim.choose("hot_water", "send_mikhalych")
	main.sim.advance(3.0)
	print("contact 18:00: state=", main.sim.actors["mikhalych"]["state"], " / request=", main.sim.requests["hot_water"]["status"], " / job=", main.sim.requests["hot_water"]["jobs"])
	main.hud._show_contact_detail("mikhalych")
	await _map_shot("contact_off_hours", main.hud.Week1.location_position("block5"), main.map.ZOOM_DEFAULT)
	print("contact visibility: hud=", main.hud._tokens["mikhalych"].visible, " / map=", main.map._tokens["mikhalych"].visible)
	main.hud._close_contact_detail()
	main.sim.advance(12.0)
	if main._night:
		main.hud.continue_day()
		await _wait(0.5)
	main.set_speed(0.0)
	main.sim.advance(2.0)
	print("contact next 08:00: state=", main.sim.actors["mikhalych"]["state"], " / request=", main.sim.requests["hot_water"]["status"], " / job=", main.sim.requests["hot_water"]["jobs"])
	main.hud.open_card("hot_water")
	await _shot("contact_resume_manually")
	main.sim.choose("hot_water", "send_mikhalych")
	print("contact reassigned: work left=", main.sim.actors["mikhalych"]["work_left"])
	main.sim.advance(8.0)
	print("contact after remaining work: request=", main.sim.requests["hot_water"]["status"], " / state=", main.sim.actors["mikhalych"]["state"])


func _run_request_lifecycle() -> void:
	print("request disabled fuel offer present: ", main.sim.requests.has("fuel_offer"))
	_dismiss_briefing()
	main.start_week()
	main.set_speed(0.0)
	while main.sim.day_index() < 2:
		if main._night:
			main.hud.continue_day()
			await _wait(0.5)
		main.set_speed(0.0)
		_dismiss_briefing()
		main.sim.advance(32.0)
	if main._night:
		main.hud.continue_day()
		await _wait(0.5)
	main.set_speed(0.0)
	main.sim.advance(2.0)
	main.sim.advance(1.0) # Wednesday 09:00: conflict at the station market.
	main.sim.choose("market_cops", "go_myself")
	main.sim.advance(0.7)
	print("request arrival: stage=", main.sim.request_stage("market_cops"), " / marker=", main.hud._markers.has("market_cops"), " / label=", main.sim.request_wait_text("market_cops"))
	await _map_shot("request_on_site", main.sim.actors["me"]["pos"], main.map.ZOOM_DEFAULT)
	main.sim.advance(2.5)
	print("request after reaction deadline: ", main.sim.clock_text(), " / stage=", main.sim.request_stage("market_cops"))
	main.hud.open_card("market_cops")
	await _shot("request_working_card")
	main.hud._close_card()
	main.sim.advance(20.0)
	if main._night:
		main.hud.continue_day()
		await _wait(0.5)
	main.set_speed(0.0)
	main.sim.advance(2.0)
	main.sim.advance(4.9) # Thursday 12:54: too late to reach the boiler by 13:00.
	main.hud._close_card()
	main.sim.choose("coal_theft", "go_myself")
	main.sim.advance(2.0)
	print("request late travel: stage=", main.sim.request_stage("coal_theft"), " / actor=", main.sim.actors["me"]["state"], " / coal_stolen=", main.sim.flags.get("coal_stolen", false))


func _run_train_review() -> void:
	_dismiss_briefing()
	main.map._debug_hour = 12.0
	var traffic = main.map.get_node("RailwayTraffic")
	traffic.set_process(false)
	var trace: Array = [traffic.snapshot()]
	var previous_state := JSON.stringify([trace[0]["active_indices"], trace[0]["departures"]])
	var captured: Dictionary = {}
	await _map_shot("trains_er2_inner_track", Vector2(410, 15), 125.0)
	captured["er2"] = true
	# Fast-forward the real scheduler between review frames, keeping normal speeds/gaps.
	for tick in range(2400):
		traffic.advance(0.5)
		var state: Dictionary = traffic.snapshot()
		var signature := JSON.stringify([state["active_indices"], state["departures"]])
		if signature != previous_state:
			trace.append(state)
			print("Rail traffic: ", JSON.stringify(state))
			previous_state = signature
		for active in state["active_indices"]:
			var model: Node3D = traffic.get_child(active)
			var leading: Vector3 = model.get_child(0).position
			var direction: int = state["trains"][active]["direction"]
			if active == 0 and direction < 0 and leading.z > 0 and leading.z < 20 and not captured.has("er2"):
				captured["er2"] = true
				await _map_shot("trains_er2_inner_track", Vector2(410, 15), 125.0)
			elif active == 1 and direction > 0 and leading.z < 370 and leading.z > 345 and leading.x > 419 and not captured.has("bend"):
				captured["bend"] = true
				await _map_shot("trains_freight_bend", Vector2(390, 375), 175.0)
			elif active == 1 and direction > 0 and leading.z < -340 and leading.z > -350 and not captured.has("haze"):
				captured["haze"] = true
				await _map_shot("trains_freight_haze", Vector2(415, -280), 210.0)
		if state["active_indices"].size() == 2 and not captured.has("passing"):
			var commuter: Vector3 = traffic.get_child(0).get_child(0).position
			var freight: Vector3 = traffic.get_child(1).get_child(0).position
			if commuter.x > 405 and freight.x > 405 and commuter.z > -330 and commuter.z < 200 and commuter.distance_to(freight) < 60:
				captured["passing"] = true
				await _map_shot("trains_passing", Vector2(415, (commuter.z + freight.z) / 2.0), 210.0)
		if state["trains"][0]["completed"] >= 2 and state["trains"][1]["completed"] >= 2:
			break
	if shots_dir != "":
		var file := FileAccess.open(shots_dir.path_join("trains-review.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify({"transitions": trace, "captures": captured}, "\t"))
	traffic.set_process(true)
	await _wait(2.0)


func _run_office() -> void:
	_dismiss_briefing()
	main.sim.advance(2.0) # Reach work before showing the boss and request cards.
	main.map._zoom = main.map.ZOOM_MAX
	main.map._camera_goal = Vector3(0, 0, -20)
	await _wait(0.5)
	main.hud._show_important_notice(main.hud.Week1.START_BRIEFING)
	await _shot("0_week_briefing")
	main.hud._continue_to_tasks()
	await _shot("0_week_tasks")
	for tab in range(1, main.hud._week_tabs.get_tab_count()):
		main.hud._week_tabs.current_tab = tab
		await _shot("0_week_tab_%d" % tab)
	main.hud._week_tabs.current_tab = 0
	main.hud._close_week_panel()
	main.hud.show_newspaper()
	await _shot("0_newspaper")
	main.hud._close_important_notice()
	main.map._camera_goal = main.map.DEFAULT_TARGET
	main.map._zoom = main.map.ZOOM_DEFAULT
	await _wait(0.5)
	main.hud._show_contact_detail("mikhalych")
	await _shot("0_contact_detail")
	main.hud._close_contact_detail()
	main.hud.open_card("hot_water")
	await _shot("1_card")
	_make_week_choices()
	main.hud.open_card("hot_water")
	await _shot("2_card_promised")
	main.hud._close_card()
	await _shot("3_planning")


func _run_map_tour() -> void:
	_dismiss_briefing()
	main.map._zoom = main.map.ZOOM_MAX
	main.map._camera_goal = Vector3(0, 0, -20)
	await _wait(0.5)
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
	await _map_shot("0_city_park", main.map.DistrictLayout.lot_center("city_park"), 165.0)
	await _map_shot("0_border_bridges", Vector2(120, -320), 880.0)
	await _map_shot("0_north", Vector2(-5, -260), 1000.0)
	await _map_shot("0_village", Vector2(275, 105), 600.0)
	await _map_shot("0_south", Vector2(-15, 350), 650.0)
	await _map_shot("0_market_hub", main.map.DistrictLayout.lot_center("market"), 340.0)
	main.map._camera_goal = main.map.DEFAULT_TARGET
	main.map._zoom = main.map.ZOOM_DEFAULT
	await _wait(0.5)


# The planning choices the week run relies on: a promise for the hot water and
# Gusev for the boiler house. Made once, by whichever scenario comes first.
func _make_week_choices() -> void:
	if _week_choices_made:
		return
	_week_choices_made = true
	main.sim.choose("hot_water", "promise")
	main.sim.choose("contractor", "pick_gusev")


func _run_week() -> void:
	_dismiss_briefing()
	if not main.sim.at_work:
		main.sim.advance(2.0)
		_dismiss_briefing()
	_make_week_choices()
	main.start_week()
	main.set_speed(4.0)
	var live_shot_taken := false
	while main.phase == "live":
		await get_tree().process_frame
		# The morning newspaper and the first office briefing are reading pauses.
		if main.hud._notice_panel != null:
			_dismiss_briefing()
			main.set_speed(4.0)
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
	main.hud._close_important_notice()
	main.hud._overlay_panel.visible = false
	await _map_shot("7_boiler_repairing", main.hud.Week1.location_position("boiler"), 300.0)


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
	_dismiss_briefing()
	print("3D Lada instances: ", get_tree().get_nodes_in_group("vehicle_lada").size())
	print("3D vehicles by model: total ", get_tree().get_nodes_in_group("vehicle_models").size(), ", lada ", get_tree().get_nodes_in_group("vehicle_lada").size(), ", wagon ", get_tree().get_nodes_in_group("vehicle_lada_wagon").size(), ", volga ", get_tree().get_nodes_in_group("vehicle_volga").size(), " (real mesh: ", main.map.VehicleModels.has_volga_model(), ")")
	var moving_cars := 0
	var moving_volgas := 0
	for agent in main.map._ambient.agents:
		if not agent["is_car"] or agent["state"] != "graph":
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
		if not agent["is_car"] or agent["state"] != "graph" or not agent["visual"].is_in_group("vehicle_volga"):
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


# Map-edge haze review: widest views at the centre and corners in both camera
# modes, then the places where roads, the bridge and the forest meet the haze.
func _run_edges_review() -> void:
	_dismiss_briefing()
	var map = main.map
	var previous_view: String = map.Settings.camera_mode
	var bounds: Rect2 = map.BOUNDS
	var corners := {
		"nw": bounds.position, "ne": Vector2(bounds.end.x, bounds.position.y),
		"sw": Vector2(bounds.position.x, bounds.end.y), "se": bounds.end,
	}
	for mode in ["iso", "front"]:
		map.Settings.camera_mode = mode
		await _map_shot("edge_wide_%s_center" % mode, bounds.get_center(), map.ZOOM_MAX)
		for corner in corners:
			await _map_shot("edge_wide_%s_%s" % [mode, corner], corners[corner], map.ZOOM_MAX)
	map.Settings.camera_mode = previous_view
	await _map_shot("edge_west_road", Vector2(-560, -187.5), 300.0)
	await _map_shot("edge_east_road", Vector2(440, -85), 250.0)
	await _map_shot("edge_bridge", Vector2(-5, -320), 250.0)
	await _map_shot("edge_forest", Vector2(-520, 120), 390.0)
	# Highway gateway: the third tunnel under the railway embankment, both cameras.
	for mode in ["iso", "front"]:
		map.Settings.camera_mode = mode
		await _map_shot("edge_highway_tunnel_%s" % mode, Vector2(420, -187.5), 120.0)
	map.Settings.camera_mode = previous_view
	# Parking rules: no parked cars on the highway or near junctions.
	await _map_shot("edge_parking_highway", Vector2(-5, -187.5), 160.0)
	await _map_shot("edge_parking_junction", Vector2(145, -85), 130.0)


# Prints what the 3D vehicles cost per frame at the closest, default and widest
# zoom: with automatic mesh LOD, with LOD off, and with the vehicles hidden.
func _run_render_cost() -> void:
	_dismiss_briefing()
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


func _run_performance() -> void:
	_dismiss_briefing()
	var profiler = load("res://scripts/dev/frame_profiler.gd").new()
	add_child(profiler)
	await profiler.run(main, shots_dir)
	profiler.queue_free()


func _run_performance_camera() -> void:
	_dismiss_briefing()
	# Keep the first traversal: shader/resource stalls must not disappear into warm-up.
	# Revisit the same destinations/zoom targets to compare first use with steady load.
	var points := [Vector2(-205, 85), Vector2(-520, 120), Vector2(120, -320),
		main.map.DistrictLayout.lot_center("market"), Vector2(275, 105), Vector2(-15, 350)]
	for pass_index in 2:
		for i in points.size():
			if _session_profiler != null:
				_session_profiler.scenario = "camera_pass_%d_leg_%d" % [pass_index + 1, i + 1]
			var point: Vector2 = points[i]
			main.map._camera_goal = Vector3(point.x, 0, point.y)
			var tween := create_tween()
			tween.tween_property(main.map, "_zoom", main.map.ZOOM_MAX if i % 2 == 0 else main.map.ZOOM_MIN, 2.0)
			await _wait(4.0)
	main.map._camera_goal = main.map.DEFAULT_TARGET
	main.map._zoom = main.map.ZOOM_DEFAULT


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
	# GPU readback/PNG encoding would create artificial stalls in a performance trace.
	if _session_profiler != null:
		await _wait(0.35) # Let each UI state render without reading pixels back.
		return
	await RenderingServer.frame_post_draw
	if shots_dir == "":
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png(shots_dir.path_join(name + ".png"))
	print("shot: ", name)


# Focused visual review of the boulevard's yard link and both asphalt junctions.
func _run_crosswalk_review() -> void:
	_dismiss_briefing()
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


# Static placement at every registered junction plus a dev-only lens preview.
func _run_traffic_light_review() -> void:
	_dismiss_briefing()
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


func _run_field_review() -> void:
	_dismiss_briefing()
	# Compare surfaces in daylight: 07:00 is still dark in the winter preview.
	main.map._debug_hour = 12.0
	await _map_shot("field_context", Vector2(205, -132), 460.0)
	await _map_shot("field_roadside", Vector2(205, -132), 180.0)


func _run_traffic_review() -> void:
	_dismiss_briefing()
	main.map._debug_hour = 12.0
	await _map_shot("traffic_west_reserve", Vector2(-420, 110), 580.0)
	await _wait(2.0)
	await _map_shot("traffic_highway_border", Vector2(-5, -205), 220.0)
	# Keep the camera on a real courtyard car, without adding review-only vehicles.
	for agent in main.map._ambient.agents:
		if agent.get("stream", "") != "courtyard":
			continue
		for i in 600:
			if agent["graph"].edges[agent["edge"]]["kind"] == "yard":
				await _map_shot("traffic_courtyard", agent["pos"], 100.0)
				return
			await _wait(0.1)


# Capture real road-traffic vans; do not add review-only vehicles to the city.
func _run_gazelle_review() -> void:
	_dismiss_briefing()
	main.map._debug_hour = 12.0
	var models := {}
	var classes := {}
	for agent in main.map._ambient.agents:
		if not agent["is_car"]:
			continue
		var model: String = agent["visual"].get_meta("traffic_model", "unknown")
		models[model] = int(models.get(model, 0)) + 1
		classes[agent["class"]] = int(classes.get(agent["class"], 0)) + 1
	print("Road traffic initial classes: ", JSON.stringify(classes))
	print("Road traffic initial models: ", JSON.stringify(models))
	var captured := {}
	for step in 200:
		for agent in main.map._ambient.agents:
			if not agent["is_car"] or agent["state"] != "graph":
				continue
			if not agent["visual"].is_in_group("vehicle_gazelle"):
				continue
			var heading: Vector2 = agent["heading"]
			var axis := "x" if absf(heading.x) > 0.95 else "z" if absf(heading.y) > 0.95 else "turn"
			if axis == "turn" or captured.has(axis):
				continue
			captured[axis] = true
			print("Gazelle road capture: ", axis, " ", agent["visual"].get_meta("traffic_model"), " at ", agent["pos"])
			await _map_shot("gazelle_road_" + axis, agent["pos"], 90.0)
			break
		if captured.size() == 2:
			return
		await _wait(0.2)
	print("Gazelle road capture orientations: ", captured.keys())


# Focused live UI capture, with input-routing and widget dimensions in the log.
func _run_ui_review() -> void:
	_dismiss_briefing()
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.map._zoom = main.map.ZOOM_DEFAULT
	main.map._camera_goal = main.map.DEFAULT_TARGET
	main.hud.show_newspaper()
	await _wait(0.3)
	await _shot("ui_newspaper")
	main.hud._close_important_notice()
	main.start_week()
	main.set_speed(0.0)
	_dismiss_briefing()
	print("UI newspaper shortcut after start: ", main.hud._newspaper_button.visible)
	print("UI idle contact dock: ", main.hud._contacts_dock.size, " / active photo=", main.hud._contact_cards["mikhalych"].visible)
	main.hud._show_week_panel()
	await _wait(0.3)
	var page: ScrollContainer = main.hud._week_tabs.get_child(0)
	var zoom_before: float = main.map._zoom
	var scroll_before: int = page.scroll_vertical
	for index in 3:
		await _ui_wheel_at(page.get_global_rect().get_center())
	await _ui_wheel_at(Vector2(30, 400))
	var magnify := InputEventMagnifyGesture.new()
	magnify.factor = 1.5
	magnify.position = Vector2(30, 400)
	Input.parse_input_event(magnify)
	await get_tree().process_frame
	print("UI folder input: zoom ", zoom_before, " -> ", main.map._zoom, " / scroll ", scroll_before, " -> ", page.scroll_vertical)
	print("UI paperwork indicator: ", main.hud._paperwork_progress.size)
	await _shot("ui_folder")
	main.hud._close_week_panel()
	await _ui_wheel_at(Vector2(30, 400))
	print("UI map wheel after close: ", zoom_before, " -> ", main.map._zoom)
	main.map._zoom = main.map.ZOOM_DEFAULT
	main.sim.choose("hot_water", "send_mikhalych")
	main.sim.advance(0.25)
	await _map_shot("ui_assigned_marker", main.hud.Week1.location_position("block5"), main.map.ZOOM_DEFAULT)
	main.sim.advance(3.0)
	await _wait(0.3)
	print("UI active contact: ", main.sim.actors["mikhalych"]["state"], " / visible=", main.hud._contact_cards["mikhalych"].visible, " / progress size=", main.hud._contact_progress["mikhalych"].size)
	main.hud._toggle_contacts_drawer()
	await _wait(0.2)
	var drawer_zoom: float = main.map._zoom
	await _ui_wheel_at(main.hud._contact_drawer.get_global_rect().get_center())
	await _ui_wheel_at(Vector2(30, 400))
	print("UI drawer input: zoom ", drawer_zoom, " -> ", main.map._zoom)
	await _shot("ui_contacts")
	main.hud._close_contacts_drawer()


func _ui_wheel_at(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	await get_tree().process_frame
	var wheel := InputEventMouseButton.new()
	wheel.position = at
	wheel.global_position = at
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	wheel.factor = 1
	Input.parse_input_event(wheel)
	await get_tree().process_frame


func _run_newspaper_review() -> void:
	_dismiss_briefing()
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.hud.show_newspaper()
	await _wait(0.3)
	await _shot("press_week1_front")


func _run_ui_motion() -> void:
	_dismiss_briefing()
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.map._zoom = main.map.ZOOM_DEFAULT
	main.map._camera_goal = main.map.DEFAULT_TARGET
	await _wait(0.3)
	main.hud._toggle_contacts_drawer()
	var start: float = main.hud._contact_drawer.position.x
	await _wait(0.08)
	print("UI drawer motion: start=", start, " / middle=", main.hud._contact_drawer.position.x)
	await _shot("ui_drawer_mid")
	await _wait(0.3)
	print("UI drawer open x=", main.hud._contact_drawer.position.x, " / lamp=", main.hud._contact_drawer_dots["mikhalych"].color)
	await _shot("ui_drawer_open")
	var legend: PanelContainer = main.hud._paper_panel()
	legend.anchor_left = 1
	legend.anchor_right = 1
	legend.offset_left = -320
	legend.offset_right = -16
	legend.offset_top = 90
	legend.offset_bottom = 390
	main.hud._root.add_child(legend)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	legend.add_child(column)
	column.add_child(main.hud._heading("Типы обращений", 22))
	for kind in ["plea", "conflict", "crisis", "offer"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(main.hud._icon(main.hud.OfficeIcons.QUEST_TYPES[kind], 32))
		row.add_child(main.hud._paper_label(main.hud.TYPE_NAMES[kind], 17))
		column.add_child(row)
	await _shot("ui_quest_icons")
	legend.queue_free()
	main.hud._close_contacts_drawer()
	await _wait(0.05)
	main.hud._toggle_contacts_drawer()
	await _wait(0.3)
	print("UI interrupted close/reopen: open=", main.hud._contact_drawer_open, " / x=", main.hud._contact_drawer.position.x)
	main.sim.advance(11.0)
	await _wait(0.1)
	print("UI unavailable lamp=", main.hud._contact_drawer_dots["mikhalych"].color, " / text=", main.hud._contact_drawer_status["mikhalych"].text)
	await _shot("ui_drawer_unavailable")
	main.hud._close_contacts_drawer()
	await _wait(0.25)
	print("UI drawer closed: visible=", main.hud._contact_drawer.visible, " / map blocked=", main.map._ui_input_blocked)


func _run_press_review() -> void:
	_dismiss_briefing()
	main.hud.show_newspaper()
	await _wait(0.25)
	print("Press font: ", main.hud._notice_panel.TEXT_FONT.get_font_name(), " / Cyrillic=", main.hud._notice_panel.TEXT_FONT.has_char(1046))
	await _shot("press_week1_front")
	await _wait(0.2)
	main.hud._close_important_notice()
	main.start_week()
	main.set_speed(0.0)
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.sim.choose("hot_water", "send_mikhalych")
	main.sim.choose("contractor", "pick_gusev")
	while not main.sim.ended:
		if main._night:
			main.hud.continue_day()
			await _wait(0.45)
		main.set_speed(0.0)
		_dismiss_briefing()
		main.sim.advance(32.0)
	main.go_to_next_week()
	await _wait(0.25)
	print("Press completed-week history: ", JSON.stringify(main.sim.press_history))
	print("Press issue/date: ", main.hud._notice_panel._edition["issue"], " / ", main.hud._notice_panel._date)
	await _wait(0.2)
	await _shot("press_week2_front")
	main.hud._close_important_notice()
	await _wait(0.1)
	print("Press dismissed: prototype overlay visible=", is_instance_valid(main.hud._overlay_panel) and main.hud._overlay_panel.visible)


func _run_header_review() -> void:
	_dismiss_briefing()
	main.hud.set_phase("planning")
	await _wait(0.3)
	await _shot("header_planning")
	for value in [0.85, 1.15]:
		main.hud.set_interface_scale(value)
		await _wait(0.2)
		print("Header requested scale=", value, " effective=", main.hud._top_bar.scale.x, " width=", main.hud._top_bar.size.x * main.hud._top_bar.scale.x)
	main.hud.set_interface_scale(1.0)
	main.start_week()
	main.set_speed(0.0)
	main.sim.advance(2.0)
	_dismiss_briefing()
	main.sim.advance(13.5)
	main.sim.choose("hot_water", "go_myself")
	main.sim.advance(1.0)
	main.hud._close_card(false)
	await _wait(0.3)
	print("Header overtime: ", main.hud._phase_label.text, " / ", main.hud._phase_detail.text)
	await _shot("header_overtime")
	for step in 200:
		if main.sim.actors["me"].get("commute_target", "") == "dormitory":
			break
		main.sim.advance(0.02)
	await _wait(0.3)
	print("Header return home: ", main.hud._phase_label.text, " / ", main.hud._phase_detail.text)
