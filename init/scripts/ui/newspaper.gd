# A press item is a printed front page, separate from office correspondence.
extends PanelContainer

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const PAPER_SHADER = preload("res://assets/shaders/newsprint_paper.gdshader")
const PHOTO_SHADER = preload("res://assets/shaders/newsprint_photo.gdshader")
const INK := Color("302c24")
const MUTED := Color("655e4e")

var _serif := OfficeTheme.heading_font(400.0)


func build(notice: Dictionary, date: String, dismiss: Callable) -> void:
	theme = OfficeTheme.make_theme(true)
	add_theme_stylebox_override("panel", OfficeTheme.box(OfficeTheme.PAPER, OfficeTheme.COVER, 28))
	var paper := ShaderMaterial.new()
	paper.shader = PAPER_SHADER
	material = paper
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	add_child(layout)
	var top := HBoxContainer.new()
	var strapline := _text(notice.get("eyebrow", "ГОРОД И ЛЮДИ"), 11)
	strapline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(strapline)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Закрыть газету"
	close.custom_minimum_size = Vector2(28, 28)
	for state in ["normal", "hover", "pressed"]:
		close.add_theme_stylebox_override(state, OfficeTheme.box(Color.TRANSPARENT, Color.TRANSPARENT, 2))
	close.pressed.connect(dismiss)
	top.add_child(close)
	layout.add_child(top)
	var masthead := _text(notice.get("masthead", "Городские вести"), 52, true)
	masthead.add_theme_font_override("font", OfficeTheme.heading_font(700.0))
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(masthead)
	layout.add_child(_rule(3))
	var edition := HBoxContainer.new()
	var date_label := _text(date, 12)
	date_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	edition.add_child(date_label)
	var section := _text(notice.get("section", "ГОРОД И ЛЮДИ"), 12)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	edition.add_child(section)
	var issue := _text(notice.get("issue", ""), 12)
	issue.autowrap_mode = TextServer.AUTOWRAP_OFF
	edition.add_child(issue)
	layout.add_child(edition)
	layout.add_child(_rule(1))
	var headline := _text(notice.get("title", ""), 40, true)
	headline.add_theme_font_override("font", OfficeTheme.heading_font(600.0))
	layout.add_child(headline)
	if notice.get("lead", "") != "":
		layout.add_child(_text(notice["lead"], 19, true))
	layout.add_child(_rule(1))

	# Two editorial columns, with a narrow printed rule instead of UI cards.
	var article := HBoxContainer.new()
	article.size_flags_vertical = Control.SIZE_EXPAND_FILL
	article.add_theme_constant_override("separation", 22)
	layout.add_child(article)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_stretch_ratio = 1.25
	copy.add_theme_constant_override("separation", 14)
	article.add_child(copy)
	copy.add_child(_text(notice.get("body", ""), 18, true))
	if notice.get("quote", "") != "":
		copy.add_child(_rule(1))
		copy.add_child(_text(notice["quote"], 25, true))
		copy.add_child(_text(notice.get("quote_author", ""), 12))
	var divider := ColorRect.new()
	divider.color = Color(0.25, 0.22, 0.17, 0.4)
	divider.custom_minimum_size.x = 1
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	article.add_child(divider)
	var photo_column := VBoxContainer.new()
	photo_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	photo_column.add_theme_constant_override("separation", 8)
	article.add_child(photo_column)
	var illustration_path: String = notice.get("illustration", "")
	if illustration_path != "" and ResourceLoader.exists(illustration_path):
		var photo := TextureRect.new()
		photo.texture = load(illustration_path)
		if notice.has("illustration_region"):
			var crop := AtlasTexture.new()
			crop.atlas = photo.texture
			crop.region = notice["illustration_region"]
			photo.texture = crop
		photo.custom_minimum_size.y = 286
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var print_material := ShaderMaterial.new()
		print_material.shader = PHOTO_SHADER
		photo.material = print_material
		photo_column.add_child(photo)
		photo_column.add_child(_text(notice.get("caption", ""), 12))
	layout.add_child(_rule(2))
	var footer := HBoxContainer.new()
	var folio := _text("ГОРОДСКИЕ ВЕСТИ  /  1", 11)
	folio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	folio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(folio)
	var put_down := Button.new()
	put_down.text = notice.get("button", "Отложить газету →")
	put_down.add_theme_color_override("font_color", INK)
	put_down.add_theme_color_override("font_hover_color", INK)
	for state in ["normal", "hover", "pressed"]:
		var style := OfficeTheme.box(Color(0.25, 0.22, 0.17, 0.05 if state == "hover" else 0.0), MUTED, 8)
		style.set_border_width_all(0)
		style.border_width_bottom = 1
		put_down.add_theme_stylebox_override(state, style)
	put_down.pressed.connect(dismiss)
	footer.add_child(put_down)
	layout.add_child(footer)


func _text(copy: String, font_size: int, serif: bool = false) -> Label:
	var label := Label.new()
	label.text = copy
	label.add_theme_color_override("font_color", INK if serif else MUTED)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("line_spacing", 3)
	if serif:
		label.add_theme_font_override("font", _serif)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return label


func _rule(thickness: int) -> ColorRect:
	var rule := ColorRect.new()
	rule.color = Color(0.19, 0.17, 0.14, 0.85 if thickness > 1 else 0.4)
	rule.custom_minimum_size.y = thickness
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rule
