extends SceneTree

func _initialize() -> void:
	for file in ["uaz_police", "raf_ambulance"]:
		var scene := load("res://models/%s.glb" % file) as PackedScene
		var root := scene.instantiate()
		for node in root.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			for surface in range(mesh.mesh.get_surface_count()):
				var mat := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
				var arrays := mesh.mesh.surface_get_arrays(surface)
				var tex := mat.albedo_texture
				print(file, " ", node.name, " ", mat.resource_name, " atlas=", tex.get_size() if tex else Vector2.ZERO, " indexed_triangles=", (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3)
		root.free()
	quit()
