# Small printed progress marks, without ProgressBar's font/theme minimum size.
extends Control

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")

var value: float = 0.0:
	set(next):
		value = next
		queue_redraw()
var max_value: float = 100.0:
	set(next):
		max_value = maxf(next, 0.001)
		queue_redraw()
var segments := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)


func _draw() -> void:
	var fraction := clampf(value / max_value, 0, 1)
	if segments > 0:
		var step := size.x / segments
		for index in segments:
			var tick := Rect2(index * step, 2, maxf(2, step - 4), 6)
			draw_rect(tick, OfficeTheme.EDGE, false, 1)
			var filled := clampf(fraction * segments - index, 0, 1)
			if filled > 0:
				draw_rect(Rect2(tick.position, Vector2(tick.size.x * filled, tick.size.y)), OfficeTheme.BURGUNDY)
	else:
		var line := Rect2(0, 0, size.x, minf(3, size.y))
		draw_rect(line, OfficeTheme.EDGE)
		draw_rect(Rect2(line.position, Vector2(line.size.x * fraction, line.size.y)), OfficeTheme.BURGUNDY)
