# Original Blender asset and its modest inhabited court, on the existing home parcel.
extends RefCounted

const MODEL = preload("res://assets/models/dormitory/dormitory.glb")
const BENCH = preload("res://assets/models/civic_center/park_bench.glb")
const BIN = preload("res://assets/models/civic_center/park_bin.glb")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")

func build(map, lot: Dictionary) -> void:
	var center: Vector2 = lot["rect"].get_center()
	var root := Node3D.new()
	root.name = "DormitoryCompound"
	root.position = Vector3(center.x, 0, center.y)
	map.add_child(root)
	var model: Node3D = MODEL.instantiate()
	model.position = Vector3(0, 0.025, -4.5)
	root.add_child(model)
	# Keep random roadside planting out of the building and authored court.
	map._occupy(center + Vector2(0, 0.5), Vector2(38, 38))
	var door := center + Vector2(2.7, -1.3)
	map.sim.graph.set_doorstep("dormitory", door)
	map.wear.add_disc(door, 3.0, 0.5)
	# Reach the actual housing footway, rather than stopping at the lot boundary.
	map._path_quad(Rect2(door.x - 1.2, door.y, 2.4, 85.2 - door.y), 0.055, "paving", Color("c0bdb1"))
	map._path_quad(Rect2(center.x + 0.5, center.y - 2.2, 4.4, 2.8), 0.055, "paving", Color("c0bdb1"))
	# A short westward connection passes south of the return wing to the sidewalk.
	map._path_quad(Rect2(lot["rect"].position.x, center.y + 10.5, door.x - lot["rect"].position.x, 1.8), 0.055, "paving", Color("c0bdb1"))
	map._path_quad(Rect2(door.x, center.y + 8, 13.0, 1.6), 0.055, "paving", Color("c0bdb1"))
	for pad in [Rect2(4.5, 4.8, 4.5, 4.8), Rect2(12, 8, 5, 4.5)]:
		map._path_quad(Rect2(center + pad.position, pad.size), 0.055, "paving", Color("c0bdb1"))
	for at in [Vector3(6.5, 0.055, 6.3), Vector3(14.5, 0.055, 11)]:
		var bench: Node3D = BENCH.instantiate()
		bench.position = at
		if at.z > 10:
			bench.rotation.y = PI
		root.add_child(bench)
	var bin: Node3D = BIN.instantiate()
	bin.position = Vector3(8.4, 0.055, 6.3)
	root.add_child(bin)
	var tree := Vegetation.create("park_deciduous_tree", Vector3(15, 0, 2.5))
	tree.scale = Vector3.ONE * 0.75
	root.add_child(tree)
	for at in [Vector3(-1, 0, 13.5), Vector3(15, 0, 15.5)]:
		root.add_child(Vegetation.create("park_shrub", at))
	# Modest planted beds along the facade and lawn edge, leaving the entrance open.
	for bed in [Rect2(6, -3.8, 8, 1.7), Rect2(-2.8, 4.5, 1.3, 5), Rect2(16, 3, 1.6, 4.5)]:
		map._ground_quad(center + bed.get_center(), bed.size, 0.04, map._season["dirt"], 3.0, false, Color("a2a08b"), true, 0.45)
	for at in [Vector3(7, 0.04, -3), Vector3(10, 0.04, -3), Vector3(13, 0.04, -3), Vector3(-2.1, 0.04, 5.5), Vector3(-2.1, 0.04, 8), Vector3(16.8, 0.04, 4), Vector3(16.8, 0.04, 6.5)]:
		var shrub := Vegetation.create("park_shrub", at)
		shrub.scale = Vector3.ONE * 0.55
		root.add_child(shrub)
	# A worn practical patch under the washing line, with a short path to it.
	map._ground_quad(center + Vector2(8.5, 16.3), Vector2(10, 4.5), 0.035, map._season["grass_dry"], 4.0, false, map._season["grass_tint"], true, 1.1)
	map._path_quad(Rect2(center.x + 3.9, center.y + 13.8, 5.5, 1.2), 0.055, "paving", Color("c0bdb1"))
	# Two clothesline frames and hanging cloth make this a lived-in home.
	for x in [5.0, 12.0]:
		map._box(Vector3(0.08, 2.2, 0.08), Vector3(x, 1.1, 16.5), Color("6b7974"), root)
	map._box(Vector3(7, 0.035, 0.035), Vector3(8.5, 2.1, 16.5), Color("696b63"), root)
	for i in 4:
		map._box(Vector3(0.8, 1.0, 0.025), Vector3(6 + i * 1.5, 1.6, 16.5), Color("c9c8b6") if i % 2 == 0 else Color("8499a0"), root)
