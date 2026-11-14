# Friday, part 2: the report and the restaurant (draft v1, rewritten in the new spoken register)

Friday 29 August 1997, evening. The report to the boss is a short task. If the player covered for him (the inspection was passed, cleanly or at a price), the report becomes an invitation to the restaurant Tolik drove past on Monday. If not, it is the old reprimand. The restaurant introduces Sedov and plants the side job.

## Branch A: the invitation (passed, cleanly or at a price)

[Кабинет главы района, 18:00]

> A short conversation, about 15 minutes. Backdrop: the boss's office with the window open. The boss is relaxed in a way the player has not seen.

БОРИС САВВИЧ: Докладывай. Нет, не надо, я уже всё знаю, садись, поедем ужинать.

ВЫ: Куда?

БОРИС САВВИЧ: Туда, где нас ждут, меня давно ждут, а теперь, получается, и тебя.

> If the outcome was a clean pass the boss says: «Я думал, ты пришёл просто работать. Выходит, ты пришёл работать хорошо». If it was a pass at a price he says: «Мне нравится, что ты понимаешь цену. Только не говори её вслух».

## Scene. The restaurant behind the executive committee

[Ресторан, 19:30]

> Conversation, about 2 hours. Backdrop: a private club behind a tall wall: a hall with dark wood, a long table, candles that are clearly for show. The player has seen only the fence from the car on Monday. Tolik waits in the official sedan outside; if the camera shows him, the radio is off. Characters: the boss, **Sedov** (about forty-five, quiet, reasonable, an expensive cheap suit), a waiter. No criminals are named or shown.

*Охранник у ворот знает Бориса Саввича в лицо. Вас он не знает и не спрашивает, что говорит о его опыте.*

*Зал полупустой. За дальним столом человек ужинает один, увидев вас, вежливо ставит нож. Это не вам. Это Борису Саввичу.*

БОРИС САВВИЧ: Знакомьтесь, это Седов, Эдуард Павлович, он у нас вопросы решает.

СЕДОВ: Добрый вечер. Эдуард Павлович, мне сказали, что с вами стоит познакомиться. Я не люблю, когда люди заранее решают, что они мне должны, поэтому давайте просто поужинаем, а о делах поговорим, если захочется.

> **Choice 1: how you greet him**

- **A. Вежливо.** «Рад знакомству.»
  СЕДОВ: Спасибо, это приятно слышать, обычно здесь сначала спрашивают, кто за кем стоит.
- **B. С интересом.** «Какие вопросы вы решаете?»
  СЕДОВ: Разные, любые, какие не удаётся решить обычным способом.
  *(bond Sedov +1; he likes being asked)*
- **C. Холодно.** «Мне нужно знать, чем вы занимаетесь.»
  СЕДОВ: Правильно, вам действительно нужно это знать, значит, вы человек, который задаёт верные вопросы, и это, пожалуй, одновременно и опасно, и интересно.

*Он наливает всем, кроме Бориса Саввича. Тому наливает официант, не спрашивая.*

> **Choice 2: what he says about your week (the lines depend on flags)**

СЕДОВ: Мне говорили, что в среду вы выступали в Доме культуры.

- *If `spoke_sharply`:* СЕДОВ: Вы хорошо говорите, это немного опасно, но хорошо, я бы на вашем месте был чуть осторожнее с формулировками и с теми, кто их слушает.
- *If `asked_who_benefits`:* СЕДОВ: Вопрос хороший, ответ на него тоже есть, только не для зала.
- *If `spoke_softly`:* СЕДОВ: Вы осторожны, а в нашем деле это ценится.
- *If the player promised patrols:* СЕДОВ: Патрули, это смелое обещание, милиции придётся объяснить, зачем они нужны.

*Борис Саввич молчит. Это не молчание согласия. Это молчание человека, который давно решил, чего не слышит.*

БОРИС САВВИЧ: Он у нас языки знает. По-ихнему. С детства.

СЕДОВ: (поднимает глаза) Вот как, по-ихнему, это интересно, потому что у нас иногда бывают гости, которым важно, чтобы их поняли правильно, и чтобы они сами нас тоже поняли.

СЕДОВ: Пока ничего не нужно, просто запомните, что я об этом сказал.

> **Choice 3: closing**

- **«Запомню.»** → СЕДОВ: Хорошо, это уже половина разговора. *(flag `sedov_planted`: the side-job offer will come in week 2)*
- **«Я работаю в администрации. Больше ничем не занимаюсь.»** → СЕДОВ: Конечно, пока вы так и думаете. *(flag `sedov_planted`, bond Sedov −1; he is amused)*
- **Промолчать.** → *(neutral; the offer still comes)*

*Домой вас везёт Толик. Он включает радио, не громко. Не говорит ничего. Потом говорит:*

ТОЛИК: Ну что, посмотрели, где обедают?

*Вы киваете. Он больше не спрашивает.*

## Branch B: the reprimand (failed)

[Кабинет главы района, 18:00]

*Борис Саввич не встаёт.*

БОРИС САВВИЧ: Садись, я кричать не буду, я вообще не кричу, ты замечал? Кричат те, кому уже нечего терять.

БОРИС САВВИЧ: Дом не готов, комиссия это напишет, мне позвонят из мэрии, и я скажу, что у меня в районе новый помощник, и это будет не лучшее, что я говорил в жизни.

БОРИС САВВИЧ: Неделя была короткая, следующая будет длиннее, иди домой.

> No restaurant, no Sedov in week 1. The flag `sedov_planted` is not set; the side-job offer may come later by another route.

## Ending the week

[Общежитие, 22:30]

*Вы поднимаетесь на третий этаж. Сергеич храпит. С кухни пахнет чаем, там никого нет, только кружка на столе, чужая, мытая.*

*Квитанция на двери комнаты: аренда, 250 руб. Вы платите. Остаётся ровно столько, чтобы не думать о том, сколько осталось.*

> The week summary follows (see `docs/story/week1/README.md` for what threads carry into week 2: Sedov, Vera's article, Gusev's favour, the act, the first salary on Monday 1 September).

## Threads into week 2

- *Седов запомнил, что вы знаете язык.* (if branch A)
- *Вера ждёт ответа на свой вопрос про акт.* (if `vera_has_the_lead` or `act_declared` or `vera_notes_missing_page`)
- *Гусев ждёт, когда вы вспомните, что он вам помог.* (if the player chose him)
- *В понедельник первая зарплата: 1500 руб.*
- *Уголь с котельной уже кто-то считает.* (plants the week 2 coal action)

## Assumptions

- Sedov's first name and patronymic (Эдуард Павлович) are mine.
- The boss knows the player speaks the neighbouring language from the recommendation file, not from a conversation.
- The restaurant is the criminals' place but nobody is called a criminal; Tolik's silence and the guard are enough.
- The rent is charged at home as already described in the daily routine; the amount shown is the weekly 250 руб.

## Open

- Whether Branch B should offer a second, smaller road to Sedov (he approaches the player on Saturday).
