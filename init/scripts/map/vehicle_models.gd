# Shared 3D vehicle resources. Positions and lengths are in metres; +Z is forward.
extends RefCounted

const MODELS := {"lada": preload("res://assets/models/vehicles/lada_sedan_v2.glb")}
const LENGTHS := {"lada": 4.37}


static func create(model_id: String, at: Vector3, length: float, axis: String) -> Node3D:
	var scene: PackedScene = MODELS[model_id]
	var vehicle: Node3D = scene.instantiate()
	vehicle.name = "Lada3D" if model_id == "lada" else model_id.to_pascal_case()
	vehicle.position = at + Vector3.UP * 0.005
	vehicle.rotation.y = PI / 2.0 if axis == "x" else 0.0
	vehicle.scale = Vector3.ONE * (length / float(LENGTHS[model_id]))
	vehicle.add_to_group("vehicle_models")
	vehicle.add_to_group("vehicle_%s" % model_id)
	return vehicle
