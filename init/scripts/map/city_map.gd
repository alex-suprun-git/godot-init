# The 3D district view. Geography and building recipes come from data; this
# node owns the camera, environment, actors, lot states and event overlays.
extends Node3D

const DistrictLayout = preload("res://scripts/data/district_layout.gd")
const BuildingCatalog = preload("res://scripts/data/building_catalog.gd")
const DistrictBuilder = preload("res://scripts/map/district_builder.gd")
const WearMask = preload("res://scripts/map/wear_mask.gd")
const Daylight = preload("res://scripts/map/daylight.gd")
const MapEdges = preload("res://scripts/map/map_edges.gd")
const MapBoundaries = preload("res://scripts/data/map_boundaries.gd")
const LIT_FACADE := preload("res://assets/shaders/lit_facade.gdshader")
const BLANK_WALL := preload("res://assets/textures/facade_panel_stair.png") # Concrete source of the windowless gable ends.
# Window cell edges in UV (per picture tile), measured on the facade art; see lit_facade.gdshader.
# Pixel edges / picture size. The 9-storey picture is drawn floor by floor, so it keeps world rows.
const WINDOW_CELLS := {
	"facade_panel_stair": {"rects": [[640.0 / 1774, 258.0 / 887, 1130.0 / 1774, 450.0 / 887, 0.0]]},
	"facade_panel_entrance": {"rects": [[1285.0 / 1774, 140.0 / 887, 1585.0 / 1774, 455.0 / 887, 0.0], [655.0 / 1774, 240.0 / 887, 722.0 / 1774, 302.0 / 887, 1.0]]},
	"facade_panel_late_5storey_lived": {
		"cols": [0.0, 174.0 / 1767, 370.0 / 1767, 543.0 / 1767, 721.0 / 1767, 884.0 / 1767, 1048.0 / 1767, 1228.0 / 1767, 1400.0 / 1767, 1596.0 / 1767, 1.0],
		"wide": [2, 7], "row_origin": 55.0 / 890, "row_pitch": 167.5 / 890,
	},
	"facade_panel_late_9storey_lived": {
		"cols": [0.0, 150.0 / 1774, 308.0 / 1774, 445.0 / 1774, 582.0 / 1774, 737.0 / 1774, 888.0 / 1774, 1037.0 / 1774, 1193.0 / 1774, 1330.0 / 1774, 1470.0 / 1774, 1625.0 / 1774, 1.0],
		"wide": [1, 4, 7, 10], "row_origin": 40.0 / 887, "row_pitch": 111.7 / 887,
	},
}
const Week1 = preload("res://scripts/data/week1.gd")
const Settings = preload("res://scripts/data/settings.gd")
const SpriteAnchors = preload("res://scripts/data/sprite_anchors.gd")
const GroundedProps = preload("res://scripts/map/grounded_props.gd")
const VegetationModels = preload("res://scripts/map/vegetation_models.gd")
const VehicleModels = preload("res://scripts/map/vehicle_models.gd")
const TrafficVehicleModels = preload("res://scripts/map/traffic_vehicle_models.gd")
const AmbientLife = preload("res://scripts/map/ambient_life.gd")
const TrafficIntersections = preload("res://scripts/data/traffic_intersections.gd")
const TrafficLight = preload("res://scripts/map/traffic_light.gd")
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
const MARKET_TENT := preload("res://assets/sprites/market_tent.png")
const SCAFFOLDING := preload("res://assets/sprites/scaffolding.png")
const PEOPLE := [
	{"texture": preload("res://assets/sprites/person_walk_man.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_walk_man"]},
	{"texture": preload("res://assets/sprites/person_walk_woman.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_walk_woman"]},
	{"texture": preload("res://assets/sprites/person_pensioner.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_pensioner"]},
	{"texture": preload("res://assets/sprites/person_worker.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_worker"]},
	{"texture": preload("res://assets/sprites/person_kid.png"), "width": PropDimensions.PEOPLE_WIDTHS["person_kid"]},
]
const PICKET_GROUP := preload("res://assets/sprites/picket_group.png")
const CRANE_TRUCK := preload("res://assets/sprites/crane_truck.png")

# Painted ground tiles, seen from above and seamless; laid on flat patches.
const GROUND_GRASS := preload("res://assets/textures/ground_grass_v2.png")
const GROUND_GRASS_DRY := preload("res://assets/textures/ground_grass_dry_v2.png")
const GROUND_ASPHALT := preload("res://assets/textures/ground_asphalt.png")
const GROUND_PAVING := preload("res://assets/textures/ground_paving.png")
const GROUND_SIDEWALK_SLABS := preload("res://assets/textures/ground_sidewalk_slabs.png")
const GROUND_SIDEWALK_ASPHALT := preload("res://assets/textures/ground_sidewalk_asphalt.png")
const SIDEWALK_SURFACE := preload("res://assets/shaders/sidewalk_surface.gdshader")
const GROUND_DIRT := preload("res://assets/textures/ground_dirt_v2.png")
const GROUND_WATER := preload("res://assets/textures/ground_water.png")
const GROUND_RAIL := preload("res://assets/textures/ground_rail.png")
const GROUND_COURTYARD := preload("res://assets/textures/ground_courtyard.png")
const GROUND_MACRO := preload("res://assets/textures/ground_macro_variation.png") # Grayscale, one tile per 120 m.
const ROAD_PAINT_SHADER := preload("res://assets/shaders/road_paint.gdshader")
const TERRAIN_GROUND_SHADER := preload("res://assets/shaders/terrain_ground.gdshader")
const TERRAIN_EDGE_SHADER := preload("res://assets/shaders/terrain_ground_edge.gdshader")
const GROUND_SNOW_GRASS := preload("res://assets/textures/ground_snow_grass.png")
const GROUND_SNOW_GRASS_DRY := preload("res://assets/textures/ground_snow_grass_dry.png")
const GROUND_SNOW_ASPHALT := preload("res://assets/textures/ground_snow_asphalt.png")
const GROUND_SNOW_PAVING := preload("res://assets/textures/ground_snow_paving.png")
const GROUND_SNOW_DIRT := preload("res://assets/textures/ground_snow_dirt.png")

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
		"bushes": true,
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
		"bushes": true,
		"grass_tint": Color(0.86, 0.74, 0.52), "asphalt_tint": Color.WHITE,
		"sky_top": Color(0.5, 0.55, 0.62), "sky_horizon": Color(0.78, 0.72, 0.64),
		"sun_rotation": Vector3(-42.0, -30.0, 0.0), "sun_color": Color(1.0, 0.9, 0.78), "sun_energy": 1.15,
		"ambient": 0.55, "fog_color": Color(0.8, 0.76, 0.7), "fog_density": 0.00025,
		"saturation": 1.0, "contrast": 1.1, "weather": "",
	},
	"winter": {
		"label": "Зима",
		"grass": GROUND_SNOW_GRASS, "grass_dry": GROUND_SNOW_GRASS_DRY, "asphalt": GROUND_SNOW_ASPHALT,
		"paving": GROUND_SNOW_PAVING, "dirt": GROUND_SNOW_DIRT, "courtyard": GROUND_SNOW_GRASS,
		"water": GROUND_WATER, "rail": GROUND_RAIL,
		"bushes": false,
		"grass_tint": Color(0.82, 0.86, 0.92), "asphalt_tint": Color(0.5, 0.53, 0.6),
		"sky_top": Color(0.5, 0.56, 0.66), "sky_horizon": Color(0.74, 0.78, 0.84),
		"sun_rotation": Vector3(-30.0, -30.0, 0.0), "sun_color": Color(0.9, 0.94, 1.0), "sun_energy": 1.15,
		"ambient": 0.5, "fog_color": Color(0.78, 0.82, 0.88), "fog_density": 0.0003,
		"saturation": 0.8, "contrast": 1.22, "weather": "",
	},
}

