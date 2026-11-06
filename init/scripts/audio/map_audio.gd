# A virtual listener at the ground focus avoids the distant orthographic camera.
# Each source gets a panner bus feeding the single user-facing Ambience channel.
extends Node

const WorldAudio = preload("res://scripts/data/world_audio.gd")
var _audio
var _map
var _railway
var _sources := {}
var _last_tick := 0.0


func setup(manager, city_map) -> void:
	_audio = manager
	_map = city_map
	_railway = _map.get_node("RailwayTraffic")
	for id in WorldAudio.SOURCES:
		var profile: Dictionary = WorldAudio.SOURCES[id]
		var bus_name: String = "World_" + id
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


func _process(_delta: float) -> void:
	if not is_instance_valid(_map) or _sources.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	var elapsed := maxf(0.0, now - _last_tick) if _last_tick > 0.0 else 0.0
	_last_tick = now
	var listener: Vector3 = _map.audio_listener_position()
	var zoom_gain := lerpf(0.1, 1.0, smoothstep(0.0, 1.0, _map.audio_proximity()))
	var width := maxf(_map.get_viewport().get_visible_rect().size.x, 1.0)
	for emitter in _railway.audio_emitters():
		var id: String = emitter["id"]
		var profile: Dictionary = WorldAudio.SOURCES[id]
		var source: Dictionary = _sources[id]
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
		source["layer"].context_gain = gain * zoom_gain
		var target_pan := 0.0
		if not _map.camera.is_position_behind(nearest):
			target_pan = clampf((_map.camera.unproject_position(nearest).x / width - 0.5) * 1.5, -0.8, 0.8)
		source["pan"].pan = lerpf(source["pan"].pan, target_pan, 1.0 - exp(-elapsed / 0.35))


func _exit_tree() -> void:
	for source in _sources.values():
		for voice in source["layer"]._voices:
			voice.stop()
		var index := AudioServer.get_bus_index(source["bus"])
		if index >= 0:
			AudioServer.remove_bus(index)
