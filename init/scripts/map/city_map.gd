# The 3D micro-district. Builds the city from simple shapes dressed with
# generated facades, following art/concepts/district_layout.svg; shows lot
# states and overlays; moves people tokens to the positions in the sim; and
# owns the scrollable, zoomable camera. The sim never sees any of this.
extends Node3D

const Week1 = preload("res://scripts/data/week1.gd")

const GRASS := Color(0.42, 0.47, 0.29)
const FOREIGN_GRASS := Color(0.5, 0.5, 0.36)
const GRASS_TINT := Color(0.66, 0.78, 0.56)
const ASPHALT := Color(0.24, 0.25, 0.26)
const PAVING := Color(0.55, 0.53, 0.49)
const PANEL := Color(0.66, 0.65, 0.61)
const PANEL_ROOF := Color(0.38, 0.38, 0.37)
const BRICK := Color(0.55, 0.27, 0.19)
const PLASTER := Color(0.82, 0.77, 0.65)
const OCHRE := Color(0.8, 0.66, 0.42)
const ROOF_RED := Color(0.48, 0.2, 0.16)
const WINDOW := Color(0.16, 0.18, 0.2)

# Generated painted surfaces (see art/PROMPTS.md). One facade tile is a 2:1
# straight-on elevation; the panel tile shows one five-storey section.
const FACADE_PANEL := preload("res://assets/textures/facade_panel_5storey.png")
const FACADE_BRICK := preload("res://assets/textures/facade_boiler_brick.png")
const FACADE_ADMIN := preload("res://assets/textures/facade_admin_stalinist.png")
const FACADE_WAREHOUSE := preload("res://assets/textures/facade_warehouse.png")
const FACADE_MERCHANT := preload("res://assets/textures/facade_merchant_house.png")
const ROOF_TAR := preload("res://assets/textures/roof_tar.png")
const TREE_BIRCH := preload("res://assets/sprites/tree_birch_august.png")
const TREE_POPLAR := preload("res://assets/sprites/tree_poplar_august.png")
const KIOSK := preload("res://assets/sprites/kiosk.png")
const MARKET_TENT := preload("res://assets/sprites/market_tent.png")
const CAR_LADA := preload("res://assets/sprites/car_lada.png")
const CAR_VOLGA := preload("res://assets/sprites/car_volga_black.png")
const VAN_UAZ := preload("res://assets/sprites/van_uaz_police.png")
const SCAFFOLDING := preload("res://assets/sprites/scaffolding.png")
const PEOPLE := [
	{"texture": preload("res://assets/sprites/person_walk_man.png"), "width": 2.1},
	{"texture": preload("res://assets/sprites/person_walk_woman.png"), "width": 2.1},
	{"texture": preload("res://assets/sprites/person_pensioner.png"), "width": 2.1},
	{"texture": preload("res://assets/sprites/person_worker.png"), "width": 2.7},
	{"texture": preload("res://assets/sprites/person_kid.png"), "width": 3.9},
]
const PICKET_GROUP := preload("res://assets/sprites/picket_group.png")
const TRUCK_ZIL := preload("res://assets/sprites/truck_zil_plain.png")
const CHURCH := preload("res://assets/sprites/church.png")
const FUEL_TANKS := preload("res://assets/sprites/fuel_tanks.png")
const BOILER_CHIMNEY := preload("res://assets/sprites/boiler_chimney.png")
const COAL_HEAP := preload("res://assets/sprites/coal_heap.png")
const CRANE_TRUCK := preload("res://assets/sprites/crane_truck.png")

# Painted ground tiles, seen from above and seamless; laid on flat patches.
const GROUND_GRASS := preload("res://assets/textures/ground_grass.png")
const GROUND_GRASS_DRY := preload("res://assets/textures/ground_grass_dry.png")
const GROUND_ASPHALT := preload("res://assets/textures/ground_asphalt.png")
const GROUND_PAVING := preload("res://assets/textures/ground_paving.png")
const GROUND_DIRT := preload("res://assets/textures/ground_dirt.png")
const GROUND_WATER := preload("res://assets/textures/ground_water.png")
const GROUND_RAIL := preload("res://assets/textures/ground_rail.png")
const GROUND_COURTYARD := preload("res://assets/textures/ground_courtyard.png")
const DECAL_CENTER_LINE := preload("res://assets/sprites/decal_center_line.png")
const DECAL_CROSSWALK := preload("res://assets/sprites/decal_crosswalk.png")

# Schematic coordinates: 1 SVG px = 0.25 map units, SVG (800, 530) is the origin.
const SVG_SCALE := 0.25
const SVG_ORIGIN := Vector2(800, 530)

# Map bounds the camera may look at, in map units (x, z).
const BOUNDS := Rect2(-200, -130, 400, 260)
const ZOOM_MIN := 120.0
const ZOOM_MAX := 520.0
const ZOOM_DEFAULT := 330.0
const CAMERA_DIRECTION := Vector3(0.0, 0.75, 0.66) # Up and toward the viewer.
const PAN_SPEED := 1.1 # Fraction of the zoom distance per second for keyboard panning.

