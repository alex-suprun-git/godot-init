# Dev audit: parked/static vehicles that collide with other geometry, overlap each other or
# stand across a road. Read-only; prints one line per finding and a summary.
#   Godot --headless --path init --script res://scripts/dev/audit_parked.gd -- --no-log
extends SceneTree

const VEHICLE_WIDTH := 2.0


func _init() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	for i in 20:
		await process_frame
	var map = main.map
	var moving := {}
	for agent in map._ambient.agents:
		if agent.get("visual") != null:
			moving[agent["visual"]] = true
	var vehicles: Array[Node3D] = []
	for node in get_nodes_in_group("vehicle_models"):
		if node is Node3D and not moving.has(node):
			vehicles.append(node)
	print("audit: %d static vehicles" % vehicles.size())
	var roads: Array = map.DistrictLayout.ROADS
	var findings := 0
	var boxes: Array[AABB] = _vehicle_boxes(vehicles)
	# Static geometry to test against: every mesh that is not part of a vehicle, not ground-flat.
	var statics: Array[Dictionary] = []
	for mesh: MeshInstance3D in map.find_children("*", "MeshInstance3D", true, false):
		if _inside_vehicle(mesh, vehicles) or mesh.mesh == null:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		if box.size.y < 0.35 or box.size.x > 60.0 or box.size.z > 60.0:
			continue # ground patches, roads, huge terrain pieces
		statics.append({"box": box, "node": mesh})
	for i in vehicles.size():
		var vehicle := vehicles[i]
		var body: AABB = boxes[i]
		var at := Vector2(vehicle.global_position.x, vehicle.global_position.z)
		var across: bool = _long_axis_x(vehicle)
		var label := "%s at (%.1f, %.1f) axis=%s" % [vehicle.name, at.x, at.y, "x" if across else "z"]
		for j in range(i + 1, vehicles.size()):
			if body.grow(-0.15).intersects(boxes[j].grow(-0.15)):
				findings += 1
				print("OVERLAP-VEHICLE  ", label, " <-> ", vehicles[j].name, " (%.1f, %.1f)" % [vehicles[j].global_position.x, vehicles[j].global_position.z])
		for entry in statics:
			if body.grow(-0.1).intersects(entry["box"]):
				findings += 1
				print("COLLIDES         ", label, " with ", String(entry["node"].get_path()).get_slice("/", 3), "/", entry["node"].name)
				break
		var flat := Rect2(at - (Vector2(2.2, 1.0) if across else Vector2(1.0, 2.2)), Vector2(4.4, 2.0) if across else Vector2(2.0, 4.4))
		for road in roads:
			if road["kind"] != "asphalt" or vehicle.is_in_group("parked_vehicles"):
				continue
			var rect: Rect2 = road["rect"]
			if not rect.intersects(flat):
				continue
			var road_along_x: bool = rect.size.x > rect.size.y
			if road_along_x != across:
				findings += 1
				print("ACROSS-ROAD      ", label, " on ", road["id"])
	print("audit: %d findings" % findings)
	quit()


func _vehicle_boxes(vehicles: Array[Node3D]) -> Array[AABB]:
	var result: Array[AABB] = []
	for vehicle in vehicles:
		var box := AABB()
		var first := true
		for mesh: MeshInstance3D in vehicle.find_children("*", "MeshInstance3D", true, false):
			var part := mesh.global_transform * mesh.get_aabb()
			box = part if first else box.merge(part)
			first = false
		result.append(box)
	return result


func _inside_vehicle(node: Node, vehicles: Array[Node3D]) -> bool:
	for vehicle in vehicles:
		if vehicle.is_ancestor_of(node):
			return true
	return node.is_in_group("vehicle_models")


# True when the vehicle's forward axis runs along world X (yaw of +-90 degrees).
func _long_axis_x(vehicle: Node3D) -> bool:
	return absf(sin(vehicle.global_rotation.y)) > 0.7
