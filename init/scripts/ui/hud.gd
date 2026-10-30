# Screen UI over the 3D map: top bar, weekly task board, important notices,
# contacts, request markers/cards, and the week summary. Built in code while
# the prototype layout is still changing quickly.
extends CanvasLayer

const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const Newspaper = preload("res://scripts/ui/newspaper.gd")
const Week1 = preload("res://scripts/data/week1.gd")
const RequestMarker = preload("res://scripts/ui/request_marker.gd")
const PersonToken = preload("res://scripts/ui/person_token.gd")
const PathLayer = preload("res://scripts/ui/path_layer.gd")
const Settings = preload("res://scripts/data/settings.gd")
const SeasonLabels := {"summer": "Лето", "autumn": "Осень", "winter": "Зима"}

signal start_week_pressed
signal speed_selected(speed: float)
signal next_week_pressed
signal restart_pressed
signal season_selected(key: String)

const INK := OfficeTheme.GRAPHITE
const PAPER := OfficeTheme.LIGHT_TEXT
const MUTED := OfficeTheme.LIGHT_MUTED
const AMBER := Color("c39967")
const RUST := OfficeTheme.BURGUNDY
const STEEL := Color("729da5")
const TYPE_NAMES := {"plea": "Просьба", "conflict": "Конфликт", "crisis": "Кризис", "offer": "Предложение"}
const TYPE_COLORS := {
	"plea": Color(0.16, 0.18, 0.18), "conflict": Color(0.62, 0.42, 0.12),
	"crisis": Color(0.7, 0.2, 0.15), "offer": Color(0.18, 0.36, 0.52),
}

var sim
var map
var audio # AudioManager; optional, the HUD works silently without it
var play_log # PlayLog; optional, records card opens and closes for playtests
var phase := "planning"

var _root: Control
var _date_label: Label
var _phase_label: Label
var _money_label: Label
var _start_button: Button
var _tasks_button: Button
var _speed_buttons := {}
var _season_buttons := {}
var _objectives_box: VBoxContainer
var _promises_box: VBoxContainer
var _standing_box: VBoxContainer
var _wire_box: VBoxContainer
var _week_backdrop: ColorRect
var _week_panel: PanelContainer
var _week_tabs: TabContainer
var _notice_backdrop: ColorRect
var _notice_panel: PanelContainer
var _notice_is_newspaper := false
var _incoming_tray: VBoxContainer
var _paper_theme := OfficeTheme.make_theme(true)
var _title_font := OfficeTheme.heading_font()
var _contact_progress := {} # actor id -> work progress
var _contact_dots := {} # actor id -> availability color
var _contact_cards := {} # actor id -> compact card
var _contact_detail_panel: PanelContainer
var _contact_detail_status: Label
var _contact_detail_actor := ""
var _path_layer: Control
var _tokens_layer: Control
var _tokens := {} # actor id -> PersonToken
var _markers_layer: Control
var _markers := {} # request id -> RequestMarker
var _card: PanelContainer
var _card_request := ""
var _overlay_panel: PanelContainer
var _toast_box: VBoxContainer


func setup(week_sim, city_map, audio_manager = null, playtest_log = null) -> void:
	sim = week_sim
	map = city_map
	audio = audio_manager
	play_log = playtest_log
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)

	# Map overlays, bottom to top: travel paths, people, request markers.
	_path_layer = PathLayer.new()
	_path_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_path_layer)
	_tokens_layer = Control.new()
	_tokens_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tokens_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_tokens_layer)
	_markers_layer = Control.new()
	_markers_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_markers_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_markers_layer)
	for id in Week1.ACTORS:
		var info: Dictionary = Week1.ACTORS[id]
		var token := PersonToken.new()
		token.texture = load(info["portrait"])
		token.region = info["face"]
		token.display_name = info["name"]
		token.is_player = id == "me"
		_tokens_layer.add_child(token)
		_tokens[id] = token

	_build_top_bar()
	_build_week_panel()
	_build_contacts_bar()
	_build_card()
	_build_toasts()
	_build_incoming_tray()
	_show_important_notice(Week1.START_BRIEFING)

	sim.request_opened.connect(func(_id): _refresh_markers())
	sim.request_changed.connect(_on_request_changed)
	sim.state_changed.connect(_refresh_panels)
	sim.entry_added.connect(_on_entry_added)
	sim.crisis_started.connect(open_card.bind(true, true))
	sim.time_changed.connect(_refresh_clock)
	_refresh_all()


func _on_season_pressed(key: String) -> void:
	if key == Settings.season:
		_season_buttons[key].button_pressed = true
		return
	season_selected.emit(key)


