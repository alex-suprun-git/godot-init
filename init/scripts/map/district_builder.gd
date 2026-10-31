# Builds one fixed layout from lot data and reusable content recipes.
# Rendering helpers stay on CityMap; simulation locations never live here.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Catalog = preload("res://scripts/data/building_catalog.gd")
const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const PitchedRoof = preload("res://scripts/map/pitched_roof.gd")

const YARD_ROAD_TINT := Color(1.18, 1.12, 1.02)

var map
var labels: Node3D
var _textures := {}


func build(city_map) -> void:
	map = city_map
	labels = Node3D.new()
	labels.name = "LotLabels"
	labels.visible = false
	map.add_child(labels)
	_build_ground()
	for id in Layout.LOTS:
		_build_lot(id, Layout.LOTS[id])
	_build_border_fence()
	_build_rail_poles()
	preload("res://scripts/map/residential_court.gd").new().build(self)
	preload("res://scripts/map/nature_places.gd").new().build(self)
	preload("res://scripts/map/heating_details.gd").new().build(map)
	_build_train_stock()


func _texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


func _build_ground() -> void:
	map._box(Vector3(2600, 1, 2400), Vector3(0, -0.6, 0), map.GRASS)
	map._ground_quad(Vector2.ZERO, Vector2(2600, 2400), 0.005, map._season["grass"], 44.0, false, map._season["grass_tint"])
	var bank: Rect2 = Layout.FOREIGN_BANK
	bank.position.x = -1300
	bank.size.x = 2600
	bank.position.y = -1200
	bank.size.y = Layout.WATER.position.y - bank.position.y
	_patch(bank, "grass_dry", 0.012)
	var river: Rect2 = Layout.WATER
	river.position.x = -1300
	river.size.x = 2600
	_patch(river, "water", 0.04)
	_patch(Rect2(Layout.WATER.position.x, Layout.WATER.end.y, Layout.WATER.size.x, 6), "paving", 0.05)
	for area in Layout.AREAS.values():
		_patch(area["rect"], area["ground"], 0.018)
	# Lot surfaces come before roads. Asphalt and tracks retain their own height.
	for id in Layout.LOTS:
		var lot: Dictionary = Layout.LOTS[id]
		var entry: Dictionary = Catalog.CONTENTS[lot["content"]]
		var condition: Dictionary = Catalog.CONDITIONS[lot["condition"]]
		var ground: String = "grass" if id == "b1_k" else entry.get("ground", "grass")
		if ground == "grass" and condition["dry_ground"]:
			ground = "grass_dry"
		_patch(lot["rect"], ground, 0.025, condition["tint"])
	for road in Layout.ROADS:
		var rect: Rect2 = road["rect"]
		# Housing-estate roads are asphalt too, just a lighter, warmer tone than the main roads.
		var ground: String = {"asphalt": "asphalt", "yard": "asphalt", "dirt": "dirt"}[road["kind"]]
		var yard: bool = road["kind"] == "yard"
		_patch(rect, ground, 0.135 if yard else 0.14, YARD_ROAD_TINT if yard else Color.WHITE)
		map._occupy(rect.get_center(), rect.size)
	for bridge in Layout.BRIDGES:
		var rect: Rect2 = bridge["rect"]
		var height: float = bridge["height"]
		var center := rect.get_center()
		map._box(Vector3(rect.size.x, 0.8, rect.size.y), Vector3(center.x, height - 0.4, center.y), Color("98978b"))
		map._ground_quad(center, rect.size, height + 0.01, map._season["asphalt"], 14.0)
		for side in [-1.0, 1.0]:
			map._box(Vector3(0.3, 1.0, rect.size.y), Vector3(center.x + side * (rect.size.x / 2 - 0.3), height + 0.5, center.y), Color("b3afa0"))
		map._occupy(center, rect.size)
	for line in Layout.RAILS:
		for i in line.size() - 1:
			_rail_segment(line[i], line[i + 1])
	map._build_road_markings()


func _patch(rect: Rect2, ground: String, height: float, condition_tint: Color = Color.WHITE) -> void:
	var tint: Color = map._season["grass_tint"] if ground in ["grass", "grass_dry"] else Color.WHITE
	if ground == "asphalt":
		tint = map._season["asphalt_tint"]
	map._ground_quad(rect.get_center(), rect.size, height, map._season[ground], 22.0 if ground in ["grass", "grass_dry", "courtyard"] else 12.0, false, tint * condition_tint)


