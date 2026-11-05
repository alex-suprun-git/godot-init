# A person standing on the map: a round portrait on a stem, with a ring that
# shows what they are doing (red: you, white: free, yellow: on the way,
# blue: working with a progress arc). Drawn in the UI layer so it stays sharp
# and readable whatever the map lighting does.
extends Control

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const PortraitDraw = preload("res://scripts/ui/portrait_draw.gd")

const BODY := Vector2(64, 86)
const CENTER := Vector2(32, 30)
const INK := OfficeTheme.GRAPHITE
const CREAM := OfficeTheme.PAPER
const RED := OfficeTheme.BURGUNDY
const YELLOW := Color("c39967")
const STEEL := Color("729da5")

var display_name := ""
var texture: Texture2D
var region := Rect2()
var is_player := false
var state := "idle" # idle | travel | work | driving
var work_fraction := 0.0
var eta_text := ""


func _ready() -> void:
	custom_minimum_size = BODY
	size = BODY
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# The reference point is unchanged: feet at (32, 80), including zoom scaling.
	draw_line(Vector2(32, 63), Vector2(32, 78), INK, 3)
	draw_line(Vector2(32, 63), Vector2(32, 78), CREAM, 1.3)
	draw_circle(Vector2(32, 80), 3, CREAM)
	var frame := Rect2(7, 0, 50, 54)
	draw_rect(Rect2(frame.position + Vector2(2, 3), frame.size), Color(0, 0, 0, 0.25))
	draw_rect(frame, RED if is_player else Color("b9a58a"))
	draw_rect(frame.grow(-2), CREAM)
	if texture != null:
		draw_texture_rect_region(texture, Rect2(11, 4, 42, 42), region)
	var activity := YELLOW if state in ["travel", "driving"] else STEEL
	if state in ["work", "paperwork"]:
		draw_rect(Rect2(11, 47, 42, 3), INK)
		draw_rect(Rect2(11, 47, 42 * clampf(work_fraction, 0, 1), 3), activity)
	elif state in ["travel", "driving"]:
		draw_rect(Rect2(11, 47, 42, 3), activity)
	var font := OfficeTheme.BODY_FONT
	var label := "Вы" if is_player else display_name
	var width := minf(90, font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12)
	var plate := Rect2(32 - width / 2, 51, width, 19)
	draw_rect(Rect2(plate.position + Vector2(1, 2), plate.size), Color(0, 0, 0, 0.22))
	draw_rect(plate, CREAM)
	draw_rect(plate, RED if is_player else Color("baa18b"), false, 1.5)
	draw_string(font, plate.position + Vector2(2, 14), label, HORIZONTAL_ALIGNMENT_CENTER, width - 4, 12, INK)
	if eta_text != "":
		var note := Rect2(3, -24, 58, 20)
		draw_rect(note, RED if is_player else INK)
		draw_string(font, note.position + Vector2(0, 14), eta_text, HORIZONTAL_ALIGNMENT_CENTER, 58, 12, CREAM)
