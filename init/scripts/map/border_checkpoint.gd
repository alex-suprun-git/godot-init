# The border is a network of working yards, controlled routes and planted
# separation areas. Keep the 330 x 120 m lot and original bridge/avenue axis.
extends RefCounted

const GROUND = preload("res://assets/shaders/atp_ground.gdshader")
const GRAIN = preload("res://assets/textures/ground_asphalt.png")
const Settings = preload("res://scripts/data/settings.gd")
var s
var site

func build(composition) -> void:
	s = composition
	site = s.site
	site.root.set_meta("visual_revision","border-yards-v3")
	_primary_control()
	_import_waiting()
	_import_compound()
	_export_compound()
	_export_waiting_and_bus()
	_perimeter_and_pedestrians()
	_landscape_and_equipment()

func road(points: Array, width := 9.0) -> void:
	# Build actual asphalt only under this circulation ribbon. The underlying
	# map grass stays visible between yards; there is no parcel-wide slab.
	var curve: Array[Vector2] = s.rounded_path(points)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var edges: Array[Vector2] = []
	for i in curve.size():
		var tangent: Vector2
		if i == 0:
			tangent = (curve[1]-curve[0]).normalized()
		elif i == curve.size()-1:
			tangent = (curve[i]-curve[i-1]).normalized()
		else:
			tangent = (curve[i+1]-curve[i-1]).normalized()
		var side := tangent.orthogonal()*width/2
		edges.append(curve[i]+side)
		edges.append(curve[i]-side)
	for i in range(curve.size()-1):
		for index in [i*2,i*2+2,i*2+1,i*2+1,i*2+2,i*2+3]:
			vertices.append(Vector3(edges[index].x,.037,edges[index].y))
			normals.append(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var material := ShaderMaterial.new()
	material.shader = GROUND
	material.set_shader_parameter("grain_texture",GRAIN)
	material.set_shader_parameter("winter",Settings.season == "winter")
	var node := MeshInstance3D.new()
	node.name = "ControlledAsphaltRoute"
	node.mesh = mesh
	node.material_override = material
	site.root.add_child(node)
	s.path(points,width)
	# A physical low kerb reads at map zoom, unlike guide paint on a vast yard.
	for i in range(1,curve.size()-2):
		for side_index in [0,1]:
			site.line(edges[i*2+side_index],edges[(i+1)*2+side_index],.22,"8c9182",.080)

func island(rect: Rect2, trees: Array = []) -> void:
	s.green(rect)
	for at in trees:
		s.plant(at,false,.49,at.x)

func _primary_control() -> void:
	# Car/truck lanes retain the existing road. The new paired roof modules
	# form two continuous, readable control stages rather than four umbrellas.
	s.ground(Rect2(-23,-24,10,48),true,.044)
	s.ground(Rect2(13,-24,10,48),true,.044)
	site.box(Vector3(0,.21,0),Vector3(4,.22,118),"9d9f8d")
	for x in [-8.5,8.5]:
		for z in [-14.0,14.0]:
			var direction := "Import" if x<0 else "Export"
			var stage := "Passport" if z<0 else "Customs"
			var model := "customs_passport_canopy" if z<0 else "customs_control_canopy"
			s.place(model,Vector3(x,.045,z),direction+stage+"Canopy")
			s.place("control_booth",Vector3(signf(x)*1.10,.32,z),direction+stage+"Booth")
			for lane in [4.5,9.5]:
				site.asset("raised_barrier",Vector3(signf(x)*(lane+1.65),.045,z+4 if x<0 else z-4))
			site.box(Vector3(signf(x)*7,.16,z),Vector3(.48,.20,12),"a2a18e")
		for z in [-22.0,6.0] if x<0 else [22.0,-6.0]:
			s.paint(Vector2(signf(x)*2.5,z),Vector2(signf(x)*11.5,z),.30)
	for x in [-20.0,13.0]:
		for z in [-22.0,8.0]:
			island(Rect2(x,z,7,14))
	for x in [-9.5,-4.5,4.5,9.5]:
		for z in [-47.0,43.0]:
			site.arrow(Vector2(x,z),x>0)

func _import_waiting() -> void:
	road([Vector2(-10,-53),Vector2(-151,-53),Vector2(-151,-26),Vector2(-13,-26)],10)
	s.ground(Rect2(-144,-49,45,20))
	s.parking(Vector2(-141,-39),6,6,18)
	for x in [-138.0,-120.0,-108.0]:
		site.vehicle("kamaz_semi",Vector2(x,-39),"z",1)
	# Document processing and passenger waiting occupy the formerly blank
	# centre of the holding loop, with a pedestrian forecourt and shelter.
	s.ground(Rect2(-88,-47,38,18),true,.044)
	s.place("customs_documents",Vector3(-70,.045,-39),"ImportDocumentsPavilion")
	s.ground(Rect2(-44,-47,26,17))
	s.parking(Vector2(-41,-39),6,3,7)
	for x in [-39.5,-33.5,-24.5]:
		site.vehicle("lada",Vector2(x,-39),"z",int(x))
	s.ground(Rect2(-73,-31,4,11),true,.046)
	for z in range(-30,-21,2):
		s.paint(Vector2(-73,z),Vector2(-69,z),.55,"ccc8b4")
	island(Rect2(-97,-46,6,15))
	island(Rect2(-49,-46,3,15))
	for z in [-42.0,-35.0]:
		s.plant(Vector2(-94,z),true,.6)
	# Queue-edge fence separates waiting from service access behind it.
	s.boundary(Vector2(-146,-29),Vector2(-101,-29))
	s.place("control_booth",Vector3(-145,.04,-21),"ImportHoldingPost")

func _import_compound() -> void:
	s.ground(Rect2(-123,-24,57,28),true,.043)
	s.place("customs_office",Vector3(-87,.04,-12),"BorderAdministration")
	s.place("customs_staff_wing",Vector3(-111,.04,-12),"AdministrationServiceWing")
	s.ground(Rect2(-151,-9,28,27),true,.044)
	s.place("customs_bonded_store",Vector3(-137,.04,-2),"BondedCargoStore")
	s.ground(Rect2(-147,17,37,14))
	s.parking(Vector2(-143,24),5)
	for i in [0,2,4]:
		site.vehicle("lada",Vector2(-141.5+i*3,24),"z",i)
	road([Vector2(-44,12),Vector2(-116,12),Vector2(-116,2)],8)
	road([Vector2(-116,12),Vector2(-116,31),Vector2(-146,31)],6)
	s.ground(Rect2(-114,-6,3,25),true,.046)
	for x in [-146.0,-143.0,-140.0]:
		site.asset("pallet_stack",Vector3(x,.045,6))
	s.boundary(Vector2(-153,-10),Vector2(-153,36))
	s.boundary(Vector2(-153,36),Vector2(-109,36))
	s.boundary(Vector2(-109,17),Vector2(-109,36))
	s.place("control_booth",Vector3(-106,.04,13),"CargoServicePost")
	site.asset("raised_barrier",Vector3(-109,.045,17))
	# Secondary entry is downstream of both import controls; central bay is
	# genuinely drive-through. Forecourt and equipment stay off the exit aisle.
	s.ground(Rect2(-108,13,52,35),true,.043)
	s.place("inspection_hall",Vector3(-82,.04,29),"ImportSecondaryInspection")
	road([Vector2(-13,30),Vector2(-44,30),Vector2(-44,3),Vector2(-82,3),Vector2(-82,17)],9)
	road([Vector2(-82,42),Vector2(-82,51),Vector2(-24,51),Vector2(-11,55)],9)
	s.boundary(Vector2(-108,14),Vector2(-108,46))
	s.boundary(Vector2(-56,15),Vector2(-56,43))
	s.boundary(Vector2(-108,13),Vector2(-87,13))
	s.boundary(Vector2(-77,13),Vector2(-56,13))
	s.place("control_booth",Vector3(-91,.045,8),"ImportInspectionPost")
	site.asset("raised_barrier",Vector3(-87.5,.045,13))
	# One truck waiting at a side door leaves the open centre bay clear.
	s.ground(Rect2(-102,42,15,9),true,.044)
	site.vehicle("zil_flatbed",Vector2(-95,47),"z",2,true)
	site.asset("pallet_stack",Vector3(-105,.045,40))
	s.drain(Vector2(-104,12),Vector2(-60,12))

func _export_compound() -> void:
	s.ground(Rect2(55,-37,52,32),true,.043)
	s.place("inspection_hall",Vector3(81,.04,-21),"ExportSecondaryInspection",PI)
	road([Vector2(13,1),Vector2(81,1),Vector2(81,-9)],9)
	road([Vector2(81,-33),Vector2(81,-47),Vector2(43,-47),Vector2(43,-3),Vector2(13,-3)],9)
	s.boundary(Vector2(55,-35),Vector2(55,-9))
	s.boundary(Vector2(107,-35),Vector2(107,-9))
	s.boundary(Vector2(55,-7),Vector2(76,-7))
	s.boundary(Vector2(86,-7),Vector2(107,-7))
	s.boundary(Vector2(55,-37),Vector2(76,-37))
	s.boundary(Vector2(86,-37),Vector2(107,-37))
	s.place("control_booth",Vector3(93,.045,-2),"ExportInspectionPost")
	site.asset("raised_barrier",Vector3(86.5,.045,-7))
	s.ground(Rect2(91,-5,12,12),true,.044)
	site.vehicle("zil_food",Vector2(97,1),"z",1,true)
	s.drain(Vector2(60,-6),Vector2(89,-6))

func _export_waiting_and_bus() -> void:
	road([Vector2(10,53),Vector2(149,53),Vector2(149,27),Vector2(13,27)],10)
	s.ground(Rect2(97,29,43,21))
	s.parking(Vector2(100,39),6,6,18)
	for x in [103.0,121.0,133.0]:
		site.vehicle("kamaz_semi",Vector2(x,39),"z",2,true)
	s.boundary(Vector2(98,29),Vector2(140,29))
	s.place("control_booth",Vector3(143,.04,22),"ExportHoldingPost")
	# The bus route rejoins upstream of export customs, not after inspection.
	road([Vector2(149,27),Vector2(132,27),Vector2(132,-28),Vector2(113,-28),Vector2(113,24),Vector2(13,24)],6)
	s.ground(Rect2(125,-18,14,27),true,.044)
	s.place("control_canopy",Vector3(132,.045,-8),"BusInspectionCanopy")
	s.place("control_booth",Vector3(142,.045,-8),"BusInspectionBooth")
	s.parking(Vector2(129.5,-8),1,5,15)
	site.vehicle("bus_paz",Vector2(132,-8),"z",1,true)
	s.ground(Rect2(139,-17,9,23),true,.046)
	# Passenger benches and a separate approach beside, not on, the bus aisle.
	for z in [-13.0,0.0]:
		site.box(Vector3(145,.5,z),Vector3(2.6,.14,.55),"82745b")
		for x in [144.0,146.0]:
			site.box(Vector3(x,.25,z),Vector3(.12,.5,.45),"53615b")
	s.boundary(Vector2(148,-20),Vector2(148,12))
	s.boundary(Vector2(123,-21),Vector2(123,14))
	s.ground(Rect2(148,-6,6,3),true,.046)

func _perimeter_and_pedestrians() -> void:
	for z in [-59.0,59.0]:
		s.boundary(Vector2(-164,z),Vector2(-13.5,z))
	s.boundary(Vector2(13.5,-59),Vector2(164,-59))
	s.boundary(Vector2(13.5,59),Vector2(154.5,59))
	s.boundary(Vector2(163.5,59),Vector2(164,59))
	s.boundary(Vector2(-164,-59),Vector2(-164,59))
	s.boundary(Vector2(164,-59),Vector2(164,59))
	for x in [-13.0,13.0]:
		for z in [-55.0,55.0]:
			site.asset("raised_barrier",Vector3(x,.045,z))
	s.ground(Rect2(155,-57,8,116),true,.055)
	# Meet the avenue at its east curb. The apron sits above the asphalt.
	s.ground(Rect2(12,-57,151,4),true,.055)
	s.place("pedestrian_control",Vector3(159,.055,33),"PedestrianControl")
	for x in [154.5,159.0]:
		s.boundary(Vector2(x,-54),Vector2(x,28))
		s.boundary(Vector2(x,38),Vector2(x,59))
	s.boundary(Vector2(13,-53),Vector2(154.5,-53))
	s.boundary(Vector2(13,-55),Vector2(159,-55))
	for x in [156.5,161.5]:
		for z in [26.0,40.0]:
			site.asset("raised_barrier",Vector3(x,.055,z),0,Vector3(.33,.5,.5))

func _landscape_and_equipment() -> void:
	# Plant the separation areas between actual branches. A few canopies and
	# small trees give each working court an edge without hiding its entrances.
	island(Rect2(-39,-18,16,36),[Vector2(-31,-10),Vector2(-31,9)])
	island(Rect2(23,-40,14,28),[Vector2(30,-32),Vector2(30,-20)])
	island(Rect2(23,7,32,12),[Vector2(31,13),Vector2(48,13)])
	island(Rect2(49,-42,22,5))
	island(Rect2(-161,39,41,16),[Vector2(-153,46),Vector2(-134,47)])
	island(Rect2(-115,41,5,13))
	for z in [-33.0,-13.0,9.0,30.0,51.0]:
		s.plant(Vector2(-160,z),false,.53,z)
	for x in [-149.0,-137.0,-124.0]:
		s.plant(Vector2(x,53),true,.6,x)
	for x in [60.0,67.0]:
		s.plant(Vector2(x,-39),true,.55)
	for z in [-37.0,11.0,47.0]:
		s.plant(Vector2(151,z),true,.55,z)
	for at in [Vector2(-156,-47),Vector2(-98,-49),Vector2(-47,-48),Vector2(-157,26),Vector2(-55,41),Vector2(-25,39),Vector2(26,-45),Vector2(107,16),Vector2(149,-39),Vector2(146,47)]:
		s.lamp(at)
