# Two voices overlap at loop seams and between tracks in an optional playlist.
extends Node

var stream: AudioStream
var playlist: Array[AudioStream] = []
var bus := "Ambience"
var level := 0.5
var context_gain := 1.0
var _context_smoothed := 1.0
var _last_tick := 0.0
var overlap_seconds := 2.0
var autoplay := true
var _voices: Array[AudioStreamPlayer] = []
var _active := 0
var _track := 0
var _overlap_started := -1.0
var _overlap_duration := 0.0
var _gain := 0.0
var _gain_from := 0.0
var _gain_started := 0.0
var _gain_duration := 2.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sources := playlist.duplicate()
	if sources.is_empty():
		sources.append(stream)
	playlist = []
	for source in sources:
		var track := source.duplicate() as AudioStream
		if track is AudioStreamMP3 or track is AudioStreamOggVorbis:
			track.loop = false
		elif track is AudioStreamWAV:
			track.loop_mode = AudioStreamWAV.LOOP_DISABLED
		playlist.append(track)
	stream = playlist[0]
	for i in 2:
		var voice := AudioStreamPlayer.new()
		voice.bus = bus
		voice.volume_linear = 0.0
		add_child(voice)
		_voices.append(voice)
	_voices[0].stream = stream
	if autoplay:
		start_playback()
	else:
		set_process(false)


func start_playback() -> void:
	if is_processing() and _voices[_active].playing:
		return
	_voices[_active].play()
	set_level(level, 2.0)
	set_process(true)


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
	var next_track := (_track + 1) % playlist.size()
	if _overlap_started < 0.0:
		var next_stream := playlist[next_track]
		var remaining := stream.get_length() - current.get_playback_position()
		var overlap := minf(overlap_seconds, minf(stream.get_length(), next_stream.get_length()) * 0.25)
		if not current.playing or remaining <= overlap:
			_overlap_duration = maxf(0.0, remaining) if current.playing else 0.0
			_overlap_started = now
			incoming.stream = next_stream
			incoming.play()
	if _overlap_started >= 0.0:
		var blend := clampf((now - _overlap_started) / maxf(0.001, _overlap_duration), 0.0, 1.0) if current.playing else 1.0
		current.volume_linear = output_gain * cos(blend * PI * 0.5)
		incoming.volume_linear = output_gain * sin(blend * PI * 0.5)
		if blend >= 1.0:
			current.stop()
			_active = 1 - _active
			_track = next_track
			stream = incoming.stream
			_overlap_started = -1.0
	else:
		current.volume_linear = output_gain
		incoming.volume_linear = 0.0
