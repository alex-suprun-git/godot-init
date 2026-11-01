# A map-wide wear mask: 0 = untouched lawn, 1 = bare trampled earth. Sources register
# worn places by world position while the map is built; `bake()` pushes the result to a
# texture the terrain shader reads. The texture object exists from the start (empty), so
# ground quads built before the sources are known keep a valid reference.
extends RefCounted

const METRES_PER_PIXEL := 1.0

var bounds: Rect2
var texture: ImageTexture
var _size: Vector2i
var _wear: PackedFloat32Array


func _init(world_bounds: Rect2) -> void:
	bounds = world_bounds
	_size = Vector2i(ceili(bounds.size.x / METRES_PER_PIXEL), ceili(bounds.size.y / METRES_PER_PIXEL))
	_wear = PackedFloat32Array()
	_wear.resize(_size.x * _size.y)
	texture = ImageTexture.create_from_image(Image.create_empty(_size.x, _size.y, false, Image.FORMAT_R8))


# Shader parameter: x, z, width, height of the area the texture covers.
func world_rect() -> Vector4:
	return Vector4(bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y)


# Worn disc around a point: full strength at the centre, fading out at `radius`.
func add_disc(center: Vector2, radius: float, strength: float) -> void:
	_paint(Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), func(at: Vector2) -> float:
		return 1.0 - smoothstep(0.0, radius, at.distance_to(center)), strength)


# Wear that hugs the outside of a rectangle (a building's footprint, a path), fading
# out over `reach` metres.
func add_ring(rect: Rect2, reach: float, strength: float) -> void:
	_paint(rect.grow(reach), func(at: Vector2) -> float:
		var dx := maxf(maxf(rect.position.x - at.x, at.x - rect.end.x), 0.0)
		var dy := maxf(maxf(rect.position.y - at.y, at.y - rect.end.y), 0.0)
		return 1.0 - smoothstep(0.0, reach, Vector2(dx, dy).length()), strength)


# Wear along the inside edge of a rectangle (a courtyard's rim), fading toward the middle.
func add_inner_edge(rect: Rect2, reach: float, strength: float) -> void:
	_paint(rect, func(at: Vector2) -> float:
		var depth := minf(minf(at.x - rect.position.x, rect.end.x - at.x), minf(at.y - rect.position.y, rect.end.y - at.y))
		return 1.0 - smoothstep(0.0, reach, depth), strength)


# Uploads the accumulated wear. Call once after the map is built.
func bake() -> void:
	var bytes := PackedByteArray()
	bytes.resize(_wear.size())
	for i in _wear.size():
		bytes[i] = int(clampf(_wear[i], 0.0, 1.0) * 255.0)
	texture.update(Image.create_from_data(_size.x, _size.y, false, Image.FORMAT_R8, bytes))


# Combines sources with max, so overlapping places do not pile up past full wear.
func _paint(area: Rect2, falloff: Callable, strength: float) -> void:
	var from := ((area.position - bounds.position) / METRES_PER_PIXEL).floor()
	var to := ((area.end - bounds.position) / METRES_PER_PIXEL).ceil()
	for y in range(maxi(int(from.y), 0), mini(int(to.y), _size.y)):
		for x in range(maxi(int(from.x), 0), mini(int(to.x), _size.x)):
			var at := bounds.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * METRES_PER_PIXEL
			var value: float = falloff.call(at) * strength
			var index := y * _size.x + x
			if value > _wear[index]:
				_wear[index] = value
