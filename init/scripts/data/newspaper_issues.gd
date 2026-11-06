# Authored headline-led weekly editions. Only public completed-week facts enter print.
extends RefCounted

const ISSUES := {
	1: {
		"issue": "№ 34 (218)", "print_date": "25 АВГУСТА 1997 ГОДА",
		"lead": "ШКОЛЫ ГОТОВЯТСЯ\nК ПЕРВОМУ СЕНТЯБРЯ",
		"deck": "До начала учебного года осталась неделя",
		"side": "КОТЕЛЬНЫЕ\nЖДУТ РЕМОНТА",
		"side_deck": "Подготовку к зиме обсудят\nв районной администрации",
		"world": "ПЕРЕВОЗЧИКИ ОБСУЖДАЮТ\nТРАНЗИТНЫЕ СБОРЫ",
		"city": "ДОМ КУЛЬТУРЫ\nОБЪЯВЛЯЕТ НАБОР",
		"classifieds": ["▪ КУПЛЮ ШКОЛЬНЫЕ УЧЕБНИКИ", "▪ МЕНЯЮ ЯБЛОКИ НА КАРТОФЕЛЬ"],
	},
	2: {
		"issue": "№ 35 (219)", "print_date": "1 СЕНТЯБРЯ 1997 ГОДА",
		"lead": "В ГОРОДСКИХ ШКОЛАХ\nНАЧАЛСЯ УЧЕБНЫЙ ГОД",
		"deck": "После летнего ремонта школы приняли учеников",
		"side": "КОТЕЛЬНЫЕ\nЖДУТ РЕМОНТА",
		"side_deck": "Подготовка к отопительному\nсезону продолжается",
		"world": "ПЕРЕГОВОРЫ О ТРАНЗИТЕ\nПРОДОЛЖАТСЯ НА НЕДЕЛЕ",
		"city": "ДОМ № 5\nЖДЁТ ГОРЯЧУЮ ВОДУ",
		"classifieds": ["▪ ПРОДАМ ШКОЛЬНУЮ ФОРМУ", "▪ КУПЛЮ КАРТОФЕЛЬ С ДОСТАВКОЙ"],
	},
}

static func build(week: int, history: Dictionary) -> Dictionary:
	if not ISSUES.has(week):
		return {}
	var edition: Dictionary = ISSUES[week].duplicate(true)
	var facts: Dictionary = history.get(week - 1, {})
	if week == 2:
		if facts.get("water_restored", false):
			edition["city"] = "В ДОМ № 5\nВЕРНУЛИ ГОРЯЧУЮ ВОДУ"
		elif facts.get("picket", false):
			edition["city"] = "ЖИЛЬЦЫ ДОМА № 5\nВЫШЛИ НА ПИКЕТ"
		if facts.get("boiler_repairs", false):
			edition["side"] = "В КОТЕЛЬНОЙ\nНАЧАЛСЯ РЕМОНТ"
			edition["side_deck"] = "На площадке появились\nлеса и ограждение"
		if facts.get("coal_loss", false):
			edition["classifieds"][0] = "ХРОНИКА: СО СКЛАДА ПРОПАЛ УГОЛЬ"
	edition["photo_region"] = Rect2(342, 432, 683, 205)
	edition["advert"] = {"title": "РЕМОНТ\nТЕЛЕВИЗОРОВ\nИ ВИДЕОМАГНИТОФОНОВ", "contact": "Вызов мастера на дом   Тел. 24-18-06"}
	edition["style"] = "newspaper"
	edition["week"] = week
	return edition
