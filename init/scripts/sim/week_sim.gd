# Node-free simulation of one week. The view calls advance() with game hours
# and listens to signals; nothing here knows about nodes, input or rendering.
extends RefCounted

const Week1 = preload("res://scripts/data/week1.gd")
const RoadGraph = preload("res://scripts/map/road_graph.gd")

signal time_changed
signal request_opened(id: String)
signal request_changed(id: String)
signal crisis_started(id: String)
signal entry_added(entry: Dictionary)
signal state_changed # money, standing, promises, objectives
signal money_changed
signal overlay_changed(lot: String, overlay: String, visible: bool)
signal lot_state_changed(lot: String, state: String)
signal promise_resolved(status: String) # "kept" or "broken"
signal option_chosen(request_id: String, option_id: String, actor: String)
signal week_ended
signal day_started(day: int) # A new working day began; everyone is back at their start lot.
signal workday_started # The protagonist has arrived at the administration at 08:00.

const WEEK_HOURS := Week1.HOURS_PER_DAY * Week1.DAYS_PER_WEEK
# What a request's card says about its wait when the data gives no wait_text.
const URGENCY_WAIT := {"now": "Ждут на месте", "today": "Только сегодня", "days": "Может подождать", "week": "Задача недели"}
const STEP := 0.25 # Simulation step in game hours; keeps event ordering stable at high speed.

var t := 0.0 # Scheduled awake hours since Monday 06:00; overtime is separate.
var _day := 0
var overtime_hours := 0.0
var last_day_end_hour := 22.0
var _day_closing := false
var _morning_started := false
var at_work := false
var _salary_months := {} # Calendar month keys already paid in this campaign.
var rent_debt := 0
var paperwork_hours := 0.0 # Accumulated across days; reset only for a new week.
var week := 1
var press_history := {} # Completed-week public facts; no private choices or money.
var money: int = Week1.START_MONEY
var traces := 0
var factions := {}
var factions_at_start := {}
var flags := {}
var requests := {} # id -> {data, status: pending|open|assigned|closed, promised}
var request_order: Array[String] = []
var actors := {} # id -> {pos, lot, state: idle|travel|work|driving, request, option, work_left, driver, path, path_index}
var graph: RoadGraph # Roads derived from the layout; people travel along it.
var promises: Array[Dictionary] = []
var entries: Array[Dictionary] = [] # Wire: {time, text}
var outcomes: Array[Dictionary] = [] # Week summary lines: {text, lot, kind, weight}.
var threads: Array[String] = [] # Unfinished business carried into next week.
var next_week := {}
var lot_states := {"boiler": "broken"}
var ended := false
var rng := RandomNumberGenerator.new()


func _init(seed_value: int = 1997) -> void:
	if not Week1.validate_layout():
		return
	rng.seed = seed_value
	for id in Week1.FACTIONS:
		factions[id] = Week1.FACTIONS[id]["value"]
	factions_at_start = factions.duplicate()
	var layout_lots: Array = []
	for id in Week1.LOTS:
		layout_lots.append(Week1.LOTS[id]["layout"])
	graph = RoadGraph.new(layout_lots)
	for id in Week1.ACTORS:
		var lot: String = Week1.ACTORS[id]["start_lot"]
		actors[id] = {
			"pos": graph.entrance_position(Week1.LOTS[lot]["layout"]), "lot": lot, "state": "idle",
			"request": "", "option": {}, "work_left": 0.0, "driver": false,
			"path": PackedVector2Array(), "path_index": 0, "commute_target": "",
		}
	for data in Week1.REQUESTS:
		if not data.get("enabled", true):
			continue
		requests[data["id"]] = {
			"data": data, "status": "pending", "promised": false,
			"expire_t": _expire_hours(data), "escalated": 0,
			"jobs": {}, # option id -> remaining on-site work; survives reassignment.
			"responded": false, # Arrival satisfies the reaction deadline; completion is separate.
		}
		request_order.append(data["id"])


# Opens what is visible at Monday 06:00. Call after connecting signals.
func begin() -> void:
	_sync_contact_availability()
	_pay_salary_if_due()
	_open_due_requests()


