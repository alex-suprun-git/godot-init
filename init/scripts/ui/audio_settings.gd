# Small modal mixer. Pausing the tree preserves the simulation's selected speed.
extends CanvasLayer

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const CHANNELS := {"Master": "Общая громкость", "Music": "Музыка", "Ambience": "Эмбиент", "UI": "Интерфейс", "SFX": "Эффекты"}
var audio
var city_map
var _root: ColorRect
var _sliders := {}
var _was_paused := false
var _previous_focus: Control


func setup(manager, map_node) -> void:
	audio = manager
	city_map = map_node
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_root = ColorRect.new()
	_root.color = Color(0.08, 0.06, 0.06, 0.55)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = OfficeTheme.make_theme(true)
	add_child(_root)
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
	title.text = "Звук"
	title.add_theme_font_override("font", OfficeTheme.heading_font())
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
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
	hint.text = "Эмбиент усиливается при приближении камеры.\nНастройки действуют до закрытия игры."
	hint.add_theme_font_size_override("font_size", 13)
	column.add_child(hint)
	var close := Button.new()
	close.text = "Продолжить · Esc"
	close.pressed.connect(_close)
	column.add_child(close)
	_root.hide()


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
	get_tree().paused = true
	_sliders["Master"].grab_focus()


func _close() -> void:
	_root.hide()
	get_tree().paused = _was_paused
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()
