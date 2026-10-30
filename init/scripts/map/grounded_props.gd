# Painted isometric props represented by vertical mesh strips. Each strip's
# opaque bottom contour lies on the ground. Unlike a camera-facing quad, this
# gives the sprite a ground footprint and keeps its wheels above the terrain.
extends RefCounted

var _meshes: Dictionary = {}


func create(texture: Texture2D, width: float, flip: bool, anchor: Vector2, axes: Vector2, view: Dictionary, height_scale: float = 1.0) -> MeshInstance3D:
	var key := "%s:%s:%s:%s:%s:%s" % [texture.resource_path, width, flip, axes, view, height_scale]
	if not _meshes.has(key):
		_meshes[key] = _build(texture, width, flip, anchor, axes, view, height_scale)
	var instance := MeshInstance3D.new()
	instance.mesh = _meshes[key]
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


func _build(texture: Texture2D, width: float, flip: bool, anchor: Vector2, axes: Vector2, view: Dictionary, height_scale: float) -> ArrayMesh:
	var image := texture.get_image()
	var w := image.get_width()
	var h := image.get_height()
	var scale := width / float(w)
	var yaw := deg_to_rad(float(view["yaw"]))
	var elevation := deg_to_rad(float(view["elevation"]))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var forward := Vector3(-sin(yaw), 0, -cos(yaw))
	# Map BOTH measured ground directions to the camera's projected axes.
	# This affine correction preserves vertical edges and never edits the PNG.
	var target := sin(elevation)
	var vertical_scale := 2.0 * target / (axes.x - axes.y)
	var shear := target + vertical_scale * axes.y
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var columns: Array[int] = []
	for x in range(0, w, 4):
		columns.append(x)
	columns.append(w)
	for x in columns:
		# Conservative envelope across adjacent strips avoids clipping at wheels,
		# stairs and other sharp changes in the alpha silhouette.
		var bottom := -1
		for px in range(maxi(0, x - 4), mini(w, x + 5)):
			for py in range(h - 1, -1, -1):
				if image.get_pixel(px, py).a >= 0.5:
					bottom = maxi(bottom, py)
					break
		if bottom < 0:
			bottom = int(anchor.y * h)
		var source_x := (float(x) - anchor.x * w) * scale
		var screen_x := -source_x if flip else source_x
		var ground_y := ((anchor.y * h - bottom - 2.0) * scale) * vertical_scale + shear * source_x
		for py in [0, h]:
			var screen_y: float = ((anchor.y * h - py) * scale) * vertical_scale + shear * source_x
			vertices.append(right * screen_x + forward * (ground_y / sin(elevation)) + Vector3.UP * ((screen_y - ground_y) / cos(elevation)) * height_scale)
			# Painted lighting must not change with the folded strip direction.
			normals.append(Vector3.UP)
			uvs.append(Vector2(float(x) / w, float(py) / h))
	for i in range(columns.size() - 1):
		var a := i * 2
		# Mirroring changes winding; retain the same lit front on both variants.
		if flip:
			indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 2, a + 1, a + 3]))
		else:
			indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 2, a + 3, a + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold = 0.5
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mesh.surface_set_material(0, material)
	return mesh
