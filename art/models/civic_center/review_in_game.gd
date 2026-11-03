# Temporary visual review inside the real game map. No saved map/data mutations.
extends SceneTree

var ASSET_DIR := ProjectSettings.globalize_path("res://../art/models/civic_center/review_exports/")
var SHOTS := ProjectSettings.globalize_path("res://../.local/civic-center-review/")
var map
var review: Node3D
var cache := {}

func _initialize() -> void:
	call_deferred("_run")

func asset(id: String, at: Vector3, yaw: float = 0.0) -> Node3D:
	if not cache.has(id):
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var err := document.append_from_file(ASSET_DIR + id + ".glb", state)
		if err != OK:
			push_error("Cannot load review asset: " + id)
			quit(1)
			return null
		cache[id] = document.generate_scene(state)
		for mesh in cache[id].find_children("*", "MeshInstance3D", true, false):
			for index in range(mesh.mesh.get_surface_count()):
				var material = mesh.mesh.surface_get_material(index)
				if material is StandardMaterial3D:
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					if material.albedo_texture != null:
						var image: Image = material.albedo_texture.get_image()
						if image != null and not image.is_compressed():
							image.generate_mipmaps()
							material.albedo_texture = ImageTexture.create_from_image(image)
					if "Generated_Front_Review" in material.resource_name:
						var facade := ShaderMaterial.new()
						facade.shader = load("res://assets/shaders/lit_facade.gdshader")
						facade.set_shader_parameter("albedo_tex",material.albedo_texture)
						facade.set_shader_parameter("surface_detail",true)
						facade.set_shader_parameter("cell",Vector2(4.0,3.5))
						mesh.set_surface_override_material(index,facade)
	var node: Node3D = cache[id].duplicate()
	review.add_child(node)
	node.position = at
	node.rotation.y = yaw
	return node

func patch(at: Vector3, size: Vector2, color: Color) -> void:
	var surface := "grass" if color == Color("748451") else ("asphalt" if color == Color("777975") else "paving")
	map._ground_quad(Vector2(at.x,at.z),size,at.y,load("res://assets/textures/ground_"+surface+".png"),6.0 if surface=="paving" else 12.0,false,Color.WHITE,false)

func shot(name: String, target: Vector3, zoom: float) -> void:
	map._camera_target = target
	map._camera_goal = target
	map._zoom = zoom
	map._update_camera()
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SHOTS + name + ".png")

