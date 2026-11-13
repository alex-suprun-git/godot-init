# One measured, shared churchyard; the JSON also drives the Blender sources.
extends RefCounted

const PLAN_PATH := "res://scripts/data/church_site.json"
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Settings = preload("res://scripts/data/settings.gd")
const PATH := "res://assets/models/church_ensemble/"
const MODELS := {
	"church": preload(PATH + "church.glb"),
	"parish_house": preload(PATH + "parish_house.glb"),
	"shed": preload(PATH + "shed.glb"),
	"fence_panel": preload(PATH + "fence_panel.glb"),
	"gate": preload(PATH + "gate.glb"),
	"grave_cross": preload(PATH + "grave_cross.glb"),
	"grave_stone": preload(PATH + "grave_stone.glb"),
	"grave_recent": preload(PATH + "grave_recent.glb"),
	"grave_rails": preload(PATH + "grave_rails.glb"),
	"bench": preload(PATH + "bench.glb"),
}
const BATCHED := ["fence_panel", "grave_cross", "grave_stone", "grave_recent", "grave_rails", "bench"]
var map
var root: Node3D
const WEATHERING := Color(0.74, 0.75, 0.72)
var _weathered := {}
var _batches := {}
var _details := {}
var _flowers: Array[Transform3D] = []
var _flower_colors: Array[Color] = []
var _rng := RandomNumberGenerator.new()


func build(builder) -> void:
	map = builder.map
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PLAN_PATH))
	root = Node3D.new()
	root.name = "ChurchEnsemble"
	map.add_child(root)
	_rng.seed = 371997
	for id in ["church", "cemetery"]:
		var rect: Rect2 = builder.Layout.LOTS[id]["rect"]
		map._occupy(rect.get_center(), rect.size)
	for id in ["church", "parish_house", "shed"]:
		_asset(id, _v(plan[id]["center"]))
	map.sim.graph.set_doorstep("church", _point(plan["church"]["entrance"]))
	for path in plan["paths"]:
		var a := Vector2(path[0], path[1])
		var b := Vector2(path[2], path[3])
		var width: float = path[4]
		var size := (b-a).abs() + (Vector2(width, 0) if is_equal_approx(a.x,b.x) else Vector2(0,width))
		builder._patch(Rect2((a+b)/2.0-size/2.0, size), "dirt", .055, Color("c8c1a5"))
	var outline: Array = plan["perimeter"]
	var gate := _point(plan["gate"]["center"])
	var half_opening: float = plan["gate"]["opening_width"] / 2.0
	for i in outline.size():
		var a := _point(outline[i])
		var b := _point(outline[(i+1)%outline.size()])
		if is_equal_approx(a.y,gate.y) and is_equal_approx(b.y,gate.y):
			_fence(a, Vector2(gate.x-half_opening, gate.y))
			_fence(Vector2(gate.x+half_opening,gate.y), b)
		else:
			_fence(a,b)
	_asset("gate",_v(plan["gate"]["center"]))
	for tree in plan["trees"]:
		var node := Vegetation.create("park_deciduous_tree",Vector3(tree[0],.04,tree[1]))
		node.scale *= float(tree[2]) / float(Vegetation.HEIGHTS["park_deciduous_tree"])
		node.rotation.y = _rng.randf_range(-PI,PI)
		root.add_child(node)
	for bench in plan["benches"]:
		var yaw := float(bench[2])*PI/2.0
		var pad_size := Vector2(2.4,1.1) if int(bench[2])%2 == 0 else Vector2(1.1,2.4)
		builder._patch(Rect2(Vector2(bench[0],bench[1])-pad_size/2.0,pad_size), "dirt", .056, Color("c8c1a5"))
		_asset("bench",Vector3(bench[0],.07,bench[1]),yaw)
	_graves(plan)
	for bed in plan["flowerbeds"]:
		var at := Vector3(bed[0],.10,bed[1])
		_detail(at,Vector3(bed[2],.10,bed[3]),Color("514432"))
		for sign_value in [-1,1]:
			_detail(at+Vector3(0,.03,sign_value*(bed[3]/2.0+.03)),Vector3(bed[2]+.16,.12,.09),Color("a09c88"))
		if Settings.season != "winter":
			for i in int(bed[2]*7):
				_flower(Vector2(bed[0]+_rng.randf_range(-bed[2]/2.0+.12,bed[2]/2.0-.12),bed[1]+_rng.randf_range(-bed[3]/2.0+.1,bed[3]/2.0-.1)))
	for planting in plan["shrubs"]:
		var shrub := Vegetation.create("park_shrub",Vector3(planting[0],.04,planting[1]))
		shrub.scale *= float(planting[2])
		shrub.rotation.y = _rng.randf_range(-PI,PI)
		root.add_child(shrub)
	_finish_batches()
	print("Church ensemble: metre-scale meshes; shared perimeter, 3.6m vehicle gate and 1m wicket; graves=", root.get_meta("grave_count",0))


