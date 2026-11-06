# Plays sound events from the table in scripts/data/audio_events.gd. Callers only
# name an event ("option_choose"); weight, variants, volume, repeat limits and
# the bus live in data. It also counts every event so the debug panel can show
# what the week actually sounded like, even while all sounds are still empty.
extends Node

const AudioEvents = preload("res://scripts/data/audio_events.gd")
const AudioLayer = preload("res://scripts/audio/audio_layer.gd")
const CityAmbience = preload("res://scripts/audio/city_ambience.gd")

signal event_fired(id: String)

const POOL_SIZE := 8

# Events below this tier are counted but not played (quiet mode for tuning).
var min_tier := 0
var stats := {} # event id -> {count, suppressed, last_msec}
var _week_started_msec := 0
var _pool: Array[AudioStreamPlayer] = []
var _last_variant := {} # event id -> index of the last played variant
var _last_played_msec := {} # event id -> when it last actually played
var _streams := {} # path -> loaded stream
var _rng := RandomNumberGenerator.new()
var music
var layers := {} # Named continuous beds, independent of the event pool.
var city_ambience


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_buses()
	city_ambience = CityAmbience.new()
	add_child(city_ambience)
	layers["city"] = city_ambience
	music = add_layer("music", preload("res://assets/audio/music/city_theme.mp3"), "Music", 1.0, 3.0)
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_pool.append(player)
	begin_week()


# Resets the per-week counters; the rate shown in the panel is per real minute.
func begin_week() -> void:
	_week_started_msec = Time.get_ticks_msec()
	for id in AudioEvents.EVENTS:
		stats[id] = {"count": 0, "suppressed": 0, "last_msec": -100000}


func minutes_played() -> float:
	return (Time.get_ticks_msec() - _week_started_msec) / 60000.0


func rate_per_minute(id: String) -> float:
	return stats[id]["count"] / max(minutes_played(), 0.5)


# `counted` is false when the panel plays a sound just to listen to it.
func play(id: String, counted: bool = true) -> void:
	if not AudioEvents.EVENTS.has(id):
		push_warning("Unknown audio event: " + id)
		return
	var data: Dictionary = AudioEvents.EVENTS[id]
	var now := Time.get_ticks_msec()
	if counted:
		stats[id]["count"] += 1
		stats[id]["last_msec"] = now
		event_fired.emit(id)
	if data["tier"] < min_tier:
		return
	# Repeat limit: the same event never plays twice within its cooldown.
	if now - _last_played_msec.get(id, -100000) < data["cooldown"] * 1000.0:
		stats[id]["suppressed"] += 1
		return
	_last_played_msec[id] = now
	var stream := _pick_stream(id, data["sounds"])
	if stream == null:
		return # Silent placeholder.
	var player := _free_player(data["tier"])
	if player == null:
		return
	player.stream = stream
	player.bus = data["bus"]
	player.volume_db = data["volume_db"]
	player.pitch_scale = 1.0 + _rng.randf_range(-data["pitch_jitter"], data["pitch_jitter"])
	player.play()


# Several recordings per event, never the same one twice in a row.
func _pick_stream(id: String, paths: Array) -> AudioStream:
	var usable: Array[AudioStream] = []
	for path in paths:
		if not _streams.has(path):
			_streams[path] = load(path) if ResourceLoader.exists(path) else null
		if _streams[path] != null:
			usable.append(_streams[path])
	if usable.is_empty():
		return null
	var index := _rng.randi() % usable.size()
	if usable.size() > 1 and index == _last_variant.get(id, -1):
		index = (index + 1) % usable.size()
	_last_variant[id] = index
	return usable[index]


# When every voice is busy, quiet sounds are dropped and important ones
# (tier 3 and up) take over the oldest voice.
func _free_player(tier: int) -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	if tier >= 3:
		_pool[0].stop()
		_pool.append(_pool.pop_front())
		return _pool[-1]
	return null


func _ensure_buses() -> void:
	for bus_name in AudioEvents.BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
			if bus_name == "Music":
				set_channel_level("Music", 0.3)

# Future camera/location controllers can blend named beds without touching UI/SFX.
func add_layer(id: String, source: AudioStream, bus_name: String, gain: float = 0.0, overlap: float = 2.0) -> Node:
	if layers.has(id):
		return layers[id]
	var layer := AudioLayer.new()
	layer.name = id
	layer.stream = source
	layer.bus = bus_name
	layer.level = clampf(gain, 0.0, 1.0)
	layer.overlap_seconds = overlap
	layers[id] = layer
	add_child(layer)
	return layer


func set_layer_level(id: String, gain: float, seconds: float = 1.0) -> void:
	if layers.has(id):
		layers[id].set_level(gain, seconds)


func remove_layer(id: String) -> void:
	if layers.has(id) and id != "city" and id != "music":
		layers[id].queue_free()
		layers.erase(id)


func set_camera_proximity(proximity: float) -> void:
	# Overview retains a distant city bed; close view reaches the user's level.
	city_ambience.context_gain = lerpf(0.2, 1.0, smoothstep(0.0, 1.0, proximity))


func set_channel_level(channel: String, value: float) -> void:
	var index := AudioServer.get_bus_index(channel)
	if index < 0:
		return
	value = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(index, is_zero_approx(value))
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value, 0.0001)))


func get_channel_level(channel: String) -> float:
	var index := AudioServer.get_bus_index(channel)
	return 0.0 if AudioServer.is_bus_mute(index) else db_to_linear(AudioServer.get_bus_volume_db(index))
