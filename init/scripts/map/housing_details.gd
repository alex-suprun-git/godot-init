extends RefCounted

# Positions are local to each panel building, in metres. Dish z is the face sign.
const SAND := Color(1.08, 1.02, 0.91)
const CLAY := Color(1.09, 0.99, 0.94)
const SAGE := Color(0.96, 1.03, 0.96)
const COOL := Color(0.99, 1.03, 1.08)
const GREY := Color(1.02, 1.01, 0.99)
const BLOCKS := {
	"b1_n": {"tint": Color(1.13, 1.03, 0.86), "aerials": [Vector3(-28, 3.1, 0.4), Vector3(16, 2.4, 0.9)], "dishes": [Vector3(6, 7.7, 1), Vector3(27, 10.8, 1)]},
	"b1_s": {"tint": Color(1.00, 1.07, 1.12), "aerials": [Vector3(-28, 3.3, 1.1), Vector3(1, 2.5, 0.2), Vector3(22, 2.9, -0.7)], "dishes": [Vector3(-24, 13.7, -1), Vector3(6, 19.8, -1), Vector3(27, 16.7, -1)], "mural": true},
	"b1_w": {"tint": Color(1.14, 0.98, 0.90), "aerials": [Vector3(-22, 2.7, 0.8)], "dishes": [Vector3(19, 10.7, 1)]},
	"b1_e": {"tint": Color(0.93, 1.03, 0.93), "aerials": [Vector3(3, 3.0, -0.8), Vector3(27, 2.3, 0.5)], "dishes": [Vector3(15, 10.7, -1)]},
	"a1_n": {"tint": SAGE, "aerials": [Vector3(-24, 2.8, 0.3)], "dishes": [Vector3(14, 10.7, 1)]},
	"a1_s": {"tint": SAND, "aerials": [Vector3(9, 2.4, 0.9), Vector3(32, 2.8, -0.5)]},
	"a1_w": {"tint": COOL, "aerials": [Vector3(-30, 2.9, 0.4), Vector3(12, 2.4, -0.8)], "dishes": [Vector3(4, 16.7, 1)]},
	"a1_e": {"tint": GREY, "aerials": [Vector3(23, 2.5, 0.9)]},
	"a2_n": {"tint": CLAY, "aerials": [Vector3(-24, 3.1, 0.6), Vector3(20, 2.5, -0.6)], "dishes": [Vector3(-22, 13.7, 1), Vector3(10, 19.7, 1)]},
	"a2_s": {"tint": COOL, "aerials": [Vector3(-5, 2.7, 0.6)]},
	"a2_w": {"tint": SAND, "aerials": [Vector3(28, 2.5, -0.8)], "dishes": [Vector3(-21, 7.7, 1)]},
	"a2_e": {"tint": SAGE, "aerials": [Vector3(-24, 2.6, 0.9), Vector3(6, 3.0, -0.8)]},
	"b2_n": {"tint": GREY, "aerials": [Vector3(28, 2.7, 0.4)]},
	"b2_s": {"tint": CLAY, "aerials": [Vector3(-26, 2.8, 0.3), Vector3(12, 2.4, -0.7)], "dishes": [Vector3(20, 10.7, -1)]},
	"b2_w": {"tint": COOL, "aerials": [Vector3(6, 2.6, 0.4)], "dishes": [Vector3(-24, 19.7, 1)]},
	"west_1_w": {"tint": CLAY, "aerials": [Vector3(22, 2.6, 0.7)]},
	"west_1_e": {"tint": GREY, "aerials": [Vector3(-26, 2.9, 0.6), Vector3(19, 2.5, -0.9)], "dishes": [Vector3(9, 16.7, -1)]},
	"west_2_w": {"tint": SAGE, "aerials": [Vector3(-23, 2.9, -0.5), Vector3(27, 2.4, 0.8)], "dishes": [Vector3(-5, 13.7, 1)]},
	"west_2_e": {"tint": SAND, "aerials": [Vector3(5, 2.5, 0.6)]},
	"west_3_w": {"tint": GREY, "aerials": [Vector3(-25, 2.5, 0.7)]},
	"west_3_e": {"tint": COOL, "aerials": [Vector3(-9, 2.8, 0.5), Vector3(25, 2.5, -0.5)], "dishes": [Vector3(16, 19.7, -1)]},
	"south_1": {"tint": SAND, "aerials": [Vector3(8, 2.4, 0.7)]},
	"south_2": {"tint": SAGE, "aerials": [Vector3(-27, 2.9, 0.4), Vector3(26, 2.5, -0.6)], "dishes": [Vector3(-8, 10.7, -1)]},
	"south_3": {"tint": GREY, "aerials": [Vector3(-4, 2.6, 0.5)]},
}
const MURAL = preload("res://assets/textures/housing_river_mural.svg")
const BRACKET := Color("626864")
static var _dish_mesh: ArrayMesh


static func build(map, parent: Node3D, size: Vector2, height: float, detail: Dictionary) -> void:
	for mount: Vector3 in detail.get("dishes", []):
		var dish := Node3D.new()
		dish.name = "BalconyDish"
		dish.position = Vector3(mount.x, mount.y, mount.z * size.y / 2.0)
		dish.rotation.y = 0.24 if mount.z > 0.0 else PI - 0.24
		parent.add_child(dish)
		map._box(Vector3(0.11, 0.30, 0.55), Vector3(0, -0.22, 0.23), BRACKET, dish)
		var bowl := MeshInstance3D.new()
		bowl.mesh = _dish()
		bowl.position = Vector3(0, 0.12, 0.54)
		bowl.rotation.x = -0.30
		dish.add_child(bowl)
		map._box(Vector3(0.055, 0.055, 0.41), Vector3(0, -0.13, 0.73), BRACKET, dish)
	if detail.get("mural", false):
		var surface := QuadMesh.new()
		surface.size = Vector2(size.y, height)
		var paint := StandardMaterial3D.new()
		paint.albedo_texture = MURAL
		paint.roughness = 0.96
		paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		var mural := MeshInstance3D.new()
		mural.name = "RiverMural"
		mural.mesh = surface
		mural.material_override = paint
		mural.rotation.y = -PI / 2.0
		mural.position = Vector3(-size.x / 2.0 - 0.026, height / 2.0, 0)
		mural.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mural)


static func _dish() -> ArrayMesh:
	if _dish_mesh != null:
		return _dish_mesh
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 16:
		var a := i * TAU / 16.0
		var b := (i + 1) * TAU / 16.0
		for vertex in [Vector3.ZERO, Vector3(0.53 * cos(b), 0.58 * sin(b), 0.17), Vector3(0.53 * cos(a), 0.58 * sin(a), 0.17)]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var enamel := StandardMaterial3D.new()
	enamel.albedo_color = Color("d2cec0")
	enamel.roughness = 0.72
	enamel.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(enamel)
	_dish_mesh = surface.commit()
	return _dish_mesh