func _rail_segment(from: Vector2, to: Vector2) -> void:
	# Split at the bridge so railway ballast follows the deck above the river.
	var points: Array[Vector2] = [from, to]
	if is_equal_approx(from.x, to.x):
		for bridge in Layout.BRIDGES:
			if bridge["kind"] != "rail":
				continue
			var deck: Rect2 = bridge["rect"]
			for z in [deck.position.y, deck.end.y]:
				if z > minf(from.y, to.y) and z < maxf(from.y, to.y):
					points.append(Vector2(from.x, z))
		points.sort_custom(func(a, b): return a.y < b.y)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var center := (a + b) / 2.0
		var mesh := QuadMesh.new()
		mesh.size = Vector2(a.distance_to(b), 3.8)
		var material := StandardMaterial3D.new()
		material.albedo_texture = map._season["rail"]
		material.uv1_scale = Vector3(a.distance_to(b) / 3.8, 1, 1)
		material.roughness = 1.0
		var rail := MeshInstance3D.new()
		rail.mesh = mesh
		rail.material_override = material
		rail.rotation.x = -PI / 2.0
		rail.rotate_y(-(b - a).angle())
		var rail_height := 0.19
		for bridge in Layout.BRIDGES:
			if bridge["kind"] == "rail" and bridge["rect"].has_point(center):
				rail_height = bridge["height"] + 0.03
		rail.position = Vector3(center.x, rail_height, center.y)
		map.add_child(rail)
		map._occupy(center, (b - a).abs() + Vector2(4, 4))


func _build_lot(id: String, lot: Dictionary) -> void:
	var entry: Dictionary = Catalog.CONTENTS[lot["content"]]
	var center: Vector2 = Layout.lot_center(id)
	var kind: String = entry["kind"]
	match kind:
		"panel", "building":
			_building(lot, entry, center, id)
		"group":
			for part in entry.get("parts", []):
				var recipe: Dictionary = part.duplicate()
				if recipe.has("sprite"):
					_prop(lot, recipe, center + part["at"])
				else:
					recipe["kind"] = "building"
					_building(lot, recipe, center + part["at"], id)
		"sprite":
			_prop(lot, entry, center)
			var size: Vector2 = entry["footprint"]
			_register_doorstep(id, lot, entry, center, size.x if lot["facing"] in ["e", "w"] else size.y)
		"station":
			var spot := _fit(lot, center + Vector2(30, 5), entry["footprint"])
			map._grounded_prop(_texture("res://assets/sprites/%s.png" % entry["sprite"]), map._ground(spot), entry["width"], true, entry.get("axes", Vector2(0.824, -0.234)))
			map._occupy(spot, entry["footprint"])
			_platform_canopy(_fit(lot, center + Vector2(-65, -14), Vector2(30, 4)))
		"garages":
			_garages(lot)
		"market":
			_market(lot)
	for prop in ([] if id == "b1_k" else entry.get("dressing", [])):
		if prop.get("sprite", "") == "garbage_pile" and not Catalog.CONDITIONS[lot["condition"]]["garbage"]:
			continue
		_prop(lot, prop, center + prop.get("at", Vector2.ZERO))
	if lot["content"] == "checkpoint":
		_checkpoint_gates(center)
	if lot["content"] == "boiler_house":
		map._build_boiler_states(center, entry)
	var label := Label3D.new()
	label.text = "%s\n%s" % [entry.get("label", id), id]
	label.font = OfficeTheme.BODY_FONT
	label.font_size = 36
	label.pixel_size = 0.3
	label.width = 320
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color("f7ecd8")
	label.outline_modulate = Color("30292b")
	label.position = Vector3(center.x, float(entry.get("height", int(entry.get("floors", 0)) * 3)) + 12, center.y)
	labels.add_child(label)


