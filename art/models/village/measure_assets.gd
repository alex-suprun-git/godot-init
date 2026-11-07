# Manual resource inspection: report actual imported bounds and root transforms.
extends SceneTree
var bounds := AABB()
var first := true

func _initialize() -> void:
	for entry in [
		["tree","res://assets/models/civic_center/park_deciduous_tree.glb"],
		["poplar","res://assets/models/civic_center/park_poplar.glb"],
		["new homestead","res://assets/models/village/d_05.glb"],
		["rebuilt homestead","res://assets/models/village/d_06.glb"],
		["church","res://assets/models/church_ensemble/church.glb"],
		["Volga raw","res://assets/models/vehicles/volga_gaz24.glb"],
		["PAZ raw","res://assets/models/vehicles/bus_paz_3205.glb"],
	]:
		var node: Node3D = load(entry[1]).instantiate()
		first = true
		_walk(node,Transform3D.IDENTITY)
		print("IMPORTED BOUNDS ",entry[0],": ",bounds.size," root scale=",node.scale)
		node.free()
	quit()

func _walk(node: Node, parent: Transform3D) -> void:
	var transform := parent
	if node is Node3D:
		transform = parent*node.transform
	if node is MeshInstance3D and node.mesh:
		var box: AABB = transform*node.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	for child in node.get_children():
		_walk(child,transform)