var sim
var camera: Camera3D
var _camera_target := Vector3(-35, 0, 15)
var _camera_goal := Vector3(-35, 0, 15)
var _zoom := ZOOM_DEFAULT
var _dragging := false
var _tokens := {} # actor id -> Node3D
var _overlays := {} # "lot:name" -> Node3D
var _lot_states := {} # lot -> {state -> Node3D}
var _occupied: Array[Rect2] = [] # Ground taken by buildings and roads; trees avoid it.
var _ground_layer := 0 # Each ground tile sits a hair above the last so overlaps never flicker.
var _walkers: Array[Dictionary] = [] # Pedestrians walking back and forth along a street.
var _materials := {}
var _rng := RandomNumberGenerator.new()


func setup(week_sim) -> void:
	sim = week_sim
	_rng.seed = 7
	_build_environment()
	_build_ground_and_roads()
	_build_microdistrict()
	_build_boiler()
	_build_center()
	_build_old_center()
	_build_depot()
	_build_south()
	_build_traffic()
	_build_pedestrians()
	_build_overlays()
	_build_trees()
	_build_tokens()
	sim.overlay_changed.connect(_on_overlay_changed)
	sim.lot_state_changed.connect(_on_lot_state_changed)
	_update_camera()


func _process(delta: float) -> void:
	if sim == null:
		return
	_pan_with_keys(delta)
	_camera_target = _camera_target.lerp(_camera_goal, min(1.0, delta * 8.0))
	_update_camera()
	_move_tokens()
	_move_walkers(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom = max(ZOOM_MIN, _zoom * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom = min(ZOOM_MAX, _zoom * 1.1)
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		# Drag the map: move the target against the mouse, scaled by zoom.
		var per_pixel := _zoom / 900.0
		_set_goal(_camera_goal + Vector3(-event.relative.x, 0, -event.relative.y) * per_pixel)
		_camera_target = _camera_goal


# Screen position of a lot marker; the HUD places buttons there.
func lot_screen_position(lot: String, height: float = 16.0) -> Vector2:
	var pos: Vector2 = Week1.LOTS[lot]["pos"]
	return camera.unproject_position(Vector3(pos.x, height, pos.y))


# Where a person stands on screen (their feet), for the HUD to draw the token.
func token_screen_position(actor_id: String) -> Vector2:
	return camera.unproject_position(_tokens[actor_id].position)


# Smoothly moves the camera to a lot, e.g. when a crisis starts off-screen.
func focus_on(lot: String) -> void:
	var pos: Vector2 = Week1.LOTS[lot]["pos"]
	_set_goal(Vector3(pos.x, 0, pos.y))


# --- Camera ------------------------------------------------------------------

func _pan_with_keys(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction.z -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction.z += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction.x += 1
	if direction != Vector3.ZERO:
		_set_goal(_camera_goal + direction.normalized() * _zoom * PAN_SPEED * delta)


func _set_goal(goal: Vector3) -> void:
	_camera_goal = Vector3(
		clamp(goal.x, BOUNDS.position.x, BOUNDS.end.x), 0.0,
		clamp(goal.z, BOUNDS.position.y, BOUNDS.end.y))


func _update_camera() -> void:
	camera.position = _camera_target + CAMERA_DIRECTION.normalized() * _zoom
	camera.look_at(_camera_target)
	# Shift the picture left so the target sits in the middle of the free map
	# area rather than under the right panel.
	camera.h_offset = _zoom * 0.1
	camera.v_offset = -_zoom * 0.03


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
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 2.5
	# The map is a calm backdrop, so game elements on top can stand out: neutral
	# daylight, almost no haze, and slightly muted colors.
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.78, 0.82, 0.86)
	environment.fog_density = 0.00008
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 0.82

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	# Late August midday: neutral white sun, high enough for short shadows.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 900.0
	add_child(sun)

	camera = Camera3D.new()
	camera.fov = 32.0
	camera.far = 3000.0
	add_child(camera)


func _build_ground_and_roads() -> void:
	_box(Vector3(900, 1, 700), Vector3(0, -0.5, 60), GRASS)
	# The painted grass is bright and busy at map scale: tint it greener and use a
	# large tile so it reads as calm lawn.
	_ground_quad(Vector2(0, 60), Vector2(900, 700), 0.005, GROUND_GRASS, 44.0, false, GRASS_TINT)
	# Neighbor state, river, embankment.
	_svg_ground(Rect2(-400, -400, 2400, 470), FOREIGN_GRASS, 0.01, false, GROUND_GRASS_DRY, 44.0, false, GRASS_TINT)
	_svg_ground(Rect2(-400, 70, 2400, 80), Color(0.24, 0.36, 0.42), 0.02, false, GROUND_WATER, 40.0)
	_svg_ground(Rect2(-400, 150, 2400, 10), Color(0.5, 0.5, 0.48), 0.05, false, GROUND_PAVING, 10.0)

	# Roads from the schematic.
	var roads := [
		Rect2(880, 160, 40, 780), Rect2(-400, 470, 2400, 26), Rect2(120, 230, 740, 18),
		Rect2(120, 720, 760, 18), Rect2(120, 230, 18, 508), Rect2(500, 230, 18, 508),
		Rect2(920, 300, 560, 18), Rect2(1180, 496, 18, 444), Rect2(920, 700, 560, 18),
	]
	for road in roads:
		_svg_ground(road, ASPHALT, 0.06, true, GROUND_ASPHALT, 14.0)
	_build_road_markings()

	# Railway along the south edge and the spur to the depot (one tile spans the track).
	_svg_ground(Rect2(-400, 940, 2400, 12), Color(0.36, 0.33, 0.3), 0.08, true, GROUND_RAIL, 3.0)
	_svg_ground(Rect2(1480, 200, 12, 740), Color(0.36, 0.33, 0.3), 0.08, true, GROUND_RAIL, 3.0, true)

	# Bridge and the border checkpoint on the far bank.
	_svg_box(Rect2(880, 40, 40, 120), 1.2, Color(0.55, 0.55, 0.53))
	_svg_box(Rect2(855, 10, 90, 28), 3.5, Color(0.85, 0.85, 0.8))
	_box(Vector3(14, 0.5, 0.6), Vector3(25, 1.8, -121), Color(0.8, 0.25, 0.2))
	var tower := _svg_point(Vector2(966, 17))
	for corner in [Vector2(-1.6, -1.6), Vector2(1.6, -1.6), Vector2(-1.6, 1.6), Vector2(1.6, 1.6)]:
		_box(Vector3(0.4, 14, 0.4), Vector3(tower.x + corner.x, 7, tower.y + corner.y), Color(0.3, 0.3, 0.3))
	_box(Vector3(5, 3, 5), Vector3(tower.x, 15.5, tower.y), Color(0.35, 0.38, 0.33))


# --- West: the residential micro-district --------------------------------------

func _build_microdistrict() -> void:
	for rect in [
		Rect2(170, 270, 140, 34), Rect2(330, 270, 140, 34), Rect2(550, 270, 140, 34),
		Rect2(710, 270, 130, 34), Rect2(550, 400, 140, 34), Rect2(170, 530, 140, 34),
		Rect2(550, 530, 140, 34), Rect2(710, 530, 130, 34), Rect2(170, 650, 140, 34),
		Rect2(550, 650, 140, 34), Rect2(710, 650, 130, 34),
	]:
		_panel_block(_svg_center(rect), rect.size.x * SVG_SCALE, 5)
	# Block 5 is the same kind of building; it only matters because of who lives there.
	var block5 := Rect2(330, 400, 140, 40)
	_panel_block(_svg_center(block5), block5.size.x * SVG_SCALE, 5)
	var yard := _svg_center(block5) + Vector2(0, 11)
	_box(Vector3(3, 0.6, 0.8), Vector3(yard.x - 8, 0.3, yard.y), Color(0.35, 0.5, 0.3))
	_box(Vector3(3, 0.6, 0.8), Vector3(yard.x + 8, 0.3, yard.y), Color(0.35, 0.5, 0.3))
	_box(Vector3(0.3, 3, 0.3), Vector3(yard.x - 2, 1.5, yard.y + 4), Color(0.7, 0.2, 0.2))
	_box(Vector3(0.3, 3, 0.3), Vector3(yard.x + 2, 1.5, yard.y + 4), Color(0.2, 0.4, 0.7))
	_box(Vector3(4.3, 0.2, 0.2), Vector3(yard.x, 3, yard.y + 4), Color(0.6, 0.6, 0.2))

	# Courtyards, school, kindergarten, garages.
	for rect in [Rect2(215, 320, 250, 70), Rect2(565, 320, 270, 70), Rect2(215, 580, 250, 60), Rect2(565, 580, 270, 60)]:
		_svg_ground(rect, Color(0.5, 0.56, 0.33), 0.03, false, GROUND_COURTYARD, 22.0)
	_svg_building(Rect2(740, 390, 100, 60), 9, Color(0.86, 0.76, 0.52), Color(0.45, 0.4, 0.35))
	_svg_building(Rect2(380, 530, 90, 40), 6, Color(0.86, 0.76, 0.52), Color(0.45, 0.4, 0.35))
	for i in 8:
		_svg_building(Rect2(170 + i * 24, 760, 22, 30), 2.6, Color(0.5, 0.45, 0.4), Color(0.35, 0.3, 0.27))

	# Kiosks along the main street.
	for y in [520, 560, 640, 800, 840]:
		_sprite(KIOSK, _ground(_svg_point(Vector2(865, y))), 5.0, null, y % 80 == 0)


func _build_boiler() -> void:
	var rect := Rect2(20, 380, 80, 70)
	var center := _svg_center(rect)
	var size := Vector3(rect.size.x * SVG_SCALE, 9, rect.size.y * SVG_SCALE)
	var base := Vector3(center.x, 0, center.y)
	_box(size, base + Vector3(0, 4.5, 0), BRICK)
	_box(Vector3(size.x + 1, 0.6, size.z + 1), base + Vector3(0, 9.3, 0), Color(0.3, 0.3, 0.3))
	_facades(base, size, FACADE_BRICK, 1.0)
	_occupy(center, Vector2(size.x, size.z))
	var chimney := _svg_point(Vector2(86, 394))
	# The painted chimney is 34 units tall (canvas 2:3), so its width is 34 * 2/3.
	_sprite(BOILER_CHIMNEY, _ground(chimney), 22.7)
	var coal_spot := _svg_point(Vector2(45, 475))
	_sprite(COAL_HEAP, _ground(coal_spot), 14.0)

	# Overground heat pipes from the boiler house to the courtyards.
	for path in [
		[Vector2(100, 415), Vector2(155, 415), Vector2(155, 315), Vector2(860, 315)],
		[Vector2(155, 415), Vector2(155, 595), Vector2(860, 595)],
	]:
		for i in path.size() - 1:
			_heat_pipe(_svg_point(path[i]), _svg_point(path[i + 1]))

	# States: broken has nothing extra; repairing adds scaffolding and a fence;
	# working adds smoke from the chimney.
	var repairing := Node3D.new()
	add_child(repairing)
	var front := size.z / 2.0 + 1.2
	for i in 3:
		_sprite(SCAFFOLDING, base + Vector3(-size.x / 3.0 + i * size.x / 3.0, 0, front + 0.5), 9.0, repairing)
	_box(Vector3(size.x + 8, 2, 0.2), base + Vector3(0, 1, front + 5), Color(0.85, 0.5, 0.2), repairing)
	_sprite(CRANE_TRUCK, base + Vector3(size.x / 2.0 + 7, 0, front + 4), 12.0, repairing, true)
	repairing.visible = false

	var working := Node3D.new()
	add_child(working)
	var smoke := CPUParticles3D.new()
	smoke.position = Vector3(chimney.x, 34.5, chimney.y)
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


# --- Center: square and administration -------------------------------------

func _build_center() -> void:
	_svg_ground(Rect2(940, 370, 200, 90), PAVING, 0.04, true, GROUND_PAVING, 12.0)
	var monument := _svg_point(Vector2(1040, 415))
	_box(Vector3(3, 2, 3), Vector3(monument.x, 1, monument.y), Color(0.45, 0.45, 0.45))
	_cylinder(0.7, 4, Vector3(monument.x, 4, monument.y), Color(0.3, 0.32, 0.3))

	var rect := Rect2(975, 324, 130, 44)
	var center := _svg_center(rect)
	var base := Vector3(center.x, 0, center.y)
	# Tall enough that the 2:1 facade (columns, steps, emblem) keeps its proportions.
	var size := Vector3(rect.size.x * SVG_SCALE, 15, rect.size.y * SVG_SCALE)
	_box(size, base + Vector3(0, size.y / 2.0, 0), PLASTER)
	_box(Vector3(size.x + 1, 0.8, size.z + 1), base + Vector3(0, size.y + 0.4, 0), Color(0.5, 0.48, 0.44))
	_roof(Vector2(size.x + 1, size.z + 1), base + Vector3(0, size.y + 0.82, 0), 14.0)
	var front := Vector2(size.x, size.y)
	_facade(front, base + Vector3(0, size.y / 2.0, size.z / 2.0 + 0.01), 0.0, FACADE_ADMIN, Vector2(1, 1))
	_facade(front, base + Vector3(0, size.y / 2.0, -size.z / 2.0 - 0.01), PI, FACADE_ADMIN, Vector2(1, 1))
	_cylinder(0.15, 19, base + Vector3(size.x / 2.0 - 2, 9.5, size.z / 2.0 + 4), Color(0.3, 0.3, 0.3))
	_box(Vector3(2.4, 1.4, 0.1), base + Vector3(size.x / 2.0 - 0.8, 18, size.z / 2.0 + 4), Color(0.7, 0.2, 0.18))
	_occupy(center, Vector2(size.x, size.z + 8))


# --- East: old center with the church ----------------------------------------

func _build_old_center() -> void:
	var rect := Rect2(1230, 520, 60, 70)
	var center := _svg_center(rect)
	var base := Vector3(center.x, 0, center.y)
	_sprite(CHURCH, base, 24.0)
	_occupy(center, Vector2(14, 22))
	# Merchant houses.
	for house in [Rect2(960, 520, 80, 44), Rect2(1060, 520, 90, 44), Rect2(960, 590, 190, 44), Rect2(1220, 610, 110, 40)]:
		_svg_building(house, 7, OCHRE, ROOF_RED, true, FACADE_MERCHANT)


# --- North-east: fuel depot on the embankment --------------------------------

func _build_depot() -> void:
	for spot in [Vector2(1240, 245), Vector2(1300, 245), Vector2(1360, 245)]:
		_occupy(_svg_point(spot), Vector2(12, 12))
	# One painted sprite for the whole tank farm with its manifold.
	_sprite(FUEL_TANKS, _ground(_svg_point(Vector2(1300, 250))), 34.0)
	_svg_building(Rect2(1180, 330, 120, 44), 6, BRICK, Color(0.4, 0.33, 0.28), false, FACADE_WAREHOUSE)
	_svg_box(Rect2(1300, 160, 160, 20), 0.8, Color(0.5, 0.48, 0.45))
	var fence := _svg_point(Vector2(1300, 285))
	_box(Vector3(46, 2.2, 0.2), Vector3(fence.x, 1.1, fence.y), Color(0.4, 0.42, 0.4))
	_box(Vector3(7, 2.6, 2.4), Vector3(fence.x - 14, 1.3, fence.y + 3), Color(0.6, 0.55, 0.2))


# --- South: station, market, private houses, wasteland ------------------------

func _build_south() -> void:
	_svg_building(Rect2(840, 885, 120, 45), 8, Color(0.85, 0.8, 0.68), Color(0.4, 0.42, 0.4))
	# Station market: out of reach at the aide stage, but busy.
	_svg_ground(Rect2(560, 790, 260, 130), PAVING, 0.04, true, GROUND_PAVING, 12.0)
	for row in 3:
		for col in 7:
			var at := _svg_point(Vector2(590 + col * 34, 818 + row * 34))
			_sprite(MARKET_TENT, _ground(at), 8.0, null, (row + col) % 2 == 0)
	# Shoppers in the aisles between the stalls.
	for i in 16:
		var aisle := _svg_point(Vector2(_rng.randf_range(580, 800), 800 + (i % 3) * 34 + 17))
		var person: Dictionary = PEOPLE[_rng.randi() % PEOPLE.size()]
		_sprite(person["texture"], _ground(aisle), person["width"], null, _rng.randf() < 0.5)
	# Private houses with pitched roofs.
	for row in 3:
		for col in 4:
			if row == 2 and col == 3:
				continue
			_svg_building(Rect2(1230 + col * 50, 740 + row * 60, 30, 26), 3.5, Color(0.78, 0.7, 0.58), Color(0.4, 0.3, 0.26), true)
	# Wasteland: bare ground with garbage and a birch grove.
	var waste := Rect2(150, 840, 300, 90)
	_svg_ground(waste, Color(0.45, 0.42, 0.3), 0.04, false, GROUND_DIRT, 22.0)
	var center := _svg_center(waste)
	for i in 8:
		_box(Vector3(1.2, 0.6, 0.9), Vector3(center.x + _rng.randf_range(-30, 30), 0.3, center.y + _rng.randf_range(-8, 8)), Color(0.35, 0.33, 0.3))
	for i in 14:
		_tree(Vector3(center.x + _rng.randf_range(-34, 34), 0, center.y + _rng.randf_range(-9, 9)))


# Parked and standing cars: the administration's Volga, a police UAZ, and
# Ladas along the streets. Sprites are fixed in place; people move, cars do not (yet).
func _build_traffic() -> void:
	var admin := _svg_point(Vector2(1040, 346))
	_sprite(CAR_VOLGA, _ground(admin + Vector2(-16, 14)), 8.5)
	_sprite(VAN_UAZ, _ground(_svg_point(Vector2(1110, 380))), 8.5, null, true)
	var lada_spots := [
		Vector2(900, 600), Vector2(900, 340), Vector2(900, 760), Vector2(400, 242), Vector2(640, 726),
		Vector2(1000, 706), Vector2(1100, 306), Vector2(300, 478), Vector2(1190, 640), Vector2(700, 484),
	]
	for i in lada_spots.size():
		_sprite(CAR_LADA, _ground(_svg_point(lada_spots[i])), 7.5, null, i % 2 == 1)


func _build_overlays() -> void:
	# Picket at Block 5: residents with placards in front of the entrance.
	var picket := Node3D.new()
	add_child(picket)
	var block5: Vector2 = Week1.LOTS["block5"]["pos"]
	_sprite(PICKET_GROUP, Vector3(block5.x, 0, block5.y + 9), 12.0, picket)
	picket.visible = false
	_overlays["block5:picket"] = picket

	# Coal theft at the boiler house: a truck without plates at the coal heap.
	var truck := Node3D.new()
	add_child(truck)
	var coal := _svg_point(Vector2(45, 475))
	_sprite(TRUCK_ZIL, Vector3(coal.x + 13, 0, coal.y + 3), 12.0, truck)
	truck.visible = false
	_overlays["boiler:truck"] = truck


func _build_trees() -> void:
	# Courtyards and street sides get trees; built-up ground and roads stay free.
	var placed := 0
	var attempts := 0
	while placed < 260 and attempts < 6000:
		attempts += 1
		var spot := Vector2(_rng.randf_range(-195, 195), _rng.randf_range(-88, 100))
		if _is_occupied(spot, 3.0):
			continue
		_tree(Vector3(spot.x, 0, spot.y))
		placed += 1


# --- Tokens ------------------------------------------------------------------

func _build_tokens() -> void:
	for id in Week1.ACTORS:
		var info: Dictionary = Week1.ACTORS[id]
		var token := Node3D.new()
		add_child(token)
		# The player's token stands on a red disc so it is easy to find.
		var disc_color := Color(0.85, 0.36, 0.27) if id == "me" else Color(0.12, 0.13, 0.12)
		var disc := _cylinder(2.2, 0.4, Vector3(0, 0.2, 0), disc_color, token)
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# The face itself is drawn by the HUD, crisp and unaffected by map lighting.
		var start: Vector2 = sim.actors[id]["pos"]
		token.position = Vector3(start.x, 0, start.y + 6)
		_tokens[id] = token


func _move_tokens() -> void:
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
			var spread := (i - (ids.size() - 1) / 2.0) * 15.0
			var token: Node3D = _tokens[ids[i]]
			token.position = token.position.lerp(Vector3(pos.x + spread, 0.0, pos.y + 6.0), 0.35)


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


# --- Schematic helpers -------------------------------------------------------

func _svg_point(point: Vector2) -> Vector2:
	return (point - SVG_ORIGIN) * SVG_SCALE


func _svg_center(rect: Rect2) -> Vector2:
	return _svg_point(rect.get_center())


# A flat ground patch (roads, yards, water) from a schematic rectangle.
func _svg_ground(rect: Rect2, color: Color, y: float, occupied: bool = false, texture: Texture2D = null, tile: float = 24.0, turned: bool = false, tint: Color = Color.WHITE) -> void:
	var center := _svg_center(rect)
	var size := rect.size * SVG_SCALE
	_box(Vector3(size.x, 0.2, size.y), Vector3(center.x, y, center.y), color)
	if texture != null:
		_ground_quad(center, size, y + 0.1, texture, tile, turned, tint)
	if occupied:
		_occupy(center, size)


# A painted ground tile laid flat on top of a patch. Tiles line up in world
# space, so neighboring patches of the same texture continue seamlessly. `tile`
# is the edge of one texture repeat in map units; `turned` runs the texture
# along the other axis (for a north-south railway).
func _ground_quad(center: Vector2, size: Vector2, y: float, texture: Texture2D, tile: float, turned: bool = false, tint: Color = Color.WHITE) -> void:
	_ground_layer += 1
	var quad := QuadMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.roughness = 0.95
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var instance := MeshInstance3D.new()
	if turned:
		quad.size = Vector2(size.y, size.x)
		material.uv1_scale = Vector3(size.y / tile, size.x / tile, 1.0)
		instance.basis = Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, -PI / 2.0)
	else:
		quad.size = size
		material.uv1_scale = Vector3(size.x / tile, size.y / tile, 1.0)
		var corner := center - size / 2.0
		material.uv1_offset = Vector3(corner.x / tile, corner.y / tile, 0.0)
		instance.basis = Basis(Vector3.RIGHT, -PI / 2.0)
	instance.mesh = quad
	instance.material_override = material
	instance.position = Vector3(center.x, y + _ground_layer * 0.004, center.y)
	add_child(instance)


# A worn white road marking laid flat on the asphalt: transparent, so only the
# paint shows. `width` runs along the road; `yaw` turns it (PI / 2 for a
# north-south road).
func _decal(texture: Texture2D, at: Vector2, width: float, yaw: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width, width * texture.get_height() / texture.get_width())
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	material.roughness = 1.0
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, -PI / 2.0)
	instance.position = Vector3(at.x, 0.62, at.y)
	add_child(instance)