func set_phase(new_phase: String) -> void:
	phase = new_phase
	_start_button.visible = phase == "planning"
	_tasks_button.visible = phase in ["planning", "live"]
	_incoming_tray.visible = phase in ["planning", "live"]
	for key in _season_buttons:
		_season_buttons[key].visible = phase == "planning"
	for speed in _speed_buttons:
		_speed_buttons[speed].visible = phase == "live"
	if phase != "planning":
		_close_week_panel()
		_close_important_notice()
		_close_contact_detail()
	match phase:
		"planning":
			_phase_label.text = "ПЛАНИРОВАНИЕ · ВРЕМЯ СТОИТ"
		"live":
			_phase_label.text = "ЖИВАЯ НЕДЕЛЯ"
		"summary":
			_phase_label.text = "ИТОГИ НЕДЕЛИ"
			_close_card(false)
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


func open_card(request_id: String, focus: bool = false, auto: bool = false) -> void:
	_close_contact_detail()
	if not _card.visible:
		_sfx("card_open")
		if play_log != null:
			play_log.note_card_open(request_id, auto)
	_card_request = request_id
	_card.visible = true
	if focus:
		map.focus_on(sim.requests[request_id]["data"]["lot"])
	_refresh_card()


func _process(_delta: float) -> void:
	_update_tokens()
	_update_markers(_map_area())
	# Toasts step aside while a card, briefing, task board, or summary needs attention.
	var overlay_open: bool = (
		(_overlay_panel != null and is_instance_valid(_overlay_panel))
		or (_week_panel != null and _week_panel.visible)
		or (_notice_panel != null and _notice_panel.visible)
	)
	_toast_box.visible = not _card.visible and not overlay_open


# People stand where the map says; the token's feet are the spot on the ground.
func _update_tokens() -> void:
	var paths: Array[Dictionary] = []
	for id in _tokens:
		var token: Control = _tokens[id]
		var actor: Dictionary = sim.actors[id]
		var feet: Vector2 = map.token_screen_position(id)
		token.position = feet - Vector2(32, 80)
		token.state = actor["state"]
		token.work_fraction = sim.actor_work_fraction(id)
		token.eta_text = ""
		if actor["state"] in ["travel", "driving"]:
			token.eta_text = _eta_text(sim.actor_eta_hours(id))
			var lot: String = sim.actor_target_lot(id)
			# Tolik rides with you, so only your path is drawn.
			if lot != "" and id != "tolik":
				paths.append({"from": feet - Vector2(0, 50), "to": map.lot_screen_position(lot, 0.0)})
	_path_layer.paths = paths
	_path_layer.queue_redraw()


# Markers float above their lot; when the lot is off-screen they stick to the
# edge of the free map area with an arrow pointing toward it.
func _update_markers(area: Rect2) -> void:
	for id in _markers:
		var marker: Control = _markers[id]
		var lot: String = sim.requests[id]["data"]["lot"]
		var index: int = _markers_at_lot(lot).find(id)
		var tip: Vector2 = map.lot_screen_position(lot, 14.0)
		var pos := tip - Vector2(32, 71) - Vector2(0, index * 76)
		var center := pos + Vector2(32, 32)
		var offscreen := not area.has_point(center)
		marker.edge_direction = Vector2.ZERO
		if offscreen:
			var inside := center.clamp(area.position + Vector2(40, 40), area.end - Vector2(40, 40))
			marker.edge_direction = (center - inside).normalized()
			pos = inside - Vector2(32, 32)
		marker.position = pos
		marker.set_meta("offscreen", offscreen)
		marker.time_left = sim.request_time_left(id)
		var worker: String = sim.request_worker(id)
		marker.work_fraction = sim.actor_work_fraction(worker) if worker != "" else 0.0


func _eta_text(hours: float) -> String:
	var minutes := int(ceil(hours * 60.0))
	if minutes < 60:
		return "%d мин" % max(minutes, 1)
	return ("%.1f ч" % (minutes / 60.0)).replace(".", ",")


# --- Layout ------------------------------------------------------------------

