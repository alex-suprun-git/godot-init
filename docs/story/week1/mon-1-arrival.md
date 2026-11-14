# Monday, part 1: arrival (draft v2, rewritten in the new spoken register)

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

> Hand-off: The boss's official black foreign sedan, which Tolik drives, is already at the kerb. Tolik's own Volga is not in the scene. The camera starts on the player's arrival and then follows the car for the whole drive. If a car-radio loop is available, it plays quietly from here and cuts out at the restaurant; otherwise ambience is enough.

ТОЛИК: О, приехали! А я уж думал, опять никто не приедет, мне Борис Саввич говорит, встреть там человека, а какого человека, не сказал, ну я стою и на всех подряд смотрю. Вы ведь помощник, да? Толик я, водитель.

ТОЛИК: Сумку давайте в багажник, он у нас широкий, я в него и мешки с картошкой возил, и чего только не возил. Садитесь, садитесь, машина чистая, я её утром мыл, ну, как мыл, воды-то нет, протёр тряпкой.

ТОЛИК: Борис Саввич раньше десяти не будет, он вообще к десяти привык, так что у нас с вами два часа и полбака, давайте я вас по району покатаю, чтобы вы потом не спрашивали, где что, а сразу знали, куда не надо ходить.

*Толик ведёт одной рукой, а второй показывает во все стороны сразу.*

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

ТОЛИК: Вот вокзал, а рядом рынок, тут весь район кормится, и одежда там, и магнитофоны, и носки, и что хотите, вы только кошелёк держите поближе, а то он у нас быстро находит нового хозяина.


### Stop 2. The dormitory

[Общежитие]

ТОЛИК: А вот ваше общежитие, Борис Саввич распорядился, комната за вами. Видите, угол буквой «Г»? Его строили по остаткам плана, ну, у нас всё по остаткам. Комната на троих, соседи нормальные, один, правда, храпит, но зато труб не слышно, он их перекрикивает.

*Четыре этажа, бельё на верёвках. Из окна кто-то машет Толику, и Толик машет в ответ, не глядя на дорогу.*

### Stop 3. Highway and the industrial zone

[Шоссе вдоль реки]

ТОЛИК: Это у нас шоссе, вон АТП, вон порт, а вон склад с мазутом, там вечно кто-то стоит с канистрой, и каждый говорит, что по делу, так что сколько там мазута на самом деле, лучше у кладовщика не спрашивать.

ТОЛИК: А вон труба, третья от края, это котельная, её к зиме уже третий год чинят, всё никак, а без неё, сами понимаете, зимой у нас не жизнь.

ТОЛИК: Если что с отоплением, ищите Михалыча, слесарь наш, золотые руки у человека, просто его не всегда найдёшь, но вы не расстраивайтесь, он всегда где-нибудь находится.

### Stop 4. The border

[Граница]

ТОЛИК: А это граница, нам туда нельзя, там только по паспорту, очередь вон двое суток стоит, дальнобойщики друг друга уже в лицо знают, я думаю, скоро кто-нибудь женится.

ТОЛИК: Будку вон ту новую в июле поставили, старая, говорят, не выдержала.

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

ТОЛИК: Тут раньше колхоз был, потом всё разобрали на огороды, теперь осталось кладбище, церковь да несколько стариков, которые уезжать не хотят. Батюшка у нас отец Георгий, хороший, вы к нему с чаем приходите, у него чай настоящий, не то что у нас в исполкоме.

*Круг по деревне: грунтовка, заборы, куры. Толик объезжает лужи с уважением.*

### Stop 7. The avenue and the executive committee

[Проспект, исполком]

ТОЛИК: Вот и исполком, его вместе с районом строили, коробка крепкая, переживёт и нас, и всех, кто после будет, лифт вот только давно не работает, но вы молодой, дойдёте.

ТОЛИК: Вам на второй этаж, там дверь с табличкой, не перепутаете, и стучите погромче, он, когда не хочет, плохо слышит.

ТОЛИК: Ровно восемь, надо же, вы вовремя, это у нас редкость, запомнят, и хорошее запомнят, и плохое. Ну, ни пуха.

*Толик уехал, на ходу включив радио. Громко.*

## Scene 0.3. At the door

[Приёмная исполкома, 08:00]

> The wait from 08:00 to 10:04 is a time skip from the same seated corridor viewpoint. The newly fitted walnut door opens onto the district head's refurbished office. The greeting leads into the briefing in `mon-2-boss-and-block5.md`.

*Ровно восемь. Вы пришли вовремя. В здании это, кажется, заметили только часы.*

*Дверь с табличкой «Глава района». Закрыта.*

*Сидеть некуда, кроме стула у стены. Вы садитесь.*

[Время идёт]

[10:04]

*Послышались шаги, тяжёлые и без спешки. Ключ повернулся с первого раза.*

БОРИС САВВИЧ: А, новый помощник. Здорово. Заходи, дверь закрой.

## Drive monologue (draft v4, in the game)

The text of the drive lives in `init/scripts/data/arrival.gd` (`MEETING` and `DRIVE`), not here: it is one continuous speech of about 24 captions, each keyed to a route position and each continuing the last. Tolik asks questions and answers for the silent protagonist, then carries on; the answers never state anything about the protagonist. Landmark beats (market, dormitory, boiler, ATP, border, restaurant, village, executive committee) keep their highlight; the rest is plain talk. A cue that is due cuts off the previous line, so a line never describes a place already passed.

What it plants: the hot-water problem, the wasteland someone is "looking at" (Gusev), the Wednesday meeting at the House of Culture, Mikhalych, Father Georgy, the boss's silence. About himself Tolik gives: about ten years behind a wheel, long-haul to the border before the administration, Boris Savvich as his second boss, a wife at the market, a daughter in the fourth class, a father who is hard of hearing. The break at the restaurant and the over-bright "Вы любите тишину?" after it stay the centre of the sequence.

### Assumptions

- The wife, the daughter and the father are inventions for the drive (see `characters/tolik.md`).
- The former market and the three towers are Tolik's gossip, not canon.
- The Wednesday meeting follows the newspaper edition proposed below.

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
