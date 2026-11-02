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


static func create(vehicle_class: String, seed_value: int, at: Vector3) -> Node3D:
	var model := VehicleModels.model_for_class(vehicle_class, seed_value)
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
	vehicle.set_meta("traffic_model", model)
	return vehicle
