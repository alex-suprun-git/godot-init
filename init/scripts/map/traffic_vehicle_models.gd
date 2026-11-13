# Moving-traffic appearance only; parked/event vehicles use VehicleModels directly.
extends RefCounted

const VehicleModels = preload("res://scripts/map/vehicle_models.gd")
const GAZELLE_SHARE_OF_ZILS := 0.5
const GAZELLES := {
	"gazelle_white": preload("res://assets/models/vehicles/gazelle_2705.glb"),
	"gazelle_blue": preload("res://assets/models/vehicles/gazelle_2705_blue.glb"),
	"gazelle_sand": preload("res://assets/models/vehicles/gazelle_2705_sand.glb"),
}
const GAZELLE_PAINTS := ["gazelle_white", "gazelle_blue", "gazelle_sand"]


static var _footprints := {}


static func create(vehicle_class: String, seed_value: int, at: Vector3, rare_car_model: String = "") -> Node3D:
	var model := VehicleModels.model_for_class(vehicle_class, seed_value)
	if vehicle_class == "car" and (VehicleModels.AUTHORED_CAR_LENGTHS.has(rare_car_model) or VehicleModels.SERVICE_LENGTHS.has(rare_car_model)):
		model = rare_car_model
	# Separate salted choices preserve existing class RNG and KamAZ selection.
	if model in ["zil_flatbed", "zil_food"]:
		var roll := posmod(hash("gazelle-share:%d" % seed_value), 10000)
		if roll < int(GAZELLE_SHARE_OF_ZILS * 10000.0):
			model = GAZELLE_PAINTS[posmod(hash("gazelle-paint:%d" % seed_value), GAZELLE_PAINTS.size())]
	var vehicle: Node3D
	if GAZELLES.has(model):
		vehicle = GAZELLES[model].instantiate()
		vehicle.name = model.to_pascal_case()
		vehicle.position = at + Vector3.UP * 0.005
		# The approved 0.831725 presentation factor is already in each GLB.
		vehicle.add_to_group("vehicle_models")
		vehicle.add_to_group("vehicle_gazelle")
		vehicle.add_to_group("vehicle_%s" % model)
	else:
		vehicle = VehicleModels.create(model, at, VehicleModels.map_length(model), "z", seed_value)
	if not _footprints.has(model):
		_footprints[model] = _measure_footprint(vehicle)
	vehicle.set_meta("traffic_half_extent", _footprints[model])
	if model in ["lada", "lada_wagon"]:
		var front := []
		for wheel: Node3D in vehicle.find_children("Wheel_*_F*", "Node3D", true, false):
			front.append({"node": wheel, "rest": wheel.basis})
		vehicle.set_meta("front_wheels", front)
	vehicle.set_meta("traffic_model", model)
	return vehicle


# Measure once per model in driving coordinates (+Z forward), including root scale
# and off-centre bumpers. The simulation can use this without touching mesh data.
static func _measure_footprint(vehicle: Node3D) -> Vector2:
	var extent := Vector2.ZERO
	for mesh: MeshInstance3D in vehicle.find_children("*", "MeshInstance3D", true, false):
		var transform := mesh.transform
		var parent := mesh.get_parent_node_3d()
		while parent != vehicle:
			transform = parent.transform * transform
			parent = parent.get_parent_node_3d()
		var bounds: AABB = Transform3D(vehicle.transform.basis, Vector3.ZERO) * transform * mesh.get_aabb()
		extent.x = maxf(extent.x, maxf(absf(bounds.position.x), absf(bounds.end.x)))
		extent.y = maxf(extent.y, maxf(absf(bounds.position.z), absf(bounds.end.z)))
	return extent + Vector2.ONE * 0.05
