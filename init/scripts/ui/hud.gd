# Screen UI over the 3D map: top bar, right panel, contacts bar, request
# markers, the request card, and the week summary. Built in code so the whole
# layout lives in one readable place while the prototype is changing fast.
extends CanvasLayer

const Week1 = preload("res://scripts/data/week1.gd")

signal start_week_pressed
signal speed_selected(speed: float)
signal next_week_pressed
signal restart_pressed

const INK := Color(0.09, 0.1, 0.1, 0.92)
const PAPER := Color(0.93, 0.9, 0.83)
const MUTED := Color(0.72, 0.69, 0.62)
const AMBER := Color(0.91, 0.66, 0.27)
const RUST := Color(0.85, 0.36, 0.27)
const STEEL := Color(0.45, 0.68, 0.85)
const TYPE_NAMES := {"plea": "Просьба", "conflict": "Конфликт", "crisis": "Кризис", "offer": "Предложение"}
const TYPE_COLORS := {
	"plea": Color(0.16, 0.18, 0.18), "conflict": Color(0.62, 0.42, 0.12),
	"crisis": Color(0.7, 0.2, 0.15), "offer": Color(0.18, 0.36, 0.52),
}

var sim
var map
var phase := "planning"

var _root: Control
var _date_label: Label
var _phase_label: Label
var _money_label: Label
var _start_button: Button
var _speed_buttons := {}
var _objectives_box: VBoxContainer
var _promises_box: VBoxContainer
var _standing_box: VBoxContainer
var _wire_box: VBoxContainer
var _contacts := {} # actor id -> status label
var _markers_layer: Control
var _markers := {} # request id -> Button
var _card: PanelContainer
var _card_request := ""
var _overlay_panel: PanelContainer


func setup(week_sim, city_map) -> void:
	sim = week_sim
	map = city_map
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)

	_markers_layer = Control.new()
	_markers_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_markers_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_markers_layer)

	_build_top_bar()
	_build_right_panel()
	_build_contacts_bar()
	_build_card()

	sim.request_opened.connect(func(_id): _refresh_markers())
	sim.request_changed.connect(_on_request_changed)
	sim.state_changed.connect(_refresh_panels)
	sim.entry_added.connect(func(_entry): _refresh_wire())
	sim.crisis_started.connect(open_card.bind(true))
	sim.time_changed.connect(_refresh_clock)
	_refresh_all()


func set_phase(new_phase: String) -> void:
	phase = new_phase
	_start_button.visible = phase == "planning"
	for speed in _speed_buttons:
		_speed_buttons[speed].visible = phase == "live"
	match phase:
		"planning":
			_phase_label.text = "ПЛАНИРОВАНИЕ · ВРЕМЯ СТОИТ"
		"live":
			_phase_label.text = "ЖИВАЯ НЕДЕЛЯ"
		"summary":
			_phase_label.text = "ИТОГИ НЕДЕЛИ"
			_close_card()
			_show_summary()
		"week2":
			_phase_label.text = "УТРО ПОНЕДЕЛЬНИКА"
	_refresh_all()


func set_speed(speed: float) -> void:
	for value in _speed_buttons:
		_speed_buttons[value].button_pressed = is_equal_approx(value, speed)


func show_week_two(changes: Array[String]) -> void:
	set_phase("week2")
	var lines: Array[String] = []
	lines.assign(changes)
	lines.append("Здесь прототип первой недели заканчивается.")
	# Compact and off to the side: the point of this screen is the changed map.
	_show_overlay("Понедельник, " + sim.date_text(0).substr(3), "Что изменилось за выходные", lines, "Сыграть заново", restart_pressed.emit, true)


func open_card(request_id: String, focus: bool = false) -> void:
	_card_request = request_id
	_card.visible = true
	if focus:
		map.focus_on(sim.requests[request_id]["data"]["lot"])
	_refresh_card()


func _process(_delta: float) -> void:
	# Markers float above their lot; when the lot is off-screen they stick to
	# the edge of the free map area with an arrow pointing toward it.
	var area := _map_area()
	for id in _markers:
		var marker: Button = _markers[id]
		var data: Dictionary = sim.requests[id]["data"]
		var lot: String = data["lot"]
		var index: int = _markers_at_lot(lot).find(id)
		var screen: Vector2 = map.lot_screen_position(lot)
		var offscreen := not area.has_point(screen)
		var label := _marker_text(id)
		if offscreen:
			label = _edge_arrow(screen, area) + " " + label
		if marker.text != label:
			marker.text = label
			marker.reset_size()
		var pos := screen - Vector2(marker.size.x / 2.0, marker.size.y + index * (marker.size.y + 4))
		if offscreen:
			pos = pos.clamp(area.position, area.end - marker.size)
		marker.position = pos
		marker.set_meta("offscreen", offscreen)


