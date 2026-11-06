# Screen UI over the 3D map: top bar, weekly task board, important notices,
# contacts, request markers/cards, and the week summary. Built in code while
# the prototype layout is still changing quickly.
extends CanvasLayer

const OfficeSkin = preload("res://scripts/ui/office_skin.gd")
const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const OfficeIcons = preload("res://scripts/ui/office_icons.gd")
const OfficePaper = preload("res://scripts/ui/office_paper.gd")
const OfficeProgress = preload("res://scripts/ui/office_progress.gd")
const OfficeStatus = preload("res://scripts/ui/office_status.gd")
const OfficeMotion = preload("res://scripts/ui/office_motion.gd")
const Newspaper = preload("res://scripts/ui/newspaper.gd")
const NewspaperIssues = preload("res://scripts/data/newspaper_issues.gd")
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
var _top_bar: PanelContainer
var _top_row: HBoxContainer
var _day_label: Label
var _clock_label: Label
var _phase_detail: Label
var _current_speed := 0.0
var _date_label: Label
var _phase_label: Label
var _money_label: Label
var _boss_notice_button: Button
var _paperwork_map_button: Button
var _paperwork_folder_button: Button
var _paperwork_progress: OfficeProgress
var _paperwork_progress_label: Label
var _start_button: Button
var _tasks_button: Button
var _map_controls: PanelContainer
var _speed_buttons := {}
var _time_controls: HBoxContainer
var _season_buttons := {}
var _season_controls: HBoxContainer
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
var _notice_hid_overlay := false
var _incoming_tray: VBoxContainer
var _newspaper_button: Button
var _paper_theme := OfficeTheme.make_theme(true)
var _title_font := OfficeTheme.heading_font()
var _contact_progress := {} # actor id -> work progress
var _contact_dots := {} # actor id -> availability color
var _contact_cards := {} # actor id -> compact card
var _contacts_dock: PanelContainer
var _contacts_button: Button
var _contacts_scroll: ScrollContainer
var _contact_drawer: PanelContainer
var _contact_drawer_backdrop: ColorRect
var _contact_drawer_status := {}
var _contact_drawer_dots := {}
var _contact_drawer_open := false
var _contact_drawer_tween: Tween
var _contact_detail_panel: PanelContainer
var _contact_detail_status: Label
var _contact_detail_lamp: OfficeStatus
var _contact_detail_map_button: Button
var _contact_detail_actor := ""
var _path_layer: Control
var _tokens_layer: Control
var _tokens := {} # actor id -> PersonToken
var _markers_layer: Control
var _markers := {} # request id -> RequestMarker
var _card: PanelContainer
var _card_request := ""
var _overlay_panel: PanelContainer
var _overlay_list: VBoxContainer # Body of the current overlay, for screens that add their own rows.
var _card_wait_label: Label # The card's wait line; ticks with the clock.
var _toast_box: VBoxContainer


func setup(week_sim, city_map, audio_manager = null, playtest_log = null) -> void:
	sim = week_sim
	map = city_map
	audio = audio_manager
	play_log = playtest_log
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _make_theme()
	add_child(_root)
	Settings.load_interface_preferences()
	Settings.ui_events.scale_changed.connect(_apply_interface_scale)
	get_viewport().size_changed.connect(_apply_interface_scale)
	_apply_interface_scale()

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
	for id in Week1.enabled_actor_ids():
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
	_build_map_controls()
	show_newspaper()

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
	_tasks_button.visible = phase in ["planning", "live"] and sim.flags.get("boss_briefing_received", false)
	_incoming_tray.visible = phase in ["planning", "live"]
	_newspaper_button.visible = phase == "planning" and NewspaperIssues.ISSUES.has(sim.week)
	_season_controls.visible = phase == "planning"
	_time_controls.visible = phase == "live"
	for speed in _speed_buttons:
		_speed_buttons[speed].visible = phase == "live"
	if phase != "planning":
		_close_week_panel()
		_close_important_notice()
		_close_contact_detail()
		_close_contacts_drawer()
	match phase:
		"planning":
			pass
		"live":
			pass
		"summary":
			pass
			_close_card(false)
			_show_summary()
		"week2":
			pass
	_refresh_all()
	_layout_top_bar.call_deferred()


func set_speed(speed: float) -> void:
	_current_speed = speed
	for value in _speed_buttons:
		_speed_buttons[value].set_pressed_no_signal(is_equal_approx(value, speed))
	_refresh_time_status()


const DAY_FULL_NAMES := ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"]
const MONTHS_GENITIVE := ["января", "февраля", "марта", "апреля", "мая", "июня", "июля", "августа", "сентября", "октября", "ноября", "декабря"]
const DAY_CARD_SECONDS := 3.0 # How long the night takes to pass on the map behind the card.

var _day_card: PanelContainer
var _day_card_done := Callable()


# A new day: a big calendar sheet flips in at the centre while the night passes on
# the map. Time stays paused until "Продолжить"; then the sheet falls away and
# `done` runs.
func show_day_card(day: int, done: Callable) -> void:
	var date: Vector2i = sim.day_date(day)
	var sheet := _paper_panel()
	sheet.anchor_left = 0.5
	sheet.anchor_right = 0.5
	sheet.anchor_top = 0.5
	sheet.anchor_bottom = 0.5
	sheet.offset_left = -260
	sheet.offset_right = 260
	sheet.offset_top = -170
	sheet.offset_bottom = 170
	_root.add_child(sheet)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 4)
	sheet.add_child(column)
	for line in [
		[DAY_FULL_NAMES[day].to_upper(), 22, OfficeTheme.SECONDARY, false],
		[str(date.x), 110, OfficeTheme.BURGUNDY, true],
		["%s %d" % [MONTHS_GENITIVE[date.y - 1], Week1.YEAR], 26, OfficeTheme.TEXT, true],
	]:
		var label := _heading(line[0], line[1], line[2]) if line[3] else _paper_label(line[0], line[1], line[2])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
	var button := _primary_button("Продолжить")
	button.custom_minimum_size = Vector2(220, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(continue_day)
	column.add_child(button)
	_day_card = sheet
	_day_card_done = done
	# Flip in from the top edge like a tear-off calendar.
	sheet.pivot_offset = Vector2(260, 0)
	sheet.scale = Vector2(1, 0)
	sheet.create_tween().tween_property(sheet, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	button.grab_focus.call_deferred()


# Closes the day card: the sheet drops and fades, then the day starts.
func continue_day() -> void:
	if _day_card == null:
		return
	var sheet := _day_card
	var done := _day_card_done
	_day_card = null
	_day_card_done = Callable()
	_sfx("card_open")
	var tween := sheet.create_tween()
	tween.tween_property(sheet, "offset_top", -110.0, 0.35).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sheet, "offset_bottom", 230.0, 0.35).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sheet, "modulate:a", 0.0, 0.35)
	tween.tween_callback(sheet.queue_free)
	done.call()


func show_week_two(changes: Array[String]) -> void:
	set_phase("week2")
	var lines: Array[String] = []
	lines.assign(changes)
	lines.append("Здесь прототип первой недели заканчивается.")
	# Compact and off to the side: the point of this screen is the changed map.
	_show_overlay("Понедельник, " + sim.date_text(0).substr(3), "Что изменилось за выходные", lines, "Сыграть заново", restart_pressed.emit, true)
	show_newspaper()


func open_card(request_id: String, focus: bool = false, auto: bool = false) -> void:
	_close_contact_detail()
	if not _card.visible:
		OfficeMotion.reveal(_card)
		_sfx("card_open")
		if play_log != null:
			play_log.note_card_open(request_id, auto)
	_card_request = request_id
	_card.visible = true
	_sync_modal_input()
	if focus:
		map.focus_on(sim.requests[request_id]["data"]["lot"])
	_refresh_card()


func _process(_delta: float) -> void:
	_sync_modal_input()
	_update_tokens()
	_update_markers(_map_area())
	# Toasts step aside while a card, briefing, task board, or summary needs attention.
	var overlay_open: bool = (
		(_overlay_panel != null and is_instance_valid(_overlay_panel))
		or (_week_panel != null and _week_panel.visible)
		or (_notice_panel != null and _notice_panel.visible)
		or (_contact_drawer != null and _contact_drawer.visible)
	)
	_toast_box.visible = not _card.visible and not overlay_open
	_map_controls.visible = not overlay_open and not _card.visible


