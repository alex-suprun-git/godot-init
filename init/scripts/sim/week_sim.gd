# Node-free simulation of one week. The view calls advance() with game hours
# and listens to signals; nothing here knows about nodes, input or rendering.
extends RefCounted

const Week1 = preload("res://scripts/data/week1.gd")

signal time_changed
signal request_opened(id: String)
signal request_changed(id: String)
signal crisis_started(id: String)
signal entry_added(entry: Dictionary)
signal state_changed # money, standing, promises, objectives
signal overlay_changed(lot: String, overlay: String, visible: bool)
signal lot_state_changed(lot: String, state: String)
signal week_ended

const WEEK_HOURS := Week1.HOURS_PER_DAY * Week1.DAYS_PER_WEEK
const STEP := 0.25 # Simulation step in game hours; keeps event ordering stable at high speed.

var t := 0.0 # Working hours since Monday 08:00 of the current week.
var week := 1
var money: int = Week1.START_MONEY
var traces := 0
var factions := {}
var factions_at_start := {}
var flags := {}
var requests := {} # id -> {data, status: pending|open|assigned|closed, promised}
var request_order: Array[String] = []
var actors := {} # id -> {pos, lot, state: idle|travel|work|driving, request, option, work_left, driver}
var promises: Array[Dictionary] = []
var entries: Array[Dictionary] = [] # Wire: {time, text}
var outcomes: Array[String] = [] # Notable results for the week summary.
var next_week := {}
var lot_states := {"boiler": "broken"}
var report_checked := false
var ended := false
var rng := RandomNumberGenerator.new()


func _init(seed_value: int = 1997) -> void:
	rng.seed = seed_value
	for id in Week1.FACTIONS:
		factions[id] = Week1.FACTIONS[id]["value"]
	factions_at_start = factions.duplicate()
	for id in Week1.ACTORS:
		var lot: String = Week1.ACTORS[id]["start_lot"]
		actors[id] = {
			"pos": Week1.LOTS[lot]["pos"], "lot": lot, "state": "idle",
			"request": "", "option": {}, "work_left": 0.0, "driver": false,
		}
	for data in Week1.REQUESTS:
		requests[data["id"]] = {"data": data, "status": "pending", "promised": false}
		request_order.append(data["id"])


# Opens what is visible at Monday 08:00. Call after connecting signals.
func begin() -> void:
	_open_due_requests()


func advance(hours: float) -> void:
	while hours > 0.0 and not ended:
		var step: float = min(hours, STEP)
		hours -= step
		_tick(step)
	time_changed.emit()


# --- Queries -----------------------------------------------------------------

static func to_hours(when: Dictionary) -> float:
	return when["day"] * Week1.HOURS_PER_DAY + (when["hour"] - Week1.WORK_START_HOUR)


func day_index() -> int:
	return min(int(t / Week1.HOURS_PER_DAY), Week1.DAYS_PER_WEEK - 1)


func clock_text() -> String:
	var in_day: float = t - day_index() * Week1.HOURS_PER_DAY
	var total_minutes := int(in_day * 60.0)
	var hour: int = Week1.WORK_START_HOUR + total_minutes / 60
	return "%02d:%02d" % [hour, total_minutes % 60]


func date_text(day: int = -1) -> String:
	if day < 0:
		day = day_index()
	var first: int = Week1.FIRST_DAY + (week - 1) * 7
	var date := first + day
	var month: int = Week1.MONTH
	if date > 31:
		date -= 31
		month += 1
	return "%s %02d.%02d.%d" % [Week1.DAY_NAMES[day], date, month, Week1.YEAR]


func when_text(when: Dictionary) -> String:
	return "%s %02d:00" % [Week1.DAY_NAMES[when["day"]], when["hour"]]


static func standing_word(value: int) -> String:
	for step in Week1.STANDING_WORDS:
		if value <= step["max"]:
			return step["word"]
	return Week1.STANDING_WORDS[-1]["word"]


func visible_requests() -> Array[String]:
	var ids: Array[String] = []
	for id in request_order:
		if requests[id]["status"] in ["open", "assigned"]:
			ids.append(id)
	return ids


