# Tuesday, part 1: the journalist at the door (draft v0)

Tuesday 26 August 1997, about 07:50. The morning starts at the dormitory at 06:00 and the walk to the executive committee is automatic from now on, but an automatic walk can be interrupted by an encounter. This is the first one. Vera is in her work look (blazer, burgundy lanyard, notebook); see `docs/story/characters/journalist.md`. Nothing is locked; one option appears only if the player learned something earlier.

## Scene. The steps of the executive committee

[Вторник, 06:00]

*Сергеича уже нет. Койка пустая, подушка хранит форму головы. Вы одеваетесь, и ноги сами идут в сторону исполкома. Это тоже, видимо, называется «привыкнуть».*

[Перед исполкомом, 07:50]

> Interrupts the automatic walk. Backdrop: the steps of the executive committee in cool morning light. Time cost about 0.5 hour. The first beat depends on what the player told her on Monday.

*На ступенях стоит девушка в тёмном пиджаке и что-то записывает. Пиджак новый, нет, не новый, но выглажен. На шее бордовый шнурок с карточкой: «Речные вести. Корреспондент».*

*Она поднимает глаза. Карандаша в волосах нет, волосы собраны.*

**If `vera_knows_job`:**

ВЕРА: Помощник главы района. Знаете, я вчера пошутила, что воду вам дадут в первую очередь. Не знала, что шучу над тем самым.

ВЕРА: Раз так, скажу сразу, без кухни. Я корреспондент. И мне нужен комментарий.

**If `vera_vague_job`:**

ВЕРА: «Бумаги, как все». Вы умеете говорить правду, не говоря её. Это пригодится в вашем доме.

ВЕРА: Я Вера, «Речные вести». Мне сказали, что к главе района прислали нового помощника. Я ждала его с утра. Он, оказывается, пил мой чай.

**If `asked_back` (in addition, either branch):**

ВЕРА: Вы единственный, кто вчера спросил, чем занимаюсь я. Это подло. Теперь мне неудобно задавать вам неудобные вопросы.

> **Choice 1: what she asks**

ВЕРА: Три предложения. Что новый помощник главы думает о районе перед отопительным сезоном? Я напишу «новый помощник главы района» и больше ничего. Имени мне не надо.

- **A. Прямо.** «Горячей воды в доме пять нет, это неправильно. Постараюсь, чтобы к пятнице она была.»
  ВЕРА: Записала. «Постараюсь, чтобы к пятнице». Вы понимаете, что это теперь в газете?
  *(a public promise: the `promise` option on the `hot_water` card is opened and counts as already made; breaking it costs more; residents standing up; boss standing down; bond Vera +1)*
- **B. Официально.** «Идёт подготовка к отопительному сезону, все вопросы решаются в рабочем порядке.»
  ВЕРА: Красиво. Как справка из жэка: всё правда, и ничего не понятно.
  *(neutral; boss standing +1; bond Vera 0)*
- **C. Отказаться.** «Без согласования с Борисом Саввичем комментариев не даю.»
  ВЕРА: Честно. Всё равно напишу, что вы отказались. Читатели любят, когда отказываются.
  *(boss standing +2; bond Vera −1; a small negative press note in the summary)*
- **D. Не для записи.** (only if the flag `knows_fake_repair` is set) «Прошлой осенью котельную якобы отремонтировали. Узнайте, кто подписывал акт.»
  ВЕРА: (её карандаш замирает) Я уже про это знаю. Только никто не хотел говорить вслух. Спасибо.
  *(bond Vera +2; she now follows the story; boss standing −2 if it ever surfaces; flag `vera_has_the_lead`, which changes Friday)*

> **Choice 2: one last move (optional)**

- **«А что вы сами думаете?»**
  ВЕРА: Что в этом городе люди хорошие. Я об этом уже говорила. И что это не оправдание.
  *(bond Vera +1)*
- **«Мне пора.»**
  ВЕРА: Мне тоже. Я вас найду. Это не угроза, это профессия.

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
