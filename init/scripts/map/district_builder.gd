# Builds one fixed layout from lot data and reusable content recipes.
# Rendering helpers stay on CityMap; simulation locations never live here.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Catalog = preload("res://scripts/data/building_catalog.gd")
const Boundaries = preload("res://scripts/data/map_boundaries.gd")
const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const PitchedRoof = preload("res://scripts/map/pitched_roof.gd")

const YARD_ROAD_TINT := Color(1.18, 1.12, 1.02)
const WATER_LEVEL := -3.5 # River bed depth: deep enough for a barge to pass under the bridges.
const HIGHWAY_TINT := Color(0.78, 0.8, 0.87) # Newer, darker, cooler asphalt than the town streets.
const VILLAGE_SETBACK := 4.0
const FENCE_INSET := 0.6
const FENCE_STEP := 3.0
const FENCE_HEIGHT := 1.3
const FENCE_GATE := 3.6

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
	_build_village_plots()
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
	# The land is two slabs with the river bed cut out between them, plus bank walls.
	var north_edge: float = Layout.WATER.position.y
	var south_edge: float = Layout.WATER.end.y
	for part in [Vector2(-1200, north_edge), Vector2(south_edge, 1200)]:
		var depth: float = part.y - part.x
		var center_z: float = (part.x + part.y) / 2.0
		map._box(Vector3(2600, 1, depth), Vector3(0, -0.6, center_z), map.GRASS)
		map._ground_quad(Vector2(0, center_z), Vector2(2600, depth), 0.005, map._season["grass"], 44.0, false, map._season["grass_tint"])
	var wall_color := Color("6c685a")
	var wall_height := -WATER_LEVEL + 0.1
	for z in [north_edge, south_edge]:
		map._box(Vector3(2600, wall_height, 0.4), Vector3(0, WATER_LEVEL + wall_height / 2.0, z), wall_color)
	map._box(Vector3(2600, 0.5, Layout.WATER.size.y), Vector3(0, WATER_LEVEL - 0.5, (north_edge + south_edge) / 2.0), Color("3f4a47"))
	var bank: Rect2 = Layout.FOREIGN_BANK
	bank.position.x = -1300
	bank.size.x = 2600
	bank.position.y = -1200
	bank.size.y = Layout.WATER.position.y - bank.position.y
	_patch(bank, "grass_dry", 0.012)
	var river: Rect2 = Layout.WATER
	river.position.x = -1300
	river.size.x = 2600
	_patch(river, "water", WATER_LEVEL)
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
		var highway: bool = road.get("look", "") == "highway"
		# The highway sits a hair lower so every town street crossing it wins the overlap.
		var tint: Color = YARD_ROAD_TINT if yard else (HIGHWAY_TINT if highway else Color.WHITE)
		_patch(rect, ground, 0.135 if yard else (0.139 if highway else 0.14), tint)
		map._occupy(rect.get_center(), rect.size)
	# Western roads and southern rails run on past the forest, under the edge haze.
	for extension in Boundaries.road_continuations():
		var road: Dictionary = extension["road"]
		var rect: Rect2 = extension["rect"]
		var highway: bool = road.get("look", "") == "highway"
		_patch(rect, "asphalt", 0.139 if highway else 0.14, HIGHWAY_TINT if highway else Color.WHITE)
		map._occupy(rect.get_center(), rect.size)
	for bridge in Layout.BRIDGES:
		_build_bridge(bridge)
	for line in Layout.RAILS:
		for i in line.size() - 1:
			_rail_segment(line[i], line[i + 1])
	for extension in Boundaries.rail_continuations():
		_rail_segment(extension[0], extension[1]) # Registers its own occupancy.
	_build_embankment()
	_build_siding_ramp()
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
		for z in [float(Layout.EMBANKMENT["from"]), float(Layout.EMBANKMENT["to"])]:
			if z > minf(from.y, to.y) and z < maxf(from.y, to.y) and Layout.EMBANKMENT["tracks"].has(from.x):
				points.append(Vector2(from.x, z))
		points.sort_custom(func(a, b): return a.y < b.y)
	elif is_equal_approx(from.y, to.y) and is_equal_approx(from.y, float(Layout.SIDING_RAMP["z"])):
		var split: float = Layout.SIDING_RAMP["x_from"]
		if split > minf(from.x, to.x) and split < maxf(from.x, to.x):
			points.append(Vector2(split, from.y))
		points.sort_custom(func(a, b): return a.x < b.x)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var center := (a + b) / 2.0
		var on_bridge := false
		for bridge in Layout.BRIDGES:
			if bridge["kind"] == "rail" and bridge["rect"].has_point(center):
				on_bridge = true
		var embankment := Rect2(Layout.EMBANKMENT["cx"] - 15.0, Layout.EMBANKMENT["from"], 30.0, Layout.EMBANKMENT["to"] - Layout.EMBANKMENT["from"])
		if embankment.has_point(center):
			on_bridge = true
		if is_equal_approx(center.y, float(Layout.SIDING_RAMP["z"])) and center.x > float(Layout.SIDING_RAMP["x_from"]):
			on_bridge = true # The siding ramp draws its own ballast and rails.
		if on_bridge:
			continue # The bridge or the embankment draws its own ground, ballast and rails.
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
	if lot["type"] == "D":
		center += _front_shift(lot, entry)
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


