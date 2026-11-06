# A prepared material fills its parent independently of Container content margins.
extends Control
var texture: Texture2D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_parent().resized.connect(queue_redraw)
	resized.connect(queue_redraw)
func _draw() -> void:
	if texture:
		draw_texture_rect(texture, Rect2(-position, get_parent().size), false, self_modulate)
