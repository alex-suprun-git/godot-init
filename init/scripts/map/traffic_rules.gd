# Shared vehicle/road policy. Movement consumes these decisions on straights,
# turn endpoints and gateway legs, so a rule cannot change at a state boundary.
extends RefCounted

const CITY_SPEED := 0.75


static func can_use_road(vehicle_class: String, road: Dictionary) -> bool:
	if road.has("vehicles") and vehicle_class not in road["vehicles"]:
		return false
	return road["kind"] == "asphalt" or (road.get("traffic", "") == "courtyard" and vehicle_class == "car")


static func lane_offset(vehicle_class: String, edge: Dictionary, road: Dictionary, passing: bool = false) -> float:
	var half: float = edge["half"]
	if edge["kind"] == "yard":
		return half * 0.5
	var median := float(road.get("median", 0.0)) * 0.5
	var lanes := maxi(1, int(road.get("lanes_per_direction", 1)))
	# Leave a strip for parked vehicles on streets that support curbside parking.
	if half >= 5.0 and road.get("look", "") != "highway" and not road.get("hub_surface", false):
		half -= 2.0
	var lane := lanes - 1
	if passing and vehicle_class != "bus":
		lane = maxi(0, lane - 1)
	return median + (half - median) * (lane + 0.5) / lanes
