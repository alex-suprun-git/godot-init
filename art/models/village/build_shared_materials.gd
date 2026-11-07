# One-off builder for a shared material library from models that were imported with
# per-model embedded textures. Run from the repository root, in two phases:
#   Godot --headless --path init --script res://scripts/dev/build_shared_materials.gd -- --phase=copy
#   Godot --headless --path init --import
#   Godot --headless --path init --script res://scripts/dev/build_shared_materials.gd -- --phase=save
# Phase copy writes one PNG per distinct texture into the library folder (named
# <material_slug>_<slot>.png). Phase save duplicates the imported material of the first model
# that uses each textured material name, points its slots at the shared PNGs and saves
# <material_slug>.tres. The slug rule matches tools/strip_glb_textures.py and
# shared_material_import.gd. Other options: --glob=<prefix> (default frontier_),
# --models=<res folder>, --library=<res folder>.
extends SceneTree

const SLOT_NAMES := {
	BaseMaterial3D.TEXTURE_ALBEDO: "albedo",
	BaseMaterial3D.TEXTURE_METALLIC: "metallic",
	BaseMaterial3D.TEXTURE_ROUGHNESS: "roughness",
	BaseMaterial3D.TEXTURE_EMISSION: "emission",
	BaseMaterial3D.TEXTURE_NORMAL: "normal",
	BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION: "occlusion",
}

var _phase := "copy"
var _prefix := "frontier_"
var _models := "res://assets/models/industrial_sites"
var _library := "res://assets/materials/frontier"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase="):
			_phase = arg.trim_prefix("--phase=")
		elif arg.begins_with("--glob="):
			_prefix = arg.trim_prefix("--glob=")
		elif arg.begins_with("--models="):
			_models = arg.trim_prefix("--models=")
		elif arg.begins_with("--library="):
			_library = arg.trim_prefix("--library=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_library))
	var materials := _collect()
	if _phase == "copy":
		_copy_textures(materials)
	elif _phase == "save":
		_save_materials(materials)
	else:
		push_error("unknown --phase=" + _phase)
		quit(1)
		return
	quit(0)


static func slug(name: String) -> String:
	var out := ""
	for ch in name.to_lower():
		out += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	var parts := out.split("_", false)
	return "_".join(parts)


# Returns {material name: first imported BaseMaterial3D that has any texture}.
func _collect() -> Dictionary:
	var found := {}
	var dir := DirAccess.open(_models)
	var names := PackedStringArray()
	for file in dir.get_files():
		if file.begins_with(_prefix) and file.ends_with(".glb"):
			names.append(file)
	names.sort()
	for file in names:
		var scene: PackedScene = load(_models.path_join(file))
		var root := scene.instantiate()
		_walk(root, found)
		root.free()
	print("scanned ", names.size(), " models, textured materials: ", found.keys())
	return found


func _walk(node: Node, found: Dictionary) -> void:
	if node is MeshInstance3D and node.mesh:
		for surface in node.mesh.get_surface_count():
			var material = node.mesh.surface_get_material(surface)
			if material is BaseMaterial3D and material.resource_name != "" and not found.has(material.resource_name):
				for slot in SLOT_NAMES:
					if material.get_texture(slot) != null:
						found[material.resource_name] = material
						break
	for child in node.get_children():
		_walk(child, found)


func _target_png(material_name: String, slot: int, material: BaseMaterial3D = null) -> String:
	# A packed roughness/metallic map is one source file: store it once, under "roughness".
	if slot == BaseMaterial3D.TEXTURE_METALLIC and material != null:
		var rough: Texture2D = material.get_texture(BaseMaterial3D.TEXTURE_ROUGHNESS)
		var metal: Texture2D = material.get_texture(BaseMaterial3D.TEXTURE_METALLIC)
		if rough != null and metal != null and rough.resource_path == metal.resource_path:
			slot = BaseMaterial3D.TEXTURE_ROUGHNESS
	return _library.path_join("%s_%s.png" % [slug(material_name), SLOT_NAMES[slot]])


func _copy_textures(materials: Dictionary) -> void:
	for material_name in materials:
		var material: BaseMaterial3D = materials[material_name]
		for slot in SLOT_NAMES:
			var texture: Texture2D = material.get_texture(slot)
			if texture == null:
				continue
			var source := texture.resource_path
			if source == "" or not source.ends_with(".png"):
				push_error("%s slot %s has no PNG source: '%s'" % [material_name, SLOT_NAMES[slot], source])
				continue
			var target := _target_png(material_name, slot, material)
			if FileAccess.file_exists(target) and slot == BaseMaterial3D.TEXTURE_METALLIC:
				continue
			var bytes := FileAccess.get_file_as_bytes(source)
			var out := FileAccess.open(target, FileAccess.WRITE)
			out.store_buffer(bytes)
			out.close()
			print("copied ", source.get_file(), " -> ", target)


func _save_materials(materials: Dictionary) -> void:
	for material_name in materials:
		var material: BaseMaterial3D = materials[material_name].duplicate()
		for slot in SLOT_NAMES:
			if material.get_texture(slot) == null:
				continue
			var target := _target_png(material_name, slot, materials[material_name])
			var texture = load(target)
			if texture == null:
				push_error("shared texture not imported yet: " + target)
				quit(1)
				return
			material.set_texture(slot, texture)
		material.resource_name = material_name
		var path := _library.path_join(slug(material_name) + ".tres")
		var error := ResourceSaver.save(material, path)
		print("saved ", path, " (", error_string(error), ")")