# The prologue supplies Monday's arrival. Start the simulation at its handoff
# so ordinary morning travel and requests cannot run underneath the cutscene.
func arrive_after_prologue(hour: float) -> void:
	var me: Dictionary = actors["me"]
	me["lot"] = "office"
	me["pos"] = graph.entrance_position(Week1.LOTS["office"]["layout"])
	_morning_started = true
	at_work = true
	t = hour - Week1.DAY_START_HOUR
	begin()
	_record_workday_start()
	time_changed.emit()


func advance(hours: float) -> void:
	while hours > 0.0 and not ended:
		_update_morning()
		var day_end := float((_day + 1) * Week1.HOURS_PER_DAY)
		var step: float = minf(hours, STEP)
		for id in Week1.enabled_actor_ids():
			if id == "me":
				continue
			var availability: Dictionary = Week1.ACTORS[id].get("availability", {"start": Week1.WORK_START_HOUR, "end": Week1.WORK_END_HOUR})
			for boundary in [availability["start"], availability["end"]]:
				if float(boundary) > clock_hour() + 0.00001:
					step = minf(step, float(boundary) - clock_hour())
		if not _day_closing:
			step = minf(step, day_end - t)
			if not at_work:
				var boundary := _morning_departure() if actors["me"]["state"] == "idle" else float(Week1.WORK_START_HOUR)
				if boundary > clock_hour():
					step = minf(step, boundary - clock_hour())
		# Arrivals and job completions are exact events, even at high simulation speed.
		for id in actors:
			if actors[id]["state"] in ["travel", "work"]:
				var left := actor_eta_hours(id)
				if left > 0.00001:
					step = minf(step, left)
		if actors["me"]["state"] == "paperwork":
			step = minf(step, paperwork_left())
		for request_id in request_order:
			var request: Dictionary = requests[request_id]
			if request["status"] in ["open", "assigned"] and not request["responded"] and _active_promise(request_id).is_empty():
				var until_deadline: float = request["expire_t"] - t
				if until_deadline > 0.00001:
					step = minf(step, until_deadline)
		hours -= step
		var was_at_work := at_work
		_tick(step)
		_update_morning()
		if not _day_closing and t >= day_end - 0.00001:
			t = day_end
			_day_closing = true
			if actors["me"]["state"] == "paperwork":
				pause_paperwork()
		if _day_closing:
			var me: Dictionary = actors["me"]
			if me["state"] == "idle":
				if me["lot"] == "dormitory":
					_finish_day()
					break
				_begin_commute("dormitory")
		if not was_at_work and at_work:
			break # The view may pause for the boss's message on arrival.
	time_changed.emit()


# --- Queries -----------------------------------------------------------------

static func to_hours(when: Dictionary) -> float:
	return when["day"] * Week1.HOURS_PER_DAY + (when["hour"] - Week1.DAY_START_HOUR)


func day_index() -> int:
	return _day


# Where an actor starts each day: the doorstep of their start lot, or its entrance.
func home_position(id: String) -> Vector2:
	var layout: String = Week1.LOTS[Week1.ACTORS[id]["start_lot"]]["layout"]
	return graph.doorsteps.get(layout, graph.entrance_position(layout))


# Clock hour as a float (08:30 is 8.5), the same time clock_text() shows.
func clock_hour() -> float:
	return Week1.DAY_START_HOUR + (t - _day * Week1.HOURS_PER_DAY) + overtime_hours


func clock_text() -> String:
	var total_minutes := int(round(clock_hour() * 60.0))
	return "%02d:%02d" % [(total_minutes / 60) % 24, total_minutes % 60]


func date_text(day: int = -1) -> String:
	if day < 0:
		day = day_index()
	var date := day_date(day)
	return "%s %02d.%02d.%d" % [Week1.DAY_NAMES[day], date.x, date.y, Week1.YEAR]


# Day of month and month (x, y) of a weekday in the current week.
func day_date(day: int) -> Vector2i:
	var stamp := Time.get_unix_time_from_datetime_dict({"year": Week1.YEAR, "month": Week1.MONTH, "day": Week1.FIRST_DAY})
	var date := Time.get_datetime_dict_from_unix_time(stamp + ((week - 1) * 7 + day) * 86400)
	return Vector2i(date["day"], date["month"])


func when_text(when: Dictionary) -> String:
	return "%s %02d:00" % [Week1.DAY_NAMES[when["day"]], when["hour"]]


