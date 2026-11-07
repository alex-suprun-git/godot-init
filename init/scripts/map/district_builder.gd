# Builds one fixed layout from lot data and reusable content recipes.
# Rendering helpers stay on CityMap; simulation locations never live here.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Catalog = preload("res://scripts/data/building_catalog.gd")
const Boundaries = preload("res://scripts/data/map_boundaries.gd")
const RailwayRoute = preload("res://scripts/map/railway_route.gd")
const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const PitchedRoof = preload("res://scripts/map/pitched_roof.gd")
const CivicFacades = preload("res://scripts/map/civic_facades.gd")
const CivicRoofs = preload("res://scripts/map/civic_roofs.gd")
const IndustrialSites = preload("res://scripts/map/industrial_sites.gd")
const VillageSurfaces = preload("res://scripts/map/village_surfaces.gd")

const YARD_ROAD_TINT := Color(1.18, 1.12, 1.02)
const WATER_LEVEL := -3.5 # River bed depth: deep enough for a barge to pass under the bridges.
const WEST_QUAY_START := -450.0

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
	preload("res://scripts/map/civic_precinct.gd").new().build(map)
	preload("res://scripts/map/station_platform.gd").new().build(map)
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
		map._ground_quad(Vector2(0, center_z), Vector2(2600, depth), 0.005, map._season["grass"], 44.0, false, map._season["grass_tint"], true)
	var wall_color := Color("6c685a")
	var wall_height := -WATER_LEVEL + 0.1
	for z in [north_edge, south_edge]:
		var start_x := WEST_QUAY_START if z == south_edge else -1300.0
		map._box(Vector3(1300.0 - start_x, wall_height, 0.4), Vector3((start_x + 1300.0) / 2.0, WATER_LEVEL + wall_height / 2.0, z), wall_color)
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
	# The quay serves the city; beyond the western industrial edge it becomes wild bank.
	_patch(Rect2(WEST_QUAY_START, south_edge, Boundaries.east_far_x() - WEST_QUAY_START, 6), "paving", 0.05)
	_build_wild_west_bank()
	for area_id in Layout.AREAS:
		var area: Dictionary = Layout.AREAS[area_id]
		if area_id == "village":
			VillageSurfaces.ground(map,area["rect"],.019,8.0)
		else:
			_patch(area["rect"], area["ground"], 0.018)
	# Lot surfaces come before roads. Asphalt and tracks retain their own height.
	for id in Layout.LOTS:
		var lot: Dictionary = Layout.LOTS[id]
		var entry: Dictionary = Catalog.CONTENTS[lot["content"]]
		var condition: Dictionary = Catalog.CONDITIONS[lot["condition"]]
		# Customs and garages own their route/yard surfaces. A generic asphalt
		# rectangle would otherwise remain beneath their planted or earth areas.
		var ground: String = "grass" if id in ["b1_k", "checkpoint", "garages"] else entry.get("ground", "grass")
		if ground == "grass" and condition["dry_ground"]:
			ground = "grass_dry"
		if lot["type"] == "D" or id in ["church","cemetery"]:
			VillageSurfaces.ground(map,lot["rect"],.026)
		else:
			_patch(lot["rect"], ground, 0.025, condition["tint"])
		if lot["type"] == "K":
			map.wear.add_inner_edge(lot["rect"], 14.0, 0.7)
	for road in Layout.ROADS:
		var rect: Rect2 = road["rect"]
		if road.get("hub_surface", false):
			map._occupy(rect.get_center(), rect.size)
			continue
		# Housing-estate roads are asphalt too, just a lighter, warmer tone than the main roads.
		var ground: String = {"asphalt": "asphalt", "yard": "asphalt", "dirt": "dirt"}[road["kind"]]
		var yard: bool = road["kind"] == "yard"
		var highway: bool = road.get("look", "") == "highway"
		# The highway sits a hair lower so every town street crossing it wins the overlap.
		var tint: Color = YARD_ROAD_TINT if yard else Color.WHITE
		# Elevated road surfaces replace ground asphalt; leave the railway open below.
		var patches: Array[Rect2] = [rect]
		for bridge in Layout.BRIDGES:
			if bridge.get("rail_overpass", false) and rect.intersects(bridge["rect"]):
				var deck: Rect2 = bridge["rect"]
				patches = []
				if rect.position.y < deck.position.y:
					patches.append(Rect2(rect.position, Vector2(rect.size.x, deck.position.y - rect.position.y)))
				if rect.end.y > deck.end.y:
					patches.append(Rect2(rect.position.x, deck.end.y, rect.size.x, rect.end.y - deck.end.y))
		for patch in patches:
			if road["kind"] == "dirt":
				VillageSurfaces.road(map,patch)
			else:
				_patch(patch, ground, 0.135 if yard else (0.139 if highway else 0.14), tint, highway)
		if yard:
			map.wear.add_ring(rect, 4.0, 0.8)
		map._occupy(rect.get_center(), rect.size)
	# Western roads and southern rails run on past the forest, under the edge haze.
	for extension in Boundaries.road_continuations():
		var road: Dictionary = extension["road"]
		var rect: Rect2 = extension["rect"]
		var highway: bool = road.get("look", "") == "highway"
		_patch(rect, "asphalt", 0.139 if highway else 0.14, Color.WHITE, highway)
		map._occupy(rect.get_center(), rect.size)
	for bridge in Layout.BRIDGES:
		_build_bridge(bridge)
	for track in range(Layout.RAILS.size()):
		var line: Array = RailwayRoute.through_line(track) if track < 2 else Layout.RAILS[track]
		for i in line.size() - 1:
			_rail_segment(line[i], line[i + 1])
	for extension in Boundaries.rail_continuations():
		_rail_segment(extension[0], extension[1]) # Registers its own occupancy.
	_build_embankment()
	_build_siding_ramp()
	map._build_road_markings()


