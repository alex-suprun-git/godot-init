extends CanvasLayer

signal finished
signal newspaper_opened
signal landmark_reached(id: String)
signal wait_ended

const Arrival = preload("res://scripts/data/arrival.gd")
const Newspaper = preload("res://scripts/ui/newspaper.gd")
const NewspaperIssues = preload("res://scripts/data/newspaper_issues.gd")
const FONT = preload("res://assets/fonts/source_serif4_regular.ttf")
const DistrictLayout = preload("res://scripts/data/district_layout.gd")
const TRAIN_AUDIO = preload("res://assets/audio/transport/er2_running.mp3")
const RADIO_TRACK = preload("res://assets/audio/ambience/prologue_car_radio.mp3")
const RADIO_BUS := "ArrivalRadio"
const RADIO_GAIN := 0.28
const RADIO_STATIC_GAIN := 0.045
const DRIVE_WORLD_GAIN := 0.35
const RECEPTION_AUDIO = preload("res://assets/audio/ambience/prologue_reception.mp3")
const TRAIN_WINDOW = preload("res://assets/locations/prologue/train-window-v2.png")
const TRAIN_CARRIAGE = preload("res://assets/locations/prologue/train-carriage-v4.png")
const OFFICE = preload("res://assets/locations/summer_day_office_v3.png")
const WAKE_SHADER = preload("res://assets/shaders/prologue_wake.gdshader")
const FOCUS_SECONDS := 6.5
const SHOT_PAUSE := 0.55
const SKIP_SECONDS := 1.25

var _map
var _hud
var _audio
var _map_audio
var _root: Control
var _curtain: ColorRect
var _slide: TextureRect
var _caption_panel: PanelContainer
var _caption: Label
var _landmark: Control
var _landmark_panel: PanelContainer
var _landmark_name: Label
var _landmark_rect: Rect2
var _landmark_focus := Vector2.ZERO
var _landmark_zoom := 0.0
var _timer: Timer
var _paper: Control
var _skip_hint: HBoxContainer
var _skip_ring: Control
var _skip_label: Label
var _skip_elapsed := 0.0
var _space_held := false
var _can_skip := false
var _show_drive := false
var _driving := false
var _skip_drive := false
var _minute := 360
var _visual_hour := 6.0
var _caption_age := 0.0
var _caption_seconds := 0.0
var _focus_age := 0.0
var _reveal_delay := 0.0
var _city_level := 0.0
var _date: String
var _radio_bus_created := false


func begin(map, hud, audio, map_audio, date: String) -> void:
	_map = map
	_hud = hud
	_audio = audio
	_map_audio = map_audio
	_date = date
	_city_level = audio.city_ambience.level
	_audio.set_layer_level("city", 0.0)
	_audio.add_layer("arrival_train", TRAIN_AUDIO, "Ambience", 0.38, 1.0)
	layer = 8
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_slide = TextureRect.new()
	_slide.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slide.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_slide.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_slide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_slide)
	_curtain = ColorRect.new()
	_curtain.color = Color("171513")
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_curtain)
	_build_landmark()
	_build_caption()
	_build_skip_hint()
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(wait_ended.emit)
	_caption.text = "Понедельник. В первой электричке почти все места заняты. На сиденье у окна кто-то оставил газету."
	_map.begin_arrival(Arrival.TRAFFIC)
	_slide.texture = TRAIN_CARRIAGE
	await _wake_up()
	await _wait_for_reading()
	_skip_label.hide()
	_caption_panel.hide()
	await _fade(0.65, 0.35)
	_paper = Newspaper.new()
	_root.add_child(_paper)
	_audio.play("newspaper_rustle")
	_paper.build(NewspaperIssues.build(1, {}), _date, close_paper)
	_root.move_child(_skip_hint, -1)
	_set_skip_enabled(true)
	newspaper_opened.emit()


func close_paper() -> void:
	if not is_instance_valid(_paper):
		return
	_set_skip_enabled(false)
	_paper.queue_free()
	_paper = null
	_audio.play("newspaper_rustle")
	_caption_panel.show()
	_caption.text = "За полем показались дома. Значит, приехали."
	_slide.texture = TRAIN_WINDOW
	_slide.show()
	await _fade(0.0, 0.55)
	await _wait_for_reading()
	_caption_panel.modulate.a = 0.0
	_audio.set_layer_level("arrival_train", 0.0, 0.5)
	_audio.set_layer_level("city", _city_level, 0.55)
	await _fade(1.0, 0.55)
	_slide.hide()
	_map.stage_arrival_meeting()
	await _fade(0.0, 0.55)
	_audio.remove_layer("arrival_train")
	_show_drive = true
	_set_skip_enabled(true)
	_start_caption(Arrival.MEETING)
	landmark_reached.emit("station")
	await _hold(_caption_seconds + 0.35)

	var drive_started := Time.get_ticks_msec()
	_driving = true
	_set_skip_enabled(true)
	if _map.prepare_arrival_drive(Arrival.DRIVE) and _map.start_arrival_drive():
		_start_radio()
		for index in Arrival.DRIVE.size():
			await _play_drive_beat(index)
			if _skip_drive:
				break
		while not _skip_drive and not _map.reached_arrival_mark(Arrival.DRIVE.size() - 1):
			await _hold(0.1)
	if OS.get_cmdline_user_args().has("--autoplay"):
		print("arrival drive: %.1f seconds at current engine speed" % ((Time.get_ticks_msec() - drive_started) / 1000.0))
	_set_skip_enabled(false)
	_driving = false
	_show_drive = false
	_landmark.hide()
	_wait_in_reception()


