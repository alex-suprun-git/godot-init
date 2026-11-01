# Manual visual review on the real district map; no persistent map changes.
# Godot --path init --script <absolute path to this file> -- --no-log --hour=12
extends SceneTree

var district: Node3D
var fleet: Node3D
var camera: Camera3D
var output: String
var models: Array[Node3D] = []


func _initialize() -> void:
	call_deferred("review")


func review() -> void:
	output = get_script().resource_path.get_base_dir().path_join("shape_v1")
	var finished: String = get_script().resource_path.get_base_dir().path_join("finish_v1")
	if FileAccess.file_exists(finished.path_join("LiAZ_5256.glb")):
		output = finished
	var simulation = load("res://scripts/sim/week_sim.gd").new()
	district = load("res://scripts/map/city_map.gd").new()
	root.add_child(district)
	district.setup(simulation)
	simulation.begin()
	district.set_process(false)
	district.set_process_unhandled_input(false)
	# A temporary review pad in the existing reserve, not a saved map edit.
	fleet = Node3D.new()
	fleet.position = Vector3(-210, 0.14, -235)
	district.add_child(fleet)
	var pad := MeshInstance3D.new()
	var slab := BoxMesh.new()
	slab.size = Vector3(31, 0.14, 25)
	pad.mesh = slab
	pad.position.y = -0.07
	var paving := StandardMaterial3D.new()
	paving.albedo_color = Color(0.31, 0.32, 0.30)
	paving.roughness = 0.95
	pad.material_override = paving
	fleet.add_child(pad)
	var ids := ["kamaz_semi", "bus_liaz", "bus_paz", "zil_flatbed", "zil_food", "volga"]
	var names := ["KamAZ", "LiAZ-5256", "PAZ-3205", "ZIL coal", "ZIL food", "Volga"]
	var xs := [-11.25, -6.75, -2.25, 2.25, 6.75, 11.25]
	var registry = load("res://scripts/map/vehicle_models.gd")
	for i in ids.size():
		# Use actual imported game scenes and presentation scales/material hooks.
		var vehicle: Node3D = registry.create(ids[i], Vector3.ZERO, registry.map_length(ids[i]), "z")
		fleet.add_child(vehicle)
		vehicle.position = Vector3(xs[i], 0.005, 0)
		models.append(vehicle)
		var label := Label3D.new()
		label.text = names[i]
		label.position = Vector3(xs[i], 0.1, 10)
		label.font_size = 48
		label.pixel_size = 0.008
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		fleet.add_child(label)
	camera = district.camera
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	await create_timer(2.0).timeout
	await capture("godot_fleet_z", 28.0)
	var refresh := OS.get_cmdline_user_args().has("--refresh-main")
	if not refresh:
		await capture("godot_map_context", 65.0)
		fleet.rotation.y = PI / 2.0
		await capture("godot_fleet_x", 28.0)
	# Review actual integrated depot instances and traffic, with no review pad.
	fleet.visible = false
	await capture_at("godot_depot", Vector3(-360, 1.5, -240), 47.0)
	var counts := {"bus_liaz": 0, "bus_paz": 0}
	var choices := {}
	var scores := {}
	for agent in district._ambient.agents:
		if not agent["is_car"] or agent["class"] != "bus":
			continue
		var vehicle: Node3D = agent["visual"]
		var heading: Vector2 = agent["heading"]
		vehicle.rotation.y = atan2(heading.x, heading.y)
		var key := "bus_liaz" if vehicle.is_in_group("vehicle_bus_liaz") else "bus_paz"
		counts[key] += 1
		var gap := 80.0
		for other in district._ambient.agents:
			if other == agent or not other["is_car"]:
				continue
			var other_at: Vector2 = other["pos"]
			gap = minf(gap, Vector2(vehicle.position.x, vehicle.position.z).distance_to(other_at))
		# Prefer an unobscured highway view over the first bus behind housing.
		var score: float = gap + (25.0 if vehicle.position.z < -170 and vehicle.position.z > -205 else 0.0)
		if not scores.has(key) or score > scores[key]:
			scores[key] = score
			choices[key] = vehicle
	if not refresh:
		for key in choices:
			await capture_at("godot_traffic_" + key, choices[key].global_position + Vector3.UP, 30.0)
	print("Actual ambient bus models: ", counts)
	print("Bus review frames saved to ", output)
	quit()


func capture(filename: String, size: float) -> void:
	var focus := fleet.global_position + Vector3(0, 1.1, 0)
	await capture_at(filename, focus, size)


func capture_at(filename: String, focus: Vector3, size: float) -> void:
	camera.size = size
	camera.h_offset = 0
	camera.v_offset = 0
	# Match the map's 45-degree yaw / 35.264-degree isometric elevation.
	camera.global_position = focus + Vector3(35, 35, 35)
	camera.look_at(focus)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(output.path_join(filename + ".png"))
	if error != OK:
		push_error("Cannot save review frame: " + filename)
