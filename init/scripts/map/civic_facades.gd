# Facade modules for the civic buildings; dimensions stay in metres.
extends RefCounted


static func tower(map, group: Node3D, size: Vector2, height: float, variant: String, tint: Color) -> void:
	var prefix := "res://assets/textures/facade_tower_"
	var long_wall: Texture2D = load(prefix + "long_" + variant + ".png")
	var end_wall: Texture2D = load(prefix + "end_" + variant + ".png")
	var crown: Texture2D = load(prefix + "crown_" + variant + ".png")
	var middle_height := height - 6.0
	# One ground floor, repeated two-storey wall modules, one top storey.
	for face in [
		[size.x, Vector3(0, 0, size.y / 2.0 + 0.015), 0.0, long_wall],
		[size.x, Vector3(0, 0, -size.y / 2.0 - 0.015), PI, long_wall],
		[size.y, Vector3(size.x / 2.0 + 0.015, 0, 0), PI / 2.0, end_wall],
		[size.y, Vector3(-size.x / 2.0 - 0.015, 0, 0), -PI / 2.0, end_wall],
	]:
		var width: float = face[0]
		var origin: Vector3 = face[1]
		var yaw: float = face[2]
		_wall(map, group, Vector2(width, middle_height), origin + Vector3.UP * (3.0 + middle_height / 2.0), yaw, face[3], Vector2(width / 12.0, middle_height / 6.0), tint, Vector2.ZERO, Vector2.ONE)
		_wall(map, group, Vector2(width, 3.0), origin + Vector3.UP * 1.5, yaw, face[3], Vector2(width / 12.0, 0.5), tint)
		_wall(map, group, Vector2(width, 3.0), origin + Vector3.UP * (height - 1.5), yaw, crown, Vector2(width / 6.0, 1.0), tint)
	var shop: Texture2D = load(prefix + "shop_" + variant + ".png")
	var entrance: Texture2D = load(prefix + "entrance_" + variant + ".png")
	# The residential entrance occupies the first 6 m bay; three shop bays follow.
	for bay in int(size.x / 6.0):
		var x := -size.x / 2.0 + 3.0 + bay * 6.0
		_wall(map, group, Vector2(6, 3), Vector3(x, 1.5, size.y / 2.0 + 0.035), 0.0, entrance if bay == 0 else shop, Vector2.ONE, tint)


static func civic(map, group: Node3D, size: Vector2, height: float, center: Texture2D, wing: Texture2D, center_width: float, tint: Color) -> void:
	var tile_width := height * 2.0
	# Rear and side walls use their own continuous wing rhythm.
	for face in [
		[size.x, Vector3(0, height / 2.0, -size.y / 2.0 - 0.015), PI],
		[size.y, Vector3(size.x / 2.0 + 0.015, height / 2.0, 0), PI / 2.0],
		[size.y, Vector3(-size.x / 2.0 - 0.015, height / 2.0, 0), -PI / 2.0],
	]:
		_wall(map, group, Vector2(face[0], height), face[1], face[2], wing, Vector2(face[0] / tile_width, 1), tint)
	_wall(map, group, Vector2(center_width, height), Vector3(0, height / 2.0, size.y / 2.0 + 0.015), 0, center, Vector2.ONE, tint)
	# Clip the outer wing fragments using UVs, never stretch a full tile into a short wall.
	var fragment := (size.x - center_width) / 2.0
	if fragment > 0.0:
		_wall(map, group, Vector2(fragment, height), Vector3(-(center_width + fragment) / 2.0, height / 2.0, size.y / 2.0 + 0.015), 0, wing, Vector2(fragment / tile_width, 1), tint, Vector2(1.0 - fragment / tile_width, 0))
		_wall(map, group, Vector2(fragment, height), Vector3((center_width + fragment) / 2.0, height / 2.0, size.y / 2.0 + 0.015), 0, wing, Vector2(fragment / tile_width, 1), tint)


static func _wall(map, group: Node3D, size: Vector2, at: Vector3, yaw: float, texture: Texture2D, repeats: Vector2, tint: Color, offset := Vector2.ZERO, seam_axes := Vector2.ZERO) -> void:
	map._facade(size, at, yaw, texture, repeats, tint, group, offset, true, seam_axes)
