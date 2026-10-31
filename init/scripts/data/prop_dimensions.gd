# Dimensions are calibrated after projection, rather than by PNG canvas alone.
extends RefCounted

const PROFILES := {
	"bus_local_1997": {"width": 8.8, "axes": Vector2(0.42, -0.52), "height_scale": 0.82, "long_axis_positive": true},
	"truck_kamaz_semi": {"width": 16.5, "axes": Vector2(0.53, -0.45), "height_scale": 0.85},
	"car_lada_v3": {"width": 4.3, "axes": Vector2(0.48, -0.43), "height_scale": 0.78},
	"car_volga_black_v3": {"width": 5.0, "axes": Vector2(0.48, -0.42), "height_scale": 0.78},
	"bus_liaz": {"width": 9.0, "axes": Vector2(0.577, -0.37), "height_scale": 0.78},
	"tram": {"width": 10.5, "axes": Vector2(0.577, -0.36), "height_scale": 0.82},
}

# Alpha-height measurements at the fixed isometric view give these canvas
# widths an upright equivalent of 1.7–1.85 m for adults and 1.4 m for the child.
const PEOPLE_WIDTHS := {
	"person_walk_man": 1.15, "person_walk_woman": 1.14,
	"person_pensioner": 1.06, "person_worker": 1.43, "person_kid": 1.55,
}
