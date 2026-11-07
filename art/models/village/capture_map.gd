# Normal game/camera review of the assembled village, without replaying the week.
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
	main.map._camera_goal = preload("res://scripts/data/village_geometry.gd").point3(Vector3(270,0,75))
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 370.0
	main.map._update_camera()
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://../.local/village-rebuild/")
	root.get_texture().get_image().save_png(dir+"in-game-village.png")
	if OS.get_cmdline_user_args().has("--exit"):
		main.map._camera_goal = Vector3(278,0,265)
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = 370.0
		main.map._update_camera()
		await create_timer(.6).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(dir+"south-exit.png")
	if OS.get_cmdline_user_args().has("--materials"):
		main.map._camera_goal = preload("res://scripts/data/village_geometry.gd").point3(Vector3(225,0,75))
		main.map._camera_target = main.map._camera_goal
		main.map._zoom = 280.0
		main.map._update_camera()
		for hour in [8.0,12.0]:
			main.map._debug_hour = hour
			await create_timer(.6).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dir+"materials-%02d.png"%int(hour))
	var families := {}
	var sites := get_nodes_in_group("village_homesteads")
	for site in sites:
		var family: String = site.get_meta("family")
		families[family] = families.get(family,0)+1
		print("Village site ",site.name," scale=",site.scale," position=",site.position)
	var old_sprites := 0
	var shared_surfaces := 0
	var outside_parcel := 0
	for site in sites:
		var id: String = str(site.name).trim_prefix("Homestead_")
		var record: Dictionary = preload("res://scripts/data/village_sites.gd").all()[id]
		for mesh in site.find_children("*","MeshInstance3D",true,false):
			if str(mesh.name).begins_with("ParcelGeometry"):
				var box: AABB = (site.global_transform.affine_inverse()*mesh.global_transform)*mesh.get_aabb()
				if box.position.x < -record["frontage"]/2.0-.03 or box.end.x > record["frontage"]/2.0+.03 or box.position.z < -record["depth"]/2.0-.03 or box.end.z > record["depth"]/2.0+.03:
					outside_parcel += 1
					print("Parcel clearance issue ",id,": ",box)
			for i in mesh.mesh.get_surface_count():
				var material = mesh.mesh.surface_get_material(i)
				if material != null and material.resource_path.begins_with("res://assets/materials/village/"):
					shared_surfaces += 1
	for sprite in main.map.find_children("*","Sprite3D",true,false):
		if sprite.texture != null and "village_" in sprite.texture.resource_path:
			old_sprites += 1
	print("Village whole prefabs: ",sites.size(),"; families=",families,"; legacy residential sprites=",old_sprites)
	print("Village imported shared surfaces=",shared_surfaces,"; prefab geometry outside parcels=",outside_parcel)
	for id in ["d_05","d_06","d_13","d_16"]:
		print("Village planned access ",id,": ",preload("res://scripts/data/village_sites.gd").point(id,"entrance")," -> ",preload("res://scripts/data/village_sites.gd").point(id,"doorstep"),"; active quest location=",main.sim.graph.has_entrance(id))
	quit()