# Scheduled hours since Monday 06:00 as a weekday and clock time ("Ср 20:00").
func hours_text(hours: float, with_day: bool = true) -> String:
	var day: int = clampi(int(hours / Week1.HOURS_PER_DAY), 0, Week1.DAYS_PER_WEEK - 1)
	var minutes := int(round((hours - day * Week1.HOURS_PER_DAY) * 60.0))
	var clock := "%02d:%02d" % [Week1.DAY_START_HOUR + minutes / 60, minutes % 60]
	return "%s %s" % [Week1.DAY_NAMES[day], clock] if with_day else clock


# How long a request waits, told as its situation: "Ждут у вокзала · ещё ~2 ч".
func request_wait_text(request_id: String) -> String:
	var request: Dictionary = requests[request_id]
	var data: Dictionary = request["data"]
	match request_stage(request_id):
		"closed":
			return "Вопрос закрыт"
		"work":
			return "Исполнитель на месте · идёт работа"
		"paused":
			return "Работа прервана · назначьте продолжение"
	var promise := _active_promise(request_id)
	if not promise.is_empty():
		return "Обещано · до " + promise["due_text"]
	var urgency: String = data.get("urgency", "week")
	var wait: String = data.get("wait_text", URGENCY_WAIT[urgency])
	match urgency:
		"now":
			var left: float = request["expire_t"] - t
			return wait + (" · меньше часа" if left < 1.0 else " · ещё ~%d ч" % ceili(left))
		"today":
			return wait + " · до " + hours_text(request["expire_t"], false)
	return wait + " · до " + hours_text(request["expire_t"])


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
	if objective["id"] == "paperwork":
		if paperwork_left() <= 0.00001:
			return "done"
		return "failed" if ended else "pending"
	if objective.has("flag"):
		if flags.has(objective["flag"]):
			return "done"
		return "failed" if requests[objective["id"]]["status"] == "closed" else "pending"
	return "pending"


func actor_status_text(id: String) -> String:
	if not actor_available(id):
		return actor_unavailable_text(id)
	var actor: Dictionary = actors[id]
	var lot_name: String = Week1.LOTS[actor["lot"]]["name"]
	match actor["state"]:
		"paperwork":
			return "Документы · осталось %.1f ч" % paperwork_left()
		"travel":
			return "В пути: " + Week1.LOTS[_actor_destination(actor)]["name"]
		"work":
			return "%s · ещё %d ч" % [requests[actor["request"]]["data"]["title"], ceil(actor["work_left"])]
		"driving":
			return "Везёт вас"
	return "Свободен · " + lot_name


# Where an actor is heading or working right now ("" when idle). Tolik follows
# whoever he is driving.
func actor_target_lot(id: String) -> String:
	var actor: Dictionary = actors[id]
	if actor["state"] == "driving":
		return actor_target_lot("me")
	if actor["state"] in ["travel", "work"]:
		return _actor_destination(actor)
	return ""


# The way still ahead: the actor's position followed by the remaining route.
func actor_route(id: String) -> PackedVector2Array:
	var actor: Dictionary = actors[id]
	if actor["state"] == "driving":
		return actor_route("me")
	var route := PackedVector2Array([actor["pos"]])
	if actor["state"] == "travel":
		for i in range(actor["path_index"], actor["path"].size()):
			route.append(actor["path"][i])
	return route


# Game hours until an actor arrives (travelling) or finishes (working).
func actor_eta_hours(id: String) -> float:
	var actor: Dictionary = actors[id]
	match actor["state"]:
		"driving":
			return actor_eta_hours("me")
		"travel":
			var speed: float = Week1.ACTORS["tolik" if actor["driver"] else id]["speed"]
			return RoadGraph.length(actor["path"], actor["pos"], actor["path_index"]) / speed
		"work":
			return actor["work_left"]
	return 0.0


# 0..1 of the work already done, for the progress ring.
func actor_work_fraction(id: String) -> float:
	var actor: Dictionary = actors[id]
	if actor["state"] == "paperwork":
		return paperwork_hours / Week1.PAPERWORK_HOURS
	if actor["state"] != "work":
		return 0.0
	return 1.0 - actor["work_left"] / max(actor.get("work_total", 1.0), 0.01)


