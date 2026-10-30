# The 3D micro-district. Builds a placeholder city from simple shapes, shows
# lot states and overlays, and moves people tokens to the positions in the sim.
# Shapes get painted facade textures later; the sim never sees any of this.
extends Node3D

const Week1 = preload("res://scripts/data/week1.gd")

const GRASS := Color(0.42, 0.47, 0.29)
const ASPHALT := Color(0.24, 0.25, 0.26)
const PANEL := Color(0.66, 0.65, 0.61)
const PANEL_ROOF := Color(0.38, 0.38, 0.37)
const BRICK := Color(0.55, 0.27, 0.19)
const PLASTER := Color(0.82, 0.77, 0.65)
const WINDOW := Color(0.16, 0.18, 0.2)
const FOLIAGE := [Color(0.33, 0.45, 0.2), Color(0.4, 0.5, 0.22), Color(0.55, 0.55, 0.2), Color(0.72, 0.6, 0.2)]

var sim
var camera: Camera3D
var _tokens := {} # actor id -> Node3D
var _overlays := {} # "lot:name" -> Node3D
var _lot_states := {} # lot -> {state -> Node3D}
var _materials := {}
var _rng := RandomNumberGenerator.new()


func setup(week_sim) -> void:
	sim = week_sim
	_rng.seed = 7
	_build_environment()
	_build_ground()
	_build_lots()
	_build_background_blocks()
	_build_trees()
	_build_tokens()
	sim.overlay_changed.connect(_on_overlay_changed)
	sim.lot_state_changed.connect(_on_lot_state_changed)


func _process(_delta: float) -> void:
	if sim == null:
		return
	# Spread tokens that share a spot side by side so faces never overlap.
	var groups := {}
	for id in _tokens:
		var pos: Vector2 = sim.actors[id]["pos"]
		var key := Vector2i(roundi(pos.x), roundi(pos.y))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(id)
	for key in groups:
		var ids: Array = groups[key]
		for i in ids.size():
			var pos: Vector2 = sim.actors[ids[i]]["pos"]
			var spread := (i - (ids.size() - 1) / 2.0) * 7.5
			var token: Node3D = _tokens[ids[i]]
			token.position = token.position.lerp(Vector3(pos.x + spread, 0.0, pos.y + 6.0), 0.35)


# Screen position of a lot marker; the HUD places buttons there.
func lot_screen_position(lot: String, height: float = 16.0) -> Vector2:
	var pos: Vector2 = Week1.LOTS[lot]["pos"]
	return camera.unproject_position(Vector3(pos.x, height, pos.y))


# --- Environment -------------------------------------------------------------

func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.45, 0.55, 0.68)
	sky_material.sky_horizon_color = Color(0.78, 0.74, 0.66)
	sky_material.ground_horizon_color = Color(0.6, 0.56, 0.48)
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 2.5
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.82, 0.76, 0.66)
	environment.fog_density = 0.0006
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.0
	environment.adjustment_contrast = 1.1

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	# Late August afternoon: warm, low-ish sun from the south-west.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.88, 0.72)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 400.0
	add_child(sun)

	camera = Camera3D.new()
	# Frames the whole micro-district in the area left of the right panel.
	camera.fov = 32.0
	camera.position = Vector3(-8.0, 190.0, 170.0)
	camera.h_offset = 26.0
	camera.v_offset = -10.0
	add_child(camera)
	camera.look_at(Vector3(-8.0, 0.0, 4.0))


