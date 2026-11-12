# Daily operating-state schedules. Times use the game's local 24-hour clock.
extends RefCounted

const DAILY := {
	"boiler_access": {
		"open_at": 6.0,
		"close_at": 20.0,
		"open_state": &"open",
		"closed_state": &"closed",
	},
	"atp": {
		"open_at": 6.0,
		"close_at": 20.0,
		"open_state": &"open",
		"closed_state": &"closed",
	},
}
