# Everyday life in the House 5 courtyard: front gardens under the windows, apple
# trees, a 1990s playground, a domino table, washing lines and a beer stall.
# Positions are metres relative to the lot centre; spots on paths, roads and
# footprints are skipped through the map occupancy grid, so it never blocks doors.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const WOOD := Color("8c7250")
const STEEL := Color("536353")
const RUBBER := Color("2f2d2b")
const PAINT := [Color("c8553d"), Color("e0b23a"), Color("3f7fa8"), Color("5f9a55")]

var map
var origin: Vector2
var root: Node3D


func build(district_builder) -> void:
	map = district_builder.map
	origin = Layout.lot_center("b1_k")
	root = Node3D.new()
	root.name = "House5CourtyardLife"
	map.add_child(root)
	_front_gardens()
	_orchard()
	_playground(Vector2(-20, -12))
	_domino_table(Vector2(19, 24))
	_washing_line(Vector2(-33, 22), Vector2(-33, 34))
	_beer_stall(Vector2(40, 19))
	_green_pockets()


func _w(at: Vector2) -> Vector2:
	return origin + at


func _free(at: Vector2, margin: float) -> bool:
	return not map._is_occupied(_w(at), margin)


func _plant(at: Vector2, kind: String, size: float, margin := 1.2) -> void:
	if not _free(at, margin):
		return
	var plant := Vegetation.create(kind, Vector3(_w(at).x, 0.055, _w(at).y))
	plant.scale *= size
	plant.rotation.y = fposmod(at.x * 0.31 + at.y * 0.17, TAU)
	root.add_child(plant)


func _box(at: Vector2, size: Vector3, height: float, color: Color) -> void:
	map._box(size, Vector3(_w(at).x, height, _w(at).y), color, root)


func _drum(at: Vector2, radius: float, height: float, y: float, color: Color) -> void:
	map._cylinder(radius, height, Vector3(_w(at).x, y, _w(at).y), color, root)


# Hedges of lilac and acacia sit 3 m in front of each facade, broken wherever a door
# path, the service road or another footprint occupies the spot.
func _front_gardens() -> void:
	# Facade fronts from the lot grid; doors are every 27 m on the long sides.
	var lines := [
		["z", -58.4, -43.0, 43.0], ["z", 54.9, -43.0, 43.0],
		["x", -64.2, -43.0, 45.0], ["x", 67.2, -43.0, 45.0],
	]
	for line in lines:
		var at: float = line[2]
		var count := 0
		while at <= float(line[3]):
			var point := Vector2(at, float(line[1])) if line[0] == "z" else Vector2(float(line[1]), at)
			_plant(point, "park_shrub", 0.95 + 0.12 * float(count % 3), 1.4)
			at += 2.3
			count += 1


func _orchard() -> void:
	# Apple trees stand 8 to 12 m off the facades, between the door paths.
	for at in [Vector2(-40, -50), Vector2(-14, -49), Vector2(14, -49), Vector2(40, -50),
			Vector2(-40, 47), Vector2(-14, 47), Vector2(14, 47), Vector2(40, 47),
			Vector2(-58, -20), Vector2(-58, 14), Vector2(58, -38), Vector2(58, 12), Vector2(58, 36)]:
		_plant(at, "park_deciduous_tree", 0.60, 2.2)


# Tyre-edged sand pit, rocking springs, a roundabout and a climbing frame next to
# the existing swing sprite.
func _playground(at: Vector2) -> void:
	for index in 10:
		var angle := TAU * float(index) / 10.0
		_drum(at + Vector2(7.5, 4.0) + Vector2(cos(angle), sin(angle)) * 2.3, 0.42, 0.42, 0.22, PAINT[index % 4])
	_box(at + Vector2(7.5, 4.0), Vector3(3.8, 0.1, 3.8), 0.12, Color("b7a47b"))
	_drum(at + Vector2(-5.5, 6.5), 1.3, 0.14, 0.20, Color("8a8576"))
	_drum(at + Vector2(-5.5, 6.5), 1.05, 0.12, 0.30, PAINT[2])
	_box(at + Vector2(-5.5, 6.5), Vector3(2.0, 0.07, 0.1), 0.42, STEEL)
	_box(at + Vector2(-5.5, 6.5), Vector3(0.1, 0.07, 2.0), 0.42, STEEL)
	# Climbing frame with a hand-over-hand ladder.
	for x in [-1.4, 1.4]:
		_box(at + Vector2(12.0 + x, -4.0), Vector3(0.1, 2.3, 0.1), 1.2, STEEL)
		_box(at + Vector2(12.0 + x, -2.6), Vector3(0.1, 2.3, 0.1), 1.2, STEEL)
	_box(at + Vector2(12.0, -4.0), Vector3(2.9, 0.09, 0.09), 2.3, STEEL)
	_box(at + Vector2(12.0, -2.6), Vector3(2.9, 0.09, 0.09), 2.3, STEEL)
	for rung in 5:
		_box(at + Vector2(10.9 + rung * 0.55, -3.3), Vector3(0.08, 0.08, 1.4), 2.3, PAINT[rung % 4])
	# Spring rocker.
	_box(at + Vector2(-1.5, 8.5), Vector3(1.4, 0.12, 0.5), 0.9, PAINT[0])
	_box(at + Vector2(-1.5, 8.5), Vector3(0.12, 0.7, 0.12), 0.5, STEEL)
	# Half-buried tyres along the edge of the play patch.
	for index in 5:
		_drum(at + Vector2(-9.0 + index * 0.9, 9.4), 0.4, 0.5, 0.25, PAINT[(index + 1) % 4])