# Which actor is dealing with a request right now ("" when nobody is).
func request_worker(request_id: String) -> String:
	for id in actors:
		if actors[id]["request"] == request_id and actors[id]["state"] in ["travel", "work"]:
			return id
	return ""


# A shared lifecycle derived from the request and its actor, never from a quest id.
func request_stage(request_id: String) -> String:
	var request: Dictionary = requests[request_id]
	if request["status"] in ["closed", "pending"]:
		return request["status"]
	var worker := request_worker(request_id)
	if worker != "":
		return actors[worker]["state"] # travel or work
	return "paused" if request["responded"] else "waiting"


# 1 when the request just appeared, 0 when its deadline is reached.
func request_time_left(request_id: String) -> float:
	var data: Dictionary = requests[request_id]["data"]
	var start := to_hours(data["appear"])
	var end: float = requests[request_id]["expire_t"]
	return clamp((end - t) / max(end - start, 0.01), 0.0, 1.0)


# Empty string when the option can be chosen, otherwise the reason it cannot.
func option_block_reason(request_id: String, option: Dictionary) -> String:
	if ended or _day_closing:
		return "День окончен · возвращение в общежитие"
	if not at_work:
		return "Рабочий день начинается в администрации в 08:00"
	var request: Dictionary = requests[request_id]
	if request["status"] != "open":
		return "Уже в работе"
	match option["actor"]:
		"promise":
			return "Уже обещано" if request["promised"] else ""
		"phone":
			var me: Dictionary = actors["me"]
			if me["state"] not in ["idle", "paperwork"] or me["lot"] != "office":
				return "Телефон только в кабинете"
			return ""
	if not Week1.actor_enabled(option["actor"]):
		return "Недоступен"
	if not actor_available(option["actor"]):
		return actor_unavailable_text(option["actor"])
	var actor: Dictionary = actors[option["actor"]]
	if actor["state"] == "paperwork":
		return "Сначала отложите документы"
	if actor["state"] != "idle":
		return "Занят"
	if option.has("requires_lot") and actor["lot"] != option["requires_lot"]:
		return "Только лично · " + Week1.LOTS[option["requires_lot"]]["name"]
	return ""


# --- Commands ----------------------------------------------------------------

func paperwork_left() -> float:
	return maxf(0.0, Week1.PAPERWORK_HOURS - paperwork_hours)


# The same office control starts/pauses paperwork, or walks back to the office.
func paperwork_block_reason() -> String:
	if ended or _day_closing:
		return "Рабочий день окончен"
	if not at_work:
		return "После прибытия в администрацию в 08:00"
	var me: Dictionary = actors["me"]
	if me["state"] == "paperwork":
		return ""
	if me["state"] != "idle":
		return "Вы заняты"
	if me["lot"] == "office" and paperwork_left() <= 0.00001:
		return "Норма недели выполнена"
	return ""


func start_paperwork() -> void:
	if paperwork_block_reason() != "" or actors["me"]["lot"] != "office" or paperwork_left() <= 0.00001:
		return
	actors["me"]["state"] = "paperwork"
	_add_entry("Вы сели за документы. На неделю осталось %.1f ч." % paperwork_left())
	state_changed.emit()


func pause_paperwork() -> void:
	if actors["me"]["state"] != "paperwork":
		return
	actors["me"]["state"] = "idle"
	_add_entry("Документы отложены. Сделано %.1f из %.0f ч; прогресс сохранён." % [paperwork_hours, Week1.PAPERWORK_HOURS])
	state_changed.emit()


func return_to_office() -> void:
	if paperwork_block_reason() == "" and actors["me"]["state"] == "idle" and actors["me"]["lot"] != "office":
		_begin_commute("office")

