# Monday, part 1: arrival (draft v0)

Monday 25 August 1997, 06:00 to about 10:00. Narration only, no mechanics taught. Tone: dry, observant, one small dark joke per stop. The protagonist's name and biography are not fixed, so no line may depend on them.

## Scene 0.1. The train

> The player reads the opening edition of the paper on the train; it is the same headline-led sheet as the in-game newspaper, shown full screen before the map appears. Edition data is in `init/scripts/data/newspaper_issues.gd`, issue 1. Proposed text changes are listed at the end of this file.

[Электричка, 05:40]

*Первая электричка. В вагоне трое и газета, которую кто-то оставил на сиденье.*

*Читать больше нечего. Читаете всё, вплоть до объявлений.*

*(newspaper opens; closing it ends the scene)*

*За окном закончились поля и начались трубы. Значит, приехали.*

## Scene 0.2. The station square

[Вокзальная площадь, 06:00]

> Hand-off: Tolik's car (the administration Volga) is already at the kerb. The camera starts on the player's arrival and then follows the car for the whole drive. Skippable on replay.

ТОЛИК: Вы, что ли, новенький? Помощником к Петру Петровичу?

ТОЛИК: Толик. Велено встретить. Вещи в багажник, сумку не держите на коленях, у меня тормоза хорошие, но не такие.

ТОЛИК: Петр Петрович раньше десяти не будет. Так что я вас по кругу. Один раз увидеть лучше, чем потом искать.

*Волга пахнет бензином и чужими сигаретами. Толик ведёт одной рукой.*

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

ТОЛИК: Вокзал. Рядом рынок. Тут всё начинается и всё заканчивается. Товар, деньги, ссоры.

### Stop 2. The dormitory

[Общежитие]

ТОЛИК: Вам тут комнату дали. На троих. Соседи нормальные, один храпит.

*Четыре этажа, угол буквой «Г», бельё на верёвках. Выглядит не так плохо, как звучит.*

### Stop 3. Highway and the industrial zone

[Шоссе вдоль реки]

ТОЛИК: Вот АТП. Вот порт. Вон склад с мазутом. Сколько из него вытекает, а сколько записано, вам потом объяснят. Или не объяснят.

ТОЛИК: А труба вон та, третья, это котельная. К зиме её чинят уже третий год.

ТОЛИК: Если что с отоплением, спросите Михалыча. Слесарь. Золотые руки. Когда на месте.

### Stop 4. The border

[Граница]

ТОЛИК: Граница. Нам туда не надо. Им сюда надо. Очередь на двое суток, а сборы, говорят, поднимут.

ТОЛИК: Будку у шлагбаума в июле меняли. Старая, говорят, не выдержала.

*Фуры стоят в два ряда. Водители спят на подножках. Краска на новой будке свежее, чем на всём вокруг.*

### Stop 5. The restaurant

[Ресторан за исполкомом]

> Tolik slows down and stops talking. No caption names the place. The player should notice it without being told.

*Высокий кирпичный забор. Охранник у ворот. Толик сбавил скорость и замолчал.*

ТОЛИК: Тут обедают.

*Он не добавил, кто.*

### Stop 6. The old village

[Старая деревня]

ТОЛИК: Деревня. Раньше колхоз, потом огороды, теперь кладбище, церковь и несколько упрямых стариков. Батюшка у нас Георгий. К нему лучше с чаем.

*Круг по деревне: грунтовка, заборы, куры. Толик объезжает лужи с уважением.*

### Stop 7. The avenue and the executive committee

[Проспект, исполком]

ТОЛИК: Исполком. Строили вместе с районом, крепкая коробка. Лифт, правда, давно не работает.

ТОЛИК: Второй этаж, дверь с табличкой. Дальше сами.

ТОЛИК: Стучите громче. Он плохо слышит, когда не хочет.

ТОЛИК: Ровно восемь. Вы вовремя. Редкость.

*Толик уехал, не оглядываясь. Волга свернула за угол.*

## Scene 0.3. At the door

[Приёмная исполкома, 08:00]

> The wait from 08:00 to 10:04 is a short time skip with captions (proposal). No secretary character is introduced. The boss's entrance leads straight into the monologue in `mon-2-boss-and-block5.md`.

*Ровно восемь. Вы пришли вовремя. В здании это, кажется, заметили только часы.*

*Дверь с табличкой «Глава района». Закрыта.*

*Сидеть некуда, кроме стула у стены. Вы садитесь.*

[Время идёт]

*В девять пришла уборщица. В половине десятого позвонил телефон, и никто не взял.*

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

- Whether the wait at the door needs the cleaner and the phone, or a plain time skip.
- Whether the drive may be skipped on the first play (default: no).