# --- Layout ------------------------------------------------------------------

func _build_top_bar() -> void:
	var bar := _panel(INK)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 56)
	_root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	bar.add_child(row)

	_date_label = _label("", 20, PAPER)
	row.add_child(_date_label)
	_phase_label = _label("", 13, AMBER)
	row.add_child(_phase_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	for speed in [0.0, 1.0, 2.0, 4.0]:
		var button := Button.new()
		button.text = "II" if speed == 0.0 else "x%d" % speed
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(48, 40)
		button.pressed.connect(speed_selected.emit.bind(speed))
		row.add_child(button)
		_speed_buttons[speed] = button

	_money_label = _label("", 16, PAPER)
	row.add_child(_money_label)
	row.add_child(_label("Влияние: взято взаймы у босса", 14, MUTED))

	_start_button = Button.new()
	_start_button.text = "Начать неделю"
	_start_button.custom_minimum_size = Vector2(170, 40)
	_start_button.add_theme_stylebox_override("normal", _style(RUST))
	_start_button.add_theme_stylebox_override("hover", _style(RUST.lightened(0.12)))
	_start_button.pressed.connect(start_week_pressed.emit)
	row.add_child(_start_button)


func _build_right_panel() -> void:
	var panel := _panel(INK)
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -380
	panel.offset_top = 64
	panel.offset_right = -8
	panel.offset_bottom = -8
	_root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)

	var boss_row := HBoxContainer.new()
	boss_row.add_theme_constant_override("separation", 10)
	boss_row.add_child(_face(Week1.BOSS["portrait"], Week1.BOSS["face"], 56))
	var boss_text := VBoxContainer.new()
	boss_text.add_child(_label("ПОРУЧЕНИЕ БОССА", 12, AMBER))
	boss_text.add_child(_label("Отопительный сезон к 15 октября", 17, PAPER))
	boss_row.add_child(boss_text)
	column.add_child(boss_row)
	_objectives_box = VBoxContainer.new()
	column.add_child(_objectives_box)

	column.add_child(_label("ОБЕЩАНИЯ", 12, AMBER))
	_promises_box = VBoxContainer.new()
	column.add_child(_promises_box)

	column.add_child(_label("ПОЛОЖЕНИЕ", 12, AMBER))
	_standing_box = VBoxContainer.new()
	column.add_child(_standing_box)

	column.add_child(_label("СВОДКА", 12, AMBER))
	_wire_box = VBoxContainer.new()
	_wire_box.add_theme_constant_override("separation", 6)
	column.add_child(_wire_box)


