# Light and sky for a given clock hour in a given season. Pure function of the
# hour: the map applies the result every frame, nothing here holds state.
# At the season's reference hour (13:00) the result equals the authored season look.
extends RefCounted

const NOON := 13.0
# Sunrise and sunset by season, in clock hours (late August, October, December).
const SUN_TIMES := {"summer": Vector2(5.8, 20.6), "autumn": Vector2(7.2, 18.0), "winter": Vector2(9.0, 15.8)}
const WARM := Color(1.0, 0.58, 0.32)
const MOON := Color(0.42, 0.52, 0.85)
const NIGHT_TOP := Color(0.04, 0.06, 0.14)
const NIGHT_HORIZON := Color(0.10, 0.12, 0.22)
const DUSK_HORIZON := Color(0.95, 0.52, 0.34)
const DUSK_TOP := Color(0.34, 0.30, 0.46)
const TWILIGHT_DEGREES := 7.0 # How far below the horizon the sky keeps its dusk glow.


static func sample(season_key: String, season: Dictionary, hour: float) -> Dictionary:
	var times: Vector2 = SUN_TIMES[season_key]
	var noon_altitude: float = -float(season["sun_rotation"].x)
	var day_fraction := (hour - times.x) / (times.y - times.x)
	# Sun height: a half sine over the day, negative (below the horizon) at night.
	var altitude := noon_altitude * sin(PI * day_fraction)
	if day_fraction < 0.0 or day_fraction > 1.0:
		altitude = -minf(TWILIGHT_DEGREES * 2.0, absf(altitude) + 3.0)
	var height := clampf(altitude / noon_altitude, -1.0, 1.0) # 1 at noon, 0 at the horizon
	# 0 = deep night, 1 = full day; twilight in between.
	var light := smoothstep(-TWILIGHT_DEGREES, 5.0, altitude)
	var direct := smoothstep(-1.0, 6.0, altitude)
	# Warmth peaks when the sun is low.
	var warm := (1.0 - smoothstep(0.05, 0.45, height)) * direct
	var glow := (1.0 - smoothstep(0.0, 0.5, light)) * smoothstep(-0.5, 0.35, light) * (1.0 - direct) + warm * 0.6

	var sun_color: Color = season["sun_color"].lerp(WARM, warm)
	var sun_energy: float = float(season["sun_energy"]) * direct
	var sun_rotation: Vector3 = season["sun_rotation"]
	# The sun swings through ±75° across the day; at night a fixed moon takes over.
	var swing := clampf((hour - NOON) / (times.y - times.x) * 150.0, -90.0, 90.0)
	var pitch := -maxf(altitude, 4.0)
	var yaw: float = sun_rotation.y + swing
	var moon_mix := 1.0 - direct
	sun_color = sun_color.lerp(MOON, moon_mix)
	sun_energy = maxf(sun_energy, 0.28 * moon_mix)
	pitch = lerpf(pitch, -38.0, moon_mix)

	var sky_top: Color = NIGHT_TOP.lerp(DUSK_TOP, clampf(glow, 0.0, 1.0)).lerp(season["sky_top"], light)
	var sky_horizon: Color = NIGHT_HORIZON.lerp(DUSK_HORIZON, clampf(glow, 0.0, 1.0)).lerp(season["sky_horizon"], light)
	return {
		"sun_rotation": Vector3(pitch, yaw, 0.0),
		"sun_color": sun_color,
		"sun_energy": sun_energy,
		"ambient": lerpf(0.22, float(season["ambient"]), light),
		"sky_top": sky_top,
		"sky_horizon": sky_horizon,
		"fog_color": sky_horizon.darkened(0.45 * (1.0 - light)).lerp(season["fog_color"], light * 0.6),
		"saturation": lerpf(0.7, float(season["saturation"]), light),
		"light": light,
		# Windows and lamps come on as dusk falls and go off after sunrise.
		"night": 1.0 - smoothstep(0.12, 0.6, light),
	}
