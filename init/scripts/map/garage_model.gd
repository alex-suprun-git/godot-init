# One dimensioned garage bay, textured from the new painted single-bay asset.
# UV landmarks remove the source image's camera from the model geometry.
extends RefCounted

const WIDTH := 3.2
const DEPTH := 6.0
const EAVES := 2.5
const RIDGE := 2.9

var _mesh: ArrayMesh


func create(texture: Texture2D, tint: Color) -> MeshInstance3D:
	if _mesh == null:
		_mesh = _build(texture)
	var instance := MeshInstance3D.new()
	instance.mesh = _mesh
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.roughness = 1.0
	instance.material_override = material
	return instance


func _build(texture: Texture2D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(WIDTH / 2, 0, DEPTH / 2)
	var b := Vector3(-WIDTH / 2, 0, DEPTH / 2)
	var c := Vector3(WIDTH / 2, 0, -DEPTH / 2)
	var d := Vector3(-WIDTH / 2, 0, -DEPTH / 2)
	var up := Vector3.UP * EAVES
	var rf := Vector3(0, RIDGE, DEPTH / 2)
	var rb := Vector3(0, RIDGE, -DEPTH / 2)
	var image_size := Vector2(texture.get_width(), texture.get_height())
	_face(st, [a, b, b + up, a + up], [Vector2(854,951), Vector2(1332,796), Vector2(1332,457), Vector2(854,620)], Vector3.BACK, image_size)
	_face(st, [c, a, a + up, c + up], [Vector2(195,578), Vector2(854,951), Vector2(854,620), Vector2(195,278)], Vector3.RIGHT, image_size)
	_face(st, [b, d, d + up, b + up], [Vector2(854,951), Vector2(195,578), Vector2(195,278), Vector2(854,620)], Vector3.LEFT, image_size)
	_face(st, [d, c, c + up, d + up], [Vector2(1332,796), Vector2(854,951), Vector2(854,620), Vector2(1332,457)], Vector3.FORWARD, image_size)
	_face(st, [a + up, rf, rb, c + up], [Vector2(854,620), Vector2(1130,430), Vector2(480,79), Vector2(195,278)], Vector3(0.25,1,0).normalized(), image_size)
	_face(st, [rf, b + up, d + up, rb], [Vector2(1130,430), Vector2(1332,457), Vector2(710,113), Vector2(480,79)], Vector3(-0.25,1,0).normalized(), image_size)
	_face(st, [a + up, b + up, rf], [Vector2(854,620), Vector2(1332,457), Vector2(1130,430)], Vector3.BACK, image_size)
	_face(st, [d + up, c + up, rb], [Vector2(1332,457), Vector2(854,620), Vector2(1130,430)], Vector3.FORWARD, image_size)
	return st.commit()


func _face(st: SurfaceTool, points: Array, pixels: Array, normal: Vector3, image_size: Vector2) -> void:
	var order := [0,1,2] if points.size() == 3 else [0,1,2,0,2,3]
	if (points[1] - points[0]).cross(points[2] - points[0]).dot(normal) > 0:
		order = [0,2,1] if points.size() == 3 else [0,2,1,0,3,2]
	for i in order:
		st.set_normal(normal)
		st.set_uv(pixels[i] / image_size)
		st.add_vertex(points[i])