func _build_top_bar() -> void:
	var bar := _panel(INK)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_root.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	bar.add_child(row)
	_date_label = _heading("", 20, PAPER)
	_date_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(_date_label)
	_phase_label = _label("", 13, MUTED)
	row.add_child(_phase_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_money_label = _label("", 17, PAPER)
	_money_label.tooltip_text = "Влияние: взято взаймы у босса"
	row.add_child(_money_label)
	var season_row := HBoxContainer.new()
	season_row.add_theme_constant_override("separation", 4)
	row.add_child(season_row)
	for key in Settings.SEASONS:
		var button := Button.new()
		button.text = SeasonLabels[key]
		button.toggle_mode = true
		button.button_pressed = Settings.season == key
		button.tooltip_text = "Карта: " + SeasonLabels[key].to_lower() + " (перезапустит неделю)"
		button.pressed.connect(_on_season_pressed.bind(key))
		season_row.add_child(button)
		_season_buttons[key] = button
	for speed in [0.0, 1.0, 2.0, 4.0]:
		var button := Button.new()
		button.text = "Ⅱ" if speed == 0.0 else "×%d" % speed
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(46, 40)
		button.pressed.connect(speed_selected.emit.bind(speed))
		button.pressed.connect(_sfx.bind("speed_click"))
		row.add_child(button)
		_speed_buttons[speed] = button
	_start_button = _primary_button("Начать неделю →")
	_start_button.pressed.connect(start_week_pressed.emit)
	row.add_child(_start_button)
	# The folder is a map control, independent of the time controls above.
	_tasks_button = Button.new()
	_tasks_button.text = ""
	_tasks_button.theme = _paper_theme
	_tasks_button.add_theme_font_override("font", _title_font)
	_tasks_button.add_theme_font_size_override("font_size", 20)
	_tasks_button.add_theme_stylebox_override("normal", OfficeTheme.box(OfficeTheme.COVER, OfficeTheme.EDGE, 16))
	_tasks_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_tasks_button.offset_left = -250
	_tasks_button.offset_right = -16
	_tasks_button.offset_top = -104
	_tasks_button.offset_bottom = -16
	_tasks_button.pressed.connect(_toggle_week_panel)
	_root.add_child(_tasks_button)
	var folder_title := VBoxContainer.new()
	folder_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	folder_title.offset_left = 16
	folder_title.offset_top = 10
	folder_title.offset_right = -16
	folder_title.offset_bottom = -10
	folder_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tasks_button.add_child(folder_title)
	var folder_caption := _paper_label("К ИСПОЛНЕНИЮ", 11, OfficeTheme.SECONDARY)
	folder_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_title.add_child(folder_caption)
	var folder_name := _heading("Дела недели · %d" % Week1.OBJECTIVES.size(), 22)
	folder_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_title.add_child(folder_name)


func _build_week_panel() -> void:
	_week_backdrop = ColorRect.new()
	_week_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_week_backdrop.color = Color(0.12, 0.075, 0.07, 0.7)
	_week_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_week_backdrop.visible = false
	_root.add_child(_week_backdrop)
	_week_panel = _panel(OfficeTheme.COVER)
	_week_panel.theme = _paper_theme
	_week_panel.set_anchors_preset(Control.PRESET_CENTER)
	_week_panel.offset_left = -540
	_week_panel.offset_right = 540
	_week_panel.offset_top = -380
	_week_panel.offset_bottom = 380
	_week_panel.visible = false
	_root.add_child(_week_panel)
	var cover := VBoxContainer.new()
	cover.add_theme_constant_override("separation", 10)
	_week_panel.add_child(cover)
	cover.add_child(_paper_label("РАБОЧАЯ ПАПКА / 01", 12))
	var page := _paper_panel()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cover.add_child(page)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	page.add_child(layout)
	var metadata := HBoxContainer.new()
	var department := _paper_label("АДМИНИСТРАЦИЯ РАЙОНА", 12, OfficeTheme.SECONDARY)
	department.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metadata.add_child(department)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Закрыть папку"
	close_button.custom_minimum_size = Vector2(38, 38)
	close_button.pressed.connect(_close_week_panel)
	metadata.add_child(close_button)
	layout.add_child(metadata)
	var header := HBoxContainer.new()
	var title_column := VBoxContainer.new()
	title_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_column.add_child(_heading("Дела недели", 38))
	title_column.add_child(_paper_label("%s — %s" % [sim.date_text(0), sim.date_text(4)], 15, OfficeTheme.SECONDARY))
	header.add_child(title_column)
	var stamp := _paper_panel()
	stamp.custom_minimum_size.x = 190
	stamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stamp.add_theme_stylebox_override("panel", OfficeTheme.box(OfficeTheme.PAPER, OfficeTheme.BURGUNDY, 8))
	var stamp_text := _heading("К ИСПОЛНЕНИЮ", 17, OfficeTheme.BURGUNDY)
	stamp_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	stamp.add_child(stamp_text)
	header.add_child(stamp)
	layout.add_child(header)
	_week_tabs = TabContainer.new()
	_week_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_week_tabs)
	var task_column := _folder_page("Поручения")
	task_column.add_child(_paper_label("ГЛАВНАЯ ЦЕЛЬ · ДО " + Week1.WEEKLY_MANDATE["deadline"].to_upper(), 12, OfficeTheme.BURGUNDY))
	task_column.add_child(_heading(Week1.WEEKLY_MANDATE["title"], 28))
	task_column.add_child(_paper_label(Week1.WEEKLY_MANDATE["description"], 16, OfficeTheme.SECONDARY))
	var signature := _heading("П. Петрович", 17, OfficeTheme.LINK)
	signature.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	task_column.add_child(signature)
	task_column.add_child(HSeparator.new())
	_objectives_box = VBoxContainer.new()
	_objectives_box.add_theme_constant_override("separation", 14)
	task_column.add_child(_objectives_box)
	_promises_box = _folder_page("Обещания")
	_standing_box = _folder_page("Положение")
	_wire_box = _folder_page("События")
	layout.add_child(_paper_label("Помощник главы района · личный экземпляр", 12, OfficeTheme.SECONDARY))