func _play_drive_beat(index: int) -> void:
	var beat: Dictionary = Arrival.DRIVE[index]
	var approach: bool = beat.has("approach_caption")
	while not _skip_drive and not _map.reached_arrival_mark(index, beat.get("lead", 0.0)):
		await _hold(0.1)
	if _skip_drive:
		return
	_landmark_rect = beat.get("highlight", DistrictLayout.LOTS[beat["lot"]]["rect"])
	_landmark_focus = beat.get("focus", _landmark_rect.get_center())
	_landmark_zoom = beat.get("focus_zoom", 0.0)
	_focus_age = -INF
	_landmark_name.text = beat.get("name", "")
	_landmark_panel.reset_size()
	_minute = beat["minute"]
	if approach:
		_start_caption(beat["approach_caption"], beat["approach_seconds"])
		await _hold(_caption_seconds + 0.35)
		if _skip_drive:
			return
		_set_quiet(true)
		await _hold(beat["silence_seconds"])
		if _skip_drive:
			return
	_start_caption(beat["caption"])
	_focus_age = 0.0
	_reveal_delay = beat.get("reveal_delay", 0.0)
	landmark_reached.emit(beat["id"])
	await _hold(_caption_seconds + 0.35)
	if _skip_drive:
		return
	if approach:
		_set_quiet(false)
	await _hold(SHOT_PAUSE)


func _process(delta: float) -> void:
	if _space_held and _can_skip:
		_skip_elapsed += delta
		_skip_ring.queue_redraw()
		if _skip_elapsed >= SKIP_SECONDS:
			_set_skip_enabled(false)
			if is_instance_valid(_paper):
				close_paper()
			else:
				_skip_drive = _driving
				if not _timer.is_stopped():
					_timer.stop()
					wait_ended.emit()
			return
	if not _show_drive:
		return
	_caption_age += delta
	_focus_age += delta
	_caption_panel.modulate.a = minf(smoothstep(0.0, 0.35, _caption_age),
		1.0 - smoothstep(_caption_seconds, _caption_seconds + 0.35, _caption_age))
	var attention := 0.0
	if _landmark_rect.has_area():
		attention = minf(smoothstep(0.0, 1.4, _focus_age - _reveal_delay),
			1.0 - smoothstep(FOCUS_SECONDS - 2.0, FOCUS_SECONDS, _focus_age))
	_visual_hour = lerpf(_visual_hour, _minute / 60.0, 1.0 - exp(-delta * 0.85))
	_map.update_arrival(_visual_hour, _landmark_focus, attention, _landmark_zoom)
	_update_landmark(attention)


func _start_caption(copy: String, seconds := -1.0) -> void:
	_caption.text = copy
	_caption_age = 0.0
	_caption_seconds = _reading_seconds(copy) if seconds < 0.0 else seconds


func _reading_seconds(copy: String) -> float:
	# Budget for both reading and looking back at the map.
	return maxf(6.0, 2.5 + copy.split(" ", false).size() / 1.9)


func _wait_for_reading() -> void:
	_set_skip_enabled(true)
	await _hold(_reading_seconds(_caption.text))
	_set_skip_enabled(false)


func _hold(seconds: float) -> void:
	_timer.start(seconds)
	await wait_ended


