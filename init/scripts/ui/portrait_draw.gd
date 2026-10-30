# Draws a round crop of a portrait onto any CanvasItem. A polygon with UVs does
# the clipping, so no shader or mask node is needed.
extends RefCounted


static func circle(canvas: CanvasItem, center: Vector2, radius: float, texture: Texture2D, region: Rect2) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var texture_size := texture.get_size()
	for i in 40:
		var angle := TAU * i / 40.0
		var unit := Vector2(cos(angle), sin(angle))
		points.append(center + unit * radius)
		uvs.append((region.position + (unit * 0.5 + Vector2(0.5, 0.5)) * region.size) / texture_size)
	canvas.draw_colored_polygon(points, Color.WHITE, uvs, texture)
