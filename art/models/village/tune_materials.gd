# Repeatable, local PBR calibration. No global light/exposure changes.
extends SceneTree
const LIBRARY := "res://assets/materials/village/"
const SHADER = preload("res://assets/shaders/village_surface.gdshader")
const TEXTURED := {
	"Buff brick":["buff_brick",Color(.83,.81,.77),.93,.0,.22],
	"Pale house plaster":["pale_house_plaster",Color(.76,.77,.72),.95,.0,.18],
	"Grey roof metal":["grey_roof_metal",Color(.66,.69,.69),.86,.12,.15],
	"Ordinary brown wood":["ordinary_brown_wood",Color(.72,.66,.56),.94,.0,.25],
	"Masonry plinth":["masonry_plinth",Color(.52,.44,.35),.95,.0,.20],
	"Yard concrete":["yard_concrete",Color(.61,.64,.63),.96,.0,.22],
	"Green fence steel":["green_fence_steel",Color(.77,.79,.72),.88,.08,.12],
	"Gravel driveway":["gravel_driveway",Color(.66,.65,.59),.96,.0,.25],
	"Garden soil":["garden_soil",Color(.72,.67,.61),.98,.0,.18],
	"Blue grey timber":["blue_grey_timber",Color(.72,.77,.79),.94,.0,.25],
}
const FLAT := {
	"Roof folds and gutters":[Color(.30,.34,.34),.88,.12],
	"Blue grey fence steel":[Color(.32,.40,.43),.89,.08],
	"Dark household iron":[Color(.15,.18,.16),.92,.08],
	"Ivory window paint":[Color(.62,.61,.55),.92,.0],
	"Deep window reveal":[Color(.075,.09,.085),.96,.0],
	"Residential glazing":[Color(.14,.23,.25),.38,.0],
	"Muted greenhouse glazing":[Color(.32,.40,.35),.72,.0],
	"Linen curtains":[Color(.56,.52,.43),.98,.0],
	"Vegetable foliage":[Color(.24,.35,.16),.98,.0],
	"Vegetable leaf tips":[Color(.32,.42,.21),.98,.0],
	"Plain household laundry":[Color(.62,.62,.55),.98,.0],
}

# Identical maps are stored once (same VRAM import settings): per-stem files exist only when unique.
const SHARED_ALBEDO := {"masonry_plinth":"buff_brick"}
const METAL_STEMS := ["grey_roof_metal","green_fence_steel"]

func _map(stem: String, kind: String) -> Texture2D:
	var own := LIBRARY+stem+"_"+kind+".png"
	if ResourceLoader.exists(own):
		return load(own)
	if kind == "albedo":
		return load(LIBRARY+SHARED_ALBEDO[stem]+"_albedo.png")
	var metal := stem in METAL_STEMS
	if kind == "normal":
		return load(LIBRARY+("normal_metal.png" if metal else "normal_fine.png"))
	return load(LIBRARY+("response_metal.png" if metal else "response_matte.png"))

func _initialize() -> void:
	for label in TEXTURED:
		var spec: Array = TEXTURED[label]
		var stem: String = spec[0]
		var material := ShaderMaterial.new()
		material.resource_name = label
		material.shader = SHADER
		material.set_shader_parameter("albedo_texture",_map(stem,"albedo"))
		material.set_shader_parameter("normal_texture",_map(stem,"normal"))
		material.set_shader_parameter("response_texture",_map(stem,"roughness"))
		if label == "Ordinary brown wood":
			material.set_shader_parameter("albedo_texture",load("res://assets/models/church_ensemble/wood.png"))
			material.set_shader_parameter("normal_texture",load("res://assets/models/church_ensemble/wood_normal.png"))
		material.set_shader_parameter("colour_tint",spec[1])
		material.set_shader_parameter("roughness_floor",spec[2])
		material.set_shader_parameter("metal_amount",spec[3])
		material.set_shader_parameter("normal_strength",spec[4])
		ResourceSaver.save(material,LIBRARY+stem+".tres")
	for label in FLAT:
		var spec: Array = FLAT[label]
		var material := StandardMaterial3D.new()
		material.resource_name = label
		material.albedo_color = spec[0]
		material.roughness = spec[1]
		material.metallic = spec[2]
		material.metallic_specular = .12
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		ResourceSaver.save(material,LIBRARY+slug(label)+".tres")
	print("Village materials calibrated: ",TEXTURED.size()," textured / ",FLAT.size()," flat; scene lighting unchanged")
	quit()

func slug(value: String) -> String:
	return value.to_lower().replace(" ","_")
