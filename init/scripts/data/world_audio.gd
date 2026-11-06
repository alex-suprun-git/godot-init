# Per-source calibration before camera attenuation and the user's Ambience bus.
extends RefCounted

const SOURCES := {
	"er2": {
		"stream": preload("res://assets/audio/transport/er2_running.mp3"),
		"gain": 0.288, "near": 30.0, "far": 240.0, "overlap": 1.0,
	},
	"freight": {
		"stream": preload("res://assets/audio/transport/freight_running.mp3"),
		"gain": 0.342, "near": 40.0, "far": 280.0, "overlap": 1.0,
	},
}
