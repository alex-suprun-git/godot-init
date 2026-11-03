# Planning pass for a real passenger edge, independent of the interim painting.
extends RefCounted

const Layout := preload("res://scripts/data/district_layout.gd")

func build(map) -> void:
	var rect: Rect2 = Layout.STATION_PLATFORM["rect"]
	var height: float = Layout.STATION_PLATFORM["height"]
	var root := Node3D.new()
	root.name = "StationPlatform3D"
	map.add_child(root)
	map._box(Vector3(rect.size.x, height, rect.size.y),
		Vector3(rect.get_center().x, height / 2.0, rect.get_center().y), Color("85847d"), root)
	map._ground_quad(rect.get_center(), rect.size, height + 0.01, map._season["paving"], 12.0)
	# The whole ER2 envelope ends at z=392.995; this edge stays 0.245 m clear.
	map._box(Vector3(rect.size.x, 0.08, 0.35),
		Vector3(rect.get_center().x, height - 0.04, rect.end.y - 0.175), Color("b8b7a9"), root)
	map._box(Vector3(rect.size.x, 0.012, 0.20),
		Vector3(rect.get_center().x, height + 0.025, rect.end.y - 0.65), Color("d5b94e"), root)
	# Broad end stairs keep the trial connected to ground at both ends.
	for east in [false, true]:
		for i in range(8):
			var step_height := height * float(8 - i) / 8.0
			var x := rect.end.x + (i + 0.5) * 0.45 if east else rect.position.x - (i + 0.5) * 0.45
			map._box(Vector3(0.45, step_height, 3.0),
				Vector3(x, step_height / 2.0, rect.get_center().y), Color("aaa89d"), root)
	map._occupy(rect.get_center(), rect.size)
