# Dashed lines with arrowheads from people on the way to where they are going.
# The HUD sets `paths` every frame; this layer only draws and never takes input.
extends Control

const YELLOW := Color(0.98, 0.78, 0.46)
const INK := Color(0.11, 0.12, 0.11)

var paths: Array[Dictionary] = [] # each: {from: Vector2, to: Vector2}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	for path in paths:
		var from: Vector2 = path["from"]
		var to: Vector2 = path["to"]
		if from.distance_to(to) < 24.0:
			continue
		draw_dashed_line(from, to, INK, 6.0, 12.0)
		draw_dashed_line(from, to, YELLOW, 3.0, 12.0)
		var direction := (to - from).normalized()
		var side := direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([to, to - direction * 14.0 + side * 8.0, to - direction * 14.0 - side * 8.0]), YELLOW)