func _folder_page(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_week_tabs.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	return column


func _show_important_notice(notice: Dictionary) -> void:
	if phase == "live":
		speed_selected.emit(0.0)
	_close_important_notice()
	_close_contact_detail()
	_notice_backdrop = ColorRect.new()
	_notice_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notice_backdrop.color = Color(0.12, 0.075, 0.07, 0.7)
	_notice_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_notice_backdrop)
	var newspaper: bool = notice.get("style", "portrait") == "newspaper"
	_notice_is_newspaper = newspaper
	var dismiss: Callable = _close_important_notice if newspaper else _continue_to_tasks
	_notice_panel = Newspaper.new() if newspaper else _paper_panel()
	_notice_panel.set_anchors_preset(Control.PRESET_CENTER)
	_notice_panel.offset_left = -470 if newspaper else -500
	_notice_panel.offset_right = 470 if newspaper else 500
	_notice_panel.offset_top = -380 if newspaper else -230
	_notice_panel.offset_bottom = 380 if newspaper else 230
	_root.add_child(_notice_panel)
	if newspaper:
		(_notice_panel as Newspaper).build(notice, notice.get("date", sim.date_text(0)), dismiss)
		return
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	_notice_panel.add_child(layout)
	var header := HBoxContainer.new()
	var eyebrow := _paper_label(notice.get("eyebrow", "ГОРОД И ЛЮДИ"), 12, OfficeTheme.SECONDARY)
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(eyebrow)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(38, 38)
	close_button.pressed.connect(dismiss)
	header.add_child(close_button)
	layout.add_child(header)
	var message := HBoxContainer.new()
	message.add_theme_constant_override("separation", 28)
	var speaker_id: String = notice.get("speaker", "boss")
	var speaker: Dictionary = Week1.BOSS if speaker_id == "boss" else Week1.ACTORS.get(speaker_id, {})
	if speaker.get("portrait", "") != "":
		var frame := _panel(OfficeTheme.PAPER.lightened(0.08))
		frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		frame.add_theme_stylebox_override("panel", OfficeTheme.box(OfficeTheme.PAPER.lightened(0.08), OfficeTheme.COVER, 5))
		frame.add_child(_face(speaker["portrait"], speaker["face"], 154))
		message.add_child(frame)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.add_theme_constant_override("separation", 16)
	text_column.add_child(_paper_label("%s · %s" % [speaker.get("name", ""), speaker.get("role", "")], 15, OfficeTheme.SECONDARY))
	text_column.add_child(_heading(notice.get("title", ""), 30))
	var body := _paper_label(notice.get("body", ""), 19)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_column.add_child(body)
	message.add_child(text_column)
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(message)
	layout.add_child(HSeparator.new())
	var continue_button := _primary_button(notice.get("button", "Продолжить →"))
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_button.pressed.connect(dismiss)
	layout.add_child(continue_button)


func _continue_to_tasks() -> void:
	_close_important_notice()
	_show_week_panel()


func _close_important_notice() -> void:
	if _notice_panel != null and is_instance_valid(_notice_panel):
		_notice_panel.queue_free()
	_notice_panel = null
	if _notice_backdrop != null and is_instance_valid(_notice_backdrop):
		_notice_backdrop.queue_free()
	_notice_backdrop = null


func _show_week_panel() -> void:
	if phase not in ["planning", "live"]:
		return
	if phase == "live":
		speed_selected.emit(0.0)
	_close_important_notice()
	_close_contact_detail()
	_close_card(false)
	_week_backdrop.visible = true
	_week_panel.visible = true
	_week_backdrop.move_to_front()
	_week_panel.move_to_front()
	_tasks_button.button_pressed = true


func _toggle_week_panel() -> void:
	if _week_panel.visible:
		_close_week_panel()
	else:
		_show_week_panel()


func _close_week_panel() -> void:
	if _week_panel != null:
		_week_panel.visible = false
	if _week_backdrop != null:
		_week_backdrop.visible = false
	if _tasks_button != null:
		_tasks_button.button_pressed = false


