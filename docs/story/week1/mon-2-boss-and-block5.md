# Monday, part 2: the boss and Block 5 (draft v1, rewritten in the new spoken register)

Monday 25 August 1997, 10:04 to the afternoon. Two scenes: the boss's briefing (a portrait monologue, as in the current game) and the first conversation (Baba Nina at Block 5). The protagonist's name is not fixed; nobody uses it.

## Scene 1. The boss's office

[Кабинет главы района, 10:04]

> Format: the existing portrait briefing (`START_BRIEFING` in `init/scripts/data/week1.gd`), then the weekly task board. The core is kept (commission on 15 October, contractor by Thursday, the boss handles fuel oil himself); the voice is rewritten for "the new man", and the meeting at the House of Culture and the first push toward Block 5 are added. The Friday item stays "a report" here; the inspection is announced on Thursday (see the root README).
>
> Voice: heavy, unhurried, sardonic. He never raises his voice. He says "ты" to the player.
>
> Anya is the young secretary. Boris names her as the person who will orient the new aide.

**БОРИС САВВИЧ ВЫЗЫВАЕТ**

**Закрой дверь. Разговор есть**

*The boss has just greeted the new aide at the door.*

Слушай один раз, повторять не буду. Пятнадцатого октября приезжает комиссия из области, будут ходить по котельным, по подвалам, по домам и спрашивать, почему батареи холодные, а спрашивать будут с меня, ну а я, соответственно, с тебя.

Подрядчика на котельную выберешь сам, до четверга, их двое, оба клянутся, что лучше них нет, кто чего стоит, разберёшься, не маленький. В пятницу придёшь с отчётом, и чтобы без «работаем над этим».

Люди будут ходить и просить, кто с водой, кто с крышей, кто просто пожаловаться. Не всех слушай, но и не отмахивайся, через месяц эти же люди будут стоять перед комиссией. В среду вечером они соберутся в Доме культуры, поговорить про границу, ты там будь. Выступать не обязан, но если станешь, то так, чтобы мне потом не краснеть.

Бумаги на тебе, их много, они скучные, и за тебя их никто не напишет. А мазутом я занимаюсь сам, туда не лезь.

Вопросы есть? Нет. Вот и хорошо.

И начни с дома пять, там воды нет. Звонили три раза, я трубку не брал, теперь твоя очередь.

Мне пора. Аня, мой секретарь, введёт тебя в курс дела.

**[Понял, Борис Саввич]**

> Interface: the work folder button appears with the weekly task board. The map controls (zoom, to-self, district) appear when the player leaves the building and the speed controls when the player first has free time on the map. The contacts drawer appears after the Nina scene, the wallet at the first moment money matters.
>
> After the button: the weekly task board opens (paperwork, contractor, report). The `hot_water` card appears on the map at Block 5. The player is on foot; the walk from the executive committee to Block 5 is about 15 game minutes.

## Scene 2. Block 5: Baba Nina

[Двор дома 5, 10:35]

> First conversation of the game. Backdrop: the courtyard of Block 5 with the bench by the entrance. Character: Baba Nina, in her seventies, glasses on a cord, a green notebook in an oilcloth cover (see `init/assets/portraits/baba_nina.png`). She is sharp, tireless and suspicious of anyone from the executive committee; she is the district's "voice of the people". She tests newcomers before she helps.
>
> Time cost: about 1 to 1.5 game hours in total (tuning value). The timeskip happens behind the scene at the end. Mikhalych cannot be sent anywhere yet: he is unknown to the player and absent. Nothing is locked in week 1.

*Дом пять. Пять этажей серого кирпича, бельё на балконах, во дворе скамейка с тремя женщинами. Когда вы подходите, разговор обрывается.*

*Одна из них встаёт. Маленькая, в очках на шнурке, с тетрадью в клеёнчатой обложке.*

НИНА: Вы из исполкома? Ну конечно, из исполкома, я по ботинкам вижу, у нас в таких только оттуда ходят. Третий день без горячей воды сидим, а у меня в подъезде восемь стариков, один лежачий, ему и помыться надо, и грелку согреть, а вы тут на ботиночках.

> **Choice 1: how to introduce yourself**

- **A.** «Я новый помощник главы района. Пришёл разобраться с водой.»
  НИНА: Помощник, значит. Ну ладно, помощник, а помогать будете или записывать? Я вот сама всё записываю, мне ещё одного записывающего не надо.
  *(bond Nina 0; she keeps testing)*
