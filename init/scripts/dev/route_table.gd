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
	var foot_speed: float = Week1.ACTORS["me"]["speed"]
	var car_speed: float = Week1.ACTORS["tolik"]["speed"]
	print("office -> target | straight m | foot m (player minutes @%.3f m/h) | car m (minutes @%.0f m/h; availability ignored)" % [foot_speed, car_speed])
	for id in ["block5", "boiler", "market", "church", "depot", "wasteland", "forest", "pond"]:
		var layout: String = Week1.LOTS[id]["layout"]
		var line := start.distance_to(graph.entrance_position(layout))
		var foot := RoadGraph.length(graph.route(start, layout, "foot"))
		var car := RoadGraph.length(graph.route(start, layout, "car"))
		print("%-10s %7.1f %9.3f (%5.1f min)  %7.1f (%5.1f min)" % [id, line, foot, foot / foot_speed * 60.0, car, car / car_speed * 60.0])
	quit()