func _build_contacts_bar() -> void:
	var bar := HBoxContainer.new()
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.anchor_right = 1.0
	bar.offset_left = 8
	bar.offset_top = -104
	bar.offset_right = -392
	bar.offset_bottom = -8
	bar.add_theme_constant_override("separation", 8)
	_root.add_child(bar)
	for id in Week1.ACTORS:
		var info: Dictionary = Week1.ACTORS[id]
		var card := _panel(INK)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		if info["portrait"] != "":
			row.add_child(_face(info["portrait"], info["face"], 72))
		else:
			var badge := _panel(Color(0.85, 0.36, 0.27))
			badge.custom_minimum_size = Vector2(72, 72)
			var me_label := _label("ВЫ", 22, PAPER)
			me_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			me_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			badge.add_child(me_label)
			row.add_child(badge)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(_label(info["name"], 17, PAPER))
		text.add_child(_label(info["role"], 12, MUTED))
		var status := _label("", 13, AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_child(status)
		row.add_child(text)
		_contacts[id] = status


func _build_card() -> void:
	_card = _panel(Color(0.12, 0.12, 0.11, 0.97))
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left = -440
	_card.offset_right = 20
	_card.offset_top = -280
	_card.offset_bottom = 230
	_card.visible = false
	_root.add_child(_card)


# --- Refresh -----------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_clock()
	_refresh_panels()
	_refresh_wire()
	_refresh_markers()


func _refresh_clock() -> void:
	_date_label.text = "Неделя %d · %s · %s" % [sim.week, sim.date_text(), sim.clock_text()]
	for id in _contacts:
		_contacts[id].text = sim.actor_status_text(id)


func _refresh_panels() -> void:
	_money_label.text = "%s млн руб." % String.num(sim.money / 1_000_000.0, 1).replace(".", ",")

	_clear(_objectives_box)
	for objective in Week1.OBJECTIVES:
		var status: String = sim.objective_status(objective)
		var color: Color = {"done": STEEL, "failed": RUST, "pending": PAPER}[status]
		var mark: String = {"done": "Выполнено · ", "failed": "Провалено · ", "pending": ""}[status]
		var line := _label(mark + objective["text"], 14, color)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_objectives_box.add_child(line)

	_clear(_promises_box)
	if sim.promises.is_empty():
		_promises_box.add_child(_label("Пока никому ничего не обещали.", 13, MUTED))
	for promise in sim.promises:
		var status_text: String = {"active": "до " + promise["due_text"], "kept": "сдержано", "broken": "НАРУШЕНО"}[promise["status"]]
		var color: Color = {"active": PAPER, "kept": STEEL, "broken": RUST}[promise["status"]]
		var line := _label("%s · %s" % [promise["text"], status_text], 14, color)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_promises_box.add_child(line)

	_clear(_standing_box)
	for id in sim.factions:
		var row := HBoxContainer.new()
		var name_label := _label(Week1.FACTIONS[id]["name"], 15, PAPER)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var value: int = sim.factions[id]
		var word_color := RUST if value <= -15 else (STEEL if value > 5 else PAPER)
		row.add_child(_label(sim.standing_word(value), 15, word_color))
		_standing_box.add_child(row)
	_refresh_clock()


func _refresh_wire() -> void:
	_clear(_wire_box)
	var recent: Array = sim.entries.slice(max(0, sim.entries.size() - 7))
	recent.reverse()
	for entry in recent:
		var line := _label("%s  %s" % [entry["time"], entry["text"]], 13, PAPER)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_wire_box.add_child(line)


func _refresh_markers() -> void:
	var visible_ids: Array[String] = []
	if phase in ["planning", "live"]:
		visible_ids = sim.visible_requests()
	for id in _markers.keys():
		if not visible_ids.has(id):
			_markers[id].queue_free()
			_markers.erase(id)
	for id in visible_ids:
		if not _markers.has(id):
			var marker := Button.new()
			marker.pressed.connect(_on_marker_pressed.bind(id))
			_markers_layer.add_child(marker)
			_markers[id] = marker
		var data: Dictionary = sim.requests[id]["data"]
		var marker: Button = _markers[id]
		var assigned: bool = sim.requests[id]["status"] == "assigned"
		marker.text = _marker_text(id)
		var color: Color = TYPE_COLORS[data["type"]]
		if assigned:
			color = color.darkened(0.4)
		marker.add_theme_stylebox_override("normal", _style(color, PAPER))
		marker.add_theme_stylebox_override("hover", _style(color.lightened(0.15), PAPER))
		marker.add_theme_stylebox_override("pressed", _style(color, PAPER))
		marker.reset_size()


func _refresh_card() -> void:
	if not _card.visible or _card_request == "":
		return
	_clear(_card)
	var request: Dictionary = sim.requests[_card_request]
	var data: Dictionary = request["data"]
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_card.add_child(column)

	var header := HBoxContainer.new()
	var kind := _label("%s · %s" % [TYPE_NAMES[data["type"]].to_upper(), Week1.LOTS[data["lot"]]["name"]], 12, AMBER)
	kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(kind)
	header.add_child(_label("до " + sim.when_text(data["expire"]), 12, RUST))
	column.add_child(header)

	var title := _label(data["title"], 22, PAPER)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	if data["asker"] != "":
		var asker: Dictionary = Week1.ACTORS[data["asker"]]
		body.add_child(_face(asker["portrait"], asker["face"], 72))
	var text := _label(data["text"], 15, PAPER)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(text)
	column.add_child(body)

	if request["promised"]:
		column.add_child(_label("Вы уже пообещали. Теперь надо сделать.", 13, AMBER))
	if request["status"] == "closed":
		column.add_child(_label("Вопрос закрыт.", 14, MUTED))
	elif request["status"] == "assigned":
		column.add_child(_label("В работе.", 14, AMBER))

	column.add_child(_label("КОГО ОТПРАВИТЬ", 12, MUTED))
	for option in data["options"]:
		var reason: String = sim.option_block_reason(_card_request, option)
		var button := Button.new()
		button.text = option["label"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 40)
		button.disabled = reason != ""
		button.pressed.connect(_on_option_pressed.bind(option["id"]))
		column.add_child(button)
		var hint := _label(option["hint"] + ("" if reason == "" else "  [" + reason + "]"), 13, MUTED)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)

	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(_close_card)
	column.add_child(close)


func _on_request_changed(_id: String) -> void:
	_refresh_markers()
	_refresh_card()


