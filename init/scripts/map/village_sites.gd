# Complete Blender-built parcels are fitted first, then placed without stretching.
extends RefCounted
const Plan = preload("res://scripts/data/village_sites.gd")
const Vegetation = preload("res://scripts/map/vegetation_models.gd")
const Settings = preload("res://scripts/data/settings.gd")
const OfficeTheme = preload("res://scripts/ui/office_theme.gd")
const PATH := "res://assets/models/village/"
const MODELS := {
	"d_01":preload(PATH+"d_01.glb"), "d_02":preload(PATH+"d_02.glb"), "d_03":preload(PATH+"d_03.glb"),
	"d_04":preload(PATH+"d_04.glb"), "d_05":preload(PATH+"d_05.glb"), "d_06":preload(PATH+"d_06.glb"),
	"d_07":preload(PATH+"d_07.glb"), "d_08":preload(PATH+"d_08.glb"), "d_09":preload(PATH+"d_09.glb"),
	"d_10":preload(PATH+"d_10.glb"), "d_11":preload(PATH+"d_11.glb"), "d_12":preload(PATH+"d_12.glb"),
	"d_13":preload(PATH+"d_13.glb"), "d_14":preload(PATH+"d_14.glb"), "d_15":preload(PATH+"d_15.glb"),
	"d_16":preload(PATH+"d_16.glb"), "d_17":preload(PATH+"d_17.glb"),
	"d_18":preload(PATH+"d_18.glb"), "d_19":preload(PATH+"d_19.glb"), "d_20":preload(PATH+"d_20.glb"),
	"d_21":preload(PATH+"d_21.glb"), "d_22":preload(PATH+"d_22.glb"), "d_23":preload(PATH+"d_23.glb"),
	"d_24":preload(PATH+"d_24.glb"), "d_25":preload(PATH+"d_25.glb"), "d_26":preload(PATH+"d_26.glb"),
	"d_27":preload(PATH+"d_27.glb"), "d_28":preload(PATH+"d_28.glb"), "d_29":preload(PATH+"d_29.glb"),
}
static var _winter_materials := {}

func build(builder, id: String, lot: Dictionary) -> void:
	var map = builder.map
	var record: Dictionary = Plan.all()[id]
	var site: Node3D = MODELS[id].instantiate()
	site.name = "Homestead_"+id
	site.position = Vector3(record["center"][0],.025,record["center"][1])
	site.rotation.y = record["yaw"]
	site.set_meta("family",record["family"])
	site.add_to_group("village_homesteads")
	map.add_child(site)
	var rect: Rect2 = lot["rect"]
	map._occupy(rect.get_center(),rect.size)
	map.wear.add_disc(Plan.point(id,"entrance"),1.8,.75)
	map.wear.add_disc(Plan.point(id,"doorstep"),1.4,.55)
	if map.sim.graph.has_entrance(id):
		map.sim.graph.set_doorstep(id,Plan.point(id,"doorstep"))
	for mesh in site.find_children("*","MeshInstance3D",true,false):
		if str(mesh.name).begins_with("SummerPlanting") and Settings.season == "winter":
			mesh.hide()
		if Settings.season == "winter":
			_winter_surfaces(mesh,map)
	var flowers: Array[Transform3D] = []
	var colors: Array[Color] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	for plant in record["planting"]:
		var at := Vector3(plant["at"][0],plant["at"][1],plant["at"][2])
		match plant["kind"]:
			"FruitTree":
				var tree := Vegetation.create("park_deciduous_tree",at)
				tree.scale *= float(plant["height"])/float(Vegetation.HEIGHTS["park_deciduous_tree"])
				tree.rotation.y = rng.randf_range(-PI,PI)
				site.add_child(tree)
			"Shrub":
				var shrub := Vegetation.create("park_shrub",at)
				shrub.scale *= float(plant["scale"])
				site.add_child(shrub)
			"Flowerbed":
				if Settings.season != "winter":
					for i in 16:
						var offset := Vector3(rng.randf_range(-plant["width"]*.45,plant["width"]*.45),.16+rng.randf_range(.0,.1),rng.randf_range(-plant["depth"]*.4,plant["depth"]*.4))
						flowers.append(Transform3D(Basis.from_scale(Vector3(.13,.10,.13)),at+offset))
						colors.append([Color("b68187"),Color("d2ba80"),Color("c7c9b0")][i%3])
	if not flowers.is_empty():
		var sphere := SphereMesh.new()
		sphere.radius = .5
		sphere.height = 1
		sphere.radial_segments = 6
		sphere.rings = 3
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.use_colors = true
		multi.mesh = sphere
		multi.instance_count = flowers.size()
		for i in flowers.size():
			multi.set_instance_transform(i,flowers[i])
			multi.set_instance_color(i,colors[i])
		var node := MultiMeshInstance3D.new()
		node.name = "GardenFlowers"
		node.multimesh = multi
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		material.roughness = .95
		node.material_override = material
		site.add_child(node)
	var label := Label3D.new()
	label.text = id+"\n"+record["family"]
	label.font = OfficeTheme.BODY_FONT
	label.font_size = 30
	label.pixel_size = .2
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = site.position+Vector3(0,12,0)
	builder.labels.add_child(label)

func _winter_surfaces(mesh: MeshInstance3D, map) -> void:
	for i in mesh.mesh.get_surface_count():
		var original = mesh.mesh.surface_get_material(i)
		if original is ShaderMaterial:
			var name_lower: String = original.resource_name.to_lower()
			if "roof" in name_lower or "soil" in name_lower or "gravel" in name_lower or "concrete" in name_lower:
				var key: String = original.resource_path+":snow"
				if not _winter_materials.has(key):
					var material: ShaderMaterial = original.duplicate()
					material.set_shader_parameter("snow_amount",.88)
					_winter_materials[key] = material
				mesh.set_surface_override_material(i,_winter_materials[key])
			continue
		if not original is StandardMaterial3D:
			continue
		var name_lower: String = original.resource_name.to_lower()
		if not ("roof" in name_lower or "soil" in name_lower or "gravel" in name_lower or "concrete" in name_lower):
			continue
		var key: String = original.resource_path+":"+original.resource_name
		if not _winter_materials.has(key):
			var material: StandardMaterial3D = original.duplicate()
			material.albedo_texture = map._season["grass"]
			material.albedo_color = Color(.89,.92,.95)
			material.normal_enabled = false
			material.roughness_texture = null
			material.roughness = .95
			material.metallic = 0
			_winter_materials[key] = material
		mesh.set_surface_override_material(i,_winter_materials[key])
