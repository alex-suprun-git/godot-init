# Original 3D civic venues, visual backdrop; no new simulation locations.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Vehicles = preload("res://scripts/map/vehicle_models.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Surfaces = preload("res://scripts/map/station_surfaces.gd")
const ROOT := "res://assets/models/civic_venues/"
const ASSETS := {
	"restaurant": preload(ROOT + "restaurant.glb"),
	"terrace": preload(ROOT + "restaurant_terrace.glb"),
	"culture_house": preload(ROOT + "culture_house.glb"),
	"wall": preload(ROOT + "privacy_wall_6m.glb"),
	"gate": preload(ROOT + "gate_leaf.glb"),
	"guardhouse": preload(ROOT + "guardhouse.glb"),
	"guard": preload(ROOT + "security_guard.glb"),
	"lamp": preload("res://assets/models/civic_center/park_lantern.glb"),
	"bench": preload("res://assets/models/civic_center/park_bench.glb"),
}

var builder
var map
var root: Node3D


func build(district_builder, id: String, lot: Dictionary) -> void:
	builder = district_builder
	map = builder.map
	root = Node3D.new()
	root.name = "PrivateRestaurantCompound" if id == "city_park" else "HouseOfCulture"
	root.set_meta("lot_id", id)
	root.set_meta("lot_rect", lot["rect"])
	map.add_child(root)
	if id == "city_park":
		_restaurant()
	else:
		_culture_house()


func asset(id: String, at: Vector3, yaw := 0.0) -> Node3D:
	var node: Node3D = ASSETS[id].instantiate()
	node.position = at
	node.rotation.y = yaw
	root.add_child(node)
	return node


func surface(rect: Rect2, kind := 1, y := 0.13) -> void:
	map._box(Vector3(rect.size.x, y, rect.size.y), Vector3(rect.get_center().x, y / 2.0, rect.get_center().y), Color("969183"), root)
	Surfaces.surface(root, rect, y + .005, kind)


