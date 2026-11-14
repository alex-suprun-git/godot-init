# Local occupancy for the ambient simulation. Entries store the live agent dictionaries,
# so each accepted movement is visible to the next driver in the same simulation tick.
extends RefCounted

const CELL := 48.0
const HALF_LENGTH := {"car": 2.5, "truck": 7.0, "bus": 6.0}
const HALF_WIDTH := {"car": 0.95, "truck": 1.3, "bus": 1.3}
var cells := {}
var car_cells := {}

func cell(point: Vector2) -> Vector2i:
	return Vector2i((point / CELL).floor())

func track(agent: Dictionary) -> void:
	var at := cell(agent["pos"])
	var grid := car_cells if agent["is_car"] else cells
	if agent.has("traffic_cell"):
		var old: Vector2i = agent["traffic_cell"]
		if old == at and agent["visible"]:
			return
		var occupants: Array = grid[old]
		# Dictionaries contain scene references; compare identity, not contents.
		for i in occupants.size():
			if is_same(occupants[i], agent):
				occupants.remove_at(i)
				break
		if occupants.is_empty():
			grid.erase(old)
		agent.erase("traffic_cell")
	if agent["visible"]:
		if not grid.has(at):
			grid[at] = []
		grid[at].append(agent)
		agent["traffic_cell"] = at

func nearby(point: Vector2, radius: float, cars_only := false) -> Array:
	var result := []
	var first := cell(point - Vector2.ONE * radius)
	var last := cell(point + Vector2.ONE * radius)
	var radius_squared := radius * radius
	for x in range(first.x, last.x + 1):
		for y in range(first.y, last.y + 1):
			var key := Vector2i(x, y)
			if car_cells.has(key):
				_collect(car_cells[key], point, radius_squared, result)
			if not cars_only and cells.has(key):
				_collect(cells[key], point, radius_squared, result)
	return result

func _collect(occupants: Array, point: Vector2, radius_squared: float, result: Array) -> void:
	for other in occupants:
		if point.distance_squared_to(other["pos"]) <= radius_squared:
			result.append(other)


static func half_length(agent: Dictionary) -> float:
	if agent.has("half_extent"):
		return agent["half_extent"].y
	return HALF_LENGTH.get(agent["class"], 0.35)

static func half_width(agent: Dictionary) -> float:
	if agent.has("half_extent"):
		return agent["half_extent"].x
	return HALF_WIDTH.get(agent["class"], 0.35)

# Separating-axis check for two oriented footprints, including a small safety margin.
static func overlaps(agent: Dictionary, other: Dictionary) -> bool:
	var offset: Vector2 = other["pos"] - agent["pos"]
	var length_a := half_length(agent)
	var length_b := half_length(other)
	var width_a := half_width(agent)
	var width_b := half_width(other)
	var broad := length_a + length_b + width_a + width_b + 0.08
	if offset.length_squared() > broad * broad:
		return false
	var a: Vector2 = agent["heading"]
	var b: Vector2 = other["heading"]
	var ar := a.orthogonal()
	var br := b.orthogonal()
	return not (_separated(a, offset, a, ar, b, br, length_a, width_a, length_b, width_b)
		or _separated(ar, offset, a, ar, b, br, length_a, width_a, length_b, width_b)
		or _separated(b, offset, a, ar, b, br, length_a, width_a, length_b, width_b)
		or _separated(br, offset, a, ar, b, br, length_a, width_a, length_b, width_b))

static func _separated(axis: Vector2, offset: Vector2, a: Vector2, ar: Vector2, b: Vector2, br: Vector2,
		length_a: float, width_a: float, length_b: float, width_b: float) -> bool:
	var reach := absf(axis.dot(a)) * length_a + absf(axis.dot(ar)) * width_a
	reach += absf(axis.dot(b)) * length_b + absf(axis.dot(br)) * width_b
	return absf(offset.dot(axis)) >= reach + 0.08

func clear_pose(agent: Dictionary, neighbors: Array) -> bool:
	var agent_is_car: bool = agent["is_car"]
	var at: Vector2 = agent["pos"]
	# Anything farther than both footprints plus the margin cannot overlap; skip it before
	# the full separating-axis test, which needs headings and four dot-product rounds.
	var length_a := half_length(agent)
	var width_a := half_width(agent)
	for other in neighbors:
		if is_same(agent, other) or (not agent_is_car and not other["is_car"]):
			continue
		var broad := length_a + half_length(other) + width_a + half_width(other) + 0.08
		if (other["pos"] - at).length_squared() > broad * broad:
			continue
		if overlaps(agent, other):
			return false
	return true