func _fade(opacity: float, seconds: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(_curtain, "modulate:a", opacity, seconds)
	await tween.finished


func _wake_up() -> void:
	_caption_panel.hide()
	var eyelids := ShaderMaterial.new()
	eyelids.shader = WAKE_SHADER
	_curtain.material = eyelids
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var set_opening := func(amount: float) -> void:
		eyelids.set_shader_parameter("opening", amount)
	tween.tween_interval(0.25)
	tween.tween_method(set_opening, 0.0, 0.28, 0.95)
	tween.tween_method(set_opening, 0.28, 0.22, 0.25)
	tween.tween_method(set_opening, 0.22, 1.0, 1.45)
	await tween.finished
	_curtain.modulate.a = 0.0
	_curtain.material = null
	_caption_panel.show()


func _set_quiet(quiet: bool) -> void:
	_audio.set_layer_level("city", _city_level * (0.10 if quiet else DRIVE_WORLD_GAIN), 0.4)
	_map_audio.scene_gain = DRIVE_WORLD_GAIN
	_audio.set_layer_level("arrival_radio", RADIO_GAIN * 0.55 if quiet else RADIO_GAIN, 0.4)
	_audio.set_layer_level("arrival_radio_static", RADIO_STATIC_GAIN * 0.55 if quiet else RADIO_STATIC_GAIN, 0.4)


func _start_radio() -> void:
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, RADIO_BUS)
	AudioServer.set_bus_send(index, "Ambience")
	_radio_bus_created = true

	var high_pass := AudioEffectHighPassFilter.new()
	high_pass.cutoff_hz = 360.0
	high_pass.resonance = 0.5
	AudioServer.add_bus_effect(index, high_pass)
	var low_pass := AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = 3200.0
	low_pass.resonance = 0.5
	AudioServer.add_bus_effect(index, low_pass)

	_audio.add_layer("arrival_radio", RADIO_TRACK, RADIO_BUS, RADIO_GAIN, 0.65)
	_audio.add_layer("arrival_radio_static", _radio_static(), RADIO_BUS, RADIO_STATIC_GAIN, 0.25)
	_set_quiet(false)


func _radio_static() -> AudioStreamWAV:
	const RATE := 12000
	const SAMPLE_COUNT := RATE * 7
	var samples := PackedByteArray()
	samples.resize(SAMPLE_COUNT * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in SAMPLE_COUNT:
		var seconds := float(i) / RATE
		var burst := maxf(1.0 - absf(seconds - 1.4) / 0.12, 1.0 - absf(seconds - 5.3) / 0.08)
		var amplitude := 0.07 + 0.48 * maxf(burst, 0.0)
		samples.encode_s16(i * 2, roundi(rng.randf_range(-amplitude, amplitude) * 32767.0))
	var noise := AudioStreamWAV.new()
	noise.format = AudioStreamWAV.FORMAT_16_BITS
	noise.mix_rate = RATE
	noise.data = samples
	return noise


func _wait_in_reception() -> void:
	_audio.set_layer_level("city", 0.0, 0.65)
	_audio.set_layer_level("arrival_radio", 0.0, 0.45)
	_audio.set_layer_level("arrival_radio_static", 0.0, 0.45)
	_audio.add_layer("arrival_reception", RECEPTION_AUDIO, "Ambience", 0.55, 1.0)
	await _fade(1.0, 0.65)
	_audio.remove_layer("arrival_radio")
	_audio.remove_layer("arrival_radio_static")
	_map_audio.set_muted(true)
	_hud.hide()
	_caption_panel.modulate.a = 0.0
	_slide.texture = OFFICE
	_slide.show()
	_caption.text = "08:00 · Приёмная\nРовно восемь. В здании это, кажется, заметили только часы."
	await _fade(0.0, 0.70)
	_caption_panel.modulate.a = 1.0
	await _wait_for_reading()
	_caption_panel.modulate.a = 0.0
	await _fade(1.0, 0.40)
	# Reframe the existing illustration toward the open door for the boss's call.
	var doorway := AtlasTexture.new()
	doorway.atlas = OFFICE
	doorway.region = Rect2(Vector2(0.39, 0.02) * OFFICE.get_size(), OFFICE.get_size() * 0.60)
	_slide.texture = doorway
	_caption.text = "10:04 · Приёмная\nБорис Саввич: Новый? Заходите. Дверь закройте. Разговор есть."
	await _fade(0.0, 0.55)
	_caption_panel.modulate.a = 1.0
	await _wait_for_reading()
	_caption_panel.hide()
	_audio.set_layer_level("arrival_reception", 0.0, 0.55)
	await _fade(1.0, 0.55)
	finish()


func finish() -> void:
	if is_queued_for_deletion():
		return
	_timer.stop()
	_audio.remove_layer("arrival_train")
	_audio.remove_layer("arrival_reception")
	_audio.remove_layer("arrival_radio")
	_audio.remove_layer("arrival_radio_static")
	_map_audio.scene_gain = 1.0
	_map_audio.set_muted(false)
	_audio.set_layer_level("city", _city_level, 0.4)
	_map.end_arrival()
	hide()
	queue_free()
	finished.emit()


func _exit_tree() -> void:
	if _radio_bus_created:
		AudioServer.remove_bus(AudioServer.get_bus_index(RADIO_BUS))


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or event.keycode != KEY_SPACE:
		return
	get_viewport().set_input_as_handled()
	if not event.pressed:
		_space_held = false
		_skip_elapsed = 0.0
		_skip_ring.queue_redraw()
	elif not event.echo and _can_skip:
		_space_held = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(_skip_ring):
		_space_held = false
		_skip_elapsed = 0.0
		_skip_ring.queue_redraw()


func _set_skip_enabled(enabled: bool) -> void:
	if enabled == _can_skip:
		return
	_can_skip = enabled
	_space_held = false
	_skip_elapsed = 0.0
	_skip_hint.visible = enabled
	_skip_ring.queue_redraw()


func _build_skip_hint() -> void:
	_skip_hint = HBoxContainer.new()
	_skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_skip_hint.offset_left = -22
	_skip_hint.offset_top = -14
	_skip_hint.offset_right = -22
	_skip_hint.offset_bottom = -14
	_skip_hint.add_theme_constant_override("separation", 6)
	_skip_ring = Control.new()
	_skip_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_skip_ring.custom_minimum_size = Vector2(20, 20)
	_skip_ring.draw.connect(_draw_skip_ring)
	_skip_hint.add_child(_skip_ring)
	_skip_label = _paper_label(14)
	_skip_label.text = "Пропуск · удержание Space"
	_skip_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.85, 0.68))
	_skip_label.add_theme_color_override("font_shadow_color", Color(0.07, 0.055, 0.046, 0.87))
	_skip_label.add_theme_constant_override("shadow_offset_y", 1)
	_skip_hint.add_child(_skip_label)
	_root.add_child(_skip_hint)
	_skip_hint.hide()


