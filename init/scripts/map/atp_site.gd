# Compact depot, authored in metres around the parcel centre (-360,-241).
extends RefCounted

const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Settings = preload("res://scripts/data/settings.gd")
const GROUND = preload("res://assets/shaders/atp_ground.gdshader")
const GRAIN = preload("res://assets/textures/ground_asphalt.png")
const LocationState = preload("res://scripts/map/location_state.gd")
const AccessGate = preload("res://scripts/map/access_gate.gd")
const Schedules = preload("res://scripts/data/location_schedules.gd")
var site

func build(owner) -> void:
	site = owner
	# Same surface height as the highway. Existing asset grounding offsets apply.
	site.root.position.y = .10
	ground(Rect2(-60,-41,120,82))
	ground(Rect2(-44,8,64,18),true) # Working apron immediately outside the bays.
	ground(Rect2(16,3.5,15,3),true) # Dispatcher entrance apron.
	ground(Rect2(33.7,3.5,2,37),true) # Wicket -> office, beside the car bays.
	ground(Rect2(26,-30,17,3),true) # Parts-store loading lip.
	ground(Rect2(15,14,9,10),true) # Tire-shop receiving apron.
	# Separate entrance and exit join the existing highway edge, not its centre.
	ground(Rect2(44,39.5,10,4.5))
	ground(Rect2(-56,39.5,8,4.5))
	site.asset("atp_hall",Vector3(-12,.04,-4))
	site.asset("atp_parts_store",Vector3(35,.04,-34))
	site.asset("atp_tire_shop",Vector3(27,.04,19),-PI/2.0)
	site.asset("atp_gatehouse",Vector3(41,.04,35))
	_perimeter()
	_routes_and_parking()
	_equipment()
	_greenery()
	print("ATP: 120x82m; hall moved 39m toward highway; separate controlled entry/exit")

func ground(rect: Rect2, concrete := false) -> void:
	# Driveway throats extend outside the parcel; keep automatic street furniture
	# clear of them as well as the enclosed yard.
	site.map._occupy(site.center+rect.get_center(),rect.size)
	var material := ShaderMaterial.new()
	material.shader = GROUND
	material.set_shader_parameter("grain_texture",GRAIN)
	material.set_shader_parameter("concrete",concrete)
	material.set_shader_parameter("winter",Settings.season == "winter")
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var node := MeshInstance3D.new()
	node.name = "ServiceConcrete" if concrete else "DepotAsphalt"
	node.mesh = mesh
	node.material_override = material
	node.rotation.x = -PI/2.0
	node.position = Vector3(rect.get_center().x,.040 if concrete else .036,rect.get_center().y)
	site.root.add_child(node)

func paint(a: Vector2, b: Vector2, width := .10, color := "b3b09a") -> void:
	site.line(a,b,width,color,.047)

func wall(a: Vector2, b: Vector2) -> void:
	var delta := b-a
	var count := maxi(1,ceili(delta.length()/4.0))
	for i in count:
		var at := a+delta*((float(i)+.5)/count)
		site.asset("atp_wall_4m",Vector3(at.x,.04,at.y),-atan2(delta.y,delta.x),Vector3(delta.length()/count/4.0,1,1))

func _perimeter() -> void:
	wall(Vector2(-59.3,-40.3),Vector2(59.3,-40.3))
	wall(Vector2(-59.3,-40.3),Vector2(-59.3,40.3))
	wall(Vector2(59.3,-40.3),Vector2(59.3,40.3))
	# Exit (-52), pedestrian wicket (34.7), entrance (49). Everything else is solid.
	wall(Vector2(-59.3,40.3),Vector2(-56,40.3))
	wall(Vector2(-48,40.3),Vector2(33.7,40.3))
	wall(Vector2(35.7,40.3),Vector2(44,40.3))
	wall(Vector2(54,40.3),Vector2(59.3,40.3))
	for x in [-56.2,-47.8,43.8,54.2]:
		site.box(Vector3(x,1.55,40.3),Vector3(.40,3.0,.45),"8a9081")
	for x in [-56.0,-48.0]:
		for y in [.5,1.4,2.3]:
			site.box(Vector3(x,y,40.2),Vector3(.18,.24,.16),"4b5956")
	_access_controls()

