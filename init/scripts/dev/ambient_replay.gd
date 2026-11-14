# Dev tool: replays the ambient traffic simulation with fixed 0.05 s steps and prints a hash of
# every agent's pose at checkpoints. Run it before and after an optimization of ambient_life.gd:
# identical output means the simulation behaves identically. Also prints the time per step.
# --fixed-fps makes the frames before the replay deterministic; without it two runs differ.
#   Godot --headless --fixed-fps 20 --path init --script res://scripts/dev/ambient_replay.gd -- --no-log
extends SceneTree

const STEPS := 6000
const CHECKPOINT := 1000


func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	for i in 20:
		await process_frame
	var map = main.map
	map.set_process(false)
	map._debug_hour = 12.0
	var ambient = map._ambient
	ambient._hour_override = 12.0
	var started := Time.get_ticks_usec()
	for step in STEPS:
		ambient.step(0.05)
		if (step + 1) % CHECKPOINT == 0:
			print("replay step %d hash %d" % [step + 1, _pose_hash(ambient)])
	var elapsed := (Time.get_ticks_usec() - started) / 1000.0
	print("replay: %d steps, %.2f ms per step" % [STEPS, elapsed / STEPS])
	quit()


func _pose_hash(ambient) -> int:
	var h := 17
	for agent in ambient.agents:
		var at: Vector2 = agent["pos"]
		h = hash([h, snappedf(at.x, 0.001), snappedf(at.y, 0.001), agent["visible"], agent["state"]])
	return h