func _draw_skip_ring() -> void:
	if _skip_elapsed <= 0.0:
		return
	var center := _skip_ring.size * 0.5
	var progress := clampf(_skip_elapsed / SKIP_SECONDS, 0.0, 1.0)
	_skip_ring.draw_arc(center, 7, -PI / 2.0, TAU - PI / 2.0, 36, Color("766858"), 2, true)
	_skip_ring.draw_arc(center, 7, -PI / 2.0, TAU * progress - PI / 2.0, 36, Color("fff1d9"), 2, true)


func _build_caption() -> void:
	_caption_panel = _paper_label_panel(20, 12)
	_caption_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_caption_panel.anchor_left = 0.20
	_caption_panel.anchor_right = 0.80
	_caption_panel.offset_top = -132
	_caption_panel.offset_bottom = -32
	_caption = _paper_label(24)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_panel.add_child(_caption)
	_root.add_child(_caption_panel)


func _build_landmark() -> void:
	_landmark = Control.new()
	_landmark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_landmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_landmark.draw.connect(_draw_landmark)
	_landmark.hide()
	_root.add_child(_landmark)
	_landmark_panel = _paper_label_panel(18, 8)
	_landmark_name = _paper_label(34)
	_landmark_panel.add_child(_landmark_name)
	_landmark.add_child(_landmark_panel)


func _update_landmark(attention: float) -> void:
	_landmark.visible = attention > 0.01
	if not _landmark.visible:
		return
	_landmark.modulate.a = attention
	_landmark_panel.visible = not _landmark_name.text.is_empty()
	if _landmark_panel.visible:
		var anchor: Vector2 = _map.ground_screen_position(_landmark_focus, 16.0)
		var label_position := anchor - Vector2(_landmark_panel.size.x * 0.5, _landmark_panel.size.y)
		var map_area: Rect2 = _hud._map_area()
		label_position.x = clampf(label_position.x, map_area.position.x, map_area.end.x - _landmark_panel.size.x)
		label_position.y = clampf(label_position.y, map_area.position.y, map_area.end.y - _landmark_panel.size.y)
		_landmark_panel.position = label_position
	_landmark.queue_redraw()


func _draw_landmark() -> void:
	var a := _landmark_rect.position
	var c := _landmark_rect.end
	var corners := PackedVector2Array()
	for point in [a, Vector2(c.x, a.y), c, Vector2(a.x, c.y)]:
		corners.append(_map.ground_screen_position(point, 1.0))
	for index in corners.size():
		var corner := corners[index]
		for neighbor in [corners[posmod(index - 1, 4)], corners[(index + 1) % 4]]:
			var arm := corner.move_toward(neighbor, minf(22.0, corner.distance_to(neighbor) * 0.22))
			_landmark.draw_line(corner, arm, Color("241a17"), 6.0, true)
			_landmark.draw_line(corner, arm, Color("f8df9f"), 2.5, true)


func _paper_label_panel(side: int, vertical: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.07, 0.055, 0.046, 0.94)
	background.border_color = Color(0.86, 0.74, 0.54, 0.46)
	background.set_border_width_all(1)
	background.set_corner_radius_all(6)
	background.content_margin_left = side
	background.content_margin_right = side
	background.content_margin_top = vertical
	background.content_margin_bottom = vertical
	panel.add_theme_stylebox_override("panel", background)
	return panel


func _paper_label(pixels: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", pixels)
	label.add_theme_color_override("font_color", Color("fff1d9"))
	return label
