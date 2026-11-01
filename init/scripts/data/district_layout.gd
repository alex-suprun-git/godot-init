# Fixed district geography in metres. Residential spacing is 88% of the v3 sketch.
# Building footprints retain their real dimensions; only centres and core lots contract.
# x is east, the second Vector2 component is south (world z).
extends RefCounted

const HOUSING_SPACING := 0.88

const LOTS := {
	"housing_reserve_w": {"type": "R", "rect": Rect2(-440, -70, 44, 365), "content": "housing_reserve", "condition": "kept", "facing": "e"},
	"housing_reserve_s": {"type": "R", "rect": Rect2(-390, 261, 365, 34), "content": "housing_reserve", "condition": "kept", "facing": "n"},
	"forest_clearing": {"type": "N", "rect": Rect2(-537, 108, 28, 24), "content": "forest_clearing", "condition": "kept", "facing": "e"},
	"pond_bank": {"type": "N", "rect": Rect2(265, -20, 24, 10), "content": "pond_bank", "condition": "kept", "facing": "s"},
	"atp": {"type": "X", "rect": Rect2(-430, -320, 140, 120), "content": "atp", "condition": "worked", "facing": "s"},
	"truck_stop": {"type": "X", "rect": Rect2(-280, -320, 140, 120), "content": "truck_stop", "condition": "worked", "facing": "s"},
	"checkpoint": {"type": "X", "rect": Rect2(-130, -320, 250, 120), "content": "checkpoint", "condition": "kept", "facing": "s"},
	"port": {"type": "X", "rect": Rect2(130, -320, 160, 120), "content": "port", "condition": "worked", "facing": "n"},
	"fuel_depot": {"type": "X", "rect": Rect2(300, -320, 95, 120), "content": "fuel_depot", "condition": "worked", "facing": "s"},
	"boiler": {"type": "X", "rect": Rect2(-430, -170, 100, 75), "content": "boiler_house", "condition": "worked", "facing": "s"},
	"garages": {"type": "G", "rect": Rect2(-320, -170, 290, 75), "content": "garages", "condition": "worked", "facing": "s"},
	"reserve": {"type": "R", "rect": Rect2(15, -170, 380, 75), "content": "wasteland", "condition": "abandoned", "facing": "s"},
	"a1_n": {"type": "W", "rect": Rect2(-337.8, -75.28, 90, 24), "content": "panel_5", "condition": "kept", "facing": "s"},
	"a1_s": {"type": "W", "rect": Rect2(-337.8, 58.48, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"a1_w": {"type": "W", "rect": Rect2(-380.48, -41.4, 24, 90), "content": "panel_9", "condition": "kept", "facing": "e"},
	"a1_e": {"type": "W", "rect": Rect2(-229.12, -41.4, 24, 90), "content": "panel_5", "condition": "kept", "facing": "w"},
	"a1_k": {"type": "K", "rect": Rect2(-336.8, -31.6, 88, 70.4), "content": "yard", "condition": "kept", "facing": "s"},
	"b1_n": {"type": "W", "rect": Rect2(-153, -75.28, 90, 24), "content": "panel_5", "condition": "kept", "facing": "s"},
	"b1_s": {"type": "W", "rect": Rect2(-153, 58.48, 90, 24), "content": "panel_9", "condition": "kept", "facing": "n"},
	"b1_w": {"type": "W", "rect": Rect2(-195.68, -41.4, 24, 90), "content": "panel_5", "condition": "kept", "facing": "e"},
	"b1_e": {"type": "W", "rect": Rect2(-44.32, -41.4, 24, 90), "content": "panel_5", "condition": "kept", "facing": "w"},
	"b1_k": {"type": "K", "rect": Rect2(-152, -31.6, 88, 70.4), "content": "yard", "condition": "kept", "facing": "s"},
	"a2_n": {"type": "W", "rect": Rect2(-337.8, 91.92, 90, 24), "content": "panel_9", "condition": "kept", "facing": "s"},
	"a2_s": {"type": "W", "rect": Rect2(-337.8, 225.68, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"a2_w": {"type": "W", "rect": Rect2(-380.48, 125.8, 24, 90), "content": "panel_5", "condition": "kept", "facing": "e"},
	"a2_e": {"type": "W", "rect": Rect2(-229.12, 125.8, 24, 90), "content": "panel_9", "condition": "kept", "facing": "w"},
	"a2_k": {"type": "K", "rect": Rect2(-336.8, 135.6, 88, 70.4), "content": "wasteland", "condition": "abandoned", "facing": "s"},
	"b2_n": {"type": "W", "rect": Rect2(-153, 91.92, 90, 24), "content": "panel_5", "condition": "kept", "facing": "s"},
	"b2_s": {"type": "W", "rect": Rect2(-153, 225.68, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"b2_w": {"type": "W", "rect": Rect2(-195.68, 125.8, 24, 90), "content": "panel_9", "condition": "kept", "facing": "e"},
	"b2_k": {"type": "K", "rect": Rect2(-152, 135.6, 88, 70.4), "content": "yard", "condition": "kept", "facing": "s"},
	"police": {"type": "G", "rect": Rect2(-44, -75, 24, 32), "content": "police", "condition": "kept", "facing": "e"},
	"polyclinic": {"type": "G", "rect": Rect2(-45, 135, 28, 42), "content": "polyclinic", "condition": "kept", "facing": "e"},
	"ispolkom": {"type": "G", "rect": Rect2(25, 22, 115, 108), "content": "ispolkom", "condition": "kept", "facing": "w"},
	"tower_e1": {"type": "W", "rect": Rect2(30, -60, 40, 38), "content": "elite_tower_placeholder", "condition": "kept", "facing": "w"},
	"department_store": {"type": "G", "rect": Rect2(30, -15, 45, 30), "content": "department_store", "condition": "kept", "facing": "w"},
	"city_park": {"type": "N", "rect": Rect2(82, -72, 54, 84), "content": "city_park", "condition": "kept", "facing": "e"},
	"tower_e2": {"type": "W", "rect": Rect2(30, 140, 40, 38), "content": "elite_tower_placeholder", "condition": "kept", "facing": "w"},
	"tower_e3": {"type": "W", "rect": Rect2(82, 140, 40, 38), "content": "elite_tower_placeholder", "condition": "kept", "facing": "w"},
	"slab_1": {"type": "W", "rect": Rect2(22, 190, 110, 14), "content": "admin_slab", "condition": "kept", "facing": "s"},
	"slab_2": {"type": "W", "rect": Rect2(22, 232, 110, 14), "content": "admin_slab", "condition": "kept", "facing": "n"},
	"church": {"type": "X", "rect": Rect2(245, 80, 60, 50), "content": "church", "condition": "fading", "facing": "w"},
	"g_south": {"type": "G", "rect": Rect2(-430, 315, 200, 70), "content": "empty_lot", "condition": "worked", "facing": "n"},
	"former_market": {"type": "N", "rect": Rect2(-215, 315, 185, 70), "content": "former_market", "condition": "kept", "facing": "n"},
	# One painted site contains the market, bus bays and railway station.
	"market": {"type": "X", "rect": Rect2(-20, 315, 250, 78), "content": "market", "condition": "kept", "facing": "n"},
	"cemetery": {"type": "N", "rect": Rect2(209, 84.5, 35, 46), "content": "cemetery", "condition": "fading", "facing": "n"},
	"d_01": {"type": "D", "rect": Rect2(156.5, -40, 42, 38), "content": "house_poor", "condition": "fading", "facing": "n"},
	"d_02": {"type": "D", "rect": Rect2(334.5, -40, 50, 38), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_03": {"type": "D", "rect": Rect2(164.5, -0.5, 38, 38), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_04": {"type": "D", "rect": Rect2(164.5, 37.5, 38, 46), "content": "house_poor", "condition": "fading", "facing": "e"},
	"d_05": {"type": "D", "rect": Rect2(164.5, 83.5, 38, 38), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_06": {"type": "D", "rect": Rect2(164.5, 121.5, 38, 46), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_07": {"type": "D", "rect": Rect2(164.5, 167.5, 38, 38), "content": "house_poor", "condition": "fading", "facing": "e"},
	"d_08": {"type": "D", "rect": Rect2(164.5, 205.5, 38, 42), "content": "house_abandoned", "condition": "abandoned", "facing": "e"},
	"d_09": {"type": "D", "rect": Rect2(207.5, 133.5, 38, 50), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_10": {"type": "D", "rect": Rect2(207.5, 231.5, 38, 50), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_11": {"type": "D", "rect": Rect2(284.5, 134, 38, 42), "content": "house_poor", "condition": "fading", "facing": "e"},
	"d_12": {"type": "D", "rect": Rect2(284.5, 176, 38, 46), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_13": {"type": "D", "rect": Rect2(247.5, 134, 35, 91), "content": "house_kept", "condition": "kept", "facing": "s"},
	"d_14": {"type": "D", "rect": Rect2(327.5, 80, 38, 38), "content": "house_abandoned", "condition": "abandoned", "facing": "w"},
	"d_15": {"type": "D", "rect": Rect2(327.5, 118, 38, 38), "content": "house_poor", "condition": "fading", "facing": "w"},
	"d_16": {"type": "D", "rect": Rect2(327.5, 156, 38, 38), "content": "house_poor", "condition": "fading", "facing": "w"},
	"d_17": {"type": "D", "rect": Rect2(327.5, 220, 38, 50), "content": "house_kept", "condition": "kept", "facing": "n"},
}

# Asphalt roads get a pavement on both sides (SIDEWALK_WIDTH); a road may override it
# with "walk": 0.0. The highway along the river has no pedestrian zone.
const SIDEWALK_WIDTH := 2.5

const ROADS := [
	{"id": "highway", "rect": Rect2(-450, -197.5, 875, 20), "kind": "asphalt", "walk": 0.0, "look": "highway"},
	{"id": "north_street", "rect": Rect2(-450, -90, 890, 10), "kind": "asphalt"},
	{"id": "south_street", "rect": Rect2(-450, 300, 890, 10), "kind": "asphalt"},
	{"id": "axis", "rect": Rect2(-17, -330, 24, 642), "kind": "asphalt", "median": 4.0},
	{"id": "village_street", "rect": Rect2(140, -80, 10, 380), "kind": "asphalt"},
	{"id": "housing_cross_path", "rect": Rect2(-398.4, 82.2, 381.4, 10), "kind": "yard"}, # ends at the axis edge (x -17): a gap lets the graph miss the junction
	{"id": "housing_spine", "rect": Rect2(-205.4, -80, 10, 380), "kind": "yard"},
	# Civic square / southern tower connection, and the lane between the two slabs.
	{"id": "square_link", "rect": Rect2(7, 136, 133, 4), "kind": "yard"},
	{"id": "civic_lane", "rect": Rect2(7, 209, 133, 5), "kind": "asphalt", "walk": 1.5},
	# Short avenue links serving the northern and southern tower groups.
	{"id": "north_tower_link", "rect": Rect2(7, -8, 20, 3), "kind": "yard"},
	{"id": "south_tower_link", "rect": Rect2(7, 172, 20, 3), "kind": "yard"},
	# Village dirt roads form closed loops: H1 north, V1 west, H2 around the church,
	# V2 east, H4 south, plus an east lane joining the ends of H1 and H3.
	{"id": "village_north", "rect": Rect2(150, -45, 237.5, 5), "kind": "dirt"},
	{"id": "village_west", "rect": Rect2(202.5, -42.5, 5, 275), "kind": "dirt"},
	# West lane: the village's only link to the village street besides the north end.
	{"id": "village_west_link", "rect": Rect2(150, 77.5, 55, 5), "kind": "dirt"},
	{"id": "village_church", "rect": Rect2(205, 77.5, 122.5, 5), "kind": "dirt"},
	{"id": "village_east", "rect": Rect2(322.5, 80, 5, 150), "kind": "dirt"},
	{"id": "village_east_link", "rect": Rect2(325, 215, 70, 5), "kind": "dirt"},
	{"id": "village_south", "rect": Rect2(205, 225, 122.5, 5), "kind": "dirt"},
	{"id": "village_outer_lane", "rect": Rect2(382.5, -42.5, 5, 262.5), "kind": "dirt"},
]

# The passenger tracks turn north into the eastern freight corridor.
const RAILS := [
	[Vector2(-450, 395), Vector2(410, 395), Vector2(410, -495)],
	[Vector2(-450, 405), Vector2(420, 405), Vector2(420, -495)],
	# The port siding leaves the elevated main line at deck height and climbs down on its own ramp.
	[Vector2(410, -250), Vector2(402, -245), Vector2(150, -245)],
]
# A wide river: barges pass under both bridges, whose decks rise to a hump over the water.
# The eastern freight line runs on an embankment past the village: it climbs over
# `ramp` metres at both ends and the two E-W roads pass under it in short tunnels
# centred on `tunnels` (z), each `gap` metres long along the track.
const EMBANKMENT := {
	"cx": 415.0, "tracks": [410.0, 420.0], "top": 10.0, "height": 6.0,
	# Starts at the rail bridge's south end at deck height (ramp_from 0), then descends to the south.
	"from": -280.0, "to": 375.0, "ramp": 90.0, "ramp_from": 0.0, "tunnels": [-85.0, 305.0], "gap": 13.0,
}
const SIDING_RAMP := {"z": -245.0, "x_from": 315.0, "x_to": 402.0, "height": 6.0, "top": 3.5}
const WATER := Rect2(-450, -440, 900, 110)
const FOREIGN_BANK := Rect2(-450, -500, 900, 60)
const BRIDGES := [
	# The road bridge ends at the water's edge on the town side; its deck climbs to
	# `height` over `ramp` metres at both ends, so cars and people ride on it.
	# Same x range as the civic axis (-17..7), so the boulevard carries straight onto the bridge.
	{"rect": Rect2(-17, -445, 24, 115), "height": 6.0, "ramp": 40.0, "kind": "road"},
	# The railway climbs an embankment on land, 50 m each side of the river.
	{"rect": Rect2(405, -495, 20, 215), "height": 6.0, "ramp": 50.0, "kind": "rail", "flat_end": true},
]
const AREAS := {
	"village": {"rect": Rect2(155, -75, 240, 370), "ground": "grass_dry", "condition": "fading"},
}


# --- Districts -----------------------------------------------------------------
# Two levels of living-city data, independent of lots. A district sets the character
# of a part of the map; a subzone inside it overrides only the fields it names.
# The first district (in order) whose rects contain a point wins, so a district that
# pokes into another one (the police corner, the polyclinic) is listed before it.
# The axis and the highway carry no district: cars only, nobody lives there.
#
#   residents  people who live there (story and consequences; never drawn one by one)
#   foot, cars relative density of visible pedestrians and cars (1.0 = typical)
#   fleet      vehicle class weights: car (passenger, several models), truck, bus, tractor
#   hours      key of HOURS, how busy the area is through the day
# Figures are provisional and meant to be tuned by playing.
const DISTRICTS := {
	"admin": {
		"name": "Administrative centre",
		"rects": [Rect2(20, -80, 125, 350), Rect2(-44, -75, 24, 32), Rect2(-45, 135, 28, 42)],
		"residents": 1200, "foot": 1.4, "cars": 0.8,
		"fleet": {"car": 0.8, "bus": 0.2}, "hours": "office",
		"subzones": {
			"admin_police": {"rect": Rect2(-44, -75, 24, 32), "cars": 0.6},
			"admin_polyclinic": {"rect": Rect2(-45, 135, 28, 42), "foot": 1.8, "hours": "commute"},
			"admin_square": {"rect": Rect2(25, 22, 115, 108), "foot": 2.0, "cars": 0.3},
			"admin_park": {"rect": Rect2(82, -72, 54, 84), "foot": 0.9, "cars": 0.0, "hours": "leisure"},
			"admin_shops": {"rect": Rect2(30, -15, 45, 30), "foot": 2.2, "hours": "market"},
			"admin_elite": {"rect": Rect2(30, -60, 40, 38), "residents": 450, "foot": 0.5, "cars": 1.2, "fleet": {"car": 1.0}},
			"admin_elite_e2": {"rect": Rect2(30, 140, 40, 38), "foot": 0.5, "cars": 1.2, "fleet": {"car": 1.0}},
			"admin_elite_e3": {"rect": Rect2(82, 140, 40, 38), "foot": 0.5, "cars": 1.2, "fleet": {"car": 1.0}},
			"admin_slab_1": {"rect": Rect2(22, 190, 110, 14), "hours": "commute"},
			"admin_slab_2": {"rect": Rect2(22, 232, 110, 14), "hours": "commute"},
		},
	},
	"transport": {
		"name": "Transport band",
		"rects": [Rect2(-440, -325, 835, 130)],
		"residents": 100, "foot": 0.3, "cars": 1.6,
		"fleet": {"truck": 0.7, "car": 0.25, "bus": 0.05}, "hours": "round_clock",
		"subzones": {
			"border_crossing": {"rect": Rect2(-130, -320, 250, 120), "foot": 0.7, "cars": 2.2, "fleet": {"truck": 0.8, "car": 0.2}},
			"truck_stop": {"rect": Rect2(-280, -320, 140, 120), "foot": 0.5, "fleet": {"truck": 0.85, "car": 0.15}},
			"atp_depot": {"rect": Rect2(-430, -320, 140, 120), "foot": 0.4, "fleet": {"truck": 0.5, "bus": 0.4, "car": 0.1}, "hours": "office"},
			"river_port": {"rect": Rect2(130, -320, 160, 120), "foot": 0.4, "fleet": {"truck": 0.9, "car": 0.1}},
			"fuel_depot": {"rect": Rect2(300, -320, 95, 120), "foot": 0.1, "cars": 0.6, "fleet": {"truck": 1.0}},
		},
	},
	"service": {
		"name": "Service belt",
		"rects": [Rect2(-440, -172, 835, 80)],
		"residents": 20, "foot": 0.2, "cars": 0.5,
		"fleet": {"car": 0.5, "truck": 0.3, "tractor": 0.2}, "hours": "office",
		"subzones": {
			"boiler_house": {"rect": Rect2(-430, -170, 100, 75), "foot": 0.3, "fleet": {"truck": 0.6, "car": 0.4}},
			"garage_coop": {"rect": Rect2(-320, -170, 290, 75), "foot": 0.5, "cars": 0.8, "fleet": {"car": 1.0}, "hours": "commute"},
			"wasteland": {"rect": Rect2(15, -170, 380, 75), "foot": 0.05, "cars": 0.1, "fleet": {"tractor": 0.7, "car": 0.3}},
		},
	},
	"panel_housing": {
		"name": "Panel housing",
		"rects": [Rect2(-440, -78, 420, 376)],
		"residents": 4000, "foot": 1.0, "cars": 0.4,
		"fleet": {"car": 0.85, "bus": 0.15}, "hours": "commute",
		"subzones": {
			"superblock_a1": {"rect": Rect2(-380, -75, 175, 157)},
			"superblock_b1": {"rect": Rect2(-196, -75, 176, 157)},
			"superblock_a2": {"rect": Rect2(-380, 92, 175, 158), "residents": 900},
			"superblock_b2": {"rect": Rect2(-196, 92, 176, 158)},
			"housing_reserves": {"rect": Rect2(-440, 255, 420, 40), "residents": 0, "foot": 0.1, "cars": 0.1},
		},
	},
	"village": {
		"name": "Old village",
		"rects": [Rect2(150, -80, 245, 375)],
		"residents": 300, "foot": 0.5, "cars": 0.2,
		"fleet": {"car": 0.55, "tractor": 0.4, "truck": 0.05}, "hours": "farm",
		"subzones": {
			"church_cemetery": {"rect": Rect2(209, 80, 96, 50), "residents": 5, "foot": 0.6, "hours": "leisure"},
			"pond": {"rect": Rect2(255, -30, 45, 30), "residents": 0, "foot": 0.3, "cars": 0.0, "hours": "leisure"},
		},
	},
	"south_hub": {
		"name": "South hub",
		"rects": [Rect2(-430, 312, 660, 81)],
		"residents": 50, "foot": 1.5, "cars": 1.0,
		"fleet": {"car": 0.5, "bus": 0.4, "truck": 0.1}, "hours": "market",
		"subzones": {
			"former_market": {"rect": Rect2(-215, 315, 185, 70), "foot": 0.2, "cars": 0.0},
			"market": {"rect": Rect2(-20, 315, 150, 78), "foot": 2.5, "cars": 0.7, "fleet": {"car": 0.6, "truck": 0.4}},
			"station": {"rect": Rect2(130, 315, 100, 78), "foot": 1.6, "cars": 1.2, "fleet": {"bus": 0.6, "car": 0.4}, "hours": "commute"},
		},
	},
}

# Activity through the day, one multiplier per hour 0..23 (1.0 = the district's typical level).
const HOURS := {
	"round_clock": [0.7, 0.6, 0.6, 0.6, 0.7, 0.8, 1.0, 1.1, 1.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.1, 1.1, 1.0, 0.9, 0.8, 0.8, 0.7, 0.7],
	"commute": [0.05, 0.03, 0.03, 0.03, 0.1, 0.5, 1.6, 2.0, 1.4, 0.6, 0.5, 0.5, 0.7, 0.6, 0.5, 0.6, 1.0, 1.8, 1.8, 1.0, 0.6, 0.4, 0.2, 0.1],
	"office": [0.05, 0.03, 0.03, 0.03, 0.05, 0.2, 0.7, 1.3, 1.6, 1.5, 1.4, 1.3, 1.2, 1.3, 1.4, 1.4, 1.3, 1.0, 0.5, 0.3, 0.2, 0.1, 0.1, 0.05],
	"market": [0.0, 0.0, 0.0, 0.0, 0.1, 0.5, 1.0, 1.6, 2.0, 2.0, 1.8, 1.6, 1.5, 1.4, 1.2, 0.9, 0.6, 0.3, 0.1, 0.05, 0.0, 0.0, 0.0, 0.0],
	"farm": [0.0, 0.0, 0.0, 0.1, 0.5, 1.2, 1.6, 1.4, 1.2, 1.0, 0.8, 0.6, 0.6, 0.8, 1.0, 1.0, 1.0, 1.0, 0.8, 0.5, 0.2, 0.1, 0.0, 0.0],
	"leisure": [0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.3, 0.5, 0.7, 0.9, 1.0, 1.0, 1.1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.4, 1.1, 0.7, 0.3, 0.1, 0.0],
}
# Also the profile of the through roads (the axis, the highway, the cross streets), which
# belong to no district: nobody lives there, trucks and buses pass through.
const DISTRICT_DEFAULTS := {"residents": 0, "foot": 0.5, "cars": 0.9, "fleet": {"car": 0.65, "truck": 0.2, "bus": 0.15}, "hours": "round_clock"}


# Id of the subzone under a point, "" if there is none.
static func subzone_at(point: Vector2) -> String:
	for district in DISTRICTS.values():
		for id in district["subzones"]:
			if district["subzones"][id]["rect"].has_point(point):
				return id
	return ""


# Id of the district under a point, "" on the axis, the highway and open ground.
static func district_at(point: Vector2) -> String:
	for id in DISTRICTS:
		for rect: Rect2 in DISTRICTS[id]["rects"]:
			if rect.has_point(point):
				return id
	return ""


# The district's figures with the subzone's overrides laid over them. Always complete.
static func profile_at(point: Vector2) -> Dictionary:
	var result: Dictionary = DISTRICT_DEFAULTS.duplicate(true)
	var id := district_at(point)
	if id == "":
		return result
	var district: Dictionary = DISTRICTS[id]
	for key in DISTRICT_DEFAULTS:
		if district.has(key):
			result[key] = district[key]
	var sub := subzone_at(point)
	if sub != "" and district["subzones"].has(sub):
		for key in DISTRICT_DEFAULTS:
			if district["subzones"][sub].has(key):
				result[key] = district["subzones"][sub][key]
	result["district"] = id
	result["subzone"] = sub
	return result


# Visible pedestrians (or cars) at this spot and hour, relative to a typical place.
static func crowd_at(point: Vector2, hour: int, cars: bool = false) -> float:
	var profile := profile_at(point)
	return float(profile["cars" if cars else "foot"]) * float(HOURS[profile["hours"]][posmod(hour, 24)])


# Returns the problems found; an empty array means the data is consistent.
static func validate_districts() -> PackedStringArray:
	var problems := PackedStringArray()
	for id in DISTRICTS:
		var district: Dictionary = DISTRICTS[id]
		if not HOURS.has(district["hours"]):
			problems.append("%s: unknown hours '%s'" % [id, district["hours"]])
		for sub_id in district["subzones"]:
			var sub: Dictionary = district["subzones"][sub_id]
			var inside := false
			for rect: Rect2 in district["rects"]:
				if rect.encloses(sub["rect"]):
					inside = true
			if not inside:
				problems.append("%s/%s: subzone is not inside its district" % [id, sub_id])
			if sub.has("hours") and not HOURS.has(sub["hours"]):
				problems.append("%s/%s: unknown hours '%s'" % [id, sub_id, sub["hours"]])
	for key in HOURS:
		if HOURS[key].size() != 24:
			problems.append("HOURS.%s needs 24 values" % key)
	return problems


static func sidewalk_width(road: Dictionary) -> float:
	return road.get("walk", SIDEWALK_WIDTH) if road["kind"] == "asphalt" else 0.0


static func lot_rect(id: String) -> Rect2:
	if not LOTS.has(id):
		push_error("DistrictLayout: unknown lot '%s'" % id)
		return Rect2()
	return LOTS[id]["rect"]


static func lot_center(id: String) -> Vector2:
	return lot_rect(id).get_center()


# Shared by road paint and the ambient pedestrian graph. Each crossing spans one
# asphalt road; side roads get markings on every arm that actually continues.
static func crosswalks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for road in ROADS:
		if road["kind"] != "asphalt":
			continue
		var rect: Rect2 = road["rect"]
		var horizontal := rect.size.x > rect.size.y
		var half := (rect.size.y if horizontal else rect.size.x) / 2.0
		for other in ROADS:
			var junction: Rect2 = other["rect"]
			if horizontal == (junction.size.x > junction.size.y) or not rect.intersects(junction.grow(0.1)):
				continue
			var center := Vector2(junction.get_center().x, rect.get_center().y) if horizontal else Vector2(rect.get_center().x, junction.get_center().y)
			var offsets: Array[float] = [0.0]
			if other["kind"] == "asphalt":
				# Without longitudinal highway pavements, follow the crossing
				# street's pavements straight across instead of stranding the zebra.
				var setback := 3.0 if sidewalk_width(road) > 0.0 else sidewalk_width(other) / 2.0
				var reach := (junction.size.x if horizontal else junction.size.y) / 2.0 + setback
				offsets = [-reach, reach]
			for offset in offsets:
				var at := center + (Vector2(offset, 0) if horizontal else Vector2(0, offset))
				if not rect.has_point(at):
					continue
				var across := Vector2(0, half + sidewalk_width(road) / 2.0) if horizontal else Vector2(half + sidewalk_width(road) / 2.0, 0)
				var side := "before" if offset < 0.0 else ("after" if offset > 0.0 else "center")
				result.append({"id": "%s__%s__%s" % [road["id"], other["id"], side],
					"road_id": road["id"], "joining_road_id": other["id"],
					"at": at, "width": half * 2.0, "along_z": not horizontal, "a": at - across, "b": at + across})
	return result


static func road_by_id(id: String) -> Dictionary:
	for road in ROADS:
		if road["id"] == id:
			return road
	push_error("DistrictLayout: unknown road '%s'" % id)
	return {}
