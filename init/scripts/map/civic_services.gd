# Police station and polyclinic as authored Blender buildings (art/models/civic_service_buildings),
# plus their fenced territory: perimeter fence with gates, paths and a service drive.
# Lots face east: the model's front (+Z) is turned towards +X, the rear sits near the lot's back edge.
extends RefCounted

const GROUND := 0.03
const FENCE_INSET := 0.3
const CONCRETE := Color(0.64, 0.63, 0.59)
const CONCRETE_DARK := Color(0.50, 0.49, 0.46)

static var _box_mesh: BoxMesh

var _boxes: Array = [] # [size, centre, colour]


func build(builder, lot: Dictionary, entry: Dictionary, id: String) -> void:
	var map = builder.map
	if lot["facing"] != "e":
		push_error("CivicServices: only east-facing lots are supported, got '%s'" % lot["facing"])
		return
	var rect: Rect2 = lot["rect"]
	var rear: float = entry["rear_extent"]
	var front: float = entry["front_extent"]
	var width: float = entry["width_extent"]
	var origin := Vector2(rect.position.x + entry.get("rear_gap", 1.0) + rear, rect.get_center().y)
	var root: Node3D = (load(entry["model"]) as PackedScene).instantiate()
	root.name = entry.get("node_name", id.to_pascal_case())
	root.position = Vector3(origin.x, .16, origin.y)
	root.rotation.y = PI / 2.0
	map.add_child(root)
	var span := Vector2(rear + front, width)
	map._occupy(Vector2(origin.x + (front - rear) / 2.0, origin.y), span)
	# People arrive on the pavement just in front of the entrance steps.
	builder._register_doorstep(id, lot, {"doorstep": 1.5}, Vector2(origin.x + front - 0.5, origin.y), 1.0)
	for path: Dictionary in entry.get("paths", []):
		_path(rect, origin, front, path)
	_fence(rect, origin, entry["fence"], entry.get("gates", []))
	# Keep street lamps and trees out of the gate approaches on the pavement side.
	for gate: Dictionary in entry.get("gates", []):
		map._occupy(Vector2(rect.end.x + 1.0, origin.y + float(gate["dz"])), Vector2(4.0, float(gate["w"]) + 2.0))
	_flush(map, "Territory_" + id)
	if entry.get("yard", "") == "police":
		preload("res://scripts/map/police_yard.gd").new().build(map, rect, origin)
	if entry.get("yard", "") == "clinic":
		preload("res://scripts/map/clinic_yard.gd").new().build(map, builder, rect, origin)
	map._occupy(rect.get_center(), rect.size)


func _add(size: Vector3, at: Vector3, colour: Color) -> void:
	_boxes.append([size, at, colour])


# Flat strip from the street edge to the entrance steps (or `to_x` when given), centred dz from the door axis.
func _path(rect: Rect2, origin: Vector2, front: float, path: Dictionary) -> void:
	var x0: float = rect.end.x - FENCE_INSET
	var x1: float = float(path["to_x"]) if path.has("to_x") else origin.x + front
	var z: float = origin.y + float(path.get("dz", 0.0))
	_add(Vector3(x0 - x1, 0.02, float(path["w"])), Vector3((x0 + x1) / 2.0, GROUND + 0.012, z), path["color"])


func _fence(rect: Rect2, origin: Vector2, style: String, gates: Array) -> void:
	var north := rect.position.y + FENCE_INSET
	var south := rect.end.y - FENCE_INSET
	var west := rect.position.x + FENCE_INSET
	var east := rect.end.x - FENCE_INSET
	_run(style, Vector2(west, north), Vector2(east, north), [])
	_run(style, Vector2(west, south), Vector2(east, south), [])
	_run(style, Vector2(west, north), Vector2(west, south), [])
	var gaps: Array = []
	for gate: Dictionary in gates:
		var centre: float = origin.y + float(gate["dz"])
		gaps.append(Vector2(centre - float(gate["w"]) / 2.0, centre + float(gate["w"]) / 2.0))
	gaps.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	_run(style, Vector2(east, north), Vector2(east, south), gaps)
	for gap: Vector2 in gaps:
		for edge in [gap.x, gap.y]:
			_post(style, Vector2(east, edge), true)


