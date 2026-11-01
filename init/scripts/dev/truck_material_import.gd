# Cargo and mechanical surfaces store linear vertex colors; cab paint stays tintable.
@tool
extends EditorScenePostImport

func _post_import(scene: Node) -> Object:
	_apply(scene)
	return scene

func _apply(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var base: Material = node.mesh.surface_get_material(surface)
			if base is BaseMaterial3D:
				var material: BaseMaterial3D = base.duplicate()
				material.vertex_color_use_as_albedo = true
				material.vertex_color_is_srgb = false
				node.mesh.surface_set_material(surface, material)
	for child in node.get_children():
		_apply(child)
