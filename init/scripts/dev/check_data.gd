# Data consistency check for CI and for local use:
#   Godot --headless --path init --script res://scripts/dev/check_data.gd
# Exits with 1 and lists the problems when the district data does not hang together.
extends SceneTree

const DistrictLayout = preload("res://scripts/data/district_layout.gd")
const RoadGraph = preload("res://scripts/map/road_graph.gd")
const Week1 = preload("res://scripts/data/week1.gd")
const BusStops = preload("res://scripts/data/bus_stops.gd")


func _init() -> void:
	var problems := PackedStringArray()
	problems.append_array(DistrictLayout.validate_districts())
	var layout_ids: Array = []
	for id in Week1.LOTS:
		var layout: String = Week1.LOTS[id]["layout"]
		layout_ids.append(layout)
		if not DistrictLayout.LOTS.has(layout):
			problems.append("week1 lot '%s' points at unknown layout lot '%s'" % [id, layout])
	var graph := RoadGraph.new(layout_ids)
	for layout in layout_ids:
		if DistrictLayout.LOTS.has(layout) and not graph.has_entrance(layout):
			problems.append("layout lot '%s' has no road entrance" % layout)
	problems.append_array(BusStops.validate())
	var crosswalks := DistrictLayout.crosswalks()
	for stop in BusStops.STOPS:
		for crossing in crosswalks:
			var gap: float = stop["at"].distance_to(crossing["at"])
			if gap < BusStops.MIN_CROSSWALK_GAP:
				problems.append("bus stop '%s' is %.1f m from crosswalk '%s' (minimum %.0f m)" % [stop["id"], gap, crossing["id"], BusStops.MIN_CROSSWALK_GAP])
	if problems.is_empty():
		print("check_data: ok (%d lots, %d districts)" % [DistrictLayout.LOTS.size(), DistrictLayout.DISTRICTS.size()])
		quit(0)
		return
	for problem in problems:
		printerr("check_data: " + problem)
	quit(1)
