# Tuesday, part 2: finding Mikhalych (draft v0)

Tuesday 26 August 1997, about 09:00 to the afternoon. The player has a missing fitter and a dry boiler house. The scene is a conversation in a pub behind the market, then a short resolution (send him to Block 5). Mikhalych becomes the first assignable contact.

## Finding the pub (a map search, no scene)

> The `find_mikhalych` card appears on Tuesday 09:00. The player learns where to look in one of two ways, so the thread cannot be missed: from Baba Nina (flag `knows_pub`) or, if the player did not ask her, from a woman on the bench in front of Block 5 (unnamed, one line: «Михалыча ищете? У рынка, за палатками, там пивная без названия»). The pub has no name on the map, only a rusted sign with the letters missing.

**Hint under the card (tunable):** «Человеку с утра неплохо бы что-нибудь съесть.» *(nudges the player to the department store; if they already bought food, the item is used in the scene)*

## Scene. The pub without a name

[Пивная за рынком, 10:30]

> Conversation, about 1 hour. Backdrop: a low room, six tables, a bar, a TV that shows a boxing match without sound. Characters: **Mikhalych** (around sixty, heavy-set, grey walrus moustache, flat cap, padded work jacket, scarred hands, as in `init/assets/portraits/mikhalych.png`; shy, dry self-deprecating humor) and the owner **Semyonych** (a minor character; he has no other scene). Nina's advice, «приведите, не приказывайте», shapes the choices.

*Хозяин пивной, плотный, без шеи, вытирает стойку так, будто хочет стереть и её тоже.*

СЕМЁНЫЧ: Вам чего?

ВЫ: Михалыч у вас?

СЕМЁНЫЧ: Если Михалыча, забирайте. Он третий день платит вчерашним долгом и завтрашними обещаниями.

*В углу за столиком сидит человек в рабочей куртке. На столе пустая тарелка, стакан и ладони, лежащие рядом, как будто это не его ладони.*

МИХАЛЫЧ: Не про воду. Я знаю про воду.

> **Choice 1: how to approach him**

- **A. Мягко.** «Нина просила вас привести. Не приказывать.»
  МИХАЛЫЧ: (поднимает глаза) Нина... Она всё в тетрадь записывает. И меня, наверное, записала.
  *(bond Mikhalych +1; chance of the later repair 0.9)*
- **B. Твёрдо.** «Вы слесарь. В доме нет воды. Встали и пошли.»
  МИХАЛЫЧ: (встаёт) Пошёл. Командуете, как будто сами знаете, куда.
  *(bond Mikhalych −1; he comes, but resentful; chance of the repair 0.6)*
- **C. Накормить.** «Закажите себе нормально поесть. Я угощаю.»
  *(costs 25 руб at the bar, shown; or the food item bought earlier is used, which gives bond +2 instead of +1. Chance 0.9)*
  МИХАЛЫЧ: (долго смотрит на тарелку) Давно мне никто так не говорил.

> **Choice 2: what to ask (about 15 minutes each, any order)**

- **«Что случилось с осени?»**
  МИХАЛЫЧ: Зима была холодная. Вот и всё. *(if bond is 0 or lower; if bond is 1 or more, he adds)* ...Не здесь.
- **«Нина говорит, у вас золотые руки.»**
  МИХАЛЫЧ: Были. Я эту котельную знаю, как свою печень. Обе в плохом состоянии.
  *(bond Mikhalych +1)*
- **«Вы боитесь комиссии?»** *(visible only if the player heard about it from the boss, which everyone did)*
  МИХАЛЫЧ: Пусть ходит. Я там не нужен. Меня там нет.
  МИХАЛЫЧ: Ко мне осенью приходили. Двое. Вежливые. Чай пили. Ничего не сказали. Это хуже всего.
  *(flag `knows_polite_men`; he says nothing about the act)*

*Он допивает чай, который, как оказывается, всё это время был чаем.*

МИХАЛЫЧ: Пойдёмте. Только не быстро. Я давно не ходил по трезвому.

[Время идёт, 11:40]

## After the scene: the repair

> Mikhalych is now an introduced and assignable contact. The `send_mikhalych` option on the `hot_water` card opens. Repair work is 5 hours on site; the chance is set by the approach (0.9 or 0.6). If it succeeds, hot water returns around 17:00: residents standing up, the picket (if it escalated) ends. If it fails he sits down on the stairs, the card reopens and bond Mikhalych drops by 1; the player may send him again.

*К пяти часам по трубам прошёл звук, который в этом районе знают все: сначала кашель, потом шипение, потом вода.*

> The log line for the summary: «Михалыч починил трубу. В доме 5 горячая вода.»

## Effects (draft values, hidden)

| Choice | Bond Mikhalych | Residents | Other |
|---|---|---|---|
| A | +1 | 0 | chance 0.9 |
| B | −1 | 0 | chance 0.6 |
| C | +1 (+2 with the food item) | 0 | costs 25 руб |
| «Золотые руки» | +1 | 0 | none |
| «Комиссия» | 0 | 0 | flag `knows_polite_men` |

## Assumptions

- Mikhalych is not drunk in the scene; he is hungover and ashamed. The tea in the glass is the small reveal.
- "Two polite men" is all the player learns about the secret on Tuesday. The act appears on Thursday or Friday.
- The owner Semyonych is a one-off minor character.
- The department store hint is on the card, not forced: if the player pays at the bar they lose a little money, not the thread.

## Open

- The pub's map position (behind the market) and the reaction of the market vendors to a man in an administration coat.
