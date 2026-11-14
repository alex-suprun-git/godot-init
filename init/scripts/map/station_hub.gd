# Dimensioned assembly of the approved station / market / shared-square composition.
# Local building/prop geometry lives in separately exported Blender assets.
extends RefCounted

const Vehicles := preload("res://scripts/map/vehicle_models.gd")
const Layout := preload("res://scripts/data/district_layout.gd")
const Surfaces := preload("res://scripts/map/station_surfaces.gd")
const ROOT := "res://assets/models/station_hub/"
const ASSETS := {
	"station": preload(ROOT + "station.glb"),
	"stall_red": preload(ROOT + "stall_red.glb"),
	"stall_blue": preload(ROOT + "stall_blue.glb"),
	"stall_ochre": preload(ROOT + "stall_ochre.glb"),
	"shelter": preload(ROOT + "bus_shelter.glb"),
	"kiosk": preload(ROOT + "kiosk.glb"),
	"bench": preload(ROOT + "bench.glb"),
	"lamp": preload(ROOT + "lamp.glb"),
}

var map
var root: Node3D

func build(city_map) -> void:
	map = city_map
	root = Node3D.new()
	root.name = "StationHub3D"
	map.add_child(root)
	_square()
	_station()
	_market()
	_furniture()
	var crowd := preload("res://scripts/map/station_crowd.gd").new()
	root.add_child(crowd)
	crowd.build(map)
	map._occupy(Vector2(-90, 350.5), Vector2(126, 67))

func _asset(id: String, at: Vector3, yaw := 0.0) -> Node3D:
	var instance: Node3D = ASSETS[id].instantiate()
	instance.position = at
	instance.rotation.y = yaw
	root.add_child(instance)
	return instance

func _paving(rect: Rect2, height := 0.18) -> void:
	map._box(Vector3(rect.size.x, height, rect.size.y),
		Vector3(rect.get_center().x, height / 2.0, rect.get_center().y), Color("a6a497"), root)
	Surfaces.surface(root, rect, height + .006, 1)

func _park(model: String, at: Vector3, axis: String, paint := -1) -> Node3D:
	var length := Vehicles.map_length(model)
	var footprint := Vector2(length + .8, 2.8) if axis == "x" else Vector2(2.8, length + .8)
	if not Layout.parking_allowed(Vector2(at.x, at.z), footprint):
		return null
	var vehicle := Vehicles.create(model, at, length, axis, paint)
	vehicle.add_to_group("parked_vehicles")
	vehicle.set_meta("parking_footprint", footprint)
	root.add_child(vehicle)
	return vehicle

func _station() -> void:
	# Raised floor meets the platform; city-side steps reach the common forecourt.
	map._box(Vector3(36, 1.27, 14), Vector3(-65, .635, 377), Color("858278"), root)
	_asset("station", Vector3(-65, 1.27, 377))
	# Taxis occupy asphalt pockets; the pedestrian apron is a separate raised walk.
	map._asphalt_quad(Rect2(-85, 354, 43, 8), .142, Color.WHITE)
	_paving(Rect2(-85, 362, 43, 8), .18)
	Surfaces.kerb(root, Rect2(-85, 362, 43, 8), .18,
		[Rect2(-68, 360, 6, 4), Rect2(-84, 369, 38, 2)])
	for i in range(7):
		var height := .18 + (i + 1) * (1.09 / 7.0)
		map._box(Vector3(6, height, .5), Vector3(-65, height / 2.0, 366.75 + i * .5), Color("aaa79b"), root)
	# The paved approach starts at the taxi pocket, beyond the bus crossing.
	_paving(Rect2(-67, 354, 4, 8), .16)
	# One clear crossing from station approach to the shelter island, rather than
	# intersecting auto-generated zebras at every internal route junction.
	for i in range(13):
		var stripe = map._box(Vector3(3.5, .018, .50),
			Vector3(-65, .162, 341.0 + i), Color("b8b5a7"), root)
		stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for x in [-77.0, -53.0]:
		_park("volga", Vector3(x, .145, 358), "x", int(abs(x)))
		for edge in [-3.0, 3.0]:
			map._paint_patch(Vector2(.10, 3.4), Vector2(x + edge, 358), .152)

