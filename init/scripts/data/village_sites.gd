# Geometry-generated site data is shared by visual placement and road access.
extends RefCounted
static var _sites: Dictionary = {}

static func all() -> Dictionary:
	if _sites.is_empty():
		_sites = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/data/village_sites.json"))
	return _sites

static func point(id: String, key: String) -> Vector2:
	var value: Array = all()[id][key]
	return Vector2(value[0],value[1])