func choose(request_id: String, option_id: String) -> void:
	var request: Dictionary = requests[request_id]
	var option := _find_option(request, option_id)
	if option.is_empty() or option_block_reason(request_id, option) != "":
		return
	option_chosen.emit(request_id, option_id, option["actor"])
	match option["actor"]:
		"promise":
			_make_promise(request, option["promise"])
		"phone":
			_resolve(request_id, option)
		_:
			var actor: Dictionary = actors[option["actor"]]
			if float(option.get("hours", 1)) <= 0.0 and actor["lot"] == _request_lot(request_id):
				_resolve(request_id, option)
				return
			actor["state"] = "travel"
			actor["request"] = request_id
			actor["option"] = option
			var jobs: Dictionary = request["jobs"]
			if not jobs.has(option_id):
				jobs[option_id] = {"left": float(option.get("hours", 1)), "total": float(option.get("hours", 1))}
			actor["work_left"] = jobs[option_id]["left"]
			actor["work_total"] = jobs[option_id]["total"]
			if option["actor"] == "me" and Week1.actor_enabled("tolik") and actors["tolik"]["state"] == "idle":
				actor["driver"] = true
				actors["tolik"]["state"] = "driving"
			# By car when Tolik drives, otherwise on foot; the route is fixed at the start.
			actor["path"] = graph.route(actor["pos"], Week1.LOTS[_request_lot(request_id)]["layout"], "car" if actor["driver"] else "foot")
			actor["path_index"] = 1
			request["status"] = "assigned"
			request_changed.emit(request_id)
	state_changed.emit()


func begin_next_week() -> Array[String]:
	press_history[week] = {
		"recorded": true,
		"water_restored": bool(flags.get("hot_water", false)),
		"picket": overlay_on("block5", "picket"),
		"boiler_repairs": next_week.get("boiler", lot_states.get("boiler", "")) == "repairing",
		"coal_loss": bool(flags.get("coal_stolen", false)),
	}
	var changes: Array[String] = []
	week += 1
	t = 0.0
	_day = 0
	overtime_hours = 0.0
	_day_closing = false
	_morning_started = false
	at_work = false
	paperwork_hours = 0.0
	flags.erase("paperwork")
	ended = false
	_reset_actors_for_morning()
	_pay_salary_if_due()
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


# Unfinished business for the week summary: explicit threads from results,
# then what the state itself still says.
func summary_threads() -> Array[String]:
	var lines: Array[String] = []
	lines.assign(threads)
	for promise in promises:
		if promise["status"] == "active":
			lines.append("Обещание в силе: " + promise["text"].to_lower() + ".")
	if overlay_on("block5", "picket"):
		lines.append("У дома 5 стоит пикет.")
	if next_week.get("boiler", "") == "repairing":
		lines.append("В понедельник на котельной начнётся ремонт.")
	if traces > 0:
		lines.append("Есть люди, которые кое-что видели.")
	return lines


var _overlays := {}


func overlay_on(lot: String, overlay: String) -> bool:
	return _overlays.get(lot + ":" + overlay, false)


# --- Internals ---------------------------------------------------------------

func _tick(step: float) -> void:
	if _day_closing:
		overtime_hours += step
	else:
		t += step
		_open_due_requests()
	_move_actors(step)
	_sync_contact_availability()
	_escalate_requests()
	_expire_requests()
	_check_promises()


# The night resets positions, not assignments: interrupted jobs await a new order.
func _reset_actors_for_morning() -> void:
	for id in actors:
		var actor: Dictionary = actors[id]
		actor["pos"] = home_position(id)
		actor["lot"] = Week1.ACTORS[id]["start_lot"]
	_sync_contact_availability()


func actor_available(id: String) -> bool:
	if not Week1.actor_enabled(id):
		return false
	if id == "me":
		return true
	var availability: Dictionary = Week1.ACTORS[id].get("availability", {"start": Week1.WORK_START_HOUR, "end": Week1.WORK_END_HOUR})
	return clock_hour() >= float(availability["start"]) - 0.00001 and clock_hour() < float(availability["end"]) - 0.00001


func actor_unavailable_text(id: String) -> String:
	var availability: Dictionary = Week1.ACTORS[id].get("availability", {"start": Week1.WORK_START_HOUR, "end": Week1.WORK_END_HOUR})
	return "Недоступен · часы связи %02d:00–%02d:00" % [availability["start"], availability["end"]]


func _sync_contact_availability() -> void:
	var changed := false
	for id in Week1.enabled_actor_ids():
		if id == "me":
			continue
		var actor: Dictionary = actors[id]
		if actor_available(id):
			if actor["state"] == "unavailable":
				actor["state"] = "idle"
				changed = true
			continue
		if actor["state"] == "unavailable":
			continue
		if actor["state"] in ["travel", "work"] and actor["request"] != "":
			var request_id: String = actor["request"]
			var request: Dictionary = requests[request_id]
			request["status"] = "open"
			_add_entry("%s больше недоступен. «%s» не закончено — назначьте продолжение вручную." % [Week1.ACTORS[id]["name"], request["data"]["title"]], "neutral")
			actor["request"] = ""
			actor["option"] = {}
			request_changed.emit(request_id)
		actor["state"] = "unavailable"
		actor["path"] = PackedVector2Array()
		actor["path_index"] = 0
		actor["pos"] = home_position(id)
		actor["lot"] = Week1.ACTORS[id]["start_lot"]
		changed = true
	if changed:
		state_changed.emit()


