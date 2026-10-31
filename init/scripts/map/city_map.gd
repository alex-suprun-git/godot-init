# The 3D district view. Geography and building recipes come from data; this
# node owns the camera, environment, actors, lot states and event overlays.
extends Node3D

const DistrictLayout = preload("res://scripts/data/district_layout.gd")
const BuildingCatalog = preload("res://scripts/data/building_catalog.gd")
const DistrictBuilder = preload("res://scripts/map/district_builder.gd")
const Week1 = preload("res://scripts/data/week1.gd")
const Settings = preload("res://scripts/data/settings.gd")
const SpriteAnchors = preload("res://scripts/data/sprite_anchors.gd")
const GroundedProps = preload("res://scripts/map/grounded_props.gd")
const VehicleModels = preload("res://scripts/map/vehicle_models.gd")
const AmbientLife = preload("res://scripts/map/ambient_life.gd")
const GarageModel = preload("res://scripts/map/garage_model.gd")
const PropDimensions = preload("res://scripts/data/prop_dimensions.gd")

const GRASS := Color(0.42, 0.47, 0.29)
const PANEL_ROOF := Color(0.38, 0.38, 0.37)
const WINDOW := Color(0.16, 0.18, 0.2)

# Generated painted surfaces (see art/PROMPTS.md). One facade tile is a 2:1
# straight-on elevation; the panel tile shows one five-storey section.
const ROOF_TAR := preload("res://assets/textures/roof_tar.png")

# Paint over the grey panel facade, so a row of identical blocks reads as a living
# district: neutral, faded yellow, blue, green, salmon and cream.
const PANEL_TINTS := [
	Color(1.0, 1.0, 1.0), Color(1.0, 0.93, 0.74), Color(0.8, 0.9, 1.0),
	Color(0.84, 0.97, 0.84), Color(1.0, 0.84, 0.78), Color(0.96, 0.96, 0.9),
]
const TREE_BIRCH := preload("res://assets/sprites/tree_birch_august.png")
const TREE_POPLAR := preload("res://assets/sprites/tree_poplar_august.png")
const MARKET_TENT := preload("res://assets/sprites/market_tent.png")
const CAR_VOLGA := preload("res://assets/sprites/car_volga_black_v3.png")
const SCAFFOLDING := preload("res://assets/sprites/scaffolding.png")
const PEOPLE := [
	{"texture": preload("res://assets/sprites/person_walk_man.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_walk_man"]},
	{"texture": preload("res://assets/sprites/person_walk_woman.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_walk_woman"]},
	{"texture": preload("res://assets/sprites/person_pensioner.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_pensioner"]},
	{"texture": preload("res://assets/sprites/person_worker.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_worker"]},
	{"texture": preload("res://assets/sprites/person_kid.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_kid"]},
]
const PICKET_GROUP := preload("res://assets/sprites/picket_group.png")
const TRUCK_ZIL := preload("res://assets/sprites/truck_zil_plain.png")
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
const ROAD_PAINT_SHADER := preload("res://assets/shaders/road_paint.gdshader")
const GROUND_SNOW_GRASS := preload("res://assets/textures/ground_snow_grass.png")
const GROUND_SNOW_GRASS_DRY := preload("res://assets/textures/ground_snow_grass_dry.png")
const GROUND_SNOW_ASPHALT := preload("res://assets/textures/ground_snow_asphalt.png")
const GROUND_SNOW_PAVING := preload("res://assets/textures/ground_snow_paving.png")
const GROUND_SNOW_DIRT := preload("res://assets/textures/ground_snow_dirt.png")
const TREE_BIRCH_OCTOBER := preload("res://assets/sprites/tree_birch_october.png")
const TREE_POPLAR_OCTOBER := preload("res://assets/sprites/tree_poplar_october.png")
const TREE_BIRCH_WINTER := preload("res://assets/sprites/tree_birch_winter.png")
const TREE_POPLAR_WINTER := preload("res://assets/sprites/tree_poplar_winter.png")

# Props that were boxes before the full sprite set arrived.
const GARAGE_SINGLE := preload("res://assets/sprites/garage_single_v3.png")
const LAMP_POST := preload("res://assets/sprites/lamp_post.png")
const BUS_STOP := preload("res://assets/sprites/bus_stop_v2.png")
const BUS_LIAZ := preload("res://assets/sprites/bus_liaz.png")
const BUSH := preload("res://assets/sprites/bush.png")

