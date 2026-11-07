# First authored courtyard: B1 / House 5. Coordinates are local to the core.
# Surface, planting and furniture layers keep future seasonal/event edits local.
extends RefCounted

var builder
var map
const Layout = preload("res://scripts/data/district_layout.gd")
const SPACING := Layout.HOUSING_SPACING
var origin := Layout.lot_center("b1_k")
var layers := {}


func build(district_builder) -> void:
	builder = district_builder
	map = builder.map
	var root := Node3D.new()
	root.name = "House5Courtyard"
	map.add_child(root)
	for title in ["Surfaces", "Furniture", "Planting", "Residents"]:
		var layer := Node3D.new()
		layer.name = title
		root.add_child(layer)
		layers[title] = layer
	# A modest service loop, rather than one paved school-sized rectangle.
	_surface(Vector2(0, -49), Vector2(132, 4.5), "asphalt")
	_surface(Vector2(0, 53), Vector2(132, 4.5), "asphalt")
	_surface(Vector2(-64, 2), Vector2(4.5, 106), "asphalt")
	_surface(Vector2(64, 2), Vector2(4.5, 106), "asphalt")
	_surface(Vector2(64, -70), Vector2(4.5, 42), "asphalt")
	_surface(Vector2(64, 73.5), Vector2(4.5, 41), "asphalt")
	for x in [-27.0, 0.0, 27.0]:
		_surface(Vector2(x / SPACING, -59.375), Vector2(1.8, 20.75), "paving")
		# The south slab moves 3 m inward to clear the widened cross street.
		_surface(Vector2(x / SPACING, 61.09 - 1.5 / SPACING), Vector2(1.8, 16.18 - 3.0 / SPACING), "paving")
	for z in [-26.0, 0.0, 26.0]:
		_surface(Vector2(-71.875 + 1.5 / SPACING, z / SPACING), Vector2(15.75 - 3.0 / SPACING, 1.8), "paving")
		_surface(Vector2(71.875, z / SPACING), Vector2(15.75, 1.8), "paving")
	# Small worn play patch and a separate quiet meeting area.
	_surface(Vector2(-20, -12), Vector2(29, 22), "courtyard")
	_surface(Vector2(19, 24), Vector2(23, 12), "courtyard")
	_surface(Vector2(-5, 4), Vector2(2, 92), "dirt")
	_surface(Vector2(19, 9), Vector2(44, 1.5), "dirt")
	_surface(Vector2(41, -21), Vector2(12, 9), "courtyard")
	_prop("bench_playground", Vector2(-20, -12), 11, Vector2(11, 7))
	_prop("carpet_beater_v2", Vector2(41, -21), 4.2, Vector2(5, 2), "x")
	for at in [Vector2(9, 29), Vector2(28, 29), Vector2(-34, 1), Vector2(18, 76)]:
		_bench(at)
		map.wear.add_disc(origin + at * SPACING, 5.0, 0.9)
	# Deliberately few cars, in bays beside the service lane.
	_surface(Vector2(33, -55), Vector2(24, 7), "courtyard")
	var lada_at := origin + Vector2(25, -55) * SPACING
	map._vehicle("lada", map._ground(lada_at) + Vector3.UP * 0.075, 4.3, "x", layers["Furniture"])
	map._occupy(lada_at, Vector2(5, 2.2))
	var volga_at := origin + Vector2(38, -55) * SPACING
	map._vehicle("volga", map._ground(volga_at) + Vector3.UP * 0.075,
		map.VehicleModels.map_length("volga"), "x", layers["Furniture"], map.VehicleModels.PAINT_BLACK)
	map._occupy(volga_at, Vector2(5, 2))
	_surface(Vector2(46, 64), Vector2(10, 7), "courtyard")
	for x in [43.0, 46.0, 49.0]:
		_box(Vector3(1.8, 1.3, 1.6), Vector2(x, 64), 0.65, Color("586759"))
	# Household flower beds close to doors, rather than scattered filler.
	for x in [-42.0, -15.0, 14.0, 39.0]:
		_surface(Vector2(x, 77), Vector2(12, 3), "dirt")
		for dx in [-4.0, 0.0, 4.0]:
			_prop("bush", Vector2(x + dx, 77), 2.2, Vector2(2, 2))
	for at in [Vector2(-47,-31), Vector2(-43,24), Vector2(-30,38), Vector2(20,-32), Vector2(44,10), Vector2(43,35), Vector2(-48,66), Vector2(49,69), Vector2(-45,-65), Vector2(48,-64)]:
		var tree: Node3D = map._tree(map._ground(origin + at * SPACING))
		tree.reparent(layers["Planting"])
		map._occupy(origin + at * SPACING, Vector2(7, 7))
	for at in [Vector2(-40,-24), Vector2(-39,-18), Vector2(-38,-12), Vector2(10,17), Vector2(16,17), Vector2(23,17), Vector2(38,26), Vector2(40,31), Vector2(-26,33), Vector2(-22,36)]:
		_prop("bush", at, 2.8, Vector2(3, 3), "", "Planting")
	_prop("person_pensioner", Vector2(13, 24), 1.0, Vector2(1, 1), "", "Residents")
	_prop("person_kid", Vector2(-13, -5), 0.7, Vector2(1, 1), "", "Residents")
	_prop("person_walk_woman", Vector2(-5, 35), 0.9, Vector2(1, 1), "", "Residents")


func _surface(at: Vector2, size: Vector2, ground: String) -> void:
	var compact_size := size * SPACING
	if minf(size.x, size.y) <= 4.5:
		if size.x < size.y:
			compact_size.x = size.x
		else:
			compact_size.y = size.y
	builder._patch(Rect2(origin + at * SPACING - compact_size / 2, compact_size), ground, 0.075)
	map.get_child(map.get_child_count() - 1).reparent(layers["Surfaces"])
	map._occupy(origin + at * SPACING, compact_size)


func _prop(sprite: String, at: Vector2, width: float, footprint: Vector2, axis := "", layer := "Furniture") -> void:
	if sprite == "bush" and not map._season["bushes"]:
		return
	var texture: Texture2D = builder._texture("res://assets/sprites/%s.png" % sprite)
	var node: Node3D
	if axis == "":
		node = map._sprite(texture, map._ground(origin + at * SPACING), width)
	else:
		node = map._prop(texture, map._ground(origin + at * SPACING), width, axis)
	node.reparent(layers[layer])
	map._occupy(origin + at * SPACING, footprint)


func _box(size: Vector3, at: Vector2, height: float, color: Color) -> void:
	map._box(size, Vector3(origin.x + at.x * SPACING, height, origin.y + at.y * SPACING), color, layers["Furniture"])
	map._occupy(origin + at * SPACING, Vector2(size.x, size.z))


func _bench(at: Vector2) -> void:
	_box(Vector3(3.5, 0.16, 0.65), at, 0.65, Color("82735a"))
	_box(Vector3(3.5, 0.55, 0.12), at + Vector2(0, 0.3 / SPACING), 1.0, Color("82735a"))
	for x in [-1.25, 1.25]:
		_box(Vector3(0.15, 0.6, 0.5), at + Vector2(x / SPACING, 0), 0.3, Color("535c55"))
