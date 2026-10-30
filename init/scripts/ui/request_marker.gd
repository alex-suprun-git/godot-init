# A request on the map. Its shape tells the type at a glance (circle: plea,
# diamond: conflict, triangle: crisis, square: offer) and the ring around it
# runs down toward the deadline. Drawn in the UI layer, so map lighting never
# dulls it. Text appears only as a tooltip.
extends Control

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const PortraitDraw = preload("res://scripts/ui/portrait_draw.gd")

signal pressed

const BODY := Vector2(64, 74)
const CENTER := Vector2(32, 32)
const INK := OfficeTheme.GRAPHITE
const CREAM := OfficeTheme.PAPER
const AMBER := Color("c39967")
const RED := OfficeTheme.BURGUNDY
const BLUE := Color("729da5")
const STEEL := Color("729da5")
const COLORS := {"plea": CREAM, "conflict": AMBER, "crisis": RED, "offer": BLUE}

var kind := "plea"
var time_left := 1.0 # 1 just appeared, 0 deadline
var assigned := false
var asker_texture: Texture2D # the face of whoever asks, when it is a person
var asker_region := Rect2()
var worker_texture: Texture2D # the face of whoever is on it, when assigned
var worker_region := Rect2()
var work_fraction := 0.0
var edge_direction := Vector2.ZERO # not zero when stuck to the screen edge
var _hover := false
var _time := 0.0


func _ready() -> void:
	custom_minimum_size = BODY
	size = BODY
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _has_point(point: Vector2) -> bool:
	return point.distance_to(CENTER) <= 33.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _draw() -> void:
	# Stem and ground shadow: the tip is the spot on the ground.
	draw_line(Vector2(CENTER.x, 60), Vector2(CENTER.x, 70), INK, 2.0)
	draw_set_transform(Vector2(CENTER.x, 71), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var fill: Color = COLORS[kind]
	if assigned:
		fill = fill.darkened(0.45)
	if kind == "crisis" and not assigned:
		var pulse := fmod(_time, 1.4) / 1.4
		draw_arc(CENTER, 28.0 + pulse * 12.0, 0.0, TAU, 48, Color(RED, 1.0 - pulse), 3.0)

	# Time ring: full when it just appeared, shrinking to the deadline.
	draw_arc(CENTER, 28.0, 0.0, TAU, 48, Color(0.1, 0.1, 0.09, 0.85), 6.0)
	if time_left > 0.0:
		var ring := RED if time_left < 0.25 else (AMBER if not assigned else Color(0.55, 0.52, 0.45))
		draw_arc(CENTER, 28.0, -PI / 2.0, -PI / 2.0 + TAU * time_left, 48, ring, 6.0)

	match kind:
		"plea":
			draw_circle(CENTER, 22.0, fill)
			if asker_texture != null and not assigned:
				PortraitDraw.circle(self, CENTER, 20.0, asker_texture, asker_region)
			else:
				_glyph("?", INK)
			draw_arc(CENTER, 22.0, 0.0, TAU, 40, INK, 2.5)
		"conflict":
			var diamond := PackedVector2Array([CENTER + Vector2(0, -25), CENTER + Vector2(25, 0), CENTER + Vector2(0, 25), CENTER + Vector2(-25, 0)])
			draw_colored_polygon(diamond, fill)
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), CREAM, 3.0)
			draw_line(CENTER + Vector2(-8, -8), CENTER + Vector2(8, 8), INK, 4.0)
			draw_line(CENTER + Vector2(8, -8), CENTER + Vector2(-8, 8), INK, 4.0)
		"crisis":
			var triangle := PackedVector2Array([CENTER + Vector2(0, -27), CENTER + Vector2(28, 21), CENTER + Vector2(-28, 21)])
			draw_colored_polygon(triangle, fill)
			draw_polyline(triangle + PackedVector2Array([triangle[0]]), CREAM, 3.0)
			_glyph("!", CREAM, 8.0)
		"offer":
			var square := Rect2(CENTER - Vector2(19, 19), Vector2(38, 38))
			draw_rect(square, fill)
			draw_rect(square, CREAM, false, 3.0)
			_glyph("₽", CREAM)
	if _hover:
		draw_arc(CENTER, 33.0, 0.0, TAU, 48, CREAM, 2.0)

	# Who is on it: a small face badge with a progress ring.
	if assigned and worker_texture != null:
		var badge := CENTER + Vector2(22, 22)
		draw_circle(badge, 15.0, INK)
		PortraitDraw.circle(self, badge, 12.0, worker_texture, worker_region)
		draw_arc(badge, 14.0, 0.0, TAU, 32, Color(0.2, 0.2, 0.2), 3.0)
		draw_arc(badge, 14.0, -PI / 2.0, -PI / 2.0 + TAU * work_fraction, 32, STEEL, 3.0)

	# Stuck to the edge: an arrow showing which way it really is.
	if edge_direction != Vector2.ZERO:
		var tip := CENTER + edge_direction * 46.0
		var side := edge_direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([tip + edge_direction * 6.0, tip + side * 8.0, tip - side * 8.0]), CREAM)


func _glyph(text: String, color: Color, lift: float = 0.0) -> void:
	var font := OfficeTheme.BODY_FONT
	draw_string(font, CENTER + Vector2(-20, 8.0 - lift), text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 24, color)
