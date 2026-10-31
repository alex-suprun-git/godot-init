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
	"b2_e": {"type": "W", "rect": Rect2(-44.32, 125.8, 24, 90), "content": "panel_5", "condition": "kept", "facing": "w"},
	"b2_k": {"type": "K", "rect": Rect2(-152, 135.6, 88, 70.4), "content": "yard", "condition": "kept", "facing": "s"},
	"police": {"type": "G", "rect": Rect2(20, -75, 115, 45), "content": "police", "condition": "kept", "facing": "w"},
	"polyclinic": {"type": "G", "rect": Rect2(20, -20, 115, 60), "content": "polyclinic", "condition": "kept", "facing": "w"},
	"ispolkom": {"type": "G", "rect": Rect2(20, 50, 115, 85), "content": "ispolkom", "condition": "kept", "facing": "w"},
	"g_axis_1": {"type": "G", "rect": Rect2(20, 145, 115, 55), "content": "empty_lot", "condition": "kept", "facing": "w"},
	"g_axis_2": {"type": "G", "rect": Rect2(20, 210, 115, 55), "content": "empty_lot", "condition": "kept", "facing": "w"},
	"church": {"type": "X", "rect": Rect2(245, 80, 60, 50), "content": "church", "condition": "fading", "facing": "w"},
	"g_south": {"type": "G", "rect": Rect2(-430, 315, 200, 70), "content": "empty_lot", "condition": "worked", "facing": "n"},
	"market": {"type": "X", "rect": Rect2(-215, 315, 185, 70), "content": "market", "condition": "worked", "facing": "n"},
	"station": {"type": "X", "rect": Rect2(15, 315, 215, 70), "content": "station", "condition": "worked", "facing": "n"},
	"d_01": {"type": "D", "rect": Rect2(165, -60, 30, 35), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_02": {"type": "D", "rect": Rect2(215, -55, 30, 35), "content": "house_poor", "condition": "fading", "facing": "w"},
	"d_03": {"type": "D", "rect": Rect2(275, -65, 35, 35), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_04": {"type": "D", "rect": Rect2(335, -55, 30, 40), "content": "house_abandoned", "condition": "abandoned", "facing": "w"},
	"d_05": {"type": "D", "rect": Rect2(170, 10, 30, 40), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_06": {"type": "D", "rect": Rect2(345, 5, 35, 40), "content": "house_poor", "condition": "fading", "facing": "w"},
	"d_07": {"type": "D", "rect": Rect2(175, 160, 30, 40), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_08": {"type": "D", "rect": Rect2(230, 175, 30, 35), "content": "house_abandoned", "condition": "abandoned", "facing": "w"},
	"d_09": {"type": "D", "rect": Rect2(330, 150, 35, 40), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_10": {"type": "D", "rect": Rect2(170, 240, 30, 40), "content": "house_poor", "condition": "fading", "facing": "w"},
	"d_11": {"type": "D", "rect": Rect2(290, 235, 35, 40), "content": "house_kept", "condition": "kept", "facing": "w"},
	"d_12": {"type": "D", "rect": Rect2(350, 240, 35, 40), "content": "house_abandoned", "condition": "abandoned", "facing": "w"},
}

const ROADS := [
	{"rect": Rect2(-450, -195, 875, 15), "kind": "asphalt"},
	{"rect": Rect2(-450, -90, 875, 10), "kind": "asphalt"},
	{"rect": Rect2(-450, 300, 875, 10), "kind": "asphalt"},
	{"id": "axis", "rect": Rect2(-20, -330, 30, 642), "kind": "asphalt"},
	{"rect": Rect2(140, -80, 10, 380), "kind": "asphalt"},
	{"rect": Rect2(-398.4, 82.2, 378.4, 10), "kind": "yard"},
	{"rect": Rect2(-205.4, -80, 10, 380), "kind": "yard"},
	{"rect": Rect2(150, -42.5, 57.5, 5), "kind": "dirt"},
	{"rect": Rect2(202.5, -40, 5, 272.5), "kind": "dirt"},
	{"rect": Rect2(205, 77.5, 122.5, 5), "kind": "dirt"},
	{"rect": Rect2(322.5, 80, 5, 142.5), "kind": "dirt"},
	{"rect": Rect2(325, 217.5, 70, 5), "kind": "dirt"},
	{"rect": Rect2(205, 227.5, 75, 5), "kind": "dirt"},
]

# The passenger tracks turn north into the eastern freight corridor.
const RAILS := [
	[Vector2(-450, 395), Vector2(410, 395), Vector2(410, -405)],
	[Vector2(-450, 405), Vector2(420, 405), Vector2(420, -405)],
	[Vector2(410, -230), Vector2(395, -245), Vector2(150, -245)],
]
const WATER := Rect2(-450, -400, 900, 70)
const FOREIGN_BANK := Rect2(-450, -460, 900, 60)
const BRIDGES := [
	{"rect": Rect2(-12, -405, 14, 80), "height": 1.2, "kind": "road"},
	{"rect": Rect2(405, -405, 20, 80), "height": 1.2, "kind": "rail"},
]
const AREAS := {
	"village": {"rect": Rect2(155, -75, 240, 370), "ground": "grass_dry", "condition": "fading"},
}


static func lot_rect(id: String) -> Rect2:
	if not LOTS.has(id):
		push_error("DistrictLayout: unknown lot '%s'" % id)
		return Rect2()
	return LOTS[id]["rect"]


static func lot_center(id: String) -> Vector2:
	return lot_rect(id).get_center()
