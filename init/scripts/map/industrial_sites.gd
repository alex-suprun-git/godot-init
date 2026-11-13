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
	"truck_cafe": preload(PATH + "frontier_truck_cafe.glb"),
	"customs_office": preload(PATH + "frontier_customs_office.glb"),
	"inspection_hall": preload(PATH + "frontier_inspection_hall.glb"),
	"customs_bonded_store": preload(PATH + "frontier_customs_bonded_store.glb"),
	"customs_staff_wing": preload(PATH + "frontier_customs_staff_wing.glb"),
	"customs_documents": preload(PATH + "frontier_customs_documents.glb"),
	"customs_passport_canopy": preload(PATH + "frontier_customs_passport_canopy.glb"),
	"customs_control_canopy": preload(PATH + "frontier_customs_control_canopy.glb"),
	"control_canopy": preload(PATH + "frontier_control_canopy.glb"),
	"control_booth": preload(PATH + "frontier_control_booth.glb"),
	"pedestrian_control": preload(PATH + "frontier_pedestrian_control.glb"),
	"port_warehouse_main": preload(PATH + "frontier_port_warehouse_main.glb"),
	"port_warehouse_small": preload(PATH + "frontier_port_warehouse_small.glb"),
	"fuel_warehouse": preload(PATH + "frontier_fuel_warehouse.glb"),
	"fuel_pump_house": preload(PATH + "frontier_fuel_pump_house.glb"),
	"fuel_loading_gantry": preload(PATH + "frontier_fuel_loading_gantry.glb"),
	"frontier_rest_shelter": preload(PATH + "frontier_rest_shelter.glb"),
	"fuel_tank": preload(PATH + "frontier_fuel_tank.glb"),
	"water_tower": preload(PATH + "frontier_water_tower.glb"),
	"boiler_house": preload(PATH + "frontier_boiler_house.glb"),
	"boiler_chimney": preload(PATH + "frontier_boiler_chimney.glb"),
	"garage_row_0": preload(PATH + "frontier_garage_row_0.glb"),
	"garage_row_1": preload(PATH + "frontier_garage_row_1.glb"),
	"garage_row_2": preload(PATH + "frontier_garage_row_2.glb"),
	"garage_row_3": preload(PATH + "frontier_garage_row_3.glb"),
	"garage_row_4": preload(PATH + "frontier_garage_row_4.glb"),
	"garage_row_5": preload(PATH + "frontier_garage_row_5.glb"),
	"garage_short_0": preload(PATH + "frontier_garage_short_0.glb"),
	"garage_short_3": preload(PATH + "frontier_garage_short_3.glb"),
	"garage_lean_to": preload(PATH + "frontier_garage_lean_to.glb"),
	"port_crane": preload(PATH + "port_crane.glb"),
	"river_barge": preload(PATH + "river_barge.glb"),
	"fence_4m": preload(PATH + "fence_4m.glb"),
	"gate_6m": preload(PATH + "gate_6m.glb"),
	"yard_lamp": preload(PATH + "yard_lamp.glb"),
	"raised_barrier": preload(PATH + "raised_barrier.glb"),
	"pallet_stack": preload(PATH + "pallet_stack.glb"),
}
const LOT_IDS := ["atp", "truck_stop", "checkpoint", "port", "fuel_depot", "boiler", "garages"]
const BATCHED := ["fence_4m", "yard_lamp", "pallet_stack", "garage_row_0", "garage_row_1", "garage_row_2", "garage_row_3", "garage_row_4", "garage_row_5", "garage_short_0", "garage_short_3", "garage_lean_to", "atp_wall_4m", "atp_solid_gate", "atp_tire_rack"]

var map
var root: Node3D
var center: Vector2
var _batches: Dictionary = {}
var _boxes: Dictionary = {}

static func supports(id: String) -> bool:
	return id in LOT_IDS

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
		district_builder._register_doorstep(id, lot, {"doorstep": 3.0}, center + Vector2(-10, -24), 12.0)
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
	# Rotate after scaling: Basis.scaled() is a global scale and would stretch a yawed box along the wrong axis.
	_boxes[color].append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(size), at))

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
	preload("res://scripts/map/frontier_sites.gd").new().build(self, "truck_stop")

func _checkpoint() -> void:
	preload("res://scripts/map/frontier_sites.gd").new().build(self, "checkpoint")

func _port() -> void:
	preload("res://scripts/map/frontier_sites.gd").new().build(self, "port")

func _fuel() -> void:
	preload("res://scripts/map/frontier_sites.gd").new().build(self, "fuel_depot")

func _boiler() -> void:
	preload("res://scripts/map/frontier_sites.gd").new().build(self, "boiler")
	preload("res://scripts/map/boiler_house.gd").new().build(map, root)

func _garages() -> void:
	preload("res://scripts/map/frontier_sites.gd").new().build(self, "garages")
