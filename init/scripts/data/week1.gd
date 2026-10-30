# Content for the first playable week (heating-season opening, late August 1997).
# Pure data: the simulation reads it, nothing here runs logic.
# Player-facing text is Russian; it moves to Godot's translation system later.
extends RefCounted

const YEAR := 1997
const MONTH := 8
const FIRST_DAY := 25 # Monday, 25 August 1997
const DAY_NAMES := ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
const WORK_START_HOUR := 8
const HOURS_PER_DAY := 12 # Working day 08:00–20:00; nights and the weekend are skipped.
const DAYS_PER_WEEK := 5

const START_MONEY := 1_200_000

# Hidden values; the player only sees words.
const FACTIONS := {
	"residents": {"name": "Жители", "value": -10},
	"business": {"name": "Бизнес", "value": 0},
	"police": {"name": "Милиция", "value": 0},
	"church": {"name": "Церковь", "value": -5},
	"boss": {"name": "Босс", "value": 10},
}

# Map positions are on the ground plane (x, z) in map units, matching the
# schematic in art/concepts/district_layout.svg (1 SVG px = 0.25 units).
const LOTS := {
	"office": {"name": "Администрация района", "pos": Vector2(66, -30)},
	"block5": {"name": "Дом 5", "pos": Vector2(-100, -22)},
	"boiler": {"name": "Котельная №3", "pos": Vector2(-185, -19)},
	"depot": {"name": "Склад топлива", "pos": Vector2(125, -62)},
	"church": {"name": "Церковь", "pos": Vector2(115, 17)},
	"market": {"name": "Рынок у вокзала", "pos": Vector2(-27, 81)},
	"wasteland": {"name": "Пустырь", "pos": Vector2(-125, 85)},
}

# speed: map units per game hour. Office to the boiler house is about two hours
# on foot and well under an hour with Tolik's car.
const ACTORS := {
	"me": {
		"name": "Вы", "role": "Помощник главы района", "start_lot": "office", "speed": 120.0,
		"portrait": "res://assets/portraits/protagonist.png", "face": Rect2(375, 176, 1237, 1237),
	},
	"mikhalych": {
		"name": "Михалыч", "role": "Слесарь ЖЭКа", "start_lot": "office", "speed": 100.0,
		"portrait": "res://assets/portraits/mikhalych.png", "face": Rect2(362, 229, 580, 580),
	},
	"nina": {
		"name": "Баба Нина", "role": "Старшая по дому 5", "start_lot": "block5", "speed": 70.0,
		"portrait": "res://assets/portraits/baba_nina.png", "face": Rect2(370, 140, 540, 540),
	},
	"tolik": {
		"name": "Толик", "role": "Водитель администрации", "start_lot": "office", "speed": 400.0,
		"portrait": "res://assets/portraits/tolik.png", "face": Rect2(266, 180, 555, 555),
	},
}

const BOSS := {
	"name": "Пётр Петрович", "role": "Глава района",
	"portrait": "res://assets/portraits/boss.png", "face": Rect2(330, 160, 540, 540),
}

# Important notices use a small set of visual formats (a character portrait or
# a newspaper clipping) and lead into the weekly task board.
const START_BRIEFING := {
	"style": "portrait", "speaker": "boss",
	"eyebrow": "ПОРУЧЕНИЕ БОССА",
	"title": "Отопительный сезон к 15 октября",
	"body": "К 15 октября район должен быть готов к проверке городской комиссии. Провал не обсуждается.",
	"button": "К поручениям",
}

const WEEKLY_MANDATE := {
	"title": "Подготовить район к отопительному сезону",
	"deadline": "15 октября",
	"description": "Городская комиссия проверит район. Босс ждёт результата.",
}