# Camera targets and rendering geometry use metres directly.
const BOUNDS := Rect2(-620, -460, 1070, 1015)
const ZOOM_DEFAULT := 350.0 # Camera distance that the zoom readout calls 100 %.
const ZOOM_MIN := ZOOM_DEFAULT / 1.25 # Closest view: 125 %.
const ZOOM_MAX := ZOOM_DEFAULT / 0.30 # Widest view: 30 %.
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
var _ui_input_blocked := false
var _arrival_hour := -1.0
var scenario_traffic := {}
var ambient_motion_scale := 1.0
var _arrival_car := {}
var _arrival_itinerary := {}
var _arrival_marks := PackedFloat32Array()
var _arrival_meeting: Node3D
var _arrival_look_ahead := Vector2.ZERO
var _arrival_focus := Vector2.ZERO
var _arrival_focus_weight := 0.0
var _arrival_follow_zoom := 150.0
var _arrival_subject_zoom := 0.0
var _tokens := {} # actor id -> Node3D
var _overlays := {} # "lot:name" -> Node3D
var _location_states := {} # location -> scheduled state controller, with event override.
var wear: WearMask # Worn-ground sources register here while the district is built.
var _occupied: Array[Rect2] = [] # Ground taken by buildings and roads; trees avoid it.
var _crosswalk_material: ShaderMaterial
var _road_paint_material: ShaderMaterial
var _lot_labels: Node3D
var _ambient: AmbientLife # Background pedestrians and cars wandering the road graph.
var profile_ambient := false
var profile_hide_ambient := false
var profile_skip_ambient := false
var profile_step_ms := 0.0
var profile_visual_ms := 0.0
var _signal_lights: Array[TrafficLight] = []
var _traffic_light_positions := PackedVector2Array()
var _hero_car: Node3D # The administration car; shown while you ride with Tolik.
var _token_discs := {} # actor id -> disc under the token, hidden while riding.
var _graph_overlay: Node3D # Dev view of the road graph and active routes (F10).
var _route_mesh: ImmediateMesh
var _materials := {}
var _grounded_props := GroundedProps.new()
var _garage_model := GarageModel.new()
var _rng := RandomNumberGenerator.new()
var _season: Dictionary
var _sun: DirectionalLight3D
var _sky_material: ProceduralSkyMaterial
var _environment: Environment
var _window_materials: Array[ShaderMaterial] = [] # Facades whose windows glow at night.
var _lamp_glow := {} # "head" / "pool" -> shared additive material.
var _night := -1.0
var _night_hour := -1.0 # While the night plays between days: the hour shown (22..31).
var _debug_hour := -1.0 # Dev: --hour=18.5 pins the clock for lighting checks.
var _weather: CPUParticles3D # Snow or falling leaves, following the camera.
var _edges: Node3D # Full-screen haze that hides the map edges.
var _gateways: Array[Dictionary] = [] # Where ambient cars leave and enter the map.
var _traffic_debug_clock := 0.0


func setup(week_sim) -> void:
	sim = week_sim
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hour="):
			_debug_hour = float(arg.trim_prefix("--hour="))
		elif arg.begins_with("--season=") and SEASONS.has(arg.trim_prefix("--season=")):
			Settings.season = arg.trim_prefix("--season=")
		elif arg.begins_with("--camera-mode=") and Settings.CAMERAS.has(arg.trim_prefix("--camera-mode=")):
			Settings.camera_mode = arg.trim_prefix("--camera-mode=")
	_season = SEASONS[Settings.season]
	_rng.seed = 7
	_build_environment()
	_build_weather()
	wear = WearMask.new(_wear_bounds())
	var builder := DistrictBuilder.new()
	builder.build(self)
	wear.bake()
	_edges = MapEdges.new()
	_edges.name = "MapEdges"
	add_child(_edges)
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
	_build_traffic_lights()
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
	# Start on the hero's actual doorstep, before the first rendered frame.
	var hero_position: Vector2 = sim.actors["me"]["pos"]
	_set_goal(Vector3(hero_position.x, 0.0, hero_position.y))
	_camera_target = _camera_goal
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cam="):
			var parts := arg.trim_prefix("--cam=").split(",")
			if parts.size() == 3:
				_set_goal(Vector3(float(parts[0]), 0.0, float(parts[1])))
				_camera_target = _camera_goal
				_zoom = clampf(float(parts[2]), ZOOM_MIN, ZOOM_MAX)
	_update_camera()


func _process(delta: float) -> void:
	if sim == null:
		return
	_pan_with_keys(delta)
	if _arrival_hour >= 0.0:
		_move_ambient(delta * ambient_motion_scale)
		_follow_arrival(delta)
	var response := 3.6 if _arrival_hour >= 0.0 else 8.0
	_camera_target = _camera_target.lerp(_camera_goal, 1.0 - exp(-delta * response))
	_update_camera()
	_move_tokens()
	_update_hero_car(delta)
	if _arrival_hour < 0.0:
		_move_ambient(delta)
	_update_daylight()
	if _graph_overlay.visible:
		_draw_routes()
	if _weather != null:
		_weather.global_position = _camera_target + Vector3(0, 80, 0)


func _unhandled_input(event: InputEvent) -> void:
	if _ui_input_blocked or _arrival_hour >= 0.0:
		return
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


# Keep map overlays readable, but compact their footprint in the overview.
func map_icon_scale() -> float:
	return clampf(sqrt(ZOOM_DEFAULT / _zoom), 0.78, 1.0)


# Smoothly moves the camera to a lot, e.g. when a crisis starts off-screen.
func focus_on(lot: String) -> void:
	var pos: Vector2 = Week1.location_position(lot)
	_zoom = minf(_zoom, ZOOM_DEFAULT)
	_set_goal(Vector3(pos.x, 0, pos.y))


func begin_arrival(profile: Dictionary) -> void:
	cancel_camera_drag()
	scenario_traffic = profile
	ambient_motion_scale = float(profile.get("motion_scale", 1.0))
	_ambient.hour = 6.0
	_ambient.set_scenario_traffic(scenario_traffic)
	for disc in _token_discs.values():
		disc.hide()
	_arrival_hour = 6.0
	_zoom = 150.0
	_set_goal(Vector3(-97, 0, 346))
	_camera_target = _camera_goal
	_update_camera()


func stage_arrival_meeting() -> void:
	get_node("RailwayTraffic").hold_commuter_at_station()
	_arrival_meeting = Node3D.new()
	add_child(_arrival_meeting)
	for index in 2:
		var person: Dictionary = PEOPLE[0 if index == 0 else 3]
		var at := Vector2(-69.0 + index * 2.3, 356.0)
		_sprite(person["texture"], _ground(at) + Vector3.UP * 0.14, person["width"], _arrival_meeting, index == 0)
	_hero_car.position = _ground(Vector2(-70, 346)) + Vector3.UP * 0.14
	_hero_car.rotation = Vector3(0, -PI / 2.0, 0)
	_hero_car.show()
	_snap_arrival_camera(Vector2(-72, 358), 118.0)


func prepare_arrival_drive(beats: Array) -> bool:
	_arrival_itinerary = _ambient.arrival_itinerary()
	_arrival_marks.clear()
	var at := 0.0
	for beat in beats:
		at = _ambient.arrival_marker(_arrival_itinerary, beat["road"], beat["at"], at)
		if at < 0.0:
			push_error("Arrival cue is out of route order: " + String(beat["id"]))
			return false
		_arrival_marks.append(at)
	return true


func start_arrival_drive() -> void:
	var start := _ambient.arrival_marker(_arrival_itinerary, "station_link", Vector2(-70, 348), 0.0)
	_arrival_car = _ambient.add_arrival_car(float(scenario_traffic.get("driver_speed", 10.0)),
		_arrival_itinerary, start, _arrival_marks[-1])
	if is_instance_valid(_arrival_meeting):
		get_node("RailwayTraffic").release_commuter()
		_arrival_meeting.queue_free()
		_arrival_meeting = null
	_arrival_car["visual"] = _hero_car
	_arrival_look_ahead = Vector2.ZERO
	_arrival_focus_weight = 0.0


func _snap_arrival_camera(at: Vector2, zoom: float) -> void:
	_zoom = zoom
	_set_goal(Vector3(at.x, 0.0, at.y))
	_camera_target = _camera_goal
	_update_camera()


func reached_arrival_mark(index: int, lead := 0.0) -> bool:
	return _ambient.arrival_distance(_arrival_car) >= _arrival_marks[index] - lead - 0.05