# People stand where the map says; the token's feet are the spot on the ground.
func _update_tokens() -> void:
	var paths: Array[PackedVector2Array] = []
	var icon_scale: float = map.map_icon_scale()
	for id in _tokens:
		var token: Control = _tokens[id]
		token.visible = sim.actor_available(id)
		if not token.visible:
			continue
		var actor: Dictionary = sim.actors[id]
		var feet: Vector2 = _root.get_global_transform().affine_inverse() * map.token_screen_position(id)
		token.scale = Vector2.ONE * icon_scale
		token.position = feet - Vector2(32, 80) * icon_scale
		token.state = actor["state"]
		token.work_fraction = sim.actor_work_fraction(id)
		token.eta_text = ""
		if actor["state"] in ["travel", "driving"]:
			token.eta_text = _eta_text(sim.actor_eta_hours(id))
			# Tolik rides with you, so only your path is drawn: the road still ahead.
			if id != "tolik":
				var route: PackedVector2Array = sim.actor_route(id)
				var line := PackedVector2Array([feet - Vector2(0, 50) * icon_scale])
				for i in range(1, route.size()):
					line.append(_root.get_global_transform().affine_inverse() * map.ground_screen_position(route[i]))
				paths.append(line)
	_path_layer.paths = paths
	_path_layer.queue_redraw()


# Markers float above their lot; when the lot is off-screen they stick to the
# edge of the free map area with an arrow pointing toward it.
func _update_markers(area: Rect2) -> void:
	var icon_scale: float = map.map_icon_scale()
	# Include names, not just portrait circles. Waiting request markers must not
	# cover the person standing at their location (often the requester herself).
	var occupied: Array[Rect2] = []
	for token: Control in _tokens.values():
		if not token.visible:
			continue
		var top := -24.0 if token.eta_text != "" else 0.0
		occupied.append(Rect2(token.position + Vector2(-16, top) * icon_scale, Vector2(96, 62 - top) * icon_scale))
	for id in _markers:
		var marker: Control = _markers[id]
		var lot: String = sim.requests[id]["data"]["lot"]
		var index: int = _markers_at_lot(lot).find(id)
		var tip: Vector2 = _root.get_global_transform().affine_inverse() * map.lot_screen_position(lot, 14.0)
		var center := tip - Vector2(0, 39 + index * 76) * icon_scale
		var offscreen := not area.has_point(center)
		marker.edge_direction = Vector2.ZERO
		var marker_scale := icon_scale
		if offscreen:
			var inside := center.clamp(area.position + Vector2(40, 40), area.end - Vector2(40, 40))
			marker.edge_direction = (center - inside).normalized()
			center = inside
			marker_scale = 1.0
		else:
			center = _clear_marker_center(center, area, occupied, icon_scale)
		marker.scale = Vector2.ONE * marker_scale
		marker.position = center - Vector2(32, 32) * marker_scale
		occupied.append(Rect2(center - Vector2.ONE * 40 * marker_scale, Vector2.ONE * 80 * marker_scale))
		marker.set_meta("offscreen", offscreen)
		marker.time_left = sim.request_time_left(id)
		var worker: String = sim.request_worker(id)
		marker.work_fraction = sim.actor_work_fraction(worker) if worker != "" else 0.0


# Pick the closest clear position, preferring a horizontal move so the marker
# stays beside its requester. Recompute from the map anchor each frame; offsets
# never accumulate while panning or zooming.
func _clear_marker_center(anchor: Vector2, area: Rect2, occupied: Array[Rect2], icon_scale: float) -> Vector2:
	var half := Vector2.ONE * 40 * icon_scale
	var candidates: Array[Vector2] = [anchor]
	for rect in occupied:
		candidates.append(Vector2(rect.end.x + half.x + 4, anchor.y))
		candidates.append(Vector2(rect.position.x - half.x - 4, anchor.y))
		candidates.append(Vector2(anchor.x, rect.position.y - half.y - 4))
		candidates.append(Vector2(anchor.x, rect.end.y + half.y + 4))
	var best := anchor
	var best_distance := INF
	for candidate in candidates:
		var bounds := Rect2(candidate - half, half * 2)
		if not area.encloses(bounds):
			continue
		var clear := true
		for rect in occupied:
			if rect.intersects(bounds):
				clear = false
				break
		if clear and candidate.distance_squared_to(anchor) < best_distance:
			best = candidate
			best_distance = candidate.distance_squared_to(anchor)
	return best


func _eta_text(hours: float) -> String:
	var minutes := int(ceil(hours * 60.0))
	if minutes < 60:
		return "%d мин" % max(minutes, 1)
	return ("%.1f ч" % (minutes / 60.0)).replace(".", ",")


# --- Layout ------------------------------------------------------------------

