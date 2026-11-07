# Shared courts for the western paired slabs and southern street frontage.
# Building positions and all through/entrance paths live in DistrictLayout.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Catalog = preload("res://scripts/data/building_catalog.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Surfaces = preload("res://scripts/map/station_surfaces.gd")
const BENCH = preload("res://assets/models/civic_center/park_bench.glb")
const BIN = preload("res://assets/models/civic_center/park_bin.glb")
const LAMP = preload("res://assets/models/station_hub/lamp.glb")

var builder
var map
var root: Node3D


func build(district_builder) -> void:
	builder = district_builder
	map = builder.map
	root = Node3D.new()
	root.name = "ResidentialInfillCourts"
	map.add_child(root)
	# Each pair shares one small play court, quiet seating and a few service bays.
	# Courts fit between the actual door paths, rather than covering a whole lot.
	for row in [1, 2, 3]:
		var west: Dictionary = Layout.LOTS["west_%d_w" % row]
		var east: Dictionary = Layout.LOTS["west_%d_e" % row]
		var z: float = west["rect"].get_center().y
		var play_z: float = z + [18.0, 15.0, 14.0][row - 1]
		var pad := Rect2(-448, play_z - 6, 12, 12)
		_surface(pad, "courtyard")
		_surface(Rect2(-436, play_z - 0.8, 4, 1.6), "paving")
		var play_at := pad.get_center()
		var texture: Texture2D = builder._texture("res://assets/sprites/bench_playground.png")
		var play: Node3D = map._prop(texture, Vector3(play_at.x, .15, play_at.y), 9.0, "x")
		play.reparent(root)
		var seat_z := z + (9.0 if row == 1 else -12.0)
		_surface(Rect2(-430, seat_z - 2, 13, 4), "paving")
		_model(BENCH, Vector2(-420, seat_z), -PI / 2)
		_model(BIN, Vector2(-418, seat_z + 1.2))
		# Two short parking bays per pair, kept off the four-metre access lane.
		var bay_z: float = z + [-18.0, -18.0, -22.0][row - 1]
		_surface(Rect2(-429.5, bay_z - 3, 12, 6), "asphalt")
		for i in range(2):
			var at := Vector2(-426.5 + i * 5.5, bay_z)
			var model := "lada" if (row + i) % 2 == 0 else "volga"
			map._vehicle(model, Vector3(at.x, .15, at.y), map.VehicleModels.map_length(model), "z", root)
			map._occupy(at, Vector2(2.5, 5))
		_model(LAMP, Vector2(-435, z - 38))
		_model(LAMP, Vector2(-429, z + 35))
		_entrance_gardens(west)
		_entrance_gardens(east)
		for at in [Vector2(-470, z - 31), Vector2(-469, z + 25), Vector2(-396, z - 29), Vector2(-396, z + 31), Vector2(-442, z + 39)]:
			_tree(at, 7.5 + row * .4)
	# Southern buildings face the internal lane, with side walks to south street.
	for id in ["south_1", "south_2", "south_3"]:
		var lot: Dictionary = Layout.LOTS[id]
		var x: float = lot["rect"].get_center().x
		_entrance_gardens(lot)
		_surface(Rect2(x - 8, 253, 16, 7), "courtyard")
		_surface(Rect2(x - 1, 260, 2, 4), "paving")
		_model(BENCH, Vector2(x - 4, 256), PI)
		_model(BIN, Vector2(x - 6, 256))
		_model(LAMP, Vector2(x + 5, 260))
		_surface(Rect2(x + 13, 256, 14, 6), "asphalt")
		var at := Vector2(x + 21, 259)
		map._vehicle("lada", Vector3(at.x, .15, at.y), map.VehicleModels.map_length("lada"), "z", root)
		map._occupy(at, Vector2(2.5, 5))
		for dx in [-40.0, -14.0, 13.0, 38.0]:
			_tree(Vector2(x + dx, 292.5), 7.0 + absf(dx) * .025)
		for dx in [-37.0, 34.0]:
			_tree(Vector2(x + dx, 255), 8.0)


func _surface(rect: Rect2, ground: String) -> void:
	builder._patch(rect, ground, .145)
	map.get_child(map.get_child_count() - 1).reparent(root)
	map._occupy(rect.get_center(), rect.size)
	if ground == "asphalt":
		# Broken-up yard edges; avoid an oversized paved rectangle.
		map.wear.add_ring(rect, 1.2, .45)


func _model(scene: PackedScene, at: Vector2, yaw: float = 0.0) -> void:
	var node: Node3D = scene.instantiate()
	node.position = Vector3(at.x, .15, at.y)
	node.rotation.y = yaw
	root.add_child(node)
	map._occupy(at, Vector2(1.5, 1.5))


func _tree(at: Vector2, height: float) -> void:
	var node := Vegetation.create("park_deciduous_tree", Vector3(at.x, .03, at.y))
	node.scale = Vector3.ONE * height / float(Vegetation.HEIGHTS["park_deciduous_tree"])
	node.rotation.y = fposmod(at.x * .73 + at.y * .37, TAU)
	root.add_child(node)
	map._occupy(at, Vector2(4, 4))


func _entrance_gardens(lot: Dictionary) -> void:
	var entry: Dictionary = Catalog.CONTENTS[lot["content"]]
	var size: Vector2 = entry["footprint"]
	var center: Vector2 = lot["rect"].get_center()
	var out: Vector2 = {"e": Vector2.RIGHT, "w": Vector2.LEFT, "n": Vector2.UP}[lot["facing"]]
	var along := Vector2(out.y, -out.x)
	# Narrow planted strips between the real 24-metre stair/entrance bays.
	for offset in [-size.x / 2 + 22, -size.x / 2 + 46]:
		var at: Vector2 = center + along * offset + out * (size.y / 2 + 2)
		var patch_size := Vector2(2, 6) if out.x != 0 else Vector2(6, 2)
		_surface(Rect2(at - patch_size / 2, patch_size), "dirt")
		for shift in [-2.0, 0.0, 2.0]:
			var shrub_at: Vector2 = at + along * shift
			var shrub := Vegetation.create("park_shrub", Vector3(shrub_at.x, .15, shrub_at.y))
			shrub.scale = Vector3.ONE * .65
			root.add_child(shrub)