# Optional press item, opened from the map's incoming tray. It reports the
# existing hot-water request and does not change simulation state.
const MORNING_NEWS := {
	"style": "newspaper", "masthead": "Городские вести",
	"eyebrow": "НЕЗАВИСИМАЯ ГОРОДСКАЯ ГАЗЕТА",
	"issue": "№ 34 (218)", "section": "ГОРОДСКОЕ ХОЗЯЙСТВО",
	"title": "Воду отключили. Объяснений пока нет.",
	"lead": "Жители дома №5 четвёртый день греют воду в кастрюлях.",
	"body": "По словам жильцов, это уже третье отключение за год. Когда закончится ремонт, в ЖЭКе пока не говорят.\n\nВ администрации района обещали разобраться в ситуации.",
	"quote": "«Зима ещё не началась, а мы уже с тазиками»",
	"quote_author": "Нина Ивановна, старшая по дому №5",
	"illustration": "res://assets/portraits/baba_nina.png",
	"illustration_region": Rect2(110, 35, 900, 760),
	"caption": "Нина Ивановна. Горячей воды в доме нет с четверга.",
	"button": "Отложить газету →",
}

# The boss's order for the week. An objective is met when its flag is set and
# failed when the request with the same id closes without it.
const OBJECTIVES := [
	{"id": "contractor", "title": "Выбрать подрядчика для котельной", "deadline": "До четверга", "lot": "boiler", "flag": "contractor"},
	{"id": "boss_report", "title": "Явиться к боссу на отчёт", "deadline": "Пятница", "lot": "office", "flag": "report"},
]