func _build_map_controls() -> void:
	_map_controls = _panel(OfficeTheme.PAPER)
	_map_controls.theme = _paper_theme
	_map_controls.add_theme_stylebox_override("panel", _clear_surface(40, 6))
	var plan := AtlasTexture.new()
	plan.atlas = preload("res://assets/ui/navigation_plan.png")
	plan.region = Rect2(9, 102, 1008, 131)
	_skin(_map_controls, plan)
	_map_controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_map_controls.offset_left = -225
	_map_controls.offset_right = 225
	_map_controls.offset_top = -58
	_map_controls.offset_bottom = -14
	_root.add_child(_map_controls)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_map_controls.add_child(row)
	var out := Button.new()
	out.text = ""
	var minus := ColorRect.new()
	minus.color = OfficeTheme.TEXT
	minus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	out.add_child(minus)
	minus.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	minus.offset_left = -7
	minus.offset_right = 7
	minus.offset_top = -1
	minus.offset_bottom = 1
	_style_strip_button(out)
	out.custom_minimum_size.x = 48
	out.tooltip_text = "Отдалить карту · колесо вниз или −"
	out.custom_minimum_size = Vector2(48, 28)
	out.pressed.connect(map.zoom_by.bind(1.25))
	row.add_child(out)
	row.add_child(VSeparator.new())
	var closer := Button.new()
	closer.text = "+"
	_style_strip_button(closer)
	closer.custom_minimum_size.x = 48
	closer.tooltip_text = "Приблизить карту · колесо вверх или +"
	closer.custom_minimum_size = Vector2(48, 28)
	closer.pressed.connect(map.zoom_by.bind(0.8))
	row.add_child(closer)
	row.add_child(VSeparator.new())
	var home := Button.new()
	home.text = "К себе"
	_style_strip_button(home)
	_button_icon(home, "locate")
	home.tooltip_text = "Вернуться к ГГ и обычному масштабу · Home"
	home.add_theme_font_size_override("font_size", 18)
	home.pressed.connect(map.reset_view)
	row.add_child(home)
	row.add_child(VSeparator.new())
	var overview := Button.new()
	overview.text = "Район"
	_style_strip_button(overview)
	_button_icon(overview, "map")
	overview.tooltip_text = "Показать весь район"
	overview.add_theme_font_size_override("font_size", 18)
	overview.pressed.connect(map.show_overview)
	row.add_child(overview)
	for button in [out, closer, home, overview]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _build_top_bar() -> void:
	var bar := _panel(OfficeTheme.PAPER)
	_top_bar = bar
	bar.theme = _paper_theme
	var stock := OfficeTheme.paper(12)
	stock.content_margin_left = 24
	stock.content_margin_right = 24
	stock.content_margin_top = 8
	stock.content_margin_bottom = 8
	stock.set_border_width_all(0)
	stock.shadow_size = 2
	bar.add_theme_stylebox_override("panel", stock)
	_decorate_paper(bar)
	_root.add_child(bar)
	var row := HBoxContainer.new()
	_top_row = row
	row.add_theme_constant_override("separation", 16)
	row.custom_minimum_size.y = 44
	bar.add_child(row)
	var calendar := VBoxContainer.new()
	calendar.add_theme_constant_override("separation", 0)
	calendar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(calendar)
	_day_label = _heading("", 16)
	_day_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	calendar.add_child(_day_label)
	_date_label = _heading("", 24, OfficeTheme.BURGUNDY)
	_date_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	calendar.add_child(_date_label)
	row.add_child(VSeparator.new())
	_clock_label = _heading("", 24, OfficeTheme.BURGUNDY)
	_clock_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_clock_label)
	row.add_child(VSeparator.new())
	var status := VBoxContainer.new()
	status.add_theme_constant_override("separation", 2)
	status.custom_minimum_size.x = 255
	status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(status)
	_phase_label = _heading("", 18, OfficeTheme.BURGUNDY)
	_phase_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.add_child(_phase_label)
	_phase_detail = _heading("", 16)
	_phase_detail.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.add_child(_phase_detail)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var wallet := HBoxContainer.new()
	wallet.tooltip_text = "Личные деньги героя · можно потратить на поездки и помощь по обращениям"
	wallet.add_theme_constant_override("separation", 8)
	wallet.add_child(_icon("wallet", 32, OfficeTheme.LINK))
	_money_label = _heading("", 19)
	_money_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_money_label.size_flags_vertical = Control.SIZE_FILL
	_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_money_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet.add_child(_money_label)
	row.add_child(VSeparator.new())
	row.add_child(wallet)
	_season_controls = HBoxContainer.new()
	_season_controls.add_theme_constant_override("separation", 4)
	row.add_child(VSeparator.new())
	row.add_child(_season_controls)
	for key in Settings.SEASONS:
		var button := Button.new()
		button.text = SeasonLabels[key]
		_style_strip_button(button)
		button.toggle_mode = true
		button.button_pressed = Settings.season == key
		button.tooltip_text = "Карта: " + SeasonLabels[key].to_lower() + " (перезапустит неделю)"
		button.pressed.connect(_on_season_pressed.bind(key))
		_season_controls.add_child(button)
		_season_buttons[key] = button
	row.add_child(VSeparator.new())
	var time_controls := HBoxContainer.new()
	_time_controls = time_controls
	time_controls.add_theme_constant_override("separation", 8)
	row.add_child(time_controls)
	var speed_group := ButtonGroup.new()
	speed_group.allow_unpress = false
	for speed in Settings.TIME_SPEEDS:
		var button := Button.new()
		button.text = "Ⅱ" if speed == 0.0 else "×%d" % speed
		_style_strip_button(button)
		button.toggle_mode = true
		button.button_group = speed_group
		button.custom_minimum_size = Vector2(46, 44)
		button.tooltip_text = "Пауза / продолжить · Space" if speed == 0.0 else "Скорость времени: ×%d" % speed
		button.pressed.connect(speed_selected.emit.bind(speed))
		button.pressed.connect(_sfx.bind("speed_click"))
		time_controls.add_child(button)
		_speed_buttons[speed] = button
	_start_button = _primary_button("Начать день →")
	_start_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_start_button.pressed.connect(start_week_pressed.emit)
	row.add_child(_start_button)
	var restart := Button.new()
	restart.name = "RestartSimulation"
	restart.text = "Заново"
	_style_strip_button(restart)
	restart.tooltip_text = "Начать с первого понедельника, 06:00. Текущий прогресс будет сброшен."
	restart.focus_mode = Control.FOCUS_NONE
	restart.pressed.connect(func():
		restart.disabled = true
		restart_pressed.emit())
	row.add_child(VSeparator.new())
	row.add_child(restart)
	get_viewport().size_changed.connect(_layout_top_bar)
	_top_row.minimum_size_changed.connect(func(): _layout_top_bar.call_deferred())
	_layout_top_bar.call_deferred()
	# The folder is a map control, independent of the time controls above.
	_tasks_button = Button.new()
	_tasks_button.text = ""
	_tasks_button.tooltip_text = "Открыть рабочую папку: поручения, обещания и отношения"
	_tasks_button.theme = _paper_theme
	_tasks_button.add_theme_font_override("font", _title_font)
	_tasks_button.add_theme_font_size_override("font_size", 20)
	_tasks_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_tasks_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_tasks_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_tasks_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_tasks_button.offset_left = -290
	_tasks_button.offset_right = -16
	_tasks_button.offset_top = -122
	_tasks_button.offset_bottom = -16
	_tasks_button.pressed.connect(_toggle_week_panel)
	_root.add_child(_tasks_button)
	var folder_art := TextureRect.new()
	folder_art.texture = load("res://assets/ui/work_folder.png")
	folder_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	folder_art.stretch_mode = TextureRect.STRETCH_SCALE
	folder_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	folder_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tasks_button.add_child(folder_art)
	_tasks_button.mouse_entered.connect(func(): folder_art.modulate = Color(1.06, 1.06, 1.06))
	_tasks_button.mouse_exited.connect(func(): folder_art.modulate = Color.WHITE)
	var folder_title := VBoxContainer.new()
	folder_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	folder_title.offset_left = 23
	folder_title.offset_top = 12
	folder_title.offset_right = -23
	folder_title.offset_bottom = -10
	folder_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tasks_button.add_child(folder_title)
	var folder_caption := _paper_label("К ИСПОЛНЕНИЮ", 11, OfficeTheme.SECONDARY)
	folder_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_title.add_child(folder_caption)
	var label_gap := Control.new()
	label_gap.custom_minimum_size.y = 12
	label_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_title.add_child(label_gap)
	var folder_row := HBoxContainer.new()
	folder_row.add_theme_constant_override("separation", 10)
	folder_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_row.add_child(_icon("folder", 24, OfficeTheme.BURGUNDY))
	folder_title.add_child(folder_row)
	var folder_name := _heading("Дела недели · %d" % Week1.OBJECTIVES.size(), 19)
	folder_name.autowrap_mode = TextServer.AUTOWRAP_OFF
	folder_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	folder_row.add_child(folder_name)
	_paperwork_map_button = Button.new()
	_paperwork_map_button.theme = _paper_theme
	_button_icon(_paperwork_map_button, "pen")
	_paperwork_map_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_paperwork_map_button.offset_left = -290
	_paperwork_map_button.offset_right = -16
	_paperwork_map_button.offset_top = -186
	_paperwork_map_button.offset_bottom = -132
	_paperwork_map_button.add_theme_font_size_override("font_size", 14)
	_paperwork_map_button.pressed.connect(_on_paperwork_pressed)
	_root.add_child(_paperwork_map_button)


func _build_week_panel() -> void:
	_week_backdrop = ColorRect.new()
	_week_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_week_backdrop.color = Color(0.12, 0.075, 0.07, 0.7)
	_week_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_week_backdrop.mouse_force_pass_scroll_events = false
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
	stamp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamp_text.size_flags_vertical = Control.SIZE_FILL
	stamp.add_child(stamp_text)
	header.add_child(stamp)
	layout.add_child(header)
	_week_tabs = TabContainer.new()
	# Arrow keys belong to the map; clicking a tab must not capture them.
	_week_tabs.tab_focus_mode = Control.FOCUS_NONE
	_week_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(_week_tabs)
	var task_column := _folder_page("Поручения")
	task_column.add_child(_paper_label("ГЛАВНАЯ ЦЕЛЬ · ДО " + Week1.WEEKLY_MANDATE["deadline"].to_upper(), 12, OfficeTheme.BURGUNDY))
	task_column.add_child(_heading(Week1.WEEKLY_MANDATE["title"], 28))
	var mandate_text := _paper_label(Week1.WEEKLY_MANDATE["description"], 16, OfficeTheme.SECONDARY)
	mandate_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_column.add_child(mandate_text)
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
	# Keep signatures, deadlines and rules clear of the scrollbar on every page.
	var inset := MarginContainer.new()
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inset.add_theme_constant_override("margin_right", 16)
	inset.add_theme_constant_override("margin_bottom", 8)
	scroll.add_child(inset)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	inset.add_child(column)
	return column


