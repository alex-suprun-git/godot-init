# Paper request marker: a portrait (requester or assigned worker), a small
# printed type symbol and a thin deadline/work line. No mixed frame shapes.
extends Control

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const OfficeIcons = preload("res://scripts/ui/office_icons.gd")

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
var show_deadline := true
var asker_texture: Texture2D # the face of whoever asks, when it is a person
var asker_region := Rect2()
var worker_texture: Texture2D # the face of whoever is on it, when assigned
var worker_region := Rect2()
var work_fraction := 0.0
var edge_direction := Vector2.ZERO # not zero when stuck to the screen edge
var _quest_icon: Texture2D
var _quest_badge: Texture2D
var _hover := false
var _time := 0.0


func _ready() -> void:
	_quest_icon = OfficeIcons.quest_texture(kind, 64)
	_quest_badge = OfficeIcons.quest_texture(kind, 36)
	custom_minimum_size = BODY
	size = BODY
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _has_point(point: Vector2) -> bool:
	return Rect2(CENTER - Vector2(27, 29), Vector2(54, 58)).has_point(point)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()


func _draw() -> void:
	# One paper/photo language for open requests and assigned people.
	# Type is a small printed corner symbol; progress never surrounds the photo.
	draw_line(Vector2(32, 57), Vector2(32, 70), INK, 2)
	draw_line(Vector2(32, 57), Vector2(32, 70), CREAM, 1)
	draw_circle(Vector2(32, 71), 3, CREAM)
	var frame := Rect2(CENTER - Vector2(23, 25), Vector2(46, 50))
	draw_rect(Rect2(frame.position + Vector2(2, 2), frame.size), Color(0, 0, 0, 0.24))
	draw_rect(frame, CREAM)
	draw_rect(frame, OfficeTheme.EDGE, false, 1.5)
	var portrait: Texture2D = worker_texture if assigned and worker_texture != null else asker_texture
	var crop := worker_region if assigned and worker_texture != null else asker_region
	if portrait != null:
		draw_texture_rect_region(portrait, Rect2(CENTER - Vector2(20, 22), Vector2(40, 40)), crop)
	else:
		draw_texture_rect(_quest_icon, Rect2(CENTER - Vector2(14, 14), Vector2(28, 28)), false, RED if kind == "crisis" else INK)
	if portrait != null:
		var badge := Rect2(CENTER + Vector2(11, -30), Vector2(18, 18))
		draw_rect(badge.grow(1), CREAM)
		draw_texture_rect(_quest_badge, badge.grow(-1), false, RED if kind == "crisis" else INK)
	if assigned or show_deadline:
		var fraction := clampf(work_fraction if assigned else time_left, 0, 1)
		var line := Rect2(frame.position + Vector2(3, 45), Vector2(40, 3))
		draw_rect(line, OfficeTheme.EDGE)
		draw_rect(Rect2(line.position, Vector2(40 * fraction, 3)), RED if assigned or time_left < 0.25 else AMBER)
	if _hover:
		draw_rect(frame.grow(2), CREAM, false, 1.5)
	if kind == "crisis" and not assigned and show_deadline:
		var pulse := fmod(_time, 1.4) / 1.4
		draw_rect(frame.grow(2 + pulse * 5), Color(RED, 0.6 * (1 - pulse)), false, 1.5)
	if edge_direction != Vector2.ZERO:
		var tip := CENTER + edge_direction * 42
		var side := edge_direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([tip + edge_direction * 6, tip + side * 6, tip - side * 6]), CREAM)
