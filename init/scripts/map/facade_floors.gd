# One wall surface with calibrated source-image rows on exact physical storeys.
# Bands use top-down image coordinates; no raster resampling or extra draw calls.
extends RefCounted

const PANEL_9_BANDS := [
	Vector2(40.0 / 887, 151.0 / 887),
	Vector2(151.0 / 887, 263.0 / 887),
	Vector2(263.0 / 887, 375.0 / 887),
	Vector2(375.0 / 887, 486.0 / 887),
	Vector2(486.0 / 887, 598.0 / 887),
	Vector2(598.0 / 887, 710.0 / 887),
	Vector2(710.0 / 887, 822.0 / 887),
]
# The E2 art has surplus masonry outside each complete window/balcony group.
# Long/end windows have different source positions, but align at floor mid-height.
const E2_LONG_BANDS := [Vector2(0.08, 0.43), Vector2(0.53, 0.88)]
const E2_END_BANDS := [Vector2(0.0, 0.35), Vector2(0.50, 0.85)]


static func mesh(size: Vector2, floors: int, bands: Array) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pitch := size.y / floors
	for floor_index in floors:
		var band: Vector2 = bands[(floors - 1 - floor_index) % bands.size()]
		var bottom := -size.y / 2.0 + floor_index * pitch
		var top := bottom + pitch
		var vertices := [Vector3(-size.x / 2, bottom, 0), Vector3(-size.x / 2, top, 0), Vector3(size.x / 2, top, 0), Vector3(size.x / 2, bottom, 0)]
		var uvs := [Vector2(0, band.y), Vector2(0, band.x), Vector2(1, band.x), Vector2(1, band.y)]
		for index in [0, 1, 2, 0, 2, 3]:
			surface.set_normal(Vector3.BACK)
			surface.set_uv(uvs[index])
			surface.add_vertex(vertices[index])
	surface.generate_tangents()
	return surface.commit()
