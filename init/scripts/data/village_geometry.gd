# Area compaction approved 2026-11-07: sqrt(0.9) per axis, west edge anchored.
# Transform placement, never the scale of buildings, furniture or trees.
extends RefCounted
const ANCHOR := Vector2(150,-75)
const SCALE := 0.9486832980505138

static func point(at: Vector2) -> Vector2:
	return ANCHOR+(at-ANCHOR)*SCALE

static func point3(at: Vector3) -> Vector3:
	var p := point(Vector2(at.x,at.z))
	return Vector3(p.x,at.y,p.y)