func _domino_table(at: Vector2) -> void:
	_box(at, Vector3(2.2, 0.12, 1.2), 0.9, WOOD)
	for x in [-0.9, 0.9]:
		_box(at + Vector2(x, 0.0), Vector3(0.14, 0.9, 0.14), 0.45, STEEL)
	for side in [-1.0, 1.0]:
		_box(at + Vector2(0.0, side * 1.1), Vector3(2.4, 0.1, 0.4), 0.5, WOOD)
	# Pitched roof on four posts keeps off sun and drizzle.
	for x in [-1.5, 1.5]:
		for z in [-1.5, 1.5]:
			_box(at + Vector2(x, z), Vector3(0.12, 2.5, 0.12), 1.25, STEEL)
	_box(at, Vector3(3.8, 0.12, 3.8), 2.55, Color("6e5b45"))
	_box(at, Vector3(3.0, 0.16, 3.0), 2.7, Color("7d6a50"))


func _washing_line(from: Vector2, to: Vector2) -> void:
	for end in [from, to]:
		_box(end + Vector2(-1.5, 0.0), Vector3(0.12, 2.4, 0.12), 1.2, STEEL)
		_box(end + Vector2(1.5, 0.0), Vector3(0.12, 2.4, 0.12), 1.2, STEEL)
	_box((from + to) * 0.5 + Vector2(-1.5, 0.0), Vector3(0.03, 0.03, from.distance_to(to)), 2.35, Color("cfcabb"))
	_box((from + to) * 0.5 + Vector2(1.5, 0.0), Vector3(0.03, 0.03, from.distance_to(to)), 2.35, Color("cfcabb"))
	var colors := [Color("d9d6c8"), Color("a9593f"), Color("4f7ca1"), Color("e0b23a"), Color("d9d6c8")]
	for index in colors.size():
		_box(from.lerp(to, (index + 0.5) / colors.size()) + Vector2(-1.5, 0.0), Vector3(0.05, 0.7, 0.55), 1.95, colors[index])


# "Пиво-Воды": a booth with an awning, two plastic tables under umbrellas and crates.
func _beer_stall(at: Vector2) -> void:
	_box(at, Vector3(3.2, 2.4, 2.4), 1.2, Color("4a7a8c"))
	_box(at + Vector2(0.0, 1.5), Vector3(3.2, 0.1, 1.0), 2.4, Color("c8553d"))
	_box(at + Vector2(0.0, 1.2), Vector3(2.0, 0.9, 0.08), 1.5, Color("1b2b30"))
	_box(at + Vector2(0.0, -1.2), Vector3(2.4, 0.5, 0.06), 2.0, Color("e7e0c8"))
	for x in [-1.0, 0.0, 1.0]:
		_box(at + Vector2(x, 2.4), Vector3(0.45, 0.35, 0.3), 0.18, Color("6d4a2e"))
	for offset in [Vector2(-3.5, 3.5), Vector2(3.5, 3.5)]:
		var spot: Vector2 = at + offset
		_drum(spot, 0.04, 2.4, 1.2, STEEL)
		_drum(spot, 1.25, 0.06, 2.35, PAINT[0])
		_drum(spot, 0.45, 0.07, 0.75, Color("e7e0c8"))
		for dz in [-0.9, 0.9]:
			_box(spot + Vector2(0.0, dz), Vector3(0.35, 0.05, 0.35), 0.45, Color("c8c3b4"))
	_box(at + Vector2(-2.2, -1.0), Vector3(0.4, 0.7, 0.4), 0.35, Color("586759"))


# Loose trees and shrubs that break up the large central lawn.
func _green_pockets() -> void:
	for at in [Vector2(-34, -2), Vector2(-24, 6), Vector2(2, -12), Vector2(10, 33), Vector2(-12, 20), Vector2(31, 34)]:
		_plant(at, "park_shrub", 1.05, 1.6)
		_plant(at + Vector2(2.5, 1.5), "park_shrub", 0.85, 1.4)
	for at in [Vector2(-45, 2), Vector2(26, -2)]:
		_plant(at, "park_poplar", 0.60, 2.4)