# Fences and vegetable beds of every village plot are drawn as boxes in one MultiMesh,
# so 17 plots cost a single draw call instead of about a thousand.
func _build_village_plots() -> void:
	var boxes := {"transforms": [] as Array[Transform3D], "colors": [] as Array[Color]}
	for id in Layout.LOTS:
		if Layout.LOTS[id]["type"] == "D":
			_fill_plot(id, Layout.LOTS[id], boxes)
		elif Layout.LOTS[id]["content"] == "cemetery":
			_fill_cemetery(id, Layout.LOTS[id], boxes)
	if boxes["transforms"].is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = BoxMesh.new()
	multi.instance_count = boxes["transforms"].size()
	for i in boxes["transforms"].size():
		multi.set_instance_transform(i, boxes["transforms"][i])
		multi.set_instance_color(i, boxes["colors"][i])
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	var node := MultiMeshInstance3D.new()
	node.name = "VillagePlots"
	node.multimesh = multi
	node.material_override = material
	map.add_child(node)


# Lot-local frame: `v` runs from the plot centre toward the street, `u` along the street.
func _fill_plot(id: String, lot: Dictionary, boxes: Dictionary) -> void:
	var fill: Dictionary = Catalog.VILLAGE_FILL[lot["condition"]]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var rect: Rect2 = lot["rect"]
	var out: Vector2 = {"s": Vector2.DOWN, "n": Vector2.UP, "e": Vector2.RIGHT, "w": Vector2.LEFT}[lot["facing"]]
	var side := Vector2(-out.y, out.x)
	var along_x: bool = lot["facing"] in ["e", "w"]
	var depth := rect.size.x if along_x else rect.size.y
	var width := rect.size.y if along_x else rect.size.x
	var at := func(u: float, v: float) -> Vector2: return rect.get_center() + side * u + out * v

	_fence_around(id, lot, boxes, rng, fill["fence"], fill["fence_color"])

	var beds: Array[Vector2] = []
	for i in fill["beds"]:
		var u := rng.randf_range(-width / 2.0 + 9.0, width / 2.0 - 9.0)
		var v := rng.randf_range(-depth / 2.0 + 8.0, -2.0)
		var spot: Vector2 = at.call(u, v)
		if beds.any(func(other: Vector2) -> bool: return other.distance_to(spot) < 8.0) or not _clear(Rect2(spot - Vector2(4, 4), Vector2(8, 8))):
			continue
		beds.append(spot)
		_add_box(boxes, spot, Vector3(7.0, 0.12, 3.0), side, Color("5b4632"))
		if map._season["bushes"]:
			for row in 3:
				_add_box(boxes, spot + out * (row - 1) * 0.9, Vector3(6.4, 0.3, 0.45), side, Color("62803c").darkened(rng.randf_range(0.0, 0.2)))
		map._occupy(spot, Vector2(8, 4) if absf(side.x) > 0.5 else Vector2(4, 8))

	for i in fill["orchard"]:
		var spot: Vector2 = at.call(lerpf(-width / 2.0 + 7.0, width / 2.0 - 7.0, (i + 0.5) / fill["orchard"]), -depth / 2.0 + rng.randf_range(5.0, 12.0))
		if map._is_occupied(spot, 2.0) or not _clear(Rect2(spot - Vector2(2, 2), Vector2(4, 4))):
			continue
		var tree: Sprite3D = map._tree(map._ground(spot))
		tree.scale *= 0.5
		tree.position.y *= 0.5
		map._occupy(spot, Vector2(3, 3))

	if fill["shed"]:
		var back: Vector2 = at.call(signf(rng.randf() - 0.5) * (width / 2.0 - 8.0), -depth / 2.0 + 8.0)
		_prop(lot, {"sprite": "village_shed", "width": 5.0, "footprint": Vector2(5, 4)}, back)