func objective_status(objective: Dictionary) -> String:
	if objective.has("flag"):
		if flags.has(objective["flag"]):
			return "done"
		return "failed" if requests[objective["id"]]["status"] == "closed" else "pending"
	if not report_checked:
		return "pending"
	return "done" if flags.get("report", false) else "failed"


func actor_status_text(id: String) -> String:
	var actor: Dictionary = actors[id]
	var lot_name: String = Week1.LOTS[actor["lot"]]["name"]
	match actor["state"]:
		"travel":
			return "В пути: " + Week1.LOTS[_request_lot(actor["request"])]["name"]
		"work":
			return "%s · ещё %d ч" % [requests[actor["request"]]["data"]["title"], ceil(actor["work_left"])]
		"driving":
			return "Везёт вас"
	return "Свободен · " + lot_name


# Empty string when the option can be chosen, otherwise the reason it cannot.
func option_block_reason(request_id: String, option: Dictionary) -> String:
	var request: Dictionary = requests[request_id]
	if request["status"] != "open":
		return "Уже в работе"
	match option["actor"]:
		"promise":
			return "Уже обещано" if request["promised"] else ""
		"phone":
			var me: Dictionary = actors["me"]
			if me["state"] != "idle" or me["lot"] != "office":
				return "Телефон только в кабинете"
			return ""
	var actor: Dictionary = actors[option["actor"]]
	if actor["state"] != "idle":
		return "Занят"
	return ""


# --- Commands ----------------------------------------------------------------

func choose(request_id: String, option_id: String) -> void:
	var request: Dictionary = requests[request_id]
	var option := _find_option(request, option_id)
	if option.is_empty() or option_block_reason(request_id, option) != "":
		return
	match option["actor"]:
		"promise":
			_make_promise(request, option["promise"])
		"phone":
			_resolve(request_id, option)
		_:
			var actor: Dictionary = actors[option["actor"]]
			actor["state"] = "travel"
			actor["request"] = request_id
			actor["option"] = option
			actor["work_left"] = float(option.get("hours", 1))
			if option["actor"] == "me" and actors["tolik"]["state"] == "idle":
				actor["driver"] = true
				actors["tolik"]["state"] = "driving"
			request["status"] = "assigned"
			request_changed.emit(request_id)
	state_changed.emit()


func begin_next_week() -> Array[String]:
	var changes: Array[String] = []
	week += 1
	t = 0.0
	for lot in next_week:
		lot_states[lot] = next_week[lot]
		lot_state_changed.emit(lot, next_week[lot])
		if lot == "boiler" and next_week[lot] == "repairing":
			changes.append("Котельную обнесли забором и поставили леса: ремонт начался.")
	if overlay_on("block5", "picket"):
		changes.append("Пикет у дома 5 стоит и в понедельник. Плакаты подновили.")
	if flags.get("coal_stolen", false):
		changes.append("Угольная куча у котельной заметно меньше, чем в прошлый понедельник.")
	if changes.is_empty():
		changes.append("Выходные прошли тихо. Подозрительно тихо.")
	next_week.clear()
	time_changed.emit()
	return changes


var _overlays := {}


func overlay_on(lot: String, overlay: String) -> bool:
	return _overlays.get(lot + ":" + overlay, false)


# --- Internals ---------------------------------------------------------------

func _tick(step: float) -> void:
	t = min(t + step, float(WEEK_HOURS))
	_open_due_requests()
	_move_actors(step)
	_expire_requests()
	_check_promises()
	_check_report()
	if t >= WEEK_HOURS:
		ended = true
		week_ended.emit()


func _open_due_requests() -> void:
	for id in request_order:
		var request: Dictionary = requests[id]
		if request["status"] == "pending" and to_hours(request["data"]["appear"]) <= t:
			request["status"] = "open"
			var data: Dictionary = request["data"]
			if data.has("overlay"):
				_set_overlay(data["overlay"]["lot"], data["overlay"]["name"], true)
			_add_entry("Новое: " + data["title"])
			request_opened.emit(id)
			if data["type"] == "crisis":
				crisis_started.emit(id)


