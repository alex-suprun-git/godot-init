# Story-driven layers over the existing boiler ensemble. No repair timer: only
# authored lot states can finish works. Fuel loss is independent of construction.
extends Node3D

const Vehicles = preload("res://scripts/map/vehicle_models.gd")
const LocationState = preload("res://scripts/map/location_state.gd")
const Schedules = preload("res://scripts/data/location_schedules.gd")
const Settings = preload("res://scripts/data/settings.gd")
const COAL_GRAIN = preload("res://assets/models/village/compacted_gravel.png")
const COAL_NORMAL = preload("res://assets/models/village/compacted_gravel_normal.png")
const STEEL := Color("626c66")
const RUST := Color("79503b")
const FELT := Color("343735")
var map
var sim
var state := "broken"
var damage: Node3D
var preparation: Node3D
var repairing: Node3D
var theft: Node3D
var full_coal: Node3D
var low_coal: Node3D
var smoke: CPUParticles3D
var worn_main: Node3D
var restored_main: Node3D
var access: LocationState
var coal_material: StandardMaterial3D
var coal_chunk: SphereMesh


func build(city_map, site_root: Node3D) -> void:
	map = city_map
	sim = map.sim
	name = "BoilerStoryStates"
	site_root.add_child(self)
	damage = _group("UnrepairedFabric")
	_build_damage()
	_build_coal()
	preparation = _group("ContractorPreparation")
	_build_preparation()
	repairing = _group("RepairWorksite")
	_build_repairs()
	theft = _group("CoalTheftLoading")
	_build_theft()
	_build_smoke()
	_build_access(site_root.get_node("VehicleGate"))
	sim.state_changed.connect(refresh)
	sim.lot_state_changed.connect(_on_lot_state)
	sim.overlay_changed.connect(_on_overlay)
	refresh()


func refresh() -> void:
	var condition: String = sim.lot_states.get("boiler", "broken")
	state = condition
	if condition == "broken" and sim.next_week.get("boiler", "") == "repairing":
		state = "preparing"
	var repaired := condition == "working"
	damage.visible = not repaired
	preparation.visible = state == "preparing"
	repairing.visible = state == "repairing"
	theft.visible = sim.overlay_on("boiler", "truck")
	if theft.visible and access.override_state == &"":
		access.set_override(&"open")
	elif not theft.visible and access.override_state == &"open":
		access.clear_override()
	var stolen: bool = sim.flags.get("coal_stolen", false)
	full_coal.visible = not stolen
	low_coal.visible = stolen
	# In cold-season views the old plant keeps firing even during repairs.
	var firing := repaired or Settings.season in ["autumn", "winter"]
	smoke.visible = firing
	if smoke.emitting != firing:
		smoke.emitting = firing
	if worn_main != null:
		worn_main.visible = not repaired
		restored_main.visible = repaired
	set_meta("condition", state)
	set_meta("coal_stock", "depleted" if stolen else "full")


func attach_heat_main(worn: Node3D, restored: Node3D) -> void:
	worn_main = worn
	restored_main = restored
	refresh()


func _on_lot_state(lot: String, _value: String) -> void:
	if lot == "boiler":
		refresh()


func _on_overlay(lot: String, _overlay: String, _shown: bool) -> void:
	if lot == "boiler":
		refresh()


func _build_access(gate: Node3D) -> void:
	access = LocationState.new()
	access.name = "AccessSchedule"
	add_child(access)
	access.state_changed.connect(func(value: StringName, animated: bool):
		gate.set_open(value == &"open", animated))
	access.configure(map.visual_clock_hour, Schedules.DAILY["boiler_access"])


func _group(title: String) -> Node3D:
	var node := Node3D.new()
	node.name = title
	add_child(node)
	return node


func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	return map._box(size, at, color, parent)