func _build_contacts_bar() -> void:
	var contact_count: int = Week1.ACTORS.size() - 1
	var dock := _panel(INK)
	dock.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dock.offset_left = 16
	dock.offset_right = 16 + 20 + contact_count * 54 + maxi(0, contact_count - 1) * 10
	dock.offset_top = -108
	dock.offset_bottom = -16
	dock.add_theme_stylebox_override("panel", OfficeTheme.box(INK, OfficeTheme.EDGE.darkened(0.25), 10))
	_root.add_child(dock)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 7)
	dock.add_child(layout)
	layout.add_child(_label("СВЯЗИ", 11, MUTED))
	var photos := HBoxContainer.new()
	photos.add_theme_constant_override("separation", 10)
	layout.add_child(photos)
	for id in Week1.ACTORS:
		if id == "me":
			continue
		var info: Dictionary = Week1.ACTORS[id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(54, 54)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", OfficeTheme.box(OfficeTheme.PAPER, OfficeTheme.PAPER, 3))
		button.add_theme_stylebox_override("hover", OfficeTheme.box(OfficeTheme.COVER, OfficeTheme.COVER, 3))
		button.pressed.connect(_on_contact_pressed.bind(id))
		photos.add_child(button)
		var portrait := _face(info["portrait"], info["face"], 48)
		portrait.position = Vector2(3, 3)
		portrait.size = Vector2(48, 48)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(portrait)
		var dot := ColorRect.new()
		dot.position = Vector2(44, 0)
		dot.size = Vector2(10, 10)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(dot)
		var progress := ProgressBar.new()
		progress.position = Vector2(3, 48)
		progress.size = Vector2(48, 3)
		progress.show_percentage = false
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(progress)
		_contact_cards[id] = button
		_contact_dots[id] = dot
		_contact_progress[id] = progress
	_refresh_clock()


func _on_contact_pressed(actor_id: String) -> void:
	if _contact_detail_actor == actor_id:
		_close_contact_detail()
	else:
		_show_contact_detail(actor_id)


func _build_card() -> void:
	_card = _paper_panel()
	_card.anchor_left = 0.5
	_card.anchor_right = 0.5
	_card.anchor_top = 0.5
	_card.anchor_bottom = 0.5
	_card.offset_left = -310
	_card.offset_right = 310
	_card.offset_top = -280
	_card.offset_bottom = 280
	_card.visible = false
	_root.add_child(_card)


# --- Refresh -----------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_clock()
	_refresh_panels()
	_refresh_wire()
	_refresh_markers()


func _refresh_clock() -> void:
	_date_label.text = "%s · %s" % [sim.date_text(), sim.clock_text()]
	for id in _contact_cards:
		_contact_dots[id].color = _contact_status_color(id)
		_contact_cards[id].tooltip_text = "%s · %s\n%s" % [Week1.ACTORS[id]["name"], Week1.ACTORS[id]["role"], sim.actor_status_text(id)]
		var progress: ProgressBar = _contact_progress[id]
		progress.visible = sim.actors[id]["state"] == "work"
		progress.value = sim.actor_work_fraction(id) * 100.0
	if _contact_detail_status != null and is_instance_valid(_contact_detail_status):
		_contact_detail_status.text = sim.actor_status_text(_contact_detail_actor)


func _contact_status_color(id: String) -> Color:
	match sim.actors[id]["state"]:
		"travel":
			return AMBER
		"work":
			return RUST
		"driving":
			return STEEL
	return Color(0.48, 0.74, 0.54)


func _show_contact_detail(actor_id: String) -> void:
	_close_contact_detail()
	_contact_detail_actor = actor_id
	var info: Dictionary = Week1.ACTORS[actor_id]
	var card_rect: Rect2 = _contact_cards[actor_id].get_global_rect()
	var viewport_size: Vector2 = _root.get_viewport_rect().size
	var detail_size := Vector2(360, 218)
	var detail_x: float = clampf(card_rect.position.x, 8.0, maxf(8.0, viewport_size.x - detail_size.x - 8.0))
	var detail_y: float = maxf(68.0, card_rect.position.y - detail_size.y - 8.0)

	_contact_detail_panel = _paper_panel()
	_contact_detail_panel.position = Vector2(detail_x, detail_y)
	_contact_detail_panel.custom_minimum_size = detail_size
	_contact_detail_panel.size = detail_size
	_root.add_child(_contact_detail_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	_contact_detail_panel.add_child(layout)
	var header := HBoxContainer.new()
	if info["portrait"] != "":
		header.add_child(_face(info["portrait"], info["face"], 56))
	else:
		var badge := ColorRect.new()
		badge.color = RUST
		badge.custom_minimum_size = Vector2(56, 56)
		var badge_text := _label(info["name"].substr(0, 1), 20, PAPER)
		badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_text.set_anchors_preset(Control.PRESET_FULL_RECT)
		badge_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(badge_text)
		header.add_child(badge)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(_heading(info["name"], 22))
	var role := _paper_label(info["role"], 15, OfficeTheme.SECONDARY)
	role.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity.add_child(role)
	header.add_child(identity)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(36, 36)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_button.pressed.connect(_close_contact_detail)
	header.add_child(close_button)
	layout.add_child(header)
	_contact_detail_status = _paper_label(sim.actor_status_text(actor_id), 16)
	_contact_detail_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_contact_detail_status)
	var map_button := Button.new()
	map_button.text = "Показать на карте"
	map_button.custom_minimum_size = Vector2(0, 36)
	map_button.pressed.connect(_focus_contact_on_map.bind(actor_id))
	layout.add_child(map_button)
	_contact_detail_panel.move_to_front()


func _focus_contact_on_map(actor_id: String) -> void:
	var lot_id: String = sim.actor_target_lot(actor_id)
	if lot_id == "":
		lot_id = sim.actors[actor_id]["lot"]
	_close_contact_detail()
	map.focus_on(lot_id)


func _close_contact_detail() -> void:
	if _contact_detail_panel != null and is_instance_valid(_contact_detail_panel):
		_contact_detail_panel.queue_free()
	_contact_detail_panel = null
	_contact_detail_status = null
	_contact_detail_actor = ""


func _refresh_panels() -> void:
	_money_label.text = "%s млн руб." % String.num(sim.money / 1_000_000.0, 1).replace(".", ",")
	_clear(_objectives_box)
	var number := 0
	for objective in Week1.OBJECTIVES:
		number += 1
		var status: String = sim.objective_status(objective)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		_objectives_box.add_child(row)
		row.add_child(_paper_label("%02d" % number, 14, OfficeTheme.SECONDARY))
		var text_column := VBoxContainer.new()
		text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_column.add_theme_constant_override("separation", 7)
		row.add_child(text_column)
		text_column.add_child(_heading(objective.get("title", ""), 22))
		var location: String = objective.get("lot", "")
		if Week1.LOTS.has(location):
			text_column.add_child(_paper_label(Week1.LOTS[location]["name"], 15, OfficeTheme.SECONDARY))
			var map_button := Button.new()
			map_button.text = "Показать на карте ↗"
			map_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			map_button.pressed.connect(_focus_objective_location.bind(location))
			text_column.add_child(map_button)
		var note: String = {"done": "Выполнено", "failed": "Провалено", "pending": objective.get("deadline", "")}[status]
		var deadline := _paper_label(note, 15, OfficeTheme.BURGUNDY)
		deadline.custom_minimum_size.x = 125
		deadline.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(deadline)
		_objectives_box.add_child(HSeparator.new())
	_clear(_promises_box)
	if sim.promises.is_empty():
		_promises_box.add_child(_heading("Пока никому ничего не обещали.", 24))
	for promise in sim.promises:
		var status_text: String = {"active": "до " + promise["due_text"], "kept": "сдержано", "broken": "нарушено"}[promise["status"]]
		_promises_box.add_child(_heading(promise["text"], 22))
		_promises_box.add_child(_paper_label(status_text, 15, OfficeTheme.BURGUNDY))
		_promises_box.add_child(HSeparator.new())
	_clear(_standing_box)
	for id in sim.factions:
		var row := HBoxContainer.new()
		var name_label := _paper_label(Week1.FACTIONS[id]["name"], 19)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_paper_label(sim.standing_word(sim.factions[id]), 19, OfficeTheme.LINK))
		_standing_box.add_child(row)
		_standing_box.add_child(HSeparator.new())
	_refresh_clock()
	_refresh_wire()


