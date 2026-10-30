# Wires the week simulation to the 3D map and the HUD and drives game time.
# Phases: planning (time stopped) -> live (time runs) -> summary -> week2.
extends Node

const WeekSim = preload("res://scripts/sim/week_sim.gd")
const CityMap = preload("res://scripts/map/city_map.gd")
const Hud = preload("res://scripts/ui/hud.gd")

# Real seconds per game hour at x1. A 12-hour working day takes 18 seconds.
const HOUR_SECONDS := 1.5

var sim
var map
var hud
var phase := "planning"
var speed := 1.0


func _ready() -> void:
	sim = WeekSim.new()
	map = CityMap.new()
	add_child(map)
	map.setup(sim)
	hud = Hud.new()
	add_child(hud)
	hud.setup(sim, map)
	hud.start_week_pressed.connect(start_week)
	hud.speed_selected.connect(set_speed)
	hud.next_week_pressed.connect(go_to_next_week)
	hud.restart_pressed.connect(func(): get_tree().reload_current_scene())
	sim.week_ended.connect(_on_week_ended)
	# Crises pause the game, as in Frostpunk: decide first, then resume.
	sim.crisis_started.connect(func(_id): set_speed(0.0))
	sim.begin()
	hud.set_phase(phase)

	var args := OS.get_cmdline_user_args()
	if args.has("--autoplay"):
		var Autoplay = load("res://scripts/dev/autoplay.gd")
		add_child(Autoplay.new())


func _process(delta: float) -> void:
	if phase == "live" and speed > 0.0:
		sim.advance(delta * speed / HOUR_SECONDS)


func start_week() -> void:
	phase = "live"
	hud.set_phase(phase)
	set_speed(1.0)


func set_speed(value: float) -> void:
	speed = value
	hud.set_speed(value)


func go_to_next_week() -> void:
	var changes: Array[String] = sim.begin_next_week()
	phase = "week2"
	hud.show_week_two(changes)


func _on_week_ended() -> void:
	phase = "summary"
	hud.set_phase(phase)