func _show_important_notice(notice: Dictionary) -> void:
	_close_contacts_drawer(false)
	if phase == "live":
		speed_selected.emit(0.0)
	_close_important_notice()
	_close_contact_detail()
	_notice_backdrop = ColorRect.new()
	_notice_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_notice_backdrop.color = Color(0.12, 0.075, 0.07, 0.7)
	_notice_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_notice_backdrop.mouse_force_pass_scroll_events = false
	_root.add_child(_notice_backdrop)
	var newspaper: bool = notice.get("style", "portrait") == "newspaper"
	_notice_is_newspaper = newspaper
	if newspaper and is_instance_valid(_overlay_panel) and _overlay_panel.visible:
		_overlay_panel.hide()
		_notice_hid_overlay = true
	var dismiss: Callable = _close_important_notice if newspaper else _continue_to_tasks
	_notice_panel = Newspaper.new() if newspaper else _paper_panel()
	_notice_panel.set_anchors_preset(Control.PRESET_CENTER)
	_notice_panel.offset_left = -500
	_notice_panel.offset_right = 500
	_notice_panel.offset_top = -395 if newspaper else -230
	_notice_panel.offset_bottom = 395 if newspaper else 230
	_root.add_child(_notice_panel)
	OfficeMotion.reveal(_notice_panel)
	_sync_modal_input()
	if newspaper:
		(_notice_panel as Newspaper).build(notice, notice.get("date", sim.date_text()), dismiss)
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
	if _notice_hid_overlay and is_instance_valid(_overlay_panel):
		_overlay_panel.show()
	_notice_hid_overlay = false
	if _notice_panel != null and is_instance_valid(_notice_panel):
		_notice_panel.queue_free()
	_notice_panel = null
	if _notice_backdrop != null and is_instance_valid(_notice_backdrop):
		_notice_backdrop.queue_free()
	_notice_backdrop = null


