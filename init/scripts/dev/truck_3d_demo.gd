# Freight asset viewer; shows the approved 20% truck reduction beside the unchanged Volga.
extends Node3D

const VehicleModels := preload("res://scripts/map/vehicle_models.gd")
const TRUCKS := [preload("res://assets/models/vehicles/truck_zil_food.glb"), preload("res://assets/models/vehicles/truck_zil_flatbed.glb"), preload("res://assets/models/vehicles/truck_kamaz_semi.glb")]
const VOLGA := preload("res://assets/models/vehicles/volga_gaz24.glb")
const MAP_FACTOR := 4.3 / 4.37
const NAMES := ["ZIL • Lebensmittelkoffer", "ZIL • Kohle und Plane", "KamAZ • Container"]

var _camera: Camera3D
var _cars: Node3D
var _variant := 0
var _yaw := 0.78
var _elevation := 0.49
var _dragging := false
var _info: Label
var _focus := Vector3(1.5, 1.8, 0)


func _ready() -> void:
	DisplayServer.window_set_title("Lkw — Modellansicht")
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("45515a")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("d2dce3")
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	for entry in [[Vector3(-40, -35, 0), 1.5], [Vector3(-28, 135, 0), 0.55]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = entry[0]
		light.light_energy = entry[1]
		light.shadow_enabled = true
		add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(140, 140)
	ground.mesh = plane
	ground.position.y = -0.02
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8a918b")
	material.roughness = 1.0
	ground.material_override = material
	add_child(ground)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.far = 400.0
	add_child(_camera)
	_camera.current = true
	_cars = Node3D.new()
	add_child(_cars)
	_build_ui()
	_show_truck(0)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--variant="):
			_show_truck(int(argument.trim_prefix("--variant=")))
		elif argument.begins_with("--capture="):
			_capture.call_deferred(argument.trim_prefix("--capture="))


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	canvas.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	var title := Label.new()
	title.text = "Lkw • 20 % kleiner im Vergleich zur Volga"
	title.add_theme_font_size_override("font_size", 21)
	box.add_child(title)
	_info = Label.new()
	box.add_child(_info)
	var controls := Label.new()
	controls.text = "Ziehen: drehen • Mausrad: Zoom"
	box.add_child(controls)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	for index in range(3):
		var button := Button.new()
		button.text = NAMES[index]
		button.pressed.connect(_show_truck.bind(index))
		buttons.add_child(button)
	var reset := Button.new()
	reset.text = "Ansicht zurücksetzen"
	reset.pressed.connect(func(): _show_truck(_variant))
	buttons.add_child(reset)


func _show_truck(index: int) -> void:
	_variant = clampi(index, 0, 2)
	for child in _cars.get_children():
		_cars.remove_child(child)
		child.queue_free()
	var truck: Node3D = TRUCKS[_variant].instantiate()
	truck.scale = Vector3.ONE * MAP_FACTOR * VehicleModels.TRUCK_VISUAL_SCALE
	_cars.add_child(truck)
	var volga: Node3D = VOLGA.instantiate()
	volga.scale = Vector3.ONE * MAP_FACTOR
	volga.position = Vector3(4.0, 0, 0)
	_cars.add_child(volga)
	_yaw = 0.78
	_elevation = 0.49
	_focus = Vector3(1.2, 1.4, 0)
	_camera.size = 15.0 if _variant == 2 else 9.0
	_info.text = NAMES[_variant] + " • Lkw −20 % / Volga unverändert"
	_update_camera()


func _update_camera() -> void:
	_camera.position = _focus + Vector3(sin(_yaw) * cos(_elevation), sin(_elevation), cos(_yaw) * cos(_elevation)) * 140.0
	_camera.look_at(_focus, Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.size = clampf(_camera.size * 0.9, 5.0, 100.0)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.size = clampf(_camera.size * 1.1, 5.0, 100.0)
	elif event is InputEventMouseMotion and _dragging:
		_yaw -= event.relative.x * 0.008
		_elevation = clampf(_elevation + event.relative.y * 0.006, 0.05, 1.45)
		_update_camera()


func _capture(path: String) -> void:
	for i in range(12):
		await RenderingServer.frame_post_draw
	var error := get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit(0 if error == OK else 1)
