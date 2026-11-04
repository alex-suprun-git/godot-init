# The old Soviet shell now hosts separate rented retail sections, August1997.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const STORE = preload("res://assets/models/department_store/department_store_1997.glb")


func build(builder, lot: Dictionary, entry: Dictionary, id: String) -> void:
	var map = builder.map
	var center := Layout.lot_center(id)
	var root: Node3D = STORE.instantiate()
	root.name = "DepartmentStore1997"
	root.position = Vector3(center.x, .16, center.y)
	root.rotation.y = -PI / 2.0
	map.add_child(root)
	# Main body is unchanged; include shallow garden-side shop displays in planting clearance.
	map._occupy(center + Vector2(.4, 1.1), Vector2(31, 26.5))
	builder._register_doorstep(id, lot, entry, center, 30.0)
