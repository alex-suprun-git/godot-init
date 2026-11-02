extends Control

func _ready() -> void:
	label_at("GAZ-2705  /  EARLY PANEL VAN", Vector2(28, 12), 26)
	label_at("Reference-led body revision · white / muted blue / sand · same geometry, camera and lighting", Vector2(28, 49), 17)
	var front := viewport_at(Rect2(0, 80, 533, 420), 5.9, Vector3(8, 5, 11))
	add_vehicle(front, "gazelle_2705", Vector3.ZERO, 0.0)
	var blue := viewport_at(Rect2(533, 80, 534, 420), 5.9, Vector3(8, 5, 11))
	add_vehicle(blue, "gazelle_2705_blue", Vector3.ZERO, 0.0)
	var sand := viewport_at(Rect2(1067, 80, 533, 420), 5.9, Vector3(8, 5, 11))
	add_vehicle(sand, "gazelle_2705_sand", Vector3.ZERO, 0.0)
	label_at("SHARED SCALE  /  Gazelle 85% x 95% x 103% = 83.1725% · all three paints enlarged 3%", Vector2(24, 512), 19)
	var lineup := viewport_at(Rect2(0, 550, 1600, 340), 12.5, Vector3(12, 13, 22))
	add_vehicle(lineup,"volga_gaz24",Vector3(-13,0,0),PI/2,0.90*4.3/4.37)
	add_vehicle(lineup,"gazelle_2705",Vector3(-6.5,0,0),PI/2)
	add_vehicle(lineup,"gazelle_2705_blue",Vector3(0,0,0),PI/2)
	add_vehicle(lineup,"gazelle_2705_sand",Vector3(6.5,0,0),PI/2)
	add_vehicle(lineup,"truck_zil_flatbed",Vector3(13,0,0),PI/2,1.05*0.80*4.3/4.37)
	label_at("MAP PIXEL DENSITY  /  iso 45° · 35.264° · default zoom equivalent; Volga / three van paints / ZIL",Vector2(24,902),18)
	var map := viewport_at(Rect2(0, 935, 1600, 125), 125.0*(350.0*0.573)/900.0, Vector3(30,30,30))
	add_vehicle(map,"volga_gaz24",Vector3(-12,0,12),PI/2,0.90*4.3/4.37)
	add_vehicle(map,"gazelle_2705",Vector3(-6,0,6),PI/2)
	add_vehicle(map,"gazelle_2705_blue",Vector3.ZERO,PI/2)
	add_vehicle(map,"gazelle_2705_sand",Vector3(6,0,-6),PI/2)
	add_vehicle(map,"truck_zil_flatbed",Vector3(12,0,-12),PI/2,1.05*0.80*4.3/4.37)
	label_at("Isolated Godot asset preview. Shared city files remain untouched; placement and traffic integration are pending.",Vector2(24,1070),16)
	for frame in range(18):await RenderingServer.frame_post_draw
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var path := arg.trim_prefix("--capture=")
			var err := get_viewport().get_texture().get_image().save_png(path)
			print("PREVIEW_CAPTURE ",path," ",error_string(err))
			get_tree().quit(0 if err==OK else 1)

func add_vehicle(world: Node3D, file: String, pos: Vector3, yaw: float, scale_factor: float=1.0) -> Node3D:
	var model := (load("res://models/%s.glb" % file) as PackedScene).instantiate() as Node3D
	world.add_child(model)
	model.position=pos
	model.rotation.y=yaw
	model.scale*=scale_factor
	return model

func label_at(text: String, pos: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text=text
	label.position=pos
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("d9e0dc"))
	add_child(label)

func viewport_at(rect: Rect2, camera_size: float, eye: Vector3) -> Node3D:
	var holder := SubViewportContainer.new()
	holder.position=rect.position
	holder.size=rect.size
	add_child(holder)
	var vp := SubViewport.new()
	vp.size=Vector2i(rect.size)
	vp.own_world_3d=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	vp.msaa_3d=Viewport.MSAA_4X
	holder.add_child(vp)
	var world := Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("384446")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("c9d7dc")
	env.ambient_light_energy=0.65
	var we := WorldEnvironment.new()
	we.environment=env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-32,0)
	sun.light_energy=1.3
	sun.light_color=Color("fff1d8")
	sun.shadow_enabled=true
	world.add_child(sun)
	var plane := MeshInstance3D.new()
	var geo := PlaneMesh.new()
	geo.size=Vector2(160,160)
	plane.mesh=geo
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color("515d57")
	mat.roughness=0.95
	plane.material_override=mat
	plane.position.y=-0.006
	world.add_child(plane)
	var cam := Camera3D.new()
	world.add_child(cam)
	cam.projection=Camera3D.PROJECTION_ORTHOGONAL
	cam.size=camera_size
	cam.position=eye
	cam.look_at(Vector3(0,.9,0))
	cam.current=true
	return world
