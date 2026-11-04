# Transient restaurant siting guide. Does not modify the playable project.
extends SceneTree

var site: Node3D

func material(color: String, metallic := 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	mat.roughness = 0.8
	mat.metallic = metallic
	return mat

func box(at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = at
	site.add_child(node)
	return node

func person(at: Vector3, mat: Material) -> void:
	box(at + Vector3(0, .8, 0), Vector3(.42, 1.15, .28), mat)
	box(at + Vector3(0, 1.55, 0), Vector3(.24, .26, .24), material("bba88e"))

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.8).timeout
	main.hud._continue_to_tasks()
	main.hud._close_week_panel()
	main.hud.hide()
	main.map._debug_hour = 12.0
	main.map._camera_goal = Vector3(91, 0, -1)
	main.map._camera_target = main.map._camera_goal
	main.map._zoom = 187.0
	main.map._update_camera()
	site = Node3D.new()
	site.name = "RestaurantTemporarySitingGuide"
	main.map.add_child(site)
	var wall := material("95836a")
	var paving := material("b4aa95")
	var road := material("555352")
	var roof := material("443d37")
	var plaster := material("c7b89d")
	var stone := material("624438")
	var glass := material("433f34", .15)
	var metal := material("383a36", .3)
	var marks := material("d5d1bb")
	# Entire confirmed city_park parcel: x82..136, z-72..12 (54 x 84 m).
	box(Vector3(109, .09, -30), Vector3(53.2, .16, 83.2), material("899466"))
	box(Vector3(109, 1.42, -71.6), Vector3(53.2, 2.8, .45), wall)
	box(Vector3(109, 1.42, 11.6), Vector3(53.2, 2.8, .45), wall)
	box(Vector3(82.4, 1.42, -30), Vector3(.45, 2.8, 83.2), wall)
	# East wall has an 8 m vehicle gate at z-8..0 and distinct pedestrian gate.
	box(Vector3(135.6, 1.42, -39.8), Vector3(.45, 2.8, 63.6), wall)
	box(Vector3(135.6, 1.42, 7.55), Vector3(.45, 2.8, 8.1), wall)
	box(Vector3(135.6, 1.42, 1), Vector3(.45, 2.8, 2), wall)
	box(Vector3(135.6, 1.32, 2.75), Vector3(.18, 2.6, 1.5), metal)
	for z in range(-70, 13, 6):
		if z > -9 and z < 5:
			continue
		box(Vector3(135.6, 1.58, z), Vector3(.75, 3.1, .75), wall)
		box(Vector3(82.4, 1.58, z), Vector3(.75, 3.1, .75), wall)
	# Paved guest court, village-street crossover, independent service approach.
	box(Vector3(111, .19, -11), Vector3(42, .18, 37), road)
	box(Vector3(139, .18, -4), Vector3(8, .12, 8), road)
	box(Vector3(89, .17, -37), Vector3(6, .14, 56), road)
	box(Vector3(102, .17, -64), Vector3(26, .14, 7), road)
	box(Vector3(119, .28, -41), Vector3(9, .3, 29), paving)
	# A's asymmetrical restaurant: front east; 18 m depth x 26 m frontage.
	box(Vector3(105, 3.2, -45), Vector3(16, 6.0, 18), stone)
	box(Vector3(113.06, 3.45, -45), Vector3(.15, 5.1, 16.4), glass)
	box(Vector3(105, 6.36, -45), Vector3(17.2, .35, 19.2), roof)
	box(Vector3(109, 4, -32), Vector3(12, 7.6, 8), plaster)
	box(Vector3(109, 1, -32), Vector3(12.1, 1.8, 8.1), stone)
	box(Vector3(109, 7.94, -32), Vector3(13.2, .3, 9.2), roof)
	box(Vector3(117, 3.2, -32), Vector3(4.4, .28, 6.6), metal)
	# Window groups and street-facing entrance.
	for z in [-33.6, -30.4]:
		box(Vector3(115.06, 5.5, z), Vector3(.18, 2.3, 2.2), glass)
	box(Vector3(115.1, 1.75, -32), Vector3(.2, 2.8, 2.8), glass)
	for z in range(-53, -36, 3):
		box(Vector3(113.18, 3.4, z), Vector3(.15, 5.3, .14), metal)
	# Guardhouse and barrier are inside the compound.
	box(Vector3(131, 1.65, 6), Vector3(4, 3.1, 4), plaster)
	box(Vector3(131, 3.3, 6), Vector3(4.7, .2, 4.7), roof)
	box(Vector3(131, 1.9, 3.96), Vector3(2.8, 1.2, .12), glass)
	box(Vector3(129.4, 1.15, -4), Vector3(.13, .13, 7.2), marks)
	box(Vector3(129.4, .6, .2), Vector3(.4, 1.2, .4), metal)
	person(Vector3(131, .2, .5), metal)
	person(Vector3(118, .3, -29.5), metal)
	# Guest parking: real shared Volgas establish scale, not fictional oversized cars.
	var cars = load("res://assets/models/vehicles/volga_gaz24.glb")
	for i in 7:
		var z := -17.0
		var x := 96.0 + i * 3.2
		for dx in [-1.4, 1.4]:
			box(Vector3(x + dx, .3, z), Vector3(.08, .025, 5.6), marks)
		if i % 2 == 0:
			var car = cars.instantiate()
			site.add_child(car)
			car.position = Vector3(x, .28, z)
			car.scale = Vector3.ONE * .90
	# Private garden/terrace at the rear and western edge, within the high wall.
	box(Vector3(104, .3, -59), Vector3(16, .4, 6), paving)
	for z in [-58.0, -60.0]:
		for x in [100.0, 105.0, 110.0]:
			box(Vector3(x, .9, z), Vector3(1.1, .12, 1.1), roof)
	await create_timer(1).timeout
	main.process_mode = Node.PROCESS_MODE_DISABLED
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://../.local/restaurant-site/")
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_texture().get_image().save_png(dir + "confirmed-parcel-guide.png")
	print("Restaurant guide: city_park x82..136 z-72..12, 54x84m; building x97..115 z-54..-28; entry east z-8..0")
	quit()
