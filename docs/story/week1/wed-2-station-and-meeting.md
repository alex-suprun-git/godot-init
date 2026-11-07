# Wednesday, part 2: the station square and the House of Culture (draft v0)

Wednesday 27 August 1997, afternoon and evening. The first part of the kiosk story (vendors and police at the station square), then the residents' meeting in the House of Culture. The two are linked by one bullet hole in a kiosk window.

## Scene 1. The station square

[Вокзальная площадь, 14:00]

> Resolution card `market_cops` (a conflict: vendors and police share the square) with one short, unnamed conversation. No new named characters. Backdrop: the station forecourt with kiosks and stalls. Time cost about 1 hour including the card.

**Ларёчники и милиция делят площадь** (conflict card, waiting at the station)

*У вокзала толпа торговцев и один милиционер, который смотрит на них с видом человека, которому недавно объяснили, где у него процент.*

*Из ближнего ларька выглядывает женщина лет пятидесяти. Она ничего не говорит. Просто показывает пальцем на окно.*

*В стекле круглая дырочка с лучами трещин. Стекло заклеено скотчем, но дыра осталась.*

ПРОДАВЩИЦА: Вот. В субботу ночью. Я не из пугливых, но вечером я теперь не торгую.

ПРОДАВЩИЦА: Милиция потом пришла, посмотрела, спросила, кому мы мешаем. А мы кому мешаем?

> **Choice: what the player says (the conversation is one beat)**

- **«Кто стрелял?»**
  ПРОДАВЩИЦА: Если бы я знала, я бы вам не сказала. Не потому, что боюсь. Потому что вы всё равно ничего не сделаете.
- **«Что вам нужно?»**
  ПРОДАВЩИЦА: Чтобы милиция ходила не за процентом, а за порядком. Это же очень большая просьба, да?
- **Промолчать и записать.**
  *(the player writes the details; flag `saw_the_kiosk`)*

### Resolution options (draft)

- **Встать на сторону торговцев.** Hint: «Торговцы вздохнут, милиция запомнит, что вы не в их доле». *(business +, police −)*
- **Встать на сторону милиции.** Hint: «Порядок появится. Торговцы решат, что вы с ними не говорите». *(police +, business −, residents −)*
- **Собрать обе стороны и разобраться.** Hint: «Долго. Не все останутся довольны. Зато всех услышите». *(costs 3 hours; small plus with both)*

> Thursday's `wasteland_stalls` (Gusev wants to move kiosks to the wasteland) continues this thread: vendors who lose their place at the square are exactly the ones Gusev offers new ones to.

## Scene 2. The House of Culture

[Дом культуры, 19:00]

> The residents' meeting, moved from Block 5 to the House of Culture and from Thursday to Wednesday evening. Backdrop: the hall, rows of seats, a stage with a table and a flag. The boss does not come; the player represents the administration. A police officer, a few residents (Nina among them, with her notebook), no one else is named. Time cost about 2 hours.

*Зал почти полон. Люди пришли с семьями и ссорами. На сцене стол, три стула, графин, которого никто не трогает.*

*Нина сидит в первом ряду и открывает тетрадь на чистой странице. Увидев вас, она кивает: коротко, как судья.*

*Председательствует майор милиции, невыспавшийся человек с хорошими манерами.*

МАЙОР: Товарищи, граждане. Мы собрались по вопросу безопасности на окраинах района. Слово представителю администрации.

*Все смотрят на вас. Вы единственный, кого здесь никто не знает.*

> **Choice 1: the speech (the main beat)**

- **A. Пообещать патрули.** «Мы добьёмся, чтобы на окраинах появились ночные патрули.»
  *(residents +, police: the major tenses, he did not agree; boss: unhappy, he has dealings with these people; the criminal side hears it and notices the new man)*
- **B. Обвинить милицию.** «Милиция должна отвечать за порядок. А сейчас она отвечает за процент.»
  *(residents ++, police −−, the criminal side notices the new man; a flag `spoke_sharply`; this later draws Sedov's interest)*
- **C. Задать наивный вопрос.** «Скажите, кому выгодно, чтобы по ночам стреляли?»
  *(the hall goes quiet; residents +, the boss: a nervous glance; flag `asked_who_benefits`; Nina writes something down and underlines it)*
- **D. Говорить мягко.** «Администрация знает о проблеме и работает над ней.»
  *(boss +, residents −; the hall's mood sinks; flag `spoke_softly`)*

> **Choice 2: the sub-question** (the hall wants a promise about heating)

МАЙОР: Тут ещё спрашивают про отопление. Можете ли вы назвать срок?

- **Назвать срок.** «К первому октября.» *(opens a promise; breaking it costs more than refusing)*
- **Честно отказать.** «Срока пока назвать не могу. Работаем.» *(residents slightly −, Nina's note: honest)*
- **Передать вопрос главе.** *(boss +, residents −)*

*Зал расходится медленно. Люди переговариваются тихо, как после похорон, на которые никто не собирался.*

*Нина останавливается у вашего стула.*

НИНА: Вы сказали. А это уже не молчание. Запишу.

[22:10]

## Effects (draft values, hidden)

| Choice | Residents | Police | Boss | Flags |
|---|---|---|---|---|
| A (patrols) | +8 | −3 | −3 | the criminal side notices |
| B (blame police) | +12 | −8 | −2 | `spoke_sharply`, the criminal side notices |
| C (naive question) | +6 | −2 | −1 | `asked_who_benefits` |
| D (soft) | −4 | +2 | +4 | `spoke_softly` |

> Bond Nina +1 for A, B or C; none for D.

## Assumptions

- The meeting has no named official except the unnamed major; no new named characters.
- The bullet hole in the kiosk glass is the incident referred to in the root README ("a shot through a station kiosk window, nobody hurt").
- The boss is deliberately absent; his reaction comes later through the report.
- A speech at 19:00 means the training session of the evening is replaced; the evening is spent.

## Open

- Whether the criminal side's attention should be visible on the map as a small marker or only as the Friday dinner.