# One fence side between two points on the same axis; `gaps` are intervals along it left open.
func _run(style: String, a: Vector2, b: Vector2, gaps: Array) -> void:
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	var s0 := a.x if along_x else a.y
	var s1 := b.x if along_x else b.y
	var fixed := a.y if along_x else a.x
	var cursor := s0
	var spans: Array = []
	for gap: Vector2 in gaps:
		if gap.x > cursor:
			spans.append(Vector2(cursor, gap.x))
		cursor = maxf(cursor, gap.y)
	if cursor < s1:
		spans.append(Vector2(cursor, s1))
	for span: Vector2 in spans:
		var length := span.y - span.x
		var count := maxi(1, roundi(length / (2.0 if style == "concrete" else 3.0)))
		var step := length / count
		for i in count:
			var start := span.x + i * step
			var mid := start + step / 2.0
			if style == "concrete":
				_concrete_panel(along_x, fixed, start, step)
			else:
				_metal_panel(along_x, fixed, start, step)
			_post(style, _at(along_x, fixed, start), false)
		_post(style, _at(along_x, fixed, span.y), false)


func _at(along_x: bool, fixed: float, s: float) -> Vector2:
	return Vector2(s, fixed) if along_x else Vector2(fixed, s)


func _size(along_x: bool, length: float, height: float, thick: float) -> Vector3:
	return Vector3(length, height, thick) if along_x else Vector3(thick, height, length)


func _concrete_panel(along_x: bool, fixed: float, start: float, step: float) -> void:
	var mid := _at(along_x, fixed, start + step / 2.0)
	_add(_size(along_x, step - 0.04, 2.2, 0.12), Vector3(mid.x, GROUND + 1.1, mid.y), CONCRETE)
	# Rib grooves and a capping strip, as on standard precast fence panels.
	for y in [0.55, 1.1, 1.65]:
		_add(_size(along_x, step - 0.3, 0.07, 0.15), Vector3(mid.x, GROUND + y, mid.y), CONCRETE_DARK)
	_add(_size(along_x, step, 0.1, 0.24), Vector3(mid.x, GROUND + 2.25, mid.y), CONCRETE_DARK)


func _metal_panel(along_x: bool, fixed: float, start: float, step: float) -> void:
	var mid := _at(along_x, fixed, start + step / 2.0)
	var green := Color(0.13, 0.27, 0.17)
	_add(_size(along_x, step, 0.3, 0.2), Vector3(mid.x, GROUND + 0.15, mid.y), CONCRETE)
	for y in [0.45, 1.5]:
		_add(_size(along_x, step, 0.07, 0.08), Vector3(mid.x, GROUND + y, mid.y), green)
	var bars := maxi(2, int(step / 0.22))
	for i in bars:
		var s := start + (i + 0.5) * step / bars
		var at := _at(along_x, fixed, s)
		_add(Vector3(0.04, 1.2, 0.04), Vector3(at.x, GROUND + 0.9, at.y), green)


func _post(style: String, at: Vector2, gate: bool) -> void:
	if style == "concrete":
		var height := 2.7 if gate else 2.45
		_add(Vector3(0.28, height, 0.28), Vector3(at.x, GROUND + height / 2.0, at.y), CONCRETE_DARK)
		if gate:
			_add(Vector3(0.4, 0.14, 0.4), Vector3(at.x, GROUND + height + 0.07, at.y), CONCRETE)
	else:
		var height := 2.3 if gate else 1.75
		_add(Vector3(0.36, height, 0.36), Vector3(at.x, GROUND + height / 2.0, at.y), Color(0.58, 0.50, 0.42))
		_add(Vector3(0.46, 0.12, 0.46), Vector3(at.x, GROUND + height + 0.06, at.y), CONCRETE)


# All fence/path boxes of one lot share one MultiMesh with vertex colours.
func _flush(map, node_name: String) -> void:
	if _box_mesh == null:
		_box_mesh = BoxMesh.new()
		_box_mesh.size = Vector3.ONE
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = 0.92
		_box_mesh.material = material
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = _box_mesh
	instances.instance_count = _boxes.size()
	for i in _boxes.size():
		instances.set_instance_transform(i, Transform3D(Basis.IDENTITY.scaled(_boxes[i][0]), _boxes[i][1]))
		var colour: Color = _boxes[i][2]
		instances.set_instance_color(i, colour.srgb_to_linear())
	var visual := MultiMeshInstance3D.new()
	visual.name = node_name
	visual.multimesh = instances
	map.add_child(visual)
