# Authored signal policy; geometry stays in DistrictLayout.ROADS.
# Stable IDs are shared by fixtures and future lane/phase controllers.
extends RefCounted

const Layout = preload("res://scripts/data/district_layout.gd")
const JUNCTIONS := {
	"axis_highway": {"roads": ["axis", "highway"]},
	"axis_north": {"roads": ["axis", "north_street"]},
	"axis_station": {"roads": ["axis", "south_street"]},
}


static func junction(id: String) -> Dictionary:
	var roads: Array = JUNCTIONS[id]["roads"]
	var vertical: Rect2 = Layout.road_by_id(roads[0])["rect"]
	var horizontal: Rect2 = Layout.road_by_id(roads[1])["rect"]
	var crossings: Array[String] = []
	for crossing in Layout.crosswalks():
		if crossing["road_id"] in roads and crossing["joining_road_id"] in roads:
			crossings.append(crossing["id"])
	return {"id": id, "roads": roads, "crossing_ids": crossings,
		"center": Vector2(vertical.get_center().x, horizontal.get_center().y)}


# One fixture at the right curb of each incoming arm, behind the near zebra.
# An arm must extend beyond the crossing: the avenue ends at the station T-junction.
static func fixtures(id: String) -> Array[Dictionary]:
	var data := junction(id)
	var center: Vector2 = data["center"]
	var result: Array[Dictionary] = []
	for road_id in data["roads"]:
		var road: Dictionary = Layout.road_by_id(road_id)
		var rect: Rect2 = road["rect"]
		var along_x := rect.size.x > rect.size.y
		var other_id: String = data["roads"][1] if road_id == data["roads"][0] else data["roads"][0]
		var other: Rect2 = Layout.road_by_id(other_id)["rect"]
		var half := (rect.size.y if along_x else rect.size.x) / 2.0
		var other_half := (other.size.x if along_x else other.size.y) / 2.0
		var lateral := half + maxf(Layout.sidewalk_width(road) * 0.82, 0.8)
		for direction: Vector2 in ([Vector2.RIGHT, Vector2.LEFT] if along_x else [Vector2.DOWN, Vector2.UP]):
			var at := center - direction * (other_half + 6.0)
			if not rect.has_point(at):
				continue
			var right := Vector2(-direction.y, direction.x)
			var approach := "west" if direction.x > 0 else ("east" if direction.x < 0 else ("north" if direction.y > 0 else "south"))
			var crossing_id := "%s__%s__%s" % [road_id, other_id, "before" if direction.x + direction.y > 0 else "after"]
			result.append({"id": id + "/" + approach, "intersection_id": id,
				"road_id": road_id, "approach": approach,
				"signal_group": id + ("/east_west" if along_x else "/north_south"),
				"position": at + right * lateral, "surface_height": 0.15 if Layout.sidewalk_width(road) > 0.0 else 0.0,
				"facing": -direction, "travel_direction": direction,
				"crossing_ids": [crossing_id]})
	return result
