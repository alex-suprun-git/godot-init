# Continuous opt-in profiling of existing autoplay scenarios, without screenshot I/O.
# Records every rendered frame; writes reports only after disconnecting the sampler.
extends Node

var scenario := "startup_settle"
var _main
var _folder: String
var _rid: RID
var _previous: int
var _started: int
var _vsync: int
var _cap: int
var _frames: Array = []
var _was_profiling: bool


func start(main, output_dir: String) -> void:
	_main = main
	_folder = output_dir if output_dir != "" else "user://performance"
	DirAccess.make_dir_recursive_absolute(_folder)
	_rid = get_viewport().get_viewport_rid()
	_vsync = DisplayServer.window_get_vsync_mode()
	_cap = Engine.max_fps
	_was_profiling = main.map.profile_ambient
	main.map.profile_ambient = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	RenderingServer.viewport_set_measure_render_time(_rid, true)
	_started = Time.get_ticks_usec()
	_previous = _started
	RenderingServer.frame_post_draw.connect(_sample)


func _sample() -> void:
	var now := Time.get_ticks_usec()
	var map = _main.map
	var label := "%s/%s/day%d/x%s%s" % [scenario, _main.phase, _main.sim.day_index() + 1, _main.speed, "/night" if _main._night else ""]
	_frames.append([(now - _started) / 1000000.0, label, (now - _previous) / 1000.0,
		map.profile_step_ms, map.profile_visual_ms,
		RenderingServer.viewport_get_measured_render_time_cpu(_rid),
		RenderingServer.viewport_get_measured_render_time_gpu(_rid),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		map._zoom, map._camera_target.x, map._camera_target.z, _main.sim.clock_hour()])
	_previous = now


func finish() -> void:
	RenderingServer.frame_post_draw.disconnect(_sample)
	_main.map.profile_ambient = _was_profiling
	DisplayServer.window_set_vsync_mode(_vsync)
	Engine.max_fps = _cap
	RenderingServer.viewport_set_measure_render_time(_rid, false)
	var groups := {}
	for frame in _frames:
		if not groups.has(frame[1]):
			groups[frame[1]] = []
		groups[frame[1]].append(frame)
	var rows := {}
	for label in groups:
		rows[label] = _summarize(groups[label])
	var slow: Array = _frames.filter(func(f): return f[2] > 33.333)
	var report := {"engine": Engine.get_version_info(), "cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"viewport": str(get_viewport().get_visible_rect().size), "season": _main.Settings.season,
		"window_pixels": str(DisplayServer.window_get_size()),
		"render_target_pixels": str(get_viewport().get_texture().get_size()),
		"camera": _main.Settings.camera_mode, "overall": _summarize(_frames), "groups": rows,
		"frames_over_33ms": slow,
		"notes": "Normal engine time, uncapped FPS, VSync off; no screenshots. Week autoplay uses the game's x4 speed. Frame CSV includes every measured frame, including transitions and first camera traversal; excludes scene construction before autoplay. GPU times are asynchronous; CPU/GPU metrics must not be summed. Group labels describe state at sample end. Short groups are not stable benchmarks."}
	var json_file := FileAccess.open(_folder.path_join("session-profile.json"), FileAccess.WRITE)
	var csv_file := FileAccess.open(_folder.path_join("session-frames.csv"), FileAccess.WRITE)
	if json_file == null or csv_file == null:
		push_error("Cannot write session profile to " + _folder)
		return
	json_file.store_string(JSON.stringify(report, "\t"))
	json_file.close()
	csv_file.store_line("seconds,label,frame_ms,ambient_step_ms,ambient_visual_ms,render_cpu_ms,render_gpu_ms,draw_calls,primitives,zoom,camera_x,camera_z,game_hour")
	for frame in _frames:
		var fields := PackedStringArray()
		for value in frame:
			fields.append(str(value))
		csv_file.store_csv_line(fields)
	csv_file.close()
	print("session profile: ", JSON.stringify(report.overall), " -> ", ProjectSettings.globalize_path(_folder))


func _summarize(frames: Array) -> Dictionary:
	if frames.is_empty():
		return {}
	var result := {"frames": frames.size(), "metrics": {}}
	var names := ["frame_ms", "ambient_step_ms", "ambient_visual_ms", "render_cpu_ms", "render_gpu_ms", "draw_calls", "primitives"]
	for index in names.size():
		var values: Array = frames.map(func(f): return f[index + 2])
		values.sort()
		var total := 0.0
		for value in values:
			total += float(value)
		result.metrics[names[index]] = {"mean": total / values.size(), "p95": values[int(ceil(values.size() * .95)) - 1], "p99": values[int(ceil(values.size() * .99)) - 1], "max": values.back()}
	result["fps"] = 1000.0 / float(result.metrics.frame_ms.mean)
	result["seconds"] = float(result.metrics.frame_ms.mean) * frames.size() / 1000.0
	for threshold in [16.667, 33.333, 50.0, 100.0]:
		result["over_%sms_count" % threshold] = frames.filter(func(f): return f[2] > threshold).size()
	return result
