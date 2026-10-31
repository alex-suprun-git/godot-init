# Settings that survive reloading the scene while the game is running. The
# season picks which look the map has; the scenario itself is the same in all of them.
extends RefCounted

# Real seconds per game hour at x1: a 15-hour day (07:00–22:00) takes 60 seconds,
# and the five-day live week takes five minutes before pauses.
const GAME_HOUR_SECONDS := 4.0
const TIME_SPEEDS := [0.0, 1.0, 2.0, 4.0]

const SEASONS := ["summer", "autumn", "winter"]

static var season := "summer"

# "iso": orthographic camera turned 45 degrees, matching the painted isometric
# sprites. "front": the older perspective camera looking straight along the
# streets. F2 switches between them while playing; --camera=front|iso at start.
const CAMERAS := ["iso", "front"]
static var camera_mode := "iso"
