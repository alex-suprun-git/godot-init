# World-anchored haze that hides the map edges: one full-screen quad whose
# shader fades the picture outside MapBoundaries.INNER.
extends Node3D

const Boundaries := preload("res://scripts/data/map_boundaries.gd")
const SHADER := preload("res://assets/shaders/map_edge_haze.gdshader")

var _material: ShaderMaterial


func _ready() -> void:
	for problem in Boundaries.validate():
		push_warning("map boundaries: " + problem)
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.render_priority = 100
	var inner := Boundaries.INNER
	_material.set_shader_parameter("inner", Vector4(inner.position.x, inner.position.y, inner.end.x, inner.end.y))
	var fade: Dictionary = Boundaries.FADE
	_material.set_shader_parameter("fade", Vector4(fade["w"], fade["n"], fade["e"], fade["s"]))
	_material.set_shader_parameter("noise_amp", Boundaries.NOISE_AMP)
	_material.set_shader_parameter("noise_scale", Boundaries.NOISE_SCALE)
	_material.set_shader_parameter("debug_stripes", OS.get_cmdline_user_args().has("--haze-stripes"))
	var instance := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	instance.mesh = quad
	instance.material_override = _material
	instance.extra_cull_margin = 16384.0
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)


func set_haze_color(color: Color) -> void:
	if _material != null:
		_material.set_shader_parameter("haze_color", color)