func _morning_departure() -> float:
	var me: Dictionary = actors["me"]
	var path := graph.route(me["pos"], Week1.LOTS["office"]["layout"], "foot")
	return maxf(Week1.DAY_START_HOUR, Week1.WORK_START_HOUR - RoadGraph.length(path) / Week1.ACTORS["me"]["speed"])


func _update_morning() -> void:
	if at_work or _day_closing:
		return
	var me: Dictionary = actors["me"]
	if not _morning_started and clock_hour() >= _morning_departure() - 0.00001:
		_morning_started = true
		_begin_commute("office")
	if _morning_started and me["state"] == "idle" and me["lot"] == "office" and clock_hour() >= Week1.WORK_START_HOUR - 0.00001:
		at_work = true
		_record_workday_start()


func _record_workday_start() -> void:
	_add_entry("%s · Вы в администрации. Рабочий день до 18:00." % clock_text())
	workday_started.emit()


func _begin_commute(lot: String) -> void:
	var me: Dictionary = actors["me"]
	me["state"] = "travel"
	me["commute_target"] = lot
	me["driver"] = false
	me["path"] = graph.route(me["pos"], Week1.LOTS[lot]["layout"], "foot")
	me["path_index"] = 1
	state_changed.emit()


func _actor_destination(actor: Dictionary) -> String:
	var commute: String = actor.get("commute_target", "")
	return commute if commute != "" else _request_lot(actor["request"])


func _finish_day() -> void:
	last_day_end_hour = clock_hour()
	if _day == Week1.DAYS_PER_WEEK - 1:
		if paperwork_left() > 0.00001:
			_apply({"boss": -Week1.PAPERWORK_BOSS_PENALTY, "log": "Документы за неделю не закончены: %.1f из %.0f ч. Шеф недоволен." % [paperwork_hours, Week1.PAPERWORK_HOURS]}, {"lot": "office", "kind": "missed"})
		var paid := mini(money, Week1.WEEKLY_RENT)
		_change_money(-paid)
		rent_debt += Week1.WEEKLY_RENT - paid
		_add_entry("Аренда общежития: −%d руб.%s" % [paid, " Долг: %d руб." % rent_debt if rent_debt > 0 else ""])
		state_changed.emit()
		ended = true
		week_ended.emit()
		return
	_day += 1
	t = float(_day * Week1.HOURS_PER_DAY)
	overtime_hours = 0.0
	_day_closing = false
	_morning_started = false
	at_work = false
	_reset_actors_for_morning()
	_pay_salary_if_due()
	day_started.emit(_day)