func _show_week_panel() -> void:
	_close_contacts_drawer(false)
	if phase not in ["planning", "live"]:
		return
	if phase == "live":
		speed_selected.emit(0.0)
	_close_important_notice()
	_close_contact_detail()
	_close_card(false)
	_week_backdrop.visible = true
	_week_panel.visible = true
	OfficeMotion.reveal(_week_panel)
	OfficeMotion.reveal(_week_backdrop, 0.12)
	_sync_modal_input()
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
	_contacts_dock = _panel(OfficeTheme.PAPER)
	_contacts_dock.theme = _paper_theme
	_contacts_dock.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_contacts_dock.offset_left = 16
	_contacts_dock.offset_bottom = -10
	_contacts_dock.add_theme_stylebox_override("panel", _clear_surface(0, 0))
	_root.add_child(_contacts_dock)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_contacts_dock.add_child(row)
	_contacts_button = Button.new()
	_contacts_button.text = ""
	_skin(_contacts_button, preload("res://assets/ui/contact_index.png"))
	_contacts_button.tooltip_text = "Все контакты"
	_contacts_button.custom_minimum_size = Vector2(174, 80)
	_style_strip_button(_contacts_button)
	var label := _heading("│  СВЯЗИ", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.position = Vector2(60, 30)
	var card_icon := _icon("index_card", 25)
	card_icon.position = Vector2(30, 29)
	_contacts_button.add_child(card_icon)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_contacts_button.add_child(label)
	_contacts_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_contacts_button.add_theme_font_size_override("font_size", 14)
	_contacts_button.pressed.connect(_toggle_contacts_drawer)
	row.add_child(_contacts_button)
	_contacts_scroll = ScrollContainer.new()
	_contacts_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contacts_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_contacts_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(_contacts_scroll)
	var photos := HBoxContainer.new()
	photos.add_theme_constant_override("separation", 8)
	_contacts_scroll.add_child(photos)
	for id in Week1.enabled_actor_ids():
		if id == "me":
			continue
		var info: Dictionary = Week1.ACTORS[id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(64, 68)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", OfficeTheme.box(OfficeTheme.PAPER.lightened(0.08), OfficeTheme.EDGE, 2))
		button.pressed.connect(_on_contact_pressed.bind(id))
		photos.add_child(button)
		var photo := PanelContainer.new()
		photo.position = Vector2(7, 0)
		var style := OfficeTheme.box(Color("f8f0df"), OfficeTheme.EDGE, 3)
		style.shadow_color = Color(0.15, 0.1, 0.08, 0.25)
		style.shadow_size = 2
		style.shadow_offset = Vector2(1, 2)
		photo.add_theme_stylebox_override("panel", style)
		photo.add_child(_face(info["portrait"], info["face"], 44))
		_ignore_mouse(photo)
		button.add_child(photo)
		var name_label := _paper_label(info["name"], 12)
		name_label.position = Vector2(0, 52)
		name_label.size = Vector2(64, 16)
		name_label.clip_text = true
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(name_label)
		var dot := OfficeStatus.new()
		dot.position = Vector2(48, -2)
		dot.size = Vector2(12, 12)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(dot)
		var progress := OfficeProgress.new()
		progress.position = Vector2(10, 46)
		progress.size = Vector2(44, 3)
		button.add_child(progress)
		_contact_cards[id] = button
		_contact_dots[id] = dot
		_contact_progress[id] = progress
	_build_contacts_drawer()
	_root.resized.connect(_layout_contacts_dock)
	_refresh_clock()


func _layout_contacts_dock() -> void:
	if _contacts_dock == null or _contacts_button == null:
		return
	var active := 0
	for button: Button in _contact_cards.values():
		if button.visible:
			active += 1
	var desired := 174 + (8 + active * 64 + maxi(0, active - 1) * 8 if active > 0 else 0)
	var available := maxf(174, _root.size.x / 2 - 240)
	var width := minf(desired, available)
	_contacts_dock.offset_right = 16 + width
	_contacts_scroll.visible = active > 0
	_contacts_scroll.custom_minimum_size.y = 88 if desired > width else 68
	_contacts_dock.offset_top = -(16 + 20 + (88 if desired > width else 68)) if active > 0 else -90


func _build_contacts_drawer() -> void:
	_contact_drawer_backdrop = ColorRect.new()
	_contact_drawer_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_contact_drawer_backdrop.color = Color(0.12, 0.08, 0.06, 0.25)
	_contact_drawer_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_contact_drawer_backdrop.mouse_force_pass_scroll_events = false
	_contact_drawer_backdrop.visible = false
	_contact_drawer_backdrop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_close_contacts_drawer())
	_root.add_child(_contact_drawer_backdrop)
	_contact_drawer = _paper_panel()
	_contact_drawer.anchor_left = 0
	_contact_drawer.anchor_right = 0
	_contact_drawer.anchor_bottom = 1
	_contact_drawer.offset_left = 16
	_contact_drawer.offset_right = 376
	_contact_drawer.offset_top = 84
	_contact_drawer.offset_bottom = -16
	_contact_drawer.visible = false
	_root.add_child(_contact_drawer)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	_contact_drawer.add_child(layout)
	var header := HBoxContainer.new()
	var title := _heading("Связи", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Закрыть контакты"
	close.pressed.connect(_close_contacts_drawer)
	header.add_child(close)
	layout.add_child(header)
	layout.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_force_pass_scroll_events = false
	layout.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for id in Week1.enabled_actor_ids():
		if id == "me":
			continue
		var info: Dictionary = Week1.ACTORS[id]
		var entry := Button.new()
		entry.custom_minimum_size.y = 104
		entry.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		entry.pressed.connect(_on_contact_pressed.bind(id))
		list.add_child(entry)
		var contents := HBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.offset_left = 6
		contents.offset_right = -6
		contents.offset_top = 8
		contents.offset_bottom = -8
		contents.add_theme_constant_override("separation", 12)
		contents.add_child(_face(info["portrait"], info["face"], 48))
		var copy := VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_child(_heading(info["name"], 19))
		copy.add_child(_paper_label(info["role"], 12, OfficeTheme.SECONDARY))
		var status_row := HBoxContainer.new()
		status_row.add_theme_constant_override("separation", 5)
		var lamp := OfficeStatus.new()
		lamp.custom_minimum_size = Vector2(12, 18)
		lamp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		status_row.add_child(lamp)
		_contact_drawer_dots[id] = lamp
		var status := _paper_label("", 13)
		status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_row.add_child(status)
		copy.add_child(status_row)
		_contact_drawer_status[id] = status
		contents.add_child(copy)
		_ignore_mouse(contents)
		entry.add_child(contents)
		list.add_child(HSeparator.new())


func _toggle_contacts_drawer() -> void:
	if _contact_drawer_open:
		_close_contacts_drawer()
		return
	_close_card(false)
	_close_contact_detail()
	if _contact_drawer_tween != null and _contact_drawer_tween.is_valid():
		_contact_drawer_tween.kill()
	if not _contact_drawer.visible:
		_contact_drawer.position.x = -376
		_contact_drawer_backdrop.modulate.a = 0
	_contact_drawer_open = true
	_contact_drawer_backdrop.visible = true
	_contact_drawer.visible = true
	_contact_drawer_backdrop.move_to_front()
	_contact_drawer.move_to_front()
	_contact_drawer_tween = _contact_drawer.create_tween().set_ignore_time_scale(true)
	_contact_drawer_tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_contact_drawer_tween.tween_property(_contact_drawer, "position:x", 16.0, 0.24)
	_contact_drawer_tween.tween_property(_contact_drawer_backdrop, "modulate:a", 1.0, 0.20)
	_sync_modal_input()


func _close_contacts_drawer(animated: bool = true) -> void:
	if _contact_drawer == null or not _contact_drawer.visible:
		return
	if not _contact_drawer_open and animated:
		return
	_contact_drawer_open = false
	if _contact_drawer_tween != null and _contact_drawer_tween.is_valid():
		_contact_drawer_tween.kill()
	if not animated:
		_contact_drawer.visible = false
		_contact_drawer_backdrop.visible = false
		return
	_contact_drawer_tween = _contact_drawer.create_tween().set_ignore_time_scale(true)
	_contact_drawer_tween.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_contact_drawer_tween.tween_property(_contact_drawer, "position:x", -376.0, 0.18)
	_contact_drawer_tween.tween_property(_contact_drawer_backdrop, "modulate:a", 0.0, 0.18)
	_contact_drawer_tween.chain().tween_callback(func():
		_contact_drawer.visible = false
		_contact_drawer_backdrop.visible = false
		_sync_modal_input())


func _on_contact_pressed(actor_id: String) -> void:
	_close_contacts_drawer()
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
	_card.offset_left = -360
	_card.offset_right = 360
	_card.offset_top = -390
	_card.offset_bottom = 390
	_card.visible = false
	_root.add_child(_card)


# --- Refresh -----------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_clock()
	_refresh_panels()
	_refresh_wire()
	_refresh_markers()


func _refresh_clock() -> void:
	var date: Vector2i = sim.day_date(sim.day_index())
	_day_label.text = DAY_FULL_NAMES[sim.day_index()].to_upper()
	_date_label.text = "%d %s %d" % [date.x, MONTHS_GENITIVE[date.y - 1].to_upper(), Week1.YEAR]
	_clock_label.text = sim.clock_text()
	_refresh_time_status()
	if _boss_notice_button != null:
		_boss_notice_button.visible = sim.flags.get("boss_briefing_received", false)
	_tasks_button.visible = phase in ["planning", "live"] and sim.flags.get("boss_briefing_received", false)
	_refresh_paperwork()
	for id in _contact_cards:
		_contact_cards[id].visible = sim.actor_available(id) and sim.actors[id]["state"] in ["travel", "work", "driving"]
		_contact_drawer_status[id].text = sim.actor_status_text(id)
		_contact_drawer_dots[id].color = _contact_status_color(id)
		_contact_dots[id].color = _contact_status_color(id)
		_contact_cards[id].tooltip_text = "%s · %s\n%s" % [Week1.ACTORS[id]["name"], Week1.ACTORS[id]["role"], sim.actor_status_text(id)]
		var progress: OfficeProgress = _contact_progress[id]
		progress.visible = sim.actors[id]["state"] == "work"
		progress.value = sim.actor_work_fraction(id) * 100.0
	_layout_contacts_dock()
	if _contact_detail_status != null and is_instance_valid(_contact_detail_status):
		_contact_detail_status.text = sim.actor_status_text(_contact_detail_actor)
		_contact_detail_lamp.color = _contact_status_color(_contact_detail_actor)
		_contact_detail_map_button.disabled = not sim.actor_available(_contact_detail_actor)
	if _card != null and _card.visible and _card_request != "" and is_instance_valid(_card_wait_label):
		_card_wait_label.text = sim.request_wait_text(_card_request)


func _contact_status_color(id: String) -> Color:
	if not sim.actor_available(id):
		return Color("d74747")
	match sim.actors[id]["state"]:
		"travel":
			return AMBER
		"work":
			return AMBER
		"driving":
			return AMBER
	return Color("4b8356")


func _show_contact_detail(actor_id: String) -> void:
	_close_contact_detail()
	_contact_detail_actor = actor_id
	var info: Dictionary = Week1.ACTORS[actor_id]
	var source: Control = _contact_cards[actor_id] if _contact_cards[actor_id].visible else _contacts_button
	var card_rect := _root.get_global_transform().affine_inverse() * source.get_global_rect()
	var viewport_size: Vector2 = _root.size
	var detail_size := Vector2(360, 218)
	var detail_x: float = clampf(card_rect.position.x, 8.0, maxf(8.0, viewport_size.x - detail_size.x - 8.0))
	var detail_y: float = maxf(68.0, card_rect.position.y - detail_size.y - 8.0)

	_contact_detail_panel = _paper_panel()
	_contact_detail_panel.position = Vector2(detail_x, detail_y)
	_contact_detail_panel.custom_minimum_size = detail_size
	_contact_detail_panel.size = detail_size
	_root.add_child(_contact_detail_panel)
	OfficeMotion.reveal(_contact_detail_panel)
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
	var availability := HBoxContainer.new()
	availability.add_theme_constant_override("separation", 6)
	_contact_detail_lamp = OfficeStatus.new()
	_contact_detail_lamp.custom_minimum_size = Vector2(12, 20)
	_contact_detail_lamp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_contact_detail_lamp.color = _contact_status_color(actor_id)
	availability.add_child(_contact_detail_lamp)
	_contact_detail_status = _paper_label(sim.actor_status_text(actor_id), 16)
	_contact_detail_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contact_detail_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	availability.add_child(_contact_detail_status)
	layout.add_child(availability)
	var map_button := Button.new()
	map_button.text = "Показать на карте"
	_button_icon(map_button, "locate")
	_contact_detail_map_button = map_button
	map_button.disabled = not sim.actor_available(actor_id)
	map_button.custom_minimum_size = Vector2(0, 36)
	map_button.pressed.connect(_focus_contact_on_map.bind(actor_id))
	layout.add_child(map_button)
	_contact_detail_panel.move_to_front()


func _focus_contact_on_map(actor_id: String) -> void:
	if not sim.actor_available(actor_id):
		return
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
	_contact_detail_lamp = null
	_contact_detail_map_button = null
	_contact_detail_actor = ""


func _refresh_panels() -> void:
	_money_label.text = "%d руб." % sim.money
	_money_label.tooltip_text = "Личные деньги\nЗарплата: %d руб. · %d-го числа\nАренда: %d руб. · по пятницам\nДолг за аренду: %d руб." % [Week1.MONTHLY_SALARY, Week1.PAYDAY, Week1.WEEKLY_RENT, sim.rent_debt]
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
		if objective["id"] == "paperwork":
			_paperwork_progress_label = _paper_label("", 16, OfficeTheme.BURGUNDY)
			text_column.add_child(_paperwork_progress_label)
			_paperwork_progress = OfficeProgress.new()
			_paperwork_progress.max_value = Week1.PAPERWORK_HOURS
			_paperwork_progress.segments = 20
			_paperwork_progress.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			_paperwork_progress.custom_minimum_size = Vector2(240, 10)
			text_column.add_child(_paperwork_progress)
			var explanation := _paper_label("Можно прерываться: сделанное сохранится на следующий день. За бумагами доступны звонки. В 22:00 работа откладывается.", 14, OfficeTheme.SECONDARY)
			explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			text_column.add_child(explanation)
			_paperwork_folder_button = _primary_button("")
			_paperwork_folder_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			_paperwork_folder_button.pressed.connect(_on_paperwork_pressed)
			text_column.add_child(_paperwork_folder_button)
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
		row.add_theme_constant_override("separation", 16)
		row.custom_minimum_size.y = 56
		row.add_child(_icon(id, 28))
		var name_label := _paper_label(Week1.FACTIONS[id]["name"], 19)
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		var standing := _paper_label(sim.standing_word(sim.factions[id]), 19, OfficeTheme.LINK)
		standing.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(standing)
		_standing_box.add_child(row)
		_standing_box.add_child(HSeparator.new())
	_refresh_clock()
	_refresh_wire()
	if _card != null and _card.visible and _card_request != "":
		_refresh_card()


func _focus_objective_location(location: String) -> void:
	_close_week_panel()
	map.focus_on(location)


func _refresh_paperwork() -> void:
	if _paperwork_map_button == null:
		return
	var me: Dictionary = sim.actors["me"]
	var active: bool = me["state"] == "paperwork"
	var action := "Отложить документы" if active else ("Вернуться в кабинет" if me["lot"] != "office" else "Сесть за документы")
	if sim.paperwork_left() <= 0.00001 and me["lot"] == "office":
		action = "Норма выполнена"
	var remaining := _eta_text(sim.paperwork_left()) if sim.paperwork_left() > 0.00001 else "готово"
	var reason: String = sim.paperwork_block_reason()
	_paperwork_map_button.visible = phase == "live" and sim.flags.get("boss_briefing_received", false)
	_paperwork_map_button.text = "Документы · %s\n%s" % [remaining, action]
	_paperwork_map_button.disabled = reason != "" or phase != "live"
	_paperwork_map_button.tooltip_text = reason if reason != "" else "Работа с документами · %.0f часов на неделю" % Week1.PAPERWORK_HOURS
	if is_instance_valid(_paperwork_folder_button):
		_paperwork_folder_button.text = action
		_paperwork_folder_button.disabled = reason != "" or phase != "live"
		_paperwork_folder_button.tooltip_text = reason
		_paperwork_progress_label.text = ("Сделано %.1f из %.0f ч" % [sim.paperwork_hours, Week1.PAPERWORK_HOURS]).replace(".", ",")
		_paperwork_progress.value = sim.paperwork_hours


func _on_paperwork_pressed() -> void:
	if phase != "live" or sim.paperwork_block_reason() != "":
		return
	_close_week_panel()
	_close_card(false)
	if sim.actors["me"]["state"] == "paperwork":
		sim.pause_paperwork()
		speed_selected.emit(0.0)
	elif sim.actors["me"]["lot"] != "office":
		sim.return_to_office()
		speed_selected.emit(1.0)
	else:
		sim.start_paperwork()
		speed_selected.emit(1.0)
	_refresh_paperwork()


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
	var panel := PanelContainer.new()
	var style := OfficeTheme.paper(14)
	style.border_color = OfficeTheme.BURGUNDY
	style.set_border_width_all(0)
	style.border_width_left = 8
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	var label := _paper_label(entry["text"], 17)
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
		for id in sim.visible_requests():
			if sim.request_stage(id) != "work":
				visible_ids.append(id)
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
			_markers_layer.add_child(created)
			_markers[id] = created
		var marker: Control = _markers[id]
		marker.tooltip_text = "%s\n%s" % [data["title"], sim.request_wait_text(id)]
		marker.assigned = sim.requests[id]["status"] == "assigned"
		marker.show_deadline = not sim.requests[id]["responded"]
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

	column.add_child(_card_banner(data))

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	header.add_child(_icon(OfficeIcons.QUEST_TYPES[data["type"]], 18, OfficeTheme.SECONDARY))
	var kind := _paper_label("%s · %s" % [TYPE_NAMES[data["type"]].to_upper(), Week1.LOTS[data["lot"]]["name"]], 12, OfficeTheme.SECONDARY)
	kind.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(kind)
	_card_wait_label = _paper_label(sim.request_wait_text(_card_request), 12, OfficeTheme.BURGUNDY)
	header.add_child(_card_wait_label)
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

	column.add_child(_paper_label("ЧТО ДЕЛАТЬ", 12, OfficeTheme.SECONDARY))
	if sim.actors["me"]["state"] == "paperwork":
		var pause_button := Button.new()
		pause_button.text = "Отложить документы · прогресс сохранится"
		pause_button.pressed.connect(func():
			sim.pause_paperwork()
			_refresh_card())
		column.add_child(pause_button)
	for option in data["options"]:
		if Week1.ACTORS.has(option["actor"]) and not Week1.actor_enabled(option["actor"]):
			continue
		column.add_child(_option_row(option))

	var close := Button.new()
	close.text = "Закрыть"
	close.pressed.connect(_close_card)
	outer.add_child(close)


const BANNER_COLORS := {"plea": STEEL, "conflict": AMBER, "crisis": RUST, "offer": OfficeTheme.LINK}
const BANNER_GRADE := preload("res://assets/shaders/event_banner_grade.gdshader")


# The picture at the top of a situation: assets/events/<id>.png (or an explicit
# "image" path) when it exists, otherwise a colored band that names the place.
func _card_banner(data: Dictionary) -> Control:
	var height := 190
	var image_path: String = data.get("image", "res://assets/events/%s.png" % data["id"])
	if ResourceLoader.exists(image_path):
		var picture := TextureRect.new()
		picture.texture = load(image_path)
		picture.custom_minimum_size = Vector2(0, height)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var grade := ShaderMaterial.new()
		grade.shader = BANNER_GRADE
		picture.material = grade
		return picture
	var band := PanelContainer.new()
	band.custom_minimum_size = Vector2(0, 74)
	var color: Color = BANNER_COLORS.get(data["type"], OfficeTheme.GRAPHITE)
	band.add_theme_stylebox_override("panel", OfficeTheme.box(color.darkened(0.35), color.darkened(0.35), 14))
	band.add_child(_label(Week1.LOTS[data["lot"]]["name"], 22, OfficeTheme.LIGHT_TEXT))
	return band


# One choice: who goes, what it says, and what it will cost or change. The whole
# row is the button; a quiet panel behind it brightens on hover.
func _option_row(option: Dictionary) -> Control:
	var reason: String = sim.option_block_reason(_card_request, option)
	var normal := OfficeTheme.box(Color("f4e9d6"), OfficeTheme.EDGE, 10)
	var hover := OfficeTheme.box(Color("fbf2e2"), OfficeTheme.BURGUNDY, 10)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", normal)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var actor_id: String = option["actor"]
	if Week1.ACTORS.has(actor_id):
		var info: Dictionary = Week1.ACTORS[actor_id]
		row.add_child(_face(info["portrait"], info["face"], 52))
	else:
		var glyph := _icon("phone" if actor_id == "phone" else "pen", 32, OfficeTheme.SECONDARY)
		glyph.custom_minimum_size = Vector2(52, 52)
		row.add_child(glyph)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 4)
	body.add_child(_heading(option["label"], 18))
	var hint := _paper_label(option["hint"] + ("" if reason == "" else "  [" + reason + "]"), 14, OfficeTheme.SECONDARY)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(hint)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 4)
	for chip in _option_chips(option):
		chips.add_child(_chip(chip[0], chip[1], chip[2] if chip.size() > 2 else ""))
	body.add_child(chips)
	row.add_child(body)
	panel.add_child(row)
	_ignore_mouse(row)

	var button := Button.new()
	button.flat = true
	button.disabled = reason != ""
	button.pressed.connect(_on_option_pressed.bind(option["id"]))
	button.mouse_entered.connect(func(): panel.add_theme_stylebox_override("panel", hover))
	button.mouse_exited.connect(func(): panel.add_theme_stylebox_override("panel", normal))
	panel.add_child(button)
	if reason != "":
		panel.modulate = Color(1, 1, 1, 0.55)
	return panel


