# People for the housing courtyards, the school and the kindergarten: domino players, a queue at the
# beer stall, mothers and children on the playground, pupils on the assembly court and the football
# pitch, small children on the kindergarten sand. Scenery only (no residents, requests or paths),
# thinning at night like the station crowd; school and kindergarten people are out in daytime only.
# Positions are metres relative to each lot centre, matching residential_cores.gd / courtyard_life.gd.
extends "res://scripts/map/station_crowd.gd"

const Layout = preload("res://scripts/data/district_layout.gd")
const MAN := 0
const WOMAN := 1
const PENSIONER := 2
const WORKER := 3
const KID := 4
const SCHOOL_HOURS := Vector2(8.0, 15.5)
const KINDERGARTEN_HOURS := Vector2(8.0, 18.0)
const YARD_HOURS := Vector2(7.0, 22.0)
const FLOOR := 0.1

var _origin := Vector2.ZERO


func build(city_map) -> void:
	map = city_map
	name = "CourtyardCrowd"
	_rng.seed = 19970826
	_house5_yard()
	_waste_yard()
	_school()
	_kindergarten()
	print("Courtyard crowd: ", _people.size(), " ambient people")


func _at(local: Vector2) -> Vector2:
	return _origin + local


func _stand(local: Vector2, kind := -1, hours := YARD_HOURS) -> void:
	_person(_at(local) + Vector2(_rng.randf_range(-.25, .25), _rng.randf_range(-.25, .25)), FLOOR, kind, hours)


func _stroll(from: Vector2, to: Vector2, kind := -1, hours := YARD_HOURS) -> void:
	_walker(_at(from), _at(to), FLOOR, kind, hours)


# Domino table, beer stall and the playground in the House 5 courtyard (courtyard_life.gd).
func _house5_yard() -> void:
	_origin = Layout.lot_center("b1_k")
	for spot in [Vector2(17.6, 22.8), Vector2(20.4, 22.8), Vector2(17.6, 25.4), Vector2(20.4, 25.4)]:
		_stand(spot, MAN if _rng.randf() < .6 else PENSIONER)
	for spot in [Vector2(38.4, 21.9), Vector2(40.0, 22.4), Vector2(41.7, 21.8)]:
		_stand(spot, MAN if _rng.randf() < .7 else WORKER)
	for spot in [Vector2(36.5, 24.5), Vector2(43.5, 24.8)]:
		_stand(spot, MAN)
	# Playground at (-20,-12): sand pit, roundabout, climbing frame.
	for spot in [Vector2(-9.0, -5.0), Vector2(-11.0, -7.0), Vector2(-8.0, -8.5)]:
		_stroll(spot, spot + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(-2.0, 2.0)), KID)
	_stand(Vector2(-3.0, -2.0), WOMAN)
	_stand(Vector2(-6.0, -1.0), PENSIONER)
	_stroll(Vector2(-31.0, -4.0), Vector2(-9.0, 3.0), PENSIONER)
	_stroll(Vector2(24.0, 4.0), Vector2(8.0, 12.0), WOMAN)


func _waste_yard() -> void:
	_origin = Layout.lot_center("a2_k")
	_stand(Vector2(-6.0, 4.0), MAN)
	_stand(Vector2(-4.4, 5.0), MAN)
	_stroll(Vector2(-30.0, -10.0), Vector2(12.0, -2.0), WORKER)


func _school() -> void:
	_origin = Layout.lot_center("a1_k")
	# Assembly court, paved (-14,1) 27x24: groups of pupils and two teachers.
	for group in [Vector2(-20.0, -4.0), Vector2(-9.0, 4.0), Vector2(-16.0, 9.0)]:
		for i in 4:
			_stand(group + Vector2(i * .9 - 1.4, _rng.randf_range(-.8, .8)), KID, SCHOOL_HOURS)
	for pair in [[Vector2(-21.0, 6.0), Vector2(-6.0, 6.0)], [Vector2(-22.0, -2.0), Vector2(-4.0, -2.0)]]:
		_stroll(pair[0], pair[1], KID, SCHOOL_HOURS)
	_stand(Vector2(-12.0, -3.0), WOMAN, SCHOOL_HOURS)
	_stand(Vector2(-5.0, 11.0), MAN, SCHOOL_HOURS)
	# Bench row (-26,5..10) and the gate walk.
	_stand(Vector2(-25.0, 5.0), KID, SCHOOL_HOURS)
	_stand(Vector2(-25.0, 10.0), KID, SCHOOL_HOURS)
	_stroll(Vector2(-14.0, 36.0), Vector2(-14.0, 24.0), KID, SCHOOL_HOURS)
	_stroll(Vector2(-13.0, 44.0), Vector2(-14.0, 30.0), WOMAN, SCHOOL_HOURS)
	# Football pitch at (31,20): a few lads running between the goals.
	for i in 6:
		var from := Vector2(25.0 + i * 1.5, 14.0 + (i % 3) * 3.0)
		_stroll(from, from + Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-3.0, 4.0)), KID, SCHOOL_HOURS)


func _kindergarten() -> void:
	_origin = Layout.lot_center("b2_k")
	# Two sand/dirt patches: (-17,16) 18x13 and (16,23) 16x8.
	for i in 5:
		var spot := Vector2(-23.0 + i * 2.6, 13.0 + (i % 2) * 3.5)
		_stroll(spot, spot + Vector2(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-1.5, 1.5)), KID, KINDERGARTEN_HOURS)
	_stand(Vector2(-12.0, 21.0), WOMAN, KINDERGARTEN_HOURS)
	for i in 3:
		var spot := Vector2(12.0 + i * 3.0, 22.0 + (i % 2) * 2.0)
		_stroll(spot, spot + Vector2(_rng.randf_range(-1.5, 1.5), _rng.randf_range(-1.0, 1.0)), KID, KINDERGARTEN_HOURS)
	_stand(Vector2(19.0, 26.0), WOMAN, KINDERGARTEN_HOURS)
	# Parents at the east gate (29,13) and on the entry court (0,5).
	_stand(Vector2(31.5, 11.0), WOMAN, KINDERGARTEN_HOURS)
	_stand(Vector2(32.5, 15.5), MAN, KINDERGARTEN_HOURS)
	_stroll(Vector2(48.0, 13.0), Vector2(31.0, 13.0), WOMAN, KINDERGARTEN_HOURS)
	_stand(Vector2(-1.0, 12.0), WOMAN, KINDERGARTEN_HOURS)