func bounds_of(node: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var actual: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = actual if first else bounds.merge(actual)
		first = false
	return bounds

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.hud.hide()
	map = main.map
	# Remove only old visual nodes centered inside the administrative lot in this run.
	# Exclude whole-map MultiMeshes and actor group roots; simulation state is not edited.
	var lot := Rect2(25, 22, 115, 108)
	for node in map.find_children("*", "GeometryInstance3D", true, false):
		if node is MeshInstance3D or node is Sprite3D:
			var p: Vector3 = node.global_position
			if node is MeshInstance3D:
				p = node.global_transform * node.get_aabb().get_center()
			if lot.has_point(Vector2(p.x, p.z)):
				if node is MeshInstance3D and node.get_aabb().size.x > 116:
					continue
				node.hide()
	review = Node3D.new()
	review.name = "CivicCenterReviewOnly"
	map.add_child(review)
	# Main front faces west toward avenue; long axis runs north/south.
	# Avenue east asphalt edge = 7 m; sidewalk width = 2.5 m. Plaza starts exactly at 9.5 m.
	patch(Vector3(27.75,.18,76), Vector2(36.5,70), Color("c5bba3"))
	patch(Vector3(53,.18,76), Vector2(24,42), Color("c5bba3"))
	patch(Vector3(77,.12,69), Vector2(28,30), Color("777975"))
	var administration := asset("administration_four_storey_review", Vector3(53,.19,72), -PI/2)
	asset("service_garage_review", Vector3(85,.16,47))
	asset("transport_founder_monument_study", Vector3(24,.19,72), -PI/2)
	asset("blank_flagpole_review", Vector3(38,.19,94))
	# Explicit pedestrian links through open rear green rather than a whole-lot painting.
	patch(Vector3(115,.12,93), Vector2(4,68), Color("b8ae96"))
	patch(Vector3(105,.12,111), Vector2(64,3), Color("b8ae96"))
	patch(Vector3(106,.12,52), Vector2(60,3), Color("b8ae96"))
	patch(Vector3(81,.18,101), Vector2(71,3), Color("b8ae96"))
	patch(Vector3(81,.18,43), Vector2(71,3), Color("b8ae96"))
	# Service access from village street; keep it separate from the central park path.
	patch(Vector3(116,.14,36),Vector2(48,4),Color("777975"))
	patch(Vector3(92,.14,52.5),Vector2(4,33),Color("777975"))
	for z in [48,62,84,100]:
		asset("park_bench",Vector3(14,.19,z),PI/2)
		asset("park_bin",Vector3(14,.19,z+1.6))
		asset("park_lantern",Vector3(11,.19,z+3))
	for at in [Vector3(110,0,64),Vector3(110,0,82),Vector3(120,0,109),Vector3(96,0,108)]:
		asset("park_bench",at+Vector3.UP*.16)
		asset("park_bin",at+Vector3(1.6,.16,0))
		asset("park_lantern",at+Vector3(2.5,.16,2.0))
	for at in [Vector3(31,0,42),Vector3(31,0,107),Vector3(51,0,41),Vector3(51,0,108),Vector3(119,0,60),Vector3(125,0,82),Vector3(125,0,103),Vector3(98,0,120),Vector3(110,0,121)]:
		map._tree(at+Vector3.UP*.16)
		map._sprite(load("res://assets/sprites/bush.png"),at+Vector3(1.5,.16,1.5),2.2,review)
	for z in [57,74,95]:map._tree(Vector3(132,.16,z))
	for at in [Vector2(71,113),Vector2(85,116),Vector2(98,103),Vector2(103,70),Vector2(126,45),Vector2(130,63),Vector2(124,76),Vector2(122,96),Vector2(126,117),Vector2(108,118),Vector2(100,91),Vector2(88,98),Vector2(109,56),Vector2(104,46),Vector2(73,104),Vector2(65,119)]:
		map._tree(Vector3(at.x,.16,at.y))
		map._sprite(load("res://assets/sprites/bush.png"),Vector3(at.x+1.5,.16,at.y-1.2),2.6,review)
	for z in [58,86]:
		asset("park_planter_2m",Vector3(56,.16,z),PI/2)
		map._sprite(load("res://assets/sprites/bush.png"),Vector3(56,.45,z),2.0,review)
	for z in range(24,129,2):asset("park_railing_2m",Vector3(137,.16,z),PI/2)
	# Existing approved car at actual game presentation scale: no merged painted cars.
	var vehicle = load("res://assets/models/vehicles/volga_gaz24.glb").instantiate()
	review.add_child(vehicle)
	vehicle.position = Vector3(74,.18,62)
	vehicle.scale = Vector3.ONE * .90
	vehicle.rotation.y = PI/2
	var measurements := {"administration_world_bounds":str(bounds_of(administration)),"volga_world_bounds":str(bounds_of(vehicle)),"office_storeys":4,"office_height_m":14,"hall_height_m":18,"tower_e2_e3_height_m":36,"tower_e1_height_m":42,"plaza_west_edge_m":9.5,"avenue_east_edge_m":7,"sidewalk_width_m":2.5,"note":"Visual inspection metadata, no automated tests. Runtime preview only; no route or map data changes."}
	var file := FileAccess.open(SHOTS+"scale-inspection.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(measurements,"\t"))
	map._sprite(load("res://assets/sprites/person_worker.png"),Vector3(40,.19,72),.8,review)
	await create_timer(1.0).timeout
	map.set_process(false)
	for node in map._tokens.values():node.hide()
	for node in map._token_discs.values():node.hide()
	await shot("site-in-game-v3",Vector3(72,0,76),220)
	# Reverse camera is solely for the square-facing entrance review.
	map.set_process(false)
	map.camera.position = Vector3(-280,300,430)
	map.camera.look_at(Vector3(53,5,72))
	map.camera.size = 64
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(SHOTS + "square-front-in-game-v3.png")
	# Keep the review scene on screen when requested, without saving project files.
	if not OS.get_cmdline_user_args().has("--keep-open"):
		for node in cache.values():
			node.free()
		quit()