func _pay_salary_if_due() -> void:
	var date := day_date(_day)
	var month_key := "%d-%d" % [Week1.YEAR, date.y]
	# Weekend days are skipped: pay on the first playable day on/after payday.
	if date.x >= Week1.PAYDAY and date.x <= Week1.PAYDAY + 2 and not _salary_months.has(month_key):
		_salary_months[month_key] = true
		_change_money(Week1.MONTHLY_SALARY)
		_add_entry("Зарплата за месяц: +%d руб." % Week1.MONTHLY_SALARY)
		state_changed.emit()


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
			var speed: float = Week1.ACTORS["tolik" if actor["driver"] else id]["speed"]
			# Spend the step's distance along the route; leftovers carry over junctions.
			var budget: float = speed * step
			var path: PackedVector2Array = actor["path"]
			var index: int = actor["path_index"]
			var pos: Vector2 = actor["pos"]
			while index < path.size() and budget > 0.0:
				var leg := pos.distance_to(path[index])
				if leg <= budget + 0.0001:
					budget = maxf(0.0, budget - leg)
					pos = path[index]
					index += 1
				else:
					pos = pos.move_toward(path[index], budget)
					budget = 0.0
			actor["pos"] = pos
			actor["path_index"] = index
			if index >= path.size():
				actor["lot"] = _actor_destination(actor)
				if actor["commute_target"] != "":
					actor["commute_target"] = ""
					actor["state"] = "idle"
				else:
					actor["state"] = "work"
					requests[actor["request"]]["responded"] = true
					request_changed.emit(actor["request"])
		elif actor["state"] == "work":
			actor["work_left"] -= step
			requests[actor["request"]]["jobs"][actor["option"]["id"]]["left"] = maxf(0.0, actor["work_left"])
			if actor["work_left"] <= 0.00001:
				_resolve(actor["request"], actor["option"])
		elif actor["state"] == "paperwork":
			paperwork_hours = minf(Week1.PAPERWORK_HOURS, paperwork_hours + step)
			if paperwork_left() <= 0.00001:
				paperwork_hours = Week1.PAPERWORK_HOURS
				actor["state"] = "idle"
				_apply({"flags": {"paperwork": true}, "log": "Работа с документами за неделю закончена: %.0f ч. Обязательная норма выполнена." % Week1.PAPERWORK_HOURS}, {"lot": "office", "kind": "done"})
	if actors["me"]["driver"]:
		actors["tolik"]["pos"] = actors["me"]["pos"]
		actors["tolik"]["lot"] = actors["me"]["lot"]


func _resolve(request_id: String, option: Dictionary) -> void:
	var request: Dictionary = requests[request_id]
	var success: bool = rng.randf() < float(option.get("chance", 1.0))
	var effects: Dictionary = option["success"] if success else option.get("fail", option["success"])
	# A failed attempt may reopen a request; a new attempt starts its work afresh.
	request["jobs"].clear()
	_apply(effects, {"lot": request["data"]["lot"], "kind": "done" if success else "failed"})
	request["status"] = "open" if effects.get("reopen", false) else "closed"
	if request["status"] == "closed" and request["data"].has("overlay"):
		var overlay: Dictionary = request["data"]["overlay"]
		_set_overlay(overlay["lot"], overlay["name"], false)
	_release_request_worker(request_id)
	request_changed.emit(request_id)
	state_changed.emit()


func _release_request_worker(request_id: String, finish_travel: bool = false) -> void:
	for id in actors:
		var actor: Dictionary = actors[id]
		if actor["request"] != request_id:
			continue
		if finish_travel and actor["state"] == "travel":
			# The appointment is gone, but a person already on the road still
			# finishes the trip without starting work or producing quest effects.
			actor["commute_target"] = _request_lot(request_id)
		else:
			actor["state"] = "idle"
		actor["request"] = ""
		actor["option"] = {}
		if actor["driver"]:
			actor["driver"] = false
			actors["tolik"]["state"] = "idle"


func _expire_requests() -> void:
	for id in request_order:
		var request: Dictionary = requests[id]
		if request["status"] in ["open", "assigned"] and not request["responded"] and request["expire_t"] <= t and _active_promise(id).is_empty():
			request["status"] = "closed"
			_release_request_worker(id, true)
			_apply(request["data"]["expire_effects"], {"lot": request["data"]["lot"], "kind": "missed"})
			if request["data"].has("overlay"):
				var overlay: Dictionary = request["data"]["overlay"]
				_set_overlay(overlay["lot"], overlay["name"], false)
			request_changed.emit(id)
			state_changed.emit()


# Requests that can wait get worse while nobody answers: each step fires once,
# counted from when the request appeared. Working on it or a promise pauses it.
func _escalate_requests() -> void:
	for id in request_order:
		var request: Dictionary = requests[id]
		var steps: Array = request["data"].get("escalation", [])
		if request["status"] != "open" or request["responded"] or not _active_promise(id).is_empty():
			continue
		while request["escalated"] < steps.size():
			var next_step: Dictionary = steps[request["escalated"]]
			if to_hours(request["data"]["appear"]) + float(next_step["after"]) > t:
				break
			request["escalated"] += 1
			_apply(next_step["effects"], {"lot": request["data"]["lot"], "kind": "escalated"})
			request_changed.emit(id)