func _focus_objective_location(location: String) -> void:
	_close_week_panel()
	map.focus_on(location)


func _on_entry_added(entry: Dictionary) -> void:
	_refresh_wire()
	# Consequences pop up over the map where the player is looking; new
	# requests already have their own marker.
	if entry["tone"] != "request":
		_show_toast(entry)


func _refresh_wire() -> void:
	_clear(_wire_box)
	var recent: Array = sim.entries.slice(max(0, sim.entries.size() - 6))
	recent.reverse()
	if recent.is_empty():
		_wire_box.add_child(_paper_label("Пока новостей нет.", 18, OfficeTheme.SECONDARY))
		return
	for entry in recent:
		var line := _paper_label("%s  %s" % [entry["time"], entry["text"]], 18, OfficeTheme.TEXT if entry["tone"] != "request" else OfficeTheme.SECONDARY)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_wire_box.add_child(line)


# Big, readable notifications at the top of the map: the colored edge says
# whether it went well, they fade on their own, and a click dismisses them.
func _build_toasts() -> void:
	_toast_box = VBoxContainer.new()
	_toast_box.anchor_left = 0.5
	_toast_box.anchor_right = 0.5
	_toast_box.offset_left = -280
	_toast_box.offset_right = 280
	_toast_box.offset_top = 76
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_theme_constant_override("separation", 8)
	_root.add_child(_toast_box)


