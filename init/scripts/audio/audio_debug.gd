# Dev panel (F3): which sound events fired this week and how often. Use it to
# tune feedback before any sound exists: the most frequent event should be the
# quietest, and a rare tier should not fire every few seconds.
extends CanvasLayer

const AudioEvents = preload("res://scripts/data/audio_events.gd")

const INK := Color(0.09, 0.1, 0.1, 0.94)
const PAPER := Color(0.93, 0.9, 0.83)
const MUTED := Color(0.62, 0.6, 0.54)
const AMBER := Color(0.91, 0.66, 0.27)
const RUST := Color(0.85, 0.36, 0.27)
const QUIET_MODES := [0, 2, 3] # min_tier values the button cycles through

var audio
var _panel: PanelContainer
var _header: Label
var _quiet_button: Button
var _rows := {} # event id -> {name, count, rate, last}
var _refresh_left := 0.0


func setup(audio_manager) -> void:
	audio = audio_manager
	layer = 50
	_panel = PanelContainer.new()
	_panel.position = Vector2(16, 76)
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.set_content_margin_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(0.36, 0.32, 0.24)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)
	_header = _label("", 14, AMBER)
	column.add_child(_header)
	_quiet_button = Button.new()
	_quiet_button.pressed.connect(_cycle_quiet_mode)
	column.add_child(_quiet_button)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 2)
	column.add_child(grid)
	for title in ["Событие (клик = послушать)", "Ур.", "За неделю", "В минуту", "Последнее"]:
		grid.add_child(_label(title, 12, MUTED))
	for id in AudioEvents.EVENTS:
		var button := Button.new()
		button.text = AudioEvents.EVENTS[id]["label"]
		button.flat = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_color_override("font_color", PAPER)
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(audio.play.bind(id, false))
		grid.add_child(button)
		var tier := _label(str(AudioEvents.EVENTS[id]["tier"]), 13, MUTED)
		var count := _label("0", 13, PAPER)
		var rate := _label("", 13, PAPER)
		var last := _label("", 13, MUTED)
		for label in [tier, count, rate, last]:
			grid.add_child(label)
		_rows[id] = {"button": button, "count": count, "rate": rate, "last": last}
	visible = false
	_update_quiet_button()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = 0.25
	_header.text = "ЗВУКОВЫЕ СОБЫТИЯ · сыграно %s · F3 скрыть" % _clock(audio.minutes_played())
	var now := Time.get_ticks_msec()
	for id in _rows:
		var row: Dictionary = _rows[id]
		var stat: Dictionary = audio.stats[id]
		var tier: int = AudioEvents.EVENTS[id]["tier"]
		var rate: float = audio.rate_per_minute(id)
		var tiring: bool = stat["count"] >= 5 and rate > AudioEvents.MAX_PER_MINUTE[tier]
		row["count"].text = str(stat["count"])
		row["rate"].text = "%.1f%s" % [rate, "  ⚠ часто" if tiring else ""]
		row["rate"].add_theme_color_override("font_color", RUST if tiring else PAPER)
		var ago: float = (now - stat["last_msec"]) / 1000.0
		row["last"].text = "" if stat["count"] == 0 else "%d с назад" % int(ago)
		# A fired event flashes amber for a moment.
		var fresh: bool = ago < 0.8
		row["button"].add_theme_color_override("font_color", AMBER if fresh else PAPER)


func _cycle_quiet_mode() -> void:
	var index := QUIET_MODES.find(audio.min_tier)
	audio.min_tier = QUIET_MODES[(index + 1) % QUIET_MODES.size()]
	_update_quiet_button()


func _update_quiet_button() -> void:
	match audio.min_tier:
		0:
			_quiet_button.text = "Играют все уровни (нажми: только 2+)"
		2:
			_quiet_button.text = "Играют уровни 2+ (нажми: только 3+)"
		_:
			_quiet_button.text = "Играют уровни 3+ (нажми: все)"


func _clock(minutes: float) -> String:
	var seconds := int(minutes * 60.0)
	return "%d:%02d" % [seconds / 60, seconds % 60]


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
