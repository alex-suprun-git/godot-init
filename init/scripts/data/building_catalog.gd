# Lot contents, independent of district coordinates. Offsets are lot-local metres.
# Missing texture paths deliberately keep dimensioned placeholder geometry.
extends RefCounted

const CONDITIONS := {
	"kept": {"tint": Color.WHITE, "dry_ground": false, "garbage": false},
	"worked": {"tint": Color(0.96, 0.95, 0.92), "dry_ground": false, "garbage": false},
	"fading": {"tint": Color(0.94, 0.91, 0.85), "dry_ground": true, "garbage": true},
	"abandoned": {"tint": Color(0.82, 0.80, 0.73), "dry_ground": true, "garbage": true},
}

# What fills a village plot around its house, by lot condition. `fence` is the share of
# fence pieces still standing, `beds` the vegetable beds, `orchard` the fruit trees and
# `shed` an outbuilding at the back. `fence_color` is the weathered paling colour.
const VILLAGE_FILL := {
	"kept": {"fence": 1.0, "beds": 3, "orchard": 5, "shed": true, "fence_color": Color("a08f68")},
	"fading": {"fence": 0.85, "beds": 1, "orchard": 3, "shed": false, "fence_color": Color("7c6c50")},
	"abandoned": {"fence": 0.5, "beds": 0, "orchard": 0, "shed": false, "fence_color": Color("5f5547")},
}