# Center lines on the main street and the cross street, plus zebra crossings.
func _build_road_markings() -> void:
	var main_x := _svg_point(Vector2(900, 0)).x
	var cross_z := _svg_point(Vector2(0, 483)).y
	var z := -88.0
	while z < 98.0:
		if abs(z - cross_z) > 16.0:
			_decal(DECAL_CENTER_LINE, Vector2(main_x, z), 28.0, PI / 2.0)
		z += 28.0
	var x := -196.0
	while x < 196.0:
		if abs(x - main_x) > 18.0:
			_decal(DECAL_CENTER_LINE, Vector2(x, cross_z), 28.0, 0.0)
		x += 28.0
	for crossing_z in [cross_z - 11.0, cross_z + 11.0]:
		_decal(DECAL_CROSSWALK, Vector2(main_x, crossing_z), 9.0, 0.0)


# People walking back and forth along the streets: ambient life that goes on
# while the game is paused, and never touches the simulation.
func _build_pedestrians() -> void:
	var main_x := _svg_point(Vector2(900, 0)).x
	var cross_z := _svg_point(Vector2(0, 483)).y
	var north_z := _svg_point(Vector2(0, 239)).y
	var south_z := _svg_point(Vector2(0, 729)).y
	# Walking lanes just off the road centers: [from, to].
	var lanes := [
		[Vector2(main_x + 7.0, -88), Vector2(main_x + 7.0, 98)],
		[Vector2(main_x - 7.0, -88), Vector2(main_x - 7.0, 98)],
		[Vector2(-190, cross_z + 5.0), Vector2(190, cross_z + 5.0)],
		[Vector2(-190, cross_z - 5.0), Vector2(190, cross_z - 5.0)],
		[Vector2(-168, north_z + 4.0), Vector2(14, north_z + 4.0)],
		[Vector2(-168, south_z - 4.0), Vector2(14, south_z - 4.0)],
		[Vector2(-172.0, north_z), Vector2(-172.0, south_z)],
	]
	for i in 22:
		var lane: Array = lanes[_rng.randi() % lanes.size()]
		var length: float = lane[0].distance_to(lane[1])
		var span := _rng.randf_range(36.0, 80.0)
		var start := _rng.randf_range(0.0, max(1.0, length - span))
		var direction: Vector2 = (lane[1] - lane[0]).normalized()
		var person: Dictionary = PEOPLE[_rng.randi() % PEOPLE.size()]
		var sprite := _sprite(person["texture"], Vector3.ZERO, person["width"])
		var from: Vector2 = lane[0] + direction * start
		_walkers.append({
			"sprite": sprite, "from": from, "to": from + direction * span,
			"t": _rng.randf(), "dir": 1.0 if _rng.randf() < 0.5 else -1.0,
			"speed": _rng.randf_range(2.0, 3.4), "lift": sprite.position.y,
		})