func _build_wild_west_bank() -> void:
	var grass := SurfaceTool.new()
	var earth := SurfaceTool.new()
	grass.begin(Mesh.PRIMITIVE_TRIANGLES)
	earth.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous: Array[Vector3] = []
	for i in range(86):
		var x := lerpf(-1300.0, WEST_QUAY_START, float(i) / 85.0)
		# Meet the existing city retaining wall at the eastern end.
		var blend := clampf((WEST_QUAY_START - x) / 28.0, 0.0, 1.0)
		var wobble := sin(x * 0.037) * 1.2 + sin(x * 0.091) * 0.6
		var shore: float = Layout.WATER.end.y - (2.2 + wobble) * blend
		var section: Array[Vector3] = [
			Vector3(x, 0.03, Layout.WATER.end.y + 7.0),
			Vector3(x, 0.025, shore),
			Vector3(x, WATER_LEVEL - 0.15, shore - (8.0 + wobble) * blend),
		]
		if not previous.is_empty():
			_strip_quad(grass, previous[0], section[0], section[1], previous[1])
			_strip_quad(earth, previous[1], section[1], section[2], previous[2])
		previous = section
	for layer in [[grass, "grass", "WildBankGrass"], [earth, "dirt", "WildBankSlope"]]:
		var surface: SurfaceTool = layer[0]
		surface.generate_normals()
		var material := StandardMaterial3D.new()
		material.albedo_texture = map._season[layer[1]]
		material.albedo_color = map._season["grass_tint"] if layer[1] == "grass" else Color("9b917c")
		material.roughness = 1.0
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var node := MeshInstance3D.new()
		node.name = layer[2]
		node.mesh = surface.commit()
		node.material_override = material
		map.add_child(node)


