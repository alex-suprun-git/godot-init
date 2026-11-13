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
# "sounds" lists one-shot recordings. Multiple entries are played in variation.
extends RefCounted

const BUSES := ["Music", "SFX", "Ambience", "UI"]
const FEEDBACK := "res://assets/audio/feedback/"

# Events per minute above which an event of that tier is flagged as tiring.
const MAX_PER_MINUTE := {1: 8.0, 2: 4.0, 3: 3.0, 4: 1.0}

const EVENTS := {
	"ui_click": {
		"label": "Нажатие кнопки или вкладки", "tier": 1, "bus": "UI",
		"sounds": [FEEDBACK + "soft_click_1.wav", FEEDBACK + "soft_click_2.wav", FEEDBACK + "soft_click_3.wav"], "volume_db": -10.0, "pitch_jitter": 0.03, "cooldown": 0.1,
	},
	"folder_open": {
		"label": "Открыть рабочую папку", "tier": 1, "bus": "UI",
		"sounds": [FEEDBACK + "folder.wav"], "volume_db": -8.0, "pitch_jitter": 0.03, "cooldown": 0.2,
	},
	"contacts_open": {
		"label": "Открыть картотеку связей", "tier": 1, "bus": "UI",
		"sounds": [FEEDBACK + "card_drawer.wav"], "volume_db": -11.0, "pitch_jitter": 0.03, "cooldown": 0.2,
	},
	"newspaper_rustle": {
		"label": "Открыть или закрыть газету", "tier": 1, "bus": "UI",
		"sounds": [FEEDBACK + "newspaper_rustle.wav"], "volume_db": -12.0, "pitch_jitter": 0.0, "cooldown": 0.0,
	},
	"paperwork_start": {
		"label": "Начать работу с документами", "tier": 2, "bus": "SFX",
		"sounds": [FEEDBACK + "typewriter.wav"], "volume_db": -10.0, "pitch_jitter": 0.0, "cooldown": 0.5,
	},
	"money_changed": {
		"label": "Получить или потратить деньги", "tier": 2, "bus": "SFX",
		"sounds": [FEEDBACK + "banknotes.wav", FEEDBACK + "coins.wav"], "volume_db": -11.0, "pitch_jitter": 0.0, "cooldown": 0.3,
	},
	"card_open": {
		"label": "Открыть карточку запроса", "tier": 1, "bus": "UI",
		"sounds": [FEEDBACK + "paper_page.wav"], "volume_db": -14.0, "pitch_jitter": 0.06, "cooldown": 0.1,
	},
	"card_close": {
		"label": "Закрыть карточку", "tier": 1, "bus": "UI",
		"sounds": [FEEDBACK + "pen_tap.wav"], "volume_db": -11.0, "pitch_jitter": 0.06, "cooldown": 0.1,
	},
	"speed_click": {
		"label": "Кнопки скорости", "tier": 1, "bus": "UI",
		"sounds": [FEEDBACK + "rubber_click_1.wav", FEEDBACK + "rubber_click_2.wav", FEEDBACK + "rubber_click_3.wav"], "volume_db": -16.0, "pitch_jitter": 0.04, "cooldown": 0.1,
	},
	"option_choose": {
		"label": "Подтвердить выбор (отправить)", "tier": 2, "bus": "SFX",
		"sounds": [FEEDBACK + "office_stamp.wav"], "volume_db": -6.0, "pitch_jitter": 0.04, "cooldown": 0.2,
	},
	"promise_made": {
		"label": "Дать обещание", "tier": 2, "bus": "SFX",
		"sounds": [FEEDBACK + "pen_write.wav"], "volume_db": -6.0, "pitch_jitter": 0.02, "cooldown": 0.3,
	},
	"week_start": {
		"label": "Начать неделю", "tier": 2, "bus": "SFX",
		"sounds": [FEEDBACK + "folder.wav"], "volume_db": -6.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"request_plea": {
		"label": "Новая просьба", "tier": 3, "bus": "SFX",
		"sounds": [FEEDBACK + "door_knock.wav"], "volume_db": -10.0, "pitch_jitter": 0.05, "cooldown": 0.5,
	},
	"request_conflict": {
		"label": "Новый конфликт", "tier": 3, "bus": "SFX",
		"sounds": [FEEDBACK + "desk_phone.wav"], "volume_db": -8.0, "pitch_jitter": 0.05, "cooldown": 0.5,
	},
	"request_offer": {
		"label": "Новое предложение", "tier": 3, "bus": "SFX",
		"sounds": [FEEDBACK + "paper_page.wav"], "volume_db": -8.0, "pitch_jitter": 0.05, "cooldown": 0.5,
	},
	"request_crisis": {
		"label": "Кризис", "tier": 3, "bus": "SFX",
		"sounds": [FEEDBACK + "alarm.wav"], "volume_db": -5.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"promise_kept": {
		"label": "Обещание сдержано", "tier": 3, "bus": "SFX",
		"sounds": [FEEDBACK + "office_stamp.wav"], "volume_db": -6.0, "pitch_jitter": 0.0, "cooldown": 0.5,
	},
	"promise_broken": {
		"label": "Обещание нарушено", "tier": 3, "bus": "SFX",
		"sounds": [FEEDBACK + "desk_phone.wav"], "volume_db": -4.0, "pitch_jitter": 0.0, "cooldown": 0.5,
	},
	"picket_start": {
		"label": "Начался пикет", "tier": 3, "bus": "SFX",
		"sounds": [FEEDBACK + "door_knock.wav"], "volume_db": -7.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"week_end": {
		"label": "Итоги недели", "tier": 4, "bus": "SFX",
		"sounds": [FEEDBACK + "folder.wav"], "volume_db": -3.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
	"week_two_morning": {
		"label": "Утро понедельника", "tier": 4, "bus": "SFX",
		"sounds": [FEEDBACK + "newspaper.wav"], "volume_db": -11.0, "pitch_jitter": 0.0, "cooldown": 1.0,
	},
}
