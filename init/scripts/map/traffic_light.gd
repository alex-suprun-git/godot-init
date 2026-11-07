# Road and pedestrian fixtures display the junction controller state.
# Shared immutable lens materials keep repeated fixtures cheap.
extends Node3D

const MODEL := preload("res://assets/models/street/traffic_light_v1.glb")
const STATES := ["off", "red", "red_amber", "amber", "green"]
const COLORS := {"red": Color("f7432e"), "amber": Color("ffba32"), "green": Color("41dd83")}
static var _materials := {}

var binding: Dictionary
var signal_state := "off"
var _lenses := {}


func _init(fixture: Dictionary) -> void:
	binding = fixture.duplicate(true)
	name = fixture["id"].replace("/", "_")
	var at: Vector2 = fixture["position"]
	var facing: Vector2 = fixture["facing"]
	position = Vector3(at.x, fixture["surface_height"], at.y)
	rotation.y = atan2(facing.x, facing.y)
	if fixture.get("pedestrian", false):
		_build_walk_head()
		set_signal("red")
		return
	var model := MODEL.instantiate()
	add_child(model)
	for mesh: MeshInstance3D in model.find_children("Lens_*", "MeshInstance3D", true, false):
		_lenses[mesh.name.trim_prefix("Lens_").to_lower()] = mesh
	set_signal("off")


# A lower two-aspect head faces walkers on the opposite curb.
func _build_walk_head() -> void:
	var post := CylinderMesh.new()
	post.top_radius = 0.065
	post.bottom_radius = 0.065
	post.height = 2.2
	post.radial_segments = 8
	_part(post, Vector3.UP * 1.1)
	var box := BoxMesh.new()
	box.size = Vector3(0.38, 0.72, 0.22)
	_part(box, Vector3.UP * 2.15)
	for color in ["red", "green"]:
		var lens := CylinderMesh.new()
		lens.top_radius = 0.125
		lens.bottom_radius = 0.125
		lens.height = 0.035
		lens.radial_segments = 12
		var node := _part(lens, Vector3(0, 2.32 if color == "red" else 1.98, 0.12))
		node.rotation.x = PI * 0.5
		_lenses[color] = node


func _part(mesh: PrimitiveMesh, at: Vector3) -> MeshInstance3D:
	if not _materials.has("housing"):
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color("38403c")
		_materials["housing"] = dark
	mesh.material = _materials["housing"]
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	add_child(node)
	return node


func set_signal(state: String) -> void:
	if state not in STATES:
		push_error("TrafficLight: unknown signal state '%s'" % state)
		return
	signal_state = state
	for color in _lenses:
		var lit: bool = state == color or (state == "red_amber" and color in ["red", "amber"])
		_lenses[color].set_surface_override_material(0, _lens_material(color, lit))


static func _lens_material(color: String, lit: bool) -> StandardMaterial3D:
	var key := color + ("_on" if lit else "_off")
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = COLORS[color] if lit else COLORS[color].darkened(0.78)
		material.roughness = 0.3
		material.emission_enabled = lit
		material.emission = COLORS[color]
		material.emission_energy_multiplier = 2.5 if lit else 0.0
		_materials[key] = material
	return _materials[key]
