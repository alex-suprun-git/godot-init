# One headline-led printed sheet. All copy is live text; artwork is independently replaceable.
extends PanelContainer

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const TEXT_FONT = preload("res://assets/fonts/source_serif4_regular.ttf")
const SERIF = preload("res://assets/fonts/source_serif4_bold.ttf")
const ITALIC = preload("res://assets/fonts/source_serif4_italic.ttf")
const MASTHEAD_FONT = preload("res://assets/fonts/roboto_slab.ttf")
const CONDENSED = preload("res://assets/fonts/oswald.ttf")
const PAPER = preload("res://assets/ui/newspaper_paper.png")
const ART = preload("res://assets/ui/newspaper_art_atlas.png")
const INK = Color("211f1c")
const DESIGN = Vector2(1060, 870)
const PRINT_SCALE := 0.975
const PRINT_OFFSET := Vector2(530, 410) * (1.0 - PRINT_SCALE)
const TYPE_SCALE := 0.95 / PRINT_SCALE # Five percent smaller overall, including inset.
var _edition: Dictionary
var _date := ""
var _headline: FontVariation
var _masthead: FontVariation
var _canvas: Control
var _close: Button
var _factor := 1.0

func build(edition: Dictionary, date: String, dismiss: Callable) -> void:
	_edition = edition
	_date = date
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_force_pass_scroll_events = false
	_headline = FontVariation.new()
	_headline.base_font = CONDENSED
	_headline.variation_opentype = {2003265652: 700.0}
	_headline.variation_embolden = 0.0
	_masthead = FontVariation.new()
	_masthead.base_font = MASTHEAD_FONT
	_masthead.variation_opentype = {2003265652: 900.0}
	_masthead.variation_embolden = 0.0
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_canvas)
	_close = Button.new()
	_close.text = "Отложить газету →"
	_close.theme = OfficeTheme.make_theme(true)
	_close.add_theme_font_override("font", SERIF)
	_close.add_theme_font_size_override("font_size", 20)
	_close.pressed.connect(dismiss)
	_canvas.add_child(_close)
	get_viewport().size_changed.connect(_fit_viewport)
	_fit_viewport()

func _fit_viewport() -> void:
	var viewport := get_viewport_rect().size
	_factor = minf((viewport.x - 40) / DESIGN.x, (viewport.y - 65) / DESIGN.y)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = DESIGN * _factor
	position = Vector2((viewport.x - size.x) / 2, maxf(12, (viewport.y - size.y) / 2 + 20))
	_close.position = Vector2(400, 831) * _factor
	_close.size = Vector2(260, 36)
	_close.scale = Vector2.ONE * _factor
	queue_redraw()

func _draw() -> void:
	if _edition.is_empty():
		return
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * _factor)
	draw_texture_rect(PAPER, Rect2(-16, -18, 1090, 855), false)
	_print_transform()
	_line(Vector2(175, 34), Vector2(175, 105))
	_print("НЕЗАВИСИМАЯ\nГОРОДСКАЯ\nГАЗЕТА", Rect2(43, 41, 115, 54), SERIF, 15)
	_print("ГОРОДСКИЕ ВЕСТИ", Rect2(205, 30, 810, 77), _masthead, 93, true)
	_line(Vector2(32, 126), Vector2(1028, 126), 3)
	_line(Vector2(32, 131), Vector2(1028, 131))
	_print("ПОНЕДЕЛЬНИК, " + _edition["print_date"], Rect2(40, 140, 760, 22), SERIF, 23)
	_print(_edition["issue"], Rect2(870, 140, 160, 22), SERIF, 23)
	_line(Vector2(32, 169), Vector2(1028, 169), 2)
	_line(Vector2(731, 184), Vector2(731, 580), 2)
	_print(_edition["lead"], Rect2(32, 185, 687, 138), _headline, 78, true)
	_print(_edition["deck"], Rect2(38, 333, 680, 30), ITALIC, 31)
	var photo := AtlasTexture.new()
	photo.atlas = ART
	photo.region = _edition["photo_region"]
	draw_texture_rect(photo, Rect2(34, 372, 684, 207), false)
	_print(_edition["side"], Rect2(754, 212, 270, 111), _headline, 58, true)
	_print(_edition["side_deck"], Rect2(754, 346, 270, 48), ITALIC, 24)
	_line(Vector2(751, 407), Vector2(1023, 407))
	_ad()
	_line(Vector2(34, 593), Vector2(1026, 593), 2)
	_rubric("ЗА РЕКОЙ", Rect2(38, 608, 130, 23))
	_rubric("ГОРОД", Rect2(619, 608, 88, 23))
	_print(_edition["world"], Rect2(38, 641, 550, 84), _headline, 44, true)
	_line(Vector2(599, 606), Vector2(599, 733))
	_print(_edition["city"], Rect2(620, 641, 405, 84), SERIF, 45, true)
	draw_rect(Rect2(32, 748, 998, 54), INK, false, 1.4)
	_line(Vector2(540, 756), Vector2(540, 794))
	_print(_edition["classifieds"][0], Rect2(55, 763, 465, 28), _headline, 30)
	_print(_edition["classifieds"][1], Rect2(564, 763, 448, 28), _headline, 30)
	draw_set_transform(Vector2.ZERO)

func _ad() -> void:
	draw_rect(Rect2(751, 427, 282, 148), INK, false, 1.3)
	_print("РЕКЛАМА", Rect2(760, 435, 70, 12), _headline, 13)
	var television := AtlasTexture.new()
	television.atlas = ART
	television.region = Rect2(1069, 519, 100, 81)
	draw_texture_rect(television, Rect2(760, 463, 100, 81), false)
	_print(_edition["advert"]["title"], Rect2(870, 446, 156, 85), _headline, 24)
	_print(_edition["advert"]["contact"], Rect2(765, 552, 256, 17), SERIF, 18)

func _rubric(copy: String, rect: Rect2) -> void:
	draw_rect(rect, INK)
	_print(copy, Rect2(rect.position + Vector2(6, 2), rect.size - Vector2(12, 4)), SERIF, 20, false, Color("eee9e1"))

# Typeset authored line breaks into measured slots; no wrapping or truncation.
# Horizontal fitting preserves the approved condensed newspaper proportions.
func _print(copy: String, rect: Rect2, font: Font, pixels: int, fill: bool = false, color: Color = INK) -> void:
	var lines := copy.split("\n")
	var step: float = rect.size.y / lines.size()
	for index in lines.size():
		var width := font.get_string_size(lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
		var sx: float = rect.size.x / maxf(width, 1) if fill else minf(1, rect.size.x / maxf(width, 1))
		var origin := rect.position + Vector2(0, index * step + step * 0.88)
		draw_set_transform((PRINT_OFFSET + origin * PRINT_SCALE) * _factor, 0, Vector2(sx, 1) * _factor * PRINT_SCALE * TYPE_SCALE)
		draw_string(font, Vector2.ZERO, lines[index], HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, color)
	_print_transform()

func _print_transform() -> void:
	draw_set_transform(PRINT_OFFSET * _factor, 0, Vector2.ONE * _factor * PRINT_SCALE)

func _line(a: Vector2, b: Vector2, width: float = 1.0) -> void:
	draw_line(a, b, INK, width, true)