func _square() -> void:
	# Broad asphalt covers the junction turning envelopes. Both throats connect
	# to south_street, never directly to the avenue's rising bridge approach.
	map._asphalt_quad(Rect2(-138, 316, 110, 39), .14, Color.WHITE)
	for x in [-130.0, -46.0]:
		map._asphalt_quad(Rect2(x - 4, 305, 8, 12), .141, Color.WHITE)
	_paving(Rect2(-121, 332, 66, 8), .24)
	Surfaces.kerb(root, Rect2(-121, 332, 66, 8), .24, [Rect2(-68, 339, 6, 2)])
	# Passenger bays lie off the through lane; left/right exits stay open.
	for x in [-104.0, -80.0]:
		_asset("shelter", Vector3(x, .25, 338.1))
		var bus := _park("bus_liaz", Vector3(x, .145, 342.9), "x")
		if bus != null:
			bus.rotation.y = -PI / 2.0
		for dx in [-6.1, 6.1]:
			map._paint_patch(Vector2(.10, 3.4), Vector2(x + dx, 342.9), .15)
	# Side parking pocket: no stall or car occupies either bus entry/exit.
	map._asphalt_quad(Rect2(-39, 328, 12, 29), .14, Color.WHITE)
	# A low parking boundary keeps parked noses off the grass without blocking access.
	Surfaces.kerb(root, Rect2(-39, 328, 12, 29), .20, [Rect2(-40, 329, 3, 27)])
	for i in range(8):
		var z := 331.0 + i * 3.0
		var model := "volga" if i % 3 == 0 else "lada"
		_park(model, Vector3(-33, .145, z), "x", i * 13 + 8)
		map._paint_patch(Vector2(5.6, .09), Vector2(-33, z - 1.4), .15)
	# Sparse centre/edge dashes establish two connected circulation arms.
	for z in range(310, 345, 8):
		for x in [-130.0, -46.0]:
			map._paint_patch(Vector2(.10, 2.7), Vector2(x, z), .15)
	for x in range(-123, -49, 8):
		if x == -67:
			continue # The crossing occupies this part of the bus lane.
		map._paint_patch(Vector2(2.7, .1), Vector2(x, 348), .15)
	# Kiosks are small accessories to the same square, not another terminal.
	_asset("kiosk", Vector3(-141, .19, 321))
	_asset("kiosk", Vector3(-31, .19, 322), -PI / 2.0)

func _market() -> void:
	# An ordinary reused asphalt site at ground level, with dusty aisles and a
	# broken grass-side edge. No raised municipal-tile plinth under the stalls.
	Surfaces.surface(root, Rect2(-152, 352, 61, 32), .045, 2)
	for row in range(4):
		for column in range(14):
			var id: String = ["stall_red", "stall_blue", "stall_ochre"][(column * 7 + row * 2) % 3]
			_asset(id, Vector3(-147 + column * 3.9, .05, 354.5 + row * 7.0))
	# Keep a railway-side edge and a pedestrian entrance at the north-east corner.
	for i in range(21):
		map._box(Vector3(.055, 1.2, .055), Vector3(-151 + i * 3, .65, 383.3), Color("555d51"), root)
	for y in [.45, 1.1]:
		map._box(Vector3(60, .035, .035), Vector3(-121, y, 383.3), Color("555d51"), root)

func _furniture() -> void:
	for at in [Vector2(-135, 319), Vector2(-47, 319), Vector2(-37, 357), Vector2(-86, 363), Vector2(-93, 382)]:
		var floor_height := .05 if at.x < -91 and at.y > 352 else .18
		_asset("lamp", Vector3(at.x, floor_height, at.y))
		map._lamp_light(Vector3(at.x, floor_height, at.y))
	for at in [Vector2(-78, 367), Vector2(-49, 367), Vector2(-61, 334)]:
		_asset("bench", Vector3(at.x, .19, at.y))
		map._box(Vector3(.45, .75, .45), Vector3(at.x + 1.5, .56, at.y), Color("666959"), root)