# The same scenario in three looks. Each season picks the ground tiles, the
# trees, the light and the weather; nothing else about the map changes.
const SEASONS := {
	"summer": {
		"label": "Лето",
		"grass": GROUND_GRASS, "grass_dry": GROUND_GRASS_DRY, "asphalt": GROUND_ASPHALT,
		"paving": GROUND_PAVING, "dirt": GROUND_DIRT, "courtyard": GROUND_COURTYARD,
		"water": GROUND_WATER, "rail": GROUND_RAIL,
		"birch": TREE_BIRCH, "poplar": TREE_POPLAR, "bushes": true,
		"grass_tint": Color(0.66, 0.78, 0.56), "asphalt_tint": Color.WHITE,
		"sky_top": Color(0.45, 0.55, 0.68), "sky_horizon": Color(0.78, 0.74, 0.66),
		"sun_rotation": Vector3(-55.0, -30.0, 0.0), "sun_color": Color(1.0, 0.97, 0.92), "sun_energy": 1.3,
		"ambient": 0.6, "fog_color": Color(0.78, 0.82, 0.86), "fog_density": 0.00008,
		"saturation": 0.95, "contrast": 1.12, "weather": "",
	},
	"autumn": {
		"label": "Осень",
		"grass": GROUND_GRASS, "grass_dry": GROUND_GRASS_DRY, "asphalt": GROUND_ASPHALT,
		"paving": GROUND_PAVING, "dirt": GROUND_DIRT, "courtyard": GROUND_COURTYARD,
		"water": GROUND_WATER, "rail": GROUND_RAIL,
		"birch": TREE_BIRCH_OCTOBER, "poplar": TREE_POPLAR_OCTOBER, "bushes": true,
		"grass_tint": Color(0.86, 0.74, 0.52), "asphalt_tint": Color.WHITE,
		"sky_top": Color(0.5, 0.55, 0.62), "sky_horizon": Color(0.78, 0.72, 0.64),
		"sun_rotation": Vector3(-42.0, -30.0, 0.0), "sun_color": Color(1.0, 0.9, 0.78), "sun_energy": 1.15,
		"ambient": 0.55, "fog_color": Color(0.8, 0.76, 0.7), "fog_density": 0.00025,
		"saturation": 1.0, "contrast": 1.1, "weather": "leaves",
	},
	"winter": {
		"label": "Зима",
		"grass": GROUND_SNOW_GRASS, "grass_dry": GROUND_SNOW_GRASS_DRY, "asphalt": GROUND_SNOW_ASPHALT,
		"paving": GROUND_SNOW_PAVING, "dirt": GROUND_SNOW_DIRT, "courtyard": GROUND_SNOW_GRASS,
		"water": GROUND_WATER, "rail": GROUND_RAIL,
		"birch": TREE_BIRCH_WINTER, "poplar": TREE_POPLAR_WINTER, "bushes": false,
		"grass_tint": Color(0.82, 0.86, 0.92), "asphalt_tint": Color(0.5, 0.53, 0.6),
		"sky_top": Color(0.5, 0.56, 0.66), "sky_horizon": Color(0.74, 0.78, 0.84),
		"sun_rotation": Vector3(-30.0, -30.0, 0.0), "sun_color": Color(0.9, 0.94, 1.0), "sun_energy": 1.15,
		"ambient": 0.5, "fog_color": Color(0.78, 0.82, 0.88), "fog_density": 0.0003,
		"saturation": 0.8, "contrast": 1.22, "weather": "snow",
	},
}

# Camera targets and rendering geometry use metres directly.
const BOUNDS := Rect2(-620, -460, 1070, 880)
const ZOOM_MIN := 80.0
const ZOOM_MAX := 1550.0
const ZOOM_DEFAULT := 350.0
const DEFAULT_TARGET := Vector3(30, 0, 105)
const PAN_SPEED := 1.1 # Fraction of the zoom distance per second for keyboard panning.

# The two cameras. "elevation" is the angle above the ground in degrees: for an
# axis at 45 degrees yaw, a ground line's slope on screen equals sin(elevation),
# so 30 degrees gives the classic 2:1 isometric slope of 0.5.
const CAMERA_VIEWS := {
	# True isometric: elevation atan(1 / sqrt(2)), so all three axes are foreshortened
	# equally and ground lines run at 30 degrees (slope 0.577). Use 30.0 for the
	# 2:1 game isometric (slope 0.5) the painted sprites measure closer to.
	"iso": {"yaw": 45.0, "elevation": 35.264, "orthographic": true},
	"front": {"yaw": 0.0, "elevation": 48.5, "orthographic": false},
}

var sim
var camera: Camera3D
var _camera_target := DEFAULT_TARGET
var _camera_goal := DEFAULT_TARGET
var _zoom := ZOOM_DEFAULT
var _dragging := false
var _tokens := {} # actor id -> Node3D
var _overlays := {} # "lot:name" -> Node3D
var _lot_states := {} # lot -> {state -> Node3D}
var _occupied: Array[Rect2] = [] # Ground taken by buildings and roads; trees avoid it.
var _road_paint_material: ShaderMaterial
var _lot_labels: Node3D
var _ambient: AmbientLife # Background pedestrians and cars wandering the road graph.
var _hero_car: Node3D # The administration car; shown while you ride with Tolik.
var _token_discs := {} # actor id -> disc under the token, hidden while riding.
var _graph_overlay: Node3D # Dev view of the road graph and active routes (F10).
var _route_mesh: ImmediateMesh
var _materials := {}
var _grounded_props := GroundedProps.new()
var _garage_model := GarageModel.new()
var _rng := RandomNumberGenerator.new()
var _season: Dictionary
var _weather: CPUParticles3D # Snow or falling leaves, following the camera.


func setup(week_sim) -> void:
	sim = week_sim
	_season = SEASONS[Settings.season]
	_rng.seed = 7
	_build_environment()
	_build_weather()
	var builder := DistrictBuilder.new()
	builder.build(self)
	_lot_labels = builder.labels
	# Whoever starts at a lot with a doorstep stands there, not at the entrance.
	for id in sim.actors:
		var actor: Dictionary = sim.actors[id]
		var layout: String = Week1.LOTS[actor["lot"]]["layout"]
		if sim.graph.doorsteps.has(layout) and actor["pos"] == sim.graph.entrance_position(layout):
			actor["pos"] = sim.graph.doorsteps[layout]
	_build_traffic()
	_build_sidewalks()
	_build_street_furniture()
	_build_ambient()
	_build_graph_overlay()
	_build_overlays()
	_build_trees()
	_build_bushes()
	_build_tokens()
	sim.overlay_changed.connect(_on_overlay_changed)
	sim.lot_state_changed.connect(_on_lot_state_changed)
	for lot in sim.lot_states:
		_on_lot_state_changed(lot, sim.lot_states[lot])
	_update_camera()


