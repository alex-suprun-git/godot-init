# Static reusable freight formation. Meshes are shared; only cargo paint varies.
extends RefCounted

const LOCOMOTIVE := preload("res://assets/models/vehicles/m62_locomotive.glb")
const WAGON := preload("res://assets/models/vehicles/container_flat_wagon.glb")
const MAP_FACTOR := 4.3 / 4.37 # Same presentation scale as the existing ER2.
const LOCO_LENGTH := 18.181793212890625
const WAGON_LENGTH := 15.14631462097168 # Measured GLB coupler-to-coupler bounds.
const WAGON_COUNT := 8
const PALETTE := [Color("985a49"), Color("526c7b"), Color("6b7450")]
const WAGON_COLORS := [0, 1, 2, 0, 2, 1, 0, 1]
const TOTAL_LENGTH := (LOCO_LENGTH + WAGON_COUNT * WAGON_LENGTH) * MAP_FACTOR


static func create() -> Node3D:
	var train := Node3D.new()
	train.name = "ContainerFreightTrain"
	var locomotive := LOCOMOTIVE.instantiate() as Node3D
	locomotive.name = "Locomotive"
	locomotive.scale = Vector3.ONE * MAP_FACTOR
	locomotive.position.z = TOTAL_LENGTH / 2.0 - LOCO_LENGTH * MAP_FACTOR / 2.0
	train.add_child(locomotive)
	var paints: Dictionary = {}
	for i in range(WAGON_COUNT):
		var wagon := WAGON.instantiate() as Node3D
		wagon.name = "ContainerWagon%02d" % (i + 1)
		wagon.scale = Vector3.ONE * MAP_FACTOR
		wagon.position.z = TOTAL_LENGTH / 2.0 - (LOCO_LENGTH + (i + 0.5) * WAGON_LENGTH) * MAP_FACTOR
		_paint_cargo(wagon, WAGON_COLORS[i], paints)
		train.add_child(wagon)
	return train


static func _paint_cargo(node: Node, color_index: int, paints: Dictionary) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var base: Material = node.get_surface_override_material(surface)
			if base == null:
				base = node.mesh.surface_get_material(surface)
			if base is BaseMaterial3D and "container paint" in base.resource_name.to_lower():
				if not paints.has(color_index):
					var paint: BaseMaterial3D = base.duplicate()
					paint.albedo_color = PALETTE[color_index]
					paint.vertex_color_use_as_albedo = true
					paint.vertex_color_is_srgb = false
					paints[color_index] = paint
				node.set_surface_override_material(surface, paints[color_index])
	for child in node.get_children():
		_paint_cargo(child, color_index, paints)
