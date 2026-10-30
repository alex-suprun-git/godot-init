# Playtest logger: records what happens while someone plays, as JSON lines, and
# writes a summary of the week at its end. It is read afterwards to find where
# the week drags, which requests are never answered, and how long decisions take.
# Files live in user://playtests (on macOS: ~/Library/Application Support/Godot/
# app_userdata/Init/playtests). Run with --no-log to turn it off.
extends Node

const Settings = preload("res://scripts/data/settings.gd")

const SPEED_KEYS := ["planning", "0", "1", "2", "4"]

var sim
var source := "player" # "autoplay" when the dev autoplay plays
var path := ""

var _file: FileAccess
var _started_msec := 0
var _last_t := 0.0
var _last_sample_hour := -1
var _requests := {} # id -> tracking data
var _busy_hours := {} # actor id -> game hours spent busy
var _waiting_hours := 0.0 # nothing to decide: no open request waiting for an answer
var _blocked_hours := 0.0 # something to decide, but no option is possible right now
var _waiting_by_day := [0.0, 0.0, 0.0, 0.0, 0.0]
var _speed_seconds := {}
var _decisions := 0
var _summarized := false
var _start_factions := {}
var _start_money := 0


func setup(week_sim, play_source: String = "player") -> void:
	sim = week_sim
	source = play_source
	_started_msec = Time.get_ticks_msec()
	for id in sim.actors:
		_busy_hours[id] = 0.0
	for key in SPEED_KEYS:
		_speed_seconds[key] = 0.0
	_start_factions = sim.factions.duplicate()
	_start_money = sim.money
	var dir := ProjectSettings.globalize_path("user://playtests")
	DirAccess.make_dir_recursive_absolute(dir)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	path = "%s/%s_%s.jsonl" % [dir, stamp, source]
	_file = FileAccess.open(path, FileAccess.WRITE)
	print("play log: ", path)
	sim.option_chosen.connect(note_choose)
	sim.request_opened.connect(_on_request_opened)
	sim.request_changed.connect(_on_request_changed)
	sim.entry_added.connect(_on_entry_added)
	sim.promise_resolved.connect(func(status): record("promise", {"status": status}))
	sim.crisis_started.connect(func(id): record("crisis", {"request": id}))
	sim.overlay_changed.connect(func(lot, overlay, shown): record("overlay", {"lot": lot, "name": overlay, "shown": shown}))
	sim.time_changed.connect(_on_time_changed)
	sim.week_ended.connect(_on_week_ended)
	record("session_start", {"source": source, "season": Settings.season, "money": sim.money, "factions": sim.factions})


func _process(delta: float) -> void:
	var main = get_parent()
	var key: String = "planning" if main.phase == "planning" else str(int(main.speed))
	if main.phase in ["planning", "live"] and _speed_seconds.has(key):
		_speed_seconds[key] += delta


# --- Called by the UI and main -------------------------------------------------

func record(type: String, data: Dictionary = {}) -> void:
	if _file == null:
		return
	var line := {"ms": Time.get_ticks_msec() - _started_msec, "week": sim.week, "t": snappedf(sim.t, 0.01), "type": type}
	line.merge(data)
	_file.store_line(JSON.stringify(line))
	_file.flush()


func note_phase(phase: String) -> void:
	record("phase", {"name": phase})


func note_speed(value: float) -> void:
	record("speed", {"value": value})


func note_card_open(request_id: String, auto: bool) -> void:
	var entry: Dictionary = _requests.get(request_id, {})
	if not entry.has("first_look_ms"):
		entry["first_look_ms"] = Time.get_ticks_msec()
	_requests[request_id] = entry
	record("card_open", {"request": request_id, "auto": auto})


func note_card_close(request_id: String) -> void:
	record("card_close", {"request": request_id})


func note_choose(request_id: String, option_id: String, actor: String) -> void:
	var entry: Dictionary = _requests.get(request_id, {})
	if not entry.has("choice_ms"):
		entry["choice_ms"] = Time.get_ticks_msec()
		entry["choice_t"] = sim.t
		entry["option"] = option_id
	_requests[request_id] = entry
	_decisions += 1
	record("choose", {"request": request_id, "option": option_id, "actor": actor})


# --- Signals from the simulation ----------------------------------------------

func _on_request_opened(id: String) -> void:
	var entry: Dictionary = _requests.get(id, {})
	entry["type"] = sim.requests[id]["data"]["type"]
	entry["appear_ms"] = Time.get_ticks_msec()
	entry["appear_t"] = sim.t
	entry["status"] = "open"
	_requests[id] = entry
	record("request_open", {"request": id, "kind": entry["type"]})


