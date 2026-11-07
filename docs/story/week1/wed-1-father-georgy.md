# Wednesday, part 1: Father Georgy (draft v1, rewritten in the new spoken register)

Wednesday 27 August 1997, morning. The `church_heat` request (the church asks to be heated before winter) becomes a visit with a conversation, as the user wanted: tea with the priest, about 1.5 game hours, which matches the value already in the data. Father Georgy is a guest, not yet a contact.

## Scene. Tea in the church house

[Церковь, 09:30]

> Conversation, about 1.5 hours. Backdrop: a small room beside the church, an oilcloth on the table, a samovar, an icon in the corner, a window onto the cemetery. Character: **Father Georgy**, about sixty, gentle, humorous, a good listener, strong tea. Tolik told the player on Monday: «К нему лучше с чаем». If the player brings tea or sugar from the department store the scene opens warmer (bond +1).

*Отец Георгий встречает вас на крыльце, как будто ждал. Рукава подвёрнуты, в руке тряпка. Он что-то мыл.*

ОТЕЦ ГЕОРГИЙ: Проходите, проходите, я вас не знаю, значит, вы новый, старых-то я всех знаю, а вы, наверное, пришли по другому делу, не так, как они.

ОТЕЦ ГЕОРГИЙ: Чаю будете? Он у меня настоящий, не то что в исполкоме дают.

*Чай действительно крепкий, после второго глотка просыпаешься.*

> **Choice 1: why you came**

- **A. По делу.** «Вы просили протопить храм. Расскажите, что нужно.»
  ОТЕЦ ГЕОРГИЙ: Нужно, чтобы зимой в храме лампады не гасли от холода, я не в переносном смысле, они у нас и правда гаснут, масло густеет.
  *(unlocks the resolution card)*
- **B. По-человечески.** «Расскажите о приходе. Кто к вам ходит?»
  ОТЕЦ ГЕОРГИЙ: Старики в основном ходят, а есть и молодые, они приходят, когда им страшно, и вот в последнее время приходят чаще.
  *(bond Georgy +1; flag `georgy_mentions_fear`)*
- **C. Прямо.** «Что вы хотите от администрации?»
  ОТЕЦ ГЕОРГИЙ: Хорошо, что вы так прямо спросили, только я ничего не хочу, я прошу, это разное, вы потом поймёте.

> **Choice 2: what to ask (about 20 minutes each)**

- **«Чего боятся ваши прихожане?»**
  ОТЕЦ ГЕОРГИЙ: Кто чего боится, старики холода, а молодые, наверное, тишины, у нас в последнее время по ночам тихо-тихо, а потом выстрелы, это не у нас, а у границы, но слышно.
  *(flag `georgy_heard_shots`; plants Wednesday evening)*
- **«Вы многих здесь знаете?»**
  ОТЕЦ ГЕОРГИЙ: Многих, да, в основном по голосам, на исповеди же лиц не видно, вот слух и привыкаешь.
  *(he says nothing more; the player can ask no further)*
- **«Нужна ли помощь с подвалом?»**
  ОТЕЦ ГЕОРГИЙ: Подвал у нас сухой и тёплый, там людей приютить можно, если вдруг что случится, не дай Бог, конечно.
  *(flag `georgy_shelter_offer`: a quiet foreshadowing of the war chapter, the cellar as a shelter)*

*Он подливает чай, не спрашивая.*

ОТЕЦ ГЕОРГИЙ: Приходите ещё, не обязательно с просьбой, просто так тоже можно.

## Resolution: `church_heat`

> The existing request stays as written in `week1.gd` (urgency days, the player may go in person, send a contact or promise). The scene replaces the 1.5 hour "tea" with a conversation that can end in a clear choice.

- **Взять на себя.** Hint: «Храм протопят. Отец Георгий запомнит». *(church standing up)*
- **Отложить до сентября.** Hint: «Батюшка поймёт. Бабушки, возможно, нет». *(church standing slightly down, residents −1)*
- **Пообещать и не уточнять.** Hint: «Бесплатно сейчас, платить потом». *(opens a promise; breaking it costs more than refusing)*

## Effects (draft values, hidden)

| Choice | Bond Georgy | Church | Other |
|---|---|---|---|
| Brought tea or sugar | +1 | 0 | none |
| B (human) | +1 | 0 | `georgy_mentions_fear` |
| Resolution: take it on | 0 | +10 | costs the player time |
| Resolution: postpone | 0 | −3 | residents −1 |

## Assumptions

- Father Georgy never says who fires the shots; he says only that it is audible from the border.
- The cellar as a shelter is an aside, not a quest; it will matter in the war chapter.
- The gift of tea is the second place where the shop hint appears (the first is Mikhalych's meal).

## Open

- Whether a second visit in a later week should turn Georgy into a contact.