# What an option costs and changes, from its data. Directions only for factions;
# money and time are shown plainly.
func _option_chips(option: Dictionary) -> Array:
	var chips: Array = []
	var hours: float = float(option.get("hours", 0))
	var jobs: Dictionary = sim.requests[_card_request]["jobs"]
	if jobs.has(option["id"]):
		hours = jobs[option["id"]]["left"]
		if hours < float(option.get("hours", 0)) - 0.00001:
			chips.append(["продолжить" if sim.requests[_card_request]["status"] == "open" else "осталось", STEEL])
	match option["actor"]:
		"phone":
			chips.append(["сразу", OfficeTheme.SECONDARY])
		"promise":
			chips.append(["бесплатно сейчас", OfficeTheme.SECONDARY])
			chips.append(["станет долгом", AMBER])
		_:
			chips.append(["сразу" if hours <= 0.0 else _eta_text(hours), OfficeTheme.SECONDARY])
	if float(option.get("chance", 1.0)) < 1.0:
		chips.append(["может сорваться", AMBER])
	var effects: Dictionary = option.get("success", option.get("promise", {}).get("made", {}))
	for id in sim.factions:
		var delta: int = effects.get(id, 0)
		if delta != 0:
			chips.append(["%s %s" % ["↑" if delta > 0 else "↓", Week1.FACTIONS[id]["name"]], STEEL if delta > 0 else RUST, id])
	var money: int = effects.get("money", 0)
	if money != 0:
		chips.append(["%s%d руб." % ["+" if money > 0 else "−", absi(money)], STEEL if money > 0 else RUST])
	if effects.get("trace", 0) > 0:
		chips.append(["останется след", RUST])
	return chips


