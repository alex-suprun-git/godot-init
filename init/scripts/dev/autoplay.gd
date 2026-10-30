# Dev-only: plays the first week automatically and saves screenshots of each
# phase, so changes can be checked without clicking through by hand.
# Run: Godot --path init -- --autoplay --shots=/absolute/output/dir
extends Node

var main
var shots_dir := ""
var _crisis_handled := false


func _ready() -> void:
	main = get_parent()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			shots_dir = arg.substr("--shots=".length())
	_run()


func _run() -> void:
	await _wait(1.5)
	main.map._zoom = main.map.ZOOM_MAX
	await _wait(0.5)
	await _shot("0_overview")
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
		if not live_shot_taken and main.sim.t >= 3.0:
			live_shot_taken = true
			main.set_speed(0.0)
			await _shot("4_live")
			main.audio_debug.visible = true
			await _wait(0.5)
			await _shot("8_audio_panel")
			main.audio_debug.visible = false
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
	get_tree().quit()


# Simple player: takes the first option that is possible for every open
# request except promises and crises, which get their own handling.
func _play_turn() -> void:
	var sim = main.sim
	for id in sim.request_order:
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


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	if shots_dir == "":
		return
	var image := get_viewport().get_texture().get_image()
	image.save_png(shots_dir.path_join(name + ".png"))
	print("shot: ", name)
