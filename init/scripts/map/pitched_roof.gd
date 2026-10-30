extends RefCounted


static func create(size: Vector2, rise: float, texture: Texture2D) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-size.x / 2, 0, size.y / 2)
	var b := Vector3(size.x / 2, 0, size.y / 2)
	var c := Vector3(-size.x / 2, 0, -size.y / 2)
	var d := Vector3(size.x / 2, 0, -size.y / 2)
	var left := Vector3(-size.x / 2, rise, 0)
	var right := Vector3(size.x / 2, rise, 0)
	var u := size.x / 8.0
	var v := Vector2(size.y / 2, rise).length() / 8.0
	_face(st, [a,b,right,left], [Vector2(0,v),Vector2(u,v),Vector2(u,0),Vector2.ZERO], Vector3(0,size.y / 2,rise).normalized())
	_face(st, [d,c,left,right], [Vector2(u,v),Vector2(0,v),Vector2.ZERO,Vector2(u,0)], Vector3(0,size.y / 2,-rise).normalized())
	_face(st, [b,d,right], [Vector2.ZERO,Vector2(1,0),Vector2(0.5,1)], Vector3.RIGHT)
	_face(st, [c,a,left], [Vector2.ZERO,Vector2(1,0),Vector2(0.5,1)], Vector3.LEFT)
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 1.0
	instance.material_override = material
	return instance


static func _face(st: SurfaceTool, points: Array, uvs: Array, normal: Vector3) -> void:
	var order := [0,1,2] if points.size() == 3 else [0,1,2,0,2,3]
	if (points[1] - points[0]).cross(points[2] - points[0]).dot(normal) > 0:
		order = [0,2,1] if points.size() == 3 else [0,2,1,0,3,2]
	for i in order:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(points[i])
