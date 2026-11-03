# One fixed through route per track; rendering and rolling stock share the bend.
extends RefCounted

const Layout := preload("res://scripts/data/district_layout.gd")
const Boundaries := preload("res://scripts/data/map_boundaries.gd")
const BEND_CENTER := Vector2(390, 375)
const BEND_STEPS := 24
const HIDDEN_MARGIN := 90.0 # More than half of the longest complete formation.

var points: Array[Vector3] = []
var distances: Array[float] = []
var length := 0.0


static func through_line(track_index: int) -> Array[Vector2]:
	var authored: Array = Layout.RAILS[track_index]
	var track_x: float = Layout.EMBANKMENT["tracks"][track_index]
	var radius := track_x - BEND_CENTER.x
	var line: Array[Vector2] = [authored[0]]
	for i in range(BEND_STEPS + 1):
		var angle := PI / 2.0 * (1.0 - float(i) / BEND_STEPS)
		line.append(BEND_CENTER + Vector2(cos(angle), sin(angle)) * radius)
	line.append(authored[-1])
	return line


func _init(track_index: int) -> void:
	var line := through_line(track_index)
	line[0].x = Boundaries.west_far_x() - HIDDEN_MARGIN
	# Height breakpoints keep the 3D distance and car pitch on the actual ramps.
	line.pop_back()
	var x: float = Layout.EMBANKMENT["tracks"][track_index]
	var embankment: Dictionary = Layout.EMBANKMENT
	line.append(Vector2(x, Layout.embankment_south_ramp_start()))
	line.append(Vector2(x, float(embankment["from"])))
	for bridge in Layout.BRIDGES:
		if bridge["kind"] == "rail" and not bridge.get("embankment_span", false):
			var rect: Rect2 = bridge["rect"]
			line.append(Vector2(x, rect.position.y + float(bridge["ramp"])))
			line.append(Vector2(x, rect.position.y))
	for point in line:
		var position := Vector3(point.x, rail_height(point), point.y)
		if not points.is_empty():
			length += position.distance_to(points[-1])
		points.append(position)
		distances.append(length)


static func rail_height(point: Vector2) -> float:
	var e: Dictionary = Layout.EMBANKMENT
	if point.y >= float(e["from"]) and point.y <= float(e["to"]) and point.x >= 405.0:
		return Layout.embankment_height(point.y) + 0.04
	for bridge in Layout.BRIDGES:
		var rect: Rect2 = bridge["rect"]
		if bridge["kind"] == "rail" and not bridge.get("embankment_span", false) and point.y >= rect.position.y and point.y < rect.end.y and point.x >= rect.position.x and point.x <= rect.end.x:
			return float(bridge["height"]) * clampf((point.y - rect.position.y) / float(bridge["ramp"]), 0.0, 1.0) + 0.03
	return 0.19


func distance_near(position: Vector3) -> float:
	var nearest := 0.0
	var best := INF
	for i in range(1, points.size()):
		var segment := points[i] - points[i - 1]
		var weight := clampf((position - points[i - 1]).dot(segment) / segment.length_squared(), 0.0, 1.0)
		var point := points[i - 1] + segment * weight
		var error := point.distance_squared_to(position)
		if error < best:
			best = error
			nearest = lerpf(distances[i - 1], distances[i], weight)
	return nearest


func sample(distance: float) -> Vector3:
	# Extrapolate under opaque haze so the cars never bunch at a clamped endpoint.
	if distance <= 0.0:
		return points[0] + (points[1] - points[0]).normalized() * distance
	if distance >= length:
		return points[-1] + (points[-1] - points[-2]).normalized() * (distance - length)
	for i in range(1, points.size()):
		if distance <= distances[i]:
			return points[i - 1].lerp(points[i], (distance - distances[i - 1]) / (distances[i] - distances[i - 1]))
	return points[-1]
