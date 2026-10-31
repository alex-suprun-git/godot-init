# Continuous city bed, independent of simulation speed and the one-shot pool.
# The recording is already quiet; default playback adds another 6 dB of space.
extends AudioStreamPlayer

const CITY_STREAM = preload("res://assets/audio/ambience/city_outskirts.ogg")
const DEFAULT_LEVEL := 0.5
const FADE_SECONDS := 2.0

var level := DEFAULT_LEVEL
var _fade: Tween


func _ready() -> void:
	name = "CityAmbience"
	bus = "Ambience"
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = CITY_STREAM
	volume_linear = 0.0
	play()
	set_level(level, FADE_SECONDS)


# A zero level mutes without resetting the long recording's playback position.
func set_level(value: float, fade_seconds: float = 0.15) -> void:
	level = clampf(value, 0.0, 1.0)
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(self, "volume_linear", level, fade_seconds)