func _chip(text: String, color: Color, icon_key: String = "") -> Control:
	var chip := PanelContainer.new()
	var style := OfficeTheme.box(color.lerp(Color.WHITE, 0.82), color.lerp(Color.WHITE, 0.55), 3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.set_corner_radius_all(1)
	chip.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	if icon_key != "":
		row.add_child(_icon(icon_key, 14, color.darkened(0.35)))
	row.add_child(_paper_label(text, 12, color.darkened(0.35)))
	chip.add_child(row)
	return chip


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


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


# Three zones: relations first, then what happened grouped by place (weightiest
# first, small things folded away), then what carries into next week.
const SUMMARY_SHOWN := 5
const OUTCOME_TAGS := {
	"done": ["сделано", STEEL], "failed": ["сорвалось", RUST], "missed": ["упущено", RUST],
	"escalated": ["стало хуже", AMBER], "promise": ["обещано", AMBER],
}


func _show_summary() -> void:
	var empty: Array[String] = []
	_show_overlay("Итоги недели · 25–29.08.1997", "Что осталось после недели", empty, "Утро понедельника", next_week_pressed.emit)
	_overlay_list.add_theme_constant_override("separation", 6)
	# The summary is the week's main read: give it most of the screen height.
	_overlay_panel.offset_left = -400
	_overlay_panel.offset_right = 400
	_overlay_panel.offset_top = -410
	_overlay_panel.offset_bottom = 400

	_summary_section("Отношения")
	var standings := GridContainer.new()
	standings.columns = 4
	standings.add_theme_constant_override("h_separation", 14)
	standings.add_theme_constant_override("v_separation", 2)
	for id in sim.factions:
		var delta: int = sim.factions[id] - sim.factions_at_start[id]
		var before: String = sim.standing_word(sim.factions_at_start[id])
		var after: String = sim.standing_word(sim.factions[id])
		standings.add_child(_icon(id, 22))
		standings.add_child(_paper_label(Week1.FACTIONS[id]["name"], 16, OfficeTheme.SECONDARY))
		standings.add_child(_paper_label(after if before == after else "%s → %s" % [before, after], 16))
		var arrow := "↑" if delta > 0 else ("↓" if delta < 0 else "—")
		standings.add_child(_paper_label(arrow, 16, STEEL if delta > 0 else (RUST if delta < 0 else OfficeTheme.SECONDARY)))
	_overlay_list.add_child(standings)

	var ranked: Array = sim.outcomes.duplicate()
	ranked.sort_custom(func(a, b): return a["weight"] > b["weight"])
	_summary_section("Что произошло")
	_summary_groups(_overlay_list, ranked.slice(0, SUMMARY_SHOWN))
	var rest: Array = ranked.slice(SUMMARY_SHOWN)
	if not rest.is_empty():
		var rest_box := VBoxContainer.new()
		rest_box.add_theme_constant_override("separation", 6)
		rest_box.visible = false
		_summary_groups(rest_box, rest)
		var toggle := Button.new()
		toggle.flat = true
		toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		toggle.text = "Показать ещё %d" % rest.size()
		toggle.add_theme_font_size_override("font_size", 15)
		toggle.add_theme_color_override("font_color", OfficeTheme.LINK)
		toggle.pressed.connect(func():
			rest_box.visible = not rest_box.visible
			toggle.text = "Свернуть" if rest_box.visible else "Показать ещё %d" % rest.size())
		_overlay_list.add_child(toggle)
		_overlay_list.add_child(rest_box)

	var threads: Array[String] = sim.summary_threads()
	if not threads.is_empty():
		_summary_section("Тянется на следующую неделю")
		for thread in threads:
			var line := _paper_label("•  " + thread, 16)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_overlay_list.add_child(line)


func _summary_section(title: String) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 14
	_overlay_list.add_child(spacer)
	var rule := HSeparator.new()
	_overlay_list.add_child(rule)
	var caption := _paper_label(title.to_upper(), 12, OfficeTheme.SECONDARY)
	caption.add_theme_constant_override("line_spacing", 0)
	_overlay_list.add_child(caption)


# Results grouped by place, in the order the weightiest of each place appears.
func _summary_groups(parent: Control, items: Array) -> void:
	var lots: Array[String] = []
	for outcome in items:
		if not lots.has(outcome["lot"]):
			lots.append(outcome["lot"])
	for lot in lots:
		var gap := Control.new()
		gap.custom_minimum_size.y = 8
		parent.add_child(gap)
		parent.add_child(_heading(Week1.LOTS[lot]["name"] if Week1.LOTS.has(lot) else "Прочее", 17))
		for outcome in items:
			if outcome["lot"] == lot:
				parent.add_child(_summary_row(outcome))


func _summary_row(outcome: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var tag: Array = OUTCOME_TAGS.get(outcome["kind"], OUTCOME_TAGS["done"])
	var tag_label := _paper_label(tag[0], 12, tag[1])
	tag_label.custom_minimum_size.x = 86
	row.add_child(tag_label)
	var text := _paper_label(outcome["text"], 16)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	return row


static func _plural(n: int, one: String, few: String, many: String) -> String:
	if n % 10 == 1 and n % 100 != 11:
		return one
	if (n % 10 in [2, 3, 4]) and not (n % 100 in [12, 13, 14]):
		return few
	return many


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
	OfficeMotion.reveal(_overlay_panel)
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
	_overlay_list = list
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
	var size := _root.size
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
	panel.mouse_force_pass_scroll_events = false
	var style := OfficeTheme.paper(24)
	style.shadow_color = Color(0.1, 0.06, 0.05, 0.4)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	_decorate_paper(panel)
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
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, OfficeTheme.LIGHT_TEXT)
	return button


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _contact_drawer != null and _contact_drawer.visible:
		_close_contacts_drawer()
	elif _notice_panel != null:
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
	var order := Button.new()
	_boss_notice_button = order
	order.theme = _paper_theme
	_document_button(order, "memo")
	_document_caption(order, "ПЁТР ПЕТРОВИЧ", "Поручение на неделю", "pen")
	order.pressed.connect(_show_important_notice.bind(Week1.START_BRIEFING))
	_incoming_tray.add_child(order)
	var newspaper := Button.new()
	_newspaper_button = newspaper
	newspaper.theme = _paper_theme
	_document_button(newspaper, "newspaper")
	_document_caption(newspaper, "ГОРОДСКИЕ ВЕСТИ", "Утренний выпуск", "newspaper")
	newspaper.pressed.connect(show_newspaper)
	_incoming_tray.add_child(newspaper)


# Pictograms share the same ink and size in navigation, standings and outcomes.
func _icon(key: String, pixels: int = 24, ink: Color = OfficeTheme.TEXT) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = OfficeIcons.texture(key, pixels * 2)
	rect.modulate = ink
	rect.custom_minimum_size = Vector2(pixels, pixels)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _button_icon(button: Button, key: String) -> void:
	button.icon = OfficeIcons.texture(key)
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", 20)
	button.add_theme_constant_override("h_separation", 8)
	for state in ["icon_normal_color", "icon_hover_color", "icon_focus_color"]:
		button.add_theme_color_override(state, OfficeTheme.TEXT)
	button.add_theme_color_override("icon_pressed_color", OfficeTheme.LIGHT_TEXT)
	button.add_theme_color_override("icon_hover_pressed_color", OfficeTheme.LIGHT_TEXT)


func _decorate_paper(control: Control, kind: String = "paper") -> void:
	var grain := OfficePaper.new()
	grain.kind = kind
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(grain)


func _document_button(button: Button, kind: String) -> void:
	button.custom_minimum_size.y = 76
	for state in ["normal", "hover", "pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var art := TextureRect.new()
	art.texture = load("res://assets/ui/memo.png" if kind == "memo" else "res://assets/ui/newspaper_slip.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art)
	button.mouse_entered.connect(func(): art.modulate = Color(1.06, 1.06, 1.06))
	button.mouse_exited.connect(func(): art.modulate = Color.WHITE)


func _document_caption(button: Button, title: String, subtitle: String, symbol: String) -> void:
	var copy := VBoxContainer.new()
	copy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	copy.offset_left = 36 if symbol == "pen" else 18
	copy.offset_right = -18
	copy.offset_top = 17 if symbol == "pen" else 20
	copy.offset_bottom = -14
	copy.add_theme_constant_override("separation", 3)
	var headline := _paper_label(title, 13, OfficeTheme.LIGHT_TEXT) if symbol == "pen" else _heading(title, 14)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.autowrap_mode = TextServer.AUTOWRAP_OFF
	if symbol == "pen":
		var nameplate := PanelContainer.new()
		nameplate.add_theme_stylebox_override("panel", OfficeTheme.box(OfficeTheme.BURGUNDY, OfficeTheme.BURGUNDY, 2))
		nameplate.add_child(headline)
		copy.add_child(nameplate)
	else:
		copy.add_child(headline)
	var description := _paper_label(subtitle, 12)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(description)
	_ignore_mouse(copy)
	button.add_child(copy)


# Update the map gate before GUI routing; do not consume the event here.
# The modal's controls and ScrollContainers still receive the wheel normally.
func _input(_event: InputEvent) -> void:
	_sync_modal_input()


func _sync_modal_input() -> void:
	_fit_interface_windows()
	if map == null:
		return
	var modal_open: bool = (
		(_card != null and _card.visible)
		or (_week_panel != null and _week_panel.visible)
		or (_notice_panel != null and is_instance_valid(_notice_panel))
		or (_overlay_panel != null and is_instance_valid(_overlay_panel))
		or (_contact_drawer != null and _contact_drawer.visible)
	)
	map.set_ui_input_blocked(modal_open)


func show_newspaper() -> void:
	var edition := NewspaperIssues.build(sim.week, sim.press_history)
	if edition.is_empty():
		return
	edition["date"] = sim.date_text(0)
	_show_important_notice(edition)


# Settings drives every HUD element; map projections are converted to local space.
func set_interface_scale(value: float) -> void:
	Settings.set_interface_scale(value)

func _apply_interface_scale(_value: float = 1.0) -> void:
	var viewport := get_viewport().get_visible_rect().size
	var factor := Settings.fitted_interface_scale(viewport)
	_root.scale = Vector2.ONE * factor
	_root.size = viewport / factor
	if not _tokens.is_empty():
		_update_tokens()
		_update_markers(_map_area())
	if is_instance_valid(_top_bar):
		_layout_top_bar.call_deferred()
	_fit_interface_windows.call_deferred()

func _fit_interface_windows() -> void:
	for child in _root.get_children():
		if not child is PanelContainer or child in [_top_bar, _map_controls, _contacts_dock, _contact_drawer]:
			continue
		if child == _notice_panel and _notice_is_newspaper:
			continue # Newspaper computes its own proportional fit.
		var panel: PanelContainer = child
		var fit_key := Vector4(_root.size.x, _root.size.y, panel.size.x, panel.size.y)
		if panel.get_meta("fit_key", Vector4.ZERO) == fit_key:
			continue
		panel.set_meta("fit_key", fit_key)
		var available := _root.size - Vector2(24, 100)
		var factor := minf(1, minf(available.x / maxf(panel.size.x, 1), available.y / maxf(panel.size.y, 1)))
		panel.pivot_offset = panel.size * Vector2(panel.anchor_left, panel.anchor_top)
		panel.scale = Vector2.ONE * factor
		var corner := panel.position + panel.pivot_offset * (1 - factor)
		var desired := corner.clamp(Vector2(12, 80), _root.size - Vector2(12, 12) - panel.size * factor)
		panel.position += desired - corner

func _layout_top_bar() -> void:
	if not is_instance_valid(_top_bar):
		return
	var viewport_width := _root.size.x
	var required := maxf(_top_row.get_combined_minimum_size().x + 48, 1)
	var factor := minf(1.0, viewport_width / required)
	_top_bar.scale = Vector2.ONE * factor
	_top_bar.position = Vector2.ZERO
	_top_bar.size = Vector2(viewport_width / factor, 68)

func _refresh_time_status() -> void:
	if not is_instance_valid(_phase_detail):
		return
	var title := "ПЛАНИРОВАНИЕ"
	var detail := "Время остановлено"
	if phase == "summary":
		title = "ИТОГИ НЕДЕЛИ"
	elif phase == "week2":
		title = "УТРО ПОНЕДЕЛЬНИКА"
	elif phase == "live":
		if sim._day_closing:
			if sim.actors["me"].get("commute_target", "") == "dormitory":
				title = "ДОРОГА ДОМОЙ"
				detail = "День завершится по прибытии"
			else:
				title = "СВЕРХУРОЧНО"
				detail = "Завершаете начатое дело"
		elif not sim.at_work:
			title = "ДОРОГА НА РАБОТУ" if sim.actors["me"].get("commute_target", "") == "office" else "УТРО"
			detail = "К 08:00 в администрацию"
		elif sim.clock_hour() >= Week1.WORK_END_HOUR:
			title = "ПОСЛЕ РАБОТЫ"
			detail = "Личное время · до 22:00"
		else:
			title = "РАБОЧЕЕ ВРЕМЯ"
			detail = "До 18:00"
		if is_zero_approx(_current_speed):
			detail = "Пауза · " + detail.left(1).to_lower() + detail.substr(1)
	_phase_label.text = title
	_phase_detail.text = detail

func _style_strip_button(button: Button) -> void:
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 40)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var fill := Color(0, 0, 0, 0)
		if state == "hover":
			fill = Color(OfficeTheme.BURGUNDY, 0.10)
		elif state == "pressed":
			fill = OfficeTheme.BURGUNDY
		var style := OfficeTheme.box(fill, OfficeTheme.BURGUNDY, 6)
		style.set_border_width_all(0)
		button.add_theme_stylebox_override(state, style)
		var color := OfficeTheme.LIGHT_TEXT if state == "pressed" else OfficeTheme.TEXT
		if state == "disabled":
			color = OfficeTheme.SECONDARY
		button.add_theme_color_override("font_color" if state == "normal" else "font_%s_color" % state, color)
	button.add_theme_color_override("font_hover_pressed_color", OfficeTheme.LIGHT_TEXT)


func _clear_surface(horizontal: int, vertical: int) -> StyleBoxEmpty:
	var style := StyleBoxEmpty.new()
	style.content_margin_left = horizontal
	style.content_margin_right = horizontal
	style.content_margin_top = vertical
	style.content_margin_bottom = vertical
	return style

func _skin(control: Control, texture: Texture2D) -> void:
	var art := OfficeSkin.new()
	art.texture = texture
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(art)
	control.move_child(art, 0)
	if control is Button:
		control.mouse_entered.connect(func(): art.self_modulate = Color(1.08, 1.04, 1))
		control.mouse_exited.connect(func(): art.self_modulate = Color.WHITE)
		control.button_down.connect(func(): art.self_modulate = Color(0.83, 0.78, 0.74))
		control.button_up.connect(func(): art.self_modulate = Color.WHITE)
