# Settings that survive reloading the scene while the game is running. The
# season picks which look the map has; the scenario itself is the same in all of them.
extends RefCounted

const SEASONS := ["summer", "autumn", "winter"]

static var season := "summer"

# "iso": orthographic camera turned 45 degrees, matching the painted isometric
# sprites. "front": the older perspective camera looking straight along the
# streets. F2 switches between them while playing; --camera=front|iso at start.
const CAMERAS := ["iso", "front"]
static var camera_mode := "iso"
