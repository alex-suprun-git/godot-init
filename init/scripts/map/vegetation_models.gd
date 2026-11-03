# Shared original civic vegetation, reused throughout the district.
extends RefCounted

const Settings = preload("res://scripts/data/settings.gd")
const SHADER = preload("res://assets/shaders/civic_foliage.gdshader")
const SCENES := {
	"park_deciduous_tree": preload("res://assets/models/civic_center/park_deciduous_tree.glb"),
	"park_poplar": preload("res://assets/models/civic_center/park_poplar.glb"),
	"park_conifer": preload("res://assets/models/civic_center/park_conifer.glb"),
	"park_shrub": preload("res://assets/models/civic_center/park_shrub.glb"),
}
const HEIGHTS := {"park_deciduous_tree": 11.170676, "park_poplar": 15.597872}
static var _materials: Dictionary = {}


static func create(id: String, at: Vector3) -> Node3D:
	var node: Node3D = SCENES[id].instantiate()
	node.position = at
	var evergreen := id == "park_conifer"
	var key := Settings.season + ":" + id
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = SHADER
		if Settings.season == "autumn" and not evergreen:
			material.set_shader_parameter("season_tint", Color(1.8, 1.15, 0.55))
		elif Settings.season == "autumn":
			material.set_shader_parameter("colour_saturation", 0.45)
			material.set_shader_parameter("season_tint", Color(1.03, 0.96, 0.78))
		elif Settings.season == "winter":
			material.set_shader_parameter("season_tint", Color(0.85, 0.95, 0.95))
			if evergreen:
				material.set_shader_parameter("colour_saturation", 0.6)
				material.set_shader_parameter("tonal_detail", 0.25)
				material.set_shader_parameter("snow_amount", 0.55)
		_materials[key] = material
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		if not str(mesh.name).begins_with("Foliage"):
			continue
		if Settings.season == "winter" and not evergreen:
			mesh.hide()
		else:
			mesh.material_override = _materials[key]
	return node
