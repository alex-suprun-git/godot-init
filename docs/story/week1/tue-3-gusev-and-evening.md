# Tuesday, part 3: Gusev and the first evening session (draft v0)

Tuesday 26 August 1997, afternoon and evening. Gusev introduces himself in reception (no envelope, no deal), the contractor conflict appears, and in the evening the player is offered the first training session.

## Scene 1. Gusev in reception

[Приёмная исполкома, 14:30]

> Conversation, about 45 minutes. Backdrop: reception, a bench, a poster about the heating season. Character: **Gusev**, late thirties, a new 1990s businessman, as in his portrait (`init/assets/portraits/gusev.png`): a burgundy double-breasted jacket, a gold chain, a brick-sized mobile phone, a confident grin, a cheap expensive look; a firm handshake and a smile that arrives before he does. Voice: friendly, expansive, generous with promises. No envelope; that offer is removed for now.

*В приёмной на скамейке сидит человек в малиновом пиджаке, с телефоном размером с кирпич, и читает «Речные вести», держа газету так, как держат документ.*

ГУСЕВ: Здравствуйте, здравствуйте, вы, значит, новенький, мне про вас Борис Саввич говорил, ну, как говорил, он мне ничего не говорил, но я же всё слышу. Меня Гусев зовут, фирма «Стройремонт», вы не подумайте, мне от вас ничего не надо, честное слово, просто в нашем районе лучше знакомиться заранее, чем потом по телефону друг другу объяснять, кто ты такой.

> **Choice 1: how you meet him**

- **A. Тепло.** «Рад знакомству. Слышал о вас.»
  ГУСЕВ: Слышали? Ну, значит, хорошее слышали, плохое-то мне пока никто не успел рассказать, давайте мы с вами сразу про хорошее и будем.
  *(bond Gusev +1)*
- **B. Сдержанно.** «Здравствуйте. По какому вопросу?»
  ГУСЕВ: Да ни по какому, я же говорю, просто так зашёл, а то сидишь целый день в машине, с людьми не разговариваешь, одичаешь совсем.
  *(bond Gusev 0)*
- **C. Холодно.** «Без записи не принимаю.»
  ГУСЕВ: (смеётся) Да запишусь, запишусь, куда я денусь, мне же с вами ещё работать.
  *(bond Gusev −1)*

ГУСЕВ: Я вам вот что скажу, раз вы человек новый, на котельную нас двое, я и ещё одна фирма, «Вершина», они, конечно, дешевле просят, но вы же понимаете, почему они так дёшево просят.

> **Choice 2: what to ask (about 15 minutes each)**

- **«Почему дёшево?»**
  ГУСЕВ: Так потому что на этой котельной до нас уже работали, прошлой осенью, взяли деньги и уехали, я о людях плохо говорить не люблю, но батареи-то у людей холодные, а деньги, получается, тёплые.
  ГУСЕВ: Но батареи у людей холодные, а деньги, получается, тёплые.
  *(flag `gusev_points_at_vershina`: the second route to the secret of the false repair, from the interested side)*
- **«Что за район?»**
  ГУСЕВ: Район хороший, деньги тут есть, и немалые, только лежат они в таких местах, что сразу и не найдёшь, вы сами скоро увидите.
- **«Чем могу быть полезен?»**
  ГУСЕВ: Да чем вы мне можете быть полезны, пока ничем, ну а там посмотрим, жизнь длинная.
  *(bond Gusev +1; a favour he will call in later)*

ГУСЕВ: (вставая) Вы заходите, если что, чаю, правда, не обещаю, а вот договор у меня всегда найдётся.

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