# Fence around a plot (lot-local frame, see `_fill_plot`): `standing` is the share of
# pieces still up, the street side keeps a gate gap, and an edge shared with a lower-id
# neighbour is left to that neighbour.
func _fence_around(id: String, lot: Dictionary, boxes: Dictionary, rng: RandomNumberGenerator, standing: float, base_color: Color) -> void:
	var rect: Rect2 = lot["rect"]
	var out: Vector2 = {"s": Vector2.DOWN, "n": Vector2.UP, "e": Vector2.RIGHT, "w": Vector2.LEFT}[lot["facing"]]
	var side := Vector2(-out.y, out.x)
	var along_x: bool = lot["facing"] in ["e", "w"]
	var depth := rect.size.x if along_x else rect.size.y
	var width := rect.size.y if along_x else rect.size.x
	var at := func(u: float, v: float) -> Vector2: return rect.get_center() + side * u + out * v
	var half_u := width / 2.0 - FENCE_INSET
	var half_v := depth / 2.0 - FENCE_INSET
	# Each edge: start, end (lot-local), the direction it runs and the way it faces outward.
	var edges := [
		{"a": Vector2(-half_u, half_v), "b": Vector2(half_u, half_v), "dir": side, "outward": out, "front": true},
		{"a": Vector2(-half_u, -half_v), "b": Vector2(half_u, -half_v), "dir": side, "outward": -out, "front": false},
		{"a": Vector2(-half_u, -half_v), "b": Vector2(-half_u, half_v), "dir": out, "outward": -side, "front": false},
		{"a": Vector2(half_u, -half_v), "b": Vector2(half_u, half_v), "dir": out, "outward": side, "front": false},
	]
	for edge in edges:
		var length: float = (edge["b"] - edge["a"]).length()
		var pieces := maxi(1, int(length / FENCE_STEP))
		var step := length / pieces
		for i in pieces:
			var t: Vector2 = edge["a"] + (edge["b"] - edge["a"]).normalized() * (step * (i + 0.5))
			var world: Vector2 = at.call(t.x, t.y)
			if edge["front"] and absf(t.x) < FENCE_GATE / 2.0:
				continue
			# A fence shared with a neighbouring plot is built once, by the lower id.
			if not edge["front"] and _neighbour_plot(id, world + edge["outward"] * 1.2):
				continue
			if rng.randf() > standing:
				continue
			var color: Color = base_color.darkened(rng.randf_range(0.0, 0.14))
			var tilt := 1.0 if lot["condition"] != "abandoned" else rng.randf_range(0.55, 1.0)
			_add_box(boxes, world, Vector3(step, FENCE_HEIGHT * tilt, 0.08), edge["dir"], color)
			var start: Vector2 = t - (edge["b"] - edge["a"]).normalized() * step / 2.0
			_add_box(boxes, at.call(start.x, start.y),Vector3(0.16, FENCE_HEIGHT * tilt + 0.2, 0.16), edge["dir"], color.darkened(0.2))


# Old village cemetery: a fenced field of grave mounds in rows, mostly wooden crosses
# (some leaning), a few stone stelae, a path from the gate and a few old trees.
func _fill_cemetery(id: String, lot: Dictionary, boxes: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	var rect: Rect2 = lot["rect"]
	_fence_around(id, lot, boxes, rng, 0.9, Color("6f6150"))
	map._occupy(rect.get_center(), rect.size)
	var out: Vector2 = {"s": Vector2.DOWN, "n": Vector2.UP, "e": Vector2.RIGHT, "w": Vector2.LEFT}[lot["facing"]]
	var side := Vector2(-out.y, out.x)
	var along_x: bool = lot["facing"] in ["e", "w"]
	var depth := rect.size.x if along_x else rect.size.y
	var width := rect.size.y if along_x else rect.size.x
	var at := func(u: float, v: float) -> Vector2: return rect.get_center() + side * u + out * v
	_add_box(boxes, at.call(0.0, 0.0), Vector3(1.6, 0.08, depth - 2.0), out, Color("6e5e46"))
	var winter: bool = not map._season["bushes"]
	for row in int((depth - 10.0) / 4.2):
		for column in int((width - 6.0) / 3.2):
			var u := -width / 2.0 + 3.5 + column * 3.2 + rng.randf_range(-0.3, 0.3)
			var v := depth / 2.0 - 7.0 - row * 4.2 + rng.randf_range(-0.3, 0.3)
			if absf(u) < 1.8 or rng.randf() < 0.22:
				continue
			var spot: Vector2 = at.call(u, v)
			var lean := rng.randf_range(-0.18, 0.18)
			var along := side.rotated(lean)
			_add_box(boxes, spot, Vector3(1.0, 0.22, 2.0), side, Color("5a4a38") if not winter else Color("d6dadb"))
			if rng.randf() < 0.2:
				_add_box(boxes, spot - out * 1.1, Vector3(0.55, 1.2, 0.12), side, Color("8d8b84"))
			else:
				var post_at: Vector2 = spot - out * 1.0
				_add_box(boxes, post_at, Vector3(0.1, 1.5, 0.1), along, Color("5c4a35"))
				_add_box(boxes, post_at, Vector3(0.7, 0.1, 0.1), along, Color("5c4a35"), 1.1)
	for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 0.1)]:
		var spot: Vector2 = at.call(corner.x * (width / 2.0 - 3.0), corner.y * (depth / 2.0 - 4.0))
		map._tree(map._ground(spot))


