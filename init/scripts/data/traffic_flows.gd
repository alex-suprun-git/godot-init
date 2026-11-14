# Counts include cars beyond the map and slots waiting to enter. Visibility is
# stable during a trip; district boundaries never hide a moving vehicle.
extends RefCounted

const CAR_COUNT := 98
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
	"city": {"slots": 16, "fleet": {"car": 1.0}, "loops": [
		["south_street", "station_entry", "station_link", "station_exit"],
		["north_street", "axis", "south_street", "west_street"],
		["north_street", "village_street", "south_street", "axis"],
	]},
	"residential": {"slots": 14, "fleet": {"car": 1.0}, "loops": [
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
	# Scheduled buses: the trips and their stops come from data/bus_stops.gd ROUTES. Two buses ring
	# line 1; line 2 gets one bus per direction (slot order picks the trip, see _add_car).
	"bus_ring": {"slots": 2, "fleet": {"bus": 1.0}, "line": "1"},
	"bus_avenue": {"slots": 2, "fleet": {"bus": 1.0}, "line": "2"},
}
