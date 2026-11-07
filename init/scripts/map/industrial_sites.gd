# Dimensioned industrial ensembles. Visuals only; retain existing simulation IDs.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const Vehicles = preload("res://scripts/map/vehicle_models.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Settings = preload("res://scripts/data/settings.gd")
const GROUND = preload("res://assets/shaders/industrial_ground.gdshader")
const GRAIN = preload("res://assets/textures/ground_asphalt.png")
const PATH := "res://assets/models/industrial_sites/"
const MODELS := {
	"atp_hall": preload(PATH + "atp_hall.glb"),
	"atp_parts_store": preload(PATH + "atp_parts_store.glb"),
	"atp_tire_shop": preload(PATH + "atp_tire_shop.glb"),
	"atp_gatehouse": preload(PATH + "atp_gatehouse.glb"),
	"atp_wall_4m": preload(PATH + "atp_wall_4m.glb"),
	"atp_solid_gate": preload(PATH + "atp_solid_gate.glb"),
	"atp_tire_rack": preload(PATH + "atp_tire_rack.glb"),
	"atp_compressor": preload(PATH + "atp_compressor.glb"),
	"truck_cafe": preload(PATH + "truck_cafe.glb"),
	"customs_office": preload(PATH + "customs_office.glb"),
	"inspection_hall": preload(PATH + "inspection_hall.glb"),
	"control_canopy": preload(PATH + "control_canopy.glb"),
	"control_booth": preload(PATH + "control_booth.glb"),
	"pedestrian_control": preload(PATH + "pedestrian_control.glb"),
	"port_warehouse_main": preload(PATH + "port_warehouse_main.glb"),
	"port_warehouse_small": preload(PATH + "port_warehouse_small.glb"),
	"fuel_warehouse": preload(PATH + "fuel_warehouse.glb"),
	"fuel_tank": preload(PATH + "fuel_tank.glb"),
	"water_tower": preload(PATH + "water_tower.glb"),
	"boiler_house": preload(PATH + "boiler_house.glb"),
	"boiler_chimney": preload(PATH + "boiler_chimney.glb"),
	"garage_row_0": preload(PATH + "garage_row_0.glb"),
	"garage_row_1": preload(PATH + "garage_row_1.glb"),
	"port_crane": preload(PATH + "port_crane.glb"),
	"river_barge": preload(PATH + "river_barge.glb"),
	"fence_4m": preload(PATH + "fence_4m.glb"),
	"gate_6m": preload(PATH + "gate_6m.glb"),
	"yard_lamp": preload(PATH + "yard_lamp.glb"),
	"raised_barrier": preload(PATH + "raised_barrier.glb"),
	"pallet_stack": preload(PATH + "pallet_stack.glb"),
}
const LOT_IDS := ["atp", "truck_stop", "checkpoint", "port", "fuel_depot", "boiler", "garages"]
const BATCHED := ["fence_4m", "yard_lamp", "pallet_stack", "garage_row_0", "garage_row_1", "atp_wall_4m", "atp_solid_gate", "atp_tire_rack"]

var map
var root: Node3D
var center: Vector2
var _batches: Dictionary = {}
var _boxes: Dictionary = {}

static func supports(id: String) -> bool:
	return id in LOT_IDS

static func build_boiler_repairing(city_map, parent: Node3D, at: Vector2) -> void:
	# Keep the existing repair-state trigger, replacing its painted equipment.
	var base := Vector3(at.x, .05, at.y)
	var steel := Color("737e73")
	for x in [-13.0,-6.5,0.0,6.5,13.0]:
		for z in [11.3,13.3]:
			city_map._box(Vector3(.10,9.6,.10),base+Vector3(x,4.8,z),steel,parent)
	for y in [3.0,6.0,9.0]:
		city_map._box(Vector3(26.5,.12,2.3),base+Vector3(0,y,12.3),Color("8d8066"),parent)
		city_map._box(Vector3(26.5,.08,.08),base+Vector3(0,y+1.0,13.3),steel,parent)
		for x in [-9.75,-3.25,3.25,9.75]:
			_repair_beam(city_map,parent,base+Vector3(x-3.25,y-2.9,13.3),base+Vector3(x+3.25,y,13.3),.07,steel)
	var truck := Vehicles.create("zil_flatbed",base+Vector3(25,0,19),Vehicles.map_length("zil_flatbed"),"x",2)
	parent.add_child(truck)
	city_map._box(Vector3(2,.8,1.6),base+Vector3(24,2,19),Color("ab8c40"),parent)
	for z in [16.5,21.5]:
		city_map._box(Vector3(3,.12,.22),base+Vector3(24,.7,z),steel,parent)
		city_map._box(Vector3(.35,.7,.35),base+Vector3(24,.35,z),steel,parent)
	_repair_beam(city_map,parent,base+Vector3(24,2.4,19),base+Vector3(18,11,9),.34,Color("ab8c40"))
	_repair_beam(city_map,parent,base+Vector3(18,11,9),base+Vector3(4,12,7),.18,Color("8d7e48"))
	_repair_beam(city_map,parent,base+Vector3(4,12,7),base+Vector3(4,10,7),.035,steel)
	city_map._box(Vector3(32,.14,.12),base+Vector3(0,1.1,17),Color("c3a354"),parent)
	for x in [-16.0,0.0,16.0]:
		city_map._box(Vector3(.15,1.2,.15),base+Vector3(x,.6,17),Color("b4a17b"),parent)