func _on_option_pressed(option_id: String) -> void:
	var request_id := _card_request
	sim.choose(request_id, option_id)
	var option: Dictionary = {}
	for candidate in sim.requests[request_id]["data"]["options"]:
		if candidate["id"] == option_id:
			option = candidate
	# Promises keep the card open so the player can still send someone.
	if option.get("actor", "") == "promise":
		_refresh_card()
	else:
		_close_card()


func _close_card() -> void:
	_card.visible = false
	_card_request = ""


func _show_summary() -> void:
	var lines: Array[String] = []
	lines.assign(sim.outcomes)
	lines.append("")
	for id in sim.factions:
		var before: String = sim.standing_word(sim.factions_at_start[id])
		var after: String = sim.standing_word(sim.factions[id])
		if before != after:
			lines.append("%s: %s → %s" % [Week1.FACTIONS[id]["name"], before, after])
	if sim.traces > 0:
		lines.append("Кто-то запомнил, что вы взяли конверт.")
	_show_overlay("Итоги недели · 25–29.08.1997", "Что осталось после недели", lines, "Утро понедельника", next_week_pressed.emit)


func _show_overlay(title: String, subtitle: String, lines: Array[String], button_text: String, action: Callable, compact: bool = false) -> void:
	if _overlay_panel != null:
		_overlay_panel.queue_free()
	_overlay_panel = _panel(Color(0.12, 0.12, 0.11, 0.97))
	if compact:
		_overlay_panel.anchor_top = 1.0
		_overlay_panel.anchor_bottom = 1.0
		_overlay_panel.offset_left = 16
		_overlay_panel.offset_top = -440
		_overlay_panel.offset_right = 476
		_overlay_panel.offset_bottom = -116
	else:
		_overlay_panel.anchor_left = 0.5
		_overlay_panel.anchor_right = 0.5
		_overlay_panel.anchor_top = 0.5
		_overlay_panel.anchor_bottom = 0.5
		_overlay_panel.offset_left = -520
		_overlay_panel.offset_right = 80
		_overlay_panel.offset_top = -300
		_overlay_panel.offset_bottom = 260
	_root.add_child(_overlay_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_overlay_panel.add_child(column)
	column.add_child(_label(subtitle.to_upper(), 12, AMBER))
	column.add_child(_label(title, 26, PAPER))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for line_text in lines:
		var line := _label(line_text, 16, PAPER)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(line)
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_stylebox_override("normal", _style(RUST))
	button.add_theme_stylebox_override("hover", _style(RUST.lightened(0.12)))
	button.pressed.connect(action)
	column.add_child(button)


# --- Helpers -----------------------------------------------------------------

func _on_marker_pressed(id: String) -> void:
	open_card(id, _markers[id].get_meta("offscreen", false))


func _marker_text(id: String) -> String:
	var request: Dictionary = sim.requests[id]
	return TYPE_NAMES[request["data"]["type"]] + (" · в работе" if request["status"] == "assigned" else "")


# The part of the screen where the map is visible, between the panels.
func _map_area() -> Rect2:
	var size := _root.get_viewport_rect().size
	return Rect2(Vector2(12, 68), Vector2(size.x - 400 - 12, size.y - 68 - 116))


func _edge_arrow(screen: Vector2, area: Rect2) -> String:
	if screen.x < area.position.x:
		return "←"
	if screen.x > area.end.x:
		return "→"
	return "↑" if screen.y < area.position.y else "↓"


func _markers_at_lot(lot: String) -> Array:
	return _markers.keys().filter(func(id): return sim.requests[id]["data"]["lot"] == lot)


func _make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 15
	theme.set_color("font_color", "Label", PAPER)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.44))
	theme.set_stylebox("normal", "Button", _style(Color(0.22, 0.23, 0.22), Color(0.45, 0.43, 0.38)))
	theme.set_stylebox("hover", "Button", _style(Color(0.3, 0.31, 0.29), AMBER))
	theme.set_stylebox("pressed", "Button", _style(Color(0.4, 0.33, 0.18), AMBER))
	theme.set_stylebox("disabled", "Button", _style(Color(0.16, 0.16, 0.15), Color(0.25, 0.25, 0.23)))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return theme


func _style(color: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	if border.a > 0.0:
		style.set_border_width_all(1)
		style.border_color = border
	style.set_corner_radius_all(3)
	return style


func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := _style(color, Color(0.36, 0.32, 0.24, 0.8))
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _face(path: String, region: Rect2, size: int) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path)
	atlas.region = region
	var rect := TextureRect.new()
	rect.texture = atlas
	rect.custom_minimum_size = Vector2(size, size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return rect


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