func _build_ground() -> void:
	_box(Vector3(320, 1, 240), Vector3(0, -0.5, 0), GRASS)
	# River along the north edge, with the border bank beyond it.
	_box(Vector3(320, 1, 16), Vector3(0, -0.35, -52), Color(0.24, 0.36, 0.42))
	_box(Vector3(320, 0.6, 2), Vector3(0, -0.1, -43), Color(0.5, 0.5, 0.48))
	_box(Vector3(320, 0.6, 2), Vector3(0, -0.1, -61), Color(0.5, 0.5, 0.48))
	_box(Vector3(320, 1, 60), Vector3(0, -0.45, -92), Color(0.47, 0.5, 0.33))
	# Roads.
	_box(Vector3(320, 0.2, 8), Vector3(0, 0.05, -6), ASPHALT)
	_box(Vector3(8, 0.2, 160), Vector3(14, 0.06, 30), ASPHALT)
	_box(Vector3(220, 0.2, 6), Vector3(-30, 0.05, 28), ASPHALT)
	_box(Vector3(6, 0.2, 30), Vector3(-52, 0.06, 10), ASPHALT)
	# Bridge to the border checkpoint.
	_box(Vector3(9, 1.2, 24), Vector3(24, 0.9, -52), Color(0.55, 0.55, 0.53))
	_box(Vector3(8, 0.2, 22), Vector3(24, 0.05, -32), ASPHALT)
	_box(Vector3(5, 3.5, 4), Vector3(18, 1.75, -68), Color(0.85, 0.85, 0.8))
	_box(Vector3(14, 0.4, 0.6), Vector3(24, 1.6, -66), Color(0.8, 0.25, 0.2))
	for corner in [Vector2(-1.6, -1.6), Vector2(1.6, -1.6), Vector2(-1.6, 1.6), Vector2(1.6, 1.6)]:
		_box(Vector3(0.4, 12, 0.4), Vector3(34 + corner.x, 6, -70 + corner.y), Color(0.3, 0.3, 0.3))
	_box(Vector3(5, 3, 5), Vector3(34, 13.5, -70), Color(0.35, 0.38, 0.33))


# --- Lots --------------------------------------------------------------------

func _build_lots() -> void:
	_build_office(Week1.LOTS["office"]["pos"])
	_build_block5(Week1.LOTS["block5"]["pos"])
	_build_boiler(Week1.LOTS["boiler"]["pos"])
	_build_depot(Week1.LOTS["depot"]["pos"])
	_build_church(Week1.LOTS["church"]["pos"])
	_build_market(Week1.LOTS["market"]["pos"])
	_build_wasteland(Week1.LOTS["wasteland"]["pos"])
	_build_overlays()


func _build_office(at: Vector2) -> void:
	var base := Vector3(at.x, 0, at.y)
	_box(Vector3(22, 10, 12), base + Vector3(0, 5, -2), PLASTER)
	_box(Vector3(23, 0.8, 13), base + Vector3(0, 10.4, -2), Color(0.5, 0.48, 0.44))
	_box(Vector3(10, 7, 3), base + Vector3(0, 3.5, 5), PLASTER)
	for i in 5:
		_cylinder(0.5, 7, base + Vector3(-4 + i * 2, 3.5, 6.8), Color(0.9, 0.87, 0.8))
	_windows(base + Vector3(0, 0, -2), Vector2(22, 12), 3, 8, 2.6)
	_cylinder(0.15, 12, base + Vector3(9, 6, 6), Color(0.3, 0.3, 0.3))
	_box(Vector3(2.4, 1.4, 0.1), base + Vector3(10.2, 11, 6), Color(0.7, 0.2, 0.18))
	# The administration's black Volga.
	_box(Vector3(4.6, 1.4, 1.9), base + Vector3(-8, 0.9, 9), Color(0.08, 0.08, 0.09))


func _build_block5(at: Vector2) -> void:
	var base := Vector3(at.x, 0, at.y)
	_panel_block(base + Vector3(0, 0, -4), 40, 5)
	# Courtyard: benches, playground, laundry.
	_box(Vector3(3, 0.6, 0.8), base + Vector3(-8, 0.3, 5), Color(0.35, 0.5, 0.3))
	_box(Vector3(3, 0.6, 0.8), base + Vector3(8, 0.3, 5), Color(0.35, 0.5, 0.3))
	_box(Vector3(0.3, 3, 0.3), base + Vector3(-2, 1.5, 8), Color(0.7, 0.2, 0.2))
	_box(Vector3(0.3, 3, 0.3), base + Vector3(2, 1.5, 8), Color(0.2, 0.4, 0.7))
	_box(Vector3(4.3, 0.2, 0.2), base + Vector3(0, 3, 8), Color(0.6, 0.6, 0.2))


