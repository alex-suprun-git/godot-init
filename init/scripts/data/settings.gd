# Settings that survive reloading the scene while the game is running. The
# season picks which look the map has; the scenario itself is the same in all of them.
extends RefCounted

# Real seconds per game hour at x1: a 16-hour day (06:00–22:00) takes 64 seconds,
# plus any overtime and the walk home. Five base days take 5 minutes 20 seconds.
const GAME_HOUR_SECONDS := 4.0
const TIME_SPEEDS := [0.0, 1.0, 2.0, 4.0]

const SEASONS := ["summer", "autumn", "winter"]

static var season := "summer"

# "iso": orthographic camera turned 45 degrees, matching the painted isometric
# sprites. "front": the older perspective camera looking straight along the
# streets. F2 switches between them while playing; --camera=front|iso at start.
const CAMERAS := ["iso", "front"]
static var camera_mode := "iso"

# Shared UI preference. Keep all screen-space layouts in logical coordinates.
class InterfaceEvents extends RefCounted:
	signal scale_changed(value: float)
static var ui_events := InterfaceEvents.new()
static var ui_scale := 1.0
static var _interface_loaded := false

static func load_interface_preferences() -> void:
	if _interface_loaded:
		return
	_interface_loaded = true
	var config := ConfigFile.new()
	if config.load("user://interface.cfg") == OK:
		ui_scale = clampf(float(config.get_value("interface", "scale", 1.0)), 0.75, 1.5)

static func set_interface_scale(value: float) -> void:
	ui_scale = clampf(value, 0.75, 1.5)
	ui_events.scale_changed.emit(ui_scale)
	var config := ConfigFile.new()
	config.set_value("interface", "scale", ui_scale)
	config.save("user://interface.cfg")

static func fitted_interface_scale(viewport: Vector2) -> float:
	return minf(ui_scale, minf(viewport.x / 1280.0, viewport.y / 720.0))