func _neighbour_plot(id: String, point: Vector2) -> bool:
	for other in Layout.LOTS:
		if other < id and Layout.LOTS[other]["type"] == "D" and Layout.LOTS[other]["rect"].has_point(point):
			return true
	return false


# `dir` is the horizontal direction the box's long side runs along.
func _add_box(boxes: Dictionary, at: Vector2, size: Vector3, dir: Vector2, color: Color, lift: float = 0.0) -> void:
	var basis := Basis(Vector3.UP, atan2(-dir.y, dir.x)) * Basis.from_scale(size)
	boxes["transforms"].append(Transform3D(basis, map._ground(at) + Vector3.UP * (size.y / 2.0 + lift)))
	boxes["colors"].append(color)


# Village plots are deep: the house stands near the street edge, the garden lies behind it.
func _front_shift(lot: Dictionary, entry: Dictionary) -> Vector2:
	var rect: Rect2 = lot["rect"]
	var size: Vector2 = entry["footprint"]
	var along_x: bool = lot["facing"] in ["e", "w"]
	var out: Vector2 = {"s": Vector2.DOWN, "n": Vector2.UP, "e": Vector2.RIGHT, "w": Vector2.LEFT}[lot["facing"]]
	var lot_depth := rect.size.x if along_x else rect.size.y
	var house_depth := size.x if along_x else size.y
	return out * maxf(0.0, lot_depth / 2.0 - VILLAGE_SETBACK - house_depth / 2.0)


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


# --- Bridges -----------------------------------------------------------------

const CONCRETE := Color("9d9a90")
const CONCRETE_DARK := Color("7e7b72")
const STEEL_BLUE := Color("4f6168")


func _build_bridge(bridge: Dictionary) -> void:
	var rect: Rect2 = bridge["rect"]
	if bridge["kind"] == "road":
		_road_bridge(rect, float(bridge["height"]), float(bridge["ramp"]))
	else:
		_rail_bridge(rect, float(bridge["height"]), float(bridge["ramp"]), bridge.get("flat_end", false))
	map._occupy(rect.get_center(), rect.size)


# Deck height of a bridge at map z: climbs over `ramp` metres from each end.
func _deck_at(rect: Rect2, height: float, ramp: float, z: float) -> float:
	return height * clampf(minf(z - rect.position.y, rect.end.y - z) / ramp, 0.0, 1.0)


# Tilted wedge-less slab from the ground up to the deck: `north` ramps start at the
# rect's north end, the others at its south end. Returns the tilted root node.
func _ramp_root(rect: Rect2, cx: float, height: float, ramp: float, north: bool) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(cx, 0.0, rect.position.y if north else rect.end.y)
	# The north ramp rises toward +Z, the south one toward -Z.
	root.rotation.x = -atan2(height, ramp) if north else atan2(height, ramp)
	map.add_child(root)
	return root


