# Monday, part 1: arrival (draft v1)

Monday 25 August 1997, 06:00 to about 10:00. Narration only, no mechanics taught. Tone: dry and observant, one small joke per stop. The protagonist's name and biography are not fixed, so no line may depend on them.

**Tolik's voice (v1):** cheerful, talkative, warm, a gossip who loves his car and his district. Long, flowing sentences and jokes, often at his own expense. The tone break at the restaurant is the point of the whole sequence: he stops mid-word, the radio goes off, and for the rest of the drive his cheer is slightly too loud.

## Interface during this part

> Progressive interface (see the root README): on the train there is no interface at all, only the newspaper. During Tolik's drive the screen shows a read-only clock and date strip and the captions, and nothing else: no buttons, no wallet, no contacts, no folder, no map controls, no restart. The first control to appear is the work folder, after the boss's briefing (see `mon-2-boss-and-block5.md`).

## Scene 0.1. The train

> The player reads the opening edition of the paper on the train; it is the same headline-led sheet as the in-game newspaper, shown full screen before the map appears. Edition data is in `init/scripts/data/newspaper_issues.gd`, issue 1. Proposed text changes are listed at the end of this file.

[Электричка, 05:40]

*Первая электричка. В вагоне трое и газета, которую кто-то оставил на сиденье.*

*Читать больше нечего. Читаете всё, вплоть до объявлений.*

*(newspaper opens; closing it ends the scene)*

*За окном закончились поля и начались трубы. Значит, приехали.*

## Scene 0.2. The station square

[Вокзальная площадь, 06:00]

> Hand-off: Tolik's car (the administration Volga) is already at the kerb. The camera starts on the player's arrival and then follows the car for the whole drive. If a car-radio loop is available, it plays quietly from here and cuts out at the restaurant; otherwise ambience is enough.

ТОЛИК: О, живой! А я думал, опять не приедет никто. Вы новенький, помощник? Толик я, водитель, и вообще человек, которому всё известно и никто не верит.

ТОЛИК: Сумку в багажник, багажник у нас широкий, и не такое возил. Садитесь, садитесь, Волга чистая, сам утром мыл. Ну, насколько вода позволила.

ТОЛИК: Петр Петрович раньше десяти не появится, так что у нас с вами два часа и полбака. Покатаю вас по району, чтобы потом не спрашивали «а где это», а сразу знали, куда не ходить.

*Волга пахнет бензином и чужими сигаретами. Толик ведёт одной рукой, а второй показывает во все стороны сразу.*

## Stops

> Each stop: the camera holds on the place for a few seconds, the caption names it, and one or two lines play. Route, as the user described it: station, left past the dormitory, the highway, the industrial zone, the border, the turn at the restaurant, the village loop, the avenue, the executive committee. Lot ids are for Codex to map; the restaurant lot has no id yet.

> Timing (decided): the drive is an in-game cutscene and the game clock keeps running, but slowed so that two game hours (06:00 to 08:00) take about 60 to 90 real seconds, which is roughly nine times slower than the normal rate of 4 real seconds per game hour. The player arrives at the executive committee at 08:00, on time. The clock is keyed to the stops and interpolates between them (proposed values below), so the pacing stays under authorial control. Skippable on replay, not on the first play (default; the user has not said otherwise).

| Stop | Clock |
|---|---|
| Station and market | 06:00 |
| Dormitory | 06:20 |
| Highway and industrial zone | 06:45 |
| Border | 07:10 |
| Restaurant | 07:30 |
| Village | 07:45 |
| Executive committee | 08:00 |

### Stop 1. Station and market

[Вокзал и рынок]

ТОЛИК: Вокзал! Рядом рынок, весь район тут кормится. Продают всё: одежду, магнитофоны, обещания. Обещания, правда, дороже.

ТОЛИК: Кошелёк держите поближе. Он тут быстро находит нового хозяина.

### Stop 2. The dormitory

[Общежитие]

ТОЛИК: А вот ваше общежитие! Видите, угол буквой «Г»? Это не замысел, это строили по остаткам плана. Комната на троих, соседи душевные. Один храпит, зато трубы не слышно: он их перекрикивает.

*Четыре этажа, бельё на верёвках. Из окна кто-то машет Толику. Толик машет в ответ, не глядя на дорогу.*

### Stop 3. Highway and the industrial zone

[Шоссе вдоль реки]

ТОЛИК: Шоссе! Вон АТП, вон порт, вон склад с мазутом. Сколько из него утекает и сколько записано, это две разные цифры, и обе уверенные.

