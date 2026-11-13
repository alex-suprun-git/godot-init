# Per-source calibration before camera attenuation and the user's Ambience bus.
extends RefCounted

const DistrictLayout := preload("res://scripts/data/district_layout.gd")

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

const CROWD := {
	"stream": preload("res://assets/audio/ambience/crowd.mp3"),
	"gain": 0.64, "overlap": 1.0,
}

# Zero-size areas retain the radial falloff of the market and station emitters.
const CROWD_ZONES := [
	{"areas": [Rect2(-121, 367, 0, 0)], "near": 24.0, "far": 79.0, "day": 1.0, "night": 0.0}, # Market
	{"areas": [Rect2(-75, 357, 0, 0)], "near": 25.0, "far": 82.0, "day": 0.85, "night": 0.20}, # Station and bus square
	{
		# The avenue pavements and the connected DK forecourt and store frontage.
		"areas": [DistrictLayout.WORKDAY_FOOT_AXIS, Rect2(7, -60, 63, 94)],
		"near": 5.0, "far": 40.0, "day": 0.55, "night": 0.0,
	},
]


static func area_sources() -> Dictionary:
	return {
		"crowd": {"profile": CROWD, "zones": CROWD_ZONES},
		"courtyards": {
			"profile": {
				"stream": preload("res://assets/audio/ambience/dvor.mp3"),
				"gain": 0.55, "overlap": 2.0,
			},
			"zones": [{
				# The school and kindergarten reserves are inside the housing district.
				"areas": DistrictLayout.DISTRICTS["panel_housing"]["rects"],
				"near": 0.0, "far": 38.0, "day": 1.0, "night": 0.25,
			}],
		},
		"village": {
			"profile": {
				"stream": preload("res://assets/audio/ambience/village.mp3"),
				"gain": 1.0, "overlap": 2.0,
			},
			"zones": [{
				"areas": DistrictLayout.DISTRICTS["village"]["rects"],
				"near": 0.0, "far": 42.0, "day": 1.0, "night": 0.4,
			}],
		},
		"transport_yards": {
			"profile": {
				"stream": preload("res://assets/audio/ambience/transport_yards.mp3"),
				"gain": 0.36, "overlap": 2.0,
			},
			"zones": [{
				"areas": [DistrictLayout.LOTS["atp"]["rect"], DistrictLayout.LOTS["truck_stop"]["rect"]],
				"near": 6.0, "far": 46.0, "day": 1.0, "night": 0.15,
			}],
		},
		"highway": {
			"profile": {
				"stream": preload("res://assets/audio/ambience/highway.mp3"),
				"gain": 0.40, "overlap": 2.0,
			},
			"zones": [{
				"areas": [DistrictLayout.road_by_id("highway")["rect"]],
				"near": 5.0, "far": 80.0, "day": 1.0, "night": 0.5,
			}],
		},
	}
