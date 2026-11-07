# Friday, part 1: the inspection (draft v1, rewritten in the new spoken register)

Friday 29 August 1997, 12:00. The commission's engineer inspects Block 5 with Vera present. The outcome (passed, passed at a price, failed) follows from what the player prepared during the week, and Vera's article reflects what was shown and what was hidden.

## Characters

- **The engineer** (Arkady Lvovich Korotkov, about fifty-five): dry, procedural, tired, polite to the point of being impolite. Wears a grey raincoat in all weather and carries a briefcase older than the player. He appears only on Friday of week 1.
- **Vera** in her work look, with her notebook. She stays a step behind and writes.
- **Mikhalych**, if the player sent or kept him there; **Nina**, who is already at the door with her notebook.

## Scene. Block 5 at noon

[Двор дома 5, 12:00]

> Backdrop: the courtyard and entrance of Block 5. Conversation with a sequence of checks; about 2 hours. Three outcomes. Each check reads the flags set during the week.

*Серый плащ появляется во дворе ровно в двенадцать. Инженер здоровается со всеми по очереди, даже с собакой.*

КОРОТКОВ: Здравствуйте. Вы корреспондент, правильно? Записывайте всё, что сочтёте нужным, я возражать не буду.

*Он идёт по подъезду, трогает батареи, включает воду, подносит ладонь, считает вслух. Нина идёт рядом и считает про себя в тетрадь.*

### Check 1: hot water and heating (minimum)

> If part 1 is not met, the outcome is a fail regardless of the rest.

КОРОТКОВ: Вода есть, она тёплая, не горячая, но для конца августа этого достаточно.

### Check 2: the yard and the entrance

- *If done by Mikhalych and paint, by Nina and residents, or by a crew:* КОРОТКОВ: Подъезд подметён, двор убран, к самой проверке это отношения не имеет, но людям, как я понимаю, приятно.
- *If not done:* КОРОТКОВ: Двор, строго говоря, не мой вопрос, но я обязан это отметить.

### Check 3: the spare part

- *If delivered (storekeeper, Vitya or Gusev):* КОРОТКОВ: Клапан установлен, он старый, но исправный.
- *If not:* КОРОТКОВ: Клапана нет, а без него насос не выйдет на рабочий режим, вы это понимаете?

### Check 4: the 1996 act

> The key check. The engineer asks for last year's completion act.

КОРОТКОВ: Мне нужен акт приёмки за прошлый год, я хотел бы увидеть, что именно здесь было отремонтировано.

- **`act_hidden`** *(the page is missing)*:
  КОРОТКОВ: Листа нет. Вы понимаете, что из архива лист сам не пропадает? Я не утверждаю, что его убрали вы, я лишь констатирую, что его нет.
  *(Vera writes this down; flag `vera_notes_missing_page`)*
- **`act_declared`** *(the player and Mikhalych come forward)*:
  МИХАЛЫЧ: (выходит из-за спины Нины) Это я подписывал... Работ там не было никаких, мне сказали подписать, я и подписал, сказали молчать, ну и молчал, пока мог.
  КОРОТКОВ: (после паузы) Благодарю вас, это сказать непросто. Вы понимаете, что я обязан занести это в протокол?
  *(bond Mikhalych +2; the engineer writes it down; Vera writes everything)*
- **`act_left`** *(nothing was done)*:
  КОРОТКОВ: Акт есть, подпись есть, а работ, судя по подвалу, нет, объясните мне, пожалуйста, как это получилось.
  *(the player must answer on the spot: «Не знаю» or «Это было до меня»; the second is true and costs nothing, but the engineer remembers who sat in the chair)*

### Check 5: a contractor

- *If chosen:* КОРОТКОВ: Договор заключён, это хорошо, хотя меня больше интересуют сроки, чем подписи.
- *If not:* КОРОТКОВ: Подрядчика нет, и мне непонятно, кто здесь собирается работать.

## Outcomes

| Outcome | Condition | Effect |
|---|---|---|
| **Failed** | Part 1 not met | boss −15; Vera's article is hard; the evening is a reprimand |
| **Passed at a price** | Part 1 and at least two others, but at least one was done by payment, a favour or by hiding the act | boss +5; a trace or witness stays; the article is double-edged |
| **Clean pass** | Part 1 and at least three others with no payment, no favour and no hidden act | boss +10; residents +5; the article is warm |

> The thresholds are tuning values. In the draft a clean pass is possible but demanding.

## Vera's article (newspaper, week 2, `city` slot and a line in the summary)

| Outcome | Headline for the city slot |
|---|---|
| Clean pass | «В ДОМЕ № 5 ПРОВЕРИЛИ ОТОПЛЕНИЕ: ЗАМЕЧАНИЙ НЕТ» |
| Passed at a price | «КОМИССИЯ ПРИНЯЛА ДОМ № 5. ЗА ЧТО, НЕ УТОЧНЯЕТСЯ» |
| Failed | «ДОМ № 5 К ЗИМЕ НЕ ГОТОВ» |
| `act_declared` | add as a second line: «ЖИЛЬЦЫ ДОМА № 5 ЖДУТ ОТВЕТА НА ВОПРОС: КТО ПОДПИСАЛ АКТ?» |
| `vera_notes_missing_page` | add: «ИЗ АРХИВА ПРОПАЛ ЛИСТ. ГДЕ ОН?» |
| `vera_has_the_lead` | add: «ПРОШЛОЙ ОСЕНЬЮ КОТЕЛЬНУЮ ЯКОБЫ ОТРЕМОНТИРОВАЛИ» |

## Vera and the player after the inspection

*Когда инженер уходит, Вера задерживается у подъезда. Блокнот закрыт.*

ВЕРА: Знаете, что самое странное, вы мне сегодня ничего не сказали, а я вроде бы всё поняла.

- **«И что вы напишете?»** → ВЕРА: То, что видела, ну а что ещё, это же моя работа. *(neutral)*
- **«Спасибо, что были рядом.»** → ВЕРА: Да ладно вам, не за что, это тоже работа. *(bond Vera +1)*
- *If bond Vera 3 or more:* **«Вечером что делаете?»** → ВЕРА: (улыбается) Так мы же на одном этаже живём, куда я денусь. *(a small romantic beat; nothing happens)*

## Assumptions

- Korotkov's name and look are mine. He appears once and returns only if the player's choices make him.
- The article is the only visible output of Vera's work in week 1; its text lands in the week 2 newspaper.
- A clean pass is deliberately demanding; most players will "pass at a price", which is the point of the week.

## Open

- The exact payment thresholds and whether the engineer should score the yard at all.