# Request types: plea, conflict, crisis, offer.
# Times are {day, hour} within the week; day 0 is Monday.
# Option fields:
#   actor: who goes ("me", a contact id, "phone", or "promise").
#   hours: work time on site after arriving.
#   chance: success probability (default 1.0).
#   success / fail: effects (faction deltas, money, trace, flags, next_week, overlay, log).
#   keeps_open: the request stays open after this option (used by promises).
const REQUESTS := [
	{
		"id": "hot_water", "type": "plea", "lot": "block5", "asker": "nina",
		"title": "Нет горячей воды с четверга",
		"text": "Баба Нина от имени подъезда: «Третий раз за год, а год ещё молодой».",
		"appear": {"day": 0, "hour": 8}, "expire": {"day": 4, "hour": 20},
		"expire_effects": {"residents": -10, "log": "Горячую воду в доме 5 так и не дали. Подъезд сделал выводы."},
		"options": [
			{
				"id": "send_mikhalych", "actor": "mikhalych", "hours": 5, "chance": 0.7,
				"label": "Отправить Михалыча",
				"hint": "Починит. Жители будут довольны. Может не дойти: выпивает.",
				"success": {"residents": 15, "flags": {"hot_water": true}, "log": "Михалыч починил трубу. В доме 5 горячая вода."},
				"fail": {"residents": -5, "reopen": true, "log": "Михалыч не дошёл до дома 5. Говорят, встретил кума."},
			},
			{
				"id": "go_myself", "actor": "me", "hours": 3,
				"label": "Поехать самому",
				"hint": "Жители оценят, что пришли лично. Трубу это не починит.",
				"success": {"residents": 8, "log": "Вы выслушали весь подъезд. Воды нет, но злятся меньше."},
			},
			{
				"id": "promise", "actor": "promise", "keeps_open": true,
				"label": "Пообещать воду к пятнице",
				"hint": "Бесплатно сейчас. Нарушить обещание хуже, чем отказать.",
				"promise": {
					"text": "Горячая вода в доме 5 к пятнице",
					"due": {"day": 4, "hour": 18}, "flag": "hot_water",
					"made": {"residents": 8, "log": "Вы пообещали подъезду горячую воду к пятнице."},
					"kept": {"residents": 12, "log": "Обещание сдержано: в доме 5 горячая вода. Об этом говорят во дворе."},
					"broken": {"residents": -25, "overlay": {"lot": "block5", "name": "picket"}, "log": "Обещание нарушено. У дома 5 пикет: «Вы обещали!»"},
				},
			},
		],
	},
	{
		"id": "contractor", "type": "conflict", "lot": "boiler", "asker": "",
		"title": "Два подрядчика на одну котельную",
		"text": "Гусев и «Стройремонт» оба уверены, что ремонт котельной — их. Решать вам, на месте.",
		"appear": {"day": 0, "hour": 8}, "expire": {"day": 3, "hour": 20},
		"expire_effects": {"boss": -20, "log": "Подрядчика так и не выбрали. Котельная стоит, Пётр Петрович мрачнеет."},
		"options": [
			{
				"id": "pick_gusev", "actor": "me", "hours": 3,
				"label": "Поддержать Гусева",
				"hint": "Бизнес будет доволен, босс тоже. «Стройремонт» — нет.",
				"success": {"business": 15, "boss": 5, "flags": {"contractor": "gusev"}, "next_week": {"boiler": "repairing"}, "log": "Ремонт котельной отдан Гусеву. Прораб «Стройремонта» долго смотрел вам вслед."},
			},
			{
				"id": "pick_stroyremont", "actor": "me", "hours": 3,
				"label": "Поддержать «Стройремонт»",
				"hint": "Гусев обидится. У «Стройремонта» какие-то серьёзные друзья.",
				"success": {"business": -5, "police": 5, "flags": {"contractor": "stroyremont"}, "next_week": {"boiler": "repairing"}, "log": "Ремонт котельной отдан «Стройремонту». Прораб пожал руку слишком крепко."},
			},
		],
	},
	{
		"id": "envelope", "type": "offer", "lot": "office", "asker": "",
		"title": "Посетитель с конвертом",
		"text": "Гусев кладёт на стол толстый конверт: «Это просто за понимание. С Петровичем всё согласовано».",
		"appear": {"day": 0, "hour": 10}, "expire": {"day": 2, "hour": 20},
		"expire_effects": {"business": -5, "log": "Гусев забрал конверт и ушёл, не прощаясь."},
		"options": [
			{
				"id": "take", "actor": "me", "hours": 1,
				"label": "Взять конверт",
				"hint": "Деньги сейчас. Кто-то это видел.",
				"success": {"money": 1_500_000, "business": 10, "trace": 1, "flags": {"envelope": true}, "log": "Конверт в ящике стола. Толик видел, как Гусев выходил довольным."},
			},
			{
				"id": "refuse", "actor": "me", "hours": 1,
				"label": "Отказаться",
				"hint": "Бизнес будет недоволен. Чистые руки.",
				"success": {"business": -10, "log": "Вы вернули конверт. Гусев улыбнулся, но глаза не улыбались."},
			},
		],
	},
	{
		"id": "church_heat", "type": "plea", "lot": "church", "asker": "",
		"title": "Протопить храм к зиме",
		"text": "Отец Георгий просит включить храм в график отопления: «Прихожане молятся в пальто».",
		"appear": {"day": 1, "hour": 9}, "expire": {"day": 4, "hour": 20},
		"expire_effects": {"church": -5, "log": "Отец Георгий так и не дождался ответа."},
		"options": [
			{
				"id": "go_myself", "actor": "me", "hours": 4,
				"label": "Поехать самому",
				"hint": "Церковь оценит личный визит. Полдня уйдёт.",
				"success": {"church": 15, "log": "Вы пили чай с отцом Георгием. Храм в списке на отопление."},
			},
			{
				"id": "send_nina", "actor": "nina", "hours": 3,
				"label": "Попросить бабу Нину",
				"hint": "Она прихожанка. Церковь будет довольна, но меньше.",
				"success": {"church": 8, "residents": 3, "log": "Баба Нина договорилась с отцом Георгием. Заодно рассказала ему про вас."},
			},
		],
	},
	{
		"id": "coal_theft", "type": "crisis", "lot": "boiler", "asker": "",
		"title": "С котельной вывозят уголь",
		"text": "Сторож пьян, у ворот грузовик без номеров, грузят уголь. Если не вмешаться — к зиме котельная без топлива.",
		"appear": {"day": 3, "hour": 10}, "expire": {"day": 3, "hour": 14},
		"overlay": {"lot": "boiler", "name": "truck"},
		"expire_effects": {"boss": -10, "residents": -10, "flags": {"coal_stolen": true}, "log": "Уголь увезли. Сторож проснулся и ничего не помнит."},
		"options": [
			{
				"id": "go_myself", "actor": "me", "hours": 1,
				"label": "Поехать самому",
				"hint": "Грузовик уедет, если вы приедете лично. Рискованно.",
				"success": {"residents": 5, "log": "Вы приехали — грузовик уехал пустым. Номера вы всё-таки запомнили."},
			},
			{
				"id": "send_mikhalych", "actor": "mikhalych", "hours": 1, "chance": 0.6,
				"label": "Отправить Михалыча",
				"hint": "Он знает сторожа. Может договориться, а может присоединиться.",
				"success": {"residents": 5, "log": "Михалыч разбудил сторожа и наорал на грузчиков. Уголь остался."},
				"fail": {"residents": -5, "flags": {"coal_stolen": true}, "log": "Михалыч помог грузить. Говорит, думал, что это вывоз по графику."},
			},
			{
				"id": "phone_police", "actor": "phone",
				"label": "Позвонить в милицию",
				"hint": "Только из кабинета. Милиция приедет, когда приедет.",
				"success": {"police": 5, "residents": -5, "flags": {"coal_stolen": true}, "log": "Наряд приехал через три часа и составил протокол на пустую площадку."},
			},
		],
	},
	{
		"id": "wasteland_stalls", "type": "offer", "lot": "wasteland", "asker": "",
		"title": "Гусев хочет ларьки на пустыре",
		"text": "«Всё равно там одни берёзы и бутылки. Я даже забор поставлю». Нужно решить на месте.",
		"appear": {"day": 1, "hour": 14}, "expire": {"day": 3, "hour": 20},
		"expire_effects": {"business": -4, "log": "Гусев не дождался ответа и поставил ларьки сам. Никто не заметил, как."},
		"options": [
			{
				"id": "allow", "actor": "me", "hours": 2,
				"label": "Разрешить ларьки",
				"hint": "Деньги и бизнес довольны. Жители не любят ларьки у дома.",
				"success": {"money": 500_000, "business": 8, "residents": -5, "trace": 1, "log": "Вы разрешили ларьки на пустыре. Берёзы остались, пока."},
			},
			{
				"id": "deny", "actor": "me", "hours": 2,
				"label": "Отказать",
				"hint": "Жители оценят. Бизнес запомнит.",
				"success": {"business": -5, "residents": 4, "log": "Вы отказали Гусеву. Он поблагодарил так, что слышно было в соседнем районе."},
			},
		],
	},
	{
		"id": "market_cops", "type": "conflict", "lot": "market", "asker": "",
		"title": "Ларёчники и милиция делят рынок",
		"text": "Участковый хочет «порядка», торговцы хотят торговать. Обе стороны ждут вас у вокзала.",
		"appear": {"day": 2, "hour": 9}, "expire": {"day": 4, "hour": 12},
		"expire_effects": {"police": -4, "business": -4, "log": "Рынок разобрался сам. Участковый ходит довольный, торговцы нет."},
		"options": [
			{
				"id": "go_myself", "actor": "me", "hours": 3,
				"label": "Поехать самому",
				"hint": "Обе стороны выслушаны. Никто не уйдёт полностью довольным.",
				"success": {"police": -3, "business": 8, "log": "Вы развели милицию и торговцев по углам рынка. Обе стороны остались при своём."},
			},
			{
				"id": "send_tolik", "actor": "tolik", "hours": 2, "chance": 0.6,
				"label": "Отправить Толика",
				"hint": "Он знает, с кем и как говорить. Но не всегда успевает.",
				"success": {"police": 6, "business": -3, "log": "Толик пошептался с участковым, торговцы заплатили. Порядок восстановлен."},
				"fail": {"police": -4, "business": -6, "log": "Толик пообещал лишнего обеим сторонам. Рынок гудит."},
			},
		],
	},
	{
		"id": "fuel_offer", "type": "offer", "lot": "depot", "asker": "",
		"title": "Кладовщик предлагает мазут «мимо кассы»",
		"text": "«Часть пойдёт на котельную, часть никто не считал. Вы же хотите, чтобы зимой было тепло».",
		"appear": {"day": 2, "hour": 13}, "expire": {"day": 4, "hour": 10},
		"expire_effects": {"business": -2, "log": "Кладовщик пожал плечами и продал мазут кому-то другому."},
		"options": [
			{
				"id": "take", "actor": "me", "hours": 2,
				"label": "Взять мазут и деньги",
				"hint": "Котельной хватит топлива. Следов больше.",
				"success": {"money": 800_000, "business": 5, "police": -3, "trace": 1, "flags": {"fuel_off_books": true}, "log": "Мазут отгрузили без накладных. Кладовщик сказал, что вы понятливый."},
			},
			{
				"id": "refuse", "actor": "me", "hours": 2,
				"label": "Отказаться",
				"hint": "Чисто, но тепла может не хватить.",
				"success": {"business": -4, "residents": 3, "log": "Вы отказались от левого мазута. Кладовщик буркнул, что чистоплюи зимой мёрзнут."},
			},
		],
	},
	{
		"id": "residents_meeting", "type": "plea", "lot": "block5", "asker": "nina",
		"title": "Жильцы просят собрание",
		"text": "Баба Нина: «Пусть кто-нибудь придёт и скажет людям, что будет. Мы же не слепые».",
		"appear": {"day": 3, "hour": 8}, "expire": {"day": 4, "hour": 20},
		"expire_effects": {"residents": -6, "log": "Собрание в доме 5 прошло без вас. Баба Нина записала всё, что вы не сказали."},
		"options": [
			{
				"id": "send_nina", "actor": "nina", "hours": 2,
				"label": "Попросить бабу Нину",
				"hint": "Она соберёт людей и скажет, как есть. Но от вашего имени.",
				"success": {"residents": 8, "log": "Баба Нина провела собрание и записала в тетрадь, кто что сказал."},
			},
			{
				"id": "go_myself", "actor": "me", "hours": 3,
				"label": "Поехать самому",
				"hint": "Люди увидят, что вы приехали. Вы потеряете полдня.",
				"success": {"residents": 12, "log": "Вы пришли на собрание сами. Люди запомнили, кто пришёл."},
			},
		],
	},
	{
		"id": "journalist", "type": "plea", "lot": "office", "asker": "",
		"title": "Журналистка просит комментарий",
		"text": "Звонок из районной газеты: «Что с горячей водой в доме 5? Люди интересуются».",
		"appear": {"day": 4, "hour": 9}, "expire": {"day": 4, "hour": 15},
		"expire_effects": {"residents": -3, "boss": -3, "log": "В газету ушло «от власти не поступило комментариев». Читать будут все."},
		"options": [
			{
				"id": "talk", "actor": "me", "hours": 1,
				"label": "Дать комментарий лично",
				"hint": "Вы в кабинете, час времени. Босс не любит, когда говорят без него.",
				"success": {"residents": 6, "boss": -3, "log": "Вы дали комментарий. Пётр Петрович читал газету и молчал."},
			},
			{
				"id": "phone", "actor": "phone",
				"label": "Ответить по телефону",
				"hint": "Только из кабинета. Коротко, но без возможности объяснить.",
				"success": {"residents": 2, "log": "Вы коротко ответили журналистке. Ничего особенного не сказали."},
			},
		],
	},
	{
		"id": "boss_report", "type": "crisis", "lot": "office", "asker": "",
		"title": "Босс вызывает на ковёр",
		"text": "Пётр Петрович: «Через четыре часа в мэрии отчёт. Приходите и расскажите, что сделали».",
		"appear": {"day": 4, "hour": 12}, "expire": {"day": 4, "hour": 16},
		"expire_effects": {"boss": -15, "log": "Вы не пришли на отчёт. Пётр Петрович отчитывался за вас сам и это запомнит."},
		"options": [
			{
				"id": "go_boss", "actor": "me", "hours": 1,
				"label": "Пойти к боссу лично",
				"hint": "Вы в кабинете, час времени. Отчёт засчитан.",
				"success": {"boss": 10, "flags": {"report": true}, "log": "Отчёт принят. Пётр Петрович кивнул и попросил «не шуметь»."},
			},
			{
				"id": "phone_excuse", "actor": "phone",
				"label": "Позвонить и сослаться на дела",
				"hint": "Только из кабинета. Босс отчёт не примет и обидится.",
				"success": {"boss": -8, "log": "Вы сослались на дела. Пётр Петрович отчёт не принял и положил трубку."},
			},
		],
	},
]

# Faction words, from worst to best.
const STANDING_WORDS := [
	{"max": -40, "word": "Вражда"},
	{"max": -15, "word": "Недовольство"},
	{"max": 5, "word": "Недоверие"},
	{"max": 25, "word": "Расположение"},
	{"max": 1000, "word": "Лояльность"},
]
