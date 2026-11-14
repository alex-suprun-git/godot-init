# Route markers cue dialogue and camera attention during one continuous drive.
extends RefCounted

const BRIEFING_HOUR := 10.0 + 4.0 / 60.0
const TRAFFIC := {
	"motion_scale": 1.25,
	"station_road_speed_scale": 1.5,
	"cars": 0.40,
	"pedestrians": 0.55,
	"pedestrians_by_district": {"south_hub": 0.75, "village": 0.10},
	"station_crowd": 0.35,
	"driver_speed": 10.0,
}
const MEETING := "Толик: О, приехали! Вы ведь помощник? Толик я, водитель. Сумку в багажник, и поедем."

const DRIVE := [
	{"id": "market", "road": "station_link", "at": Vector2(-70, 348), "minute": 364, "lot": "market", "name": "Вокзал и рынок",
		"focus": Vector2(-103, 370),
		"caption": "Толик: Вон вокзал, рядом рынок. Тут весь район кормится. Кошелёк держите поближе."},
	{"id": "dormitory", "road": "west_street", "at": Vector2(-480, 75), "minute": 380, "lot": "dormitory", "name": "Общежитие",
		"caption": "Толик: А вот общежитие. Сосед храпит так, что труб не слышно."},
	{"id": "industrial_link", "road": "industrial_link", "at": Vector2(-440, -166), "lead": 7.0, "minute": 398, "lot": "boiler", "name": "Котельная",
		"caption": "Толик: Выезжаем на шоссе. Котельную вон третий год к зиме чинят."},
	{"id": "depot", "road": "highway", "at": Vector2(-392, -187.5), "minute": 405, "lot": "atp", "name": "АТП",
		"caption": "Толик: Вон АТП. С отоплением к Михалычу. Золотые руки, если найдёте."},
	{"id": "border", "road": "highway", "at": Vector2(-182, -187.5), "minute": 430, "lot": "checkpoint", "name": "Погранпункт",
		"focus": Vector2(-76, -245), "focus_zoom": 200.0,
		"highlight": Rect2(-151, -303, 152, 104),
		"caption": "Толик: А это граница. Будка новая. Старая, говорят, не выдержала."},
	{"id": "restaurant", "road": "village_street", "at": Vector2(145, -64), "lead": 30.0, "minute": 450, "lot": "city_park",
		"focus": Vector2(123, -22), "focus_zoom": 99.0, "caption": "Толик: Тут обедают.",
		"approach_caption": "Толик: …а я ему: батя, ты же ничего не пон…",
		"approach_seconds": 2.7, "silence_seconds": 0.45, "reveal_delay": 0.85},
	{"id": "village", "road": "village_west_link", "at": Vector2(174, 72.046), "minute": 465, "lot": "church", "name": "Церковь",
		"caption": "Толик: Ну-с! Деревня! Вон церковь отца Георгия. Вот у кого чай настоящий."},
	{"id": "office", "road": "axis", "at": Vector2(-5, 77), "lead": 58.0, "minute": 480, "lot": "ispolkom", "name": "Исполком",
		"caption": "Толик: Исполком. Вам на второй этаж. Борис Саввич будет к десяти. Ну, ни пуха."},
]