func _building(lot: Dictionary, entry: Dictionary, desired: Vector2, lot_id: String = "") -> void:
	var size: Vector2 = entry["footprint"]
	var facing: String = lot["facing"]
	var yaw: float = {"s": 0.0, "n": PI, "e": PI / 2, "w": -PI / 2}[facing]
	var footprint := Vector2(size.y, size.x) if facing in ["e", "w"] else size
	var center := desired if entry.get("lane_island", false) else _fit(lot, desired, footprint)
	var group := Node3D.new()
	group.position = map._ground(center)
	group.rotation.y = yaw
	map.add_child(group)
	var height: float = entry.get("height", int(entry.get("floors", 1)) * 3.0)
	var tint: Color = Catalog.CONDITIONS[lot["condition"]]["tint"]
	var color: Color = entry.get("placeholder_color", Color("b3ae9d")) * tint
	if entry.get("kind", "") == "panel":
		map._panel_block(size, entry["floors"], color, group)
	else:
		map._box(Vector3(size.x, height, size.y), Vector3(0, height / 2, 0), color, group)
		if not entry.has("pitched"):
			map._box(Vector3(size.x + 0.6, 0.4, size.y + 0.6), Vector3(0, height + 0.2, 0), map.PANEL_ROOF, group)
	var roof: Texture2D = _texture(entry.get("roof", "res://assets/textures/roof_tar.png"))
	if roof != null and entry.has("pitched"):
		# Gabled roof with eaves; the ridge runs along the building's long side.
		var gable := PitchedRoof.create(Vector2(size.x + 0.8, size.y + 0.8), float(entry["pitched"]), roof)
		gable.position.y = height
		gable.material_override.albedo_color = Catalog.CONDITIONS[lot["condition"]]["tint"]
		group.add_child(gable)
	elif roof != null:
		map._roof(Vector2(size.x + 0.6, size.y + 0.6), Vector3(0, height + 0.41, 0), 12.0, roof, group)
	if entry.has("facade_center"):
		var center_texture := _texture(entry["facade_center"])
		var wing_texture := _texture(entry.get("facade_wing", ""))
		var center_width: float = entry["center_width"]
		var wing_width: float = entry["wing_width"]
		if wing_texture != null:
			map._facades(Vector3.ZERO, Vector3(size.x, height, size.y), wing_texture, height * 2 / wing_width, tint, group)
		if center_texture != null:
			map._facade(Vector2(center_width, height), Vector3(0, height / 2, size.y / 2 + 0.025), 0, center_texture, Vector2.ONE, tint, group)
	else:
		var facade := _texture(entry.get("facade", ""))
		if facade != null:
			var repeats := height / (float(entry.get("facade_floors", entry.get("floors", 5))) * 3.0)
			map._facades(Vector3.ZERO, Vector3(size.x, height, size.y), facade, repeats, tint, group)
	if entry.get("kind", "") == "panel":
		map._panel_overlays(entry, size, height, group)
	map._occupy(center, footprint)
	_register_doorstep(lot_id, lot, entry, center, size.y)


# Chain-link fence along the river bank of the border strip, with gaps for the two
# bridges and the port quay. Posts are one MultiMesh; the mesh is a single alpha-cut
# quad per run with a generated diamond pattern.
const BORDER_FENCE_Z := -322.0
const BORDER_FENCE_HEIGHT := 2.4
const BORDER_FENCE_GAPS := [Vector2(-16, 6), Vector2(125, 295), Vector2(400, 430)]


func _build_border_fence() -> void:
	var runs: Array[Vector2] = []
	var from := -430.0
	for gap in BORDER_FENCE_GAPS:
		runs.append(Vector2(from, gap.x))
		from = gap.y
	runs.append(Vector2(from, 395.0))
	var posts := MultiMesh.new()
	posts.transform_format = MultiMesh.TRANSFORM_3D
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.4, BORDER_FENCE_HEIGHT + 0.3, 0.4)
	posts.mesh = post_mesh
	var spots: Array[Vector3] = []
	var net := _chainlink_material()
	for run in runs:
		var length := run.y - run.x
		if length < 4.0:
			continue
		var quad := QuadMesh.new()
		quad.size = Vector2(length, BORDER_FENCE_HEIGHT)
		var material: StandardMaterial3D = net.duplicate()
		material.uv1_scale = Vector3(length / 1.2, BORDER_FENCE_HEIGHT / 1.2, 1.0)
		var wire := MeshInstance3D.new()
		wire.mesh = quad
		wire.material_override = material
		wire.position = Vector3((run.x + run.y) / 2.0, BORDER_FENCE_HEIGHT / 2.0, BORDER_FENCE_Z)
		wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		map.add_child(wire)
		var x := run.x
		while x <= run.y + 0.01:
			spots.append(Vector3(x, (BORDER_FENCE_HEIGHT + 0.3) / 2.0, BORDER_FENCE_Z))
			x += 6.0
	posts.instance_count = spots.size()
	for i in spots.size():
		posts.set_instance_transform(i, Transform3D(Basis.IDENTITY, spots[i]))
	var instance := MultiMeshInstance3D.new()
	instance.name = "BorderFencePosts"
	instance.multimesh = posts
	instance.material_override = map._material(Color("b4b0a3"))
	map.add_child(instance)