func update_arrival(hour: float, focus: Vector2, focus_weight: float, subject_zoom: float) -> void:
	_arrival_hour = hour
	_arrival_focus = focus
	_arrival_focus_weight = focus_weight
	_arrival_subject_zoom = subject_zoom


func _follow_arrival(delta: float) -> void:
	if _arrival_car.is_empty():
		return
	var car := Vector2(_arrival_car["pos"])
	var heading := Vector2(_arrival_car["heading"])
	var lead := heading * minf(9.0, float(_arrival_car["speed"]) * float(_arrival_car["speed_scale"]))
	_arrival_look_ahead = _arrival_look_ahead.lerp(lead, 1.0 - exp(-delta * 2.8))
	var follow := car + _arrival_look_ahead
	var toward_landmark := _arrival_focus - follow
	var target := follow + toward_landmark.limit_length(64.0) * _arrival_focus_weight * 0.82
	if _arrival_subject_zoom > 0.0:
		target = follow.lerp(_arrival_focus, _arrival_focus_weight)
	var subject_zoom := _arrival_subject_zoom if _arrival_subject_zoom > 0.0 else _arrival_follow_zoom
	var zoom_goal := lerpf(_arrival_follow_zoom, subject_zoom, _arrival_focus_weight)
	_zoom = lerpf(_zoom, zoom_goal, 1.0 - exp(-delta * 3.6))
	_set_goal(Vector3(target.x, 0.0, target.y))


func end_arrival() -> void:
	get_node("RailwayTraffic").release_commuter()
	if is_instance_valid(_arrival_meeting):
		_arrival_meeting.queue_free()
	if not _arrival_car.is_empty():
		_ambient.remove_arrival_car(_arrival_car)
	_arrival_car = {}
	scenario_traffic = {}
	ambient_motion_scale = 1.0
	_ambient.set_scenario_traffic(scenario_traffic)
	_arrival_hour = -1.0
	_hero_car.hide()
	_zoom = ZOOM_DEFAULT
	for disc in _token_discs.values():
		disc.show()


# --- Camera ------------------------------------------------------------------

func audio_proximity() -> float:
	# Magnification, not physical camera height: also works for orthographic view.
	return clampf(inverse_lerp(ZOOM_DEFAULT / ZOOM_MAX, ZOOM_DEFAULT / ZOOM_MIN, ZOOM_DEFAULT / _zoom), 0.0, 1.0)


func audio_listener_position() -> Vector3:
	return _camera_target


func cancel_camera_drag() -> void:
	_dragging = false


func zoom_by(factor: float) -> void:
	_zoom = clampf(_zoom * factor, ZOOM_MIN, ZOOM_MAX)


func reset_view() -> void:
	var pos: Vector2 = sim.actors["me"]["pos"]
	_zoom = ZOOM_DEFAULT
	_set_goal(Vector3(pos.x, 0, pos.y))


func show_overview() -> void:
	var center := BOUNDS.get_center()
	_zoom = ZOOM_MAX
	_set_goal(Vector3(center.x, 0, center.y))


func _pan_with_keys(delta: float) -> void:
	if _ui_input_blocked or _arrival_hour >= 0.0:
		return
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
	# Orthographic size controls magnification independently of camera distance.
	# Keep the eye behind nearby tall buildings even at the closest zoom.
	var distance: float = maxf(_zoom, 600.0) if view["orthographic"] else _zoom
	camera.position = _camera_target + direction * distance
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
	_sky_material = sky_material

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

	_environment = environment
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
	_sun = sun
	add_child(sun)

	camera = Camera3D.new()
	camera.fov = 32.0
	camera.far = 5000.0
	add_child(camera)


# Plays the night after returning home, ending at 06:00.
func play_night(seconds: float) -> void:
	_night_hour = sim.last_day_end_hour
	var tween := create_tween()
	var morning := (floorf(_night_hour / 24.0) + 1.0) * 24.0 + Week1.DAY_START_HOUR
	if fmod(_night_hour, 24.0) < Week1.DAY_START_HOUR:
		morning -= 24.0
	tween.tween_property(self, "_night_hour", morning, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func(): _night_hour = -1.0)


# The light follows the clock on screen: sun height, warmth, sky and ambient.
func visual_clock_hour() -> float:
	if _arrival_hour >= 0.0:
		return _arrival_hour
	var hour: float = _debug_hour if _debug_hour >= 0.0 else sim.clock_hour()
	if _night_hour >= 0.0:
		hour = _night_hour
	return fposmod(hour,24.0)

func _update_daylight() -> void:
	var hour := visual_clock_hour()
	var look := Daylight.sample(Settings.season, _season, hour)
	_sun.rotation_degrees = look["sun_rotation"]
	_sun.light_color = look["sun_color"]
	_sun.light_energy = look["sun_energy"]
	_environment.ambient_light_energy = look["ambient"]
	_environment.fog_light_color = look["fog_color"]
	if _edges != null:
		# The haze quad is unshaded, so it carries the dimmed fog colour (already
		# darkened at night) and a further night factor, or it would glow after dark.
		var haze_color: Color = look["fog_color"]
		_edges.set_haze_color(haze_color.darkened(0.55 * float(look["night"])))
	_environment.adjustment_saturation = look["saturation"]
	_sky_material.sky_top_color = look["sky_top"]
	_sky_material.sky_horizon_color = look["sky_horizon"]
	_sky_material.ground_horizon_color = look["sky_horizon"].darkened(0.2)
	_apply_night(look["night"])


# Window glow and street lamps, driven by one number; skipped while it is unchanged.
func _apply_night(night: float) -> void:
	if absf(night - _night) < 0.01:
		return
	_night = night
	for material in _window_materials:
		material.set_shader_parameter("night", night)
	if _lamp_glow.is_empty():
		return
	_lamp_glow["head"].albedo_color.a = night * 0.5
	_lamp_glow["pool"].albedo_color.a = night * 0.26


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


# Parked cars follow road geometry; site-specific vehicles are catalog dressing.
# Parked cars keep clear of junctions by this many metres beyond the crossing road's edge.
const PARKING_CLEARANCE := 25.0


func _build_traffic() -> void:
	for road in DistrictLayout.ROADS:
		# No parking on the highway at all.
		if road["kind"] != "asphalt" or road.get("look", "") == "highway" or road.get("hub_surface", false):
			continue
		var rect: Rect2 = road["rect"]
		var along_x := rect.size.x > rect.size.y
		var length := maxf(rect.size.x, rect.size.y)
		for i in range(1, int(length / 100.0)):
			# A car's centre sits 0.95 m inside the road edge: parked at the kerb.
			var at := rect.position + (Vector2(i * 100, rect.size.y - 0.95) if along_x else Vector2(rect.size.x - 0.95, i * 100))
			if _near_junction(road, at, along_x):
				continue
			var look := i * 5 + int(length) + i * 977
			var model := VehicleModels.traffic_model(look)
			var car_length := VehicleModels.map_length(model)
			var footprint := Vector2(car_length + .8, 2.8) if along_x else Vector2(2.8, car_length + .8)
			if not DistrictLayout.parking_allowed(at, footprint):
				continue
			var parked := _vehicle(model, _ground(at) + Vector3.UP * 0.14, car_length, "x" if along_x else "z", null, look)
			parked.add_to_group("parked_vehicles")
			parked.set_meta("parking_footprint", footprint)


# True when a parking spot lies within PARKING_CLEARANCE of a road crossing or joining this one.
func _near_junction(road: Dictionary, at: Vector2, along_x: bool) -> bool:
	var rect: Rect2 = road["rect"]
	for other in DistrictLayout.ROADS:
		var crossing: Rect2 = other["rect"]
		if other == road or along_x == (crossing.size.x > crossing.size.y) or not rect.intersects(crossing.grow(0.1)):
			continue
		var distance := absf(at.x - crossing.get_center().x) if along_x else absf(at.y - crossing.get_center().y)
		var half := crossing.size.x / 2.0 if along_x else crossing.size.y / 2.0
		if distance < half + PARKING_CLEARANCE:
			return true
	return false