func _access_controls() -> void:
	# Moving parts are individual nodes; static fence/detail instances stay batched.
	var gates := AccessGate.new()
	gates.name = "ATPAccess"
	site.root.add_child(gates)
	var leaf: PackedScene = site.MODELS["atp_solid_gate"]
	gates.add_hinged_leaf(leaf,Vector3(-56,.04,40.3),4.0,1.0,deg_to_rad(80.0))
	gates.add_hinged_leaf(leaf,Vector3(-48,.04,40.3),4.0,-1.0,deg_to_rad(80.0))
	gates.add_sliding_leaf(leaf,Vector3(46.5,.04,40.1),Vector3(41,.04,40.1),5.0)
	gates.add_sliding_leaf(leaf,Vector3(51.5,.04,40.1),Vector3(57,.04,40.1),5.0)
	gates.add_hinged_leaf(leaf,Vector3(33.8,.04,40.3),1.8,1.0,PI/2.0)
	gates.add_barrier(Vector3(44.7,.04,35.0))
	gates.add_barrier(Vector3(-55.5,.04,35.0))
	var operating := LocationState.new()
	operating.name = "OperatingState"
	site.root.add_child(operating)
	operating.state_changed.connect(func(value: StringName, animated: bool):
		gates.set_open(value == &"open",animated)
		site.root.set_meta("operating_state",value))
	site.map.register_location_state("atp",operating)
	operating.configure(site.map.visual_clock_hour,Schedules.DAILY["atp"])

func _routes_and_parking() -> void:
	# Entry -> east collector -> rear aisle -> west collector -> exit.
	# 9m centreline corner radii, 8m aisles; final swept envelopes are not certified.
	var path: Array[Vector2] = [Vector2(49,43.5),Vector2(49,-13.5)]
	for i in range(1,13):
		var angle := -PI/2.0*float(i)/12.0
		path.append(Vector2(40,-13.5)+Vector2(cos(angle),sin(angle))*9.0)
	path.append(Vector2(-43,-22.5))
	for i in range(1,13):
		var angle := -PI/2.0-PI/2.0*float(i)/12.0
		path.append(Vector2(-43,-13.5)+Vector2(cos(angle),sin(angle))*9.0)
	path.append(Vector2(-52,43.5))
	for i in range(path.size()-1):
		var a := path[i]
		var b := path[i+1]
		var offset := (b-a).normalized().orthogonal()*4.0
		# Junction with the repair apron remains open across the front.
		if a.y < 27 or b.y < 27:
			paint(a+offset,b+offset,.08)
			paint(a-offset,b-offset,.08)
	# Front transverse manoeuvring lane. Ends open into the collectors.
	for x in range(-43,40,7):
		paint(Vector2(x,32.5),Vector2(x+3,32.5),.09)
	_arrow(Vector2(49,22),true)
	_arrow(Vector2(-52,22),false)
	paint(Vector2(-4,-22.5),Vector2(-9,-22.5),.12)
	paint(Vector2(-9,-22.5),Vector2(-7.5,-21.5),.12)
	paint(Vector2(-9,-22.5),Vector2(-7.5,-23.5),.12)
	# Marked rear stabling: parked noses face the aisle, away from the perimeter.
	for i in range(14):
		var x := -37+i*4.0
		paint(Vector2(x,-38.5),Vector2(x,-27.5))
	paint(Vector2(-37,-38.5),Vector2(15,-38.5))
	for i in [0,1,3,4,6,7,9,10,12]:
		site.vehicle("bus_liaz" if i%3 == 0 else "bus_paz",Vector2(-35+i*4,-33),"z",i)
	# The existing open bay has one bus receiving service, not a row blocking it.
	site.vehicle("bus_paz",Vector2(0,10.6),"z",1,true)
	# Three staff-car spaces align beside the office walk and east collector.
	for z in [8.0,14.0,20.0,26.0]:
		paint(Vector2(37.8,z),Vector2(42.2,z))
	paint(Vector2(37.8,8),Vector2(37.8,26))
	for z in [11.0,23.0]:
		site.vehicle("lada",Vector2(40,z),"z",int(z))
	# Parts delivery stands beside its store, clear of the circulation aisle.
	site.vehicle("zil_flatbed",Vector2(24,-35),"z",2)
	site.vehicle("lada",Vector2(18,19),"x",1)

