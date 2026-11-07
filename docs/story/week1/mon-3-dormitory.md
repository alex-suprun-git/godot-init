# Monday, part 3: going home and the neighbour (draft v1, rewritten in the new spoken register)

Monday 25 August 1997, from 18:00. Two scenes: the "going home" quest (the player clicks the dormitory and chooses how to travel) and the first evening conversation with the neighbour (Vera, see `docs/story/characters/journalist.md`). The protagonist's name is not used; Vera calls him "Новенький".

## Scene 1. Going home (a quest, not an automatic walk)

[Исполком, 18:00]

> Official duty ends at 18:00. For the first evening there is no automatic walk home: a card "Вернуться в общежитие" appears, with a small note under it. This teaches the map and the transport choice without a tutorial, and it quietly tests whether the player remembered the dormitory from Tolik's drive (he pointed it out and said the room is already assigned). The wallet appears here because a taxi price is shown for the first time.

**Вернуться в общежитие** (the card, type plea, no asker)

*День кончился. Общежитие вы утром видели из окна «Волги»: угол буквой «Г», на западе, за бельём на верёвках. Дорогу вам, правда, никто не записал.*

> Hint under the card (tunable): «Нажмите на общежитие на карте».

Options:

- **Пойти пешком.** Free. About an hour (to be measured on the real route). Hint: «Дорога длинная, зато без расходов. Увидите район по пути».
  *(the walk passes the west street; one caption on the way: *Бельё на верёвках. Из окна кто-то спросил, не новый ли вы. Вы не успели ответить.*)*
- **Взять такси.** Price shown on the card (starting value 40 руб, a tuning value). Hint: «Быстро. Но первые деньги уходят не на то, на что хотелось бы».
- **Остаться на работе допоздна.** Hint: «Бумаги не кончатся. Ночевать, правда, придётся дома». *(starts paperwork; leaves the quest open until 22:00)*

> No option is a trap. At 22:00 the existing overtime rule ends the day: if the player has not reached the dormitory, the walk home is automatic and takes the time it takes.

## Scene 2. The corridor kitchen

[Общежитие, третий этаж, 21:30]

> Conversation, about 1 hour (tuning value). Backdrop: the corridor kitchen: a two-ring stove, a kettle, a calendar from a sawmill, one bulb. Character: Vera, in her home look (cardigan, pencil in her hair). Nothing is locked.

*Комната на третьем этаже. На соседней койке кто-то спит так, что койка слегка вибрирует. Это Сергеич. Вас предупреждали.*

*В конце коридора горит свет. Кухня. У плиты девушка моет кружку и не оборачивается.*

ВЕРА: Ой, вы новенький, да? Подождите, не уходите, чайник сейчас закипит, он у нас минут пять греется, а потом как зашипит, лучше отойти.

ВЕРА: Вы к Сергеичу, на третью койку? Мне говорили, там как раз освободилась.

ВЫ: К нему.

ВЕРА: Ну, держитесь, он ночью такое выводит, что я вообще не понимаю, как стены стоят.

> **Choice 1: what she asks next**

ВЕРА: А вы где работаете? Просто тут все друг у друга спрашивают, делать больше нечего, вы не обижайтесь.

- **A.** «Работаю в районной администрации. Помощником главы.»
  ВЕРА: Помощником, ничего себе, ну тогда воду вам, наверное, в первую очередь дадут.
  *(flag `vera_knows_job`; bond Vera 0)*
- **B.** «Бумаги. Как все.»
  ВЕРА: Бумаги, ну да, у всех бумаги, кого ни спроси.
  *(flag `vera_vague_job`)*
- **C.** «А вы?»
  ВЕРА: Я? Я всё больше по буквам, ну, читаю там, пишу, по-разному.
  *(flag `asked_back`; bond Vera +1; she is pleased to be asked)*

*Она ставит чайник на конфорку и наконец поворачивается. Лет двадцать пять, карандаш в волосах, на кофте дырка на локте, которую она, кажется, не замечает.*

> **Choice 2: small talk (each about 15 minutes; any of the three, in any order)**

- **«Как тут живётся?»**
  ВЕРА: Воду дают с шести до восьми, а потом как повезёт, горячей у нас, по-моему, вообще никогда не было, но зато кухня есть, это почти как квартира.
- **«Что это за город?»**
  ВЕРА: Хороший город, правда, люди хорошие, и накормят, и пожалеют, и поддержат, только от этого всё как-то непонятно.
  ВЫ: Что непонятно?
  ВЕРА: Ну как так получается, что люди хорошие, а всё остальное вот так.
- **«Вы местная?»**
  ВЕРА: Местная, да, здесь родилась, и все думают, что я уеду, и я тоже думаю, уже лет пять, а всё как-то откладываю.

*Чайник закипает. Она наливает вам первой, не спрашивая.*

> **Choice 3: how it ends**

- **«Спасибо за чай.»**
  ВЕРА: Да ладно, кружка общая, я потом помою.
  *(bond Vera +1)*
- **«Скажите, как вас зовут?»**
  ВЕРА: Вера. Я на этом же этаже, в четырнадцатой, если что, стучите, только не после двенадцати.
  *(bond Vera +1; she does not ask his name back)*
- **«Пойду, завтра рано вставать.»**
  ВЕРА: Ну давайте, спокойной ночи, Новенький.
  *(neutral)*

[22:40]

*Сергеич перевернулся на другой бок. Койка перестала вибрировать. Вы заснули, и вам ничего не приснилось.*

[Вторник, 06:00]

## Flags and effects (draft values, hidden from the player)

| Flag | Meaning | Used on Tuesday |
|---|---|---|
| `vera_knows_job` | She knows he works in the administration, but not that he is *the* aide | She is less surprised, more guarded |
| `vera_vague_job` | He hid it | She is amused and a little annoyed |
| `asked_back` | He showed interest in her | She is warmer |
| bond Vera | 0 to 3 | Tone of the Tuesday meeting |

## Assumptions

- The first evening has no automatic walk home; the taxi price (40 руб) is a placeholder.
- Sergeich, a roommate who snores, is a minor character and has no scene. A third roommate is not introduced.
- Vera reveals her name only if asked. She calls the protagonist "Новенький" and never learns his name in week 1.
- Hot water in the dormitory is a background fact; it is not a request.

## Open

- How long the real walk from the executive committee to the dormitory is in game minutes.
- Whether the roommate Sergeich should be named in Tolik's line on Monday morning (currently "один храпит").
