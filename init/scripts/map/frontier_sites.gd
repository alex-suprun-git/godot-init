# Complete service compounds beside the border; metres relative to each lot.
# Markings and stored vehicles are scenery, not simulated border processing.
extends RefCounted

const AccessGate = preload("res://scripts/map/access_gate.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Settings = preload("res://scripts/data/settings.gd")
const GROUND = preload("res://assets/shaders/atp_ground.gdshader")
const GRAIN = preload("res://assets/textures/ground_asphalt.png")
var site

func build(owner, id: String) -> void:
	site = owner
	# Match the actual road surface: .10 root + .036 asphalt = .136 m.
	site.root.position.y = .10
	site.root.set_meta("visual_revision", "frontier-compact-v2")
	match id:
		"checkpoint": checkpoint()
		"fuel_depot": fuel()
		"port": port()
		"truck_stop": truck_stop()
		"boiler": boiler()
		"garages": garages()

func ground(rect: Rect2, concrete := false, height := .036) -> void:
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var material := ShaderMaterial.new()
	material.shader = GROUND
	material.set_shader_parameter("grain_texture", GRAIN)
	material.set_shader_parameter("concrete", concrete)
	material.set_shader_parameter("winter", Settings.season == "winter")
	var node := MeshInstance3D.new()
	node.name = "WorkingConcrete" if concrete else "CirculationAsphalt"
	node.mesh = mesh
	node.material_override = material
	node.rotation.x = -PI / 2.0
	node.position = Vector3(rect.get_center().x, height, rect.get_center().y)
	site.root.add_child(node)
	site.map._occupy(site.center + rect.get_center(), rect.size)

func paint(a: Vector2, b: Vector2, width := .11, color := "bcb9a2") -> void:
	site.line(a, b, width, color, .052)

func rounded_path(points: Array) -> Array[Vector2]:
	# Rounded quadratic corners, instead of right-angle yard turns. This is a
	# visual centreline, not a swept-envelope or navigation implementation.
	var smooth: Array[Vector2] = [points[0]]
	for i in range(1, points.size() - 1):
		var corner: Vector2 = points[i]
		var before: Vector2 = points[i-1]
		var after: Vector2 = points[i+1]
		var radius := minf(10.0, minf(corner.distance_to(before), corner.distance_to(after)) * .42)
		var a := corner.move_toward(before, radius)
		var b := corner.move_toward(after, radius)
		smooth.append(a)
		for j in range(1, 9):
			var t := float(j) / 8.0
			smooth.append(a.lerp(corner, t).lerp(corner.lerp(b, t), t))
	smooth.append(points[-1])
	return smooth

func path(points: Array, width := 8.0) -> void:
	var smooth := rounded_path(points)
	for i in range(smooth.size()-1):
		var a := smooth[i]
		var b := smooth[i+1]
		var normal := (b-a).normalized().orthogonal() * width / 2.0
		paint(a+normal, b+normal, .09)
		paint(a-normal, b-normal, .09)

func green(rect: Rect2, kerb := true) -> void:
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var material := StandardMaterial3D.new()
	material.albedo_texture = site.map._season["grass"]
	material.albedo_color = site.map._season["grass_tint"]
	material.roughness = 1.0
	material.uv1_scale = Vector3(rect.size.x/8.0, rect.size.y/8.0, 1)
	var node := MeshInstance3D.new()
	node.name = "PlantedBuffer"
	node.mesh = mesh
	node.material_override = material
	node.rotation.x = -PI/2.0
	node.position = Vector3(rect.get_center().x, .075, rect.get_center().y)
	site.root.add_child(node)
	if kerb:
		for edge in [[rect.position,Vector2(rect.end.x,rect.position.y)],
			[Vector2(rect.position.x,rect.end.y),rect.end],
			[rect.position,Vector2(rect.position.x,rect.end.y)],
			[Vector2(rect.end.x,rect.position.y),rect.end]]:
			site.line(edge[0],edge[1],.18,"929784",.083)

func plant(at: Vector2, shrub := false, factor := .53, yaw := 0.0) -> void:
	var node := Vegetation.create("park_shrub" if shrub else "park_deciduous_tree", Vector3(at.x,.076,at.y))
	node.scale *= factor
	node.rotation.y = yaw
	site.root.add_child(node)

func drain(a: Vector2, b: Vector2) -> void:
	paint(a,b,.30,"4e5954")
	var delta := b-a
	var count := maxi(1, int(delta.length()/.55))
	for i in count:
		var at := a+delta*(float(i)+.5)/float(count)
		var across := delta.normalized().orthogonal()*.17
		paint(at-across,at+across,.065,"899085")

func parking(at: Vector2, count: int, pitch := 3.0, depth := 6.0) -> void:
	for i in range(count+1):
		paint(at+Vector2(i*pitch,-depth/2),at+Vector2(i*pitch,depth/2))
	paint(at+Vector2(0,-depth/2),at+Vector2(count*pitch,-depth/2))

func lamp(at: Vector2) -> void:
	site.asset("yard_lamp",Vector3(at.x,.04,at.y))

func gate(x: float, half_width: float, z: float, moving := false) -> void:
	var leaves: Node3D
	if moving:
		leaves = AccessGate.new()
		leaves.name = "VehicleGate"
		site.root.add_child(leaves)
	for side in [-1.0, 1.0]:
		var hinge := Vector3(x+side*half_width,.04,z)
		if moving:
			# Leaves swing into the yard and meet with a small gap.
			leaves.add_hinged_leaf(site.MODELS["gate_6m"],hinge,half_width-.10,-side,deg_to_rad(87.0),6.0)
		else:
			site.asset("gate_6m",hinge-Vector3(0,0,half_width/2),PI/2.0,Vector3(half_width/6,1,1))
		site.box(Vector3(hinge.x,1.4,z),Vector3(.22,2.8,.22),"58665d")

func enclosure(size: Vector2, openings: Array, pedestrian := 0.0, solid := false, rail_z := 100000.0, moving_gate := false) -> void:
	var w := size.x/2-.8
	var d := size.y/2-.8
	boundary(Vector2(-w,-d),Vector2(w,-d),solid)
	for x in [-w,w]:
		if absf(rail_z) < d:
			boundary(Vector2(x,-d),Vector2(x,rail_z-5),solid)
			boundary(Vector2(x,rail_z+5),Vector2(x,d),solid)
		else:
			boundary(Vector2(x,-d),Vector2(x,d),solid)
	var previous := -w
	var slots: Array = openings.duplicate()
	if pedestrian != 0.0:
		slots.append(Vector2(pedestrian,1.8))
	slots.sort_custom(func(a,b): return a.x < b.x)
	for opening in slots:
		boundary(Vector2(previous,d),Vector2(opening.x-opening.y/2,d),solid)
		gate(opening.x,opening.y/2,d,moving_gate and opening.x != pedestrian)
		previous=opening.x+opening.y/2
	boundary(Vector2(previous,d),Vector2(w,d),solid)

func boundary(a: Vector2, b: Vector2, solid := false) -> void:
	if a.distance_to(b) < .05:
		return
	if not solid:
		site.fence(a,b)
		return
	var delta := b-a
	var count := maxi(1,ceili(delta.length()/4.0))
	for i in count:
		var at := a+delta*(float(i)+.5)/count
		site.asset("atp_wall_4m",Vector3(at.x,.04,at.y),-atan2(delta.y,delta.x),Vector3(delta.length()/count/4,1,1))

func access(x: float, z: float, depth: float, width: float) -> void:
	ground(Rect2(x-width/2,z,width,depth))
	drain(Vector2(x-width/2,z+1),Vector2(x+width/2,z+1))

func place(id: String, at: Vector3, title: String, yaw := 0.0) -> void:
	site.asset(id,at,yaw)
	var node: Node3D = site.root.get_child(site.root.get_child_count()-1)
	node.name = title
	node.set_meta("site_zone",title)
	if site.root.get_meta("lot_id") == "checkpoint":
		node.add_to_group("border_control_zones")

func checkpoint() -> void:
	preload("res://scripts/map/border_checkpoint.gd").new().build(self)

func fuel() -> void:
	# 95 x 82 m, pulled toward the highway. The siding now lies at local z=-4.
	ground(Rect2(-46,-40,92,80))
	site.asset("fuel_warehouse",Vector3(-10,.04,-24))
	site.asset("water_tower",Vector3(30,.04,-27))
	site.asset("fuel_pump_house",Vector3(29,.04,10))
	site.asset("fuel_loading_gantry",Vector3(30,.045,29),PI/2.0)
	ground(Rect2(-27,-18,34,12),true,.044)
	ground(Rect2(20,15,19,22),true,.044)
	# Keep the siding/ramp clear, including the two side boundary openings.
	for x in [-40.0,-25.0]:
		paint(Vector2(x,-9),Vector2(x,1),.12,"b0a388")
	ground(Rect2(-17.5,4,35,24),true,.06)
	for z in [4.0,28.0]:
		site.box(Vector3(0,.60,z),Vector3(35,1.2,.24),"969c8c")
	for x in [-17.5,17.5]:
		site.box(Vector3(x,.60,16),Vector3(.24,1.2,24),"969c8c")
	for at in [Vector2(-10,11),Vector2(2,11),Vector2(2,21)]:
		site.asset("fuel_tank",Vector3(at.x,.07,at.y))
		site.line(Vector2(at.x+4,at.y),Vector2(12,at.y),.20,"65756a",.70)
	site.line(Vector2(12,9),Vector2(12,32),.25,"65756a",.70)
	site.line(Vector2(12,32),Vector2(27,32),.25,"65756a",.70)
	for x in [13.0,20.0]:
		site.box(Vector3(x,.3,32),Vector3(.4,.6,1.2),"8e9387")
	for i in 5:
		site.box(Vector3(-17.5+float(i)*.40,.18+float(i)*.22,23),Vector3(.5,.18,1.2),"9c9d8e")
	site.asset("atp_gatehouse",Vector3(-17,.04,32))
	ground(Rect2(-20,29,5,11),true,.047)
	ground(Rect2(-43,-39,85,3),true,.044)
	parking(Vector2(-40,-32),3)
	site.vehicle("lada",Vector2(-35.5,-32),"z",2)
	site.vehicle("zil_flatbed",Vector2(-13,-11),"x",1)
	for x in [-23.0,-20.0,-17.0]:
		site.asset("pallet_stack",Vector3(x,.045,-16))
	path([Vector2(-32,43),Vector2(-32,-11),Vector2(13,-11),Vector2(13,-31)])
	access(-32,39,5,11)
	enclosure(Vector2(95,82),[Vector2(-32,11)],-19,true,-4.0)
	green(Rect2(38,-34,5,28))
	green(Rect2(-44,7,7,30))
	green(Rect2(-11,35,49,3))
	for at in [Vector2(-41,12),Vector2(-41,30),Vector2(40,-31),Vector2(40,-14)]:
		plant(at,false,.38,at.y)
	for x in [-5.0,7.0,20.0,33.0]:
		plant(Vector2(x,37),true,.5)
	for at in [Vector2(-40,-18),Vector2(40,-37),Vector2(39,36)]:
		lamp(at)
	drain(Vector2(-26,-7),Vector2(7,-7))
	# The former northern asphalt is grass with an irregular seasonal belt.
	for row in 2:
		for col in 5:
			plant(Vector2(-38+col*18+sin(float(col)*2)*2,-69+row*18+cos(float(col))*2),false,.47+float(col%2)*.07,float(col))

func port() -> void:
	# 120 x 120 m. Both unchanged-size warehouses, the siding and quay fit
	# around one western collector instead of a broad unassigned apron.
	ground(Rect2(-59,-59,118,118))
	ground(Rect2(-58,-58,116,18),true,.043)
	ground(Rect2(-32,-11,87,21),true,.044)
	ground(Rect2(-20,44,55,11),true,.044)
	site.asset("port_warehouse_main",Vector3(4,.04,-27))
	site.asset("port_warehouse_small",Vector3(4,.04,38))
	site.asset("port_crane",Vector3(-40,.04,-52))
	site.asset("river_barge",Vector3(-29,-2.5,-78))
	for z in [-56.0,-48.0]:
		paint(Vector2(-55,z),Vector2(55,z),.16,"56665e")
	site.box(Vector3(0,-.1,-59),Vector3(120,.7,.5),"858b7c")
	for x in [-53.0,-27.0,0.0,27.0,53.0]:
		site.box(Vector3(x,.38,-56),Vector3(.65,.7,.65),"53645c")
	# Stock remains north of the actual siding at local z=15.
	for z in [-3.0,5.0]:
		for x in [43.0,52.0]:
			site.vehicle("container_20ft",Vector2(x,z),"x",int(x))
	for x in [-23.0,-19.0,-15.0,-8.0]:
		site.asset("pallet_stack",Vector3(x,.045,-10))
	parking(Vector2(38,-.5),2,9,16)
	# Buffer stop at the shortened siding end, clear of border pedestrian control.
	site.box(Vector3(-40,.80,15),Vector3(.35,1.15,3.0),"5a6258")
	path([Vector2(-46,62),Vector2(-46,-2),Vector2(-13,-2)])
	path([Vector2(-46,27),Vector2(-46,-43),Vector2(31,-43)])
	site.vehicle("zil_flatbed",Vector2(-13,-3),"x",2)
	site.vehicle("zil_flatbed",Vector2(7,50),"x",1)
	site.asset("atp_gatehouse",Vector3(-32,.04,51))
	ground(Rect2(-35,47,7,12),true,.047)
	boundary(Vector2(-59,-59),Vector2(-59,59))
	boundary(Vector2(59,-59),Vector2(59,10))
	boundary(Vector2(59,20),Vector2(59,59))
	boundary(Vector2(-59,59),Vector2(-52,59))
	boundary(Vector2(-40,59),Vector2(-28,59))
	boundary(Vector2(-26,59),Vector2(59,59))
	gate(-46,6,59)
	gate(-27,1,59)
	access(-46,58,5,12)
	green(Rect2(-57,-36,5,20))
	green(Rect2(50,25,6,30))
	green(Rect2(-20,55,65,2))
	for x in [-13.0,5.0,24.0,42.0]:
		plant(Vector2(x,56),true,.45)
	for at in [Vector2(-54,-25),Vector2(53,34),Vector2(53,49)]:
		plant(at,false,.38,at.x)
	for at in [Vector2(-54,47),Vector2(54,52),Vector2(53,-41),Vector2(-54,-39)]:
		lamp(at)
	drain(Vector2(-29,2),Vector2(28,2))

func truck_stop() -> void:
	# 100 x 82 m: ten truck bays, a cafe, rear delivery and four car bays.
	ground(Rect2(-49,-40,98,80))
	site.asset("truck_cafe",Vector3(23,.04,-17))
	ground(Rect2(5,-11,37,10),true,.046)
	ground(Rect2(7,-35,32,9),true,.046)
	ground(Rect2(33,-1,3,41),true,.047)
	site.asset("frontier_rest_shelter",Vector3(26,.05,2))
	green(Rect2(20,-1,13,8))
	parking(Vector2(-38,-23),5,5,20)
	parking(Vector2(-38,17),5,5,20)
	for i in [0,2,4]:
		site.vehicle("kamaz_semi",Vector2(-35.5+i*5,-23),"z",i)
	for i in [1,3]:
		site.vehicle("kamaz_semi",Vector2(-35.5+i*5,17),"z",i,true)
	path([Vector2(42,43),Vector2(42,3),Vector2(-44,3),Vector2(-44,43)],8)
	path([Vector2(-44,3),Vector2(-44,-35),Vector2(43,-35),Vector2(43,-28)],8)
	parking(Vector2(8,17),4)
	for i in [0,2,3]:
		site.vehicle("lada",Vector2(9.5+i*3,17),"z",i)
	site.vehicle("zil_food",Vector2(25,-30),"x",2)
	site.asset("pallet_stack",Vector3(36,.045,-27))
	enclosure(Vector2(100,82),[Vector2(-42,12),Vector2(42,12)],35)
	access(-42,39,5,12)
	access(42,39,5,12)
	green(Rect2(-34,33,63,5))
	green(Rect2(-36,-39,70,2))
	green(Rect2(23,12,8,14))
	for at in [Vector2(-27,36),Vector2(-4,36),Vector2(20,36)]:
		plant(at,false,.4,at.y)
	for x in [-28.0,-13.0,4.0,22.0]:
		plant(Vector2(x,37),true,.45)
	for at in [Vector2(-47,-36),Vector2(-47,31),Vector2(47,35),Vector2(4,-37)]:
		lamp(at)
	drain(Vector2(6,-1),Vector2(32,-1))
	for row in 2:
		for col in 6:
			plant(Vector2(-45+col*17+sin(float(col+row)*2)*2,-69+row*18+cos(float(col))*2),false,.48+float(col%2)*.07,float(col))

func boiler() -> void:
	# 80 x 62 m; boiler_house.gd owns the coal bay and story dressing.
	ground(Rect2(-39,-30,78,60))
	site.asset("boiler_house",Vector3(0,.04,0))
	site.asset("boiler_chimney",Vector3(23,.04,-15))
	ground(Rect2(-21,10.5,42,16),true,.046)
	ground(Rect2(17,-20,13,14),true,.045)
	site.asset("fuel_pump_house",Vector3(-28,.04,-21))
	enclosure(Vector2(80,62),[Vector2(0,14)],12,true,100000.0,true)
	access(0,29,6,14)
	ground(Rect2(11,23,2,12),true,.046)
	ground(Rect2(-20,-17,2,43),true,.046)
	ground(Rect2(-31,-17,13,2),true,.046)
	parking(Vector2(26,24),2)
	site.vehicle("lada",Vector2(27.5,24),"z",2)
	for z in [-10.0,-7.0,-4.0]:
		site.asset("pallet_stack",Vector3(-23,.045,z))
	green(Rect2(-37,-29,74,4))
	green(Rect2(-36,27,24,2))
	green(Rect2(18,28,18,1))
	green(Rect2(37,-21,1,47))
	for at in [Vector2(-33,-27),Vector2(-12,-27),Vector2(10,-27)]:
		plant(at,false,.36,at.x)
	for x in [-30.0,-19.0,21.0,31.0]:
		plant(Vector2(x,28.5),true,.4)
	for at in [Vector2(-37,27),Vector2(37,27),Vector2(-36,-26)]:
		lamp(at)
	drain(Vector2(-20,26),Vector2(20,26))
	for x in [-30.0,-9.0,17.0,34.0]:
		plant(Vector2(x,-37),true,.6)

func garage_earth(rect: Rect2, texture: String, tint: Color, height := .13, feather := 1.0) -> void:
	# Existing prepared seasonal terrain, softly edged into the surrounding land.
	site.map._ground_quad(site.center+rect.get_center(),rect.size,height,
		site.map._season[texture],8.0,false,tint,true,feather)

func garages() -> void:
	# Self-built cooperative: packed blocks, narrow irregular alleys, no lane
	# paint, kerbed islands or formal parking. Individual bays stay full size.
	site.root.set_meta("visual_revision","garages-selfbuilt-v6")
	site.root.set_meta("garage_bays",78)
	# Greyer and darker than the shared dirt, which read as salmon pink beside the grass.
	garage_earth(Rect2(-62,-20,124,41),"dirt",Color(.62,.60,.55),.13,2.4)
	var modules: Array = []
	var setbacks := [-15.1,-15.4,-14.9,-15.3,-14.7]
	for col in 5:
		modules.append(["garage_row_"+str((col*3+int(col/2.0))%6),Vector2(-42.6+col*21.3,setbacks[col]),0.0])
	modules.append(["garage_row_4",Vector2(-56,0),PI/2.0])
	modules.append(["garage_row_2",Vector2(-29,-1.9),PI+.006])
	modules.append(["garage_row_5",Vector2(-7.7,-2.25),PI-.007])
	modules.append(["garage_row_1",Vector2(20,-2.1),.008])
	modules.append(["garage_short_3",Vector2(36.9,-1.8),-.009])
	modules.append(["garage_row_0",Vector2(-26,13.8),PI-.006])
	modules.append(["garage_row_4",Vector2(-4.7,14.3),PI+.007])
	modules.append(["garage_row_2",Vector2(58,8),-PI/2.0])
	modules.append(["garage_short_0",Vector2(24,11.8),PI-.01])
	for module in modules:
		var at: Vector2 = module[1]
		site.asset(module[0],Vector3(at.x,.04,at.y),module[2])
	# Two owner's lean-tos break the formerly empty back-wall strip. Their
	# depth leaves approximately 4-5 m of usable unmarked passage opposite.
	site.asset("garage_lean_to",Vector3(-30,.04,2.6),.018)
	site.asset("garage_lean_to",Vector3(-11,.04,2.5),-.024)
	# Remnants of older paving are small, irregular and unmarked. The entry
	# alone meets the real street asphalt at its existing surface height.
	garage_earth(Rect2(-47.8,-4.5,5.8,8.2),"asphalt",Color(.75,.75,.70),.132,.55)
	garage_earth(Rect2(-17,-10.5,10.7,3.5),"asphalt",Color(.70,.72,.68),.132,.60)
	garage_earth(Rect2(29,3.2,7.6,4.8),"asphalt",Color(.76,.75,.70),.132,.70)
	ground(Rect2(-48.75,19,5.5,7))
	# A slightly jogged inexpensive fence follows the accumulated buildings.
	boundary(Vector2(-62,-20.2),Vector2(-62,15))
	boundary(Vector2(-62,15),Vector2(-59,20.2))
	boundary(Vector2(-59,20.2),Vector2(-48.75,20.2))
	boundary(Vector2(-43.25,20.2),Vector2(-39.9,20.2))
	boundary(Vector2(-38.1,20.2),Vector2(15,20.2))
	boundary(Vector2(15,20.2),Vector2(27,19.4))
	boundary(Vector2(27,19.4),Vector2(62,20.2))
	boundary(Vector2(62,20.2),Vector2(62,-7))
	boundary(Vector2(62,-7),Vector2(60,-20.2))
	boundary(Vector2(60,-20.2),Vector2(-4,-20.6))
	boundary(Vector2(-4,-20.6),Vector2(-62,-20.2))
	gate(-46,2.75,20.2)
	gate(-39,.9,20.2)
	# Cars are informally left beside their owner's boxes, off the tight link.
	site.vehicle("lada",Vector2(-48.5,1.75),"x",2,true)
	site.vehicle("lada",Vector2(-20,7.4),"x",1)
	site.vehicle("rural_4x4",Vector2(48.3,13.2),"x",2)
	site.asset("pallet_stack",Vector3(-34,.04,2.9))
	site.asset("atp_tire_rack",Vector3(-16,.04,2.7))
	site.box(Vector3(50,.55,-1),Vector3(1.1,1.1,.8),"716850")
	# One improvised yard-light pole replaces the regular street-light array.
	site.box(Vector3(-51,2.7,17),Vector3(.17,5.4,.17),"6a6251")
	site.box(Vector3(-50.6,5.2,17),Vector3(.9,.09,.09),"53615b")
	site.box(Vector3(-50.2,5.16,17),Vector3(.4,.16,.25),"aaac98")
	for at in [Vector2(-60,13),Vector2(-56,-19),Vector2(-15,-20),Vector2(36,-20),Vector2(59,18),Vector2(35,17.5)]:
		plant(at,true,.36,at.x)
	_garage_tree_belts()

func _garage_tree_belts() -> void:
	# User-requested interim woodland on the released service land. Keep it
	# separate from the approved self-built yard for later reserve-land work.
	var grove := Node3D.new()
	grove.name = "TemporaryGarageGroves"
	grove.set_meta("temporary_reserve_landscaping",true)
	site.root.add_child(grove)
	var candidates: Array[Vector2] = []
	for row in 3:
		for col in 31:
			candidates.append(Vector2(-332+col*9.5,-167+row*11))
	for row in 4:
		for col in 14:
			candidates.append(Vector2(-173+col*9.5,-134+row*10))
	for row in 3:
		for col in 2:
			candidates.append(Vector2(-332+col*10,-131+row*12))
	var placed := 0
	for i in candidates.size():
		var at := candidates[i]+Vector2(sin(float(i)*2.31),cos(float(i)*1.79))*1.6
		var clear := true
		for road in site.Layout.ROADS:
			if road["rect"].grow(6.0).has_point(at):
				clear = false
				break
		if not clear:
			continue
		for lot in site.Layout.LOTS.values():
			if lot["rect"].grow(4.5).has_point(at):
				clear = false
				break
		if not clear:
			continue
		var species := "park_conifer" if i%9==0 else "park_poplar" if i%13==0 else "park_deciduous_tree"
		var local: Vector2 = at-site.center
		var node := Vegetation.create(species,Vector3(local.x,-.095,local.y))
		node.scale *= .64+float((i*7)%11)*.022
		node.rotation.y = float(i)*2.39996
		grove.add_child(node)
		site.map._occupy(at,Vector2(3,3))
		placed += 1
	grove.set_meta("tree_count",placed)
	print("Garage reserve woodland: ",placed," trees; street and entry remain clear")
