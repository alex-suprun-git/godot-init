# Shared visual language: warm graphite, paper files, and burgundy ink.
extends RefCounted

const BODY_FONT = preload("res://assets/fonts/golos_text.ttf")
const TITLE_FONT = preload("res://assets/fonts/roboto_slab.ttf")
const GRAPHITE := Color("342829")
const PAPER := Color("eee0ca")
const TEXT := Color("382c29")
const SECONDARY := Color("715d53")
const LIGHT_TEXT := Color("eee3d2")
const LIGHT_MUTED := Color("c6b6ab")
const BURGUNDY := Color("873c42")
const COVER := Color("b89c82")
const EDGE := Color("baa18b")
const LINK := Color("77564d")

static func heading_font(weight: float = 700.0) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = TITLE_FONT
	font.variation_opentype = {2003265652: weight}
	return font


static func box(fill: Color, border: Color, margin: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(margin)
	style.set_corner_radius_all(1)
	return style


static func make_theme(on_paper: bool = false) -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 16
	if on_paper:
		theme.set_font("font", "Button", heading_font(600.0))
	var foreground := TEXT if on_paper else LIGHT_TEXT
	var muted := SECONDARY if on_paper else LIGHT_MUTED
	var surface := PAPER if on_paper else GRAPHITE
	for type in ["Label", "Button", "TabContainer"]:
		theme.set_color("font_color", type, foreground)
	theme.set_color("font_hover_color", "Button", foreground)
	theme.set_color("font_pressed_color", "Button", LIGHT_TEXT)
	theme.set_color("font_focus_color", "Button", foreground)
	theme.set_color("font_hover_pressed_color", "Button", LIGHT_TEXT)
	theme.set_color("font_disabled_color", "Button", muted)
	var normal := box(surface, SECONDARY.lightened(0.28) if on_paper else EDGE, 10)
	normal.set_corner_radius_all(3)
	normal.shadow_color = Color(0.12, 0.08, 0.06, 0.18)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(0, 1)
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", box(surface.lightened(0.07), BURGUNDY, 10))
	theme.set_stylebox("pressed", "Button", box(BURGUNDY, BURGUNDY, 10))
	theme.set_stylebox("disabled", "Button", box(surface.darkened(0.04), EDGE.darkened(0.1), 10))
	var focus := box(Color(0, 0, 0, 0), COVER, 0)
	focus.set_border_width_all(2)
	theme.set_stylebox("focus", "Button", focus)
	var line := StyleBoxLine.new()
	line.color = EDGE.darkened(0.12)
	line.thickness = 1
	theme.set_stylebox("separator", "HSeparator", line)
	theme.set_color("font_selected_color", "TabContainer", TEXT)
	theme.set_color("font_unselected_color", "TabContainer", SECONDARY)
	theme.set_color("font_hovered_color", "TabContainer", TEXT)
	theme.set_font_size("font_size", "TabContainer", 16)
	for state in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var tab := box(PAPER, EDGE, 12)
		tab.set_border_width_all(0)
		if state == "tab_selected":
			tab.border_width_bottom = 2
			tab.border_color = BURGUNDY
		theme.set_stylebox(state, "TabContainer", tab)
	# The content starts below the tab underline, including on sparse pages.
	var tab_page := box(PAPER, PAPER, 8)
	tab_page.content_margin_top = 20
	tab_page.content_margin_bottom = 12
	theme.set_stylebox("panel", "TabContainer", tab_page)
	theme.set_stylebox("panel", "TooltipPanel", box(PAPER, COVER, 12))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 15)
	theme.set_stylebox("background", "ProgressBar", box(GRAPHITE, GRAPHITE, 0))
	theme.set_stylebox("fill", "ProgressBar", box(COVER, COVER, 0))
	return theme


# A clean sheet with a fine cut edge and a small contact shadow.
static func paper(margin: int = 12, fill: Color = PAPER) -> StyleBoxFlat:
	var style := box(fill, EDGE, margin)
	style.set_corner_radius_all(2)
	style.shadow_color = Color(0.12, 0.08, 0.06, 0.28)
	style.shadow_size = 4
	style.shadow_offset = Vector2(1, 3)
	return style
