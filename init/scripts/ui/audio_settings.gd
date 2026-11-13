# Small modal mixer. Pausing the tree preserves the simulation's selected speed.
extends CanvasLayer

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const Settings = preload("res://scripts/data/settings.gd")
const CHANNELS := {"Master": "Общая громкость", "Music": "Музыка", "Ambience": "Эмбиент", "UI": "Интерфейс", "SFX": "Эффекты"}
var audio
var city_map
var _root: ColorRect
var _sliders := {}
var _scale_slider: HSlider
var _scale_value: Label
var _was_paused := false
var _previous_focus: Control


func setup(manager, map_node) -> void:
	audio = manager
	city_map = map_node
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_root = ColorRect.new()
	_root.color = Color(0.08, 0.06, 0.06, 0.55)
	_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_root.theme = OfficeTheme.make_theme(true)
	add_child(_root)
	Settings.load_interface_preferences()
	Settings.ui_events.scale_changed.connect(_apply_interface_scale)
	get_viewport().size_changed.connect(_apply_interface_scale)
	_apply_interface_scale()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 440
	panel.add_theme_stylebox_override("panel", OfficeTheme.box(OfficeTheme.PAPER, OfficeTheme.EDGE, 24))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Настройки"
	title.add_theme_font_override("font", OfficeTheme.heading_font())
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	var scale_row := HBoxContainer.new()
	column.add_child(scale_row)
	var scale_label := Label.new()
	scale_label.text = "Масштаб интерфейса"
	scale_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scale_row.add_child(scale_label)
	_scale_value = Label.new()
	scale_row.add_child(_scale_value)
	_scale_slider = HSlider.new()
	_scale_slider.min_value = 75
	_scale_slider.max_value = 150
	_scale_slider.step = 5
	_scale_slider.value = Settings.ui_scale * 100
	_scale_slider.value_changed.connect(func(value: float): Settings.set_interface_scale(value / 100.0))
	column.add_child(_scale_slider)
	var reset := Button.new()
	reset.text = "Масштаб 100%"
	reset.pressed.connect(func(): _scale_slider.value = 100)
	reset.pressed.connect(audio.play.bind("ui_click"))
	column.add_child(reset)
	for channel in CHANNELS:
		var row := HBoxContainer.new()
		column.add_child(row)
		var label := Label.new()
		label.text = CHANNELS[channel]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var value := Label.new()
		value.custom_minimum_size.x = 48
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(value)
		var slider := HSlider.new()
		slider.max_value = 100
		slider.step = 1
		slider.value_changed.connect(func(amount: float):
			audio.set_channel_level(channel, amount / 100.0)
			value.text = "%d%%" % roundi(amount))
		column.add_child(slider)
		_sliders[channel] = slider
	var hint := Label.new()
	hint.text = "Масштаб сохраняется. На небольшом экране ограничен доступным местом.\nЭмбиент усиливается при приближении камеры.\nГромкость действует до закрытия игры."
	hint.add_theme_font_size_override("font_size", 13)
	column.add_child(hint)
	var close := Button.new()
	close.text = "Продолжить · Esc"
	close.pressed.connect(_close)
	column.add_child(close)
	_root.hide()
	_apply_interface_scale()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if event.is_echo():
			return
		if _root.visible:
			_close()
		else:
			_open()


func _open() -> void:
	_previous_focus = get_viewport().gui_get_focus_owner()
	_was_paused = get_tree().paused
	city_map.cancel_camera_drag()
	for channel in _sliders:
		var slider: HSlider = _sliders[channel]
		slider.value = audio.get_channel_level(channel) * 100.0
		# Refresh the numeric label even when the value has not changed.
		slider.value_changed.emit(slider.value)
	_root.show()
	audio.play("ui_click")
	get_tree().paused = true
	_sliders["Master"].grab_focus()


func _close() -> void:
	audio.play("ui_click")
	_root.hide()
	get_tree().paused = _was_paused
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()


func _apply_interface_scale(_value: float = 1.0) -> void:
	var viewport := get_viewport().get_visible_rect().size
	var factor := Settings.fitted_interface_scale(viewport)
	_root.scale = Vector2.ONE * factor
	_root.size = viewport / factor
	if is_instance_valid(_scale_value):
		_scale_value.text = "%d%%" % roundi(Settings.ui_scale * 100)
		if factor < Settings.ui_scale - 0.001:
			_scale_value.text += " (на экране %d%%)" % roundi(factor * 100)
		_scale_slider.set_value_no_signal(Settings.ui_scale * 100)