func _show_toast(entry: Dictionary) -> void:
	while _toast_box.get_child_count() >= 2:
		var oldest := _toast_box.get_child(0)
		_toast_box.remove_child(oldest)
		oldest.queue_free()
	var tone_color: Color = {"good": STEEL, "bad": RUST, "neutral": AMBER}.get(entry["tone"], AMBER)
	var panel := PanelContainer.new()
	var style := _style(INK, tone_color)
	style.set_border_width_all(0)
	style.border_width_left = 8
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	var label := _label(entry["text"], 19, PAPER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(520, 0)
	panel.add_child(label)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			panel.queue_free())
	_toast_box.add_child(panel)
	var tween := panel.create_tween()
	tween.tween_interval(7.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.6)
	tween.tween_callback(panel.queue_free)


func _refresh_markers() -> void:
	var visible_ids: Array[String] = []
	if phase in ["planning", "live"]:
		visible_ids = sim.visible_requests()
	for id in _markers.keys():
		if not visible_ids.has(id):
			_markers[id].queue_free()
			_markers.erase(id)
	for id in visible_ids:
		var data: Dictionary = sim.requests[id]["data"]
		if not _markers.has(id):
			var created := RequestMarker.new()
			created.pressed.connect(_on_marker_pressed.bind(id))
			created.kind = data["type"]
			if data["asker"] != "":
				var asker: Dictionary = Week1.ACTORS[data["asker"]]
				created.asker_texture = load(asker["portrait"])
				created.asker_region = asker["face"]
			created.tooltip_text = "%s\nдо %s" % [data["title"], sim.when_text(data["expire"])]
			_markers_layer.add_child(created)
			_markers[id] = created
		var marker: Control = _markers[id]
		marker.assigned = sim.requests[id]["status"] == "assigned"
		var worker: String = sim.request_worker(id)
		if worker != "":
			var worker_info: Dictionary = Week1.ACTORS[worker]
			marker.worker_texture = load(worker_info["portrait"])
			marker.worker_region = worker_info["face"]


func _refresh_card() -> void:
	if not _card.visible or _card_request == "":
		return
	_clear(_card)
	var request: Dictionary = sim.requests[_card_request]
	var data: Dictionary = request["data"]
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	_card.add_child(outer)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)

	var header := HBoxContainer.new()
	var kind := _paper_label("%s · %s" % [TYPE_NAMES[data["type"]].to_upper(), Week1.LOTS[data["lot"]]["name"]], 12, OfficeTheme.SECONDARY)
	kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(kind)
	header.add_child(_paper_label("до " + sim.when_text(data["expire"]), 12, OfficeTheme.BURGUNDY))
	column.add_child(header)

	var title := _heading(data["title"], 26)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	if data["asker"] != "":
		var asker: Dictionary = Week1.ACTORS[data["asker"]]
		body.add_child(_face(asker["portrait"], asker["face"], 72))
	var text := _paper_label(data["text"], 17, OfficeTheme.TEXT)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(text)
	column.add_child(body)

	if request["promised"]:
		column.add_child(_paper_label("Вы уже пообещали. Теперь надо сделать.", 14, OfficeTheme.BURGUNDY))
	if request["status"] == "closed":
		column.add_child(_paper_label("Вопрос закрыт.", 15, OfficeTheme.SECONDARY))
	elif request["status"] == "assigned":
		column.add_child(_paper_label("В работе.", 15, OfficeTheme.BURGUNDY))

	column.add_child(_paper_label("КОГО ОТПРАВИТЬ", 12, OfficeTheme.SECONDARY))
	for option in data["options"]:
		var reason: String = sim.option_block_reason(_card_request, option)
		var button := Button.new()
		button.text = option["label"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 40)
		button.disabled = reason != ""
		button.pressed.connect(_on_option_pressed.bind(option["id"]))
		column.add_child(button)
		var hint := _paper_label(option["hint"] + ("" if reason == "" else "  [" + reason + "]"), 14, OfficeTheme.SECONDARY)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(hint)

	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(_close_card)
	outer.add_child(close)


func _on_request_changed(_id: String) -> void:
	_refresh_markers()
	_refresh_card()


func _on_option_pressed(option_id: String) -> void:
	var request_id := _card_request
	var option: Dictionary = {}
	for candidate in sim.requests[request_id]["data"]["options"]:
		if candidate["id"] == option_id:
			option = candidate
	# Committing to a choice is a tier 2 sound; a promise has its own.
	_sfx("promise_made" if option.get("actor", "") == "promise" else "option_choose")
	sim.choose(request_id, option_id)
	# Promises keep the card open so the player can still send someone.
	if option.get("actor", "") == "promise":
		_refresh_card()
	else:
		_close_card(false)


