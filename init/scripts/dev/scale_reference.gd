# Manual visual reference. Open scenes/dev/scale_reference.tscn and press F6.
# Optional: --shots=/absolute/directory saves a frame and exits.
extends Node3D

const CityMap = preload("res://scripts/map/city_map.gd")


func _ready() -> void:
	var map := CityMap.new()
	add_child(map)
	map.set_process_unhandled_input(false)
	map._box(Vector3(70, 0.2, 45), Vector3(0,-0.12,0), Color(0.42,0.45,0.39))
	for x in range(-30,31):
		map._box(Vector3(0.02,0.01,40), Vector3(x,0,0), Color(0.29,0.32,0.28))
	for z in range(-20,21):
		map._box(Vector3(60,0.01,0.02), Vector3(0,0,z), Color(0.29,0.32,0.28))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 29
	camera.position = Vector3(35,35,32)
	add_child(camera)
	camera.look_at(Vector3(0,0,-3))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-30,0)
	sun.light_energy = 1.1
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.34,0.38,0.38)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var garage := map._garage_model.create(CityMap.GARAGE_SINGLE, Color.WHITE)
	garage.position = Vector3(-8,0,0)
	map.add_child(garage)
	map._prop(CityMap.CAR_LADA, Vector3(-2,0,3), 4.3, "x")
	map._prop(CityMap.CAR_VOLGA, Vector3(5,0,3), 5.0, "x")
	map._sprite(CityMap.PEOPLE[0]["texture"], Vector3(-3,0,6), CityMap.PEOPLE[0]["width"])
	map._sprite(CityMap.PEOPLE[4]["texture"], Vector3(-1,0,6), CityMap.PEOPLE[4]["width"])
	map._box(Vector3(0.06,1.8,0.06), Vector3(-3.7,0.9,6), Color(0.3,0.9,0.5))
	for offset in [-0.55,0.55]:
		map._box(Vector3(0.08,2.2,0.08), Vector3(-6 + offset,1.1,6), Color(0.9,0.85,0.65))
	map._box(Vector3(1.18,0.08,0.08), Vector3(-6,2.2,6), Color(0.9,0.85,0.65))
	map._grounded_prop(CityMap.MARKET_TENT, Vector3(3,0,-7), 5.6, true, Vector2(0.843,-0.366))
	map._prop(CityMap.BUS_STOP, Vector3(-8,0,-10), 6.5, "z")
	map._prop(CityMap.BUS_LIAZ, Vector3(11,0,-5), 9, "z")
	_label("Гараж: 3,2 × 6 м", Vector3(-8,3.5,0))
	_label("Лада", Vector3(-2,3,3))
	_label("Волга", Vector3(5,3,3))
	_label("1,8 м / ребёнок 1,4 м", Vector3(-2,1,8))
	_label("Дверь 2,2 м", Vector3(-6,2.8,6))
	_label("Палатка", Vector3(3,4.5,-7))
	_label("Остановка", Vector3(-8,5,-10))
	_label("Автобус", Vector3(11,5,-5))
	_label("Сетка: 1 × 1 м", Vector3(10,1,10))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			await get_tree().create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.substr(8).path_join("scale_reference.png"))
			get_tree().quit()


func _label(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 40
	label.pixel_size = 0.01
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