- **B.** «Я никто. Приехал сегодня утром. Расскажите, что случилось.»
  НИНА: Приехали, значит, сегодня. Ну тогда садитесь, чего стоять, а то вы как комиссия, стоите над душой и молчите.
  *(bond Nina +1; she sits you down)*
- **C.** «Давайте заявление, оформим по порядку.»
  НИНА: Заявление вам, ну да, а у меня их в тетради три штуки лежит, и все по порядку, и все приняты, а вода как была холодная, так и холодная.
  *(bond Nina −1, residents −1 in the summary line)*

*Она раскрывает тетрадь на закладке.*

НИНА: С четверга у нас горячей воды нет, это уже третий раз за год, а год-то ещё не кончился. Я в мэрию два раза писала, и оба раза мне ответили, что принято к сведению, ну принято и принято, а мыться-то как?

> **Choice 2: what to ask (each costs about 15 game minutes; the player may ask all three, in any order)**

- **«Кто у вас обычно чинит?»**
  НИНА: Михалыч наш, слесарь из жэка, золотые руки у человека, я вам скажу, только третий день его нет.
  ВЫ: Нет?
  НИНА: Запил он, милый, раньше с ним, конечно, тоже бывало, но чтобы так, это только с осени, как подменили человека, ходит серый, глаза в пол, на людей не смотрит.
  НИНА: Ищите за рынком, позади палаток, там пивная есть, без названия, ну, вывеска-то есть, только буквы повыпадали, а если там нет, то у сестры его, на Лесной, он между ними ходит туда-сюда.
  *(flags: `knows_mikhalych_missing`, `knows_pub`)*
- **«Что было прошлой зимой?»**
  НИНА: Прошлой зимой нам на собрании бумагу показывали, что котельную отремонтировали, всё готово, мы даже похлопали, а в январе спали в пальто.
  НИНА: Бумага красивая была, с печатью, я потому и запомнила.
  *(flag: `knows_fake_repair`; later pays off with the 1996 acts)*
- **«Что вам нужно?»**
  НИНА: Чтобы вода шла, во-первых, а во-вторых, чтобы пришёл кто-нибудь и людям сказал, что будет, не по телевизору, а сюда, в двор, потому что люди же не слепые, всё видят.
  *(flag: `nina_wants_a_visit`; plants the meeting on Wednesday evening)*

*Она захлопывает тетрадь, но не убирает.*

НИНА: Только вы его не ругайте, когда найдёте, он человек стеснительный, вы его лучше попросите, чем приказывать, он тогда придёт, а прикажете, так упрётся.

> **Choice 3: closing (how the scene ends)**

- **«Постараюсь. Но вода должна быть.»**
  НИНА: Должна, это правильно, только «постараюсь» у нас уже много раз слышали.
  *(neutral)*
- **«Обещаю: сделаю всё, чтобы вода была к пятнице.»**
  *(opens the `promise` option on the `hot_water` card; breaking it costs more than refusing)*
  НИНА: Запишу, пятница, значит. Вы уж не подведите, а то я тетрадку с собой ношу.
- **«Спасибо, что рассказали.»**
  НИНА: Да не за что, мне самой легче, когда человека слышат.
  *(bond Nina +1)*

НИНА: Как вас записать?

*Вы не успеваете ответить.*

НИНА: Ну, запишу «новый помощник», а дальше видно будет.

[Время идёт, 11:50]

> After the scene: the `hot_water` card stays open, with Mikhalych unavailable until found (the pub, Tuesday). Afternoon is free on the map: the player may walk, explore, buy something, or start paperwork. At the end of the day the "going home" quest starts (see `mon-3-dormitory.md`, not written yet).

## Data and engine notes for Codex

- `ACTORS.nina` has `enabled: false`; the first conversation makes her a known person (bond starts here), but she is not yet an assignable contact. Make "introduced" and "assignable" two separate states.
- `ACTORS.mikhalych` currently starts at `office` with availability 08:00 to 18:00. In the redesign he starts absent (location: the pub, to be mapped) and the "send Mikhalych" option is closed until the player has met him.
- `START_BRIEFING.body` replaced by the text above; `OBJECTIVES` unchanged for Monday.
- Bond with Nina: a small integer with a verbal label. Numbers are hidden. Three levels are enough for the demo.
- The shop hint (card note "something simple may help") is not used on Monday.

## Open

- Name and location of the pub ("пивная на задах у рынка") on the map.
- Whether the three choices should affect the Residents standing visibly on Monday or only in the summary.
- Whether Nina should already mention the House of Culture meeting herself (currently only the boss does).
