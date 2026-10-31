# Dashed lines with arrowheads from people on the way to where they are going.
# The HUD sets `paths` every frame; this layer only draws and never takes input.
extends Control

const YELLOW := Color(0.98, 0.78, 0.46)
const INK := Color(0.11, 0.12, 0.11)

var paths: Array[PackedVector2Array] = [] # screen-space polylines, start to destination


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	for path in paths:
		if path.size() < 2 or path[0].distance_to(path[path.size() - 1]) < 24.0:
			continue
		for i in path.size() - 1:
			draw_dashed_line(path[i], path[i + 1], INK, 6.0, 12.0)
		for i in path.size() - 1:
			draw_dashed_line(path[i], path[i + 1], YELLOW, 3.0, 12.0)
		var to := path[path.size() - 1]
		var before := path[path.size() - 2]
		var direction := (to - before).normalized()
		var side := direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([to, to - direction * 14.0 + side * 8.0, to - direction * 14.0 - side * 8.0]), YELLOW)