static func _repair_beam(city_map, parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var node: MeshInstance3D = city_map._box(Vector3(width,a.distance_to(b),width),(a+b)/2.0,color,parent)
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func build(district_builder, id: String, lot: Dictionary) -> void:
	map = district_builder.map
	center = lot["rect"].get_center()
	root = Node3D.new()
	root.name = "Industrial_" + id
	root.position = Vector3(center.x, 0, center.y)
	root.set_meta("lot_id", id)
	root.set_meta("lot_rect", lot["rect"])
	root.add_to_group("industrial_sites")
	map.add_child(root)
	# A parcel is not available for unrelated automatic decoration.
	map._occupy(center, lot["rect"].size)
	var size: Vector2 = lot["rect"].size
	if id not in ["checkpoint", "atp"]:
		surface(Rect2(-size / 2.0, size), 1 if id == "port" else 0)
	match id:
		"atp": _atp()
		"truck_stop": _truck_stop()
		"checkpoint": _checkpoint()
		"port": _port()
		"fuel_depot": _fuel()
		"boiler":
			_boiler()
			district_builder._register_doorstep(id, lot, {"doorstep": 3.0}, center + Vector2(-7, 0), 20.0)
		"garages": _garages()
	if id == "fuel_depot":
		district_builder._register_doorstep(id, lot, {"doorstep": 3.0}, center + Vector2(-10, -20), 12.0)
	_finish_batches()

func asset(id: String, at: Vector3, yaw := 0.0, scale_factor := Vector3.ONE) -> void:
	if id in BATCHED:
		if not _batches.has(id):
			_batches[id] = []
		_batches[id].append(Transform3D(Basis(Vector3.UP, yaw).scaled(scale_factor), at))
		return
	var node: Node3D = MODELS[id].instantiate()
	node.name = id
	node.position = at
	node.rotation.y = yaw
	node.scale = scale_factor
	root.add_child(node)

func _finish_batches() -> void:
	for id in _batches:
		var source: Node3D = MODELS[id].instantiate()
		var mesh_node: MeshInstance3D = source if source is MeshInstance3D else source.find_children("*", "MeshInstance3D", true, false)[0]
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = mesh_node.mesh
		multi.instance_count = _batches[id].size()
		var local := mesh_node.transform
		if source != mesh_node:
			local = source.transform * local
		for i in multi.instance_count:
			multi.set_instance_transform(i, _batches[id][i] * local)
		var node := MultiMeshInstance3D.new()
		node.name = id
		node.multimesh = multi
		root.add_child(node)
		source.free()
	for color in _boxes:
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = BoxMesh.new()
		multi.instance_count = _boxes[color].size()
		for i in multi.instance_count:
			multi.set_instance_transform(i, _boxes[color][i])
		var node := MultiMeshInstance3D.new()
		node.name = "SiteDetails_" + color
		node.multimesh = multi
		node.material_override = map._material(Color(color))
		root.add_child(node)

func box(at: Vector3, size: Vector3, color := "97998c", yaw := 0.0) -> void:
	if not _boxes.has(color):
		_boxes[color] = []
	_boxes[color].append(Transform3D(Basis(Vector3.UP, yaw).scaled(size), at))

func line(a: Vector2, b: Vector2, width := .12, color := "d1cbb7", y := .065) -> void:
	var delta := b - a
	box(Vector3((a.x+b.x)/2.0, y, (a.y+b.y)/2.0), Vector3(delta.length(), .018, width), color, -atan2(delta.y, delta.x))

func route(points: Array, width := 8.0) -> void:
	# Painted guide edges only: these do not add roads to the ambient traffic graph.
	for i in range(points.size()-1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i+1]
		var normal := (b-a).normalized().orthogonal() * width / 2.0
		line(a+normal, b+normal, .10)
		line(a-normal, b-normal, .10)

func arrow(at: Vector2, north := false) -> void:
	var sign := -1.0 if north else 1.0
	line(at-Vector2(0,sign*2), at+Vector2(0,sign*2), .16, "dbd5bc", .165)
	line(at+Vector2(0,sign*2), at+Vector2(-1,sign*.6), .16, "dbd5bc", .165)
	line(at+Vector2(0,sign*2), at+Vector2(1,sign*.6), .16, "dbd5bc", .165)

func surface(rect: Rect2, kind := 0, y := .036) -> void:
	var material := ShaderMaterial.new()
	material.shader = GROUND
	material.set_shader_parameter("grain_texture", GRAIN)
	material.set_shader_parameter("concrete", kind == 1)
	material.set_shader_parameter("winter", Settings.season == "winter")
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var node := MeshInstance3D.new()
	node.name = "ConcreteApron" if kind == 1 else "ServiceAsphalt"
	node.mesh = mesh
	node.material_override = material
	node.rotation.x = -PI/2.0
	node.position = Vector3(rect.get_center().x, y, rect.get_center().y)
	root.add_child(node)

func fence(a: Vector2, b: Vector2) -> void:
	var delta := b-a
	var count := maxi(1, ceili(delta.length()/4.0))
	for i in count:
		var at := a + delta * ((float(i)+.5)/count)
		asset("fence_4m", Vector3(at.x,.04,at.y), -atan2(delta.y,delta.x), Vector3(delta.length()/count/4.0,1,1))

func perimeter(size: Vector2, gates: Array, north_open := false) -> void:
	var w := size.x/2.0-.7
	var d := size.y/2.0-.7
	if not north_open:
		fence(Vector2(-w,-d), Vector2(w,-d))
	fence(Vector2(-w,-d), Vector2(-w,d))
	fence(Vector2(w,-d), Vector2(w,d))
	var previous := -w
	for gate in gates:
		fence(Vector2(previous,d),Vector2(gate.x-gate.y/2.0,d))
		# Open leaves lie along the fence; the access opening remains drivable.
		asset("gate_6m",Vector3(gate.x-gate.y/2.0-3,.04,d-.18))
		previous = gate.x+gate.y/2.0
	fence(Vector2(previous,d),Vector2(w,d))

func tree(at: Vector2, scale_factor := .6) -> void:
	var node := Vegetation.create("park_poplar",Vector3(at.x,.04,at.y))
	node.scale *= scale_factor
	root.add_child(node)

func vehicle(id: String, at: Vector2, axis := "z", paint := 0, reverse := false) -> void:
	var length := 6.06 if id == "container_20ft" else Vehicles.map_length(id)
	var node := Vehicles.create(id,Vector3(at.x,.045,at.y),length,axis,paint)
	if reverse:
		node.rotation.y += PI
	node.add_to_group("parked_vehicles")
	node.set_meta("parking_footprint",Vector2(3,17) if id == "kamaz_semi" else Vector2(3,12))
	root.add_child(node)

func bays(x: float, z: float, count: int, pitch := 4.0, depth := 15.0) -> void:
	for i in range(count+1):
		line(Vector2(x+i*pitch,z-depth/2.0),Vector2(x+i*pitch,z+depth/2.0))
	line(Vector2(x,z-depth/2.0),Vector2(x+count*pitch,z-depth/2.0))

func _atp() -> void:
	preload("res://scripts/map/atp_site.gd").new().build(self)

func _truck_stop() -> void:
	asset("truck_cafe",Vector3(30,.04,-30))
	surface(Rect2(11,-23.5,38,9),1,.048)
	perimeter(Vector2(140,120),[Vector2(-48,14),Vector2(48,14)])
	bays(-59,0,7,5,20)
	bays(-59,30,7,5,20)
	for i in [0,2,4,6]:
		vehicle("kamaz_semi",Vector2(-56.5+i*5,0),"z",i)
	for i in [1,4]:
		vehicle("kamaz_semi",Vector2(-56.5+i*5,30),"z",i,true)
	bays(12,9,10,3,6)
	for i in [0,3,7]:
		vehicle("lada",Vector2(13.5+i*3,9),"z",i)
	for at in [Vector2(-62,-45),Vector2(60,42),Vector2(59,-10),Vector2(-10,48)]:
		asset("yard_lamp",Vector3(at.x,.04,at.y))
	for x in [-19,1,21,62]:
		tree(Vector2(x,51),.52)

func _checkpoint() -> void:
	# Existing 24m axis and its four traffic lanes remain clear. The 4m median
	# carries the small control booths. Passport precedes customs for imports;
	# northbound exports encounter them in the opposite order.
	surface(Rect2(-125,-60,111,120))
	surface(Rect2(14,-60,111,120))
	box(Vector3(0,.24,0),Vector3(4,.24,120),"a8aa9b")
	asset("customs_office",Vector3(-86,.045,-13))
	asset("inspection_hall",Vector3(-84,.045,30),0)
	asset("inspection_hall",Vector3(84,.045,-20),PI)
	for x in [-7.3,7.3]:
		for z in [-14,14]:
			asset("control_canopy",Vector3(x,.15,z))
			asset("control_booth",Vector3(signf(x)*1.1,.37,z))
			asset("raised_barrier",Vector3(signf(x)*12.5,.16,z+4))
	for x in [-9.5,-4.5,4.5,9.5]:
		for z in [-45,43]:
			arrow(Vector2(x,z),x>0)
	# The lay-bys rejoin upstream of their next control. Export secondary
	# rejoins before passport, matching the canonical circulation diagram.
	route([Vector2(-10,-50),Vector2(-59,-50),Vector2(-59,-24),Vector2(-13,-24)])
	route([Vector2(10,53),Vector2(69,53),Vector2(69,27),Vector2(13,27)])
	route([Vector2(-13,21),Vector2(-54,21),Vector2(-54,6),Vector2(-84,6),Vector2(-84,17)])
	route([Vector2(-84,43),Vector2(-84,51),Vector2(-13,51)])
	route([Vector2(13,0),Vector2(84,0),Vector2(84,-7)])
	route([Vector2(84,-33),Vector2(84,-45),Vector2(43,-45),Vector2(43,-8),Vector2(13,-8)])
	bays(-54,-37,3,6,18)
	bays(50,39,3,6,18)
	for x in [-51,-39]:
		vehicle("kamaz_semi",Vector2(x,-37),"z",1)
	for x in [53,65]:
		vehicle("kamaz_semi",Vector2(x,39),"z",2,true)
	# Closed perimeter with only the central controlled vehicle opening and
	# the distinct east pedestrian gate. No invented northern frontage road.
	fence(Vector2(-124,-59),Vector2(-13.5,-59))
	fence(Vector2(13.5,-59),Vector2(124,-59))
	fence(Vector2(-124,-59),Vector2(-124,59))
	fence(Vector2(124,-59),Vector2(124,59))
	fence(Vector2(-124,59),Vector2(-13.5,59))
	fence(Vector2(13.5,59),Vector2(114.5,59))
	fence(Vector2(123.5,59),Vector2(124,59))
	for x in [-13,13]:
		for z in [-55,55]:
			asset("raised_barrier",Vector3(x,.15,z))
	# Segregated two-way walkway follows the eastern boundary. Its northern
	# turn ends at the existing bridge approach, without changing bridge width.
	surface(Rect2(115,-57,8,116),1,.06)
	surface(Rect2(10,-58,113,4),1,.06)
	asset("pedestrian_control",Vector3(119,.08,33))
	fence(Vector2(114.5,-54),Vector2(114.5,28))
	fence(Vector2(114.5,38),Vector2(114.5,59))
	fence(Vector2(119,-54),Vector2(119,28))
	fence(Vector2(119,38),Vector2(119,59))
	fence(Vector2(10,-53),Vector2(114.5,-53))
	fence(Vector2(114.5,28),Vector2(115,28))
	fence(Vector2(123,28),Vector2(124,28))
	fence(Vector2(114.5,38),Vector2(115,38))
	fence(Vector2(123,38),Vector2(124,38))
	for at in [Vector2(-115,47),Vector2(-113,-47),Vector2(-26,-5),Vector2(26,37),Vector2(111,-46),Vector2(110,10)]:
		asset("yard_lamp",Vector3(at.x,.04,at.y))
	bays(-115,-39,4,3,6)
	vehicle("lada",Vector2(-110,-39),"z",3)
	for x in [-115,-95,-75,104]:
		tree(Vector2(x,54),.55)

func _port() -> void:
	# The existing siding runs at local z=15; neither warehouse nor cargo
	# touches its corridor. Two quay rails are scenery, not additional rail routes.
	asset("port_warehouse_main",Vector3(0,.045,-23))
	asset("port_warehouse_small",Vector3(12,.045,40))
	asset("port_crane",Vector3(-50,.045,-52))
	asset("river_barge",Vector3(-45,-2.4,-78))
	for z in [-56,-48]:
		line(Vector2(-72,z),Vector2(68,z),.16,"60675f",.085)
	perimeter(Vector2(160,120),[Vector2(-55,12)],true)
	# Quay edge and bollards leave the crane's portal and its rail track clear.
	box(Vector3(0,-.1,-59),Vector3(160,.7,.5),"888c80")
	for x in [-70,-35,0,35,70]:
		box(Vector3(x,.38,-56),Vector3(.65,.7,.65),"5e675e")
	for z in [-4,4]:
		for x in [35,43,51,59]:
			vehicle("container_20ft",Vector2(x,z),"x",int(x))
	for x in [-15,-11,-7,0,4]:
		asset("pallet_stack",Vector3(x,.045,-7))
	vehicle("zil_flatbed",Vector2(-52,35),"z",2)
	for at in [Vector2(-72,48),Vector2(72,48),Vector2(70,-40),Vector2(-72,-40)]:
		asset("yard_lamp",Vector3(at.x,.045,at.y))

func _fuel() -> void:
	asset("fuel_warehouse",Vector3(-10,.045,-20))
	asset("water_tower",Vector3(30,.045,-35))
	# 35 x24m concrete bund, retaining the catalog's tank-compound footprint.
	surface(Rect2(-17.5,20,35,24),1,.06)
	for z in [20,44]:
		box(Vector3(0,.60,z),Vector3(35,1.2,.24),"9b9e90")
	for x in [-17.5,17.5]:
		box(Vector3(x,.60,32),Vector3(.24,1.2,24),"9b9e90")
	for at in [Vector2(-10,27),Vector2(2,27),Vector2(2,37)]:
		asset("fuel_tank",Vector3(at.x,.07,at.y))
	# External collection manifold leads to the loading stand, not across traffic.
	line(Vector2(7,27),Vector2(7,49),.27,"7c8376",.64)
	line(Vector2(7,49),Vector2(27,49),.27,"7c8376",.64)
	for x in [12,22]:
		box(Vector3(x,.34,49),Vector3(.5,.65,1.3),"8c9184")
	box(Vector3(28,1.35,49),Vector3(2,2.7,1.1),"5c685d")
	perimeter(Vector2(95,120),[Vector2(-30,10)])
	bays(-41,-38,4,3,6)
	vehicle("zil_flatbed",Vector2(-31,8),"z",1)
	for at in [Vector2(-40,45),Vector2(38,46),Vector2(-39,-47)]:
		asset("yard_lamp",Vector3(at.x,.04,at.y))
	for x in [-10,-6,-2]:
		asset("pallet_stack",Vector3(x,.05,-8))

func _boiler() -> void:
	asset("boiler_house",Vector3(0,.04,0))
	asset("boiler_chimney",Vector3(23,.04,-15))
	surface(Rect2(-21,10.5,42,16),1,.05)
	perimeter(Vector2(100,75),[Vector2(0,14)])
	# Low coal bay and simple faceted stock replace the old painted heap.
	box(Vector3(-29,.4,19),Vector3(18,.8,11),"858c80")
	box(Vector3(-29,1.0,15),Vector3(16,1.2,.25),"7d857b")
	for i in range(6):
		box(Vector3(-35+i*2.2,1.3+sin(i*1.7)*.25,19),Vector3(3.5,1.3,6.5),"373b35",i*.31)
	for at in [Vector2(-43,28),Vector2(42,28),Vector2(-42,-27)]:
		asset("yard_lamp",Vector3(at.x,.04,at.y))
	asset("pallet_stack",Vector3(-18,.05,-7))
	# Existing HeatingInfrastructure supplies the paired pipes and valves.

func _garages() -> void:
	# Three rows, separated by16m drive aisles; a west collector reaches both
	# south-street gates. Each21m module contains six independently drawn doors.
	for row in 3:
		for col in 10:
			asset("garage_row_"+str((row+col)%2),Vector3(-115+col*25,.04,-22+row*22))
	perimeter(Vector2(290,75),[Vector2(-135,10),Vector2(134,10)])
	for x in [-135,134]:
		line(Vector2(x,35),Vector2(x,-31),.10)
	for x in [-136,-70,0,70,135]:
		asset("yard_lamp",Vector3(x,.04,31))
	vehicle("lada",Vector2(-25,10),"x",2)
	vehicle("lada",Vector2(49,-12),"x",1)
	for x in [-120,-85,-50,-15,20,55,90,120]:
		tree(Vector2(x,-32),.35)
