# Two voices overlap at loop seams; wall-clock envelopes ignore simulation speed.
extends Node

var stream: AudioStream
var bus := "Ambience"
var level := 0.5
var context_gain := 1.0
var _context_smoothed := 1.0
var _last_tick := 0.0
var overlap_seconds := 2.0
var _voices: Array[AudioStreamPlayer] = []
var _active := 0
var _overlap_started := -1.0
var _gain := 0.0
var _gain_from := 0.0
var _gain_started := 0.0
var _gain_duration := 2.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = stream.duplicate()
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = false
	overlap_seconds = clampf(overlap_seconds, 0.05, stream.get_length() * 0.25)
	for i in 2:
		var voice := AudioStreamPlayer.new()
		voice.stream = stream
		voice.bus = bus
		voice.volume_linear = 0.0
		add_child(voice)
		_voices.append(voice)
	_voices[0].play()
	set_level(level, 2.0)


func set_level(value: float, fade_seconds: float = 0.15) -> void:
	level = clampf(value, 0.0, 1.0)
	_gain_from = _gain
	_gain_started = Time.get_ticks_msec() / 1000.0
	_gain_duration = maxf(0.001, fade_seconds)


func get_playback_position() -> float:
	return _voices[_active].get_playback_position()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var elapsed := maxf(0.0, now - _last_tick) if _last_tick > 0.0 else 0.0
	_last_tick = now
	_context_smoothed = lerpf(_context_smoothed, context_gain, 1.0 - exp(-elapsed / 0.35))
	_gain = lerpf(_gain_from, level, clampf((now - _gain_started) / _gain_duration, 0.0, 1.0))
	var output_gain := _gain * _context_smoothed
	var current := _voices[_active]
	var incoming := _voices[1 - _active]
	if _overlap_started < 0.0 and (not current.playing or current.get_playback_position() >= stream.get_length() - overlap_seconds):
		incoming.play()
		_overlap_started = now
	if _overlap_started >= 0.0:
		var blend := clampf((now - _overlap_started) / overlap_seconds, 0.0, 1.0)
		current.volume_linear = output_gain * cos(blend * PI * 0.5)
		incoming.volume_linear = output_gain * sin(blend * PI * 0.5)
		if blend >= 1.0:
			current.stop()
			_active = 1 - _active
			_overlap_started = -1.0
	else:
		current.volume_linear = output_gain
		incoming.volume_linear = 0.0
