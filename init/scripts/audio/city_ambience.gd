extends "res://scripts/audio/audio_layer.gd"


func _init() -> void:
	name = "CityAmbience"
	stream = preload("res://assets/audio/ambience/city_quiet.mp3")
	bus = "Ambience"
	level = 0.5
	overlap_seconds = 2.0