# Concrete road bridge: a humpback deck whose ramps rise over the water, solid
# parapets, lamps, and piers standing in the river bed.
func _road_bridge(rect: Rect2, height: float, ramp: float) -> void:
	var width := rect.size.x
	var cx := rect.get_center().x
	var z0 := rect.position.y
	var z1 := rect.end.y
	var flat := Rect2(cx - width / 2.0, z0 + ramp, width, z1 - z0 - 2.0 * ramp)
	var flat_center := flat.get_center()
	map._box(Vector3(width, 0.8, flat.size.y), Vector3(cx, height - 0.4, flat_center.y), CONCRETE)
	map._box(Vector3(width + 0.4, 0.35, flat.size.y), Vector3(cx, height - 0.95, flat_center.y), CONCRETE_DARK)
	map._ground_quad(flat_center, Vector2(width - 0.8, flat.size.y), height + 0.01, map._season["asphalt"], 14.0)
	for side in [-1.0, 1.0]:
		map._box(Vector3(0.4, 1.0, flat.size.y), Vector3(cx + side * (width / 2.0 - 0.2), height + 0.5, flat_center.y), CONCRETE)
		map._box(Vector3(0.6, 0.15, flat.size.y), Vector3(cx + side * (width / 2.0 - 0.2), height + 1.07, flat_center.y), Color("b3afa0"))
	# Piers every 16 m through the water, each up to the underside of the deck.
	var water: Rect2 = Layout.WATER
	var z := z0 + 14.0
	while z < z1 - 8.0:
		var top := _deck_at(rect, height, ramp, z) - 1.15
		if z > water.position.y + 2.0 and z < water.end.y - 2.0 and top > WATER_LEVEL + 1.0:
			var bottom := WATER_LEVEL - 0.6
			map._box(Vector3(width - 4.0, top - bottom, 2.4), Vector3(cx, (top + bottom) / 2.0, z), CONCRETE_DARK)
		z += 16.0
	# Lamps along the whole deck, lit at night like the street lamps.
	var lamp := _texture("res://assets/sprites/lamp_post.png")
	z = z0 + 10.0
	while z < z1 - 6.0:
		for side in [-1.0, 1.0]:
			var base := Vector3(cx + side * (width / 2.0 - 0.6), _deck_at(rect, height, ramp, z) + 0.1, z)
			if lamp != null:
				map._sprite(lamp, base, 6.0)
			map._lamp_light(base)
		z += 24.0
	# Ramps: tilted slabs from the ground up to the deck.
	var length := sqrt(ramp * ramp + height * height)
	for north in [true, false]:
		var ramp_root := _ramp_root(rect, cx, height, ramp, north)
		var dir := 1.0 if north else -1.0
		map._box(Vector3(width, 0.8, length), Vector3(0, -0.4, dir * length / 2.0), CONCRETE, ramp_root)
		map._box(Vector3(width + 0.4, 0.35, length), Vector3(0, -0.95, dir * length / 2.0), CONCRETE_DARK, ramp_root)
		var surface := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(width - 0.8, length)
		var material := StandardMaterial3D.new()
		material.albedo_texture = map._season["asphalt"]
		material.uv1_scale = Vector3((width - 0.8) / 14.0, length / 14.0, 1.0)
		material.roughness = 0.95
		surface.mesh = quad
		surface.material_override = material
		surface.rotation.x = -PI / 2.0
		surface.position = Vector3(0, 0.02, dir * length / 2.0)
		ramp_root.add_child(surface)
		for side in [-1.0, 1.0]:
			map._box(Vector3(0.4, 1.0, length), Vector3(side * (width / 2.0 - 0.2), 0.5, dir * length / 2.0), CONCRETE, ramp_root)


