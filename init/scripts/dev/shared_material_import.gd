# Import script for models that share their textured materials (see
# tools/strip_glb_textures.py). The GLB keeps only material names; this script replaces
# each textured material by the shared one from the library, matched by name slug.
# Set it as import_script/path in the model's .import file.
@tool
extends EditorScenePostImport

const LIBRARY := "res://assets/materials/frontier/"


func _post_import(scene: Node) -> Object:
	_apply(scene)
	return scene


static func slug(name: String) -> String:
	var out := ""
	for ch in name.to_lower():
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	return "_".join(out.split("_", false))


func _apply(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for surface in node.mesh.get_surface_count():
			var material: Material = node.mesh.surface_get_material(surface)
			if material == null or material.resource_name == "":
				continue
			var path := LIBRARY + slug(material.resource_name) + ".tres"
			if ResourceLoader.exists(path):
				node.mesh.surface_set_material(surface, load(path))
	for child in node.get_children():
		_apply(child)
