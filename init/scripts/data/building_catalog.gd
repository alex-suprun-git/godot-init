# Lot contents, independent of district coordinates. Offsets are lot-local metres.
# Missing texture paths deliberately keep dimensioned placeholder geometry.
extends RefCounted

const CONDITIONS := {
	"kept": {"tint": Color.WHITE, "dry_ground": false, "garbage": false},
	"worked": {"tint": Color(0.96, 0.95, 0.92), "dry_ground": false, "garbage": false},
	"fading": {"tint": Color(0.94, 0.91, 0.85), "dry_ground": true, "garbage": true},
	"abandoned": {"tint": Color(0.82, 0.80, 0.73), "dry_ground": true, "garbage": true},
}

const CONTENTS := {
	"housing_reserve": {"kind": "open", "ground": "grass", "label": "Резерв жилой застройки", "dressing": []},
	"forest_clearing": {"kind": "open", "ground": "grass_dry", "label": "Лесная поляна", "dressing": []},
	"pond_bank": {"kind": "open", "ground": "grass", "label": "Пруд у посёлка", "dressing": []},
	"panel_5": {
		"kind": "panel", "footprint": Vector2(84, 11), "floors": 5,
		"facade": "res://assets/textures/facade_panel_late_5storey.png",
		"roof": "res://assets/textures/roof_panel_flat.png",
		"entrance_base": "res://assets/textures/facade_panel_entrance.png",
		"stair": "res://assets/textures/facade_panel_stair.png",
		"ground_floor": "res://assets/textures/facade_panel_groundfloor_shop.png",
		"placeholder_color": Color("ccc9bd"), "label": "Пятиэтажный дом", "dressing": [],
	},
	"panel_9": {
		"kind": "panel", "footprint": Vector2(78, 12), "floors": 9,
		"facade": "res://assets/textures/facade_panel_late_9storey.png",
		"roof": "res://assets/textures/roof_panel_flat.png",
		"entrance_base": "res://assets/textures/facade_panel_entrance.png",
		"stair": "res://assets/textures/facade_panel_stair.png",
		"ground_floor": "res://assets/textures/facade_panel_groundfloor_shop.png",
		"placeholder_color": Color("d4d2c7"), "label": "Девятиэтажный дом", "dressing": [],
	},
	"yard": {"kind": "open", "footprint": Vector2.ZERO, "ground": "courtyard", "label": "Двор · резерв школы", "dressing": [
		{"sprite": "bench_playground", "at": Vector2(-18, 6), "width": 11.0, "footprint": Vector2(10, 6)},
		{"sprite": "carpet_beater_v2", "at": Vector2(20, -12), "width": 4.2, "footprint": Vector2(5, 2), "axis": "x"},
	]},
	"wasteland": {"kind": "open", "footprint": Vector2.ZERO, "ground": "grass_dry", "label": "Пустырь · стройрезерв", "dressing": [
		{"sprite": "garbage_pile", "at": Vector2(-20, 12), "width": 7.0, "footprint": Vector2(7, 4)},
		{"sprite": "garbage_pile", "at": Vector2(23, -14), "width": 5.0, "footprint": Vector2(5, 3)},
	]},
	"empty_lot": {"kind": "open", "footprint": Vector2.ZERO, "ground": "grass", "label": "Свободный участок", "dressing": []},
	"ispolkom": {
		"kind": "building", "footprint": Vector2(30, 25), "height": 15.0,
		"center_width": 30.0, "wing_width": 30.0, "wings": 0,
		"facade_center": "res://assets/textures/facade_ispolkom_front.png",
		"facade_wing": "res://assets/textures/facade_ispolkom_side.png",
		"roof": "res://assets/textures/roof_tar.png", "placeholder_color": Color("d5d1c2"),
		"ground": "paving", "label": "Райисполком", "dressing": [
			{"sprite": "monument", "at": Vector2(-40, 0), "width": 7.0, "footprint": Vector2(6, 6)},
			{"sprite": "car_volga_black_v3", "at": Vector2(-32, 25), "width": 5.0, "footprint": Vector2(5, 2), "axis": "z"},
		],
	},
	"police": {
		"kind": "building", "footprint": Vector2(36, 14), "height": 6.0,
		"center_width": 12.0, "wing_width": 12.0, "wings": 1,
		"facade_center": "res://assets/textures/facade_police_front.png",
		"facade_wing": "res://assets/textures/facade_police_side.png",
		"roof": "res://assets/textures/roof_tar.png", "placeholder_color": Color("aab5b5"),
		"ground": "paving", "label": "Райотдел милиции", "dressing": [
			{"sprite": "van_uaz_police", "at": Vector2(-28, 8), "width": 5.2, "footprint": Vector2(5, 2), "axis": "z"},
		],
	},
	"polyclinic": {
		"kind": "building", "footprint": Vector2(30, 18), "height": 15.0,
		"center_width": 30.0, "wing_width": 30.0, "wings": 0,
		"facade_center": "res://assets/textures/facade_polyclinic_entrance.png",
		"facade_wing": "res://assets/textures/facade_polyclinic.png",
		"roof": "res://assets/textures/roof_tar.png", "placeholder_color": Color("cbd6d0"),
		"ground": "paving", "label": "Поликлиника", "dressing": [
			{"model": "lada", "at": Vector2(-30, -16), "length": 4.3, "footprint": Vector2(2.2, 5), "axis": "z"},
			{"model": "lada", "at": Vector2(-30, -5), "length": 4.3, "footprint": Vector2(2.2, 5), "axis": "z"},
		],
	},
	"boiler_house": {
		"kind": "building", "footprint": Vector2(28, 20), "height": 9.0,
		"facade": "res://assets/textures/facade_boiler_brick.png", "roof": "res://assets/textures/roof_tar.png",
		"placeholder_color": Color("8c4530"), "ground": "asphalt", "label": "Котельная №3", "dressing": [
			{"sprite": "boiler_chimney", "at": Vector2(23, -15), "width": 22.7, "footprint": Vector2(7, 7)},
			{"sprite": "coal_heap", "at": Vector2(-27, 19), "width": 14.0, "footprint": Vector2(14, 9)},
		],
	},
	"garages": {"kind": "garages", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "Гаражный кооператив", "dressing": []},
	"church": {"kind": "sprite", "sprite": "church", "width": 32.0, "footprint": Vector2(24, 30), "ground": "grass_dry", "label": "Церковь", "dressing": []},
	"fuel_depot": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "Склад топлива", "parts": [
		{"at": Vector2(-10, -20), "footprint": Vector2(28, 12), "height": 6.0, "facade": "res://assets/textures/facade_warehouse.png", "placeholder_color": Color("a29079")},
	], "dressing": [
		{"sprite": "fuel_tanks", "at": Vector2(0, 22), "width": 34.0, "footprint": Vector2(35, 24)},
		{"sprite": "water_tower", "at": Vector2(30, -35), "width": 12.0, "footprint": Vector2(8, 8)},
	]},
	"atp": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "АТП · автобусный парк", "parts": [
		{"at": Vector2(-20, -24), "footprint": Vector2(64, 24), "height": 8.0, "facade_floors": 8.0 / 3.0, "facade": "res://assets/textures/facade_bus_garage.png", "placeholder_color": Color("988d7a")},
	], "dressing": [
		{"sprite": "bus_local_1997", "at": Vector2(-30, 20), "width": 8.8, "footprint": Vector2(3, 10), "axis": "z"},
		{"sprite": "bus_local_1997", "at": Vector2(-8, 20), "width": 8.8, "footprint": Vector2(3, 10), "axis": "z"},
		{"sprite": "bus_liaz", "at": Vector2(16, 20), "width": 9.0, "footprint": Vector2(10, 3), "axis": "z"},
	]},
	"truck_stop": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "Стоянка дальнобойщиков", "parts": [
		{"at": Vector2(30, -30), "footprint": Vector2(32, 12), "height": 4.0, "facade_floors": 4.0 / 3.0, "facade": "res://assets/textures/facade_roadside_cafe.png", "placeholder_color": Color("b79b76")},
	], "dressing": [
		{"sprite": "truck_kamaz_semi", "at": Vector2(-40, 8), "width": 16.5, "footprint": Vector2(3, 17), "axis": "z"},
		{"sprite": "truck_kamaz_semi", "at": Vector2(-15, 8), "width": 16.5, "footprint": Vector2(3, 17), "axis": "z"},
		{"sprite": "truck_zil_plain", "at": Vector2(10, 8), "width": 8.5, "footprint": Vector2(9, 3), "axis": "z"},
	]},
	"checkpoint": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "КПП · таможня", "parts": [
		{"at": Vector2(-77, -17), "footprint": Vector2(30, 18), "height": 6.0, "facade_floors": 2.0, "facade": "res://assets/textures/facade_customs_office.png", "placeholder_color": Color("c5c7b5")},
		{"at": Vector2(50, 20), "footprint": Vector2(40, 24), "height": 7.0, "facade_floors": 7.0 / 3.0, "facade": "res://assets/textures/facade_inspection_hangar.png", "placeholder_color": Color("9a9b90")},
		{"at": Vector2(-7, -40), "lane_island": true, "sprite": "checkpoint_booth", "width": 3.2, "footprint": Vector2(3, 3)},
		{"at": Vector2(7, -40), "lane_island": true, "sprite": "checkpoint_booth", "width": 3.2, "footprint": Vector2(3, 3)},
	], "dressing": [
		{"sprite": "border_post", "at": Vector2(-40, -34), "width": 20.0, "footprint": Vector2(20, 15)},
		{"sprite": "truck_kamaz_semi", "at": Vector2(85, -30), "width": 16.5, "footprint": Vector2(3, 17), "axis": "z"},
		{"sprite": "truck_kamaz_semi", "at": Vector2(103, -30), "width": 16.5, "footprint": Vector2(3, 17), "axis": "z"},
	]},
	"port": {"kind": "group", "footprint": Vector2.ZERO, "ground": "paving", "label": "Речной порт", "parts": [
		{"at": Vector2(0, -23), "footprint": Vector2(65, 22), "height": 8.0, "facade": "res://assets/textures/facade_warehouse.png", "placeholder_color": Color("998c77")},
		{"at": Vector2(12, 40), "footprint": Vector2(40, 12), "height": 6.0, "facade": "res://assets/textures/facade_warehouse.png", "placeholder_color": Color("a49377")},
	], "dressing": [
		{"sprite": "barge", "at": Vector2(0, -83), "width": 42.0, "footprint": Vector2(43, 10), "axis": "x", "water": true},
		{"sprite": "portal_crane", "at": Vector2(-50, 10), "width": 22.0, "footprint": Vector2(10, 10)},
		{"sprite": "shipping_containers", "at": Vector2(53, 10), "width": 9.0, "footprint": Vector2(8, 6)},
	]},
	"market": {"kind": "market", "footprint": Vector2.ZERO, "ground": "paving", "label": "Рынок челноков", "dressing": []},
	"station": {"kind": "station", "footprint": Vector2(40, 12), "ground": "paving", "label": "Вокзал · автостанция", "sprite": "station_v3", "width": 40.0, "axes": Vector2(0.50, -0.41), "dressing": [
		{"sprite": "bus_local_1997", "at": Vector2(-65, 7), "width": 8.8, "footprint": Vector2(10, 3), "axis": "x"},
	]},
	"house_kept": {"kind": "sprite", "sprite": "village_house_kept", "width": 10.0, "footprint": Vector2(9, 7), "ground": "grass", "label": "Жилой дом с садом", "dressing": [
		{"sprite": "village_well", "at": Vector2(9, 9), "width": 2.0, "footprint": Vector2(2, 2)},
	]},
	"house_poor": {"kind": "sprite", "sprite": "village_house_poor", "width": 9.0, "footprint": Vector2(9, 7), "ground": "grass_dry", "label": "Старый деревенский дом", "dressing": [
		{"sprite": "village_shed", "at": Vector2(10, 10), "width": 5.0, "footprint": Vector2(5, 4)},
	]},
	"house_abandoned": {"kind": "sprite", "sprite": "village_house_abandoned", "width": 9.0, "footprint": Vector2(8, 6), "ground": "grass_dry", "label": "Заброшенный дом", "dressing": []},
}