# Railway on an embankment that climbs on land, then a steel through-truss over the
# river with concrete piers; one truss pair per track.
func _rail_bridge(rect: Rect2, height: float, ramp: float, bridge_flat_end: bool = false) -> void:
	var cx := rect.get_center().x
	var water: Rect2 = Layout.WATER
	var z0 := rect.position.y
	var z1 := rect.end.y
	var tracks: Array[float] = [410.0, 420.0]
	# Level deck from the first to the last point at full height.
	# `flat_end`: the deck stays at full height to the south end, where the embankment takes over.
	var flat_end: bool = bridge_flat_end
	var flat_from := z0 + ramp
	var flat_to := z1 if flat_end else z1 - ramp
	var flat_center := (flat_from + flat_to) / 2.0
	var flat_length := flat_to - flat_from
	map._box(Vector3(rect.size.x, 0.8, flat_length), Vector3(cx, height - 0.4, flat_center), CONCRETE)
	for track in tracks:
		_rail_quad(Vector3(track, height + 0.03, flat_center), flat_length, null)
	# Piers in the river bed under the level deck.
	for z in [water.position.y + water.size.y * 0.2, water.get_center().y, water.position.y + water.size.y * 0.8]:
		var top := height - 0.8
		var bottom := WATER_LEVEL - 0.6
		map._box(Vector3(rect.size.x - 2.0, top - bottom, 3.0), Vector3(cx, (top + bottom) / 2.0, z), CONCRETE_DARK)
	# Embankments: solid gravel wedges with ballast and rails on top.
	var length := sqrt(ramp * ramp + height * height)
	for north in [true, false]:
		if not north and flat_end:
			continue
		var root := _ramp_root(rect, cx, height, ramp, north)
		var dir := 1.0 if north else -1.0
		map._box(Vector3(rect.size.x, height, length), Vector3(0, -height / 2.0, dir * length / 2.0), Color("7b766a"), root)
		for track in tracks:
			_rail_quad(Vector3(track - cx, 0.03, dir * length / 2.0), length, root)
	# Truss over the water only.
	var span_from := water.position.y + 5.0
	var span_length := water.size.y - 10.0
	var bays := 16
	var bay := span_length / bays
	var truss_height := 5.4
	var boxes: Array[Transform3D] = []
	for track in tracks:
		for side in [-2.3, 2.3]:
			var x: float = track + side
			var base := height + 0.2
			boxes.append(_beam(Vector3(x, base, span_from + span_length / 2.0), Vector3(0.35, 0.35, span_length), 0.0))
			boxes.append(_beam(Vector3(x, base + truss_height, span_from + span_length / 2.0), Vector3(0.4, 0.4, span_length), 0.0))
			for i in bays + 1:
				boxes.append(_beam(Vector3(x, base + truss_height / 2.0, span_from + i * bay), Vector3(0.25, truss_height, 0.25), 0.0))
			for i in bays:
				var diagonal := sqrt(bay * bay + truss_height * truss_height)
				var angle := atan2(bay, truss_height) * (1.0 if i % 2 == 0 else -1.0)
				boxes.append(_beam(Vector3(x, base + truss_height / 2.0, span_from + (i + 0.5) * bay), Vector3(0.2, diagonal, 0.2), angle))
		for z in [span_from, span_from + span_length / 2.0, span_from + span_length]:
			boxes.append(_beam(Vector3(track, height + 0.2 + truss_height, z), Vector3(4.8, 0.3, 0.3), 0.0))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = BoxMesh.new()
	multi.instance_count = boxes.size()
	for i in boxes.size():
		multi.set_instance_transform(i, boxes[i])
	var node := MultiMeshInstance3D.new()
	node.name = "RailBridgeTruss"
	node.multimesh = multi
	node.material_override = map._material(STEEL_BLUE)
	map.add_child(node)


# One run of railway ballast along Z (local to `parent`, or the map when null).
func _rail_quad(at: Vector3, length: float, parent: Node3D) -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(length, 3.8)
	var material := StandardMaterial3D.new()
	material.albedo_texture = map._season["rail"]
	material.uv1_scale = Vector3(length / 3.8, 1, 1)
	material.roughness = 1.0
	var rail := MeshInstance3D.new()
	rail.mesh = mesh
	rail.material_override = material
	rail.rotation.x = -PI / 2.0
	rail.rotate_y(-PI / 2.0)
	rail.position = at
	(parent if parent != null else map).add_child(rail)


# --- Eastern embankment ------------------------------------------------------

# Cross-section of the embankment at height `h`: slope foot, shoulder, shoulder, foot.
func _embankment_section(cx: float, top: float, h: float) -> Array[Vector2]:
	return [Vector2(cx - top - 1.5 * h, 0.0), Vector2(cx - top, h), Vector2(cx + top, h), Vector2(cx + top + 1.5 * h, 0.0)]


func _embankment_height(z: float) -> float:
	var e: Dictionary = Layout.EMBANKMENT
	var from_ramp: float = e.get("ramp_from", e["ramp"])
	var up := (z - float(e["from"])) / from_ramp if from_ramp > 0.0 else INF
	return float(e["height"]) * clampf(minf(up, (float(e["to"]) - z) / float(e["ramp"])), 0.0, 1.0)


