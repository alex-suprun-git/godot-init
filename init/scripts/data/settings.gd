# Settings that survive reloading the scene while the game is running. The
# season picks which look the map has; the scenario itself is the same in all of them.
extends RefCounted

# Real seconds per game hour at x1: a 16-hour day (06:00–22:00) takes 64 seconds,
# plus any overtime and the walk home. Five base days take 5 minutes 20 seconds.
const GAME_HOUR_SECONDS := 4.0
const TIME_SPEEDS := [0.0, 1.0, 2.0, 4.0]

const SEASONS := ["summer", "autumn", "winter"]

static var season := "summer"

# "iso": orthographic camera turned 45 degrees, matching the painted isometric
# sprites. "front": the older perspective camera looking straight along the
# streets. F2 switches between them while playing; --camera=front|iso at start.
const CAMERAS := ["iso", "front"]
static var camera_mode := "iso"

# Header scale preference; remaining HUD regions will opt in after layout review.
static var ui_scale := 1.0
