# Fixed district geography in metres. Residential spacing is 88% of the v3 sketch.
# Building footprints retain their real dimensions; only centres and core lots contract.
# x is east, the second Vector2 component is south (world z).
extends RefCounted

const HOUSING_SPACING := 0.88

const LOTS := {
	# Infill uses existing panel types; the four school/core reserves remain intact.
	"west_1_w": {"type": "W", "rect": Rect2(-468, -70, 24, 90), "content": "panel_5", "condition": "kept", "facing": "e"},
	"west_1_e": {"type": "W", "rect": Rect2(-420, -70, 24, 90), "content": "panel_9", "condition": "kept", "facing": "w"},
	"dormitory": {"type": "W", "rect": Rect2(-472.5, 30, 38, 45), "content": "dormitory", "condition": "kept", "facing": "s", "entrance": Vector2(-450.8, 75)},
	"west_2_w": {"type": "W", "rect": Rect2(-468, 99, 24, 90), "content": "panel_9", "condition": "kept", "facing": "e"},
	"west_2_e": {"type": "W", "rect": Rect2(-420, 99, 24, 90), "content": "panel_5", "condition": "kept", "facing": "w"},
	"west_3_w": {"type": "W", "rect": Rect2(-468, 200, 24, 90), "content": "panel_5", "condition": "kept", "facing": "e"},
	"west_3_e": {"type": "W", "rect": Rect2(-420, 200, 24, 90), "content": "panel_9", "condition": "kept", "facing": "w"},
	"south_1": {"type": "W", "rect": Rect2(-390, 270, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"south_2": {"type": "W", "rect": Rect2(-298, 270, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"south_3": {"type": "W", "rect": Rect2(-150, 270, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"forest_clearing": {"type": "N", "rect": Rect2(-567, 108, 28, 24), "content": "forest_clearing", "condition": "kept", "facing": "e"},
	"pond_bank": {"type": "N", "rect": Rect2(259.0986, -22.8224, 22.7684, 9.4868), "content": "pond_bank", "condition": "kept", "facing": "s"},
	"atp": {"type": "X", "rect": Rect2(-420, -282, 120, 82), "content": "atp", "condition": "worked", "facing": "s"},
	"truck_stop": {"type": "X", "rect": Rect2(-280, -282, 100, 82), "content": "truck_stop", "condition": "worked", "facing": "s"},
	"checkpoint": {"type": "X", "rect": Rect2(-170, -320, 330, 120), "content": "checkpoint", "condition": "kept", "facing": "s"},
	"port": {"type": "X", "rect": Rect2(170, -320, 120, 120), "content": "port", "condition": "worked", "facing": "n"},
	"fuel_depot": {"type": "X", "rect": Rect2(300, -282, 95, 82), "content": "fuel_depot", "condition": "worked", "facing": "s"},
	"boiler": {"type": "X", "rect": Rect2(-420, -157, 80, 62), "content": "boiler_house", "condition": "worked", "facing": "s"},
	# Wheat meets both road edges, with no verge/headland rim. Keep the 80 m
	# boiler gap and carry the western end beyond the opaque edge haze.
	"boiler_field": {"type": "N", "rect": Rect2(-795, -177.5, 285, 87.5), "content": "wheat_field", "condition": "kept", "facing": "s", "haze_overlap": 145.0, "verge": 0.0, "headland": 0.0},
	"garages": {"type": "G", "rect": Rect2(-309, -137, 126, 42), "content": "garages", "condition": "worked", "facing": "s"},
	"reserve": {"type": "R", "rect": Rect2(15, -174.5, 420, 79), "content": "wheat_field", "condition": "kept", "facing": "s"},
	"a1_n": {"type": "W", "rect": Rect2(-337.8, -75.28, 90, 24), "content": "panel_5", "condition": "kept", "facing": "s"},
	"a1_s": {"type": "W", "rect": Rect2(-337.8, 55.48, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"a1_w": {"type": "W", "rect": Rect2(-380.48, -41.4, 24, 90), "content": "panel_9", "condition": "kept", "facing": "e"},
	"a1_e": {"type": "W", "rect": Rect2(-232.12, -41.4, 24, 90), "content": "panel_5", "condition": "kept", "facing": "w"},
	"a1_k": {"type": "K", "rect": Rect2(-336.8, -31.6, 88, 70.4), "content": "yard", "condition": "kept", "facing": "s"},
	"b1_n": {"type": "W", "rect": Rect2(-153, -75.28, 90, 24), "content": "panel_5", "condition": "kept", "facing": "s"},
	"b1_s": {"type": "W", "rect": Rect2(-153, 55.48, 90, 24), "content": "panel_9", "condition": "kept", "facing": "n"},
	"b1_w": {"type": "W", "rect": Rect2(-192.68, -41.4, 24, 90), "content": "panel_5", "condition": "kept", "facing": "e"},
	"b1_e": {"type": "W", "rect": Rect2(-44.32, -41.4, 24, 90), "content": "panel_5", "condition": "kept", "facing": "w"},
	"b1_k": {"type": "K", "rect": Rect2(-152, -31.6, 88, 70.4), "content": "yard", "condition": "kept", "facing": "s"},
	"a2_n": {"type": "W", "rect": Rect2(-337.8, 94.92, 90, 24), "content": "panel_9", "condition": "kept", "facing": "s"},
	"a2_s": {"type": "W", "rect": Rect2(-337.8, 225.68, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"a2_w": {"type": "W", "rect": Rect2(-380.48, 125.8, 24, 90), "content": "panel_5", "condition": "kept", "facing": "e"},
	"a2_e": {"type": "W", "rect": Rect2(-232.12, 125.8, 24, 90), "content": "panel_9", "condition": "kept", "facing": "w"},
	"a2_k": {"type": "K", "rect": Rect2(-336.8, 135.6, 88, 70.4), "content": "wasteland", "condition": "abandoned", "facing": "s"},
	"b2_n": {"type": "W", "rect": Rect2(-153, 94.92, 90, 24), "content": "panel_5", "condition": "kept", "facing": "s"},
	"b2_s": {"type": "W", "rect": Rect2(-153, 225.68, 90, 24), "content": "panel_5", "condition": "kept", "facing": "n"},
	"b2_w": {"type": "W", "rect": Rect2(-192.68, 125.8, 24, 90), "content": "panel_9", "condition": "kept", "facing": "e"},
	"b2_k": {"type": "K", "rect": Rect2(-152, 135.6, 88, 70.4), "content": "yard", "condition": "kept", "facing": "s"},
	"b2_e": {"type": "W", "rect": Rect2(-44.32, 190, 24, 66), "content": "panel_5_short", "condition": "kept", "facing": "w"},
	"pub": {"type": "G", "rect": Rect2(-188, 271, 34, 25), "content": "pub_site", "condition": "kept", "facing": "s"},
	"police": {"type": "G", "rect": Rect2(-56, -77, 36, 34), "content": "police", "condition": "kept", "facing": "e"},
	"polyclinic": {"type": "G", "rect": Rect2(-53, 130, 33, 52), "content": "polyclinic", "condition": "kept", "facing": "e"},
	"ispolkom": {"type": "G", "rect": Rect2(25, 22, 115, 108), "content": "ispolkom", "condition": "kept", "facing": "w", "entrance": Vector2(25, 72)},
	"tower_e1": {"type": "G", "rect": Rect2(30, -60, 40, 38), "content": "culture_house", "condition": "kept", "facing": "w"},
	"department_store": {"type": "G", "rect": Rect2(9.5, 0.5, 30, 30), "content": "department_store", "condition": "kept", "facing": "w"},
	"city_park": {"type": "G", "rect": Rect2(86.7, -77.7, 51, 80), "content": "private_restaurant", "condition": "kept", "facing": "e"},
	# Three matching southern towers, evenly spaced between the two streets.
	"tower_e2": {"type": "W", "rect": Rect2(19.5, 140, 34, 38), "content": "elite_tower_placeholder", "condition": "kept", "facing": "w"},
	"tower_e3": {"type": "W", "rect": Rect2(56.5, 140, 34, 38), "content": "elite_tower_placeholder", "condition": "kept", "facing": "w"},
	"tower_e4": {"type": "W", "rect": Rect2(93.5, 140, 34, 38), "content": "elite_tower_placeholder", "condition": "kept", "facing": "w"},
	"slab_1": {"type": "W", "rect": Rect2(22, 190, 110, 14), "content": "admin_slab", "condition": "kept", "facing": "s"},
	"slab_2": {"type": "W", "rect": Rect2(22, 232, 110, 14), "content": "admin_slab", "condition": "kept", "facing": "n"},
	"church": {"type": "X", "rect": Rect2(240.1249, 72.0459, 56.921, 47.4342), "content": "church", "condition": "fading", "facing": "w", "entrance": Vector2(257.2012, 75.1766)},
	"g_south": {"type": "G", "rect": Rect2(-430, 315, 140, 70), "content": "empty_lot", "condition": "worked", "facing": "n"},
	"former_market": {"type": "N", "rect": Rect2(15, 315, 215, 78), "content": "former_market", "condition": "kept", "facing": "n"},
	# The event ID remains market; the assembled 3D hub includes the station and square.
	"market": {"type": "X", "rect": Rect2(-153, 317, 126, 67), "content": "market", "condition": "kept", "facing": "n", "entrance": Vector2(-108, 351)},
	"cemetery": {"type": "N", "rect": Rect2(205.9723, 76.315, 33.2039, 43.6394), "content": "cemetery", "condition": "fading", "facing": "n", "entrance": Vector2(257.2012, 75.1766)},
	"d_01": {"type": "D", "rect": Rect2(176.4092, -41.7961, 22.7684, 26.5631), "content": "house_poor", "condition": "fading", "facing": "n"},
	"d_02": {"type": "D", "rect": Rect2(324.16, -41.7961, 22.7684, 26.5631), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_03": {"type": "D", "rect": Rect2(173.2427, 2.3177, 26.5631, 22.7684), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_04": {"type": "D", "rect": Rect2(173.2427, 26.5861, 26.5631, 22.7684), "content": "house_poor", "condition": "fading", "facing": "e"},
	"d_05": {"type": "D", "rect": Rect2(173.2427, 82.0071, 26.5631, 22.7684), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_06": {"type": "D", "rect": Rect2(173.2427, 106.2755, 26.5631, 22.7684), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_07": {"type": "D", "rect": Rect2(173.2427, 130.5439, 26.5631, 22.7684), "content": "house_poor", "condition": "fading", "facing": "e"},
	"d_08": {"type": "D", "rect": Rect2(175.1401, 154.8123, 24.6658, 20.871), "content": "house_abandoned", "condition": "abandoned", "facing": "e"},
	"d_09": {"type": "D", "rect": Rect2(204.5493, 122.5, 26.5631, 22.7684), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_10": {"type": "D", "rect": Rect2(211.1901, 215.7714, 22.7684, 26.5631), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_11": {"type": "D", "rect": Rect2(287.0847, 122.5, 26.5631, 22.7684), "content": "house_poor", "condition": "fading", "facing": "e"},
	"d_12": {"type": "D", "rect": Rect2(287.0847, 146.7684, 26.5631, 22.7684), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_13": {"type": "D", "rect": Rect2(233, 183.0419, 22.7684, 26.5631), "content": "house_kept", "condition": "kept", "facing": "s"},
	"d_14": {"type": "D", "rect": Rect2(318.3913, 78.6867, 26.5631, 22.7684), "content": "house_abandoned", "condition": "abandoned", "facing": "w"},
	"d_15": {"type": "D", "rect": Rect2(318.3913, 102.9551, 26.5631, 22.7684), "content": "house_poor", "condition": "fading", "facing": "w"},
	"d_16": {"type": "D", "rect": Rect2(318.3913, 127.2235, 24.6658, 20.871), "content": "house_poor", "condition": "fading", "facing": "w"},
	"d_17": {"type": "D", "rect": Rect2(325.0321, 204.8616, 22.7684, 26.5631), "content": "house_kept", "condition": "kept", "facing": "n"},
	# Additional homes use previously empty frontage; the village is compacted10% in area.
	"d_18": {"type": "D", "rect": Rect2(206.921, -41.7961, 23.7171, 21.8197), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_19": {"type": "D", "rect": Rect2(230.6381, -41.7961, 23.7171, 21.8197), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_20": {"type": "D", "rect": Rect2(254.3552, -41.7961, 23.7171, 21.8197), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_21": {"type": "D", "rect": Rect2(278.0722, -41.7961, 23.7171, 21.8197), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_22": {"type": "D", "rect": Rect2(301.7893, -41.7961, 20.871, 25.6144), "content": "house_kept", "condition": "kept", "facing": "n"},
	"d_23": {"type": "D", "rect": Rect2(205.498, -19.0277, 20.871, 20.871), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_24": {"type": "D", "rect": Rect2(205.498, 3.7407, 20.871, 20.871), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_25": {"type": "D", "rect": Rect2(205.498, 26.5091, 20.871, 20.871), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_26": {"type": "D", "rect": Rect2(205.498, 49.2775, 20.871, 18.9737), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_27": {"type": "D", "rect": Rect2(342.1084, -1.9514, 28.4605, 18.9737), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_28": {"type": "D", "rect": Rect2(342.1084, 22.7144, 28.4605, 18.9737), "content": "house_kept", "condition": "kept", "facing": "e"},
	"d_29": {"type": "D", "rect": Rect2(342.1084, 47.3801, 28.4605, 18.9737), "content": "house_kept", "condition": "kept", "facing": "e"},
	"village_shop": {"type":"G", "rect":Rect2(298.4689, 61.1361, 6.6408, 8.0638), "content":"village_kiosk", "condition":"kept", "facing":"s"},
}

# Asphalt roads get a pavement on both sides (SIDEWALK_WIDTH); a road may override it
# with "walk": 0.0. The highway along the river has no pedestrian zone.
const SIDEWALK_WIDTH := 2.5
const CROSSWALK_DEPTH := 3.5

const ROADS := [
	# Extra village exit to the two-lane south street parallel to the passenger railway.
	# One-way farm lane along the east end of the western wheat field, from the north street up to the
	# highway. Scenery only: no zebra, no sidewalks, rare scripted traffic (rare_traffic.gd).
	{"id": "field_lane", "rect": Rect2(-505, -177.5, 5, 87.5), "kind": "dirt", "ambient_only": true, "one_way": "north"},
	{"id":"village_south_exit", "rect":Rect2(275.5,211.9767,5,93.0233), "kind":"dirt"},
	# "speed" scales car speed (default 1.0); courtyard traffic is opt-in and passenger-only.
	{"id": "west_street", "rect": Rect2(-485, -85, 10, 390), "kind": "asphalt"},
	{"id": "highway", "rect": Rect2(-450, -197.5, 890, 20), "kind": "asphalt", "walk": 0.0, "look": "highway", "speed": 2.0, "lanes_per_direction": 2},
	{"id": "north_street", "rect": Rect2(-500, -90, 940, 10), "kind": "asphalt"},
	{"id": "south_street", "rect": Rect2(-500, 300, 940, 10), "kind": "asphalt"},
	{"id": "axis", "rect": Rect2(-17, -330, 24, 885), "kind": "asphalt", "median": 4.0, "lanes_per_direction": 2},
	{"id": "village_street", "rect": Rect2(140, -80, 10, 380), "kind": "asphalt"},
	# Two residential streets: 10 m asphalt, one lane each way, 2.5 m sidewalks.
	# Flanking slabs move 3 m away from the unchanged street axes.
	{"id": "housing_cross_path", "rect": Rect2(-480, 82.2, 463, 10), "kind": "asphalt", "speed": 0.75},
	{"id": "housing_spine", "rect": Rect2(-205.4, -80, 10, 380), "kind": "asphalt", "speed": 0.75},
	# Quiet infill access, connected to the street grid. Ambient through traffic
	# remains on the original routes; these lanes serve entrances and short bays.
	{"id": "west_infill_north", "rect": Rect2(-434, -80, 4, 110), "kind": "yard", "ambient_only": true},
	{"id": "west_infill_south", "rect": Rect2(-434, 87.2, 4, 212.8), "kind": "yard", "ambient_only": true},
	{"id": "west_infill_entry_n", "rect": Rect2(-475, 26, 45, 4), "kind": "yard", "ambient_only": true},
	{"id": "west_infill_entry_s", "rect": Rect2(-475, 192, 45, 4), "kind": "yard", "ambient_only": true},
	{"id": "dormitory_infill_walk", "rect": Rect2(-433, 28, 2, 59.2), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "dormitory_housing_walk", "rect": Rect2(-432, 47.5, 231.6, 2), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "south_infill_access", "rect": Rect2(-393, 262, 376, 4), "kind": "yard", "ambient_only": true},
	{"id": "south_walk_w", "rect": Rect2(-393, 264, 2, 36), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "south_walk_middle_w", "rect": Rect2(-299, 264, 2, 36), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "south_walk_middle_e", "rect": Rect2(-191, 264, 2, 36), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "south_walk_e", "rect": Rect2(-41, 264, 2, 36), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w1_w_door0", "rect": Rect2(-450.5, 4.2, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w1_w_door1", "rect": Rect2(-450.5, -19.8, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w1_w_door2", "rect": Rect2(-450.5, -43.8, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w1_e_door0", "rect": Rect2(-432, -52.8, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w1_e_door1", "rect": Rect2(-432, -28.8, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w1_e_door2", "rect": Rect2(-432, -4.8, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w2_w_door0", "rect": Rect2(-450, 170.2, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w2_w_door1", "rect": Rect2(-450, 146.2, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w2_w_door2", "rect": Rect2(-450, 122.2, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w2_e_door0", "rect": Rect2(-432, 113.2, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w2_e_door1", "rect": Rect2(-432, 137.2, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w2_e_door2", "rect": Rect2(-432, 161.2, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w3_w_door0", "rect": Rect2(-450.5, 274.2, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w3_w_door1", "rect": Rect2(-450.5, 250.2, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w3_w_door2", "rect": Rect2(-450.5, 226.2, 18.5, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w3_e_door0", "rect": Rect2(-432, 217.2, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w3_e_door1", "rect": Rect2(-432, 241.2, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_w3_e_door2", "rect": Rect2(-432, 265.2, 18, 1.6), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s1_door0", "rect": Rect2(-315.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s1_door1", "rect": Rect2(-339.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s1_door2", "rect": Rect2(-363.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s2_door0", "rect": Rect2(-223.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s2_door1", "rect": Rect2(-247.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s2_door2", "rect": Rect2(-271.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s3_door0", "rect": Rect2(-75.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s3_door1", "rect": Rect2(-99.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	{"id": "infill_s3_door2", "rect": Rect2(-123.8, 264, 1.6, 12.5), "kind": "yard", "ambient_only": true, "surface": "paving"},
	# Civic square / southern tower connection, and the lane between the two slabs.
	{"id": "square_link", "rect": Rect2(7, 136, 133, 4), "kind": "yard"},
	# Separate paths around the civic building; no path crosses its footprint.
	{"id": "civic_front_walk", "rect": Rect2(7, 70.5, 34.25, 3), "kind": "yard"},
	{"id": "civic_north_walk", "rect": Rect2(7, 41.5, 138, 3), "kind": "yard"},
	{"id": "civic_south_walk", "rect": Rect2(7, 102.5, 138, 3), "kind": "yard"},
	{"id": "civic_memorial_walk", "rect": Rect2(35, 82, 3, 22), "kind": "yard"},
	{"id": "civic_park_spine", "rect": Rect2(120.5, 43, 3, 95), "kind": "yard"},
	{"id": "civic_park_west", "rect": Rect2(95.5, 84, 3, 35), "kind": "yard"},
	{"id": "civic_park_north", "rect": Rect2(97, 82.5, 25, 3), "kind": "yard"},
	{"id": "civic_park_south", "rect": Rect2(97, 117.5, 25, 3), "kind": "yard"},
	{"id": "civic_lane", "rect": Rect2(7, 209, 133, 5), "kind": "asphalt", "walk": 1.5},
	# Public walks join DK, both sides of the store, and the administration garden.
	{"id": "store_north_walk", "rect": Rect2(7, -1.5, 40, 3), "kind": "yard"},
	{"id": "store_south_walk", "rect": Rect2(7, 31, 40, 3), "kind": "yard"},
	{"id": "civic_public_spine", "rect": Rect2(44, -23, 3, 67.5), "kind": "yard"},
	{"id": "culture_garden_walk", "rect": Rect2(28, -23, 54, 3), "kind": "yard"},
	{"id": "civic_garden_crosswalk", "rect": Rect2(45.5, 9.5, 99.5, 3), "kind": "yard"},
	{"id": "civic_east_garden_walk", "rect": Rect2(79, -23, 3, 35.5), "kind": "yard"},
	{"id": "culture_walk", "rect": Rect2(7, -43, 29, 4), "kind": "yard"},
	# Actual graph connections for the shared forecourt. Its custom surface provides
	# broad paved turning space; road strips retain routes/lanes without duplicate paint.
	{"id": "station_entry", "rect": Rect2(-134, 305, 8, 43), "kind": "asphalt", "walk": 0.0, "hub_surface": true, "speed": 0.4},
	{"id": "station_exit", "rect": Rect2(-50, 305, 8, 43), "kind": "asphalt", "walk": 0.0, "hub_surface": true, "speed": 0.4},
	{"id": "station_link", "rect": Rect2(-130, 344, 84, 8), "kind": "asphalt", "walk": 0.0, "hub_surface": true, "speed": 0.4},
	# Village dirt roads form closed loops: H1 north, V1 west, H2 around the church,
	# V2 east, H4 south, plus an east lane joining the ends of H1 and H3.
	{"id": "village_north", "rect": Rect2(150.0, -46.6678, 225.3123, 5.0), "kind": "dirt"},
	{"id": "village_west", "rect": Rect2(199.6776, -44.1678, 5.0, 260.8879), "kind": "dirt"},
	# West lane: the village's only link to the village street besides the north end.
	{"id": "village_west_link", "rect": Rect2(150.0, 69.5459, 52.1776, 5.0), "kind": "dirt"},
	{"id": "village_church", "rect": Rect2(202.1775, 69.5459, 116.2137, 5.0), "kind": "dirt"},
	{"id": "village_east", "rect": Rect2(313.5196, 72.046, 5.0, 142.3025), "kind": "dirt"},
	{"id": "village_east_link", "rect": Rect2(316.0196, 199.9899, 66.4078, 5.0), "kind": "dirt"},
	{"id": "village_south", "rect": Rect2(202.1775, 209.4767, 116.2137, 5.0), "kind": "dirt"},
	{"id": "village_outer_lane", "rect": Rect2(370.4406, -44.1678, 5.0, 249.0294), "kind": "dirt"},
]

# The passenger tracks turn north into the eastern freight corridor.
const RAILS := [
	[Vector2(-450, 395), Vector2(410, 395), Vector2(410, -495)],
	[Vector2(-450, 405), Vector2(420, 405), Vector2(420, -495)],
	# The port siding leaves the elevated main line at deck height and climbs down on its own ramp.
	# Keep the terminal inside the compact port, beyond the expanded checkpoint.
	[Vector2(410, -250), Vector2(402, -245), Vector2(190, -245)],
	# Storage track: a points switch inside the port fence splits it from the siding; stock stands on both.
	[Vector2(286, -245), Vector2(264, -237.5), Vector2(197, -237.5)],
]
# A wide river: barges pass under both bridges, whose decks rise to a hump over the water.
# The eastern freight line runs on an embankment past the village: it climbs over
# `ramp` metres at both ends and the three E-W roads pass under it in short tunnels
# centred on `tunnels` (z), each `gap` metres long along the track.
const EMBANKMENT_CROSSINGS := [
	{"id": "highway_rail_overpass", "z": -187.5, "gap": 28.0},
	{"id": "north_street_rail_overpass", "z": -85.0, "gap": 13.0},
	{"id": "south_street_rail_overpass", "z": 305.0, "gap": 13.0},
]
const EMBANKMENT := {
	"cx": 415.0, "tracks": [410.0, 420.0], "top": 10.0, "height": 6.0,
	# Starts at the rail bridge's south end at deck height (ramp_from 0), then descends to the south.
	"from": -280.0, "to": 375.0, "ramp": 90.0, "ramp_from": 0.0,
	"tunnels": [EMBANKMENT_CROSSINGS[0]["z"], EMBANKMENT_CROSSINGS[1]["z"], EMBANKMENT_CROSSINGS[2]["z"]], "gap": 13.0,
	# The highway tunnel is wider than the 13 m default: the road is 20 m wide.
	"gaps": {EMBANKMENT_CROSSINGS[0]["z"]: EMBANKMENT_CROSSINGS[0]["gap"]},
}
const SIDING_RAMP := {"z": -245.0, "x_from": 315.0, "x_to": 402.0, "height": 6.0, "top": 3.5}
# Each ambient train keeps its own through track in both travel directions.
const COMMUTER_TRAIN := {"track_index": 0}
const FREIGHT_TRAIN := {"track_index": 1}
# Low-detail planning geometry: a continuous passenger platform west/east of
# the avenue, including the clear span underneath it. Near track centre is z=395.
const STATION_PLATFORM := {"rect": Rect2(-139, 384, 100, 8.75), "height": 1.27}
const WATER := Rect2(-450, -440, 900, 110)
const FOREIGN_BANK := Rect2(-450, -500, 900, 60)
const BRIDGES := [
	# The avenue continues south over both through tracks. The 75 m approaches
	# start beyond the south-street junction; the 30 m clear span covers both tracks.
	{"id": "rail_overpass", "rect": Rect2(-19.5, 315, 29, 180), "height": 7.5, "ramp": 75.0, "kind": "road", "parking": false, "rail_overpass": true},
	# The road bridge ends at the water's edge on the town side; its deck climbs to
	# `height` over `ramp` metres at both ends, so cars and people ride on it.
	# Same x range as the civic axis (-17..7), so the boulevard carries straight onto the bridge.
	{"id": "border_road_bridge", "entrance_id": "bridge_road", "rect": Rect2(-17, -445, 24, 115), "height": 6.0, "ramp": 40.0, "kind": "road", "parking": false},
	# The railway climbs an embankment on land, 50 m each side of the river.
	{"id": "river_rail_bridge", "rect": Rect2(405, -495, 20, 215), "height": 6.0, "ramp": 50.0, "kind": "rail", "parking": false, "flat_end": true},
	# Three separately addressable spans in the eastern embankment. The same
	# crossing data determines the earth gaps and these bridge footprints.
	{"id": EMBANKMENT_CROSSINGS[0]["id"], "rect": Rect2(404.5, EMBANKMENT_CROSSINGS[0]["z"] - EMBANKMENT_CROSSINGS[0]["gap"] / 2.0, 21, EMBANKMENT_CROSSINGS[0]["gap"]), "height": 6.0, "ramp": 0.0, "kind": "rail", "parking": false, "embankment_span": true},
	{"id": EMBANKMENT_CROSSINGS[1]["id"], "rect": Rect2(404.5, EMBANKMENT_CROSSINGS[1]["z"] - EMBANKMENT_CROSSINGS[1]["gap"] / 2.0, 21, EMBANKMENT_CROSSINGS[1]["gap"]), "height": 6.0, "ramp": 0.0, "kind": "rail", "parking": false, "embankment_span": true},
	{"id": EMBANKMENT_CROSSINGS[2]["id"], "rect": Rect2(404.5, EMBANKMENT_CROSSINGS[2]["z"] - EMBANKMENT_CROSSINGS[2]["gap"] / 2.0, 21, EMBANKMENT_CROSSINGS[2]["gap"]), "height": 6.0, "ramp": 0.0, "kind": "rail", "parking": false, "embankment_span": true},
]
const AREAS := {
	"village": {"rect": Rect2(154.7434, -75.0, 227.684, 351.0128), "ground": "grass_dry", "condition": "fading"},
}


# Stable bridge IDs are future gameplay hooks. Rects include the entire ramps.
static func bridge_by_id(id: String) -> Dictionary:
	for bridge in BRIDGES:
		if bridge["id"] == id:
			return bridge
	return {}


static func parking_allowed(at: Vector2, footprint: Vector2) -> bool:
	var vehicle := Rect2(at - footprint / 2.0, footprint)
	for bridge in BRIDGES:
		if not bridge.get("parking", false) and vehicle.intersects(bridge["rect"].grow(.5)):
			return false
	return true


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
		# The relocated store reaches the avenue sidewalk, west of the main district rect.
		"rects": [Rect2(19.5, -80, 125.5, 350), LOTS["department_store"]["rect"], Rect2(-56, -77, 36, 34), Rect2(-53, 130, 33, 52)],
		"residents": 1200, "foot": 1.4, "cars": 0.8,
		"fleet": {"car": 0.8, "bus": 0.2}, "hours": "office",
		"subzones": {
			"admin_police": {"rect": Rect2(-56, -77, 36, 34), "cars": 0.6},
			"admin_polyclinic": {"rect": Rect2(-53, 130, 33, 52), "foot": 1.8, "hours": "commute"},
			"admin_square": {"rect": Rect2(25, 22, 115, 108), "foot": 2.0, "cars": 0.3},
			"admin_restaurant": {"rect": LOTS["city_park"]["rect"], "residents": 0, "foot": 0.0, "cars": 0.0, "hours": "leisure"},
			"admin_shops": {"rect": LOTS["department_store"]["rect"], "foot": 2.2, "hours": "market"},
			"admin_culture": {"rect": LOTS["tower_e1"]["rect"], "residents": 0, "foot": 0.8, "cars": 0.4, "fleet": {"car": 1.0}, "hours": "leisure"},
			"admin_elite_e2": {"rect": LOTS["tower_e2"]["rect"], "foot": 0.5, "cars": 1.2, "fleet": {"car": 1.0}},
			"admin_elite_e3": {"rect": LOTS["tower_e3"]["rect"], "foot": 0.5, "cars": 1.2, "fleet": {"car": 1.0}},
			"admin_elite_e4": {"rect": LOTS["tower_e4"]["rect"], "foot": 0.5, "cars": 1.2, "fleet": {"car": 1.0}},
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
			"border_crossing": {"rect": Rect2(-170, -320, 330, 120), "foot": 0.7, "cars": 2.2, "fleet": {"truck": 0.8, "car": 0.2}},
			"truck_stop": {"rect": Rect2(-280, -282, 100, 82), "foot": 0.5, "fleet": {"truck": 0.85, "car": 0.15}},
			"atp_depot": {"rect": Rect2(-420, -282, 120, 82), "foot": 0.4, "fleet": {"truck": 0.5, "bus": 0.4, "car": 0.1}, "hours": "office"},
			"river_port": {"rect": Rect2(170, -320, 120, 120), "foot": 0.4, "fleet": {"truck": 0.9, "car": 0.1}},
			"fuel_depot": {"rect": Rect2(300, -282, 95, 82), "foot": 0.1, "cars": 0.6, "fleet": {"truck": 1.0}},
		},
	},
	"service": {
		"name": "Service belt",
		"rects": [Rect2(-440, -174.5, 875, 82.5)],
		"residents": 20, "foot": 0.2, "cars": 0.5,
		"fleet": {"car": 0.5, "truck": 0.3, "tractor": 0.2}, "hours": "office",
		"subzones": {
			"boiler_house": {"rect": Rect2(-420, -157, 80, 62), "foot": 0.3, "fleet": {"truck": 0.6, "car": 0.4}},
			"garage_coop": {"rect": Rect2(-309, -137, 126, 42), "foot": 0.5, "cars": 0.8, "fleet": {"car": 1.0}, "hours": "commute"},
			"wheat_field": {"rect": LOTS["reserve"]["rect"], "foot": 0.05, "cars": 0.1, "fleet": {"tractor": 0.7, "car": 0.3}},
		},
	},
	"panel_housing": {
		"name": "Panel housing",
		"rects": [Rect2(-472.5, -78, 452.5, 376)],
		"residents": 6000, "foot": 1.0, "cars": 0.4,
		"fleet": {"car": 0.85, "bus": 0.15}, "hours": "commute",
		"subzones": {
			"superblock_a1": {"rect": Rect2(-380, -75, 175, 157)},
			"superblock_b1": {"rect": Rect2(-196, -75, 176, 157)},
			"superblock_a2": {"rect": Rect2(-380, 92, 175, 158), "residents": 900},
			"superblock_b2": {"rect": Rect2(-196, 92, 176, 158)},
			"west_infill_north": {"rect": Rect2(-472.5, -78, 76.5, 108), "residents": 500, "foot": 0.8, "cars": 0.2},
			"west_infill_south": {"rect": Rect2(-472.5, 92, 76.5, 203), "residents": 1000, "foot": 0.9, "cars": 0.2},
			"south_infill": {"rect": Rect2(-393, 255, 373, 43), "residents": 500, "foot": 0.8, "cars": 0.3},
		},
	},
	"village": {
		"name": "Old village",
		"rects": [Rect2(150.0, -79.7434, 232.4274, 355.7562)],
		"residents": 300, "foot": 0.5, "cars": 0.2,
		"fleet": {"car": 0.55, "tractor": 0.4, "truck": 0.05}, "hours": "farm",
		"subzones": {
			"church_cemetery": {"rect": Rect2(205.9723, 72.0459, 91.0736, 47.4342), "residents": 5, "foot": 0.6, "hours": "leisure"},
			"pond": {"rect": Rect2(227.792, -19.0277, 113.842, 87.2789), "residents": 0, "foot": 0.3, "cars": 0.0, "hours": "leisure"},
		},
	},
	"south_hub": {
		"name": "South hub",
		"rects": [Rect2(-430, 312, 660, 81)],
		"residents": 50, "foot": 1.5, "cars": 1.0,
		"fleet": {"car": 0.5, "bus": 0.4, "truck": 0.1}, "hours": "market",
		"subzones": {
			"former_market": {"rect": LOTS["former_market"]["rect"], "foot": 0.2, "cars": 0.0},
			"market": {"rect": Rect2(-153, 352, 62, 32), "foot": 2.5, "cars": 0.7, "fleet": {"car": 0.6, "truck": 0.4}},
			"station": {"rect": Rect2(-90, 354, 63, 39), "foot": 1.6, "cars": 1.2, "fleet": {"bus": 0.6, "car": 0.4}, "hours": "commute"},
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

# A second pedestrian pool supplements these districts only during the workday.
const WORKDAY_FOOT_HOURS := Vector2i(8, 18)
const WORKDAY_FOOT_DISTRICTS := ["admin", "panel_housing"]
const WORKDAY_FOOT_AXIS := Rect2(-20, -80, 40, 350) # District-free avenue pavements/crossings.


static func workday_pedestrians_at(point: Vector2, hour: int) -> bool:
	var h := posmod(hour, 24)
	if h < WORKDAY_FOOT_HOURS.x or h >= WORKDAY_FOOT_HOURS.y:
		return false
	return district_at(point) in WORKDAY_FOOT_DISTRICTS or WORKDAY_FOOT_AXIS.has_point(point)


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
# Junction zebras dropped on purpose: the avenue and the village street had one at every yard walk,
# which read as a zebra every 30 m. Real street junctions and the key doors (store, culture house,
# square, cross path mouth) keep theirs.
const SKIPPED_CROSSWALKS := [
	"axis__civic_north_walk__center", "axis__civic_south_walk__center", "axis__store_south_walk__center",
	"axis__south_infill_access__center", "axis__housing_cross_path__before",
	"village_street__civic_garden_crosswalk__center", "village_street__civic_north_walk__center",
	"village_street__civic_south_walk__center", "village_street__square_link__center",
]


static func crosswalks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for road in ROADS:
		# Forecourt routes use one deliberately placed crossing in StationHub.
		# Junction-derived zebras on both arms otherwise overlap at its tight turns.
		if road["kind"] != "asphalt" or road.get("hub_surface", false):
			continue
		var rect: Rect2 = road["rect"]
		var horizontal := rect.size.x > rect.size.y
		var half := (rect.size.y if horizontal else rect.size.x) / 2.0
		for other in ROADS:
			if other.get("hub_surface", false):
				continue
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
				if "%s__%s__%s" % [road["id"], other["id"], side] in SKIPPED_CROSSWALKS:
					continue
				result.append({"id": "%s__%s__%s" % [road["id"], other["id"], side],
					"road_id": road["id"], "joining_road_id": other["id"],
					"at": at, "width": half * 2.0, "along_z": not horizontal, "a": at - across, "b": at + across})
	return result


# A tunnel deck stays level at full clearance; its landward approach starts after it.
# Shared by the earth/track mesh and moving-car height samples.
static func embankment_south_ramp_start() -> float:
	var start := float(EMBANKMENT["to"]) - float(EMBANKMENT["ramp"])
	var gaps: Dictionary = EMBANKMENT.get("gaps", {})
	for tunnel in EMBANKMENT["tunnels"]:
		var half: float = float(gaps.get(tunnel, EMBANKMENT["gap"])) / 2.0
		if float(tunnel) - half < float(EMBANKMENT["to"]):
			start = maxf(start, float(tunnel) + half)
	return start


static func embankment_height(z: float) -> float:
	var from_ramp: float = EMBANKMENT.get("ramp_from", EMBANKMENT["ramp"])
	var up := (z - float(EMBANKMENT["from"])) / from_ramp if from_ramp > 0.0 else INF
	var down := (float(EMBANKMENT["to"]) - z) / (float(EMBANKMENT["to"]) - embankment_south_ramp_start())
	return float(EMBANKMENT["height"]) * clampf(minf(up, down), 0.0, 1.0)


static func road_by_id(id: String) -> Dictionary:
	for road in ROADS:
		if road["id"] == id:
			return road
	push_error("DistrictLayout: unknown road '%s'" % id)
	return {}
