# Shared static four-car assembly; dimensions are measured from the exported GLBs.
extends RefCounted

const Vehicles := preload("res://scripts/map/vehicle_models.gd")
const HEAD := preload("res://assets/models/vehicles/er2_head.glb")
const MOTOR := preload("res://assets/models/vehicles/er2_motor.glb")
const CAR_LENGTH := 20.90647315979004


static func create() -> Node3D:
	var train := Node3D.new()
	train.name = "ER2FourCarTrain"
	var factor: float = Vehicles.LADA_MAP_LENGTH / float(Vehicles.LENGTHS["lada"])
	for i in range(4):
		var car: Node3D = (HEAD if i in [0, 3] else MOTOR).instantiate()
		car.name = "HeadFront" if i == 0 else ("HeadRear" if i == 3 else "Motor%d" % i)
		car.scale = Vector3.ONE * factor
		car.position.z = (1.5 - i) * CAR_LENGTH * factor
		car.rotation.y = PI if i >= 2 else 0.0
		train.add_child(car)
	return train