# A tileable chain-link pattern drawn once: two sets of diagonal wires on transparency.
func _chainlink_material() -> StandardMaterial3D:
	var size := 48
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d1 := absi(((x + y) % (size / 2)) - size / 4)
			var d2 := absi((((x - y) % (size / 2)) + size / 2) % (size / 2) - size / 4)
			# A faint veil everywhere keeps the net readable from far away; wires are denser.
			var wire := minf(d1, d2) > size / 4 - 4
			image.set_pixel(x, y, Color(0.66, 0.68, 0.66, 0.85 if wire else 0.2))
	var material := StandardMaterial3D.new()
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.8
	return material


# Power poles along the two railway lines, as in the concept art.
func _build_rail_poles() -> void:
	var texture := _texture("res://assets/sprites/power_pole.png")
	if texture == null:
		return
	for z in range(-200, 380, 55):
		var at := Vector2(432.0, z)
		if not map._is_occupied(at, 0.5):
			map._sprite(texture, map._ground(at), 8.0)
	for x in range(-420, 400, 55):
		var at := Vector2(x, 418.0)
		if not map._is_occupied(at, 0.5):
			map._sprite(texture, map._ground(at), 8.0)


# Where people stand on arrival: `entry.doorstep` metres in front of the facade
# (`depth` is the building's size along its facing) on the lot's facing side.
func _register_doorstep(lot_id: String, lot: Dictionary, entry: Dictionary, center: Vector2, depth: float) -> void:
	if lot_id == "" or not entry.has("doorstep"):
		return
	var out: Vector2 = {"s": Vector2.DOWN, "n": Vector2.UP, "e": Vector2.RIGHT, "w": Vector2.LEFT}[lot["facing"]]
	map.sim.graph.set_doorstep(lot_id, center + out * (depth / 2.0 + float(entry["doorstep"])))


# Keep all footprints out of roads/railways, including village roads through plots.
func _clear(rect: Rect2) -> bool:
	for road in Layout.ROADS:
		if rect.intersects(road["rect"].grow(0.5)):
			return false
	for line in Layout.RAILS:
		for i in line.size() - 1:
			var corridor := Rect2(line[i], Vector2.ZERO).expand(line[i + 1]).grow(2.5)
			if rect.intersects(corridor):
				return false
	return true


func _fit(lot: Dictionary, desired: Vector2, size: Vector2) -> Vector2:
	var bounds: Rect2 = lot["rect"]
	for offset in [Vector2.ZERO, Vector2(0, -10), Vector2(0, 10), Vector2(-10, 0), Vector2(10, 0), Vector2(0, -20), Vector2(0, 20), Vector2(-20, 0), Vector2(20, 0)]:
		var center: Vector2 = desired + offset
		var rect := Rect2(center - size / 2, size)
		if bounds.encloses(rect) and _clear(rect):
			return center
	push_error("DistrictBuilder: no road-clear footprint for '%s' at %s" % [lot["content"], desired])
	return desired


func _prop(lot: Dictionary, entry: Dictionary, desired: Vector2) -> void:
	if entry.has("model"):
		var model_footprint: Vector2 = entry["footprint"]
		var model_center := _fit(lot, desired, model_footprint)
		var lift: float = entry.get("lift", 0.0)
		map._vehicle(entry["model"], map._ground(model_center) + Vector3.UP * (0.025 + lift), float(entry["length"]), entry.get("axis", "z"), null, int(entry.get("paint", -1)))
		map._occupy(model_center, model_footprint)
		return
	var path: String = "res://assets/sprites/%s.png" % entry["sprite"]
	var texture := _texture(path)
	if texture == null:
		var size: Vector2 = entry.get("footprint", Vector2(8, 6))
		var center := _fit(lot, desired, size)
		var height: float = entry.get("height", 4.0)
		map._box(Vector3(size.x, height, size.y), map._ground(center) + Vector3(0, height / 2, 0), entry.get("placeholder_color", Color("a49c88")))
		map._occupy(center, size)
		return
	var footprint: Vector2 = entry.get("footprint", Vector2(6, 6))
	var center := desired if entry.get("water", false) or entry.get("lane_island", false) else _fit(lot, desired, footprint)
	var at: Vector3 = map._ground(center)
	var node: Node3D
	if entry.has("axis"):
		node = map._prop(texture, at, entry.get("width", 8.0), entry["axis"])
	else:
		node = map._sprite(texture, at, entry.get("width", 8.0))
		if entry.has("tint"):
			node.modulate = entry["tint"]
	map._occupy(center, footprint)