# Pavements retain the road-derived strips/cuts. Only the civic axis south of the
# north cross street uses slabs; the approach towards the river uses asphalt.
# Ordinary roads use pedestrian asphalt. Both share world-aligned material coordinates.
func _build_sidewalks() -> void:
	var winter := Settings.season == "winter"
	var civic_start := _civic_avenue_start()
	# Prepared 1024px source: three slabs between measured joint centres
	# x=12..767, y=36..796. Three 50cm slabs repeat every 1.5m.
	var slab_region := Vector4(12.0 / 1024.0, 36.0 / 1024.0, 755.0 / 1024.0, 760.0 / 1024.0)
	var slabs := _sidewalk_material(GROUND_SIDEWALK_SLABS, 1.5, slab_region)
	var asphalt := _sidewalk_material(GROUND_SIDEWALK_ASPHALT, 4.0)
	slabs.set_shader_parameter("surface_brightness", 0.85)
	asphalt.set_shader_parameter("surface_brightness", 0.65)
	asphalt.set_shader_parameter("mottle_strength", 0.22)
	slabs.set_shader_parameter("winter", winter)
	asphalt.set_shader_parameter("winter", winter)
	slabs.set_shader_parameter("snow_compaction", 0.64)
	asphalt.set_shader_parameter("snow_compaction", 0.82)
	var covered: Array[Rect2] = []
	var sidewalk_roads: Array[Dictionary] = []
	# The civic paving owns shared corners. Subtract already rendered surfaces so
	# crossing strips never put two different materials on the same plane.
	for road in DistrictLayout.ROADS:
		if road.get("id", "") == "axis":
			sidewalk_roads.push_front(road)
		else:
			sidewalk_roads.append(road)
	# Visual continuations retain road width/material through the opaque haze.
	for extension in MapBoundaries.road_continuations():
		var continued: Dictionary = extension["road"].duplicate()
		continued["rect"] = extension["rect"]
		sidewalk_roads.append(continued)
	for road in sidewalk_roads:
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
				for patch in _uncovered_sidewalk(piece, covered):
					var material: ShaderMaterial = slabs if road.get("id", "") == "axis" and patch.get_center().y >= civic_start else asphalt
					var quad := QuadMesh.new()
					quad.size = patch.size
					var instance := MeshInstance3D.new()
					instance.name = "SidewalkSlabs" if material == slabs else "SidewalkAsphalt"
					instance.mesh = quad
					instance.material_override = material
					instance.rotation.x = -PI / 2.0
					instance.position = Vector3(patch.get_center().x, 0.15, patch.get_center().y)
					add_child(instance)
					covered.append(patch)


# Derive the change of street treatment from the existing crossing geometry.
func _civic_avenue_start() -> float:
	for road in DistrictLayout.ROADS:
		if road.get("id", "") == "north_street":
			var rect: Rect2 = road["rect"]
			return rect.end.y
	return -INF


# Rectangular subtraction preserves the union of the original sidewalk strips.
func _uncovered_sidewalk(rect: Rect2, covered: Array[Rect2]) -> Array[Rect2]:
	var remaining: Array[Rect2] = [rect]
	for occupied in covered:
		var next: Array[Rect2] = []
		for piece in remaining:
			var overlap := piece.intersection(occupied)
			if not overlap.has_area():
				next.append(piece)
				continue
			for fragment in [
				Rect2(piece.position, Vector2(overlap.position.x - piece.position.x, piece.size.y)),
				Rect2(Vector2(overlap.end.x, piece.position.y), Vector2(piece.end.x - overlap.end.x, piece.size.y)),
				Rect2(Vector2(overlap.position.x, piece.position.y), Vector2(overlap.size.x, overlap.position.y - piece.position.y)),
				Rect2(Vector2(overlap.position.x, overlap.end.y), Vector2(overlap.size.x, piece.end.y - overlap.end.y)),
			]:
				if fragment.has_area():
					next.append(fragment)
		remaining = next
		if remaining.is_empty():
			break
	return remaining


func _sidewalk_material(texture: Texture2D, repeat_metres: float, region: Vector4 = Vector4(0, 0, 1, 1)) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = SIDEWALK_SURFACE
	material.set_shader_parameter("surface_texture", texture)
	material.set_shader_parameter("repeat_metres", repeat_metres)
	material.set_shader_parameter("source_region", region)
	return material


# The strip minus every other road it runs into, as a list of rects.
func _strip_pieces(strip: Rect2, along_x: bool, own: Dictionary, margin: float = 0.0, median_only := false) -> Array[Rect2]:
	var cuts: Array[Vector2] = []
	# The checkpoint owns a paved control island in place of the planted median.
	if median_only and own.get("id", "") == "axis":
		var checkpoint: Rect2 = DistrictLayout.LOTS["checkpoint"]["rect"]
		cuts.append(Vector2(checkpoint.position.y, checkpoint.end.y))
	# The overpass owns its elevated sidewalks and structural median.
	for bridge in DistrictLayout.BRIDGES:
		if bridge.get("rail_overpass", false) and strip.intersects(bridge["rect"]):
			var deck: Rect2 = bridge["rect"]
			cuts.append(Vector2(deck.position.x, deck.end.x) if along_x else Vector2(deck.position.y, deck.end.y))
	for other in DistrictLayout.ROADS:
		if other == own:
			continue
		var rect: Rect2 = other["rect"]
		if rect.intersects(strip):
			cuts.append(Vector2(rect.position.x - margin, rect.end.x + margin) if along_x else Vector2(rect.position.y - margin, rect.end.y + margin))
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
			# A lamp that would stand in a lot gate slides along the road to the next clear spot.
			for shift in [0.0, 12.0, -12.0]:
				var spot := at + (Vector2(shift, 0) if along_x else Vector2(0, shift))
				if not _is_occupied(spot, 0.5):
					_sprite(LAMP_POST, _ground(spot), 6.0)
					_lamp_light(_ground(spot))
					break


# A lit lamp: a glow at the lamp head (about 8 m up, a little to the screen's
# right where the arm ends) and a pool of light on the road under it.
func _lamp_light(base: Vector3, head_height: float = 8.2, glow_scale: float = 1.0) -> void:
	if _lamp_glow.is_empty():
		var gradient := Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		texture.width = 128
		texture.height = 128
		for key in ["head", "pool"]:
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.albedo_texture = texture
			material.albedo_color = Color(1.0, 0.76, 0.42, 0.0)
			material.no_depth_test = key == "head"
			material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED if key == "head" else BaseMaterial3D.BILLBOARD_DISABLED
			_lamp_glow[key] = material
		var head := QuadMesh.new()
		head.size = Vector2(2.2, 2.2)
		_lamp_glow["head_mesh"] = head
		var pool := QuadMesh.new()
		pool.size = Vector2(16.0, 16.0)
		_lamp_glow["pool_mesh"] = pool
	var head_glow := MeshInstance3D.new()
	head_glow.mesh = _lamp_glow["head_mesh"]
	head_glow.material_override = _lamp_glow["head"]
	head_glow.position = base + Vector3.UP * head_height + _view_right() * 0.7 * glow_scale
	head_glow.scale = Vector3.ONE * glow_scale
	head_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(head_glow)
	var pool_glow := MeshInstance3D.new()
	pool_glow.mesh = _lamp_glow["pool_mesh"]
	pool_glow.material_override = _lamp_glow["pool"]
	pool_glow.rotation.x = -PI / 2.0
	pool_glow.position = base + Vector3.UP * 0.2
	pool_glow.scale = Vector3.ONE * glow_scale
	pool_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(pool_glow)


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
	for road in DistrictLayout.ROADS:
		var rect: Rect2 = road["rect"]
		if road["kind"] == "dirt":
			continue
		var along_x := rect.size.x > rect.size.y
		for i in range(1, int(maxf(rect.size.x, rect.size.y) / 26.0)):
			var at := rect.position + (Vector2(i * 26, rect.size.y + 6) if along_x else Vector2(rect.size.x + 6, i * 26))
			if not _is_occupied(at, 3.0) and not _near_traffic_light(at):
				# This lot owns its 3D planting. Consume the same RNG values even
				# when suppressing a roadside tree, preserving all later trees.
				_tree(_ground(at), not preload("res://scripts/map/civic_center.gd").PLANTING_RECT.has_point(at))


