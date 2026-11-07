# One-off: build the shared church material library from the models as currently imported
# (textures still extracted next to each GLB). Run after the 12 base maps exist in
# init/assets/materials/church_ensemble/ and have been imported:
#   Godot --headless --path init --script res://../art/models/church_ensemble/build_shared_materials.gd
# For every textured material name it duplicates the first imported material, points its
# slots at the shared base maps (matched by file content, so no per-model copy is needed) and
# saves <material_slug>.tres. Afterwards run tools/strip_glb_textures.py on the GLBs.
extends SceneTree

const MODELS := "res://assets/models/church_ensemble/"
const LIBRARY := "res://assets/materials/church_ensemble/"
# Godot's glTF importer also fills the metallic slot with the packed roughness/metallic map.
const SLOTS := [
	BaseMaterial3D.TEXTURE_ALBEDO,
	BaseMaterial3D.TEXTURE_NORMAL,
	BaseMaterial3D.TEXTURE_ROUGHNESS,
	BaseMaterial3D.TEXTURE_METALLIC,
]

func _initialize() -> void:
	var by_content := {}
	for file in DirAccess.get_files_at(LIBRARY):
		if file.ends_with(".png"):
			by_content[FileAccess.get_md5(LIBRARY + file)] = LIBRARY + file
	var found := {}
	for file in DirAccess.get_files_at(MODELS):
		if file.ends_with(".glb"):
			var root: Node = (load(MODELS + file) as PackedScene).instantiate()
			_walk(root, found)
			root.free()
	for material_name in found:
		var material: BaseMaterial3D = found[material_name].duplicate()
		for slot in SLOTS:
			var texture: Texture2D = material.get_texture(slot)
			if texture == null:
				continue
			var key := FileAccess.get_md5(texture.resource_path)
			if not by_content.has(key):
				push_error("%s: no shared map matches %s" % [material_name, texture.resource_path])
				quit(1)
				return
			material.set_texture(slot, load(by_content[key]))
		for slot in [BaseMaterial3D.TEXTURE_EMISSION, BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION]:
			if material.get_texture(slot) != null:
				push_error("%s: unexpected texture in slot %d" % [material_name, slot])
				quit(1)
				return
		material.resource_name = material_name
		var path := LIBRARY + _slug(material_name) + ".tres"
		print("saved ", path, " (", error_string(ResourceSaver.save(material, path)), ")")
	quit(0)

static func _slug(name: String) -> String:
	var out := ""
	for ch in name.to_lower():
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	return "_".join(out.split("_", false))

func _walk(node: Node, found: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var material = node.mesh.surface_get_material(i)
			if material is BaseMaterial3D and material.resource_name != "" and not found.has(material.resource_name):
				for slot in SLOTS:
					if material.get_texture(slot) != null:
						found[material.resource_name] = material
						break
	for child in node.get_children():
		_walk(child, found)
