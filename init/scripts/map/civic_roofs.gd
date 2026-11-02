# Roof fittings are instanced boxes; their metre scale stays readable on the map.
extends RefCounted

static var _box_mesh: BoxMesh


static func build(map, parent: Node3D, size: Vector2, height: float, style: String) -> void:
	var roof := Node3D.new()
	roof.name = "RoofFittings"
	roof.position.y = height + 0.42
	parent.add_child(roof)
	var boxes: Array = []
	var concrete := Color("a19e92")
	var metal := Color("777f7e")
	var dark := Color("414b4c")
	var cap := Color("a9ada7")
	var parapet_height := 0.65 if style == "tower" else 0.4
	for z in [-size.y / 2.0, size.y / 2.0]:
		boxes.append([Vector3(size.x + 0.45, parapet_height, 0.32), Vector3(0, parapet_height / 2.0, z), concrete])
		boxes.append([Vector3(size.x + 0.65, 0.12, 0.52), Vector3(0, parapet_height + 0.06, z), metal])
	for x in [-size.x / 2.0, size.x / 2.0]:
		boxes.append([Vector3(0.32, parapet_height, size.y), Vector3(x, parapet_height / 2.0, 0), concrete])
		boxes.append([Vector3(0.52, 0.12, size.y), Vector3(x, parapet_height + 0.06, 0), metal])
	# Access hut with a dark door and an overhanging metal cap.
	var hut := Vector3(4.0, 2.2, 3.4) if style == "tower" else Vector3(2.6, 1.25, 2.4)
	var hut_at := Vector3(-size.x * 0.18, hut.y / 2.0, -size.y * 0.15)
	boxes.append([hut, hut_at, concrete])
	boxes.append([Vector3(hut.x + 0.35, 0.15, hut.z + 0.35), hut_at + Vector3.UP * (hut.y / 2.0 + 0.075), metal])
	boxes.append([Vector3(0.8, minf(1.8, hut.y - 0.1), 0.04), hut_at + Vector3(0, -0.05, hut.z / 2.0 + 0.025), dark])
	if style == "store":
		for x in [-5.5, 4.0]:
			var pos := Vector3(x, 0.65, 4.0)
			boxes.append([Vector3(3.2, 1.3, 2.0), pos, metal])
			boxes.append([Vector3(2.7, 0.85, 0.05), pos + Vector3(0, 0, 1.03), dark])
			boxes.append([Vector3(3.6, 0.12, 2.4), pos + Vector3.UP * 0.7, cap])
			for slat in 5:
				boxes.append([Vector3(2.7, 0.06, 0.08), pos + Vector3(0, -0.3 + slat * 0.15, 1.08), cap])
	else:
		var count := maxi(2, int(size.x / 12.0))
		for i in count:
			var x := lerpf(-size.x / 2.0 + 4.0, size.x / 2.0 - 4.0, (i + 0.5) / count)
			for z in [-size.y * 0.3, size.y * 0.3]:
				boxes.append([Vector3(1.1, 0.95, 0.8), Vector3(x, 0.475, z), concrete])
				boxes.append([Vector3(0.9, 0.3, 0.06), Vector3(x, 0.77, z + 0.44), dark])
				boxes.append([Vector3(1.45, 0.13, 1.1), Vector3(x, 1.04, z), metal])
	# E1's roofline uses the approved pilaster rhythm, with actual stepped caps.
	if style == "tower":
		var brick := Color("c4a16f") if height > 40.0 else Color("c4c0aa")
		if height > 40.0:
			for z in [-size.y / 2.0, size.y / 2.0]:
				for x in [-9.0, -3.0, 3.0, 9.0]:
					boxes.append([Vector3(0.85, 1.05, 0.65), Vector3(x, 0.525, z), brick])
					boxes.append([Vector3(1.05, 0.12, 0.8), Vector3(x, 1.11, z), concrete])
		for shift in [Vector3(5.0, 0, -3.0), Vector3(-6.0, 0, 5.0)]:
			map._cylinder(0.055, 3.1, shift + Vector3.UP * 1.55, metal, roof)
			for y in [2.1, 2.7]:
				boxes.append([Vector3(2.1, 0.045, 0.045), shift + Vector3.UP * y, metal])
				for x in [-0.65, 0.0, 0.65]:
					boxes.append([Vector3(0.045, 0.045, 0.85), shift + Vector3(x, y, 0), metal])
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_box_mesh.size = Vector3.ONE
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.92
		_box_mesh.material = material
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = _box_mesh
	instances.instance_count = boxes.size()
	for i in boxes.size():
		instances.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(boxes[i][0]), boxes[i][1]))
		var colour: Color = boxes[i][2]
		instances.set_instance_color(i, colour.srgb_to_linear())
	var visual := MultiMeshInstance3D.new()
	visual.multimesh = instances
	roof.add_child(visual)
