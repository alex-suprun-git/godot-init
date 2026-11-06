# Paper surface reused from the prepared folder label, beneath live controls.
extends Control

var kind := "paper"
static var _paper_texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _paper_texture == null:
		_paper_texture = load("res://assets/ui/work_folder.png")
	resized.connect(queue_redraw)


func _draw() -> void:
	# PanelContainer positions this child inside its content margins.
	# Draw across the sheet, leaving its cut edge and contact shadow visible.
	var surface := Rect2(-position + Vector2(2, 2), get_parent().size - Vector2(4, 4))
	if _paper_texture != null:
		draw_texture_rect_region(_paper_texture, surface, Rect2(90, 177, 840, 125), Color(1, 1, 1, 0.5))
	if kind == "newspaper":
		var origin := surface.position
		var width := surface.size.x
		draw_line(origin + Vector2(10, 4), origin + Vector2(width - 10, 4), Color("715d53"), 1)
		draw_line(origin + Vector2(10, 7), origin + Vector2(width - 10, 7), Color("baa18b"), 1)
		var corner := surface.end
		draw_colored_polygon(PackedVector2Array([corner - Vector2(14, 0), corner - Vector2(0, 14), corner]), Color("d5c6af"))
		draw_line(corner - Vector2(14, 0), corner - Vector2(0, 14), Color("baa18b"), 1)
	elif kind == "memo":
		var pin := surface.position + Vector2(surface.size.x - 18, -5)
		draw_polyline(PackedVector2Array([pin + Vector2(2, 4), pin + Vector2(2, 15), pin + Vector2(8, 15), pin + Vector2(8, 0), pin + Vector2(0, 0), pin + Vector2(0, 18), pin + Vector2(10, 18), pin + Vector2(10, 5)]), Color("9a8e80"), 1.3, true)