func _build_boiler(at: Vector2) -> void:
	var base := Vector3(at.x, 0, at.y)
	_box(Vector3(20, 9, 12), base + Vector3(0, 4.5, 0), BRICK)
	_box(Vector3(21, 0.6, 13), base + Vector3(0, 9.3, 0), Color(0.3, 0.3, 0.3))
	_windows(base, Vector2(20, 12), 1, 5, 4.0)
	_cylinder(1.6, 32, base + Vector3(12, 16, -4), Color(0.5, 0.25, 0.18))
	var coal := _sphere(4.0, base + Vector3(-14, 0.4, 4), Color(0.1, 0.1, 0.11))
	coal.scale = Vector3(1.2, 0.35, 1.0)

	# States: broken has nothing extra; repairing adds scaffolding and a fence;
	# working adds smoke from the chimney.
	var repairing := Node3D.new()
	add_child(repairing)
	for i in 7:
		_box(Vector3(0.3, 11, 0.3), base + Vector3(-9 + i * 3, 5.5, 7.2), Color(0.55, 0.42, 0.25), repairing)
	for level in 3:
		_box(Vector3(19, 0.3, 1.4), base + Vector3(0, 3 + level * 3.5, 7.2), Color(0.6, 0.47, 0.28), repairing)
	_box(Vector3(26, 2, 0.2), base + Vector3(0, 1, 11), Color(0.85, 0.5, 0.2), repairing)
	_box(Vector3(5, 2.2, 2.2), base + Vector3(-15, 1.1, 8), Color(0.85, 0.65, 0.15), repairing)
	repairing.visible = false

	var working := Node3D.new()
	add_child(working)
	var smoke := CPUParticles3D.new()
	smoke.position = base + Vector3(12, 32.5, -4)
	smoke.amount = 40
	smoke.lifetime = 6.0
	smoke.direction = Vector3(0.3, 1, 0)
	smoke.spread = 12.0
	smoke.initial_velocity_min = 2.0
	smoke.initial_velocity_max = 3.0
	smoke.gravity = Vector3(0.6, 0.4, 0)
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 4.0
	var puff := SphereMesh.new()
	puff.radius = 0.6
	puff.height = 1.2
	puff.material = _material(Color(0.85, 0.85, 0.85, 0.5))
	smoke.mesh = puff
	working.add_child(smoke)
	working.visible = false

	_lot_states["boiler"] = {"repairing": repairing, "working": working}


func _build_depot(at: Vector2) -> void:
	var base := Vector3(at.x, 0, at.y)
	for i in 3:
		_cylinder(4.2, 7, base + Vector3(-10 + i * 10, 3.5, -4), Color(0.72, 0.73, 0.72))
	_box(Vector3(14, 6, 7), base + Vector3(4, 3, 8), BRICK)
	_box(Vector3(14.6, 0.5, 7.6), base + Vector3(4, 6.2, 8), Color(0.4, 0.33, 0.28))
	_box(Vector3(36, 2.2, 0.2), base + Vector3(0, 1.1, 13), Color(0.4, 0.42, 0.4))
	_box(Vector3(2.2, 2.6, 2.2), base + Vector3(-14, 1.3, 13.5), Color(0.75, 0.75, 0.7))
	_box(Vector3(7, 2.6, 2.4), base + Vector3(-6, 1.3, 16.5), Color(0.6, 0.55, 0.2))