func _beam(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var node := _box(parent, (a+b)/2.0, Vector3(width, a.distance_to(b), width), color)
	node.quaternion = Quaternion(Vector3.UP, (b-a).normalized())


func _patch(parent: Node3D, at: Vector3, size: Vector2, color: Color, plane := "wall", seed_value := 0) -> void:
	# Irregular silhouettes keep spalled plaster, tar and soot from reading as
	# rectangular decals. Double-sided for both facade orientations.
	var mesh := ImmediateMesh.new()
	var material: StandardMaterial3D = map._material(color).duplicate()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	for i in 11:
		var points: Array[Vector3] = [Vector3.ZERO]
		for j in [i, i+1]:
			var angle := float(j % 11) * TAU/11.0
			var variation := .84 + .16 * sin(float((j % 11)*7+seed_value*13))
			var p := Vector2(cos(angle),sin(angle)) * size * .5 * variation
			points.append(Vector3(p.x,0,p.y) if plane == "roof" else (Vector3(0,p.y,p.x) if plane == "side" else Vector3(p.x,p.y,0)))
		for point in points:
			mesh.surface_set_normal(Vector3.UP if plane == "roof" else (Vector3.RIGHT if plane == "side" else Vector3.BACK))
			mesh.surface_add_vertex(point)
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	parent.add_child(node)


func _build_damage() -> void:
	# Failed felt, standing damp and improvised sheet repairs; not bomb damage.
	for patch in [[-8,4,9,6], [5,-4,10,7], [8,5,7,5], [-3,-7,7,4]]:
		_patch(damage,Vector3(patch[0],9.19,patch[1]),Vector2(patch[2],patch[3]),FELT,"roof",int(patch[0]))
	for patch in [[-9,1,4.0,3.0,.13], [6,5,5.0,3.5,-.2], [1,-6,3.7,2.4,.1]]:
		var sheet := _box(damage,Vector3(patch[0],9.23,patch[1]),Vector3(patch[2],.06,patch[3]),RUST)
		sheet.rotation.y = patch[4]
	for x in [-10.0,1.0,7.0]:
		_beam(damage,Vector3(x,9.22,2),Vector3(x+.6,9.65,4),.18,FELT)
	# Remaining islands of old render and salt damage against exposed brick.
	for p in [[-11,2.4,4.5,3.6],[-1.5,3,4.7,4.6],[10.5,2,4.3,3.0]]:
		_patch(damage,Vector3(p[0],p[1],10.16),Vector2(p[2],p[3]),Color("a49a7c"),"wall",int(p[0]))
	for z in [-6.0,1.0,7.0]:
		_patch(damage,Vector3(14.17,2.4,z),Vector2(4.8,3.8),Color("96947d"),"side",int(z))
	for x in [-12.0,-2.0,11.8]:
		_patch(damage,Vector3(x,4.8,10.18),Vector2(.9,7.5),Color("55584b"),"wall",int(x))
	for z in [-7.0,3.0,8.0]:
		_patch(damage,Vector3(14.18,4.4,z),Vector2(.85,7.8),Color("55584b"),"side",int(z))
	# Two boarded lights, one broken pane; enough remaining glazing for work.
	for x in [-10.0,10.0]:
		_box(damage,Vector3(x,6.9,10.22),Vector3(3.95,1.9,.08),Color("242d2b"))
		for offset in [-.65,0.0,.65]:
			var board := _box(damage,Vector3(x,6.9+offset,10.31),Vector3(4.15,.38,.1),Color("786d53"))
			board.rotation.z = .06 if x < 0 else -.08
	_box(damage,Vector3(14.24,6.5,6),Vector3(.07,1.85,2.8),Color("29302d"))
	_beam(damage,Vector3(14.32,5.8,4.7),Vector3(14.32,7.2,7.3),.19,Color("847b60"))
	for x in [-8.5,-5.7,5.3,7.0]:
		_patch(damage,Vector3(x,1.9,10.3),Vector2(.5,2.8),RUST,"wall",int(x))
	# Soot cap belongs to past operation and remains when the chimney is cold.
	map._cylinder(1.42,.62,Vector3(23,33.7,-15),Color("343b36"),damage)
	for i in 8:
		_box(damage,Vector3(-15.5+sin(i*2.1),.23,-1+i*1.1),Vector3(.5,.35,.7),Color("887f6a"))


func _build_coal() -> void:
	# Reuse the prepared aggregate maps, tinted toward black coal. Triplanar
	# projection keeps the broken stone grain continuous across the heap faces.
	coal_material = StandardMaterial3D.new()
	coal_material.albedo_texture = COAL_GRAIN
	coal_material.albedo_color = Color("555961")
	coal_material.normal_enabled = true
	coal_material.normal_texture = COAL_NORMAL
	coal_material.normal_scale = 1.35
	coal_material.uv1_triplanar = true
	coal_material.uv1_scale = Vector3.ONE * .75
	coal_material.roughness = .82
	coal_material.metallic_specular = .24
	coal_chunk = SphereMesh.new()
	coal_chunk.radial_segments = 5
	coal_chunk.rings = 2
	var chunk_material := StandardMaterial3D.new()
	chunk_material.vertex_color_use_as_albedo = true
	chunk_material.roughness = .79
	chunk_material.metallic_specular = .14
	coal_chunk.material = chunk_material
	var bay := _group("CoalBay")
	_box(bay, Vector3(-29,.09,19), Vector3(18,.12,11), Color("767b70"))
	_box(bay, Vector3(-29,.65,14), Vector3(18,1.2,.3), Color("7d857b"))
	_box(bay, Vector3(-37.8,.65,19), Vector3(.3,1.2,10), Color("7d857b"))
	full_coal = _group("CoalStockFull")
	low_coal = _group("CoalStockDepleted")
	_heap(full_coal, Vector3(-33,.16,18.5), Vector3(8.6,2.7,7.4), 7)
	_heap(full_coal, Vector3(-28,.16,19.5), Vector3(8.0,2.1,7.0), 16)
	_heap(full_coal, Vector3(-24.3,.16,19), Vector3(6.0,1.4,5.2), 2)
	_heap(low_coal, Vector3(-34,.16,16.8), Vector3(6.7,.62,4.6), 9)
	_heap(low_coal, Vector3(-30,.16,16.2), Vector3(4.6,.31,3.0), 4)
	# Fine residue and scattered pieces remain visible after the truck leaves.
	_heap(bay, Vector3(-30,.155,21), Vector3(13.8,.035,6.3), 14)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19970825
	for i in 15:
		var size := rng.randf_range(.15,.55)
		var at := Vector3(rng.randf_range(-36.5,-21.8),.16,rng.randf_range(20.2,24.3))
		_heap(bay, at, Vector3(size*1.3,size*.46,size), i)


func _heap(parent: Node3D, at: Vector3, size: Vector3, seed_value: int) -> void:
	const SIDES := 15
	var rim: Array[Vector3] = []
	var shoulder: Array[Vector3] = []
	var crest := Vector3(size.x*.06,size.y,-size.z*.10)
	for i in SIDES:
		var angle := float(i)*TAU/SIDES
		var factor := .83+.17*sin(float(i*3+seed_value))
		var foot := Vector3(cos(angle)*size.x*.5*factor,0,sin(angle)*size.z*.5*factor)
		var mid := foot.lerp(crest,.46+.08*cos(float(i*7+seed_value)))
		mid.y = size.y*(.43+.16*cos(float(i*2+seed_value)))
		rim.append(foot)
		shoulder.append(mid)
	var triangles := PackedVector3Array()
	for i in SIDES:
		var next := (i+1)%SIDES
		triangles.append_array([crest, shoulder[i], shoulder[next],
			shoulder[i], rim[i], rim[next], shoulder[i], rim[next], shoulder[next]])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in triangles:
		surface.add_vertex(vertex)
	surface.generate_normals()
	var node := MeshInstance3D.new()
	node.mesh = surface.commit()
	node.material_override = coal_material
	node.position = at
	parent.add_child(node)
	if size.y >= .25:
		_add_coal_chunks(node, triangles, size, seed_value)


func _add_coal_chunks(parent: Node3D, triangles: PackedVector3Array, size: Vector3, seed_value: int) -> void:
	# Scatter real fragments over the same triangles as the heap, so chunks
	# follow its slopes and add texture that survives the district camera.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7300 + seed_value
	var chunks := MultiMesh.new()
	chunks.transform_format = MultiMesh.TRANSFORM_3D
	chunks.use_colors = true
	chunks.mesh = coal_chunk
	chunks.instance_count = ceili(size.x * size.z * 3.3)
	var last_face := floori(triangles.size() / 3.0) - 1
	for i in chunks.instance_count:
		var face := rng.randi_range(0, last_face) * 3
		var u := rng.randf()
		var v := rng.randf()
		if u + v > 1.0:
			u = 1.0 - u
			v = 1.0 - v
		var at := triangles[face].lerp(triangles[face+1], u)
		at += v * (triangles[face+2] - triangles[face])
		var diameter := rng.randf_range(.15, .55)
		var shape := Basis(Vector3.UP, rng.randf_range(0.0, TAU))
		shape = shape.scaled(Vector3(diameter, diameter*.53, diameter*rng.randf_range(.6, 1.1)))
		chunks.set_instance_transform(i, Transform3D(shape, at + Vector3.UP * diameter*.11))
		chunks.set_instance_color(i, Color("282a2f").lerp(Color("5b5e67"), rng.randf_range(0.0, .8)).srgb_to_linear())
	var cluster := MultiMeshInstance3D.new()
	cluster.name = "LooseCoalFragments"
	cluster.multimesh = chunks
	parent.add_child(cluster)


func _build_preparation() -> void:
	for y in [.2,.5,.8]:
		_box(preparation,Vector3(7,y,19),Vector3(8,.18,1.1),STEEL)
	_box(preparation,Vector3(9,1,22),Vector3(4,1.8,2.8),Color("6b7361"))
	_notice(preparation,"ПОДРЯДЧИК ВЫБРАН\nПОДГОТОВКА РЕМОНТА",Vector3(2,2.2,14))


func _build_repairs() -> void:
	# Front-right bay only: retain the main door (-7, +10), gate (0, +29),
	# coal access to the west and the heat main (+14..34, +4..18).
	for x in [0.0,6.0,12.0]:
		for z in [11.4,13.4]:
			_beam(repairing,Vector3(x,.05,z),Vector3(x,8.2,z),.1,STEEL)
	for y in [2.8,5.6,8.0]:
		_box(repairing,Vector3(6,y,12.4),Vector3(12.6,.14,2.3),Color("8a7b5d"))
		_beam(repairing,Vector3(-.2,y+1,13.4),Vector3(12.2,y+1,13.4),.09,STEEL)
		for x in [0.0,6.0]:
			_beam(repairing,Vector3(x,y-2.7,13.4),Vector3(x+6,y,13.4),.08,STEEL)
	for x in [11.3,12.0]:
		_beam(repairing,Vector3(x,.15,14),Vector3(x,8.1,12.6),.08,STEEL)
	for i in 22:
		var y := .3+float(i)*.35
		_beam(repairing,Vector3(11.3,y,14-y*.175),Vector3(12,y,14-y*.175),.07,STEEL)
	for x in [3.0,8.0]:
		_box(repairing,Vector3(x,.5,21),Vector3(3.5,.9,2.4),Color("9b9077"))
	for x in [-.5,12.5]:
		_box(repairing,Vector3(x,.65,17),Vector3(.13,1.2,.13),STEEL)
	_box(repairing,Vector3(6,1.1,17),Vector3(13,.22,.12),Color("b8a35c"))
	var truck := Vehicles.create("zil_flatbed",Vector3(23,.05,18.7),Vehicles.map_length("zil_flatbed"),"x",2)
	repairing.add_child(truck)
	_notice(repairing,"РЕМОНТ КОТЕЛЬНОЙ\nПРОХОД СЛЕВА",Vector3(-.5,2.2,17))


func _build_theft() -> void:
	# Beside the coal bay, clear of the open gate and the building's main door.
	var truck := Vehicles.create("zil_flatbed",Vector3(-26,.05,26.2),Vehicles.map_length("zil_flatbed"),"x",0)
	theft.add_child(truck)
	_heap(theft, Vector3(-25.5,1.62,26.2), Vector3(2.7,.52,1.5), 8)
	_beam(theft,Vector3(-24,.25,23),Vector3(-23.5,1.6,23),.08,Color("8b7a58"))
	_box(theft,Vector3(-24,.22,23),Vector3(.4,.07,.6),STEEL)


func _notice(parent: Node3D, words: String, at: Vector3) -> void:
	_box(parent,at,Vector3(3,1.5,.12),Color("b8ac86"))
	_beam(parent,at-Vector3(0,2,0),at,.12,STEEL)
	var label := Label3D.new()
	label.text = words
	label.font_size = 34
	label.pixel_size = .009
	label.position = at+Vector3(0,0,.08)
	label.modulate = Color("393d33")
	parent.add_child(label)


func _build_smoke() -> void:
	smoke = CPUParticles3D.new()
	smoke.name = "ChimneySmoke"
	smoke.position = Vector3(23,34.1,-15)
	smoke.amount = 36
	smoke.lifetime = 6.0
	smoke.preprocess = smoke.lifetime
	smoke.direction = Vector3(.3,1,0)
	smoke.spread = 12
	smoke.initial_velocity_min = 2
	smoke.initial_velocity_max = 3
	smoke.gravity = Vector3(.6,.4,0)
	smoke.scale_amount_min = 2
	smoke.scale_amount_max = 4
	var puff := SphereMesh.new()
	puff.radius = .6
	puff.height = 1.2
	puff.material = map._material(Color(.65,.67,.64,.4))
	smoke.mesh = puff
	smoke.emitting = false
	add_child(smoke)
