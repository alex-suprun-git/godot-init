# Thursday: Gusev day and the inspection announcement (draft v1, rewritten in the new spoken register)

Thursday 28 August 1997. Two decisions that Gusev touches on the same day (the wasteland kiosks and the contractor), then the boss announces Friday's inspection and the chain of preparations begins. The inspection is the main quest of the week: a minimum that must be met and several tight, realistic extras, some of which cost the player's own money.

## Scene 1. Gusev's two asks

[Исполком, 09:00]

> Two cards on the same day. The player may meet Gusev in person (a short conversation, about 30 minutes) or decide from the card. The decisions interact: giving him both makes him much stronger, and the boss notices.

*Гусев приходит без звонка и без записи. Он по-прежнему улыбается, но сегодня улыбка с делом.*

ГУСЕВ: Вы человек занятой, я знаю, поэтому коротко, у меня к вам два предложения, и оба, если честно, выгодны не мне, а вам, вы сами потом увидите.

ГУСЕВ: Первое, пустырь у вокзала, там можно спокойно поставить ларьки, штук двадцать, торговцы, которые сейчас мёрзнут на площади, получат нормальные места, а район получит порядок, всем же лучше.

ГУСЕВ: А второе, это котельная, вы же знаете, что я могу, ну а остальное вам расскажут те, кому не хочется, чтобы вы знали, как оно на самом деле.

### Card: `wasteland_stalls` (offer)

- **Разрешить двадцать.** Hint: «Торговцы довольны, Гусев тоже. Пустырь перестанет быть пустырём». *(business +, Gusev bond +1, residents −2, police −, because their cut at the square goes with the kiosks)*
- **Разрешить пять.** Hint: «Компромисс. Гусев поморщится, но заметит, что вы умеете договариваться». *(small + business, police 0)*
- **Отказать.** Hint: «Береза останется, пока. Гусев запомнит». *(residents +2, Gusev bond −1)*

### Card: `contractor` (conflict, deadline today 20:00)

- **Гусев («Стройремонт»).** Hint: «Дороже, но у него есть люди и опыт». *(business +, flag `contractor_gusev`)*
- **«Вершина».** Hint: «Дешевле. Но почему так дёшево?» *(if chosen, a risk: the later act, if found, points at them; flag `contractor_vershina`)*
- **Не выбирать сегодня.** Hint: «Подрядчика не будет, пока не решитесь». *(boss −20 at the deadline if nothing is chosen)*

> If the player gave Gusev both (twenty stalls and the contractor), flag `gusev_got_both`: the summary line says «Гусев в этом районе теперь везде», the boss will remark on it on Friday, and residents lose some trust.

## Scene 2. The boss announces the inspection

[Кабинет главы района, 14:00]

> Portrait briefing, as on Monday. Voice: heavy, unhurried, sardonic.

**БОРИС САВВИЧ ВЫЗЫВАЕТ**

**Завтра в двенадцать**

Завтра в двенадцать приедет инженер из горкомиссии, один, тихий такой, сухой, очень внимательный, будет смотреть дом пять, воду, батареи, подъезд, двор и бумаги, а потом решит, готов ли район к сезону.

Минимум, чтобы в доме была тёплая вода, остальное ты знаешь сам, не всё успеешь, а многое можно сделать так, чтобы выглядело, будто сделано, только это я бы на твоём месте делал не слишком усердно.

Отчёт ко мне вечером, если всё нормально, поедем ужинать, если нет, поговорим здесь.

**[Понял, Борис Саввич]**

> The inspection chain opens in the weekly folder as a single item with five parts. The `boss_report` card is shortened (a short task with few required hours) and moves to Friday evening.

## The inspection chain (five parts)

Friday 12:00 is the deadline. The minimum is part 1. The rest are realistic but tight; the player cannot do all of them in a day and a half without spending money or taking shortcuts.

| Part | What | Ways to do it | Cost |
|---|---|---|---|
| **1. Hot water and heating** (minimum) | The house works | Already done on Tuesday if Mikhalych fixed the pipe | none |
| **2. The yard and the entrance** | It looks cared for | Mikhalych and paint (3 h, paint 60 руб); Baba Nina rallies the residents (3 h, needs bond Nina 1 or more); a paid crew (150 руб, fast) | time or money |
| **3. The spare part** | A pump valve is stuck at the depot | The storekeeper wants «за хлопоты» (100 руб); Vitya on a Gazelle delivers (80 руб); Gusev provides it if he is chosen as contractor (free, but he is owed a favour) | money or a favour |
| **4. The 1996 act** | The inspector will ask for last year's completion act | Find the original in the archive (a documents task, 2 h); ask Mikhalych what he signed (needs bond 1 or more); say nothing | time, a witness, or a risk |
| **5. A contractor is chosen** | Works are visibly about to start | Resolve the `contractor` card | see the card |

> Own-pocket payments (parts 2 and 3) are an intended place where the thin wallet bites. Prices are tuning values, shown on the card before the player chooses.

### Part 4 in detail: the act

> If the player asks Mikhalych (bond 1 or more and flag `knows_polite_men`) he confesses on Thursday evening, or the player finds the act in the archive. Either way the act shows: last autumn's boiler repairs, signed as completed, with the stamp of «Вершина» and Mikhalych's signature, and no work done.

*Акт аккуратный. Подпись крупная, будто человек очень старался. Печать чуть смазана. Работ, судя по подвалу, не было.*

**Что с ним делать?**

- **Убрать лист из архива.** Hint: «Проверка пройдёт спокойнее. Но тот, кто убирал, останется». *(a trace; a witness: Mikhalych and whoever helped; flag `act_hidden`)*
- **Предупредить Михалыча и пойти к инженеру открыто.** Hint: «Честно. Михалычу тяжело, Борису Саввичу тоже, зато правда сказана вами». *(bond Mikhalych +2; the boss will be unhappy; flag `act_declared`)*
- **Ничего не делать.** Hint: «Если инженер спросит, ответ будет не вашим». *(flag `act_left`)*

## Evening

> A training session is offered again (the second of four). The player may also spend the evening preparing. Mikhalych, if he came this far, sits down on the Block 5 steps with his tea and says something short and hopeful: «Завтра, значит. Ничего. Переживём.»

## Assumptions

- The wasteland kiosks are a bigger deal than the number suggests: they are the thing the vendors from the station square need (Wednesday).
- "Вершина" is the firm that took the money last year; the player can discover it only through the act, or Gusev's hint on Tuesday.
- The inspector arrives alone and is new to the district.
- The own-pocket payments are small enough that the starting 1,200 руб can cover several, but not all.

## Open

- Whether part 4 should include a way to ask Gusev for help (he would, for a price).
