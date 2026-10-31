# Dev-only: prints straight-line and road-route travel times from the office.
# Run: Godot --headless --path init --script res://scripts/dev/route_table.gd
extends SceneTree

const Week1 = preload("res://scripts/data/week1.gd")
const RoadGraph = preload("res://scripts/map/road_graph.gd")


func _init() -> void:
	var lots: Array = []
	for id in Week1.LOTS:
		lots.append(Week1.LOTS[id]["layout"])
	var graph := RoadGraph.new(lots)
	var start := graph.entrance_position(Week1.LOTS["office"]["layout"])
	print("office -> target | straight m | foot m (min @70..120 m/h) | car m (min @400 m/h)")
	for id in ["block5", "boiler", "market", "church", "depot", "wasteland", "forest", "pond"]:
		var layout: String = Week1.LOTS[id]["layout"]
		var line := start.distance_to(graph.entrance_position(layout))
		var foot := RoadGraph.length(graph.route(start, layout, "foot"))
		var car := RoadGraph.length(graph.route(start, layout, "car"))
		print("%-10s %7.0f %7.0f (%3.0f min @120)  %7.0f (%3.0f min @400)" % [id, line, foot, foot / 120.0 * 60.0, car, car / 400.0 * 60.0])
	quit()
