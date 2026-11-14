# A virtual listener at the ground focus avoids the distant orthographic camera.
# Each source gets a panner bus feeding the single user-facing Ambience channel.
extends Node

const WorldAudio = preload("res://scripts/data/world_audio.gd")
var scene_gain := 1.0
var _audio
var _map
var _railway
var _sources := {}
var _area_sources := {}
var _last_tick := 0.0


func setup(manager, city_map) -> void:
	_audio = manager
	_map = city_map
	_railway = _map.get_node("RailwayTraffic")
	for id in WorldAudio.SOURCES:
		_add_source(id, WorldAudio.SOURCES[id])
	_area_sources = WorldAudio.area_sources()
	for id in _area_sources:
		_add_source(id, _area_sources[id]["profile"])


func _add_source(id: String, profile: Dictionary) -> void:
	var bus_name := "World_" + id
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Ambience")
	var panner := AudioEffectPanner.new()
	AudioServer.add_bus_effect(index, panner)
	var layer = _audio.add_layer("world_" + id, profile["stream"], bus_name, profile["gain"], profile["overlap"])
	layer.context_gain = 0.0
	layer._context_smoothed = 0.0
	_sources[id] = {"layer": layer, "pan": panner, "bus": bus_name}


func set_muted(muted: bool) -> void:
	for source in _sources.values():
		AudioServer.set_bus_mute(AudioServer.get_bus_index(source["bus"]), muted)


func _process(_delta: float) -> void:
	if not is_instance_valid(_map) or _sources.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	var elapsed := maxf(0.0, now - _last_tick) if _last_tick > 0.0 else 0.0
	_last_tick = now
	var listener: Vector3 = _map.audio_listener_position()
	var proximity: float = _map.audio_proximity()
	var zoom_gain := lerpf(0.1, 1.0, smoothstep(0.0, 1.0, proximity))
	var width := maxf(_map.get_viewport().get_visible_rect().size.x, 1.0)
	var pan_weight := 1.0 - exp(-elapsed / 0.35)
	for emitter in _railway.audio_emitters():
		var id: String = emitter["id"]
		var profile: Dictionary = WorldAudio.SOURCES[id]
		var distance := INF
		var nearest := listener
		# Long formations remain audible beside their wagons, not just the engine.
		for position: Vector3 in emitter["positions"]:
			var offset := position - listener
			offset.y = 0.0
			if offset.length() < distance:
				distance = offset.length()
				nearest = position
		var gain := 1.0 - smoothstep(profile["near"], profile["far"], distance)
		if not emitter["running"]:
			gain = 0.0
		_mix_source(_sources[id], nearest, gain * zoom_gain, width, pan_weight)
	# The standard 100% view is close enough to hear local ambience.
	var local_zoom := smoothstep(0.33, 0.74, proximity)
	var hour: float = _map.visual_clock_hour()
	var daytime := smoothstep(4.0, 7.0, hour) * (1.0 - smoothstep(19.0, 22.0, hour))
	var ground := Vector2(listener.x, listener.z)
	for id in _area_sources:
		var mix := _area_mix(_area_sources[id]["zones"], ground, daytime)
		_mix_source(_sources[id], Vector3(mix.x, 0.0, mix.z), mix.y * local_zoom, width, pan_weight)


func _area_mix(zones: Array, ground: Vector2, daytime: float) -> Vector3:
	var strongest := 0.0
	var weighted_position := Vector2.ZERO
	var total_weight := 0.0
	# Blend the position across zones of one recording. The strongest zone
	# sets volume so overlapping zones of the same recording do not stack.
	for zone in zones:
		var distance := INF
		var nearest := ground
		for area: Rect2 in zone["areas"]:
			var point := ground.clamp(area.position, area.end)
			var offset := ground.distance_to(point)
			if offset < distance:
				distance = offset
				nearest = point
		var weight := (1.0 - smoothstep(zone["near"], zone["far"], distance)) * lerpf(zone["night"], zone["day"], daytime)
		weighted_position += nearest * weight
		total_weight += weight
		strongest = maxf(strongest, weight)
	var position := weighted_position / total_weight if total_weight > 0.0 else ground
	return Vector3(position.x, strongest, position.y)


func _mix_source(source: Dictionary, position: Vector3, gain: float, width: float, pan_weight: float) -> void:
	source["layer"].context_gain = gain * scene_gain
	var target_pan := 0.0
	if not _map.camera.is_position_behind(position):
		target_pan = clampf((_map.camera.unproject_position(position).x / width - 0.5) * 1.5, -0.8, 0.8)
	source["pan"].pan = lerpf(source["pan"].pan, target_pan, pan_weight)


func _exit_tree() -> void:
	for source in _sources.values():
		for voice in source["layer"]._voices:
			voice.stop()
		var index := AudioServer.get_bus_index(source["bus"])
		if index >= 0:
			AudioServer.remove_bus(index)
