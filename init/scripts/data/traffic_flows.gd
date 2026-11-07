# Counts include cars beyond the map and slots waiting to enter. Visibility is
# stable during a trip; district boundaries never hide a moving vehicle.
extends RefCounted

const CAR_COUNT := 90
const STREAMS := {
	"through": {"slots": 30, "fleet": {"truck": 0.51, "car": 0.44, "bus": 0.05}, "trips": [
		{"entry": "highway_w", "exit": "highway_e", "roads": ["highway"]},
		{"entry": "highway_e", "exit": "highway_w", "roads": ["highway"]},
	]},
	"border": {"slots": 14, "fleet": {"truck": 0.68, "car": 0.32}, "trips": [
		{"entry": "border_bridge", "exit": "axis_south", "roads": ["axis"], "semi_roads": ["axis", "north_street", "west_street", "south_street", "axis"]},
		{"entry": "axis_south", "exit": "border_bridge", "roads": ["axis"], "semi_roads": ["axis", "south_street", "west_street", "north_street", "axis"]},
		{"entry": "highway_w", "exit": "border_bridge", "roads": ["highway", "axis"]},
		{"entry": "highway_e", "exit": "border_bridge", "roads": ["highway", "axis"]},
		{"entry": "border_bridge", "exit": "highway_w", "roads": ["axis", "highway"]},
		{"entry": "border_bridge", "exit": "highway_e", "roads": ["axis", "highway"]},
	]},
	"city": {"slots": 18, "fleet": {"car": 0.8, "bus": 0.2}, "loops": [
		["south_street", "station_entry", "station_link", "station_exit"],
		["north_street", "axis", "south_street", "west_street"],
		["north_street", "village_street", "south_street", "axis"],
	]},
	"residential": {"slots": 8, "fleet": {"car": 0.9, "bus": 0.1}, "loops": [
		["north_street", "housing_spine", "housing_cross_path", "west_street"],
		["housing_cross_path", "housing_spine", "south_street", "west_street"],
		["north_street", "axis", "housing_cross_path", "housing_spine"],
		["housing_cross_path", "axis", "south_street", "housing_spine"],
	]},
	"western_transit": {"slots": 12, "fleet": {"car": 0.915, "truck": 0.085}, "trips": [
		{"entry": "north_street_w", "exit": "north_street_e", "roads": ["north_street"]},
		{"entry": "north_street_e", "exit": "north_street_w", "roads": ["north_street"]},
		{"entry": "south_street_w", "exit": "south_street_e", "roads": ["south_street"]},
		{"entry": "south_street_e", "exit": "south_street_w", "roads": ["south_street"]},
		{"entry": "north_street_w", "exit": "south_street_w", "roads": ["north_street", "west_street", "south_street"]},
		{"entry": "south_street_w", "exit": "north_street_w", "roads": ["south_street", "west_street", "north_street"]},
	]},
	"avenue_transit": {"slots": 8, "fleet": {"car": 0.8725, "truck": 0.1275}, "trips": [
		{"entry": "border_bridge", "exit": "axis_south", "roads": ["axis"], "semi_roads": ["axis", "north_street", "west_street", "south_street", "axis"]},
		{"entry": "axis_south", "exit": "border_bridge", "roads": ["axis"], "semi_roads": ["axis", "south_street", "west_street", "north_street", "axis"]},
	]},
}
