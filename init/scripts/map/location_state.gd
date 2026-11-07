# A location's scheduled visual state, with an explicit event override.
# Consumers animate their own objects; this component owns no geometry.
extends Node

signal state_changed(state: StringName, animated: bool)

var state: StringName = &""
var scheduled_state: StringName = &""
var override_state: StringName = &""
var _clock: Callable
var _schedule: Dictionary = {}

func configure(clock: Callable, schedule: Dictionary) -> void:
	_clock = clock
	_schedule = schedule.duplicate()
	_refresh(false) # Loading a scene starts in the current pose, without a replay.

func _process(_delta: float) -> void:
	if _clock.is_valid():
		_refresh(true)

func set_override(value: StringName, animated := true) -> void:
	override_state = value
	_refresh(animated)

func clear_override(animated := true) -> void:
	override_state = &""
	_refresh(animated)

func _refresh(animated: bool) -> void:
	if _clock.is_valid() and not _schedule.is_empty():
		var hour := fposmod(float(_clock.call()),24.0)
		var opening: float = _schedule["open_at"]
		var closing: float = _schedule["close_at"]
		var operating := hour >= opening and hour < closing
		if opening > closing: # A schedule can also span midnight.
			operating = hour >= opening or hour < closing
		scheduled_state = _schedule["open_state"] if operating else _schedule["closed_state"]
	var next: StringName = override_state if override_state != &"" else scheduled_state
	if next == &"" or next == state:
		return
	state = next
	state_changed.emit(state,animated)