func _process(delta: float) -> void:
	if sim == null:
		return
	_pan_with_keys(delta)
	_camera_target = _camera_target.lerp(_camera_goal, min(1.0, delta * 8.0))
	_update_camera()
	_move_tokens()
	_update_hero_car(delta)
	_move_ambient(delta)
	if _graph_overlay.visible:
		_draw_routes()
	if _weather != null:
		_weather.global_position = _camera_target + Vector3(0, 80, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		zoom_by(1.0 / maxf(event.factor, 0.01))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode in [KEY_PLUS, KEY_EQUAL]:
			zoom_by(0.8)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_MINUS:
			zoom_by(1.25)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_HOME:
			reset_view()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		_lot_labels.visible = not _lot_labels.visible
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_graph_overlay.visible = not _graph_overlay.visible
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		Settings.camera_mode = "front" if Settings.camera_mode == "iso" else "iso"
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_by(0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_by(1.1)
		elif event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		# Drag the map: move the target against the mouse, scaled by zoom and
		# turned into the camera's own right and forward directions.
		var per_pixel := _zoom / 900.0
		_set_goal(_camera_goal + (-_view_right() * event.relative.x + _view_forward() * event.relative.y) * per_pixel)
		_camera_target = _camera_goal


# Screen position of a lot marker; the HUD places buttons there.
func lot_screen_position(lot: String, height: float = 16.0) -> Vector2:
	var pos: Vector2 = Week1.location_position(lot)
	return camera.unproject_position(Vector3(pos.x, height, pos.y))


# Screen position of a ground point given in map metres.
func ground_screen_position(at: Vector2, height: float = 0.0) -> Vector2:
	return camera.unproject_position(Vector3(at.x, height, at.y))


# Where a person stands on screen (their feet), for the HUD to draw the token.
func token_screen_position(actor_id: String) -> Vector2:
	return camera.unproject_position(_tokens[actor_id].position)


# Smoothly moves the camera to a lot, e.g. when a crisis starts off-screen.
func focus_on(lot: String) -> void:
	var pos: Vector2 = Week1.location_position(lot)
	_zoom = minf(_zoom, ZOOM_DEFAULT)
	_set_goal(Vector3(pos.x, 0, pos.y))


# --- Camera ------------------------------------------------------------------

func zoom_by(factor: float) -> void:
	_zoom = clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)


func zoom_percent() -> int:
	return roundi(ZOOM_DEFAULT / _zoom * 100.0)


func reset_view() -> void:
	var pos: Vector2 = sim.actors["me"]["pos"]
	_zoom = ZOOM_DEFAULT
	_set_goal(Vector3(pos.x, 0, pos.y))


func show_overview() -> void:
	var center := BOUNDS.get_center()
	_zoom = ZOOM_MAX
	_set_goal(Vector3(center.x, 0, center.y))


func _pan_with_keys(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		direction += _view_forward()
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		direction -= _view_forward()
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		direction -= _view_right()
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		direction += _view_right()
	if direction != Vector3.ZERO:
		_set_goal(_camera_goal + direction.normalized() * _zoom * PAN_SPEED * delta)


# "Up" and "right" on the screen, as directions on the ground.
func _view_forward() -> Vector3:
	var yaw := deg_to_rad(CAMERA_VIEWS[Settings.camera_mode]["yaw"])
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _view_right() -> Vector3:
	var yaw := deg_to_rad(CAMERA_VIEWS[Settings.camera_mode]["yaw"])
	return Vector3(cos(yaw), 0.0, -sin(yaw))


func _set_goal(goal: Vector3) -> void:
	_camera_goal = Vector3(
		clamp(goal.x, BOUNDS.position.x, BOUNDS.end.x), 0.0,
		clamp(goal.z, BOUNDS.position.y, BOUNDS.end.y))


func _update_camera() -> void:
	var view: Dictionary = CAMERA_VIEWS[Settings.camera_mode]
	var yaw := deg_to_rad(view["yaw"])
	var elevation := deg_to_rad(view["elevation"])
	var direction := Vector3(sin(yaw) * cos(elevation), sin(elevation), cos(yaw) * cos(elevation))
	camera.position = _camera_target + direction * _zoom
	camera.look_at(_camera_target)
	# The painted sprites are isometric: an orthographic camera keeps every
	# building and prop at one scale and slope instead of bending toward the edges.
	var visible_height := _zoom * 0.573 # What the 32 degree perspective camera shows at the target.
	if view["orthographic"]:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = visible_height
		camera.near = 1.0
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 32.0
		camera.near = 0.05
	# The full-width map no longer reserves a permanent sidebar.
	camera.h_offset = 0.0
	camera.v_offset = -visible_height * 0.03



# --- Environment -------------------------------------------------------------

func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = _season["sky_top"]
	sky_material.sky_horizon_color = _season["sky_horizon"]
	sky_material.ground_horizon_color = _season["sky_horizon"].darkened(0.2)
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = _season["ambient"]
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ssao_enabled = true
	environment.ssao_radius = 2.0
	environment.ssao_intensity = 2.5
	# The map is a calm backdrop, so game elements on top can stand out: little
	# haze and slightly muted colors in every season.
	environment.fog_enabled = true
	environment.fog_light_color = _season["fog_color"]
	environment.fog_density = _season["fog_density"] / 3.0
	environment.adjustment_enabled = true
	environment.adjustment_contrast = _season["contrast"]
	environment.adjustment_saturation = _season["saturation"]

	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	# The sun follows the season: high and white in summer, lower and warmer in
	# autumn, low and cool in winter.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = _season["sun_rotation"]
	sun.light_color = _season["sun_color"]
	sun.light_energy = _season["sun_energy"]
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 2200.0
	add_child(sun)

	camera = Camera3D.new()
	camera.fov = 32.0
	camera.far = 5000.0
	add_child(camera)


# Snow in winter, falling leaves in autumn: a box of particles that hovers
# above wherever the camera looks.
func _build_weather() -> void:
	var kind: String = _season["weather"]
	if kind == "":
		return
	_weather = CPUParticles3D.new()
	_weather.local_coords = false
	_weather.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_weather.emission_box_extents = Vector3(190, 1, 130)
	_weather.direction = Vector3(0, -1, 0)
	var quad := QuadMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	if kind == "snow":
		_weather.amount = 1600
		_weather.lifetime = 9.0
		_weather.gravity = Vector3(0, -3.0, 0)
		_weather.spread = 20.0
		_weather.initial_velocity_min = 0.5
		_weather.initial_velocity_max = 1.5
		quad.size = Vector2(0.5, 0.5)
		material.albedo_color = Color(1, 1, 1)
	else:
		_weather.amount = 240
		_weather.lifetime = 11.0
		_weather.gravity = Vector3(0, -1.9, 0)
		_weather.spread = 60.0
		_weather.initial_velocity_min = 0.5
		_weather.initial_velocity_max = 2.5
		quad.size = Vector2(0.8, 0.5)
		material.albedo_color = Color(0.85, 0.5, 0.14)
	quad.material = material
	_weather.mesh = quad
	_weather.preprocess = _weather.lifetime
	add_child(_weather)


# Boiler visual states are lot-local and follow the same recipe as its dressing.
func _build_boiler_states(center: Vector2, entry: Dictionary) -> void:
	var base := _ground(center)
	var footprint: Vector2 = entry["footprint"]
	var chimney := center
	for prop in entry["dressing"]:
		if prop["sprite"] == "boiler_chimney":
			chimney += prop["at"]
	var repairing := Node3D.new()
	repairing.name = "BoilerRepairing"
	add_child(repairing)
	for i in 3:
		_sprite(SCAFFOLDING, base + Vector3(-10 + i * 10, 0, footprint.y / 2 + 1.5), 9.0, repairing)
	_box(Vector3(footprint.x + 8, 2, 0.2), base + Vector3(0, 1, footprint.y / 2 + 6), Color(0.85, 0.5, 0.2), repairing)
	_prop(CRANE_TRUCK, base + Vector3(footprint.x / 2 + 7, 0, footprint.y / 2 + 5), 9.0, "x", repairing)
	repairing.visible = false
	var working := Node3D.new()
	working.name = "BoilerWorking"
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


# Parked cars follow road geometry; site-specific vehicles are catalog dressing.
func _build_traffic() -> void:
	for road in DistrictLayout.ROADS:
		if road["kind"] != "asphalt":
			continue
		var rect: Rect2 = road["rect"]
		var along_x := rect.size.x > rect.size.y
		var length := maxf(rect.size.x, rect.size.y)
		for i in range(1, int(length / 100.0)):
			# A car's centre sits 0.95 m inside the road edge: parked at the kerb.
			var at := rect.position + (Vector2(i * 100, rect.size.y - 0.95) if along_x else Vector2(rect.size.x - 0.95, i * 100))
			var look := i * 5 + int(length) + i * 977
			_vehicle(VehicleModels.traffic_model(look), _ground(at) + Vector3.UP * 0.14, 4.3, "x" if along_x else "z", null, look)


# Pavements are derived from the roads: a strip on each side, cut wherever another
# road crosses. A ground_sidewalk.png texture replaces the placeholder colour.
func _build_sidewalks() -> void:
	var texture_path := "res://assets/textures/ground_sidewalk.png"
	var texture: Texture2D = load(texture_path) if ResourceLoader.exists(texture_path) else null
	for road in DistrictLayout.ROADS:
		var width := DistrictLayout.sidewalk_width(road)
		if width <= 0.0:
			continue
		var rect: Rect2 = road["rect"]
		var along_x := rect.size.x > rect.size.y
		for side in [-1.0, 1.0]:
			var strip: Rect2
			if along_x:
				strip = Rect2(rect.position.x, rect.position.y - width if side < 0 else rect.end.y, rect.size.x, width)
			else:
				strip = Rect2(rect.position.x - width if side < 0 else rect.end.x, rect.position.y, width, rect.size.y)
			for piece in _strip_pieces(strip, along_x, road):
				_ground_quad(piece.get_center(), piece.size, 0.15, texture, 4.0, false, Color.WHITE if texture != null else SIDEWALK_PLACEHOLDER)


# The strip minus every other road it runs into, as a list of rects.
func _strip_pieces(strip: Rect2, along_x: bool, own: Dictionary) -> Array[Rect2]:
	var cuts: Array[Vector2] = []
	for other in DistrictLayout.ROADS:
		if other == own:
			continue
		var rect: Rect2 = other["rect"]
		if rect.intersects(strip):
			cuts.append(Vector2(rect.position.x, rect.end.x) if along_x else Vector2(rect.position.y, rect.end.y))
	cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var pieces: Array[Rect2] = []
	var from := strip.position.x if along_x else strip.position.y
	var to := strip.end.x if along_x else strip.end.y
	var cursor := from
	for cut in cuts:
		if cut.x - cursor > 0.5:
			pieces.append(_strip_piece(strip, along_x, cursor, minf(cut.x, to)))
		cursor = maxf(cursor, cut.y)
	if to - cursor > 0.5:
		pieces.append(_strip_piece(strip, along_x, cursor, to))
	return pieces


func _strip_piece(strip: Rect2, along_x: bool, from: float, to: float) -> Rect2:
	if along_x:
		return Rect2(from, strip.position.y, to - from, strip.size.y)
	return Rect2(strip.position.x, from, strip.size.x, to - from)


func _build_street_furniture() -> void:
	for road in DistrictLayout.ROADS:
		if road["kind"] != "asphalt":
			continue
		var rect: Rect2 = road["rect"]
		var along_x := rect.size.x > rect.size.y
		var length := maxf(rect.size.x, rect.size.y)
		for i in range(1, int(length / 40.0)):
			var offset := Vector2(i * 40, -2) if along_x else Vector2(-2, i * 40)
			var at := rect.position + offset
			if not _is_occupied(at, 0.5):
				_sprite(LAMP_POST, _ground(at), 6.0)


func _build_bushes() -> void:
	if not _season["bushes"]:
		return
	for lot in DistrictLayout.LOTS.values():
		if lot["type"] not in ["W", "K", "D"]:
			continue
		var rect: Rect2 = lot["rect"]
		for i in 6:
			var at := rect.position + Vector2(_rng.randf_range(1, rect.size.x - 1), _rng.randf_range(1, rect.size.y - 1))
			if not _is_occupied(at, 1.0):
				_sprite(BUSH, _ground(at), _rng.randf_range(2.5, 4.0), null, _rng.randf() < 0.5)


func _build_overlays() -> void:
	var picket := Node3D.new()
	add_child(picket)
	var block5 := Week1.location_position("block5")
	var housing: Dictionary = DistrictLayout.LOTS[Week1.LOTS["block5"]["layout"]]
	var front: Vector2 = {"n": Vector2.UP, "s": Vector2.DOWN, "e": Vector2.RIGHT, "w": Vector2.LEFT}[housing["facing"]]
	# The protest faces the public street, opposite the inward-facing courtyard.
	# It stays visible beside the block instead of hiding behind its north wall.
	_sprite(PICKET_GROUP, _ground(block5 - front * 12), 12.0, picket)
	picket.visible = false
	_overlays["block5:picket"] = picket
	var truck := Node3D.new()
	add_child(truck)
	var boiler := Week1.location_position("boiler")
	var recipe: Dictionary = BuildingCatalog.CONTENTS[DistrictLayout.LOTS[Week1.LOTS["boiler"]["layout"]]["content"]]
	for prop in recipe["dressing"]:
		if prop["sprite"] == "coal_heap":
			_prop(TRUCK_ZIL, _ground(boiler + prop["at"] + Vector2(13, 3)), 8.5, "z", truck)
	truck.visible = false
	_overlays["boiler:truck"] = truck


func _build_trees() -> void:
	# Reserved cores get younger, sparse trees; village gardens keep older growth.
	for id in DistrictLayout.LOTS:
		var lot: Dictionary = DistrictLayout.LOTS[id]
		if id == "b1_k" or lot["type"] not in ["K", "D", "R"]:
			continue
		var rect: Rect2 = lot["rect"]
		var count := 22 if lot["type"] == "K" else 10
		for i in count:
			var at := rect.position + Vector2(_rng.randf_range(3, rect.size.x - 3), _rng.randf_range(3, rect.size.y - 3))
			if not _is_occupied(at, 4.0):
				var tree := _tree(_ground(at))
				if lot["type"] == "K" and lot["condition"] == "kept":
					tree.scale *= 0.65
					tree.position.y *= 0.65
	for road in DistrictLayout.ROADS:
		var rect: Rect2 = road["rect"]
		if road["kind"] == "dirt":
			continue
		var along_x := rect.size.x > rect.size.y
		for i in range(1, int(maxf(rect.size.x, rect.size.y) / 26.0)):
			var at := rect.position + (Vector2(i * 26, rect.size.y + 6) if along_x else Vector2(rect.size.x + 6, i * 26))
			if not _is_occupied(at, 3.0):
				_tree(_ground(at))


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
		_token_discs[id] = disc
		# The face itself is drawn by the HUD, crisp and unaffected by map lighting.
		var start: Vector2 = sim.actors[id]["pos"]
		token.position = Vector3(start.x, 0, start.y + 6)
		_tokens[id] = token
	_hero_car = _vehicle("lada", Vector3.ZERO, 4.3, "z", null, 2)
	_hero_car.visible = false


# When you travel with Tolik you sit in the car: it drives the route and the
# discs under both of you disappear. On foot there is no car.
func _update_hero_car(delta: float) -> void:
	var me: Dictionary = sim.actors["me"]
	var riding: bool = me["state"] == "travel" and me["driver"]
	_hero_car.visible = riding
	_token_discs["me"].visible = not riding
	_token_discs["tolik"].visible = not riding
	if not riding:
		return
	var pos: Vector2 = me["pos"]
	var path: PackedVector2Array = me["path"]
	var index: int = me["path_index"]
	_hero_car.position = Vector3(pos.x, 0.14, pos.y)
	if index < path.size() and pos.distance_to(path[index]) > 0.01:
		var heading := path[index] - pos
		_hero_car.rotation.y = lerp_angle(_hero_car.rotation.y, atan2(heading.x, heading.y), minf(1.0, delta * 8.0))


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
			# Spread along the screen's horizontal so faces never overlap, whatever
			# the camera angle.
			var origin := _ground(pos)
			var pixels_per_metre := camera.unproject_position(origin).distance_to(camera.unproject_position(origin + _view_right()))
			var world_gap := 72.0 / maxf(pixels_per_metre, 0.001)
			var spread := (i - (ids.size() - 1) / 2.0) * world_gap
			var token: Node3D = _tokens[ids[i]]
			var spot := Vector3(pos.x, 0.0, pos.y) + _view_right() * spread - _view_forward() * 6.0
			token.position = token.position.lerp(spot, 0.35)


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


# --- Ground and street details -----------------------------------------------

func _ground_quad(center: Vector2, size: Vector2, y: float, texture: Texture2D, tile: float, turned: bool = false, tint: Color = Color.WHITE) -> void:
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
	instance.position = Vector3(center.x, y, center.y)
	add_child(instance)


# Paint dimensions are in world metres, independent of any image canvas.
func _paint_patch(size: Vector2, at: Vector2, y: float) -> void:
	if _road_paint_material == null:
		_road_paint_material = ShaderMaterial.new()
		_road_paint_material.shader = ROAD_PAINT_SHADER
	var quad := QuadMesh.new()
	quad.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = _road_paint_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.rotation.x = -PI / 2.0
	instance.position = Vector3(at.x, y, at.y)
	add_child(instance)


# A crossing spans the road; each narrow bar runs along the direction of travel.
func _crosswalk(at: Vector2, road_width: float, along_z: bool, y: float) -> void:
	const BAR := 0.45
	const GAP := 0.45
	const DEPTH := 3.5
	var count := int((road_width - 1.0 + GAP) / (BAR + GAP))
	for i in count:
		var offset := (i - (count - 1) / 2.0) * (BAR + GAP)
		var shift := Vector2(offset, 0) if along_z else Vector2(0, offset)
		var size := Vector2(BAR, DEPTH) if along_z else Vector2(DEPTH, BAR)
		_paint_patch(size, at + shift, y)


func _build_road_markings() -> void:
	for road in DistrictLayout.ROADS:
		if road["kind"] != "asphalt":
			continue
		var rect: Rect2 = road["rect"]
		var along_x := rect.size.x > rect.size.y
		var length := maxf(rect.size.x, rect.size.y)
		var width := minf(rect.size.x, rect.size.y)
		var start := rect.position + (Vector2(0, width / 2) if along_x else Vector2(width / 2, 0))
		for i in range(1, int(length / 8.0)):
			var at := start + (Vector2(i * 8, 0) if along_x else Vector2(0, i * 8))
			var junction := false
			for other in DistrictLayout.ROADS:
				if other != road and other["rect"].grow(6).has_point(at):
					junction = true
			if not junction:
				_paint_patch(Vector2(3, 0.12) if along_x else Vector2(0.12, 3), at, 0.145)
	# Crossings on the civic axis, derived from its road intersections.
	for axis in DistrictLayout.ROADS:
		if axis.get("id", "") != "axis":
			continue
		var axis_rect: Rect2 = axis["rect"]
		for road in DistrictLayout.ROADS:
			var rect: Rect2 = road["rect"]
			if rect.size.x > rect.size.y and road["kind"] == "asphalt" and rect.intersects(axis_rect):
				for side in [-1.0, 1.0]:
					_crosswalk(Vector2(axis_rect.get_center().x, rect.get_center().y + side * (rect.size.y / 2 + 3)), axis_rect.size.x, true, 0.145)


const SIDEWALK_PLACEHOLDER := Color("8f8b80")
const AMBIENT_WALKERS := 36
const AMBIENT_CARS := 60


func _build_ambient() -> void:
	_ambient = AmbientLife.new(sim.graph, 1997)
	# Their own RNG: the look of background life must not shift the trees built later.
	var look := RandomNumberGenerator.new()
	look.seed = 2026
	for i in AMBIENT_WALKERS:
		var agent := _ambient.add(false, look.randf_range(1.6, 2.4))
		if agent.is_empty():
			break
		var person: Dictionary = PEOPLE[look.randi() % PEOPLE.size()]
		var sprite := _sprite(person["texture"], _ground(agent["pos"]), person["width"])
		agent["visual"] = sprite
		agent["lift"] = sprite.position.y
	for i in AMBIENT_CARS:
		var agent := _ambient.add(true, look.randf_range(7.0, 12.0))
		if agent.is_empty():
			break
		var seed_value := look.randi()
		agent["visual"] = _vehicle(VehicleModels.traffic_model(seed_value), _ground(agent["pos"]) + Vector3.UP * 0.14, 4.3, "z", null, seed_value)


func _move_ambient(delta: float) -> void:
	_ambient.step(delta)
	var right := _view_right()
	for agent in _ambient.agents:
		var at: Vector2 = agent["pos"]
		var heading: Vector2 = agent["heading"]
		if agent["is_car"]:
			var car: Node3D = agent["visual"]
			car.position = Vector3(at.x, 0.14, at.y)
			car.rotation.y = lerp_angle(car.rotation.y, atan2(heading.x, heading.y), minf(1.0, delta * 6.0))
		else:
			var sprite: Sprite3D = agent["visual"]
			sprite.position = Vector3(at.x, agent["lift"], at.y)
			# Face the way they walk as seen on screen.
			sprite.flip_h = heading.x * right.x + heading.y * right.z < 0.0


# --- Dev overlay: the road graph (F10, or --graph) -----------------------------

const GRAPH_COLORS := {
	"asphalt": Color(0.35, 0.8, 1.0), "dirt": Color(1.0, 0.6, 0.2),
	"yard": Color(0.4, 0.9, 0.4), "access": Color(1.0, 0.3, 0.9),
}


func _build_graph_overlay() -> void:
	_graph_overlay = Node3D.new()
	_graph_overlay.name = "RoadGraphOverlay"
	_graph_overlay.visible = OS.get_cmdline_user_args().has("--graph")
	add_child(_graph_overlay)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.no_depth_test = true
	material.render_priority = 10
	var graph_mesh := ImmediateMesh.new()
	graph_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for edge in sim.graph.edges:
		_ribbon(graph_mesh, sim.graph.points[edge["a"]], sim.graph.points[edge["b"]], 1.2, GRAPH_COLORS[edge["kind"]], 0.5)
	for point in sim.graph.points:
		_ribbon(graph_mesh, point - Vector2(2, 0), point + Vector2(2, 0), 4.0, Color.WHITE, 0.6)
	graph_mesh.surface_end()
	var graph_node := MeshInstance3D.new()
	graph_node.mesh = graph_mesh
	graph_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_graph_overlay.add_child(graph_node)
	_route_mesh = ImmediateMesh.new()
	var route_node := MeshInstance3D.new()
	route_node.mesh = _route_mesh
	route_node.material_override = material
	route_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_graph_overlay.add_child(route_node)


func _draw_routes() -> void:
	_route_mesh.clear_surfaces()
	var any := false
	for id in sim.actors:
		if id == "tolik":
			continue
		var route: PackedVector2Array = sim.actor_route(id)
		if route.size() < 2:
			continue
		if not any:
			_route_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			any = true
		for i in route.size() - 1:
			_ribbon(_route_mesh, route[i], route[i + 1], 2.4, Color(1.0, 0.9, 0.2), 0.8)
	if any:
		_route_mesh.surface_end()


func _ribbon(mesh: ImmediateMesh, from: Vector2, to: Vector2, width: float, color: Color, y: float) -> void:
	var side := (to - from).normalized().orthogonal() * width * 0.5
	var corners := [from - side, from + side, to + side, to - side]
	for index in [0, 1, 2, 0, 2, 3]:
		mesh.surface_set_color(color)
		mesh.surface_add_vertex(Vector3(corners[index].x, y, corners[index].y))


# A panel volume has exact 3 m storeys; surfaces are resolved by the catalog.
func _panel_block(size: Vector2, floors: int, tint: Color, parent: Node3D) -> void:
	var height := floors * 3.0
	_box(Vector3(size.x, height, size.y), Vector3(0, height / 2, 0), tint, parent)
	_box(Vector3(size.x + 0.6, 0.4, size.y + 0.6), Vector3(0, height + 0.2, 0), PANEL_ROOF, parent)


func _panel_overlays(entry: Dictionary, size: Vector2, height: float, parent: Node3D) -> void:
	var base_path: String = entry.get("entrance_base", "")
	var stair_path: String = entry.get("stair", "")
	var shop_path: String = entry.get("ground_floor", "")
	for i in int(size.x / 24):
		var x := -size.x / 2 + 12 + i * 24
		var ground_path := shop_path if i == 0 and shop_path != "" else base_path
		if ground_path != "" and ResourceLoader.exists(ground_path):
			_facade(Vector2(6, 3), Vector3(x, 1.5, size.y / 2 + 0.03), 0, load(ground_path), Vector2.ONE, Color.WHITE, parent)
		if stair_path != "" and ResourceLoader.exists(stair_path):
			for floor_index in range(1, int(height / 3)):
				_facade(Vector2(6, 3), Vector3(x, floor_index * 3 + 1.5, size.y / 2 + 0.03), 0, load(stair_path), Vector2.ONE, Color.WHITE, parent)


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
		if spot.distance_to(Week1.location_position(lot)) < 10.0:
			return true
	# Keep the river and the far bank free of trees.
	return spot.y < DistrictLayout.WATER.end.y


# --- Shape helpers -----------------------------------------------------------

func _windows(base: Vector3, footprint: Vector2, floors: int, per_row: int, floor_height: float) -> void:
	var spacing: float = footprint.x / float(per_row)
	var end_windows: int = maxi(2, int(footprint.y / 3.5))
	var end_spacing: float = footprint.y / float(end_windows)
	for floor_index in floors:
		var window_y: float = floor_index * floor_height + floor_height * 0.55
		for i in per_row:
			var x: float = -footprint.x / 2.0 + spacing * (i + 0.5)
			for side in [-1.0, 1.0]:
				_box(Vector3(spacing * 0.45, floor_height * 0.45, 0.1), base + Vector3(x, window_y, side * (footprint.y / 2.0 + 0.05)), WINDOW)
		for i in end_windows:
			var z: float = -footprint.y / 2.0 + end_spacing * (i + 0.5)
			for side in [-1.0, 1.0]:
				_box(Vector3(0.1, floor_height * 0.45, end_spacing * 0.45), base + Vector3(side * (footprint.x / 2.0 + 0.05), window_y, z), WINDOW)


func _tree(at: Vector3) -> Sprite3D:
	# Painted tree sprite standing upright and turning toward the camera:
	# mostly birches, with taller poplars for variety.
	var poplar := _rng.randf() < 0.25
	var height := _rng.randf_range(13.0, 18.0) if poplar else _rng.randf_range(9.0, 13.0)
	var sprite := Sprite3D.new()
	sprite.texture = _season["poplar"] if poplar else _season["birch"]
	sprite.pixel_size = height / sprite.texture.get_height()
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.shaded = true
	sprite.modulate = Color(1, 1, 1).lerp(Color(0.92, 0.95, 0.8), _rng.randf())
	sprite.position = at + Vector3(0, height / 2.0, 0)
	add_child(sprite)
	return sprite


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
	# The node sits exactly on the ground point and the picture hangs from its
	# measured anchor (see scripts/dev/measure_sprite_anchors.gd), so a long prop
	# stands on the road instead of floating by the empty margin below it.
	var anchor := _anchor_of(texture)
	var anchor_x := (1.0 - anchor.x) if flip else anchor.x
	# With centered off, the offset is the picture's bottom-left corner relative to
	# the node: the anchor is (1 - anchor.y) of the picture above the bottom edge.
	sprite.centered = false
	sprite.offset = Vector2(-anchor_x * texture.get_width(), -(1.0 - anchor.y) * texture.get_height())
	sprite.position = at
	(parent if parent != null else self).add_child(sprite)
	return sprite


# Real vehicle meshes rotate along world axes and share the imported GLB.
func _vehicle(model_id: String, at: Vector3, length: float, axis: String, parent: Node = null, paint: int = -1) -> Node3D:
	var vehicle := VehicleModels.create(model_id, at, length, axis, paint)
	(parent if parent != null else self).add_child(vehicle)
	return vehicle


# A long painted prop mirrored to match a street, rail or river axis.
func _prop(texture: Texture2D, at: Vector3, width: float, axis: String, parent: Node = null) -> Node3D:
	var profile: Dictionary = PropDimensions.PROFILES.get(texture.resource_path.get_file().get_basename(), {})
	if not profile.is_empty():
		var source_axes: Vector2 = profile["axes"]
		var mirror: bool = bool(profile.get("long_axis_positive", false)) != (axis == "x")
		return _grounded_prop(texture, at, float(profile["width"]), mirror, source_axes, parent)
	var drawn := "x" if _slope_of(texture) > 0.0 else "z"
	var slope := _slope_of(texture)
	var axes := Vector2(slope, -0.577) if slope > 0.0 else Vector2(0.577, slope)
	return _grounded_prop(texture, at, width, drawn != axis, axes, parent)


func _grounded_prop(texture: Texture2D, at: Vector3, width: float, flip: bool, axes: Vector2, parent: Node = null) -> Node3D:
	# Calibration describes the fixed orthographic isometric view. Preserve the
	# original billboard rendering for the optional perspective camera.
	if not CAMERA_VIEWS[Settings.camera_mode]["orthographic"]:
		return _sprite(texture, at, width, parent, flip)
	var profile: Dictionary = PropDimensions.PROFILES.get(texture.resource_path.get_file().get_basename(), {})
	var prop := _grounded_props.create(texture, width, flip, _anchor_of(texture), axes, CAMERA_VIEWS[Settings.camera_mode], float(profile.get("height_scale", 1.0)))
	prop.position = at + Vector3(0, 0.12, 0)
	(parent if parent != null else self).add_child(prop)
	return prop


func _anchor_of(texture: Texture2D) -> Vector2:
	var entry: Dictionary = SpriteAnchors.ANCHORS.get(texture.resource_path.get_file().get_basename(), {})
	return entry.get("anchor", Vector2(0.5, 1.0))


func _slope_of(texture: Texture2D) -> float:
	var entry: Dictionary = SpriteAnchors.ANCHORS.get(texture.resource_path.get_file().get_basename(), {})
	return entry.get("slope", 0.0)


# A textured flat roof: a quad facing up, tiled so the roof detail stays small.
func _roof(size: Vector2, at: Vector3, tile: float, texture: Texture2D = ROOF_TAR, parent: Node = null) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.uv1_scale = Vector3(size.x / tile, size.y / tile, 1.0)
	material.roughness = 0.95
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	instance.position = at
	instance.rotation.x = -PI / 2.0
	(parent if parent != null else self).add_child(instance)


# Painted facades on the four sides of a box-shaped building.
func _facades(base: Vector3, size: Vector3, texture: Texture2D, tiles_per_height: float, tint: Color = Color.WHITE, parent: Node = null) -> void:
	var tile_width := size.y * 2.0 / tiles_per_height
	var center_y := size.y / 2.0
	_facade(Vector2(size.x, size.y), base + Vector3(0, center_y, size.z / 2.0 + 0.01), 0.0, texture, Vector2(size.x / tile_width, tiles_per_height), tint, parent)
	_facade(Vector2(size.x, size.y), base + Vector3(0, center_y, -size.z / 2.0 - 0.01), PI, texture, Vector2(size.x / tile_width, tiles_per_height), tint, parent)
	_facade(Vector2(size.z, size.y), base + Vector3(size.x / 2.0 + 0.01, center_y, 0), PI / 2.0, texture, Vector2(size.z / tile_width, tiles_per_height), tint, parent)
	_facade(Vector2(size.z, size.y), base + Vector3(-size.x / 2.0 - 0.01, center_y, 0), -PI / 2.0, texture, Vector2(size.z / tile_width, tiles_per_height), tint, parent)


# One textured wall: a quad facing +Z, turned by yaw around the vertical axis.
func _facade(size: Vector2, at: Vector3, yaw: float, texture: Texture2D, tiles: Vector2, tint: Color = Color.WHITE, parent: Node = null) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = tint
	material.uv1_scale = Vector3(tiles.x, tiles.y, 1.0)
	material.roughness = 0.95
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	instance.position = at
	instance.rotation.y = yaw
	(parent if parent != null else self).add_child(instance)


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
