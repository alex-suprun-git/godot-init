# Shared-material post-import for the church ensemble (see tools/strip_glb_textures.py).
@tool
extends EditorScenePostImport
const LIBRARY := "res://assets/materials/church_ensemble/"

func _post_import(scene: Node) -> Object:
	_apply(scene)
	return scene

static func slug(name: String) -> String:
	var out := ""
	for ch in name.to_lower():
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	return "_".join(out.split("_",false))

func _apply(node: Node) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var material = node.mesh.surface_get_material(i)
			if material == null or material.resource_name == "":
				continue
			var path := LIBRARY+slug(material.resource_name)+".tres"
			if ResourceLoader.exists(path):
				node.mesh.surface_set_material(i,load(path))
	for child in node.get_children():
		_apply(child)
