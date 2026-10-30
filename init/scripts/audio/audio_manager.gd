# Plays sound events from the table in scripts/data/audio_events.gd. Callers only
# name an event ("option_choose"); weight, variants, volume, repeat limits and
# the bus live in data. It also counts every event so the debug panel can show
# what the week actually sounded like, even while all sounds are still empty.
extends Node

const AudioEvents = preload("res://scripts/data/audio_events.gd")

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


func _ready() -> void:
	_rng.randomize()
	_ensure_buses()
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