func _build_church(at: Vector2) -> void:
	var base := Vector3(at.x, 0, at.y)
	_box(Vector3(10, 9, 14), base + Vector3(0, 4.5, 0), Color(0.93, 0.9, 0.84))
	_box(Vector3(6, 6, 5), base + Vector3(0, 3, 9), Color(0.93, 0.9, 0.84))
	_cylinder(3.0, 4, base + Vector3(0, 11, 0), Color(0.93, 0.9, 0.84))
	var dome := _sphere(3.2, base + Vector3(0, 13.4, 0), Color(0.24, 0.45, 0.36))
	dome.scale = Vector3(1, 1.2, 1)
	_sphere(0.7, base + Vector3(0, 17.4, 0), Color(0.85, 0.68, 0.25))
	_box(Vector3(0.25, 3, 0.25), base + Vector3(0, 19, 0), Color(0.85, 0.68, 0.25))
	_box(Vector3(1.6, 0.25, 0.25), base + Vector3(0, 19.6, 0), Color(0.85, 0.68, 0.25))
	# Old merchant houses around the church.
	_box(Vector3(12, 7, 8), base + Vector3(16, 3.5, -4), Color(0.8, 0.66, 0.42))
	_box(Vector3(12.4, 2.5, 8.4), base + Vector3(16, 8.2, -4), Color(0.48, 0.2, 0.16))
	_windows(base + Vector3(16, 0, -4), Vector2(12, 8), 2, 4, 2.6)
	_box(Vector3(10, 7, 8), base + Vector3(18, 3.5, 12), Color(0.86, 0.8, 0.62))
	_box(Vector3(10.4, 2.5, 8.4), base + Vector3(18, 8.2, 12), Color(0.45, 0.25, 0.2))


func _build_market(at: Vector2) -> void:
	var base := Vector3(at.x, 0, at.y)
	_box(Vector3(46, 0.2, 22), base + Vector3(0, 0.08, 4), Color(0.48, 0.46, 0.43))
	var colors := [Color(0.25, 0.4, 0.65), Color(0.7, 0.25, 0.2), Color(0.3, 0.5, 0.35), Color(0.85, 0.82, 0.72)]
	for row in 3:
		for col in 7:
			var tent_color: Color = colors[(row * 7 + col) % colors.size()]
			_box(Vector3(4, 0.4, 3.4), base + Vector3(-18 + col * 6, 2.6, -2 + row * 6), tent_color)
			_box(Vector3(3.6, 2.4, 3), base + Vector3(-18 + col * 6, 1.2, -2 + row * 6), Color(0.45, 0.38, 0.32))
	for i in 3:
		_box(Vector3(3, 2.6, 2.4), base + Vector3(26, 1.3, -4 + i * 5), Color(0.8, 0.8, 0.75))


func _build_wasteland(at: Vector2) -> void:
	var base := Vector3(at.x, 0, at.y)
	_box(Vector3(30, 0.2, 20), base + Vector3(0, 0.07, 0), Color(0.45, 0.42, 0.3))
	for i in 6:
		_box(Vector3(1.2, 0.6, 0.9), base + Vector3(_rng.randf_range(-12, 12), 0.3, _rng.randf_range(-8, 8)), Color(0.35, 0.33, 0.3))
	for i in 7:
		_tree(base + Vector3(_rng.randf_range(-13, 13), 0, _rng.randf_range(-9, 9)), true)


