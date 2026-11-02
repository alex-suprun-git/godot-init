# Uses the ER2 review world's lighting, orbit controls and capture mechanism.
extends "res://scripts/dev/er2_3d_demo.gd"

const LOCOMOTIVE := preload("res://assets/models/vehicles/m62_locomotive.glb")
const TRUCK := preload("res://assets/models/vehicles/truck_kamaz_semi.glb")
const Vehicles := preload("res://scripts/map/vehicle_models.gd")
const Freight := preload("res://scripts/map/freight_train.gd")

var _initial_view := true


func _ready() -> void:
	super._ready()
	DisplayServer.window_set_title("Тепловоз — сравнение с ЭР2, грузовиком и Волгой")


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	canvas.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	margin.add_child(box)
	_info = Label.new()
	box.add_child(_info)
	var controls := Label.new()
	controls.text = "Перетаскивание — вращение • колесо — приближение"
	box.add_child(controls)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	for comparison in [true, false]:
		var button := Button.new()
		button.text = "Сравнить с ЭР2" if comparison else "Только тепловоз"
		button.pressed.connect(_show_consist.bind(comparison))
		buttons.add_child(button)
	var freight_button := Button.new()
	freight_button.text = "Тепловоз + 8 платформ"
	freight_button.pressed.connect(_show_freight)
	buttons.add_child(freight_button)


func _add_model(resource: PackedScene, x: float, z: float, factor: float, caption: String, label_offset := 11.5) -> void:
	var model := resource.instantiate() as Node3D
	model.position = Vector3(x, 0, z)
	model.scale = Vector3.ONE * factor
	# Same portable vertex-color interpretation as the ER2 import hook.
	_apply_colors(model)
	_cars.add_child(model)
	var label := Label3D.new()
	label.text = caption
	label.position = Vector3(x, 0.1, z + label_offset)
	label.font_size = 38
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	_cars.add_child(label)


func _apply_colors(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var base: Material = node.mesh.surface_get_material(surface)
			if base is BaseMaterial3D:
				var material: BaseMaterial3D = base.duplicate()
				material.vertex_color_use_as_albedo = true
				material.vertex_color_is_srgb = false
				node.set_surface_override_material(surface, material)
	for child in node.get_children():
		_apply_colors(child)


func _show_consist(comparison: bool) -> void:
	if _initial_view:
		if OS.get_cmdline_user_args().has("--freight"):
			_initial_view = false
			_show_freight()
			return
		comparison = not OS.get_cmdline_user_args().has("--solo")
		_initial_view = false
	_full_consist = comparison
	for child in _cars.get_children():
		_cars.remove_child(child)
		child.queue_free()
	_add_model(LOCOMOTIVE, -3.5 if comparison else 0.0, 0.0, MAP_FACTOR, "Тепловоз")
	if comparison:
		_add_model(HEAD, 3.5, 0.0, MAP_FACTOR, "ЭР2 · головной")
		_add_model(MOTOR, 10.5, 0.0, MAP_FACTOR, "ЭР2 · моторный")
		_add_model(TRUCK, -10.5, -3.0, MAP_FACTOR * Vehicles.TRUCK_VISUAL_SCALE, "КамАЗ", 8.0)
		_add_model(VOLGA, -10.5, 7.0, MAP_FACTOR, "Волга", 3.0)
	_yaw = 0.78
	_elevation = 0.54
	_focus = Vector3(0, 1.7, 0)
	_camera.size = 27.0 if comparison else 15.0
	_info.text = "Тепловоз • короче и уже вагона ЭР2\nКрыша чуть выше крыши ЭР2, ниже пантографа"
	_update_camera()


func _show_freight() -> void:
	for child in _cars.get_children():
		_cars.remove_child(child)
		child.queue_free()
	_cars.add_child(Freight.create())
	_yaw = 0.78
	_elevation = 0.54
	_focus = Vector3(0, 1.7, 0)
	_camera.size = 78.0
	_info.text = "Тепловоз + 8 контейнерных платформ • ≈ %.1f м\nКирпичный · сине-серый · оливковый" % Freight.TOTAL_LENGTH
	_update_camera()