func _make_promise(request: Dictionary, promise: Dictionary) -> void:
	request["promised"] = true
	promises.append({
		"text": promise["text"], "due": to_hours(promise["due"]), "due_text": when_text(promise["due"]),
		"flag": promise["flag"], "kept": promise["kept"], "broken": promise["broken"], "status": "active",
		"request": request["data"]["id"],
	})
	_apply(promise["made"], {"lot": request["data"]["lot"], "kind": "promise"})
	request_changed.emit(request["data"]["id"])


func _check_promises() -> void:
	for promise in promises:
		if promise["status"] != "active":
			continue
		var lot: String = _request_lot(promise["request"])
		if flags.get(promise["flag"], false):
			promise["status"] = "kept"
			_apply(promise["kept"], {"lot": lot, "kind": "done"})
			promise_resolved.emit("kept")
		elif promise["due"] <= t:
			promise["status"] = "broken"
			_apply(promise["broken"], {"lot": lot, "kind": "missed"})
			promise_resolved.emit("broken")
			# The broken promise is the request's ending; it does not also expire.
			var request: Dictionary = requests[promise["request"]]
			if request["status"] == "open":
				request["status"] = "closed"
				request_changed.emit(promise["request"])


func _change_money(amount: int) -> void:
	if amount == 0:
		return
	money += amount
	money_changed.emit()


# `context` places a logged result in the week summary: {lot, kind} where kind
# is done, failed, missed, escalated or promise.
func _apply(effects: Dictionary, context: Dictionary = {}) -> void:
	for id in factions:
		if effects.has(id):
			factions[id] += effects[id]
	if effects.has("money"):
		_change_money(effects["money"])
	traces += effects.get("trace", 0)
	for key in effects.get("flags", {}):
		flags[key] = effects["flags"][key]
	for lot in effects.get("next_week", {}):
		next_week[lot] = effects["next_week"][lot]
	if effects.has("overlay"):
		_set_overlay(effects["overlay"]["lot"], effects["overlay"]["name"], true)
	if effects.has("overlay_off"):
		_set_overlay(effects["overlay_off"]["lot"], effects["overlay_off"]["name"], false)
	if effects.has("thread") and not threads.has(effects["thread"]):
		threads.append(effects["thread"])
	if effects.has("log"):
		# Tone follows how the factions took it: it colors the toast on screen.
		var mood := 0
		for id in factions:
			mood += effects.get(id, 0)
		_add_entry(effects["log"], "bad" if mood < 0 else ("good" if mood > 0 else "neutral"))
		var weight := 0
		for id in factions:
			weight += absi(effects.get(id, 0))
		weight += 10 * (int(effects.has("overlay")) + effects.get("trace", 0))
		outcomes.append({
			"text": effects["log"], "lot": context.get("lot", ""), "kind": context.get("kind", "done"),
			"weight": weight, "mood": mood,
		})
	state_changed.emit()


func _set_overlay(lot: String, overlay: String, visible: bool) -> void:
	_overlays[lot + ":" + overlay] = visible
	overlay_changed.emit(lot, overlay, visible)


# `kind`: "request" for a new request, "news" for consequences; `tone` is the
# mood of a news item (good, bad or neutral).
func _add_entry(text: String, tone: String = "request") -> void:
	var entry := {"time": clock_text(), "text": text, "tone": tone}
	entries.append(entry)
	entry_added.emit(entry)


# When an unanswered request closes. An explicit "expire" wins; otherwise the
# urgency class sets the window from the moment it appears.
func _expire_hours(data: Dictionary) -> float:
	if data.has("expire"):
		return to_hours(data["expire"])
	var appear := to_hours(data["appear"])
	var day: int = data["appear"]["day"]
	match data.get("urgency", "week"):
		"now":
			return appear + 3.0
		"today":
			return maxf(to_hours({"day": day, "hour": 20}), appear + 3.0)
		"days":
			return to_hours({"day": mini(day + 2, Week1.DAYS_PER_WEEK - 1), "hour": 20})
	return to_hours({"day": Week1.DAYS_PER_WEEK - 1, "hour": 20})


func _active_promise(request_id: String) -> Dictionary:
	for promise in promises:
		if promise["request"] == request_id and promise["status"] == "active":
			return promise
	return {}


func _request_lot(request_id: String) -> String:
	return requests[request_id]["data"]["lot"]


func _find_option(request: Dictionary, option_id: String) -> Dictionary:
	for option in request["data"]["options"]:
		if option["id"] == option_id:
			return option
	return {}