const CONTENTS := {
	"housing_reserve": {"kind": "open", "ground": "grass", "label": "Резерв жилой застройки", "dressing": []},
	"forest_clearing": {"kind": "open", "ground": "grass_dry", "label": "Лесная поляна", "dressing": []},
	"cemetery": {"kind": "open", "ground": "grass_dry", "label": "Старое кладбище", "dressing": []},
	"pond_bank": {"kind": "open", "ground": "grass", "label": "Пруд у посёлка", "dressing": []},
	"panel_5": {
		"kind": "panel", "footprint": Vector2(84, 11), "floors": 5,
		"facade": "res://assets/textures/facade_panel_late_5storey_lived.png",
		"roof": "res://assets/textures/roof_panel_flat.png",
		"entrance_base": "res://assets/textures/facade_panel_entrance.png",
		"stair": "res://assets/textures/facade_panel_stair.png",
		"ground_floor": "res://assets/textures/facade_panel_groundfloor_shop.png",
		"placeholder_color": Color("ccc9bd"), "label": "Пятиэтажный дом", "dressing": [],
	},
	# Interim intact dormitory using existing residential materials; dedicated art is pending.
	"dormitory_placeholder": {
		"kind": "panel", "footprint": Vector2(60, 14), "floors": 3, "doorstep": 2.0,
		"facade": "res://assets/textures/facade_panel_late_5storey_lived.png",
		"roof": "res://assets/textures/roof_panel_flat.png",
		"entrance_base": "res://assets/textures/facade_panel_entrance.png",
		"stair": "res://assets/textures/facade_panel_stair.png",
		"placeholder_color": Color("ccc9bd"), "label": "Общежитие", "dressing": [],
	},
	"panel_9": {
		"kind": "panel", "footprint": Vector2(78, 12), "floors": 9, "doorstep": 3.0,
		"facade": "res://assets/textures/facade_panel_late_9storey_lived.png",
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
	"wheat_field": {"kind": "wheat_field", "ground": "grass", "label": "Пшеничное поле", "dressing": []},
	"empty_lot": {"kind": "open", "footprint": Vector2.ZERO, "ground": "grass", "label": "Свободный участок", "dressing": []},
	"ispolkom": {
		"kind": "civic_center", "footprint": Vector2.ZERO, "height": 18.0,
		"ground": "grass", "label": "Райисполком", "dressing": [],
	},
	"police": {
		"kind": "building", "footprint": Vector2(18, 10), "height": 6.0, "doorstep": 2.0,
		"civic_facade": true, "center_width": 12.0,
		"facade_center": "res://assets/textures/facade_police_new_center.png",
		"facade_wing": "res://assets/textures/facade_police_new_wing.png",
		"roof": "res://assets/textures/roof_tar.png", "placeholder_color": Color("aab5b5"),
		"ground": "paving", "label": "Райотдел милиции", "dressing": [
		],
	},
	"polyclinic": {
		"kind": "building", "footprint": Vector2(24, 14), "height": 9.0, "doorstep": 2.0,
		"civic_facade": true, "center_width": 18.0,
		"facade_center": "res://assets/textures/facade_polyclinic_new_center.png",
		"facade_wing": "res://assets/textures/facade_polyclinic_new_wing.png",
		"roof": "res://assets/textures/roof_tar.png", "placeholder_color": Color("cbd6d0"),
		"ground": "paving", "label": "Поликлиника", "dressing": [
		],
	},
	"elite_tower_placeholder": {
		"kind": "building", "footprint": Vector2(24, 20), "floors": 14, "height": 42.0, "doorstep": 3.0,
		"tower_variant": "e1", "door_offset": -9.0, "roof": "res://assets/textures/facade_tower_roof_e1.png",
		"placeholder_color": Color("cbb38b"), "label": "Высотный жилой дом", "dressing": [],
	},
	"admin_slab": {
		"kind": "panel", "footprint": Vector2(108, 11), "floors": 5, "doorstep": 2.0,
		"facade": "res://assets/textures/facade_panel_late_5storey_lived.png",
		"roof": "res://assets/textures/roof_panel_flat.png",
		"entrance_base": "res://assets/textures/facade_panel_entrance.png",
		"stair": "res://assets/textures/facade_panel_stair.png",
		"placeholder_color": Color("ccc9bd"), "label": "Пятиэтажный дом", "dressing": [],
	},
	"department_store": {
		"kind": "building", "footprint": Vector2(24, 30), "height": 6.0, "doorstep": 2.0,
		"civic_facade": true, "center_width": 12.0,
		"facade_center": "res://assets/textures/facade_department_store_center.png",
		"facade_wing": "res://assets/textures/facade_department_store_wing.png",
		"roof": "res://assets/textures/roof_tar.png", "ground": "paving",
		"placeholder_color": Color("d4c5ae"), "label": "Универмаг", "dressing": [],
	},
	"city_park": {
		# Reserved for the park replacement on its separate branch.
		"kind": "open", "ground": "grass", "label": "Городской сквер", "dressing": [],
	},
	"boiler_house": {
		"kind": "building", "footprint": Vector2(28, 20), "height": 9.0, "doorstep": 3.0,
		"facade": "res://assets/textures/facade_boiler_brick.png", "roof": "res://assets/textures/roof_tar.png",
		"placeholder_color": Color("8c4530"), "ground": "asphalt", "label": "Котельная №3", "dressing": [
			{"sprite": "boiler_chimney", "at": Vector2(23, -15), "width": 22.7, "footprint": Vector2(7, 7)},
			{"sprite": "coal_heap", "at": Vector2(-27, 19), "width": 14.0, "footprint": Vector2(14, 9)},
		],
	},
	"garages": {"kind": "garages", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "Гаражный кооператив", "dressing": []},
	"church": {"kind": "sprite", "sprite": "church", "width": 32.0, "footprint": Vector2(24, 30), "doorstep": 3.0, "ground": "grass_dry", "label": "Церковь", "dressing": []},
	"fuel_depot": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "Склад топлива", "parts": [
		{"at": Vector2(-10, -20), "footprint": Vector2(28, 12), "height": 6.0, "pitched": 2.0, "roof": "res://assets/textures/roof_rusty_metal.png", "doorstep": 3.0, "facade": "res://assets/textures/facade_warehouse.png", "placeholder_color": Color("a29079")},
	], "dressing": [
		{"sprite": "fuel_tanks", "at": Vector2(0, 22), "width": 34.0, "footprint": Vector2(35, 24)},
		{"sprite": "water_tower", "at": Vector2(30, -35), "width": 12.0, "footprint": Vector2(8, 8)},
	]},
	"atp": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "АТП · автобусный парк", "parts": [
		{"at": Vector2(-20, -24), "footprint": Vector2(64, 24), "height": 8.0, "pitched": 3.2, "roof": "res://assets/textures/roof_rusty_metal.png",  "facade_floors": 8.0 / 3.0, "facade": "res://assets/textures/facade_bus_garage.png", "placeholder_color": Color("988d7a")},
	], "dressing": [
		{"model": "bus_paz", "at": Vector2(-30, 20), "length": 7.075, "footprint": Vector2(3, 7.2), "axis": "z"},
		{"model": "bus_paz", "at": Vector2(-8, 20), "length": 7.075, "footprint": Vector2(3, 7.2), "axis": "z"},
		{"model": "bus_liaz", "at": Vector2(16, 20), "length": 11.55, "footprint": Vector2(3, 11.7), "axis": "z"},
	]},
	"truck_stop": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "Стоянка дальнобойщиков", "parts": [
		{"at": Vector2(30, -30), "footprint": Vector2(32, 12), "height": 4.0, "facade_floors": 4.0 / 3.0, "facade": "res://assets/textures/facade_roadside_cafe.png", "placeholder_color": Color("b79b76")},
	], "dressing": [
		{"model": "kamaz_semi", "at": Vector2(-52, 8), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 0},
		{"model": "kamaz_semi", "at": Vector2(-46, 8), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 1},
		{"model": "kamaz_semi", "at": Vector2(-40, 8), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 2},
		{"model": "kamaz_semi", "at": Vector2(-34, 8), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 3},
		{"model": "kamaz_semi", "at": Vector2(-52, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 1},
		{"model": "kamaz_semi", "at": Vector2(-46, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 2},
		{"model": "kamaz_semi", "at": Vector2(-40, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 3},
		{"model": "zil_flatbed", "at": Vector2(-2, 10), "length": 6.94724266, "footprint": Vector2(3, 8), "axis": "z", "paint": 0},
		{"model": "zil_food", "at": Vector2(4, 10), "length": 7.04408628, "footprint": Vector2(3, 8), "axis": "z", "paint": 1},
	]},
	"checkpoint": {"kind": "group", "footprint": Vector2.ZERO, "ground": "asphalt", "label": "КПП · таможня", "parts": [
		{"at": Vector2(-77, -17), "footprint": Vector2(30, 18), "height": 6.0, "facade_floors": 2.0, "facade": "res://assets/textures/facade_customs_office.png", "placeholder_color": Color("c5c7b5")},
		{"at": Vector2(50, 20), "footprint": Vector2(40, 24), "height": 7.0, "pitched": 2.4, "roof": "res://assets/textures/roof_rusty_metal.png",  "facade_floors": 7.0 / 3.0, "facade": "res://assets/textures/facade_inspection_hangar.png", "placeholder_color": Color("9a9b90")},
		{"at": Vector2(-7, -40), "lane_island": true, "sprite": "checkpoint_booth", "width": 3.2, "footprint": Vector2(3, 3)},
		{"at": Vector2(7, -40), "lane_island": true, "sprite": "checkpoint_booth", "width": 3.2, "footprint": Vector2(3, 3)},
	], "dressing": [
		{"sprite": "border_post", "at": Vector2(-40, -34), "width": 20.0, "footprint": Vector2(20, 15)},
		{"model": "kamaz_semi", "at": Vector2(85, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 0},
		{"model": "kamaz_semi", "at": Vector2(91, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 1},
		{"model": "kamaz_semi", "at": Vector2(97, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 2},
		{"model": "kamaz_semi", "at": Vector2(103, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 3},
		{"model": "kamaz_semi", "at": Vector2(109, -30), "length": 16.71313986, "footprint": Vector2(3, 17), "axis": "z", "paint": 4},
	]},
	"port": {"kind": "group", "footprint": Vector2.ZERO, "ground": "paving", "label": "Речной порт", "parts": [
		{"at": Vector2(0, -23), "footprint": Vector2(65, 22), "height": 8.0, "pitched": 3.2, "roof": "res://assets/textures/roof_rusty_metal.png",  "facade": "res://assets/textures/facade_warehouse.png", "placeholder_color": Color("998c77")},
		{"at": Vector2(12, 40), "footprint": Vector2(40, 12), "height": 6.0, "pitched": 2.2, "roof": "res://assets/textures/roof_rusty_metal.png",  "facade": "res://assets/textures/facade_warehouse.png", "placeholder_color": Color("a49377")},
	], "dressing": [
		{"sprite": "barge", "at": Vector2(0, -83), "width": 42.0, "footprint": Vector2(43, 10), "axis": "x", "water": true, "lift": -3.4},
		{"sprite": "portal_crane", "at": Vector2(-50, 10), "width": 22.0, "footprint": Vector2(10, 10)},
		{"model": "container_20ft", "at": Vector2(44, 4), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 0},
		{"model": "container_20ft", "at": Vector2(47.4, 4), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 1},
		{"model": "container_20ft", "at": Vector2(50.8, 4), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 2},
		{"model": "container_20ft", "at": Vector2(54.2, 4), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 3},
		{"model": "container_20ft", "at": Vector2(44, 14), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 4},
		{"model": "container_20ft", "at": Vector2(47.4, 14), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 5},
		{"model": "container_20ft", "at": Vector2(50.8, 14), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 6},
		{"model": "container_20ft", "at": Vector2(54.2, 14), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 7},
		{"model": "container_20ft", "at": Vector2(44, 24), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 8},
		{"model": "container_20ft", "at": Vector2(47.4, 24), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 9},
		{"model": "container_20ft", "at": Vector2(50.8, 24), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 10},
		{"model": "container_20ft", "at": Vector2(54.2, 24), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 11},
		{"model": "container_20ft", "at": Vector2(44, 4), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 12, "lift": 2.59},
		{"model": "container_20ft", "at": Vector2(47.4, 4), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 13, "lift": 2.59},
		{"model": "container_20ft", "at": Vector2(50.8, 4), "length": 6.06, "footprint": Vector2(2.5, 6.1), "axis": "z", "paint": 14, "lift": 2.59},
	]},
	"former_market": {"kind": "open", "ground": "grass", "label": "Бывший рынок · поле", "dressing": []},
	"market": {
		"kind": "station_hub", "ground": "grass", "label": "Рынок · вокзал · привокзальная площадь",
		"dressing": [],
	},
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
