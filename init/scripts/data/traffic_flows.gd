# Counts include cars beyond the map and slots waiting to enter. Visibility is
# stable during a trip; district boundaries never hide a moving vehicle.
extends RefCounted

const CAR_COUNT := 66
const STREAMS := {
	"through": {"slots": 30, "fleet": {"truck": 0.6, "car": 0.35, "bus": 0.05}, "trips": [
		{"entry": "highway_w", "exit": "highway_e", "roads": ["highway"]},
		{"entry": "highway_e", "exit": "highway_w", "roads": ["highway"]},
	]},
	"border": {"slots": 14, "fleet": {"truck": 0.8, "car": 0.2}, "trips": [
		{"entry": "border_bridge", "exit": "axis_south", "roads": ["axis"]},
		{"entry": "axis_south", "exit": "border_bridge", "roads": ["axis"]},
		{"entry": "highway_w", "exit": "border_bridge", "roads": ["highway", "axis"]},
		{"entry": "highway_e", "exit": "border_bridge", "roads": ["highway", "axis"]},
		{"entry": "border_bridge", "exit": "highway_w", "roads": ["axis", "highway"]},
		{"entry": "border_bridge", "exit": "highway_e", "roads": ["axis", "highway"]},
	]},
	"city": {"slots": 18, "fleet": {"car": 0.8, "bus": 0.2}, "loops": [
		["north_street", "axis", "south_street", "west_street"],
		["north_street", "village_street", "south_street", "axis"],
	]},
	"courtyard": {"slots": 4, "fleet": {"car": 1.0}, "loops": [
		["north_street", "housing_spine", "housing_cross_path", "west_street"],
		["housing_cross_path", "housing_spine", "south_street", "west_street"],
		["north_street", "axis", "housing_cross_path", "housing_spine"],
		["housing_cross_path", "axis", "south_street", "housing_spine"],
	]},
}
