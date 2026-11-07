# Tuesday, part 3: Gusev and the first evening session (draft v0)

Tuesday 26 August 1997, afternoon and evening. Gusev introduces himself in reception (no envelope, no deal), the contractor conflict appears, and in the evening the player is offered the first training session.

## Scene 1. Gusev in reception

[Приёмная исполкома, 14:30]

> Conversation, about 45 minutes. Backdrop: reception, a bench, a poster about the heating season. Character: **Gusev**, about fifty, a builder who became a businessman: a leather jacket over a good shirt, a firm handshake, a smile that arrives before he does. Voice: friendly, expansive, generous with promises. No envelope; that offer is removed for now.

*В приёмной на скамейке сидит человек в кожаной куртке и читает «Речные вести», держа газету так, как держат документ.*

ГУСЕВ: Вы новенький? Гусев, строительная фирма «Стройремонт». Не за деньгами и не за просьбой, поверьте. Просто познакомиться. В нашем районе знакомство дороже денег, а стоит дешевле.

> **Choice 1: how you meet him**

- **A. Тепло.** «Рад знакомству. Слышал о вас.»
  ГУСЕВ: Слышали? Хорошее слышали или то, что про меня говорят? Это же разные вещи.
  *(bond Gusev +1)*
- **B. Сдержанно.** «Здравствуйте. По какому вопросу?»
  ГУСЕВ: По никакому. Редкая формулировка для приёмной.
  *(bond Gusev 0)*
- **C. Холодно.** «Без записи не принимаю.»
  ГУСЕВ: (смеётся) Я запишусь. Мне с вами ещё работать.
  *(bond Gusev −1)*

ГУСЕВ: Я вам вот что скажу, раз уж вы новенький. Подрядчиков на котельную двое. Я и ещё одна фирма, «Вершина». Они обещают дешевле. Но вы же понимаете, почему так дёшево.

> **Choice 2: what to ask (about 15 minutes each)**

- **«Почему дёшево?»**
  ГУСЕВ: Потому что на этой котельной работали до нас. Прошлой осенью. Работали, получили, уехали. Я не люблю говорить про других.
  ГУСЕВ: Но батареи у людей холодные, а деньги, получается, тёплые.
  *(flag `gusev_points_at_vershina`: the second route to the secret of the false repair, from the interested side)*
- **«Что за район?»**
  ГУСЕВ: Хороший район. Деньги тут не маленькие, но лежат в странных местах. Вы увидите.
- **«Чем могу быть полезен?»**
  ГУСЕВ: Ничем. Пока ничем. Пока.
  *(bond Gusev +1; a favour he will call in later)*

ГУСЕВ: (вставая) Заходите. Чаю не обещаю, а договор всегда найдётся.

*Он уходит, оставив на скамейке газету. Заголовок про Дом культуры подчёркнут карандашом.*

> At 15:00 the `contractor` card appears (conflict, deadline Thursday 20:00). The boss's briefing already mentioned it; Gusev's visit makes it personal.

## Scene 2. The first evening session

[Вечер, 18:00]

> The character drawer button appears on the right side for the first time. The player is offered one evening session (about 2 hours) from three activities; each adds one tick of progress. Level 1 needs two to three ticks and level 2 a further three to four (tuning values). The week has four evenings, Tuesday to Friday. The walk home is automatic now. No numbers are shown, only ticks.

*День кончился. В кабинете остались бумаги, дома остался Сергеич, а между ними два свободных часа.*

**Чем занять вечер?** (three cards)

- **Бумаги.** *Остаться в пустом кабинете и читать «Положение о жилищно-коммунальном хозяйстве». Читать его никто не любит, поэтому его всегда подписывают, не читая.*
  Hint: «Научит видеть в документах то, чего в них не хотели бы показывать».
- **Улица.** *Пойти во двор или в пивную и просто послушать. Что обсуждают, кто с кем здоров и кто с кем нет.*
  Hint: «Научит разговаривать с теми, кто не любит разговаривать с властью». *(costs a round at the pub, 20 руб, shown)*
- **Слово.** *Сесть с газетой и радио, повторить вслух то, что хотелось бы сказать завтра. Лучше вслух: так видно, где врёшь.*
  Hint: «Научит быть услышанным».

> Result of the first session: one tick, shown in the character drawer. A short caption confirms it: *«Вы почувствовали, что стало чуть легче. Впрочем, не факт.»* No other effect in week 1.

## Assumptions

- Gusev knows about the House of Culture meeting because he reads the paper; the pencil mark is atmosphere, not a plot point.
- "Вершина" is the other contractor, the one the mafia quietly backs; the player does not learn that yet.
- Gusev's help is a favour he will call in later (it feeds the Thursday decision).
- The pub round (20 руб) is the only cost of the training sessions in week 1.

## Open

- Whether the "Улица" session should be offered at the pub from Tuesday, or only after the player has been there once (Mikhalych).