# --- Tokens ------------------------------------------------------------------

func _build_tokens() -> void:
	for id in Week1.enabled_actor_ids():
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
		token.position = _ground(start)
		_tokens[id] = token
	_hero_car = _vehicle("volga", Vector3.ZERO, VehicleModels.map_length("volga"), "z", null, VehicleModels.PAINT_BLACK)
	_hero_car.visible = false


# When you travel with Tolik you sit in the car: it drives the route and the
# discs under both of you disappear. On foot there is no car.
func _update_hero_car(delta: float) -> void:
	if _arrival_hour >= 0.0:
		return
	var me: Dictionary = sim.actors["me"]
	var riding: bool = me["state"] == "travel" and me["driver"]
	_hero_car.visible = riding
	_token_discs["me"].visible = not riding
	if _token_discs.has("tolik"):
		_token_discs["tolik"].visible = not riding
	if not riding:
		return
	var pos: Vector2 = me["pos"]
	var path: PackedVector2Array = me["path"]
	var index: int = me["path_index"]
	var lane := _lane_shift(me, true)
	_hero_car.position = _ground(pos + lane) + Vector3.UP * 0.14
	if index < path.size() and pos.distance_to(path[index]) > 0.01:
		var heading := path[index] - pos
		_hero_car.rotation.y = lerp_angle(_hero_car.rotation.y, atan2(heading.x, heading.y), minf(1.0, delta * 8.0))
		_hero_car.rotation.x = _overpass_pitch(pos + lane, heading)


# Where the actor stands relative to the route's centerline while travelling.
func _lane_shift(actor: Dictionary, is_car: bool) -> Vector2:
	var path: PackedVector2Array = actor["path"]
	var index: int = actor["path_index"]
	if actor["state"] != "travel" or index >= path.size():
		return Vector2.ZERO
	return sim.graph.lane_shift(actor["pos"], path[index] - actor["pos"], is_car)


func _move_tokens() -> void:
	# Spread tokens that share a spot side by side so faces never overlap.
	var groups := {}
	for id in _tokens:
		_tokens[id].visible = sim.actor_available(id)
		if not sim.actor_available(id):
			continue
		var pos: Vector2 = sim.actors[id]["pos"]
		var key := Vector2i(roundi(pos.x), roundi(pos.y))
		if not groups.has(key):
			groups[key] = []
		groups[key].append(id)
	for key in groups:
		var ids: Array = groups[key]
		for i in ids.size():
			var actor: Dictionary = sim.actors[ids[i]]
			var pos: Vector2 = actor["pos"]
			if not actor["driver"]:
				pos += _lane_shift(actor, false)
			# Spread along the screen's horizontal so faces never overlap, whatever
			# the camera angle.
			var origin := _ground(pos)
			var pixels_per_metre := camera.unproject_position(origin).distance_to(camera.unproject_position(origin + _view_right()))
			var world_gap := 64.0 * map_icon_scale() / maxf(pixels_per_metre, 0.001)
			var spread := (i - (ids.size() - 1) / 2.0) * world_gap
			var token: Node3D = _tokens[ids[i]]
			# Feet follow the simulation exactly. Smoothing world positions makes
			# portraits lag behind on fast travel, pause and overnight relocation.
			token.position = _ground(pos) + _view_right() * spread


# --- Signal handlers ---------------------------------------------------------

func _on_overlay_changed(lot: String, overlay: String, shown: bool) -> void:
	var key := lot + ":" + overlay
	if _overlays.has(key):
		_overlays[key].visible = shown


func _on_lot_state_changed(lot: String, state: String) -> void:
	if _location_states.has(lot):
		_location_states[lot].set_override(StringName(state))


func register_location_state(id: String, controller: Node) -> void:
	_location_states[id] = controller
	if sim.lot_states.has(id):
		controller.set_override(StringName(sim.lot_states[id]),false)

func location_state(id: String) -> StringName:
	return _location_states[id].state if _location_states.has(id) else &""

func set_location_state_override(id: String, state: StringName, animated := true) -> void:
	if _location_states.has(id):
		_location_states[id].set_override(state,animated)

func clear_location_state_override(id: String, animated := true) -> void:
	if _location_states.has(id):
		_location_states[id].clear_override(animated)


# --- Ground and street details -----------------------------------------------

# `organic` swaps the flat tiled material for the terrain shader (world-space UVs,
# de-tiled, large-scale variation); use it for grass, dirt and similar natural ground.
# `soft_edge` (metres, organic only) fades the patch out toward its border so it blends
# into the ground laid beneath it; leave it 0 where the patch meets a road or kerb.
func _ground_quad(center: Vector2, size: Vector2, y: float, texture: Texture2D, tile: float, turned: bool = false, tint: Color = Color.WHITE, organic: bool = false, soft_edge: float = 0.0) -> void:
	var quad := QuadMesh.new()
	var material: Material
	var instance := MeshInstance3D.new()
	if organic and not OS.get_cmdline_user_args().has("--flat-ground"):
		var shader_material := ShaderMaterial.new()
		shader_material.shader = TERRAIN_EDGE_SHADER if soft_edge > 0.0 else TERRAIN_GROUND_SHADER
		if soft_edge > 0.0:
			shader_material.set_shader_parameter("quad_metres", size)
			shader_material.set_shader_parameter("edge_metres", soft_edge)
		shader_material.set_shader_parameter("ground_texture", texture)
		shader_material.set_shader_parameter("winter", Settings.season == "winter")
		shader_material.set_shader_parameter("tint", tint)
		shader_material.set_shader_parameter("tile_metres", tile)
		shader_material.set_shader_parameter("macro_texture", GROUND_MACRO)
		if wear != null:
			shader_material.set_shader_parameter("wear_mask", wear.texture)
			shader_material.set_shader_parameter("wear_rect", wear.world_rect())
			shader_material.set_shader_parameter("dirt_texture", _season["dirt"])
		material = shader_material
		quad.size = Vector2(size.y, size.x) if turned else size
		instance.basis = (Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, -PI / 2.0)) if turned else Basis(Vector3.RIGHT, -PI / 2.0)
	else:
		var standard := StandardMaterial3D.new()
		standard.albedo_texture = texture
		standard.albedo_color = tint
		standard.roughness = 0.95
		standard.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		material = standard
		if turned:
			quad.size = Vector2(size.y, size.x)
			standard.uv1_scale = Vector3(size.y / tile, size.x / tile, 1.0)
			instance.basis = Basis(Vector3.UP, PI / 2.0) * Basis(Vector3.RIGHT, -PI / 2.0)
		else:
			quad.size = size
			standard.uv1_scale = Vector3(size.x / tile, size.y / tile, 1.0)
			var corner := center - size / 2.0
			standard.uv1_offset = Vector3(corner.x / tile, corner.y / tile, 0.0)
			instance.basis = Basis(Vector3.RIGHT, -PI / 2.0)
	instance.mesh = quad
	instance.material_override = material
	instance.position = Vector3(center.x, y, center.y)
	add_child(instance)


# Local paths retain their earth, compacted yard or paving character.
func _path_quad(rect: Rect2, height: float, ground: String, tint: Color) -> void:
	var winter := Settings.season == "winter"
	var paved := ground == "paving"
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/local_paths.gdshader")
	var texture: Texture2D = (GROUND_PAVING if paved else GROUND_DIRT) if winter else _season[ground]
	material.set_shader_parameter("surface_texture", texture)
	material.set_shader_parameter("surface_tint", tint)
	material.set_shader_parameter("winter", winter)
	material.set_shader_parameter("paved", paved)
	material.set_shader_parameter("yard", ground == "courtyard")
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.rotation.x = -PI / 2.0
	instance.position = Vector3(rect.get_center().x, height, rect.get_center().y)
	add_child(instance)


