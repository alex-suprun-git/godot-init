# Lightweight UI transitions, independent of simulation speed and pause.
extends RefCounted


static func reveal(control: Control, duration: float = 0.16) -> void:
	if control.has_meta("reveal_tween"):
		var previous: Tween = control.get_meta("reveal_tween")
		if previous != null and previous.is_valid():
			previous.kill()
	control.modulate.a = 0
	var tween := control.create_tween().set_ignore_time_scale(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	control.set_meta("reveal_tween", tween)
