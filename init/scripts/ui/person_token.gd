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
	# The feet are at the bottom of the stem.
	draw_line(Vector2(CENTER.x, 54), Vector2(CENTER.x, 78), INK, 2.5)
	draw_set_transform(Vector2(CENTER.x, 80), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 11.0, Color(0, 0, 0, 0.4))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var ring := CREAM
	if is_player:
		ring = RED
	if state == "travel" or state == "driving":
		ring = YELLOW
	elif state == "work":
		ring = STEEL
	draw_circle(CENTER, 27.0, INK)
	PortraitDraw.circle(self, CENTER, 23.0, texture, region)
	draw_arc(CENTER, 25.0, 0.0, TAU, 40, ring, 5.0 if is_player else 4.0)
	if state == "work":
		draw_arc(CENTER, 25.0, 0.0, TAU, 40, Color(0.15, 0.15, 0.14), 5.0)
		draw_arc(CENTER, 25.0, -PI / 2.0, -PI / 2.0 + TAU * work_fraction, 40, STEEL, 5.0)

	# Name under the portrait; the player is just "Вы".
	var font := OfficeTheme.BODY_FONT
	var label := "Вы" if is_player else display_name
	draw_string_outline(font, Vector2(-16, 52), label, HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, 4, INK)
	draw_string(font, Vector2(-16, 52), label, HORIZONTAL_ALIGNMENT_CENTER, 96.0, 12, CREAM)

	if eta_text != "":
		var pill := Rect2(Vector2(46, 2), Vector2(58, 20))
		draw_rect(pill, INK)
		draw_string(font, pill.position + Vector2(0, 14), eta_text, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 12, YELLOW)