func _patch(rect: Rect2, ground: String, height: float, condition_tint: Color = Color.WHITE, highway: bool = false) -> void:
	if ground == "asphalt":
		map._asphalt_quad(rect, height, condition_tint, highway)
		return
	if ground in ["dirt", "courtyard", "paving"] and minf(rect.size.x, rect.size.y) <= 12.0:
		map._path_quad(rect, height, ground, condition_tint)
		return
	var tint: Color = map._season["grass_tint"] if ground in ["grass", "grass_dry"] else Color.WHITE
	var organic: bool = ground in ["grass", "grass_dry", "dirt", "courtyard"]
	map._ground_quad(rect.get_center(), rect.size, height, map._season[ground], 22.0 if ground in ["grass", "grass_dry", "courtyard"] else 12.0, false, tint * condition_tint, organic, 6.0 if ground in ["grass_dry", "dirt", "courtyard"] else 0.0)


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
	if lot["type"] == "D":
		preload("res://scripts/map/village_sites.gd").new().build(self,id,lot)
		return
	var entry: Dictionary = Catalog.CONTENTS[lot["content"]]
	if id in ["tower_e2", "tower_e3", "tower_e4"]:
		entry = entry.duplicate()
		# Match the northern tower's tan-brick textures at the same 3 m floor pitch.
		entry["tower_variant"] = "e1"
		entry["height"] = 36.0
		entry["floors"] = 12
		entry["roof"] = "res://assets/textures/facade_tower_roof_e1.png"
	var center: Vector2 = Layout.lot_center(id)
	var kind: String = "industrial_site" if IndustrialSites.supports(id) else entry["kind"]
	match kind:
		"church_ensemble":
			preload("res://scripts/map/church_ensemble.gd").new().build(self)
		"industrial_site":
			IndustrialSites.new().build(self, id, lot)
		"dormitory":
			preload("res://scripts/map/dormitory.gd").new().build(map, lot)
		"department_store_1997":
			preload("res://scripts/map/department_store.gd").new().build(self, lot, entry, id)
		"civic_venue":
			preload("res://scripts/map/civic_venues.gd").new().build(self, id, lot)
		"civic_center":
			preload("res://scripts/map/civic_center.gd").new().build(self)
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
		"wheat_field":
			preload("res://scripts/map/wheat_field.gd").new().build(map, lot)
		"garages":
			_garages(lot)
		"market":
			_market(lot)
		"painted_lot":
			_painted_lot(lot, entry, center)
		"station_hub":
			preload("res://scripts/map/station_hub.gd").new().build(map)
	for prop in ([] if id == "b1_k" or kind == "industrial_site" else entry.get("dressing", [])):
		if prop.get("sprite", "") == "garbage_pile" and not Catalog.CONDITIONS[lot["condition"]]["garbage"]:
			continue
		_prop(lot, prop, center + prop.get("at", Vector2.ZERO))
	if lot["content"] == "checkpoint" and kind != "industrial_site":
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
		var detailed_roof: bool = entry.has("tower_variant") or entry.get("civic_facade", false) or entry.get("kind", "") == "panel"
		map._roof(Vector2(size.x + 0.6, size.y + 0.6), Vector3(0, height + 0.41, 0), 12.0, roof, group, detailed_roof)
		if detailed_roof:
			var roof_style := "tower" if entry.has("tower_variant") else ("store" if lot_id == "department_store" else "housing")
			CivicRoofs.build(map, group, size, height, roof_style)
	if entry.has("tower_variant"):
		CivicFacades.tower(map, group, size, height, entry["tower_variant"], tint)
	elif entry.get("civic_facade", false):
		CivicFacades.civic(map, group, size, height, _texture(entry["facade_center"]), _texture(entry["facade_wing"]), entry["center_width"], tint)
	elif entry.has("facade_center"):
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
			if lot["content"] == "panel_9":
				map._facades(Vector3.ZERO, Vector3(size.x, height, size.y), facade, repeats, tint, group, 9, preload("res://scripts/map/facade_floors.gd").PANEL_9_BANDS)
			else:
				map._facades(Vector3.ZERO, Vector3(size.x, height, size.y), facade, repeats, tint, group)
	if entry.get("kind", "") == "panel":
		map._panel_overlays(entry, size, height, group)
	map._occupy(center, footprint)
	if entry.get("kind", "") == "panel" or entry.has("tower_variant"):
		# Residents wear the ground along their blocks, most of all in front of the doors.
		map.wear.add_ring(Rect2(center - footprint / 2.0, footprint), 9.0, 0.8)
	_register_doorstep(lot_id, lot, entry, center, size.y)


# --- Bridges -----------------------------------------------------------------

const CONCRETE := Color("9d9a90")
const CONCRETE_DARK := Color("7e7b72")
const BRIDGE_SURFACES := {
	"concrete": preload("res://assets/textures/bridge_concrete.png"),
	"ballast": preload("res://assets/textures/bridge_ballast.png"),
	"steel": preload("res://assets/textures/bridge_steel.png"),
}
var _bridge_materials := {}