func _move_walkers(delta: float) -> void:
	for walker in _walkers:
		var from: Vector2 = walker["from"]
		var to: Vector2 = walker["to"]
		var length: float = from.distance_to(to)
		walker["t"] += walker["dir"] * walker["speed"] * delta / length
		if walker["t"] > 1.0 or walker["t"] < 0.0:
			walker["t"] = clamp(walker["t"], 0.0, 1.0)
			walker["dir"] = -walker["dir"]
		var pos: Vector2 = from.lerp(to, walker["t"])
		var sprite: Sprite3D = walker["sprite"]
		sprite.position = Vector3(pos.x, walker["lift"], pos.y)
		var heading: Vector2 = (to - from) * walker["dir"]
		sprite.flip_h = heading.x + heading.y * 0.5 < 0.0


func _svg_box(rect: Rect2, height: float, color: Color) -> void:
	var center := _svg_center(rect)
	var size := rect.size * SVG_SCALE
	_box(Vector3(size.x, height, size.y), Vector3(center.x, height / 2.0, center.y), color)
	_occupy(center, size)


# A simple building: walls, a flat or pitched roof, and windows or a painted facade.
func _svg_building(rect: Rect2, height: float, wall: Color, roof: Color, pitched: bool = false, facade: Texture2D = null) -> void:
	var center := _svg_center(rect)
	var size := rect.size * SVG_SCALE
	var base := Vector3(center.x, 0, center.y)
	_box(Vector3(size.x, height, size.y), base + Vector3(0, height / 2.0, 0), wall)
	if pitched:
		# Stepped stand-in for a pitched roof until roofs get real shapes.
		_box(Vector3(size.x + 0.6, 2.4, size.y * 0.72), base + Vector3(0, height + 1.0, 0), roof)
		_box(Vector3(size.x + 0.6, 1.2, size.y * 0.4), base + Vector3(0, height + 2.6, 0), roof)
	else:
		_box(Vector3(size.x + 0.5, 0.5, size.y + 0.5), base + Vector3(0, height + 0.25, 0), roof)
	if facade != null:
		_facades(base, Vector3(size.x, height, size.y), facade, 1.0)
	elif height >= 5.0:
		_windows(base, size, int(height / 3.2), max(2, int(size.x / 3.5)), 3.2)
	_occupy(center, size)