func _graves(plan: Dictionary) -> void:
	var count := 0
	for row in plan["grave_rows"].size():
		var z: float = plan["grave_rows"][row]
		for column in plan["grave_columns"].size():
			var x: float = plan["grave_columns"][column]
			var at := Vector2(x,z)+Vector2(_rng.randf_range(-.10,.10),_rng.randf_range(-.10,.10))
			var near_tree := false
			for tree in plan["trees"]:
				if at.distance_to(Vector2(tree[0],tree[1])) < 2.6:
					near_tree = true
			if near_tree:
				continue
			var recent: bool = row >= 4 and (row*10+column)%4 == 0
			var model := "grave_recent" if recent else ("grave_stone" if (row+column)%3 == 0 else "grave_cross")
			var yaw := _rng.randf_range(-.065,.065) if not recent else .0
			_asset(model,Vector3(at.x,.04,at.y),yaw)
			if (row*10+column)%3 == 1:
				_asset("grave_rails",Vector3(at.x,.04,at.y),yaw)
			if Settings.season != "winter" and (recent or column%3 == 0):
				for i in (8 if recent else 4):
					_flower(at+Vector2(_rng.randf_range(-.28,.28),_rng.randf_range(-.5,.1)))
			count += 1
	root.set_meta("grave_count",count)


func _fence(a: Vector2, b: Vector2) -> void:
	var delta := b-a
	if delta.length() < .1:
		return
	var count := maxi(1,ceili(delta.length()/3.0))
	for i in count:
		var at := a+delta*(float(i)+.5)/count
		_asset("fence_panel",Vector3(at.x,.04,at.y),-delta.angle(),Vector3(delta.length()/count/3.0,1,1))


func _asset(id: String, at: Vector3, yaw := .0, scale_factor := Vector3.ONE) -> void:
	if id in BATCHED:
		if not _batches.has(id):
			_batches[id] = []
		_batches[id].append(Transform3D(Basis(Vector3.UP,yaw).scaled(scale_factor),at))
		return
	var node: Node3D = MODELS[id].instantiate()
	node.name = id
	node.position = at
	if id in ["church", "parish_house"]:
		_weather(node)
	root.add_child(node)


# The painted walls and green roofs were far brighter than the weathered village around them.
func _weather(node: Node) -> void:
	for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var base := mesh.mesh.surface_get_material(surface)
			if not base is BaseMaterial3D:
				continue
			if not _weathered.has(base):
				var worn: BaseMaterial3D = base.duplicate()
				worn.albedo_color = base.albedo_color * WEATHERING
				_weathered[base] = worn
			mesh.set_surface_override_material(surface, _weathered[base])


func _detail(at: Vector3, size: Vector3, color: Color) -> void:
	if not _details.has(color):
		_details[color] = []
	_details[color].append(Transform3D(Basis.from_scale(size),at))


func _flower(at: Vector2) -> void:
	var height := _rng.randf_range(.18,.32)
	_detail(Vector3(at.x,.1+height/2.0,at.y),Vector3(.025,height,.025),Color("46613a"))
	_flowers.append(Transform3D(Basis.from_scale(Vector3(.13,.07,.13)),Vector3(at.x,.1+height,at.y)))
	_flower_colors.append([Color("bd8e93"),Color("d7cba6"),Color("bc8a46")][_rng.randi_range(0,2)])


func _finish_batches() -> void:
	for id in _batches:
		var source: Node3D = MODELS[id].instantiate()
		var mesh_node: MeshInstance3D = source if source is MeshInstance3D else source.find_children("*","MeshInstance3D",true,false)[0]
		var local := mesh_node.transform
		if source != mesh_node:
			local = source.transform * local
		var transforms: Array = []
		for transform in _batches[id]:
			transforms.append(transform*local)
		_multimesh(id,mesh_node.mesh,transforms)
		source.free()
	for color in _details:
		var node := _multimesh("GroundDetails",BoxMesh.new(),_details[color])
		node.material_override = map._material(color)
	if not _flowers.is_empty():
		var sphere := SphereMesh.new()
		sphere.radius = .5
		sphere.height = 1.0
		sphere.radial_segments = 6
		sphere.rings = 3
		var node := _multimesh("SeasonalFlowers",sphere,_flowers,true)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = .95
		node.material_override = material
		for i in _flower_colors.size():
			node.multimesh.set_instance_color(i,_flower_colors[i])


func _multimesh(label: String, mesh: Mesh, transforms: Array, colors := false) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = colors
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.multimesh = multi
	root.add_child(node)
	return node


func _point(value: Array) -> Vector2:
	return Vector2(value[0],value[1])


func _v(value: Array) -> Vector3:
	return Vector3(value[0],.04,value[1])