func _platform_canopy(center: Vector2) -> void:
	var concrete := Color("9b9b91")
	map._box(Vector3(30, 0.35, 4), Vector3(center.x, 3.35, center.y), concrete)
	map._roof(Vector2(30, 4), Vector3(center.x, 3.54, center.y), 12.0)
	for x in [-13.5, -4.5, 4.5, 13.5]:
		map._box(Vector3(0.35, 3.2, 0.35), Vector3(center.x + x, 1.65, center.y), concrete)
	for x in [-9.0, 0.0, 9.0]:
		map._box(Vector3(3.0, 0.18, 0.5), Vector3(center.x + x, 0.6, center.y), Color("75695a"))
		for end in [-1.0, 1.0]:
			map._box(Vector3(0.15, 0.55, 0.4), Vector3(center.x + x + end * 1.2, 0.3, center.y), concrete)
	map._occupy(center, Vector2(30, 4))


func _garages(lot: Dictionary) -> void:
	var center: Vector2 = lot["rect"].get_center()
	for row in 3:
		for bay in 24:
			var spot := center + Vector2((bay - 11.5) * 3.2, (row - 1) * 17.0)
			var garage: Node3D = map._garage_model.create(_texture("res://assets/sprites/garage_single_v3.png"), map.PANEL_TINTS[bay % map.PANEL_TINTS.size()])
			garage.position = map._ground(spot)
			map.add_child(garage)
			map._occupy(spot, Vector2(3.2, 6))


func _market(lot: Dictionary) -> void:
	var center: Vector2 = lot["rect"].get_center()
	for row in 4:
		for col in 18:
			var spot := center + Vector2((col - 8.5) * 8, (row - 1.5) * 14)
			map._grounded_prop(_texture("res://assets/sprites/market_tent.png"), map._ground(spot), 5.6, true, Vector2(0.843, -0.366))
			map._occupy(spot, Vector2(5, 4))
	for offset in [Vector2(-82, -20), Vector2(-82, 6), Vector2(82, 20)]:
		map._sprite(_texture("res://assets/sprites/kiosk.png"), map._ground(center + offset), 3.5)


func _build_train_stock() -> void:
	var stock := _texture("res://assets/sprites/train_wagons_v2.png") # train_commuter.png
	var passenger: Array = Layout.RAILS[0]
	var station := Layout.lot_center("station")
	var platform := Geometry2D.get_closest_point_to_segment(station, passenger[0], passenger[1])
	map._prop(stock, Vector3(platform.x, 0.2, platform.y), 60.0, "x")
	var freight: Vector2 = passenger[1].lerp(passenger[2], 0.6)
	map._prop(stock, Vector3(freight.x, 0.2, freight.y), 55.0, "z")
	var siding: Array = Layout.RAILS[2]
	var transfer: Vector2 = siding[-2].lerp(siding[-1], 0.5)
	map._prop(stock, Vector3(transfer.x, 0.2, transfer.y), 40.0, "x")


func _checkpoint_gates(center: Vector2) -> void:
	# The catalog booths form islands between the checkpoint's three lanes.
	# Placeholder barrier arms span only the two outer lanes, not the whole road.
	for side in [-1.0, 1.0]:
		var at := center + Vector2(side * 11.75, -35)
		map._box(Vector3(0.3, 1.4, 0.3), Vector3(at.x - 3, 0.7, at.y), Color("73564a"))
		for stripe in 6:
			map._box(Vector3(1, 0.16, 0.16), Vector3(at.x - 2.5 + stripe, 1.2, at.y), Color("c0bbaa") if stripe % 2 == 0 else Color("a3493c"))
