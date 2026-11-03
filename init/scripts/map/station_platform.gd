# Planning pass for a real passenger edge, independent of the interim painting.
extends RefCounted

const Layout := preload("res://scripts/data/district_layout.gd")
const Surfaces := preload("res://scripts/map/station_surfaces.gd")

func build(map) -> void:
	var rect: Rect2 = Layout.STATION_PLATFORM["rect"]
	var height: float = Layout.STATION_PLATFORM["height"]
	var root := Node3D.new()
	root.name = "StationPlatform3D"
	map.add_child(root)
	map._box(Vector3(rect.size.x, height, rect.size.y),
		Vector3(rect.get_center().x, height / 2.0, rect.get_center().y), Color("85847d"), root)
	Surfaces.surface(root, rect, height + .01, 0)
	# Separate metre-long coping stones and vertical concrete panels, with real
	# joints. All faces remain clear of the actual ER2 envelope at z=392.995.
	var coping: Array[Vector3] = []
	var facing: Array[Vector3] = []
	for i in range(int(rect.size.x)):
		coping.append(Vector3(rect.position.x + i + .5, height + .015, rect.end.y - .275))
		if i % 2 == 0:
			facing.append(Vector3(rect.position.x + i + 1.0, height / 2.0, rect.end.y - .015))
	Surfaces.concrete_batch(root, Vector3(.987, .09, .55), coping, "PlatformCopingStones")
	Surfaces.concrete_batch(root, Vector3(1.98, height - .10, .07), facing, "PlatformConcreteFacing")
	# Small drainage details at the back, away from the safety line and boarding gap.
	var grate_bars: Array[Vector3] = []
	for x in [-130.0, -115.0, -100.0, -85.0, -45.0]:
		map._box(Vector3(.50, .012, .28), Vector3(x, height + .013, rect.position.y + .45), Color("4d504b"), root)
		for i in range(7):
			grate_bars.append(Vector3(x - .21 + i * .07, height + .023, rect.position.y + .45))
	Surfaces.concrete_batch(root, Vector3(.035, .015, .24), grate_bars, "PlatformDrainGrates", .22)
	# Match the railway's material family in the thin shoulder outside the wall.
	map._ground_quad(Vector2(rect.get_center().x, rect.end.y + .20), Vector2(rect.size.x, .38),
		.032, preload("res://assets/textures/bridge_ballast.png"), 4.0)
	# Restrained paint with small breaks at construction joints, not a neon band.
	for i in range(int(ceil(rect.size.x / 4.0))):
		map._box(Vector3(3.94, .012, .13),
			Vector3(rect.position.x + i * 4 + 2.0, height + .025, rect.end.y - .75), Color("b39a47"), root)
	# Broad end stairs keep the trial connected to ground at both ends.
	for east in [false, true]:
		for i in range(8):
			var step_height := height * float(8 - i) / 8.0
			var x := rect.end.x + (i + 0.5) * 0.45 if east else rect.position.x - (i + 0.5) * 0.45
			map._box(Vector3(0.45, step_height, 3.0),
				Vector3(x, step_height / 2.0, rect.get_center().y), Color("aaa89d"), root)
	map._occupy(rect.get_center(), rect.size)