func _arrow(at: Vector2, north: bool) -> void:
	var sign := -1.0 if north else 1.0
	paint(at-Vector2(0,sign*2),at+Vector2(0,sign*2),.15)
	paint(at+Vector2(0,sign*2),at+Vector2(-.9,sign*.6),.15)
	paint(at+Vector2(0,sign*2),at+Vector2(.9,sign*.6),.15)

func _equipment() -> void:
	site.asset("atp_tire_rack",Vector3(25,.04,26))
	site.asset("atp_tire_rack",Vector3(29,.04,26))
	site.asset("atp_compressor",Vector3(31.4,.04,16),PI/2.0)
	for x in [32.0,35.0,38.0]:
		site.asset("pallet_stack",Vector3(x,.045,-29))
	# Drainage at the bay thresholds and the workshop apron edge.
	for x in range(-43,20,2):
		site.box(Vector3(x,.049,9.2),Vector3(1.8,.025,.30),"535c55")
	for z in range(15,25,2):
		site.box(Vector3(17,.049,z),Vector3(.30,.025,1.8),"535c55")
	for at in [Vector2(-56,-36),Vector2(54,-35),Vector2(-55,28),Vector2(54,29)]:
		site.asset("yard_lamp",Vector3(at.x,.04,at.y))

func green(rect: Rect2) -> void:
	var mesh := QuadMesh.new()
	mesh.size = rect.size
	var material := StandardMaterial3D.new()
	material.albedo_texture = site.map._season["grass"]
	material.albedo_color = site.map._season["grass_tint"]
	material.roughness = 1.0
	material.uv1_scale = Vector3(rect.size.x/8.0,rect.size.y/8.0,1)
	var node := MeshInstance3D.new()
	node.name = "DepotPlantedBed"
	node.mesh = mesh
	node.material_override = material
	node.rotation.x = -PI/2.0
	node.position = Vector3(rect.get_center().x,.07,rect.get_center().y)
	site.root.add_child(node)
	for edge in [[rect.position,Vector2(rect.end.x,rect.position.y)],
		[Vector2(rect.position.x,rect.end.y),rect.end],
		[rect.position,Vector2(rect.position.x,rect.end.y)],
		[Vector2(rect.end.x,rect.position.y),rect.end]]:
		site.line(edge[0],edge[1],.14,"969b88",.075)

func plant(id: String, at: Vector2, scale_factor: float, outside := false, yaw := 0.0) -> void:
	var node := Vegetation.create(id,Vector3(at.x,-.07 if outside else .07,at.y))
	node.scale *= scale_factor
	node.rotation.y = yaw
	site.root.add_child(node)
	site.map._occupy(site.center+at,Vector2(3,3))

func _greenery() -> void:
	green(Rect2(-45,37.0,75,2.4))
	green(Rect2(52,-38,5,11))
	green(Rect2(-58,-38,5,8))
	green(Rect2(11,24.0,12,3.8))
	for x in [-40,-27,-14,-1,12,25]:
		plant("park_shrub",Vector2(x,38),.45,false,x*.2)
	for at in [Vector2(-55,-35),Vector2(54,-34),Vector2(15,25.8)]:
		plant("park_poplar",at,.44)
	for x in [12.5,18.5,21.5]:
		plant("park_shrub",Vector2(x,26.5),.42)
	# Former rear asphalt becomes an irregular tree/shrub belt on existing grass.
	for row in 3:
		for col in 7:
			var at := Vector2(-60+col*18+sin(float(col+row)*2.3)*3,-74+row*11+cos(float(col)*1.7)*2)
			plant("park_deciduous_tree" if (col+row)%3 else "park_poplar",at,.52+float((col+row)%3)*.08,true,float(col*row)*.7)
	for col in 15:
		plant("park_shrub",Vector2(-62+col*8,-45+sin(float(col)*1.8)*2.2),.55,true,float(col))