func _panel_block(center: Vector2, length: float, floors: int) -> void:
	var base := Vector3(center.x, 0, center.y)
	var height := floors * 3.0
	_box(Vector3(length, height, 11), base + Vector3(0, height / 2.0, 0), PANEL)
	_box(Vector3(length + 0.6, 0.6, 11.6), base + Vector3(0, height + 0.3, 0), PANEL_ROOF)
	_roof(Vector2(length + 0.6, 11.6), base + Vector3(0, height + 0.62, 0), 18.0)
	# Long sides get the painted facade; taller blocks repeat it vertically.
	var tiles_x := length / (height * 2.0 * 5.0 / floors)
	_facade(Vector2(length, height), base + Vector3(0, height / 2.0, 5.51), 0.0, FACADE_PANEL, Vector2(tiles_x, floors / 5.0))
	_facade(Vector2(length, height), base + Vector3(0, height / 2.0, -5.51), PI, FACADE_PANEL, Vector2(tiles_x, floors / 5.0))
	_occupy(center, Vector2(length, 11))


func _heat_pipe(from: Vector2, to: Vector2) -> void:
	var middle := (from + to) / 2.0
	var length := from.distance_to(to)
	var along_x: bool = abs(to.x - from.x) > abs(to.y - from.y)
	var size := Vector3(length, 0.7, 0.7) if along_x else Vector3(0.7, 0.7, length)
	for offset in [-0.5, 0.5]:
		var shift := Vector3(0, 0, offset) if along_x else Vector3(offset, 0, 0)
		_box(size, Vector3(middle.x, 2.6, middle.y) + shift, Color(0.72, 0.7, 0.64))
	var steps := int(length / 8.0)
	for i in steps + 1:
		var point := from.lerp(to, float(i) / max(1, steps))
		_box(Vector3(0.4, 2.4, 0.4), Vector3(point.x, 1.2, point.y), Color(0.4, 0.38, 0.35))


