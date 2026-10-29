extends Node2D

var elapsed := 0.0
var stars: Array[Vector3] = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7319
	for i in range(150):
		stars.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.5, 1.8)))

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	var bands := 36
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		var color := Color(0.025, 0.035, 0.105).lerp(Color(0.105, 0.035, 0.16), t)
		draw_rect(Rect2(0, size.y * t, size.x, size.y / bands + 2), color)

	var nebula := Vector2(size.x * 0.31, size.y * 0.48)
	draw_circle(nebula, size.y * 0.38, Color(0.18, 0.055, 0.28, 0.15))
	draw_circle(nebula + Vector2(80, -25), size.y * 0.23, Color(0.06, 0.18, 0.34, 0.12))

	for i in range(stars.size()):
		var star := stars[i]
		var twinkle := 0.55 + 0.45 * sin(elapsed * star.z + float(i))
		var point := Vector2(star.x * size.x, star.y * size.y)
		draw_circle(point, 0.7 + star.z * 0.65, Color(0.72, 0.84, 1.0, twinkle))
		if i % 23 == 0:
			draw_line(point - Vector2(4, 0), point + Vector2(4, 0), Color(0.65, 0.8, 1.0, twinkle * 0.55), 1.0)

	var planet := Vector2(size.x * 0.73, size.y * 0.48)
	var radius := size.y * 0.19
	for glow in range(8, 0, -1):
		draw_circle(planet, radius + glow * 8.0, Color(0.28, 0.32, 1.0, 0.018))
	draw_circle(planet, radius, Color(0.23, 0.31, 0.82))
	draw_circle(planet + Vector2(-radius * 0.24, -radius * 0.18), radius * 0.78, Color(0.36, 0.52, 1.0, 0.62))
	draw_circle(planet + Vector2(radius * 0.3, radius * 0.25), radius * 0.76, Color(0.08, 0.11, 0.39, 0.7))
	draw_arc(planet, radius * 1.04, 3.45, 5.9, 80, Color(0.68, 0.78, 1.0, 0.65), 2.0, true)

	draw_set_transform(planet, -0.16, Vector2(1.85, 0.38))
	draw_arc(Vector2.ZERO, radius * 1.43, 0.0, TAU, 120, Color(0.58, 0.78, 1.0, 0.72), 5.0, true)
	draw_arc(Vector2.ZERO, radius * 1.55, 0.0, TAU, 120, Color(0.29, 0.52, 0.95, 0.38), 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var moon := planet + Vector2(cos(elapsed * 0.34) * size.y * 0.31, sin(elapsed * 0.34) * size.y * 0.11)
	draw_circle(moon, 5.5, Color(0.72, 0.87, 1.0))
	draw_circle(moon, 10.0, Color(0.45, 0.68, 1.0, 0.13))

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(40, 48), "ORBITAL  /  07", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.64, 0.79, 1.0))
	draw_string(font, Vector2(40, 78), "THE QUIET SIDE OF SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.42, 0.55, 0.78))
	draw_string(font, Vector2(40, size.y - 34), "WASD  /  ARROWS     —     FLY", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.58, 0.7, 0.9, 0.8))
	draw_string(font, Vector2(40, size.y - 34), "SECTOR  09 ·  41.8 LY", HORIZONTAL_ALIGNMENT_RIGHT, size.x - 80, 12, Color(0.48, 0.57, 0.76, 0.8))