ТОЛИК: А вон труба, третья от края, это котельная. К зиме её чинят уже третий год. Она у нас как старый друг: ремонту не поддаётся, а без неё холодно.

ТОЛИК: Если что с отоплением, спрашивайте Михалыча. Слесарь, золотые руки! Когда на месте. А когда не на месте, вы не расстраивайтесь, он найдётся.

### Stop 4. The border

[Граница]

ТОЛИК: А это граница! Нам дальше нельзя, дальше только с паспортом и душой наизнанку. Очередь двое суток, дальнобойщики друг друга в лицо знают. Скоро женятся, я так думаю.

ТОЛИК: Будку у шлагбаума в июле меняли. Старая, говорят, не выдержала.

*Фуры стоят в два ряда. Водители спят на подножках. Краска на новой будке свежее, чем на всём вокруг.*

### Stop 5. The restaurant

[Ресторан за исполкомом]

> The tone break. No caption names the place. Tolik is mid-story, so the line must cut off. The radio, if any, stops. Hold the shot a beat longer than the others, with almost no sound. The player should notice the change without being told what it means.

ТОЛИК: ...и вот я ему говорю: батя, ты же в этом ничего не пон...

*Высокий кирпичный забор. Охрана у ворот. Толик замолчал на полуслове и выключил радио, не глядя.*

*Волга поехала медленнее.*

ТОЛИК: Тут обедают.

*Он не сказал, кто. Целую минуту никто ничего не говорил.*

### Stop 6. The old village

[Старая деревня]

> Tolik recovers, but too loudly. The player should hear that he is making an effort.

ТОЛИК: Ну-с! Деревня!

*Он сам услышал, что вышло слишком бодро, и добавил тише:*

ТОЛИК: Раньше колхоз, потом огороды, теперь кладбище, церковь и несколько упрямых стариков. Батюшка у нас Георгий, к нему лучше с чаем. Чай у него настоящий, не то что в исполкоме.

*Круг по деревне: грунтовка, заборы, куры. Толик объезжает лужи с уважением.*

### Stop 7. The avenue and the executive committee

[Проспект, исполком]

ТОЛИК: Исполком! Строили вместе с районом, крепкая коробка, переживёт и нас, и всех, кто потом будет. Лифт, правда, давно не работает, зато на лестнице вас никто не догонит.

ТОЛИК: Второй этаж, дверь с табличкой. Дальше сами. Стучите громче, он плохо слышит, когда не хочет.

ТОЛИК: Ровно восемь. Вы вовремя. Редкость. Запомнят, и хорошее, и плохое. Ну, ни пуха!

*Толик уехал, на ходу включив радио. Громко.*

## Scene 0.3. At the door

[Приёмная исполкома, 08:00]

> The wait from 08:00 to 10:04 is a plain time skip (decided). No secretary character is introduced. The boss's entrance leads straight into the monologue in `mon-2-boss-and-block5.md`.

*Ровно восемь. Вы пришли вовремя. В здании это, кажется, заметили только часы.*

*Дверь с табличкой «Глава района». Закрыта.*

*Сидеть некуда, кроме стула у стены. Вы садитесь.*

[Время идёт]

[10:04]

*Послышались шаги, тяжёлые и без спешки. Ключ повернулся с первого раза.*

ПЁТР ПЕТРОВИЧ: Новый? Заходите. Дверь закройте. Разговор есть.

## Proposed changes to newspaper issue 1

> For the train edition. Fields follow `newspaper_issues.gd`. The `lead`, `side` and `world` items can stay. The changes plant the House of Culture meeting and the border without explaining them.

| Field | Current | Proposed |
|---|---|---|
| `city` | ДОМ КУЛЬТУРЫ ОБЪЯВЛЯЕТ НАБОР | В СРЕДУ В ДОМЕ КУЛЬТУРЫ — ВСТРЕЧА ЖИТЕЛЕЙ С АДМИНИСТРАЦИЕЙ |
| city deck | (none) | Начало в 19:00. Вопрос: безопасность на окраинах района |
| `classifieds[0]` | КУПЛЮ ШКОЛЬНЫЕ УЧЕБНИКИ | СДАЮ КОМНАТУ. ТОЛЬКО РАБОТАЮЩИМ |
| `classifieds[1]` | МЕНЯЮ ЯБЛОКИ НА КАРТОФЕЛЬ | (keep) |

## Open

- Whether the drive may be skipped on the first play (default: no).