func _occupy(center: Vector2, size: Vector2) -> void:
	_occupied.append(Rect2(center - size / 2.0, size))


func _is_occupied(spot: Vector2, margin: float) -> bool:
	for rect in _occupied:
		if rect.grow(margin).has_point(spot):
			return true
	for lot in Week1.LOTS:
		if spot.distance_to(Week1.LOTS[lot]["pos"]) < 10.0:
			return true
	# Keep the river and the far bank free of trees.
	return spot.y < -88


# --- Shape helpers -----------------------------------------------------------

func _windows(base: Vector3, footprint: Vector2, floors: int, per_row: int, floor_height: float) -> void:
	var spacing := footprint.x / float(per_row)
	for floor_index in floors:
		for i in per_row:
			var x := -footprint.x / 2.0 + spacing * (i + 0.5)
			var y := floor_index * floor_height + floor_height * 0.55
			for side in [-1.0, 1.0]:
				_box(Vector3(spacing * 0.45, floor_height * 0.45, 0.1), base + Vector3(x, y, side * (footprint.y / 2.0 + 0.05)), WINDOW)


func _tree(at: Vector3) -> void:
	# Painted tree sprite standing upright and turning toward the camera:
	# mostly birches, with taller poplars for variety.
	var poplar := _rng.randf() < 0.25
	var height := _rng.randf_range(13.0, 18.0) if poplar else _rng.randf_range(9.0, 13.0)
	var sprite := Sprite3D.new()
	sprite.texture = TREE_POPLAR if poplar else TREE_BIRCH
	sprite.pixel_size = height / sprite.texture.get_height()
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = true
	sprite.modulate = Color(1, 1, 1).lerp(Color(0.92, 0.95, 0.8), _rng.randf())
	sprite.position = at + Vector3(0, height / 2.0, 0)
	add_child(sprite)


