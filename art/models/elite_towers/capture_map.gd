# Focused live-map review of facade placement and the optional material response.
extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	main.map._debug_hour = 12.0
	main.map._camera_goal = Vector3(20, 0, 50)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 320.0
	await create_timer(1.0).timeout
	main.process_mode = Node.PROCESS_MODE_DISABLED
	await RenderingServer.frame_post_draw
	var overview_transform: Transform3D = main.map.camera.global_transform
	var overview_size: float = main.map.camera.size
	var overview_offset: float = main.map.camera.v_offset
	var output := ProjectSettings.globalize_path("res://../.local/civic-facades/map-detail.png")
	root.get_texture().get_image().save_png(output)
	print("Civic facade frame: ", output)
	main.map._camera_goal = Vector3(-15, 0, -60)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 230.0
	main.map._update_camera()
	await _settle_render()
	output = ProjectSettings.globalize_path("res://../.local/civic-facades/map-north.png")
	root.get_texture().get_image().save_png(output)
	print("Civic north/roof frame: ", output)
	main.map._camera_goal = Vector3(20, 0, 50)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 320.0
	main.map._update_camera()
	main.map.camera.global_transform = overview_transform
	main.map.camera.size = overview_size
	main.map.camera.v_offset = overview_offset
	# Same camera and lighting; only the new roughness response is disabled.
	for material in main.map._window_materials:
		material.set_shader_parameter("surface_detail", false)
		material.set_shader_parameter("seam_blend", Vector2.ZERO)
	_disable_roof_detail(main.map)
	await _settle_render()
	output = ProjectSettings.globalize_path("res://../.local/civic-facades/map-baseline.png")
	root.get_texture().get_image().save_png(output)
	print("Civic facade baseline: ", output)
	quit()


func _settle_render() -> void:
	for frame in 3:
		await process_frame
		await RenderingServer.frame_post_draw


func _disable_roof_detail(node: Node) -> void:
	if node is MeshInstance3D and node.material_override is ShaderMaterial:
		var material: ShaderMaterial = node.material_override
		if material.shader.resource_path.ends_with("roof_felt.gdshader"):
			material.set_shader_parameter("surface_detail", false)
	for child in node.get_children():
		_disable_roof_detail(child)
