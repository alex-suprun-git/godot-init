# Tuesday, part 1: the journalist at the door (draft v1, rewritten in the new spoken register)

Tuesday 26 August 1997, about 07:50. The morning starts at the dormitory at 06:00 and the walk to the executive committee is automatic from now on, but an automatic walk can be interrupted by an encounter. This is the first one. Vera is in her work look (blazer, burgundy lanyard, notebook); see `docs/story/characters/journalist.md`. Nothing is locked; one option appears only if the player learned something earlier.

## Scene. The steps of the executive committee

[Вторник, 06:00]

*Сергеича уже нет, койка пустая. Вы одеваетесь и идёте на работу, ноги уже знают дорогу.*

[Перед исполкомом, 07:50]

> Interrupts the automatic walk. Backdrop: the steps of the executive committee in cool morning light. Time cost about 0.5 hour. The first beat depends on what the player told her on Monday.

*На ступенях стоит девушка в тёмном пиджаке и что-то записывает. Пиджак новый, нет, не новый, но выглажен. На шее бордовый шнурок с карточкой: «Речные вести. Корреспондент».*

*Она поднимает глаза. Карандаша в волосах нет, волосы собраны.*

**If `vera_knows_job`:**

ВЕРА: Ой, это вы, помощник главы района, а я вчера ещё сказала, что воду вам в первую очередь дадут, и даже не подумала, что это вы и есть.

ВЕРА: Ну раз так, скажу сразу, не как соседка, я корреспондент, из «Речных вестей», и мне от вас нужен комментарий.

**If `vera_vague_job`:**

ВЕРА: «Бумаги, как все», ну надо же, и ведь не соврали ни слова, а я вам вчера чай налила.

ВЕРА: Я из «Речных вестей», мне сказали, что к главе района прислали нового помощника, я его с самого утра жду, а он, оказывается, у нас на третьем этаже живёт.

**If `asked_back` (in addition, either branch):**

ВЕРА: Вы же вчера единственный спросили, чем я занимаюсь, и мне теперь как-то неудобно задавать вам неудобные вопросы, но придётся.

> **Choice 1: what she asks**

ВЕРА: Мне нужно всего три предложения, что новый помощник главы думает о районе перед отопительным сезоном, я напишу «новый помощник главы района», и всё, имени мне не надо.

- **A. Прямо.** «Горячей воды в доме пять нет, это неправильно. Постараюсь, чтобы к пятнице она была.»
  ВЕРА: Так, записала, «постараюсь, чтобы к пятнице», вы только понимаете, что это теперь в газете будет?
  *(a public promise: the `promise` option on the `hot_water` card is opened and counts as already made; breaking it costs more; residents standing up; boss standing down; bond Vera +1)*
- **B. Официально.** «Идёт подготовка к отопительному сезону, все вопросы решаются в рабочем порядке.»
  ВЕРА: Ну да, понятно, это как справка из жэка, там тоже всё правда, а что именно, не разберёшь.
  *(neutral; boss standing +1; bond Vera 0)*
- **C. Отказаться.** «Без согласования с Борисом Саввичем комментариев не даю.»
  ВЕРА: Ну, честно, что тут скажешь, только я всё равно напишу, что вы отказались, мне же надо что-то написать.
  *(boss standing +2; bond Vera −1; a small negative press note in the summary)*
- **D. Не для записи.** (only if the flag `knows_fake_repair` is set) «Прошлой осенью котельную якобы отремонтировали. Узнайте, кто подписывал акт.»
  ВЕРА: (карандаш останавливается) Я про это уже слышала, только никто вслух не говорил, все шёпотом, спасибо вам.
  *(bond Vera +2; she now follows the story; boss standing −2 if it ever surfaces; flag `vera_has_the_lead`, which changes Friday)*

> **Choice 2: one last move (optional)**

- **«А что вы сами думаете?»**
  ВЕРА: Что люди у нас хорошие, я вам вчера уже говорила, только это, по-моему, ничего не оправдывает.
  *(bond Vera +1)*
- **«Мне пора.»**
  ВЕРА: Мне тоже, я вас потом найду, вы не пугайтесь, это просто работа такая.

*Она уходит по ступеням вниз, не оглядываясь. На шнурке качается карточка.*

[Исполком, 08:20]

> Day continues: the boss's morning, the search for Mikhalych (`tue-2-mikhalych.md`).

## Effects (draft values, hidden from the player)

| Choice | Bond Vera | Boss | Residents | Other |
|---|---|---|---|---|
| A | +1 | −1 | +3 | public promise on `hot_water` |
| B | 0 | +1 | 0 | none |
| C | −1 | +2 | 0 | press note in the summary |
| D | +2 | −2 (if it surfaces) | 0 | `vera_has_the_lead` |

## Assumptions

- She has been told to interview "the new aide" and did not know it was her neighbour. Her "I'll find you" is a promise she keeps on Friday.
- Option D is visible only with `knows_fake_repair`, not greyed out (week 1 locks nothing).
- The public promise in A is the first time a player's words reach the newspaper.

## Open

- Whether the summary shows Vera's article as a line of its own in week 2 already.