# World-sized triplanar sampling keeps the same grain on narrow beams and piers.
func _bridge_material(surface: String, dark: bool = false) -> StandardMaterial3D:
	var key := "%s:%s" % [surface, dark]
	if not _bridge_materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_texture = BRIDGE_SURFACES[surface]
		material.albedo_color = Color(0.8, 0.8, 0.8) if dark else Color.WHITE
		if surface == "ballast":
			# Keep the aggregate distinct from pale concrete under summer lighting.
			material.albedo_color = Color(0.65, 0.65, 0.65)
		material.roughness = 0.75 if surface == "steel" else 0.95
		material.uv1_triplanar = true
		material.uv1_world_triplanar = true
		# One repeat is sized in metres so each painted feature stays >= 3 px at the default map camera.
		var metres := 6.0 if surface == "ballast" else 8.0
		material.uv1_scale = Vector3.ONE / metres
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_bridge_materials[key] = material
	return _bridge_materials[key]


func _bridge_concrete_box(size: Vector3, at: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var instance: MeshInstance3D = map._box(size, at, Color.WHITE, parent)
	instance.material_override = _bridge_material("concrete", color == CONCRETE_DARK)
	return instance


# Ballast covers the former bare deck; existing rail/sleeper strips remain on top.
func _rail_deck_surface(at: Vector3, width: float, length: float, parent: Node = null) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(width - 1.4, length)
	var instance := MeshInstance3D.new()
	instance.name = "BridgeBallast"
	instance.mesh = quad
	instance.material_override = _bridge_material("ballast")
	instance.rotation.x = -PI / 2.0
	instance.position = at + Vector3.UP * 0.015
	(parent if parent != null else map).add_child(instance)
	# Narrow raised concrete maintenance edges replace the broad bare white bands.
	for side in [-1.0, 1.0]:
		_bridge_concrete_box(Vector3(0.7, 0.12, length), at + Vector3(side * (width / 2.0 - 0.35), 0.06, 0), CONCRETE, parent)



func _bridge_root(bridge: Dictionary) -> Node3D:
	var bridge_root := Node3D.new()
	bridge_root.name = "Bridge_" + str(bridge["id"])
	bridge_root.set_meta("bridge_id", bridge["id"])
	bridge_root.set_meta("bridge_kind", bridge["kind"])
	bridge_root.set_meta("bridge_rect", bridge["rect"])
	bridge_root.set_meta("parking_allowed", false)
	bridge_root.add_to_group("map_bridges")
	map.add_child(bridge_root)
	return bridge_root


func _build_bridge(bridge: Dictionary) -> void:
	if bridge.get("embankment_span", false):
		return # Built with the embankment gap, under the same registered bridge ID.
	var rect: Rect2 = bridge["rect"]
	var previous_children: Array[Node] = map.get_children()
	var bridge_root := _bridge_root(bridge)
	if bridge.get("rail_overpass", false):
		_avenue_overpass(bridge)
	elif bridge["kind"] == "road":
		_road_bridge(rect, float(bridge["height"]), float(bridge["ramp"]))
	else:
		_rail_bridge(rect, float(bridge["height"]), float(bridge["ramp"]), bridge.get("flat_end", false))
	# Legacy builders add directly to map. Keep each complete structure, including
	# ramps, piers, lamps and lights, under its own stable gameplay-addressable node.
	for child in map.get_children():
		if child != bridge_root and not child in previous_children:
			child.reparent(bridge_root)
	map._occupy(rect.get_center(), rect.size)


# Four-lane avenue over live railway tracks. Segment boundaries include the
# ramp crests, so road, pavements and barriers share exactly the same profile.
func _avenue_overpass(bridge: Dictionary) -> void:
	var rect: Rect2 = bridge["rect"]
	var height: float = bridge["height"]
	var ramp: float = bridge["ramp"]
	var cx := rect.get_center().x
	var z0 := rect.position.y
	var z1 := rect.end.y
	var asphalt := ShaderMaterial.new()
	asphalt.shader = preload("res://assets/shaders/town_asphalt.gdshader")
	asphalt.set_shader_parameter("grain_texture", map.GROUND_ASPHALT)
	asphalt.set_shader_parameter("winter", map.Settings.season == "winter")
	var root := Node3D.new()
	root.name = "AvenueRailOverpass"
	map.add_child(root)
	for span in [Vector2(z0, z0 + ramp), Vector2(z0 + ramp, z1 - ramp), Vector2(z1 - ramp, z1)]:
		var z: float = span.x
		while z < span.y - 0.01:
			var end := minf(z + 5.0, span.y)
			var a := Vector3(cx, 0.10 + _deck_at(rect, height, ramp, z), z)
			var b := Vector3(cx, 0.10 + _deck_at(rect, height, ramp, end), end)
			_overpass_strip(a, b, 0.0, rect.size.x, 0.8, -0.4, CONCRETE, root)
			var surface := _overpass_strip(a, b, 0.0, 24.0, 0.02, 0.025, Color.WHITE, root)
			surface.material_override = asphalt
			# Solid paved divider replaces the planted median on the structure.
			_overpass_strip(a, b, 0.0, 4.0, 0.18, 0.09, Color("9c9b8e"), root)
			for side in [-1.0, 1.0]:
				_overpass_strip(a, b, side * 13.25, 2.5, 0.18, 0.09, Color("aaa89c"), root)
				_overpass_strip(a, b, side * 14.25, 0.32, 1.0, 0.5, CONCRETE, root)
				_overpass_strip(a, b, side * 14.25, 0.46, 0.12, 1.06, Color("888b87"), root)
				# Two traffic lanes in each direction, with continuous edge lines.
				for x in [side * 2.2, side * 11.7]:
					_overpass_strip(a, b, x, 0.12, 0.012, 0.045, Color("ddd9c9"), root)
				if int(round((z - z0) / 5.0)) % 2 == 0:
					_overpass_strip(a, b, side * 7.0, 0.12, 0.012, 0.045, Color("ddd9c9"), root)
			z = end
	# Portal supports stay outside the ballast of both E-W tracks (z=395/405).
	for z in [z0 + ramp - 5.0, z1 - ramp + 5.0]:
		var underside := 0.14 + _deck_at(rect, height, ramp, z) - 1.1
		_bridge_concrete_box(Vector3(rect.size.x - 1.0, 0.5, 1.8), Vector3(cx, underside + 0.05, z), CONCRETE_DARK, root)
		for side in [-1.0, 1.0]:
			_bridge_concrete_box(Vector3(1.4, underside, 1.4), Vector3(cx + side * 10.0, underside / 2.0, z), CONCRETE, root)
	# Modest bridge lamps, shared with the city's day/night lighting.
	var lamp := _texture("res://assets/sprites/lamp_post.png")
	for z in range(int(z0 + 15.0), int(z1), 30):
		for side in [-1.0, 1.0]:
			var base := Vector3(cx + side * 13.9, 0.32 + _deck_at(rect, height, ramp, z), z)
			if lamp != null:
				map._sprite(lamp, base, 6.0)
			map._lamp_light(base)


# A thin box whose top follows the incline between two road-surface points.
func _overpass_strip(a: Vector3, b: Vector3, x: float, width: float, thickness: float, lift: float, color: Color, parent: Node3D) -> MeshInstance3D:
	var instance = map._box(Vector3(width, thickness, a.distance_to(b)), (a + b) / 2.0 + Vector3(x, lift, 0), color, parent)
	instance.rotation.x = -atan2(b.y - a.y, b.z - a.z)
	return instance


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
	_bridge_concrete_box(Vector3(width, 0.8, flat.size.y), Vector3(cx, height - 0.4, flat_center.y), CONCRETE)
	_bridge_concrete_box(Vector3(width + 0.4, 0.35, flat.size.y), Vector3(cx, height - 0.95, flat_center.y), CONCRETE_DARK)
	map._ground_quad(flat_center, Vector2(width - 0.8, flat.size.y), height + 0.01, map._season["asphalt"], 14.0)
	for side in [-1.0, 1.0]:
		_bridge_concrete_box(Vector3(0.4, 1.0, flat.size.y), Vector3(cx + side * (width / 2.0 - 0.2), height + 0.5, flat_center.y), CONCRETE)
		_bridge_concrete_box(Vector3(0.6, 0.15, flat.size.y), Vector3(cx + side * (width / 2.0 - 0.2), height + 1.07, flat_center.y), Color("b3afa0"))
	# Piers every 16 m through the water, each up to the underside of the deck.
	var water: Rect2 = Layout.WATER
	var z := z0 + 14.0
	while z < z1 - 8.0:
		var top := _deck_at(rect, height, ramp, z) - 1.15
		if z > water.position.y + 2.0 and z < water.end.y - 2.0 and top > WATER_LEVEL + 1.0:
			var bottom := WATER_LEVEL - 0.6
			_bridge_concrete_box(Vector3(width - 4.0, top - bottom, 2.4), Vector3(cx, (top + bottom) / 2.0, z), CONCRETE_DARK)
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
		_bridge_concrete_box(Vector3(width, 0.8, length), Vector3(0, -0.4, dir * length / 2.0), CONCRETE, ramp_root)
		_bridge_concrete_box(Vector3(width + 0.4, 0.35, length), Vector3(0, -0.95, dir * length / 2.0), CONCRETE_DARK, ramp_root)
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
			_bridge_concrete_box(Vector3(0.4, 1.0, length), Vector3(side * (width / 2.0 - 0.2), 0.5, dir * length / 2.0), CONCRETE, ramp_root)


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
	_bridge_concrete_box(Vector3(rect.size.x, 0.8, flat_length), Vector3(cx, height - 0.4, flat_center), CONCRETE)
	_rail_deck_surface(Vector3(cx, height, flat_center), rect.size.x, flat_length)
	for track in tracks:
		_rail_quad(Vector3(track, height + 0.03, flat_center), flat_length, null)
	# Piers in the river bed under the level deck.
	for z in [water.position.y + water.size.y * 0.2, water.get_center().y, water.position.y + water.size.y * 0.8]:
		var top := height - 0.8
		var bottom := WATER_LEVEL - 0.6
		_bridge_concrete_box(Vector3(rect.size.x - 2.0, top - bottom, 3.0), Vector3(cx, (top + bottom) / 2.0, z), CONCRETE_DARK)
	# Embankments: solid gravel wedges with ballast and rails on top.
	var length := sqrt(ramp * ramp + height * height)
	for north in [true, false]:
		if not north and flat_end:
			continue
		var root := _ramp_root(rect, cx, height, ramp, north)
		var dir := 1.0 if north else -1.0
		map._box(Vector3(rect.size.x, height, length), Vector3(0, -height / 2.0, dir * length / 2.0), Color("7b766a"), root)
		_rail_deck_surface(Vector3(0, 0, dir * length / 2.0), rect.size.x, length, root)
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
	node.material_override = _bridge_material("steel")
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
	return Layout.embankment_height(z)


# A grassed railway embankment with ramps at both ends. Where a road crosses it the
# earth stops and a concrete deck carries the track over a short tunnel.
func _build_embankment() -> void:
	var e: Dictionary = Layout.EMBANKMENT
	var cx: float = e["cx"]
	var top: float = e["top"]
	var peak: float = e["height"]
	var gap: float = e["gap"]
	var gaps: Dictionary = e.get("gaps", {})
	# Stations along z: the ends of the ramps, and the two edges of every tunnel.
	var spans: Array[Vector2] = []
	var cursor := float(e["from"])
	var cuts: Array[Vector2] = []
	for z in e["tunnels"]:
		var half: float = float(gaps.get(z, gap)) / 2.0
		cuts.append(Vector2(z - half, z + half))
	for cut in cuts:
		spans.append(Vector2(cursor, cut.x))
		cursor = cut.y
	spans.append(Vector2(cursor, e["to"]))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var crown := SurfaceTool.new()
	crown.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ballast: Array[SurfaceTool] = []
	for track in e["tracks"]:
		var strip := SurfaceTool.new()
		strip.begin(Mesh.PRIMITIVE_TRIANGLES)
		ballast.append(strip)
	for span in spans:
		# Break the span where a ramp meets the plateau, so heights stay straight lines.
		var marks: Array[float] = [span.x]
		for z in [float(e["from"]) + float(e.get("ramp_from", e["ramp"])), Layout.embankment_south_ramp_start()]:
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
			_strip_quad(crown, Vector3(a[1].x, a[1].y + 0.015, za), Vector3(a[2].x, a[2].y + 0.015, za), Vector3(b[2].x, b[2].y + 0.015, zb), Vector3(b[1].x, b[1].y + 0.015, zb))
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
	# The same world-aligned ballast spans the whole crown, not only bridge decks.
	crown.generate_normals()
	var crown_node := MeshInstance3D.new()
	crown_node.name = "RailEmbankmentBallast"
	crown_node.mesh = crown.commit()
	crown_node.material_override = _bridge_material("ballast")
	map.add_child(crown_node)
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
	for cut_index in range(cuts.size()):
		var cut: Vector2 = cuts[cut_index]
		var crossing: Dictionary = Layout.EMBANKMENT_CROSSINGS[cut_index]
		var bridge_root := _bridge_root(Layout.bridge_by_id(crossing["id"]))
		var length := cut.y - cut.x
		var middle := (cut.x + cut.y) / 2.0
		_bridge_concrete_box(Vector3(top * 2.0 + 1.0, 1.2, length), Vector3(cx, peak - 0.6, middle), CONCRETE, bridge_root)
		for end in [cut.x, cut.y]:
			var inward := 1.0 if end == cut.x else -1.0
			_bridge_concrete_box(Vector3(top * 2.0 + 1.0, peak - 0.6, 0.8), Vector3(cx, (peak - 0.6) / 2.0, end + inward * 0.4), CONCRETE_DARK, bridge_root)
		_rail_deck_surface(Vector3(cx, peak, middle), top * 2.0 + 1.0, length, bridge_root)
		for track in e["tracks"]:
			_rail_quad(Vector3(track, peak + 0.04, middle), length, bridge_root)
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
	var doorstep: Vector2 = center + out * (depth / 2.0 + float(entry["doorstep"]))
	# Local facade X follows the building rotation; tower entrances occupy an outer bay.
	var facade_right := Vector2(out.y, -out.x)
	doorstep += facade_right * float(entry.get("door_offset", 0.0))
	map.sim.graph.set_doorstep(lot_id, doorstep)
	map.wear.add_disc(doorstep, 10.0, 1.0)


# Keep all footprints out of roads/railways, including village roads through plots.
func _clear(rect: Rect2) -> bool:
	for road in Layout.ROADS:
		if rect.intersects(road["rect"].grow(0.5)):
			return false
	for track in range(Layout.RAILS.size()):
		var line: Array = RailwayRoute.through_line(track) if track < 2 else Layout.RAILS[track]
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


func _painted_lot(lot: Dictionary, entry: Dictionary, center: Vector2) -> void:
	var texture := _texture("res://assets/sprites/%s.png" % entry["sprite"])
	if texture == null:
		push_error("DistrictBuilder: missing painted lot '%s'" % entry["sprite"])
		return
	# Grounded strips seat the painted site's front contour on the terrain while
	# retaining the height of its buildings, trees and other painted objects.
	var node := preload("res://scripts/map/grounded_props.gd").new().create(
		texture, entry["width"], false, entry["anchor"], entry["axes"], map.CAMERA_VIEWS["iso"])
	node.name = entry.get("node_name", "CityParkPainted")
	var footprint: Vector2 = entry["footprint"]
	node.position = map._ground(center + entry.get("offset", Vector2.ZERO) + footprint / 2.0) + Vector3.UP * 0.06
	map.add_child(node)
	# The painting already contains its trees, furniture and lawns.
	map._occupy(center, lot["rect"].size)


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
	var traffic := preload("res://scripts/map/railway_traffic.gd").new()
	traffic.name = "RailwayTraffic"
	map.add_child(traffic)
	var stock := _texture("res://assets/sprites/train_wagons_v2.png") # train_commuter.png
	# The station tracks stay clear; freight stock remains on the port siding.
	var siding: Array = Layout.RAILS[2]
	# Stored wagons belong to the level loading reach, before the ramp begins.
	var ramp_foot := Vector2(float(Layout.SIDING_RAMP["x_from"]),float(Layout.SIDING_RAMP["z"]))
	var transfer: Vector2 = siding[-1].lerp(ramp_foot, 0.5)
	map._prop(stock, Vector3(transfer.x, 0.2, transfer.y), 40.0, "x")


func _checkpoint_gates(center: Vector2) -> void:
	# The catalog booths form islands between the checkpoint's three lanes.
	# Placeholder barrier arms span only the two outer lanes, not the whole road.
	for side in [-1.0, 1.0]:
		var at := center + Vector2(side * 11.75, -35)
		map._box(Vector3(0.3, 1.4, 0.3), Vector3(at.x - 3, 0.7, at.y), Color("73564a"))
		for stripe in 6:
			map._box(Vector3(1, 0.16, 0.16), Vector3(at.x - 2.5 + stripe, 1.2, at.y), Color("c0bbaa") if stripe % 2 == 0 else Color("a3493c"))
