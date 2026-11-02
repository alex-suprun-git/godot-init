# Shared vehicle/road policy. Movement consumes these decisions on straights,
# turn endpoints and gateway legs, so a rule cannot change at a state boundary.
extends RefCounted


static func can_use_road(vehicle_class: String, road: Dictionary) -> bool:
	if road.has("vehicles") and vehicle_class not in road["vehicles"]:
		return false
	return road["kind"] == "asphalt" or (road.get("traffic", "") == "courtyard" and vehicle_class == "car")


static func lane_offset(vehicle_class: String, edge: Dictionary, road: Dictionary) -> float:
	var half: float = edge["half"]
	if edge["kind"] == "yard":
		return clampf(half * 0.45, 0.7, 1.0)
	if vehicle_class == "bus":
		# Lane count is per direction, numbered from the centre toward the curb.
		# Exclude a boulevard's median before finding the outer lane centre.
		var median_half := float(road.get("median", 0.0)) * 0.5
		var lanes := maxi(1, int(road.get("lanes_per_direction", 1)))
		var lane_width := maxf(half - median_half, 0.0) / lanes
		return median_half + lane_width * (lanes - 0.5)
	return clampf(half * 0.35, 1.5, 4.0)
