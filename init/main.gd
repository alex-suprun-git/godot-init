# Wires the week simulation to the 3D map, the HUD and the audio, and drives
# game time. Phases: planning (time stopped) -> live (time runs) -> summary -> week2.
extends Node

const WeekSim = preload("res://scripts/sim/week_sim.gd")
const CityMap = preload("res://scripts/map/city_map.gd")
const Hud = preload("res://scripts/ui/hud.gd")
const AudioManager = preload("res://scripts/audio/audio_manager.gd")
const AudioSettings = preload("res://scripts/ui/audio_settings.gd")
const AudioDebug = preload("res://scripts/audio/audio_debug.gd")
const PlayLog = preload("res://scripts/dev/play_log.gd")
const Settings = preload("res://scripts/data/settings.gd")
const Arrival = preload("res://scripts/data/arrival.gd")
const ArrivalSequence = preload("res://scripts/ui/arrival_sequence.gd")

var sim
var map
var hud
var audio
var audio_debug
var play_log
var phase := "planning"
var speed := 1.0
var _resume_speed := 1.0
var _night := false # Between two days: time is held while the day card shows.
var arrival: ArrivalSequence


func _ready() -> void:
	sim = WeekSim.new()
	var args := OS.get_cmdline_user_args()
	var play_arrival := not args.has("--autoplay")
	for arg in args:
		if arg.begins_with("--only="):
			play_arrival = play_arrival or arg.trim_prefix("--only=").get_slice(",", 0) == "prologue"
	var skip_arrival := not args.has("--autoplay") and args.has("--skip-prologue")
	play_arrival = play_arrival and not skip_arrival
	for arg in args:
		if arg.begins_with("--season=") and Settings.SEASONS.has(arg.substr("--season=".length())):
			Settings.season = arg.substr("--season=".length())
		if arg.begins_with("--camera=") and Settings.CAMERAS.has(arg.substr("--camera=".length())):
			Settings.camera_mode = arg.substr("--camera=".length())
	# The playtest log starts before anything happens, so no event is missed.
	if not args.has("--no-log"):
		play_log = PlayLog.new()
		add_child(play_log)
		play_log.setup(sim, "autoplay" if args.has("--autoplay") else "player")
	audio = AudioManager.new()
	audio.defer_music = play_arrival or skip_arrival
	add_child(audio)
	map = CityMap.new()
	add_child(map)
	map.setup(sim)
	hud = Hud.new()
	add_child(hud)
	hud.setup(sim, map, audio, play_log, not play_arrival and not skip_arrival)
	audio_debug = AudioDebug.new()
	add_child(audio_debug)
	audio_debug.setup(audio)
	var audio_settings := AudioSettings.new()
	add_child(audio_settings)
	audio_settings.setup(audio, map)
	audio.set_camera_proximity(map.audio_proximity())
	var map_audio := preload("res://scripts/audio/map_audio.gd").new()
	audio.add_child(map_audio)
	map_audio.setup(audio, map)
	hud.start_week_pressed.connect(start_week)
	hud.speed_selected.connect(set_speed)
	hud.next_week_pressed.connect(go_to_next_week)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	hud.season_selected.connect(func(key):
		Settings.season = key
		get_tree().reload_current_scene())
	sim.week_ended.connect(_on_week_ended)
	sim.day_started.connect(_on_day_started)
	sim.workday_started.connect(func():
		map.focus_on("office")
		if not sim.flags.get("boss_briefing_received", false):
			sim.flags["boss_briefing_received"] = true
			hud._show_important_notice(hud.Week1.START_BRIEFING)
			audio.music.start_playback()
			sim.state_changed.emit())
	# Crises pause the game, as in Frostpunk: decide first, then resume.
	sim.crisis_started.connect(func(_id): set_speed(0.0))
	# Sounds for things that happen in the world. The sim knows nothing about
	# them; it only emits signals.
	sim.request_opened.connect(_on_request_opened)
	sim.option_chosen.connect(func(_request_id, _option_id, actor):
		audio.play("promise_made" if actor == "promise" else "option_choose"))
	sim.money_changed.connect(audio.play.bind("money_changed"))
	sim.promise_resolved.connect(func(status): audio.play("promise_" + status))
	sim.overlay_changed.connect(_on_overlay_changed)
	if play_arrival:
		phase = "prologue"
		hud.hide()
		arrival = ArrivalSequence.new()
		add_child(arrival)
		arrival.finished.connect(_finish_arrival)
		arrival.begin(map, hud, audio, map_audio, sim.date_text(0))
	elif skip_arrival:
		_finish_arrival()
	else:
		sim.begin()
		hud.set_phase(phase)

	if args.has("--autoplay"):
		var Autoplay = load("res://scripts/dev/autoplay.gd")
		add_child(Autoplay.new())


func _finish_arrival() -> void:
	hud.show()
	start_week()
	sim.arrive_after_prologue(Arrival.BRIEFING_HOUR)


func _process(delta: float) -> void:
	audio.set_camera_proximity(map.audio_proximity())
	if phase == "live" and speed > 0.0 and not _night:
		sim.advance(delta * speed / Settings.GAME_HOUR_SECONDS)


func _input(event: InputEvent) -> void:
	if phase == "prologue" and OS.is_debug_build() and event is InputEventKey and event.keycode == KEY_F7:
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo:
			arrival.finish()
		return
	if phase != "live" or _night or not event is InputEventKey or event.keycode != KEY_SPACE:
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return
	# Consume both edges before GUI input so Space never activates a focused
	# request/choice button as well. Holding it must not repeatedly toggle.
	get_viewport().set_input_as_handled()
	if event.pressed and not event.echo:
		set_speed(_resume_speed if is_zero_approx(speed) else 0.0)
		audio.play("speed_click")


func start_week() -> void:
	phase = "live"
	if play_log != null:
		play_log.note_phase("live")
	audio.begin_week()
	audio.play("week_start")
	hud.set_phase(phase)
	set_speed(1.0)


func set_speed(value: float) -> void:
	if not Settings.TIME_SPEEDS.has(value):
		return
	speed = value
	if value > 0.0:
		_resume_speed = value
	hud.set_speed(value)
	if play_log != null:
		play_log.note_speed(value)


func go_to_next_week() -> void:
	var changes: Array[String] = sim.begin_next_week()
	phase = "week2"
	audio.begin_week()
	audio.play("week_two_morning")
	hud.show_week_two(changes)


# The night between working days: pause, flip the calendar while the map runs
# through the night; "Продолжить" starts the morning at normal speed.
func _on_day_started(day: int) -> void:
	_night = true
	set_speed(0.0)
	map.focus_on("dormitory")
	map.play_night(hud.DAY_CARD_SECONDS)
	hud.show_day_card(day, func():
		_night = false
		set_speed(1.0))


func _on_week_ended() -> void:
	phase = "summary"
	audio.play("week_end")
	hud.set_phase(phase)


func _on_request_opened(id: String) -> void:
	audio.play("request_" + sim.requests[id]["data"]["type"])


func _on_overlay_changed(_lot: String, overlay: String, shown: bool) -> void:
	if shown and overlay == "picket":
		audio.play("picket_start")