func _build_overlays() -> void:
	# Picket at Block 5: residents with placards in front of the entrance.
	var picket := Node3D.new()
	add_child(picket)
	var block5: Vector2 = Week1.LOTS["block5"]["pos"]
	var coats := [Color(0.25, 0.22, 0.2), Color(0.4, 0.3, 0.25), Color(0.3, 0.32, 0.38), Color(0.5, 0.42, 0.3)]
	for i in 9:
		var spot := Vector3(block5.x - 10 + i * 2.4, 0, block5.y + 11 + (i % 2) * 1.6)
		_capsule(spot + Vector3(0, 1.0, 0), coats[i % coats.size()], picket)
		if i % 3 == 1:
			_box(Vector3(0.15, 3.2, 0.15), spot + Vector3(0.5, 1.6, 0), Color(0.4, 0.3, 0.2), picket)
			_box(Vector3(2.4, 1.4, 0.1), spot + Vector3(0.5, 3.4, 0), Color(0.95, 0.93, 0.88), picket)
	# Overlays are drawn larger than life so they read from the map camera.
	_scale_around(picket, Vector3(block5.x, 0, block5.y + 12), 2.2)
	picket.visible = false
	_overlays["block5:picket"] = picket

	# Coal theft at the boiler house: a truck without plates at the coal heap.
	var truck := Node3D.new()
	add_child(truck)
	var boiler: Vector2 = Week1.LOTS["boiler"]["pos"]
	var at := Vector3(boiler.x - 16, 0, boiler.y + 10)
	_box(Vector3(3, 2.6, 2.6), at + Vector3(4.5, 1.6, 0), Color(0.25, 0.32, 0.25), truck)
	_box(Vector3(6, 1.8, 2.8), at + Vector3(0, 1.4, 0), Color(0.3, 0.36, 0.28), truck)
	_box(Vector3(5.4, 0.6, 2.4), at + Vector3(0, 2.6, 0), Color(0.1, 0.1, 0.11), truck)
	for i in 3:
		_capsule(at + Vector3(-4 + i * 1.5, 1.0, 2.5), Color(0.2, 0.2, 0.2), truck)
	_scale_around(truck, at, 1.8)
	truck.visible = false
	_overlays["boiler:truck"] = truck


func _scale_around(node: Node3D, pivot: Vector3, factor: float) -> void:
	for child in node.get_children():
		child.position = pivot + (child.position - pivot) * factor
		child.scale *= factor


func _build_background_blocks() -> void:
	_panel_block(Vector3(-36, 0, 44), 34, 5)
	_panel_block(Vector3(-78, 0, 8), 30, 5)
	_panel_block(Vector3(-82, 0, -26), 26, 9)
	_panel_block(Vector3(56, 0, 44), 30, 5)
	_panel_block(Vector3(-4, 0, -28), 24, 9)
	_box(Vector3(14, 6, 10), Vector3(66, 3, 0), BRICK)
	_box(Vector3(10, 4, 8), Vector3(-10, 2, 48), Color(0.75, 0.72, 0.62))


func _build_trees() -> void:
	var placed := 0
	while placed < 70:
		var spot := Vector3(_rng.randf_range(-110, 110), 0, _rng.randf_range(-40, 70))
		if _near_anything(Vector2(spot.x, spot.z)):
			continue
		_tree(spot, _rng.randf() < 0.4)
		placed += 1


func _near_anything(spot: Vector2) -> bool:
	if abs(spot.y + 6) < 7 or abs(spot.x - 14) < 7 or abs(spot.y - 28) < 6:
		return true
	for lot in Week1.LOTS:
		if spot.distance_to(Week1.LOTS[lot]["pos"]) < 22:
			return true
	for block in [Vector2(-36, 44), Vector2(-78, 8), Vector2(-82, -26), Vector2(56, 44), Vector2(-4, -28)]:
		if abs(spot.x - block.x) < 22 and abs(spot.y - block.y) < 9:
			return true
	return false


# --- Tokens ------------------------------------------------------------------

func _build_tokens() -> void:
	for id in Week1.ACTORS:
		var info: Dictionary = Week1.ACTORS[id]
		var token := Node3D.new()
		add_child(token)
		var is_player: bool = info["portrait"] == ""
		var disc_color := Color(0.85, 0.36, 0.27) if is_player else Color(0.12, 0.13, 0.12)
		var disc := _cylinder(2.0, 0.4, Vector3(0, 0.2, 0), disc_color, token)
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if is_player:
			# The player has no portrait: a red marker with "ВЫ".
			var label := Label3D.new()
			label.text = "ВЫ"
			label.font_size = 96
			label.pixel_size = 0.05
			label.outline_size = 18
			label.modulate = Color(1, 0.97, 0.9)
			label.outline_modulate = Color(0.55, 0.16, 0.1)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.render_priority = 11
			label.position = Vector3(0, 6.5, 0)
			token.add_child(label)
		else:
			var sprite := Sprite3D.new()
			sprite.texture = load(info["portrait"])
			sprite.region_enabled = true
			sprite.region_rect = info["face"]
			sprite.pixel_size = 7.0 / info["face"].size.x
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.no_depth_test = true
			sprite.render_priority = 10
			sprite.position = Vector3(0, 6.5, 0)
			token.add_child(sprite)
		var start: Vector2 = sim.actors[id]["pos"]
		token.position = Vector3(start.x, 0, start.y + 6)
		_tokens[id] = token