func _ground(at: Vector2) -> Vector3:
	return Vector3(at.x, 0.0, at.y)


# A painted prop standing on the ground: cars, kiosks, tents, scaffolding. It
# faces the camera and is drawn at the map camera's angle, so it needs no
# 3D model. `width` is in map units; `flip` mirrors it for variety.
func _sprite(texture: Texture2D, at: Vector3, width: float, parent: Node = null, flip: bool = false) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = width / texture.get_width()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = true
	sprite.flip_h = flip
	sprite.position = at + Vector3(0, texture.get_height() * sprite.pixel_size / 2.0, 0)
	(parent if parent != null else self).add_child(sprite)
	return sprite


# A textured flat roof: a quad facing up, tiled so the roof detail stays small.
func _roof(size: Vector2, at: Vector3, tile: float) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = ROOF_TAR
	material.uv1_scale = Vector3(size.x / tile, size.y / tile, 1.0)
	material.roughness = 0.95
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	instance.position = at
	instance.rotation.x = -PI / 2.0
	add_child(instance)


# Painted facades on the four sides of a box-shaped building.
func _facades(base: Vector3, size: Vector3, texture: Texture2D, tiles_per_height: float) -> void:
	var tile_width := size.y * 2.0 / tiles_per_height
	var center_y := size.y / 2.0
	_facade(Vector2(size.x, size.y), base + Vector3(0, center_y, size.z / 2.0 + 0.01), 0.0, texture, Vector2(size.x / tile_width, tiles_per_height))
	_facade(Vector2(size.x, size.y), base + Vector3(0, center_y, -size.z / 2.0 - 0.01), PI, texture, Vector2(size.x / tile_width, tiles_per_height))
	_facade(Vector2(size.z, size.y), base + Vector3(size.x / 2.0 + 0.01, center_y, 0), PI / 2.0, texture, Vector2(size.z / tile_width, tiles_per_height))
	_facade(Vector2(size.z, size.y), base + Vector3(-size.x / 2.0 - 0.01, center_y, 0), -PI / 2.0, texture, Vector2(size.z / tile_width, tiles_per_height))


# One textured wall: a quad facing +Z, turned by yaw around the vertical axis.
func _facade(size: Vector2, at: Vector3, yaw: float, texture: Texture2D, tiles: Vector2) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.uv1_scale = Vector3(tiles.x, tiles.y, 1.0)
	material.roughness = 0.95
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	instance.position = at
	instance.rotation.y = yaw
	add_child(instance)


func _scale_around(node: Node3D, pivot: Vector3, factor: float) -> void:
	for child in node.get_children():
		child.position = pivot + (child.position - pivot) * factor
		child.scale *= factor


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
