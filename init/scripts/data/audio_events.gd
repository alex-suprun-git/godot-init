# Table of sound events. Pure data: the audio manager plays from it and the
# F3 debug panel reads it, so tuning feedback never needs code changes.
#
# Tiers (how much a feedback sound may weigh; see README, "Feedback"):
#   1  barely there: frequent, reversible actions; short, quiet, several variants
#   2  meaningful: the player committed to something
#   3  event: rare and recognizable; something happened in the world
#   4  story moment: unique
# Hover, scrolling and camera movement are tier 0: silent by design, so they
# are not in this table.
#
# "sounds" lists audio files (res://assets/audio/...). An empty list is a silent
# placeholder: the event still fires, counts, and shows up in the debug panel,
# so the design can be tuned before any sound exists.
extends RefCounted

const BUSES := ["Music", "SFX", "Ambience", "UI"]

# Events per minute above which an event of that tier is flagged as tiring.
const MAX_PER_MINUTE := {1: 8.0, 2: 4.0, 3: 3.0, 4: 1.0}

const EVENTS := {
	"card_open": {
		"label": "Открыть карточку запроса", "tier": 1, "bus": "UI",
		"sounds": [], "volume_db": -14.0, "pitch_jitter": 0.06, "cooldown": 0.1,
	},
	"card_close": {
		"label": "Закрыть карточку", "tier": 1, "bus": "UI",
		"sounds": [], "volume_db": -16.0, "pitch_jitter": 0.06, "cooldown": 0.1,
	},
	"speed_click": {
		"label": "Кнопки скорости", "tier": 1, "bus": "UI",
		"sounds": [], "volume_db": -16.0, "pitch_jitter": 0.04, "cooldown": 0.1,
	},
	"option_choose": {
		"label": "Подтвердить выбор (отправить)", "tier": 2, "bus": "SFX",
		"sounds": [], "volume_db": -6.0, "pitch_jitter": 0.04, "cooldown": 0.2,
	},
	"promise_made": {
		"label": "Дать обещание", "tier": 2, "bus": "SFX",
		"sounds": [], "volume_db": -6.0, "pitch_jitter": 0.02, "cooldown": 0.3,
	},
	"week_start": {
		"label": "Начать неделю", "tier": 2, "bus": "SFX",
		"sounds": [], "volume_db": -6.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"request_plea": {
		"label": "Новая просьба", "tier": 3, "bus": "SFX",
		"sounds": [], "volume_db": -8.0, "pitch_jitter": 0.05, "cooldown": 0.5,
	},
	"request_conflict": {
		"label": "Новый конфликт", "tier": 3, "bus": "SFX",
		"sounds": [], "volume_db": -8.0, "pitch_jitter": 0.05, "cooldown": 0.5,
	},
	"request_offer": {
		"label": "Новое предложение", "tier": 3, "bus": "SFX",
		"sounds": [], "volume_db": -8.0, "pitch_jitter": 0.05, "cooldown": 0.5,
	},
	"request_crisis": {
		"label": "Кризис", "tier": 3, "bus": "SFX",
		"sounds": [], "volume_db": -3.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"promise_kept": {
		"label": "Обещание сдержано", "tier": 3, "bus": "SFX",
		"sounds": [], "volume_db": -6.0, "pitch_jitter": 0.0, "cooldown": 0.5,
	},
	"promise_broken": {
		"label": "Обещание нарушено", "tier": 3, "bus": "SFX",
		"sounds": [], "volume_db": -4.0, "pitch_jitter": 0.0, "cooldown": 0.5,
	},
	"picket_start": {
		"label": "Начался пикет", "tier": 3, "bus": "SFX",
		"sounds": [], "volume_db": -6.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"week_end": {
		"label": "Итоги недели", "tier": 4, "bus": "SFX",
		"sounds": [], "volume_db": -3.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"week_two_morning": {
		"label": "Утро понедельника", "tier": 4, "bus": "SFX",
		"sounds": [], "volume_db": -3.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
}
