# A compact availability lamp shared by the drawer and assigned-contact strip.
extends Control

var color := Color("4b8356"):
	set(next):
		color = next
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := Vector2(size.x / 2, minf(size.y / 2, 9))
	draw_circle(center, 5, Color(color, 0.16))
	draw_circle(center, 3.2, color)
	draw_circle(center + Vector2(-0.8, -0.8), 1.0, color.lightened(0.45))
