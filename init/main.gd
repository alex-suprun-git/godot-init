# Wires the week simulation to the 3D map, the HUD and the audio, and drives
# game time. Phases: planning (time stopped) -> live (time runs) -> summary -> week2.
extends Node

const WeekSim = preload("res://scripts/sim/week_sim.gd")
const CityMap = preload("res://scripts/map/city_map.gd")
const Hud = preload("res://scripts/ui/hud.gd")
const AudioManager = preload("res://scripts/audio/audio_manager.gd")
const AudioDebug = preload("res://scripts/audio/audio_debug.gd")
const PlayLog = preload("res://scripts/dev/play_log.gd")
const Settings = preload("res://scripts/data/settings.gd")

# Real seconds per game hour at x1. A 12-hour working day takes 18 seconds.
const HOUR_SECONDS := 1.5

var sim
var map
var hud
var audio
var audio_debug
var play_log
var phase := "planning"
var speed := 1.0


func _ready() -> void:
	sim = WeekSim.new()
	var args := OS.get_cmdline_user_args()
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
	add_child(audio)
	map = CityMap.new()
	add_child(map)
	map.setup(sim)
	hud = Hud.new()
	add_child(hud)
	hud.setup(sim, map, audio, play_log)
	audio_debug = AudioDebug.new()
	add_child(audio_debug)
	audio_debug.setup(audio)
	hud.start_week_pressed.connect(start_week)
	hud.speed_selected.connect(set_speed)
	hud.next_week_pressed.connect(go_to_next_week)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	hud.season_selected.connect(func(key):
		Settings.season = key
		get_tree().reload_current_scene())
	sim.week_ended.connect(_on_week_ended)
	# Crises pause the game, as in Frostpunk: decide first, then resume.
	sim.crisis_started.connect(func(_id): set_speed(0.0))
	# Sounds for things that happen in the world. The sim knows nothing about
	# them; it only emits signals.
	sim.request_opened.connect(_on_request_opened)
	sim.promise_resolved.connect(func(status): audio.play("promise_" + status))
	sim.overlay_changed.connect(_on_overlay_changed)
	sim.begin()
	hud.set_phase(phase)

	if args.has("--autoplay"):
		var Autoplay = load("res://scripts/dev/autoplay.gd")
		add_child(Autoplay.new())


func _process(delta: float) -> void:
	if phase == "live" and speed > 0.0:
		sim.advance(delta * speed / HOUR_SECONDS)


func start_week() -> void:
	phase = "live"
	if play_log != null:
		play_log.note_phase("live")
	audio.begin_week()
	audio.play("week_start")
	hud.set_phase(phase)
	set_speed(1.0)


func set_speed(value: float) -> void:
	speed = value
	hud.set_speed(value)
	if play_log != null:
		play_log.note_speed(value)


func go_to_next_week() -> void:
	var changes: Array[String] = sim.begin_next_week()
	phase = "week2"
	audio.begin_week()
	audio.play("week_two_morning")
	hud.show_week_two(changes)


func _on_week_ended() -> void:
	phase = "summary"
	audio.play("week_end")
	hud.set_phase(phase)


func _on_request_opened(id: String) -> void:
	audio.play("request_" + sim.requests[id]["data"]["type"])


func _on_overlay_changed(_lot: String, overlay: String, shown: bool) -> void:
	if shown and overlay == "picket":
		audio.play("picket_start")