# A grassed railway embankment with ramps at both ends. Where a road crosses it the
# earth stops and a concrete deck carries the track over a short tunnel.
func _build_embankment() -> void:
	var e: Dictionary = Layout.EMBANKMENT
	var cx: float = e["cx"]
	var top: float = e["top"]
	var peak: float = e["height"]
	var gap: float = e["gap"]
	# Stations along z: the ends of the ramps, and the two edges of every tunnel.
	var spans: Array[Vector2] = []
	var cursor := float(e["from"])
	var cuts: Array[Vector2] = []
	for z in e["tunnels"]:
		cuts.append(Vector2(z - gap / 2.0, z + gap / 2.0))
	for cut in cuts:
		spans.append(Vector2(cursor, cut.x))
		cursor = cut.y
	spans.append(Vector2(cursor, e["to"]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ballast: Array[SurfaceTool] = []
	for track in e["tracks"]:
		var strip := SurfaceTool.new()
		strip.begin(Mesh.PRIMITIVE_TRIANGLES)
		ballast.append(strip)
	for span in spans:
		# Break the span where a ramp meets the plateau, so heights stay straight lines.
		var marks: Array[float] = [span.x]
		for z in [float(e["from"]) + float(e.get("ramp_from", e["ramp"])), float(e["to"]) - float(e["ramp"])]:
			if z > span.x and z < span.y:
				marks.append(z)
		marks.append(span.y)
		for i in marks.size() - 1:
			var za: float = marks[i]
			var zb: float = marks[i + 1]
			var a := _embankment_section(cx, top, _embankment_height(za))
			var b := _embankment_section(cx, top, _embankment_height(zb))
			for side in [[0, 1], [2, 3]]:
				_strip_quad(surface, Vector3(a[side[0]].x, a[side[0]].y, za), Vector3(a[side[1]].x, a[side[1]].y, za), Vector3(b[side[1]].x, b[side[1]].y, zb), Vector3(b[side[0]].x, b[side[0]].y, zb))
			_strip_quad(surface, Vector3(a[1].x, a[1].y, za), Vector3(a[2].x, a[2].y, za), Vector3(b[2].x, b[2].y, zb), Vector3(b[1].x, b[1].y, zb))
			for k in e["tracks"].size():
				var x: float = e["tracks"][k]
				var ha := a[1].y + 0.04
				var hb := b[1].y + 0.04
				var strip: SurfaceTool = ballast[k]
				var quad := [Vector3(x - 1.9, ha, za), Vector3(x + 1.9, ha, za), Vector3(x + 1.9, hb, zb), Vector3(x - 1.9, hb, zb)]
				var uvs := [Vector2(za / 3.8, 0), Vector2(za / 3.8, 1), Vector2(zb / 3.8, 1), Vector2(zb / 3.8, 0)]
				for index in [0, 1, 2, 0, 2, 3]:
					strip.set_uv(uvs[index])
					strip.add_vertex(quad[index])
		# Vertical end faces at the tunnels (not at the tips of the ramps).
		for z in [span.x, span.y]:
			if _embankment_height(z) > 0.1 and z != float(e["from"]):
				var s := _embankment_section(cx, top, _embankment_height(z))
				for index in [0, 1, 2, 0, 2, 3]:
					surface.set_uv(Vector2(s[index].x / 10.0, z / 10.0))
					surface.add_vertex(Vector3(s[index].x, s[index].y, z))
	surface.generate_normals()
	var earth := StandardMaterial3D.new()
	earth.albedo_texture = map._season["grass"]
	earth.albedo_color = map._season["grass_tint"] * Color(0.85, 0.85, 0.8)
	earth.roughness = 1.0
	earth.cull_mode = BaseMaterial3D.CULL_DISABLED
	earth.uv1_scale = Vector3(0.45, 0.45, 1.0)
	var node := MeshInstance3D.new()
	node.name = "RailEmbankment"
	node.mesh = surface.commit()
	node.material_override = earth
	map.add_child(node)
	var rails := StandardMaterial3D.new()
	rails.albedo_texture = map._season["rail"]
	rails.roughness = 1.0
	rails.cull_mode = BaseMaterial3D.CULL_DISABLED
	for strip in ballast:
		strip.generate_normals()
		var strip_node := MeshInstance3D.new()
		strip_node.mesh = strip.commit()
		strip_node.material_override = rails
		strip_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		map.add_child(strip_node)
	# Tunnels: concrete abutments, a deck under the ballast, rails on top.
	for cut in cuts:
		var length := cut.y - cut.x
		var middle := (cut.x + cut.y) / 2.0
		map._box(Vector3(top * 2.0 + 1.0, 1.2, length), Vector3(cx, peak - 0.6, middle), CONCRETE)
		for end in [cut.x, cut.y]:
			var inward := 1.0 if end == cut.x else -1.0
			map._box(Vector3(top * 2.0 + 1.0, peak - 0.6, 0.8), Vector3(cx, (peak - 0.6) / 2.0, end + inward * 0.4), CONCRETE_DARK)
		for track in e["tracks"]:
			_rail_quad(Vector3(track, peak + 0.04, middle), length, null)
	map._occupy(Vector2(cx, (float(e["from"]) + float(e["to"])) / 2.0), Vector2(36, float(e["to"]) - float(e["from"])))


# The port siding comes down off the elevated main line: an earth ramp from deck
# height at the junction to ground level, with ballast and rails following it.
func _build_siding_ramp() -> void:
	var r: Dictionary = Layout.SIDING_RAMP
	var z0: float = r["z"]
	var top: float = r["top"]
	var peak: float = r["height"]
	var xa: float = r["x_from"]
	var xb: float = r["x_to"]
	var xc := xb + 6.0 # Runs a little into the main embankment so the two merge.
	var marks: Array[float] = [xa, xb, xc]
	var earth := SurfaceTool.new()
	earth.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ballast := SurfaceTool.new()
	ballast.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in marks.size() - 1:
		var x0: float = marks[i]
		var x1: float = marks[i + 1]
		var h0: float = peak * clampf((x0 - xa) / (xb - xa), 0.0, 1.0)
		var h1: float = peak * clampf((x1 - xa) / (xb - xa), 0.0, 1.0)
		var a: Array[Vector2] = [Vector2(z0 - top - 1.5 * h0, 0.0), Vector2(z0 - top, h0), Vector2(z0 + top, h0), Vector2(z0 + top + 1.5 * h0, 0.0)]
		var b: Array[Vector2] = [Vector2(z0 - top - 1.5 * h1, 0.0), Vector2(z0 - top, h1), Vector2(z0 + top, h1), Vector2(z0 + top + 1.5 * h1, 0.0)]
		for side in [[0, 1], [1, 2], [2, 3]]:
			var p: int = side[0]
			var q: int = side[1]
			var quad: Array[Vector3] = [Vector3(x0, a[p].y, a[p].x), Vector3(x0, a[q].y, a[q].x), Vector3(x1, b[q].y, b[q].x), Vector3(x1, b[p].y, b[p].x)]
			for index in [0, 1, 2, 0, 2, 3]:
				earth.set_uv(Vector2(quad[index].x / 10.0, quad[index].z / 10.0))
				earth.add_vertex(quad[index])
		var strip: Array[Vector3] = [Vector3(x0, h0 + 0.04, z0 - 1.9), Vector3(x0, h0 + 0.04, z0 + 1.9), Vector3(x1, h1 + 0.04, z0 + 1.9), Vector3(x1, h1 + 0.04, z0 - 1.9)]
		for index in [0, 1, 2, 0, 2, 3]:
			ballast.set_uv(Vector2(strip[index].x / 3.8, 0.0 if strip[index].z < z0 else 1.0))
			ballast.add_vertex(strip[index])
	# The short bend where the siding leaves the main track, at deck height.
	var bend: Array = Layout.RAILS[2]
	var from: Vector2 = bend[0]
	var to: Vector2 = bend[1]
	var across := Vector2(-(to - from).y, (to - from).x).normalized() * 1.9
	var corners: Array[Vector3] = [Vector3(from.x - across.x, peak + 0.04, from.y - across.y), Vector3(from.x + across.x, peak + 0.04, from.y + across.y), Vector3(to.x + across.x, peak + 0.04, to.y + across.y), Vector3(to.x - across.x, peak + 0.04, to.y - across.y)]
	for index in [0, 1, 2, 0, 2, 3]:
		ballast.set_uv(Vector2(corners[index].x / 3.8, 0.0))
		ballast.add_vertex(corners[index])
	earth.generate_normals()
	ballast.generate_normals()
	var grass := StandardMaterial3D.new()
	grass.albedo_texture = map._season["grass"]
	grass.albedo_color = map._season["grass_tint"] * Color(0.85, 0.85, 0.8)
	grass.roughness = 1.0
	grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	grass.uv1_scale = Vector3(0.45, 0.45, 1.0)
	var earth_node := MeshInstance3D.new()
	earth_node.name = "SidingRamp"
	earth_node.mesh = earth.commit()
	earth_node.material_override = grass
	map.add_child(earth_node)
	var rails := StandardMaterial3D.new()
	rails.albedo_texture = map._season["rail"]
	rails.roughness = 1.0
	rails.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rail_node := MeshInstance3D.new()
	rail_node.mesh = ballast.commit()
	rail_node.material_override = rails
	rail_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	map.add_child(rail_node)
	map._occupy(Vector2((xa + xc) / 2.0, z0), Vector2(xc - xa, top * 2.0 + 12.0))


func _strip_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point in [a, b, c, a, c, d]:
		st.set_uv(Vector2(point.x / 10.0, point.z / 10.0))
		st.add_vertex(point)


# One box as a transform: `size` is the box extent, `tilt` turns it around the X axis
# (the truss plane is YZ), so a diagonal is a tall box leaned over.
func _beam(at: Vector3, size: Vector3, tilt: float) -> Transform3D:
	var basis := Basis(Vector3.RIGHT, tilt) * Basis.from_scale(size)
	return Transform3D(basis, at)


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
		var at := Vector2(441.0, z)
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
	var at: Vector3 = map._ground(center) + Vector3.UP * float(entry.get("lift", 0.0))
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
