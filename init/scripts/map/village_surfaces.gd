# Rural ground and compacted aggregate lanes; navigation retains the dirt-road kind.
extends RefCounted
const Settings = preload("res://scripts/data/settings.gd")
const Layout = preload("res://scripts/data/district_layout.gd")
const GRASS = preload("res://assets/models/village/rural_grass.png")
const GRAVEL = preload("res://assets/models/village/compacted_gravel.png")
const SOIL = preload("res://assets/models/village/garden_soil.png")

static func ground(map, rect: Rect2, height: float, soft := .0) -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/village_ground.gdshader")
	material.set_shader_parameter("rural_texture",GRASS)
	material.set_shader_parameter("shared_texture",map._season["grass"])
	material.set_shader_parameter("soil_texture",SOIL)
	material.set_shader_parameter("winter",Settings.season == "winter")
	material.set_shader_parameter("seasonal_tint",map._season["grass_tint"])
	material.set_shader_parameter("quad_size",rect.size)
	material.set_shader_parameter("edge_metres",soft)
	material.set_shader_parameter("wear_mask",map.wear.texture)
	material.set_shader_parameter("wear_rect",map.wear.world_rect())
	_quad(map,rect,height,material,"RuralGround")

static func road(map, rect: Rect2, height := .14, tracks := true) -> void:
	_quad(map,rect,height,path_material(map,rect,tracks),"CompactedGravelLane")

static func path_material(map, rect := Rect2(), tracks := false, soil_blend := .0) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/village_gravel.gdshader")
	material.set_shader_parameter("gravel_texture",GRAVEL)
	material.set_shader_parameter("grass_texture",GRASS)
	material.set_shader_parameter("snow_texture",map._season["dirt"])
	material.set_shader_parameter("winter",Settings.season == "winter")
	material.set_shader_parameter("grass_tint",map._season["grass_tint"])
	material.set_shader_parameter("along_x",rect.size.x > rect.size.y)
	material.set_shader_parameter("quad_size",rect.size)
	material.set_shader_parameter("traffic_tracks",tracks)
	material.set_shader_parameter("polygon_surface",rect.size == Vector2.ZERO)
	material.set_shader_parameter("soil_mix",soil_blend)
	var junctions := PackedVector4Array()
	if tracks:
		for road_data in Layout.ROADS:
			var other: Rect2 = road_data["rect"]
			if road_data["kind"] != "dirt" or other == rect or not rect.intersects(other):
				continue
			var overlap := rect.intersection(other)
			junctions.append(Vector4(overlap.get_center().x,overlap.get_center().y,overlap.size.x,overlap.size.y))
	material.set_shader_parameter("junction_count",mini(junctions.size(),12))
	while junctions.size() < 12:
		junctions.append(Vector4.ZERO)
	material.set_shader_parameter("junction_rects",junctions)
	return material

static func _quad(map, rect: Rect2, height: float, material: Material, label: String) -> void:
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	node.rotation.x = -PI/2.0
	node.position = Vector3(rect.get_center().x,height,rect.get_center().y)
	map.add_child(node)