# Asphalt roads share world coordinates so adjacent pieces have no texture seams.
func _asphalt_material(tint: Color, highway: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://assets/shaders/town_asphalt.gdshader")
	material.set_shader_parameter("grain_texture", GROUND_ASPHALT)
	material.set_shader_parameter("highway", highway)
	material.set_shader_parameter("winter", Settings.season == "winter")
	material.set_shader_parameter("surface_tint", tint)
	return material


func _asphalt_quad(rect: Rect2, height: float, tint: Color, highway: bool = false) -> void:
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _asphalt_material(tint, highway)
	instance.rotation.x = -PI / 2.0
	instance.position = Vector3(rect.get_center().x, height, rect.get_center().y)
	add_child(instance)


# Paint dimensions are in world metres, independent of any image canvas.
func _paint_patch(size: Vector2, at: Vector2, y: float, crossing: bool = false) -> void:
	if _road_paint_material == null:
		_road_paint_material = ShaderMaterial.new()
		_road_paint_material.shader = ROAD_PAINT_SHADER
	var quad := QuadMesh.new()
	quad.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	if crossing and _crosswalk_material == null:
		_crosswalk_material = ShaderMaterial.new()
		_crosswalk_material.shader = ROAD_PAINT_SHADER
		_crosswalk_material.set_shader_parameter("paint_colour", Color(0.70, 0.69, 0.65))
	instance.material_override = _crosswalk_material if crossing else _road_paint_material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.rotation.x = -PI / 2.0
	instance.position = Vector3(at.x, y, at.y)
	add_child(instance)


# A crossing spans the road; each narrow bar runs along the direction of travel.
func _crosswalk(at: Vector2, road_width: float, along_z: bool, y: float) -> void:
	const BAR := 0.45
	const GAP := 0.45
	const DEPTH := DistrictLayout.CROSSWALK_DEPTH
	var count := int((road_width - 1.0 + GAP) / (BAR + GAP))
	for i in count:
		var offset := (i - (count - 1) / 2.0) * (BAR + GAP)
		var shift := Vector2(offset, 0) if along_z else Vector2(0, offset)
		var size := Vector2(BAR, DEPTH) if along_z else Vector2(DEPTH, BAR)
		_paint_patch(size, at + shift, y, true)


func _build_road_markings() -> void:
	for road in DistrictLayout.ROADS:
		if road["kind"] != "asphalt" or road.get("hub_surface", false):
			continue
		var rect: Rect2 = road["rect"]
		for extension in MapBoundaries.road_continuations():
			if extension["road"] == road:
				rect = rect.merge(extension["rect"])
		var along_x := rect.size.x > rect.size.y
		var width := minf(rect.size.x, rect.size.y)
		var source_rect: Rect2 = road["rect"]
		var start := source_rect.position + (Vector2(0, width / 2) if along_x else Vector2(width / 2, 0))
		if road.get("look", "") == "highway":
			_highway_lines(road, rect)
			continue
		if road.has("median"):
			_boulevard_median(road)
			continue
		var low := rect.position.x if along_x else rect.position.y
		var high := rect.end.x if along_x else rect.end.y
		var phase := start.x if along_x else start.y
		for i in range(int(ceil((low - phase) / 8.0)), int(floor((high - phase) / 8.0)) + 1):
			var at := start + (Vector2(i * 8, 0) if along_x else Vector2(0, i * 8))
			var junction := false
			for other in DistrictLayout.ROADS:
				if other != road and other["rect"].grow(6).has_point(at):
					junction = true
			if not junction:
				_paint_patch(Vector2(3, 0.12) if along_x else Vector2(0.12, 3), at, 0.145)
	for crossing in DistrictLayout.crosswalks():
		_crosswalk(crossing["at"], crossing["width"], crossing["along_z"], 0.145)


# Highway markings: solid edge lines and a solid double centre line, in 8 m pieces
# that stop short of every junction.
func _highway_lines(road: Dictionary, rect: Rect2) -> void:
	var source_rect: Rect2 = road["rect"]
	var cy := rect.get_center().y
	var offsets := [-rect.size.y / 2.0 + 0.9, rect.size.y / 2.0 - 0.9, -0.25, 0.25]
	for i in range(int(ceil((rect.position.x - source_rect.position.x) / 8.0)), int(floor((rect.end.x - source_rect.position.x) / 8.0)) + 1):
		var x := source_rect.position.x + i * 8.0
		var junction := false
		for other in DistrictLayout.ROADS:
			if other != road and other["rect"].grow(8).has_point(Vector2(x, cy)):
				junction = true
		if junction:
			continue
		for offset in offsets:
			_paint_patch(Vector2(8.0, 0.16), Vector2(x, cy + offset), 0.145)


# A boulevard: a kerbed green strip down the middle with trees, broken at every
# crossing so the crosswalks and turns stay free.
func _boulevard_median(road: Dictionary) -> void:
	var rect: Rect2 = road["rect"]
	var width: float = road["median"]
	var civic_start := _civic_avenue_start()
	var strip := Rect2(rect.get_center().x - width / 2.0, rect.position.y, width, rect.size.y)
	for piece in _strip_pieces(strip, false, road, 7.0, true):
		if piece.size.y < 6.0:
			continue
		_box(Vector3(piece.size.x + 0.5, 0.25, piece.size.y), _ground(piece.get_center()) + Vector3.UP * 0.2, Color("b3afa0"))
		_ground_quad(piece.get_center(), piece.size, 0.33, _season["grass"], 22.0, false, _season["grass_tint"], true)
		var z := piece.position.y + 7.0
		while z < piece.end.y - 3.0:
			_tree(_ground(Vector2(piece.get_center().x, z)) + Vector3.UP * 0.3,
				road.get("id", "") != "axis" or z >= civic_start)
			z += 14.0


# Walkers use district/hour visibility; car slots follow the authored traffic flows.
const AMBIENT_WALKERS := 288
const AMBIENT_CARS := preload("res://scripts/data/traffic_flows.gd").CAR_COUNT


func _build_ambient() -> void:
	_gateways = MapBoundaries.resolve(sim.graph)
	_ambient = AmbientLife.new(sim.graph, 1997, _gateways)
	if OS.get_cmdline_user_args().has("--traffic-debug"):
		print("map gateways resolved: %d / %d" % [_gateways.size(), MapBoundaries.GATEWAYS.size()])
		for gateway in _gateways:
			print("  %s node %d edge %d at %s out %s leg %.0f m sample %s" % [gateway["id"], gateway["node"], gateway["edge"], gateway["point"], gateway["out"], gateway["leg_length"], gateway["sample"]])
	# Their own RNG: the look of background life must not shift the trees built later.
	var look := RandomNumberGenerator.new()
	look.seed = 2026
	var base_walkers: Array[Dictionary] = []
	for i in AMBIENT_WALKERS:
		var agent := _ambient.add(false, look.randf_range(1.6, 2.4))
		if agent.is_empty():
			break
		var person: Dictionary = PEOPLE[look.randi() % PEOPLE.size()]
		var sprite := _sprite(person["texture"], _ground(agent["pos"]), person["width"])
		agent["visual"] = sprite
		agent["lift"] = sprite.position.y - _ground(agent["pos"]).y
		base_walkers.append(agent)
	var rare_car_slots := ["luxury_sedan", "luxury_suv", "rural_4x4"]
	var service_slots := ["uaz_police", "raf_ambulance"]
	for i in AMBIENT_CARS:
		var speed := look.randf_range(7.0, 12.0)
		var seed_value := look.randi()
		var agent := _ambient.add(true, speed, seed_value)
		if agent.is_empty():
			break
		if agent["class"] == "car" and not rare_car_slots.is_empty():
			agent["rare_car_model"] = rare_car_slots.pop_front()
		# One police van and one ambulance circle the town for good: they take the
		# first city-stream cars whose loop runs along the civic axis.
		elif agent["class"] == "car" and agent["stream"] == "city" and not service_slots.is_empty() \
				and _ambient.trip_uses_road(agent, "axis"):
			agent["rare_car_model"] = service_slots.pop_front()
		var car := TrafficVehicleModels.create(agent["class"], seed_value, _ground(agent["pos"]) + Vector3.UP * 0.14, agent.get("rare_car_model", ""))
		add_child(car)
		agent["half_extent"] = car.get_meta("traffic_half_extent")
		agent["visual"] = car
	# Daytime reserve, hidden outside the centre/housing or 08:00–18:00.
	# Keep this after the base pedestrians/cars so their random sequence is unchanged.
	var workday_look := RandomNumberGenerator.new()
	workday_look.seed = 2036
	for original in base_walkers:
		var agent := _ambient.add_workday_walker(original, workday_look.randf_range(1.6, 2.4))
		var person: Dictionary = PEOPLE[workday_look.randi() % PEOPLE.size()]
		var sprite := _sprite(person["texture"], _ground(agent["pos"]), person["width"])
		agent["visual"] = sprite
		agent["lift"] = sprite.position.y - _ground(agent["pos"]).y
		sprite.visible = agent["visible"]


func _move_ambient(delta: float) -> void:
	if profile_skip_ambient:
		profile_step_ms = 0.0
		profile_visual_ms = 0.0
		return
	var started := Time.get_ticks_usec() if profile_ambient else 0
	_ambient.hour = visual_clock_hour() if _arrival_hour >= 0.0 else sim.clock_hour()
	_ambient.step(delta)
	for light in _signal_lights:
		var controller = _ambient.signals[light.binding["intersection_id"]]
		var color: String
		if light.binding.get("pedestrian", false):
			color = "green" if controller.phase == controller.WALK else "red"
		else:
			color = controller.vehicle_color(light.binding["travel_direction"].x != 0.0)
		if color != light.signal_state:
			light.set_signal(color)
	var stepped := Time.get_ticks_usec() if profile_ambient else 0
	if OS.get_cmdline_user_args().has("--traffic-debug"):
		_print_traffic_stats(delta)
	var right := _view_right()
	for agent in _ambient.agents:
		var at: Vector2 = agent["pos"]
		var heading: Vector2 = agent["heading"]
		if agent["is_car"]:
			if agent["respawned"]:
				_respawn_car(agent)
			var car: Node3D = agent["visual"]
			car.visible = agent["visible"] and not profile_hide_ambient
			if car.has_meta("front_wheels"):
				_steer_front_wheels(car, at, heading, delta)
			car.position = Vector3(at.x, _ground(at).y + 0.14, at.y)
			car.rotation.y = atan2(heading.x, heading.y)
			car.rotation.x = _overpass_pitch(at, heading)
		else:
			var sprite: Sprite3D = agent["visual"]
			sprite.visible = agent["visible"] and not profile_hide_ambient
			sprite.position = _ground(at) + Vector3.UP * float(agent["lift"])
			# Face the way they walk as seen on screen.
			sprite.flip_h = heading.x * right.x + heading.y * right.z < 0.0
	if profile_ambient:
		profile_step_ms = (stepped - started) / 1000.0
		profile_visual_ms = (Time.get_ticks_usec() - stepped) / 1000.0


# Steering comes from the curvature of the path actually travelled. Both Ladas
# have separate front wheels and a 2.42 m wheelbase.
func _steer_front_wheels(car: Node3D, at: Vector2, heading: Vector2, delta: float) -> void:
	var distance := at.distance_to(Vector2(car.position.x, car.position.z))
	var angle: float = car.get_meta("steer_angle", 0.0)
	var target := angle
	if distance > 0.002:
		var yaw := wrapf(atan2(heading.x, heading.y) - car.rotation.y, -PI, PI)
		target = clampf(atan(2.42 * yaw / distance), -0.55, 0.55)
	angle = move_toward(angle, target, 1.5 * delta)
	for wheel: Dictionary in car.get_meta("front_wheels"):
		wheel["node"].basis = Basis(Vector3.UP, angle) * wheel["rest"]
	car.set_meta("steer_angle", angle)


# A slot that re-entered the map gets a new car: the class follows the entry road's fleet.
func _respawn_car(agent: Dictionary) -> void:
	agent["respawned"] = false
	agent["visual"].queue_free()
	var seed_value: int = agent["appearance_seed"]
	var at: Vector2 = agent["pos"]
	var car := TrafficVehicleModels.create(agent["class"], seed_value, _ground(at) + Vector3.UP * 0.14, agent.get("rare_car_model", ""))
	add_child(car)
	var heading: Vector2 = agent["heading"]
	car.rotation.y = atan2(heading.x, heading.y)
	agent["half_extent"] = car.get_meta("traffic_half_extent")
	agent["visual"] = car


# Dev: every 10 s of ambient time, per-gateway exits and arrivals and the slot invariant.
func _print_traffic_stats(delta: float) -> void:
	_traffic_debug_clock += delta
	if _traffic_debug_clock < 10.0:
		return
	_traffic_debug_clock = 0.0
	var states := {"graph": 0, "out": 0, "wait": 0, "in": 0}
	var cars := 0
	var streams := {}
	var buses := 0
	var overlaps := 0
	for agent in _ambient.agents:
		if agent["is_car"]:
			cars += 1
			if agent["visible"] and not _ambient._space.clear_pose(agent, _ambient._space.nearby(agent["pos"], 20.0)):
				overlaps += 1
			streams[agent["stream"]] = streams.get(agent["stream"], 0) + 1
			if agent["class"] == "bus":
				buses += 1
			states[agent["state"]] += 1
	print("traffic: exits ", _ambient.stats["exits"], " arrivals ", _ambient.stats["arrivals"], " states ", states)
	print("traffic motion: max_step=", _ambient.stats["max_step"], " max_excess=", _ambient.stats["max_excess"], " warnings=", _ambient.stats["motion_warnings"])
	for id in _ambient.signals:
		var controller = _ambient.signals[id]
		if controller.phase in [controller.CLEAR_EW,controller.CLEAR_NS] and controller.elapsed > 12 and OS.get_cmdline_user_args().has("--signal-trace"):
			for j in _ambient._junctions:
				if j["owner"] > 0:
					for owner in _ambient.agents:
						if owner.get("slot",-1) == j["owner"]:
							print("LOCK ",j["node"]," ",j["center"]," owner ",owner["slot"]," pos ",owner["pos"]," limit ",owner["limit"]," reason ",owner.get("stop_reason",""))
			print("SIGNAL_WAIT ",id," waiting ",controller.waiting.keys()," walking ",controller.walking)
			for a in _ambient.agents:
				if not controller.inside.has(a.get("slot",-1)):
					continue
				print("STUCK ",id," ",a["slot"]," ",a["pos"]," ",a["heading"]," gap ",a["limit"], " blocked ",a.get("blocked_by",""), " class ",a["class"])
				for b in _ambient._space.nearby(a["pos"],18):
					if not is_same(a,b):
						print(" neighbor ",b.get("slot",-1)," ",b["pos"]," ",b["heading"]," ",b["speed_scale"]," why ",b.get("stop_reason","")," atedge ",b["edge"]," from ",b["from"]," turning ", b["turn"].get("node",-1))
		print("signal ", id, " phase=", controller.phase, " elapsed=", snappedf(controller.elapsed, 0.1),
			" walking=",controller.walking," pedestrian_entries=",controller.pedestrian_entries," cleared=",controller.cleared)
	print("traffic observed road speed factors: ", _ambient.stats["road_speeds"])
	print("traffic passing: started=", _ambient.stats["passes_started"], " returned=", _ambient.stats["passes_finished"], " vehicles overlapping=", overlaps)
	print("traffic flows: ", streams, " buses=", buses, " completed_loops=", _ambient.stats["loops"])
	if cars != AMBIENT_CARS or states["graph"] + states["out"] + states["wait"] + states["in"] != AMBIENT_CARS:
		print("TRAFFIC INVARIANT BROKEN: ", cars, " cars, states ", states)


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


# The area the wear mask covers: every lot and road of the district plus a margin.
func _wear_bounds() -> Rect2:
	var area := Rect2()
	var first := true
	for rect in DistrictLayout.LOTS.values().map(func(lot): return lot["rect"]) + DistrictLayout.ROADS.map(func(road): return road["rect"]):
		area = rect if first else area.merge(rect)
		first = false
	return area.grow(30.0)


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


func _tree(at: Vector3, spawn: bool = true) -> Node3D:
	# Preserve the original random sequence, even for suppressed trees.
	var poplar := _rng.randf() < 0.25
	var height := _rng.randf_range(13.0, 18.0) if poplar else _rng.randf_range(9.0, 13.0)
	var variation := _rng.randf()
	if not spawn:
		return null
	var id := "park_poplar" if poplar else "park_deciduous_tree"
	var tree := VegetationModels.create(id, at)
	tree.scale = Vector3.ONE * height / float(VegetationModels.HEIGHTS[id])
	tree.rotation.y = variation * TAU
	add_child(tree)
	return tree


func _ground(at: Vector2) -> Vector3:
	return Vector3(at.x, _bridge_height(at), at.y)


# Deck height under a map point: zero on land, rising along the ramps of the road bridge.
func _bridge_height(at: Vector2) -> float:
	for bridge in DistrictLayout.BRIDGES:
		# Road users travel below railway spans, not on their decks.
		if bridge["kind"] != "road":
			continue
		var rect: Rect2 = bridge["rect"]
		if rect.has_point(at):
			var ramp: float = bridge["ramp"]
			var south: float = INF if bridge.get("flat_end", false) else rect.end.y - at.y
			return float(bridge["height"]) * clampf(minf(at.y - rect.position.y, south) / ramp, 0.0, 1.0)
	return 0.0


func _overpass_pitch(at: Vector2, heading: Vector2) -> float:
	for bridge in DistrictLayout.BRIDGES:
		if bridge.get("rail_overpass", false) and bridge["rect"].has_point(at):
			var direction := heading.normalized()
			return -atan2(_bridge_height(at + direction) - _bridge_height(at - direction), 2.0)
	return 0.0


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
func _roof(size: Vector2, at: Vector3, tile: float, texture: Texture2D = ROOF_TAR, parent: Node = null, surface_detail := false) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.uv1_scale = Vector3(size.x / tile, size.y / tile, 1.0)
	material.roughness = 0.95
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	instance.material_override = material
	if surface_detail:
		var roofing := ShaderMaterial.new()
		roofing.shader = preload("res://assets/shaders/roof_felt.gdshader")
		roofing.set_shader_parameter("albedo_tex", texture)
		roofing.set_shader_parameter("uv_scale", Vector2(size.x / tile, size.y / tile))
		roofing.set_shader_parameter("surface_detail", not OS.get_cmdline_user_args().has("--facade-baseline"))
		instance.material_override = roofing
	instance.position = at
	instance.rotation.x = -PI / 2.0
	(parent if parent != null else self).add_child(instance)


# Painted facades on the four sides of a box-shaped building.
# `blank_ends`: the two gable walls (the narrow faces) get no windows, like real panel blocks.
func _facades(base: Vector3, size: Vector3, texture: Texture2D, tiles_per_height: float, tint: Color = Color.WHITE, parent: Node = null, floor_count: int = 0, floor_bands: Array = [], blank_ends := false) -> void:
	var tile_width := size.y * 2.0 / tiles_per_height
	var center_y := size.y / 2.0
	for face in [
		[Vector2(size.x, size.y), Vector3(0, center_y, size.z / 2.0 + 0.01), 0.0],
		[Vector2(size.x, size.y), Vector3(0, center_y, -size.z / 2.0 - 0.01), PI],
		[Vector2(size.z, size.y), Vector3(size.x / 2.0 + 0.01, center_y, 0), PI / 2.0],
		[Vector2(size.z, size.y), Vector3(-size.x / 2.0 - 0.01, center_y, 0), -PI / 2.0],
	]:
		var gable: bool = blank_ends and face[0].x == size.z and face[0].x != size.x
		_facade(face[0], base + face[1], face[2], BLANK_WALL if gable else texture, Vector2(face[0].x / tile_width, tiles_per_height), tint, parent, Vector2.ZERO, false, Vector2.ZERO, 0 if gable else floor_count, floor_bands, gable)


# One textured wall: a quad facing +Z, turned by yaw around the vertical axis.
func _facade(size: Vector2, at: Vector3, yaw: float, texture: Texture2D, tiles: Vector2, tint: Color = Color.WHITE, parent: Node = null, uv_offset := Vector2.ZERO, surface_detail := false, seam_blend := Vector2.ZERO, floor_count: int = 0, floor_bands: Array = [], blank_wall := false) -> void:
	var quad := QuadMesh.new()
	quad.size = size
	var material := ShaderMaterial.new()
	material.shader = LIT_FACADE
	material.set_shader_parameter("albedo_tex", texture)
	material.set_shader_parameter("tint", tint)
	material.set_shader_parameter("uv_scale", tiles)
	if floor_count > 0:
		material.set_shader_parameter("uv_scale", Vector2(tiles.x, 1.0))
	material.set_shader_parameter("uv_offset", uv_offset)
	material.set_shader_parameter("surface_detail", (surface_detail or texture.resource_path.ends_with("_lived.png")) and not OS.get_cmdline_user_args().has("--facade-baseline"))
	material.set_shader_parameter("seam_blend", Vector2.ZERO if OS.get_cmdline_user_args().has("--facade-baseline") else seam_blend)
	material.set_shader_parameter("night", maxf(_night, 0.0))
	material.set_shader_parameter("blank_wall", blank_wall)
	material.set_shader_parameter("wall_size", size)
	var cells: Dictionary = {} if blank_wall else WINDOW_CELLS.get(texture.resource_path.get_file().get_basename(), {})
	if cells.has("rects"):
		var rects := PackedVector4Array()
		var always := PackedFloat32Array()
		for entry in cells["rects"]:
			rects.append(Vector4(entry[0], entry[1], entry[2], entry[3]))
			always.append(entry[4])
		rects.resize(4)
		always.resize(4)
		material.set_shader_parameter("rect_data", rects)
		material.set_shader_parameter("rect_always", always)
		material.set_shader_parameter("rect_count", cells["rects"].size())
	elif not cells.is_empty():
		var cols := PackedFloat32Array(cells["cols"])
		var wide := PackedFloat32Array()
		wide.resize(16)
		for index in cells["wide"]:
			wide[index] = 1.0
		cols.resize(16)
		material.set_shader_parameter("col_edges", cols)
		material.set_shader_parameter("col_wide", wide)
		material.set_shader_parameter("col_count", cells["cols"].size())
		material.set_shader_parameter("row_origin", cells["row_origin"])
		material.set_shader_parameter("row_pitch", cells["row_pitch"])
	_window_materials.append(material)
	var instance := MeshInstance3D.new()
	instance.mesh = quad
	if floor_count > 0:
		instance.mesh = preload("res://scripts/map/facade_floors.gd").mesh(size, floor_count, floor_bands)
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


func _build_traffic_lights() -> void:
	for id in TrafficIntersections.JUNCTIONS:
		for fixture in TrafficIntersections.fixtures(id):
			_traffic_light_positions.append(fixture["position"])
			var light := TrafficLight.new(fixture)
			add_child(light)
			_signal_lights.append(light)
			light.add_to_group("traffic_lights")
		var data := TrafficIntersections.junction(id)
		for zebra in DistrictLayout.crosswalks():
			if not zebra["id"] in data["crossing_ids"]:
				continue
			var toward_center: Vector2 = (data["center"] - zebra["at"]).normalized()
			for end in ["a", "b"]:
				var at: Vector2 = zebra[end]
				var binding := {"pedestrian": true, "id": zebra["id"] + "/" + end, "intersection_id": id,
					"position": at + toward_center * 2.1, "facing": (zebra["at"] - at).normalized(), "surface_height": 0.15}
				var light := TrafficLight.new(binding)
				add_child(light)
				_signal_lights.append(light)
				_traffic_light_positions.append(binding["position"])


# Keep roadside tree crowns from covering the nearby signal head.
func _near_traffic_light(at: Vector2) -> bool:
	for spot in _traffic_light_positions:
		if at.distance_to(spot) < 8.0:
			return true
	return false


# Modal ownership is explicit; wheel bubbling and held keys cannot move the map.
func set_ui_input_blocked(blocked: bool) -> void:
	if blocked and not _ui_input_blocked:
		_dragging = false
		_camera_goal = _camera_target
	_ui_input_blocked = blocked