func _move_actors(step: float) -> void:
	for id in actors:
		var actor: Dictionary = actors[id]
		if actor["state"] == "travel":
			var target: Vector2 = Week1.LOTS[_request_lot(actor["request"])]["pos"]
			var speed: float = Week1.ACTORS["tolik" if actor["driver"] else id]["speed"]
			var pos: Vector2 = actor["pos"]
			actor["pos"] = pos.move_toward(target, speed * step)
			if actor["pos"].distance_to(target) < 0.01:
				actor["state"] = "work"
				actor["lot"] = _request_lot(actor["request"])
		elif actor["state"] == "work":
			actor["work_left"] -= step
			if actor["work_left"] <= 0.0:
				_resolve(actor["request"], actor["option"])
	if actors["me"]["driver"]:
		actors["tolik"]["pos"] = actors["me"]["pos"]
		actors["tolik"]["lot"] = actors["me"]["lot"]


func _resolve(request_id: String, option: Dictionary) -> void:
	var request: Dictionary = requests[request_id]
	var success: bool = rng.randf() < float(option.get("chance", 1.0))
	var effects: Dictionary = option["success"] if success else option.get("fail", option["success"])
	_apply(effects)
	request["status"] = "open" if effects.get("reopen", false) else "closed"
	if request["status"] == "closed" and request["data"].has("overlay"):
		var overlay: Dictionary = request["data"]["overlay"]
		_set_overlay(overlay["lot"], overlay["name"], false)
	var actor_id: String = option["actor"]
	if actors.has(actor_id):
		var actor: Dictionary = actors[actor_id]
		actor["state"] = "idle"
		actor["request"] = ""
		if actor["driver"]:
			actor["driver"] = false
			actors["tolik"]["state"] = "idle"
	request_changed.emit(request_id)
	state_changed.emit()


func _expire_requests() -> void:
	for id in request_order:
		var request: Dictionary = requests[id]
		if request["status"] == "open" and to_hours(request["data"]["expire"]) <= t:
			request["status"] = "closed"
			_apply(request["data"]["expire_effects"])
			if request["data"].has("overlay"):
				var overlay: Dictionary = request["data"]["overlay"]
				_set_overlay(overlay["lot"], overlay["name"], false)
			request_changed.emit(id)
			state_changed.emit()


func _make_promise(request: Dictionary, promise: Dictionary) -> void:
	request["promised"] = true
	promises.append({
		"text": promise["text"], "due": to_hours(promise["due"]), "due_text": when_text(promise["due"]),
		"flag": promise["flag"], "kept": promise["kept"], "broken": promise["broken"], "status": "active",
	})
	_apply(promise["made"])
	request_changed.emit(request["data"]["id"])


func _check_promises() -> void:
	for promise in promises:
		if promise["status"] != "active":
			continue
		if flags.get(promise["flag"], false):
			promise["status"] = "kept"
			_apply(promise["kept"])
		elif promise["due"] <= t:
			promise["status"] = "broken"
			_apply(promise["broken"])


func _check_report() -> void:
	if report_checked or to_hours(Week1.REPORT_TIME) > t:
		return
	report_checked = true
	var me: Dictionary = actors["me"]
	var present: bool = me["lot"] == "office" and me["state"] == "idle"
	flags["report"] = present
	_apply(Week1.REPORT_OK if present else Week1.REPORT_MISSED)


func _apply(effects: Dictionary) -> void:
	for id in factions:
		if effects.has(id):
			factions[id] += effects[id]
	if effects.has("money"):
		money += effects["money"]
	traces += effects.get("trace", 0)
	for key in effects.get("flags", {}):
		flags[key] = effects["flags"][key]
	for lot in effects.get("next_week", {}):
		next_week[lot] = effects["next_week"][lot]
	if effects.has("overlay"):
		_set_overlay(effects["overlay"]["lot"], effects["overlay"]["name"], true)
	if effects.has("log"):
		_add_entry(effects["log"])
		outcomes.append(effects["log"])
	state_changed.emit()


func _set_overlay(lot: String, overlay: String, visible: bool) -> void:
	_overlays[lot + ":" + overlay] = visible
	overlay_changed.emit(lot, overlay, visible)


func _add_entry(text: String) -> void:
	var entry := {"time": clock_text(), "text": text}
	entries.append(entry)
	entry_added.emit(entry)


func _request_lot(request_id: String) -> String:
	return requests[request_id]["data"]["lot"]


func _find_option(request: Dictionary, option_id: String) -> Dictionary:
	for option in request["data"]["options"]:
		if option["id"] == option_id:
			return option
	return {}
