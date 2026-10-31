# Shared 3D vehicle resources. Positions and lengths are in metres; +Z is forward.
extends RefCounted

const MODELS := {
	"lada": preload("res://assets/models/vehicles/lada_sedan_v2.glb"),
	"lada_wagon": preload("res://assets/models/vehicles/lada_wagon.glb"),
	"kamaz_semi": preload("res://assets/models/vehicles/truck_kamaz_semi.glb"),
	"zil_flatbed": preload("res://assets/models/vehicles/truck_zil_flatbed.glb"),
	"container_20ft": preload("res://assets/models/vehicles/container_20ft.glb"),
}
# Civilian variants share the GLB; the administration keeps black lacquer.
const VOLGA_PATH := "res://assets/models/vehicles/volga_gaz24.glb"
const VOLGA_SOURCE_LENGTH := 4.905458 # Measured from volga_gaz24.glb.
const LADA_MAP_LENGTH := 4.3
const VOLGA_TRAFFIC_SHARE := 1.0 / 15.0
const VOLGA_PAINT_SHADER := preload("res://assets/shaders/vehicle_paint.gdshader")
const VOLGA_PAINTS := [
	Color(0.76, 0.74, 0.65), # ivory
	Color(0.62, 0.65, 0.65), # grey
	Color(0.31, 0.42, 0.50), # muted blue
	Color(0.34, 0.43, 0.34), # olive green
	Color(0.39, 0.14, 0.16), # burgundy
	Color(0.65, 0.55, 0.40), # beige
]
const PAINT_BLACK := -2 # Only for the Volga: the traffic palette has no black.
const BLACK_PAINT := Color(0.035, 0.035, 0.045)
const LENGTHS := {"lada": 4.37, "lada_wagon": 4.37, "kamaz_semi": 16.5, "zil_flatbed": 7.4, "container_20ft": 6.06}
# Tarpaulins, shipping containers and truck cabs have their own palettes.
const TARP_PAINTS := [
	Color(0.49, 0.48, 0.37), # khaki
	Color(0.24, 0.32, 0.45), # blue
	Color(0.50, 0.50, 0.48), # grey
	Color(0.32, 0.40, 0.28), # green
]
const TRUCK_CAB_PAINTS := [
	Color(0.31, 0.42, 0.29), Color(0.20, 0.33, 0.52), Color(0.62, 0.20, 0.16),
	Color(0.80, 0.60, 0.18), Color(0.55, 0.57, 0.58), Color(0.38, 0.24, 0.16),
]
const CONTAINER_PAINTS := [
	Color(0.60, 0.24, 0.17), Color(0.16, 0.28, 0.45), Color(0.20, 0.38, 0.27),
	Color(0.72, 0.50, 0.17), Color(0.45, 0.47, 0.47), Color(0.52, 0.19, 0.20),
]
# 1990s Russian car paints, none white or black: the ivory body takes the tint.
const PAINTS := [
	Color(0.55, 0.10, 0.14), # cherry
	Color(0.14, 0.32, 0.20), # dark green
	Color(0.12, 0.20, 0.45), # dark blue
	Color(0.45, 0.65, 0.85), # sky blue
	Color(0.82, 0.70, 0.45), # sand
	Color(0.85, 0.68, 0.15), # mustard
	Color(0.42, 0.26, 0.16), # brown
	Color(0.55, 0.57, 0.58), # silver grey
	Color(0.85, 0.42, 0.12), # orange
	Color(0.40, 0.45, 0.20), # olive
	Color(0.75, 0.14, 0.12), # red
	Color(0.55, 0.75, 0.55), # mint
]

static var _paint_materials := {}


static func has_volga_model() -> bool:
	return ResourceLoader.exists(VOLGA_PATH)


# Map length in metres: every car keeps the Lada's 4.37 -> 4.3 scale factor.
static func map_length(model_id: String) -> float:
	if model_id == "volga" and has_volga_model():
		return VOLGA_SOURCE_LENGTH * LADA_MAP_LENGTH / float(LENGTHS["lada"])
	return LADA_MAP_LENGTH


static func _scene(model_id: String) -> PackedScene:
	if model_id == "volga":
		return load(VOLGA_PATH) if has_volga_model() else MODELS["lada"]
	return MODELS[model_id]