# --- Signal handlers ---------------------------------------------------------

func _on_overlay_changed(lot: String, overlay: String, shown: bool) -> void:
	var key := lot + ":" + overlay
	if _overlays.has(key):
		_overlays[key].visible = shown


func _on_lot_state_changed(lot: String, state: String) -> void:
	if not _lot_states.has(lot):
		return
	for state_name in _lot_states[lot]:
		_lot_states[lot][state_name].visible = state_name == state


# --- Shape helpers -----------------------------------------------------------

func _panel_block(base: Vector3, length: float, floors: int) -> void:
	var height := floors * 3.0
	_box(Vector3(length, height, 11), base + Vector3(0, height / 2.0, 0), PANEL)
	_box(Vector3(length + 0.6, 0.6, 11.6), base + Vector3(0, height + 0.3, 0), PANEL_ROOF)
	_windows(base, Vector2(length, 11), floors, int(length / 3.2), 3.0)
	# A few glazed-in balconies in different colors, as in the concept art.
	var balcony_colors := [Color(0.55, 0.62, 0.55), Color(0.7, 0.6, 0.45), Color(0.45, 0.5, 0.6)]
	for i in int(length / 8):
		var floor_index := _rng.randi_range(1, floors - 1)
		var x := -length / 2.0 + 4 + i * 8 + _rng.randf_range(-1, 1)
		_box(Vector3(2.6, 2.2, 1.2), base + Vector3(x, floor_index * 3.0 + 1.4, 6.0), balcony_colors[i % 3])


func _windows(base: Vector3, footprint: Vector2, floors: int, per_row: int, floor_height: float) -> void:
	var spacing := footprint.x / float(per_row)
	for floor_index in floors:
		for i in per_row:
			var x := -footprint.x / 2.0 + spacing * (i + 0.5)
			var y := floor_index * floor_height + floor_height * 0.55
			for side in [-1.0, 1.0]:
				_box(Vector3(spacing * 0.45, floor_height * 0.45, 0.1), base + Vector3(x, y, side * (footprint.y / 2.0 + 0.05)), WINDOW)


func _tree(at: Vector3, birch: bool) -> void:
	var trunk_color := Color(0.88, 0.87, 0.82) if birch else Color(0.32, 0.25, 0.18)
	var height := _rng.randf_range(5.0, 8.0)
	_cylinder(0.35, height, at + Vector3(0, height / 2.0, 0), trunk_color)
	var crown := _sphere(_rng.randf_range(2.2, 3.4), at + Vector3(0, height + 1.0, 0), FOLIAGE[_rng.randi() % FOLIAGE.size()])
	crown.scale = Vector3(1, 1.25, 1)


func _material(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.92
		if color.a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[key] = material
	return _materials[key]


func _add_mesh(mesh: Mesh, at: Vector3, color: Color, parent: Node) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = at
	instance.material_override = _material(color)
	(parent if parent != null else self).add_child(instance)
	return instance


func _box(size: Vector3, at: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add_mesh(mesh, at, color, parent)


func _cylinder(radius: float, height: float, at: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	return _add_mesh(mesh, at, color, parent)


func _sphere(radius: float, at: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _add_mesh(mesh, at, color, parent)


func _capsule(at: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 2.0
	return _add_mesh(mesh, at, color, parent)
