# Focused normal-camera graphical review; no separate mockup scene.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._close_important_notice()
	main.hud._close_week_panel()
	main.map._debug_hour = 12.0
	main.map._camera_goal = Vector3(250,0,97)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 150.0
	main.map._update_camera()
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://../.local/church-ensemble/")
	root.get_texture().get_image().save_png(dir+"in-game-ensemble.png")
	var site: Node3D = main.map.get_node("ChurchEnsemble")
	print("Church actual doorstep: ",main.sim.graph.doorsteps.get("church"))
	print("Church actual entrance: ",main.sim.graph.entrance_position("church"))
	print("Church grounds: ",site.get_meta("grave_count")," graves; ",site.get_child_count()," root nodes")
	for id in ["church","parish_house","shed"]:
		print("Church asset ",id,": ",site.get_node(id).position," scale=",site.get_node(id).scale)
	quit()