static func _source_length(model_id: String) -> float:
	if model_id == "volga":
		return VOLGA_SOURCE_LENGTH if has_volga_model() else float(LENGTHS["lada"])
	return float(LENGTHS[model_id])


# Background traffic: roughly one car in three is the wagon. Same seed, same car.
# The same seed always gives the same car; the Volga share replaces some cars
# without adding any, so the total on the map is unchanged.
# Vehicle class from the district fleet mix to a model. Buses and tractors have no
# model yet and run as cars until they do.
static func model_for_class(vehicle_class: String, seed_value: int) -> String:
	if vehicle_class == "truck":
		return "kamaz_semi" if (abs(seed_value) >> 4) % 3 == 0 else "zil_flatbed"
	return traffic_model(seed_value)


static func traffic_model(seed_value: int) -> String:
	if posmod(hash(seed_value), 15000) < int(VOLGA_TRAFFIC_SHARE * 15000.0):
		return "volga"
	return "lada_wagon" if (abs(seed_value) >> 8) % 3 == 0 else "lada"


static func create(model_id: String, at: Vector3, length: float, axis: String, paint: int = -1) -> Node3D:
	var vehicle: Node3D = _scene(model_id).instantiate()
	vehicle.name = "Lada3D" if model_id == "lada" else model_id.to_pascal_case()
	vehicle.position = at + Vector3.UP * 0.005
	vehicle.rotation.y = PI / 2.0 if axis == "x" else 0.0
	vehicle.scale = Vector3.ONE * (length / _source_length(model_id))
	if model_id == "volga" and has_volga_model():
		if paint >= 0:
			_repaint_volga(vehicle, posmod(hash("%d:volga-paint" % paint), VOLGA_PAINTS.size()))
	elif paint == PAINT_BLACK:
		_repaint(vehicle, PAINT_BLACK)
	elif paint >= 0:
		_repaint(vehicle, paint % PAINTS.size())
	vehicle.add_to_group("vehicle_models")
	vehicle.add_to_group("vehicle_%s" % model_id)
	return vehicle


# Cache one material per civilian body colour, retaining the shared maps.
static func _repaint_volga(vehicle: Node3D, paint: int) -> void:
	for node in vehicle.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		for surface in mesh.mesh.get_surface_count():
			var base: Material = mesh.mesh.surface_get_material(surface)
			if not (base is BaseMaterial3D and "paint" in base.resource_name):
				continue
			var key := "volga|%s|%d" % [base.resource_name, paint]
			if not _paint_materials.has(key):
				var tinted := ShaderMaterial.new()
				tinted.shader = VOLGA_PAINT_SHADER
				tinted.set_shader_parameter("body_atlas", base.albedo_texture)
				tinted.set_shader_parameter("orm_atlas", base.roughness_texture)
				tinted.set_shader_parameter("body_color", VOLGA_PAINTS[paint])
				_paint_materials[key] = tinted
			mesh.set_surface_override_material(surface, _paint_materials[key])


# One shared material per (body part, paint), so many vehicles stay cheap to draw.
static func _repaint(vehicle: Node3D, paint: int) -> void:
	for node in vehicle.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		for surface in mesh.mesh.get_surface_count():
			var base: Material = mesh.mesh.surface_get_material(surface)
			if base is BaseMaterial3D and "paint" in base.resource_name:
				var key := "%s|%d" % [base.resource_name, paint]
				if not _paint_materials.has(key):
					var tinted: BaseMaterial3D = base.duplicate()
					var palette := _palette_for(base.resource_name)
					tinted.albedo_color = BLACK_PAINT if paint == PAINT_BLACK and palette == PAINTS else palette[paint % palette.size()]
					_paint_materials[key] = tinted
				mesh.set_surface_override_material(surface, _paint_materials[key])


static func _palette_for(material_name: String) -> Array:
	if "tarpaulin" in material_name:
		return TARP_PAINTS
	if "Container" in material_name:
		return CONTAINER_PAINTS
	if "KamAZ" in material_name or "ZIL" in material_name:
		return TRUCK_CAB_PAINTS
	return PAINTS