func box(at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	return map._box(size, at, Color(color), root)


func tree(at: Vector2, scale_factor := .7, evergreen := false) -> void:
	var node := Vegetation.create("park_conifer" if evergreen else "park_deciduous_tree", Vector3(at.x, .06, at.y))
	node.scale *= scale_factor
	root.add_child(node)
	map._occupy(at + Vector2(root.position.x, root.position.z), Vector2(3, 3))


func shrub(at: Vector2, scale_factor := .55) -> void:
	var node := Vegetation.create("park_shrub", Vector3(at.x, .06, at.y))
	node.scale *= scale_factor
	root.add_child(node)


func wall(a: Vector2, b: Vector2) -> void:
	var delta := b - a
	var count := maxi(1, int(ceil(delta.length() / 6.0)))
	var segment := delta.length() / count
	for i in count:
		var center := a + delta * ((float(i) + .5) / count)
		var node := asset("wall", Vector3(center.x, .04, center.y), -atan2(delta.y, delta.x))
		node.scale.x = segment / 6.0


func _restaurant() -> void:
	# Keep the 51 x80 m layout together, aligned to both adjoining street sidewalks.
	var rect: Rect2 = Layout.LOTS["city_park"]["rect"]
	root.position = Vector3(rect.position.x - 85.0, 0, rect.position.y + 70.0)
	map._occupy(rect.get_center(), rect.size)
	asset("restaurant", Vector3(106, .16, -42), PI / 2.0)
	asset("terrace", Vector3(105, .16, -26.8), PI / 2.0)
	# Solid 3 m perimeter; only the east visitor entrance is open.
	wall(Vector2(85.6, -69.4), Vector2(135.4, -69.4))
	wall(Vector2(85.6, -69.4), Vector2(85.6, 9.4))
	wall(Vector2(85.6, 9.4), Vector2(135.4, 9.4))
	wall(Vector2(135.4, -69.4), Vector2(135.4, -8))
	wall(Vector2(135.4, 0), Vector2(135.4, 1.8))
	wall(Vector2(135.4, 3.4), Vector2(135.4, 9.4))
	# Main sliding leaf is retracted behind the wall; separate pedestrian wicket.
	asset("gate", Vector3(135.15, .12, -10.1), PI / 2.0)
	var wicket := asset("gate", Vector3(135.15, .12, 2.6), PI / 2.0)
	wicket.scale.x = 1.6 / 3.8
	asset("guardhouse", Vector3(130, .16, 6.5), 0)
	asset("guard", Vector3(131.3, .16, 1.0), -.5)
	asset("guard", Vector3(117.3, .16, -50), PI / 2.0)
	# Internal arrival road, side parking, screened service lane. Sidewalk outside stays public.
	surface(Rect2(133, -8, 7.0 - root.position.x, 8), 0, .145)
	surface(Rect2(120, -8, 15.5, 10), 0, .14)
	surface(Rect2(121, -56, 7, 50), 0, .14)
	surface(Rect2(92, -23, 33, 17), 0, .14)
	surface(Rect2(87, -63, 6, 57), 0, .14)
	surface(Rect2(87, -66, 29, 7), 0, .14)
	surface(Rect2(115, -57, 6, 30), 1, .20)
	surface(Rect2(118, -8, 13, 4), 1, .20)
	surface(Rect2(101, -28, 9, 5), 1, .17)
	# Four luxury cars occupy the existing nine full-size parking spaces.
	for i in 10:
		box(Vector3(94 + i * 3.0, .155, -18), Vector3(.08, .025, 5.5), "c4c0ac")
	for i in [0, 2, 4, 6]:
		var at := Vector3(95.5 + i * 3.0, .145, -18)
		var model := "luxury_sedan" if i % 4 == 0 else "luxury_suv"
		var car := Vehicles.create(model, at, Vehicles.map_length(model), "z")
		car.add_to_group("parked_vehicles")
		car.set_meta("parking_footprint", Vector2(2.8, 5.5))
		root.add_child(car)
	# Barrier and period box camera stay inside the controlled grounds.
	box(Vector3(129.5, .7, .1), Vector3(.3, 1.4, .3), "67665d")
	box(Vector3(129.5, 1.15, -3.65), Vector3(.11, .11, 7.5), "d4cfb6")
	for z in [-6.5, -5.0, -3.5, -2.0]:
		box(Vector3(129.5, 1.15, z), Vector3(.12, .12, .55), "9b2920")
	box(Vector3(128.2, 2.1, 1.1), Vector3(.08, 4.2, .08), "55584d")
	box(Vector3(128.2, 4.1, .9), Vector3(.22, .18, .45), "9b9d8f")
	for at in [Vector2(118, -54), Vector2(118, -30), Vector2(129, -38), Vector2(130, -10)]:
		asset("lamp", Vector3(at.x, .12, at.y))
	# Broad planted margins and private garden, keeping the service approach clear.
	for at in [Vector2(89, 5), Vector2(103, 5), Vector2(117, 5), Vector2(130, -23), Vector2(130, -45), Vector2(130, -62), Vector2(119, -65), Vector2(99, -66)]:
		tree(at, .55 + fposmod(at.x * .13, .17))
	for at in [Vector2(93, -30), Vector2(94, -47), Vector2(130, -53)]:
		tree(at, .5, true)
	for z in range(-66, 8, 4):
		if z < -10 or z > 3:
			shrub(Vector2(132, z), .5)
	for x in range(89, 128, 4):
		shrub(Vector2(x, 7), .55)
	for z in range(-58, -25, 4):
		shrub(Vector2(94, z), .45)
	asset("bench", Vector3(109, .16, 5), PI)
	asset("bench", Vector3(120, .16, -64), PI / 2.0)
	print("Restaurant compound: 51x80m parcel (~10% smaller); guarded village-street entry")


func _culture_house() -> void:
	# User explicitly replaces only tower_e1; west-facing foyer, mosaic toward south.
	map._occupy(Vector2(50, -41), Vector2(33, 34))
	asset("culture_house", Vector3(50, .16, -41), -PI / 2.0)
	surface(Rect2(28, -58, 10.0, 34), 1, .14)
	surface(Rect2(7, -43, 21, 4), 1, .14)
	surface(Rect2(62, -57, 8, 32), 0, .14)
	for z in [-55.0, -27.0]:
		asset("bench", Vector3(30.2, .15, z), -PI / 2.0)
		asset("lamp", Vector3(26.4, .15, z))
	for at in [Vector2(29, -62), Vector2(68, -62), Vector2(68, -21)]:
		tree(at, .64)
	for z in [-58.5, -23.0]:
		for x in [33.0, 39.0, 45.0, 51.0, 57.0]:
			shrub(Vector2(x, z), .45)