func _on_request_changed(id: String) -> void:
	var status: String = sim.requests[id]["status"]
	var entry: Dictionary = _requests.get(id, {})
	if entry.get("status", "") == status:
		return
	entry["status"] = status
	if status == "closed":
		entry["closed_t"] = sim.t
	_requests[id] = entry
	record("request_status", {"request": id, "status": status})


func _on_entry_added(entry: Dictionary) -> void:
	if entry["tone"] != "request":
		record("news", {"text": entry["text"], "tone": entry["tone"]})


func _on_time_changed() -> void:
	var dt: float = sim.t - _last_t
	_last_t = sim.t
	if dt <= 0.0 or dt > 3.0:
		return
	for id in sim.actors:
		if sim.actors[id]["state"] != "idle":
			_busy_hours[id] += dt
	# Is there anything for the player to decide right now?
	var waiting_ids: Array[String] = []
	for id in sim.request_order:
		if sim.requests[id]["status"] == "open":
			waiting_ids.append(id)
	if waiting_ids.is_empty():
		_waiting_hours += dt
		_waiting_by_day[sim.day_index()] += dt
	elif not _any_option_possible(waiting_ids):
		_blocked_hours += dt
	var hour := int(sim.t)
	if hour != _last_sample_hour:
		_last_sample_hour = hour
		record("sample", _sample(waiting_ids))


func _any_option_possible(ids: Array[String]) -> bool:
	for id in ids:
		for option in sim.requests[id]["data"]["options"]:
			if sim.option_block_reason(id, option) == "":
				return true
	return false


func _sample(waiting_ids: Array[String]) -> Dictionary:
	var states := {}
	for id in sim.actors:
		states[id] = sim.actors[id]["state"]
	return {
		"money": sim.money, "traces": sim.traces, "factions": sim.factions.duplicate(),
		"waiting": waiting_ids, "actors": states,
	}


func _on_week_ended() -> void:
	_write_summary("week_end")


func _exit_tree() -> void:
	# Closed early: still leave a summary of what was played.
	_write_summary("session_end")


# --- Summary -----------------------------------------------------------------

func _write_summary(type: String) -> void:
	if _file == null or _summarized:
		return
	if type == "week_end":
		_summarized = false # session_end still follows, with the same numbers
	else:
		_summarized = true
	var rows := []
	for id in sim.request_order:
		if not _requests.has(id) or not _requests[id].has("appear_ms"):
			continue
		var entry: Dictionary = _requests[id]
		var row := {"request": id, "kind": entry["type"], "answered": entry.has("choice_ms")}
		if entry.has("choice_ms"):
			row["option"] = entry["option"]
			row["decision_seconds"] = snappedf((entry["choice_ms"] - entry["appear_ms"]) / 1000.0, 0.1)
			row["decision_game_hours"] = snappedf(entry["choice_t"] - entry["appear_t"], 0.1)
		if entry.has("first_look_ms"):
			row["first_look_seconds"] = snappedf((entry["first_look_ms"] - entry["appear_ms"]) / 1000.0, 0.1)
		if entry.has("closed_t"):
			row["open_game_hours"] = snappedf(entry["closed_t"] - entry["appear_t"], 0.1)
		rows.append(row)
	var total_hours: float = max(sim.t, 0.01)
	var utilization := {}
	for id in _busy_hours:
		utilization[id] = snappedf(_busy_hours[id] / total_hours, 0.01)
	var waiting_by_day := []
	for hours in _waiting_by_day:
		waiting_by_day.append(snappedf(hours, 0.1))
	var factions_change := {}
	for id in sim.factions:
		factions_change[id] = [_start_factions[id], sim.factions[id]]
	var summary := {
		"source": source,
		"real_seconds": snappedf((Time.get_ticks_msec() - _started_msec) / 1000.0, 0.1),
		"game_hours": snappedf(sim.t, 0.1),
		"decisions": _decisions,
		"requests": rows,
		"requests_expired_unanswered": rows.filter(func(row): return not row["answered"]).size(),
		"waiting_hours": snappedf(_waiting_hours, 0.1),
		"waiting_share": snappedf(_waiting_hours / total_hours, 0.01),
		"waiting_hours_by_day": waiting_by_day,
		"blocked_hours": snappedf(_blocked_hours, 0.1),
		"contact_utilization": utilization,
		"seconds_by_speed": _speed_seconds,
		"factions": factions_change,
		"money": [_start_money, sim.money],
		"traces": sim.traces,
	}
	record(type, summary)
	if type == "session_end":
		_file.close()
		_file = null