func _close_card(play_sound: bool = true) -> void:
	if _card.visible and play_log != null and _card_request != "":
		play_log.note_card_close(_card_request)
	if play_sound and _card.visible:
		_sfx("card_close")
	_card.visible = false
	_card_request = ""


func _sfx(event_id: String) -> void:
	if audio != null:
		audio.play(event_id)


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
	_overlay_panel = _paper_panel()
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
		_overlay_panel.offset_left = -340
		_overlay_panel.offset_right = 340
		_overlay_panel.offset_top = -300
		_overlay_panel.offset_bottom = 260
	_root.add_child(_overlay_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_overlay_panel.add_child(column)
	column.add_child(_paper_label(subtitle.to_upper(), 12, OfficeTheme.SECONDARY))
	column.add_child(_heading(title, 30))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)
	for line_text in lines:
		var line := _paper_label(line_text, 17)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(line)
	var button := _primary_button(button_text)
	button.custom_minimum_size = Vector2(0, 44)
	button.add_theme_stylebox_override("normal", _style(RUST))
	button.add_theme_stylebox_override("hover", _style(RUST.lightened(0.12)))
	button.pressed.connect(action)
	column.add_child(button)


# --- Helpers -----------------------------------------------------------------

func _on_marker_pressed(id: String) -> void:
	open_card(id, _markers[id].get_meta("offscreen", false))


# The part of the screen where the map is visible, between the panels.
func _map_area() -> Rect2:
	var size := _root.get_viewport_rect().size
	return Rect2(Vector2(12, 68), Vector2(size.x - 24, size.y - 68 - 116))


func _markers_at_lot(lot: String) -> Array:
	return _markers.keys().filter(func(id): return sim.requests[id]["data"]["lot"] == lot)


func _make_theme() -> Theme:
	return OfficeTheme.make_theme()


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
	var style := _style(color, OfficeTheme.EDGE.darkened(0.15))
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
	# HBox containers otherwise stretch the crop to the tallest sibling. Keep
	# portraits square even when the dialog body expands to fill its window.
	rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return rect


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _paper_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.theme = _paper_theme
	var style := OfficeTheme.box(OfficeTheme.PAPER, OfficeTheme.COVER, 24)
	style.shadow_color = Color(0.1, 0.06, 0.05, 0.4)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _paper_label(text: String, size: int, color: Color = OfficeTheme.TEXT) -> Label:
	var label := _label(text, size, color)
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return label


func _heading(text: String, size: int, color: Color = OfficeTheme.TEXT) -> Label:
	var label := _paper_label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", _title_font)
	return label


func _primary_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.add_theme_stylebox_override("normal", OfficeTheme.box(OfficeTheme.BURGUNDY, OfficeTheme.BURGUNDY, 12))
	button.add_theme_stylebox_override("hover", OfficeTheme.box(OfficeTheme.BURGUNDY.lightened(0.1), OfficeTheme.BURGUNDY, 12))
	button.add_theme_stylebox_override("pressed", OfficeTheme.box(OfficeTheme.BURGUNDY.darkened(0.1), OfficeTheme.BURGUNDY, 12))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, OfficeTheme.LIGHT_TEXT)
	return button


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _notice_panel != null:
		if _notice_is_newspaper:
			_close_important_notice()
		else:
			_continue_to_tasks()
	elif _week_panel.visible:
		_close_week_panel()
	elif _contact_detail_panel != null:
		_close_contact_detail()
	elif _card.visible:
		_close_card()
	else:
		return
	get_viewport().set_input_as_handled()


func _build_incoming_tray() -> void:
	_incoming_tray = VBoxContainer.new()
	_incoming_tray.anchor_left = 1.0
	_incoming_tray.anchor_right = 1.0
	_incoming_tray.offset_left = -270
	_incoming_tray.offset_right = -16
	_incoming_tray.offset_top = 86
	_incoming_tray.add_theme_constant_override("separation", 8)
	_root.add_child(_incoming_tray)
	var caption := _label("НА ВАШЕМ СТОЛЕ", 11, PAPER)
	caption.add_theme_color_override("font_shadow_color", INK)
	caption.add_theme_constant_override("shadow_offset_y", 1)
	caption.add_theme_constant_override("shadow_outline_size", 2)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_incoming_tray.add_child(caption)
	var order := Button.new()
	order.text = "ПЁТР ПЕТРОВИЧ\nПоручение на неделю"
	order.add_theme_font_size_override("font_size", 14)
	order.pressed.connect(_show_important_notice.bind(Week1.START_BRIEFING))
	_incoming_tray.add_child(order)
	var newspaper := Button.new()
	newspaper.text = "ГОРОДСКИЕ ВЕСТИ\nУтренний выпуск"
	newspaper.add_theme_font_size_override("font_size", 14)
	newspaper.pressed.connect(_show_important_notice.bind(Week1.MORNING_NEWS))
	_incoming_tray.add_child(newspaper)
