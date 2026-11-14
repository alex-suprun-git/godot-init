# 2D Grand Strategy — Godot Learning Project

A learning project for exploring Godot and gradually building an original 2D grand strategy game.

## What Chapter One Is

Chapter one is a political-career story on a living district map. In late August 1997 a newcomer arrives in a border city of a small fictional post-Soviet republic and becomes aide to the district head. The goal of the chapter is to become mayor; the long-term game it belongs to is a grand strategy (see "Long-Term Direction").

- **Loop.** A week is a cycle: planning (time stopped), a live week in which people move across the map and requests and crises appear, and a summary. The player acts through two verbs: *resolutions* (request cards: send people, spend money or reputation, make promises) and *conversations* (scenes that cost game time and build relationships).
- **Pressure.** Time is the main pressure. Money is scarce and the easy money is dirty. Reputation, both public standing with factions and personal bonds with people, is the currency of favors.
- **People.** The player is one person on the map. Contacts are people they know and owe; they have loyalty, secrets and their own working hours.
- **Tone.** Pragmatic realism with dark humor in 1997. There are no clean hands; the leitmotif is for whom you dirty them. Honest and corrupt paths are both viable.
- **Arc.** A peaceful arc (aide, district head, mayor), then a war in the neighbouring republic that spills over the border and changes what the first arc was about. The city and its people are the ledger of everything the player did.
- **State today.** A playable week-one prototype: an isometric district map built from 3D models with traffic and trains, a request and contact system, a weekly summary, a newspaper, dormitory routine and rent, audio, and dev tools (autoplay with screenshots, playtest logs). Week 1 is being rebuilt as arrival and introductions (see "Week 1 Redesign").
- **Where things live.** This README is the design canon. Map and district design: `docs/MAP_AND_DISTRICT.md`. Implementation notes: `docs/IMPLEMENTATION_NOTES.md`. Story scripts and writing rules: `docs/story/` (`GUIDE.md`). Task briefs: `tasks/`. Art: `art/`. Agent rules: `AGENTS.md`.

## Long-Term Direction

- Combine the broad civilizational development of *Civilization* with the geopolitical depth and simulation of *Hearts of Iron IV*.
- Use Pax Historia as an inspiration point for an alternate-history sandbox, not as a design to copy.
- For the long-term game the gameplay loop, eras, map, and victory conditions are still open design questions; chapter one fixes them for its own scope (see above).

## Setting and Tone (Provisional)

- This campaign is the first chapter of the larger grand strategy game.
- Setting: a fictional city in a small fictional Slavic post-Soviet republic during the 1990s, with the full mix of the era: some good and a lot of rot. Society is deeply divided, but there is no civil war in our country. A war breaks out in the neighboring republic later (see Story Arc).
- The outside world is background context in the first chapter, with quiet foreshadowing of the later war (see Story Arc). The starting city is a border city, so neighboring states become an active factor in the war chapter.
- The first chapter takes place in the 1990s: it starts in late August 1997 and ends by the year 2000 at the latest.
- The starting city has about 250,000–300,000 inhabitants, large enough to support many mechanics and factions.
- Tone: in the first chapter, pragmatic realism with dark humor, not grim horror. The tone changes radically when the war reaches the city (see Story Arc).
- The protagonist is a specific person with a biography, motivation, and voice, as in *Suzerain*; the player makes the decisions, with no morality meter. The hero may react to what was done in their own inner lines without the game judging it. The concrete biography is still open. Questions to answer first, derived from the leitmotif:
  - For whom is he ready to dirty his hands at the start: family, a specific person, the city?
  - What in his past makes him a clean slate for the boss?
  - What is he most afraid to lose?
  - The answers define his circle and who can become a witness.
- Core fantasy: climbing to power and reshaping the system according to the player's own vision, with methods the player chooses.

## The City (Provisional)

A border trade city on a river that lives on trade and transit rather than on a dying factory.

- River port and a bridge crossing the border: the city's main artery and main source of illicit income (customs, trucks, smuggling).
- A clothing market directly beside the railway station, where traders, the mafia, police and ordinary people meet. The station hub's design and its 3D implementation notes are in `docs/MAP_AND_DISTRICT.md`.
- An old center with merchant houses and a cathedral, so the city has real visual beauty, not only gray.
- The long northern reserve between the highway and north street is a wheat field (details in `docs/MAP_AND_DISTRICT.md`).
- Soviet housing estates and one factory on the verge of closing: background and a source of social tension, not the face of the city.
- River, embankment, and suburban dachas with forest: space for decisions such as clearing forest for a new housing block.
- Visual contrast is the signature look: beautiful old buildings next to kiosks, advertising, and new gangster mansions. The 1990s without grim horror.
- The former city-park parcel (`city_park`, behind the department store) holds the private restaurant-club with its own secured grounds (see `docs/MAP_AND_DISTRICT.md`).
- The border adds colour in the first chapter (smuggling) and becomes a sharper factor at the mayor stage.

## Factions (Provisional)

| Faction | Wants | Leverage |
|---|---|---|
| Ordinary people | Wages, heating, order, to be left alone | Pickets, votes, rumors |
| Police | Their cut, budget, no interference | Inspections, looking the other way or not |
| Church | Land, buildings, moral authority | Influence over the elderly and society, public endorsement |
| Business | Land, permits, tax breaks, protection | Money, jobs, connections higher up |
| Mafia | Control of the market and the border | Threats, money, "solving problems" |

- Superiors (district head, city hall) and the press are pressure forces but do not need to be full factions in the first prototype. Superiors set objectives and deadlines; the press amplifies any event and is a key tool for the rival.
- Factions become interesting when their interests collide on the same place. For example, the market matters to the mafia, business, police, and ordinary people at once, so any decision about it offends someone.

## Rival (Provisional)

- An old party apparatchik from another district who competes with the player for the mayor's office. The central theme is new versus old.
- They know every connection, are an experienced schemer, and act mainly through superiors and the police.
- On the map: their district changes visibly, requests the player is too slow on get intercepted by them, press scandals about the player appear, and they occasionally offer a deal.
- Their character and motives can be deepened later.

## Career Paths (Provisional)

- The player starts as an aide to the district head, hired for their qualities as a clean slate. The boss does not involve them in shady dealings from day one.
- Each career stage widens the player's world, which is what makes stages feel different beyond scale:
  - Aide: ordinary residents and workers from day one; the church and business only in rare, one-off episodes. The boss assigns tasks that cannot be solved by the book, and the player learns "the street": the system does not work as written, and the boss only cares that the issue is closed.
  - District head: the mafia and everything tied to it come into play directly.
- The boss, the district head, is a tired cynic: once idealistic, now just holding on until retirement and covering himself. Not evil; "that's just how things work". His more human side is revealed gradually, which makes removing him more dramatic.
- Starting resources of an aide: reputation initially comes from the boss's name and cannot be abused without the boss noticing. The salary is close to nothing; real money comes mostly through gray channels (envelopes, kickbacks, favors). Without money tasks are hard, and the only easy money is dirty.
- The honest path must be genuinely viable. Balancing it is a key design priority: it works through people, relationships, and promises rather than money.
- The honest path has strengths the corrupt path cannot buy:
  - People's trust as a resource: residents help on their own (for example, fixing their building's entrance) when the player keeps their word, replacing money for small tasks.
  - People tell the player things: pieces of compromising material come to an honest official for free, while a corrupt one has to buy them.
  - No traces: the rival finds little to build a dossier on, a major advantage late in the chapter.
  - The press is more willing to back an honest official.
  - Popular support decides the mayoral election, where money helps less than with appointments.
- Resulting asymmetry: the corrupt path is fast early but accumulates vulnerability; the honest path stalls early but becomes nearly untouchable by the end. Trust must still be earned; it does not come automatically.
- To become district head, something must happen to the current boss, and the player should have several ways to make that happen. Candidate paths:
  - Do the boss's work while quietly digging under them; the work builds connections at every level, and reputation unlocks access to valuable information and people.
  - Make a deal with the mafia to remove the boss, then win the snap election with residents' support.
  - Dig up compromising material so the boss is arrested, then win the election.
  - Help the boss become mayor and receive the district post as a reward.
- Release version of the first chapter: the player chooses a starting district for replayability. Prototype: one district, the most eventful one, tuned for the demo.

## Core Loop: People on the Map (Provisional)

- The core gameplay is allocating the player and their contacts across the city map, not answering dialog windows. The map is the main interface, not a backdrop.
- The player is physically somewhere on the map and can only be in one place at a time. Showing up in person is slower but carries more weight than sending someone.
- Contacts are people the player knows (for example, a plumber, a beat cop, a journalist, a driver), not subordinates. They help because the player owes them or they owe the player, so every favor is a debt, in line with promises and traces.
- Contacts are alive: they have loyalty, can be bought by the rival, can leave traces or betray the player. The network grows with the career and reflects the player's history.
- Each contact has their own dialog and a relationship that can be developed, unlocking new help.
- A request is resolved by sending people, money, or a promise to its location. Travel takes time, and busy people cannot be used elsewhere. Results show on the map.
- Weekly cycle on this model: planning is scheduling on the map (where the player goes, whom to send where, where to place promises); the live week shows people moving and doing their jobs, and crises force reassignments; the summary shows changes on the map rather than walls of text.
- At the start of a week, an important authored message can appear as a short portrait dialog or a newspaper-style notice, followed by a large, dismissible task board. The board keeps weekly objectives clear and puts promises, faction standing, and the event log in separate tabs; the player can reopen it from the map.
- All contacts are listed in a left-side drawer opened with "Связи"; it slides from the button's side with a short background fade. Availability has a green lamp for free, amber for busy/travelling, and red for unavailable. Only contacts travelling on an assignment, working, or driving appear as compact photos in the bottom dock. Selecting a person opens their role, full status, and a map focus action without keeping a large character card on screen. Availability is data-driven per character (Mikhalych: 08:00–18:00). Outside these hours a contact is absent from the map and paths, has a temporary red status mark on their card, and cannot be assigned or focused on the map. Work or travel stops at the end of availability; the request reopens, while remaining on-site hours are kept per solution in the request. The next availability window makes the contact free, without automatically resuming; the player must assign them again and allow for travel time. Completion effects roll once the remaining work is finished; a failed attempt that reopens a request starts a fresh attempt. Focused development capture: `--autoplay --only=contacts`.
- Interface: the map is the main interface. The approved UI direction is "Living Chancellery" (cream paper, warm graphite, burgundy ink) with a headline-led newspaper; contacts open in a left drawer and weekly tasks live in a work folder. Design decisions and implementation details are in `docs/IMPLEMENTATION_NOTES.md`.
- Calls: a phone call is fast but only works from the office and only with strong contacts; a visit is slower but stronger. A mobile phone (rare and a status symbol in 1997–98) is a career reward that allows calls from anywhere; a pager may be an intermediate step.
- Conversations are the second pillar next to the map: scene-based talks on a painted location backdrop that cost game time, build bonds, widen the contact network and unlock information (see "Week 1 Redesign"). Not every call or quest is a conversation. Rare key story moments (the boss, the meeting of accomplices, deals with the rival) remain short cutscene-like dialogs.
- Each week is a self-contained run: urgency and timers live within one working or calendar week, together with NPC interactions.
- Map changes:
  - Instant: sudden events such as a fire, a picket, or an accident appear in the middle of the week as overlays.
  - Gradual: slow changes such as a new housing block change lot states only between weeks, at the start of the next week, alongside the consequences of the previous one. Long projects pass through visible intermediate stages over several weeks (fence, foundation, frame) rather than appearing out of nowhere.
  - Scheduled operating states: ATP access is open from 06:00 until 20:00 and closed overnight. A location-state component drives the gate leaves, wicket and boom arms with a two-second visual transition. Schedules are separate data; an event may temporarily override the scheduled state, then return control to it. This is a visual-state prototype, without new navigation restrictions or depot traffic behavior. The same visible game clock drives lighting and scheduled state, including the overnight transition.
- Provisional target: about 35–40 weeks per chapter at roughly 3–4 minutes each. Exact numbers are tuned in the prototype, and day length is a configuration value.
- Prototype pacing: at ×1, one game hour takes four real seconds (64 seconds per 06:00–22:00 day; five minutes twenty seconds per five-day live week, excluding pauses and overtime). ×2 and ×4 multiply that simulation rate; pause stops it. The base rate and supported speeds live in `init/scripts/data/settings.gd`.
- During the live week, Space toggles pause and resumes the last selected running speed, including after a crisis pauses the game. Holding Space does not repeatedly toggle it.
- The shift to this core loop needs deliberate balancing.

- Office workload: alongside direct assignments from the boss, the protagonist has a recurring activity, "Работа с документами" (paperwork), requiring 20 hours per week at the administration as an initial balance setting. Start/pause it from the map control or weekly folder; completed hours persist across interruptions and nights, and the quota resets for a new week. Calls and dispatching available contacts remain possible while working; attending a request personally requires pausing first. The office control also allows walking back from another location. At 22:00 paperwork is automatically put aside and the protagonist goes home; authored personal visits still finish in overtime. An unfinished quota at the end of Friday costs 10 boss standing (provisional balance); meeting it fulfills the duty without a bonus. Work is personal in the opening demo; delegation unlocks later, with conditions still undecided. No separate weekly paperwork stories are needed yet. Other requests remain voluntary opportunities for money, reputation or kindness unless explicitly assigned by the boss. Focused development capture: `--autoplay --only=paperwork`.

## Player Mobility and Personal Money (Provisional)

Mobility and money are both scarce for a junior aide, which is part of what makes the map matter.

The opening starts with no contacts: the protagonist is the only newcomer. Contacts are introduced in person (Baba Nina on Monday and Mikhalych on Tuesday of week 1) and only then become assignable; "introduced" and "assignable" are separate states, and an unintroduced person has no map token or dispatch choices. See "Week 1 Redesign: Arrival and Introductions".

Tolik appears in week 1 only in the arrival drive (introduction only) and returns as a driver in week 2. Until then he stays disabled through his actor `enabled` flag, not removed: absent from contacts, map tokens and request choices, and unable to drive the protagonist automatically. His data and driving logic remain for later relationship mechanics. Player walking pace is calibrated to 15 game minutes from the administration to House 5: 707.68 map metres per game hour on the current 176.92 m route. All other walks use the same speed and their actual route length, without added travel time. Quest work duration is separate and should follow the activity: tea with the priest now takes 1.5 hours; other existing quest durations still need review. One game hour still takes 4 real seconds at ×1; clock pacing is unchanged.

- **Transport is a privilege, not a default.** The protagonist starts on foot or with a bicycle. The black Volga belongs to the boss. The administration's driver (Tolik) drives the boss and only gives the player a lift when the player has earned some goodwill and the Volga is free.
  - Modes: on foot, bicycle (about twice as fast, can use yard paths), bus (stops, fixed routes, waiting), taxi (paid, fast), a lift from Tolik (free, conditional).
  - The boss's car is busy in random time windows (not an authored schedule). A lift is possible only outside a window and with enough standing with the boss; the exact threshold is tuned in the prototype.
- **Sending people works only from the executive committee** (the office phone), as already stated in the calls rule above. There are no payphones. Away from the office the player can act only in person. Results of people already sent and new requests are visible at once; that is a game convention, not a rule to simulate. Mobile phones and pagers remain career rewards that lift the office restriction.
- **Personal money.** The player has a small personal reserve, shown plainly in the UI. Unlike reputation, the player cannot yet take from the budget, so money is scarce and bribes carry real weight.
  - Money sinks: taxi fares (the fare is shown before the player chooses, an explicit exception to the rule that numbers stay hidden), bribes the story requires (some situations can only be settled with a payoff, or offer it as an option), and weekly dormitory rent: 250 rubles, automatically charged on Friday after returning home.
  - Income: 1,500 rubles once a month, on the 1st (the next playable weekday if the date falls on a skipped weekend). The starting reserve is 1,200 rubles. Amounts are provisional balance settings; all money uses stable fictional rubles, without denomination changes.
  - Unpaid rent is recorded as debt when the reserve is insufficient. Collector pressure and ways to repay arrears remain planned, not implemented.
  - The protagonist initially lives in the western dormitory; a better room is a possible long-term money sink, not part of the first prototype.
- Future idea, not in the first prototype: poor standing has consequences for the bicycle. Each key building has its own resident person or group (guards, regulars, local toughs). If the player's standing with a faction is very bad and they arrive there by bicycle, there is a chance the bicycle is damaged or stolen, with a mocking note left behind, and the player pays for repair or a new one. The player is warned once, in advance and separately (a contact's remark, a message, a newspaper note), when standing drops to a dangerous level. There are no repeated warnings at the building itself: the player is expected to remember and decide.
- The map is deliberately large and slow so that travel and waiting carry the weight of every decision (see Starting District Layout).

## Player Actions and Requests (Provisional)

- Besides answering requests, the player can act on their own initiative: call the right person (spend reputation by calling in a favor), give or take a bribe (money), arrange a meeting between two sides (compromise), leak information to the press, and make promises.
- Promises are the signature mechanic: they cost nothing now and become a debt later. Broken promises surface as consequences on the map, such as pickets.
- At most 3–4 requests are active on the map at the same time.
- How long a request stays open follows from its situation, not from a hand-set date. Each request has an urgency class:
  - Now (about 3 hours): people stand on the spot and wait (a conflict at the market, coal being stolen, a visitor in the office).
  - Today (until 20:00): a deal that goes to someone else in the evening (the storekeeper's fuel, Gusev's stalls, a meeting tonight).
  - Days (about two days): a complaint that can wait (the pipes, the church).
  - Week (until Friday): the week's tasks (the contractor, the report).
- The request card states the fiction, not a bare time: "Waiting for you at the station, about 3 h left" rather than "until Fri 12:00".
- Requests that can wait escalate while unanswered instead of only expiring: the pipe complaint turns into a letter to the newspaper and then a picket. Waiting is allowed but grows more expensive. A promise pauses a request's deadline and escalation until the promised date.
- Shared request framework: `week1.gd` declares content and `week_sim.gd` applies common rules. Requests pass through waiting, travel, work on site, optional interruption and a result. The reaction deadline continues during travel and is satisfied on arrival; work then has its own duration. Arrival removes the waiting marker and countdown; an interrupted job reappears for manual reassignment without restarting the satisfied reaction deadline. Missing the deadline en route applies the expiry consequence; the trip finishes without starting quest work. Promise deadlines remain separate commitments. Zero-hour personal choices can require an explicit location and resolve immediately there. Optional requests can be disabled through `enabled: false`; the fuel-depot offer is disabled pending redesign because travelling merely to refuse it and rewarding residents for that refusal do not provide meaningful gameplay.
- Urgent requests combine with the office-only dispatch rule: leaving the office means missing what is urgent, which is the price of going out.
- Request types:
  - Plea: a person or group asks for help; ignoring it hurts the relationship.
  - Conflict: two sides clash and the player picks one; someone is always offended.
  - Crisis: a timer runs; missing it has serious consequences such as fires, accidents, or riots.
  - Offer: someone proposes a deal, money, or an alliance; the player may refuse.

## Week Summary (Provisional)

The end-of-week summary is organized, not a chronological wall of text. The outcome texts themselves stay short and flavorful.

1. Top: relations. A compact strip of faction standings with their direction this week (for example "Residents: Distrust → Discontent, down").
2. Middle: what happened, grouped by place on the map, not by time. Each line is marked done, missed, or escalated. The weightiest come first; minor items collapse into "and N minor things".
3. Bottom: threads into next week. What is unfinished and will come back (a stalled boiler house, a remembered license plate, stalls Gusev set up on his own, an open promise).

A boss's one-line reaction with portrait and a newspaper clipping when the press wrote about the player are planned accents. Later, the middle list can become pins on the map with the same grouping.

## Compromising Material (Provisional)

- Connections are part of reputation, not a separate resource.
- Compromising material is not a currency but a rare, concrete item about a specific person, such as a faction leader or the player's boss.
- It works like an ultimate ability: assembled slowly and painstakingly from several pieces, then used once for a big effect (arrest, blackmail, a press scandal), not as a small bonus in negotiations.
- A dossier on one person consists of 3–4 pieces (a witness, a document, a photo, accounting records). Pieces come from contacts, request rewards, risky actions, or events.
- Ways to use a complete dossier:
  - Leak it to the press: loud, the target falls, but the press may turn on the player too.
  - Hand it to the police or prosecutors: the target is removed, but the player needs their own people there.
  - Blackmail: the target stays in place and works for the player, but will never forgive it.
- It works both ways: the rival is also building a dossier on the player. The player sees hints but does not know how much the rival has. Because promotion requires being active rather than lying low, this pressure keeps growing over time.
- Open: how a target notices the player digging and reacts (striking first, covering tracks). This needs its own mechanic.

## Story Arc (Provisional)

The campaign has a peaceful arc and a war arc, and the second changes what the first was about. The turn is far into the story.

- **Peaceful arc: a decent city.** By the standards of the 1990s the city is good. It is full of decent, kind people. There are kickbacks, there are thugs, and people live poorly, but in other regions things are far worse and here it is stable. Its tone is pragmatic realism with dark humor.
  - Chapter one: the climb from aide to mayor, with the heating season as the opening (this document).
  - Chapter two: the player is mayor and passes a series of smaller crises (to be written separately). The player may come to think the hard part is over.
- **The turn: near the end of chapter two.** Then the war comes. The rival and the boss are resolved before this point and are not part of the turn.
- **Foreshadowing is gradual,** never a sudden jump: press items, radio, the first refugees, border incidents, building up well before the turn. It can start as early as chapter one.
  - Border side quests and events later in the peaceful arc (odd cargo at customs, unusual buyers, quiet deals around weapon stocks) hint that someone is preparing for something. They read as ordinary 1990s border business at the time and make sense only in hindsight.
- **War chapter: a separate chapter.** A war starts in the neighboring "brotherly" republic. Our country officially stays neutral, but the border city is hit hard.
  - Spillover, not a front line: a migration crisis, smuggling (weapons and worse), and random strikes.
  - Some forces profit from the war. Our country has large stocks of weapons and ammunition and even factories, so there is money in selling them.
  - The player is the mayor or even governs the region. This is a different scene with different emphases from the district-level game, not a soldier's view of the front.
  - The tone changes radically. There will be genuinely heavy scenes of the border region at war.
  - The war changes the player and the hero, above all their choices and their role in events.
- **Complicity.** The war's machinery is partly assembled by the player during the peaceful chapters: weapon stocks they ignored, smugglers they spared, a customs officer they promoted, money they took. The border hints of the peaceful arc are the player's own compromises coming back.
- **Dirty choices during play, not only at the end.** Situations repeatedly force a choice about people who know too much. An honest option exists in every situation, but not in all of them at once; some wrongdoing over the arc is unavoidable. Example: kill a worker who might talk and ruin everyone in the player's circle, or brutally frighten him into leaving the country.
- **The truth always surfaces later.** What the player tried to bury comes out regardless. Choices do not decide whether it surfaces; they decide the moral context, relationships, and who pays the price.
- **Dirty work spreads complicity.** The player can do it personally (present, exposed) or send a contact. A contact sent to do it becomes a witness and an accomplice too, so dirt spreads through the player's circle systemically, through the same "whom to send where" loop.
- **The war chapter is the big test.** Almost everything there is dirty. The real choice is for whose good: one's own and one's circle, or the common good. There are always people who will not support the player.
- **Agency.** The player cannot stop or prevent the war. They shape what kind of city meets it and who survives.
- **Losses follow choices.** Losses depend on the player's earlier choices and relationships, not on scripted deaths alone. Contacts are persistent, as in the core loop, so the city and its people carry the drama.
- **Why the district map fits.** The checkpoint, port, bridges, freight station, and truck stop that drive peacetime smuggling are the same places that carry refugees, arms, and strikes in the war. Lot states (market to refugee camp, school to shelter, reserve block to tent camp) show the change on the map.
- **After the war: the ending.** If the player comes through the war crises well, many forces stand behind them, and the way opens to the top, possibly head of state. There is no planned gameplay between leading a city or region and leading the country. The game may end on the hero's choice, and both outcomes are tragic and dignified:
  - Accept: the hero can do a lot of good (for whom is beside the point), but blood will be spilled.
  - Refuse and stay: sooner or later the sharks devour him. Perhaps deservedly.
  - Staying a hero in the eyes of the region and the country may require removing the witnesses of his dark deeds, most of them scum by then. Where the line is, is the question. The game may end abruptly at that moment, in the spirit of Outlast's *Whistleblower*.
- **The city is the ledger.** Because the truth always surfaces and both endings are tragic, the difference between playthroughs lives in the city and its people: who survived, who stayed close, who curses the player, who left, what was built and what it became in the war. This is why the city map, its residents per building, its condition layers, and its lot states matter so much: the map carries the consequences of the whole game.
- **Leitmotif:** there are no clean hands; the question is for whom you dirty them.
- **Story scenes** are sequences of still paintings in the window-art oil manner with text, not animated cutscenes. Voice acting is deferred; if added later, only for a few key moments and only if the quality holds.
- **Open:** exact calendar dates of chapter two and the turn. The first chapter still ends by 2000 at the latest.

## Endings and Pacing (Provisional)

- Victory: the player becomes mayor, and the kind of mayor depends on the path: the mafia's man, business's puppet, the people's mayor, or a puppet of superiors.
- Defeat: a missed deadline, the rival winning, or being removed (arrest, disgraceful resignation, or, in the 1990s, physically).
- A playthrough of the first chapter lasts about 2–3 hours. Artificial grinding is not a goal.
- Time follows a weekly hybrid cycle, inspired by *This Is the Police* and *Papers, Please*:
  - Planning phase: time is stopped. The player reads the summary, makes important decisions, and hands out promises.
  - Live phase: the week plays out in real time (with pause and speed-up). The city lives, and crises pop up that need quick answers.
  - Summary: the results of the week, including consequences that arrived.
- Risk: weeks can feel monotonous if they are too similar, so authored events, deadlines, and crises must vary their rhythm.
- Daily routine: the playable day starts at 06:00 at the protagonist's dormitory in the western housing reserve. The newspaper appears automatically only at the beginning of the week; there is no other morning menu yet. From Tuesday the protagonist automatically walks to the administration in time for 08:00 (an encounter can interrupt the walk); on Monday of week 1 the day instead begins with the train, Tolik's drive and the wait for the boss (see "Week 1 Redesign"). The boss's briefing and weekly assignments first appear when the boss arrives. Official duty runs 08:00–18:00; the evening remains available until 22:00. At 22:00 new actions are blocked, but a personal job already underway, including travel to it, finishes in overtime before the automatic walk home. Only after arriving at the dormitory does the day end and the next-day calendar appear; Friday rent is charged then, before the week summary. The next morning begins at home at 06:00. Contacts follow their own availability hours; when those hours end, assignments are interrupted and require manual reassignment, with completed on-site work preserved. The dormitory now uses an original four-storey L-shaped Blender model with an entrance court, physical window frames, a canopy and a Cyrillic sign. The compact 38 × 45 m compound sits beside west street; the hero starts at its entrance, with the camera centered there immediately. Sources and visual review: `art/models/dormitory/README.md`. Focused development capture: `--autoplay --only=routine`.
- Lighting follows the clock and the season (sunrise and sunset differ by season); windows and street lamps light up at dusk. Purely visual for now.
- The top-bar "Заново" button restarts the entire simulation at the first Monday, 06:00, resetting progress while retaining the selected season and camera mode.
- Feeling the city and the player's impact on it matters more than covering many calendar years. The first chapter therefore covers a short period of about 1–2 years, ending by 2000 at the latest. It starts in late August 1997; the end date is open.
- The protagonist has three trainable skills (documents, street, speech) and a fixed translator trait (see "Week 1 Redesign"). Further stats or perks are undecided.

## City and District (Summary)

The first chapter is played in one outskirts district of the city, not in its centre. The full design (city map, far-bank city, lot grid, village, civic area, visual rules) is in `docs/MAP_AND_DISTRICT.md`.

- The district lives on transport, the border and trade: a border crossing with customs, the river port, the railway junction, a bus and truck depot, a truck stop, and a spontaneous market beside the station.
- History in layers: an old village by the river with a church came first, then the port and railway, then late-1980s panel housing for their workers. In the 1990s parking lots, trading and warehouses grew around the flows of people and goods.
- The village overhaul is approved in game: 29 complete 3D household parcels, a shared church/cemetery ensemble and public pond paths. Ground layout is 10% smaller in area while building dimensions remain unchanged; detailed records live in `docs/MAP_AND_DISTRICT.md` and the asset READMEs.
- North to south: the neighbouring country, the border river with a road and a railway bridge, a transport band along the embankment, a highway, a reserve band (boiler house, garages), four residential superblocks, the civic axis from the checkpoint to the station, and the old village to the east.
- The district executive committee is a late-Soviet modernist building, one block inland from the river. The protagonist lives in a dormitory on the western edge.
- The map is built from fixed lots; unique buildings are added by changing what stands on a lot, not by moving the layout.
- Condition differs by layer and is a visual rule: panel housing intact, transport and industry worn by use, the village slowly emptying, some plots left unfinished.
- The map is deliberately large and slow, so travel and waiting carry the weight of every decision.

## Opening Scenario (Provisional)

The first stretch of the game is built around one concrete 1990s objective: the heating season.

- Setup: late August 1997, about seven weeks before the deadline. The boss, the district head, orders the player to have the district ready for heating by October 15, when a city commission will inspect it. Failing is not an option. This is the first objective with a deadline.
- Every faction has a stake: residents fear another winter in coats; business wants the fuel oil supply and boiler repair contracts; the mafia steals fuel oil and wants its own contractor; the police protect the fuel depot; the church asks to heat the cathedral or open a shelter.
- Week 1 itself (the order of days, requests and introductions) is described in "Week 1 Redesign: Arrival and Introductions". The earlier plan of one taught mechanic per request on day one no longer applies; the envelope offer is removed, and the rival's TV appearance is deferred without a date.
- About ten days later, consequences show on the map: repairs at the boiler house or an abandoned construction site; unhappy residents gathering as the promised date nears; a newspaper note hinting that someone is interested in the player's affairs.
- Early October: the first trial run of the heating system bursts a pipe at Block 5, a crisis (art: `init/assets/events/pipe_burst.png`). Week one needs its own late-summer crisis; it is undecided.
- Seasons move visibly through the opening: summer greenery with the first yellow leaves in late August, heavy leaf fall by October.
- Hidden hook: the boss is taking a kickback on the fuel oil contract. This is the player's first chance to start digging under the boss, quietly opening the compromising-material path without telling the player directly.
- This scenario is also the content of the first prototype: one objective, a handful of requests, faction relationships, and visible map changes.

## Week 1 Redesign: Arrival and Introductions (Provisional, 2026-11-07)

Week 1 is the player's first week in the district, so the story is rebuilt as "the new man arrives and meets people", not as a day of request mechanics. There is no tutorial; the story and the people carry the introduction. The heating-season objective and the boss's core brief stay.

- **Two verbs.** A *resolution* is the existing request card (choose a position or send people; costs money, reputation or contact time). A *conversation* is a visual-novel scene: a painted 2D location backdrop, the character(s) and a dialogue the player steers. Conversations cost the player game time (a time skip behind the scene) and build relationships, widen the contact network and unlock information and story. Not every call or quest is a conversation; most requests stay resolutions. Conversation length and time cost are tuning values (starting range 0.5–2 game hours). This refines "dialogs remain rare" in the Core Loop section: the map is still the main interface, conversations are the second pillar.
- **Personal involvement.** In the first weeks the player does everything in person and meets every character before using them; "send Mikhalych" only becomes available after the introduction. Delegation comes later.
- **Monday.**
  1. 06:00, the player arrives by electric train and reads the opening newspaper on the train (the newspaper is the prologue; it is no longer a morning shortcut).
  2. Tolik, the administration driver, meets them at the station and drives a long scenic route around the district while briefly explaining the situation (narration only), then leaves them at the boss's door. Tolik is introduction-only for now.
  3. Work starts around 10:00. The boss's opening monologue is rewritten for "the new man", keeping its core (heating ready by October 15). The weekly requests are the existing ones, starting later in the game day.
  4. The envelope offer is removed for now. Gusev (the businessman) is introduced as a person first.
  5. Heating complaint arrives (Block 5, no hot water). Mikhalych the plumber is nowhere to be found, so the player talks to the residents; Baba Nina, the most active one, tells them (with a story hint) that he is on a drinking spree. This is the first conversation and the first contact lead.
  6. Evening: going home is itself a quest. The player picks the transport icon and travels to the dormitory, where they meet the young neighbour in a conversation instead of a plain check-in. Romance is a possible later thread.
- **The neighbour is a journalist,** but neither knows the other's role at the dormitory. On Tuesday, on the way to the executive committee, she turns up in front of the building as the press; the player recognises her.
- **The week by day** (requests keep their ids from `week1.gd`; times are targets, not final):

| Day | Story and conversations | Resolutions |
|---|---|---|
| Mon | Train, Tolik's drive, the boss, Block 5 and Baba Nina, the dormitory neighbour | `hot_water` appears |
| Tue | Journalist outside the executive committee; the search for Mikhalych (pub), getting him out of it; Gusev introduces himself in reception | `hot_water` can be fixed once Mikhalych is back; `contractor` appears (deadline Thursday) |
| Wed | Father Georgy in the morning: visit with conversation; the station square in the afternoon (kiosk story, part 1) | `church_heat`, `market_cops`; `residents_meeting` in the evening (in the House of Culture; topic: the rising criminal showdowns on the district's border, where the outsider protagonist is given the floor) |
| Thu | "Gusev day": his wasteland kiosks and the contractor decision fall on the same day and interact (giving him both is a trade-off) | `wasteland_stalls`; `contractor` deadline |
| Fri | The inspection (noon), the journalist is present; the report to the boss in the evening | Inspection chain finishes; `boss_report` as a short task; week summary |

- **The kiosk story** merges `market_cops` (vendors and police at the station square) and `wasteland_stalls` (Gusev wants kiosks on the wasteland) into one chain: moving stalls to the wasteland helps Gusev and takes money from the police, and the vendors lose their spot at the square. Week 1 adds no new named characters for it: Gusev carries the conversation side, and vendors and police act through the existing request cards. Details are still to be written.
- **The journalist's thread:** Tuesday's surprise leads to a short interview; what the player tells her in conversations during the week, and what they did in resolutions, shapes her Friday article, which appears in the newspaper through `press_history`. She is present at Friday's inspection and her article is the payoff, not a cold call. Her professional interest and the romance pull against each other.
- **Week 2 (preview):** `coal_theft` and the fuel-oil offer (`fuel_offer`) move there. The coal quest becomes an action sequence on the map: the truck drives out of the boiler house along real roads, and the player intercepts it, follows it to the buyer or lets it go (blocking with a car, calling the police, tailing, photographing). Tolik returns as the driver for it. This needs a design pass and a prototype before it counts as decided.
- **Tuesday and later** are more everyday: the walk to the administration is automatic, but an automatic walk can be interrupted by an encounter (the journalist is the first one).
- **Week 1 cast to introduce:** Mikhalych, Baba Nina, the boss, the journalist, Gusev. The priest keeps his visit-with-conversation scene; he is a guest, not yet a contact.
- **Contacts** are people the player has built enough relationship with through conversations. Who is a contact by the end of week 1 is open (Mikhalych and Nina, with the journalist possibly third); the coal-theft crisis moves to week 2, when the player has two or more contacts and a different set of requests (to be defined).
- **Tolik's drive** starts with a short meeting outside the station while the electric train stands at the platform. The camera follows one continuous drive from the station to the executive committee at traffic speed, with dialogue and camera emphasis cued along the route. Tolik passes the market, dormitory, industrial sites, checkpoint and restaurant. He crosses the village from west to east, turns south and approaches the executive committee from the south along the avenue.
- **The inspection is the week's main quest,** a multi-part chain across the week, not a single morning. On Thursday the boss announces that a representative of the city heating commission (an engineer, one new character, appearing only on Friday) will inspect Block 5 on Friday at noon. The minimum is a working heating repair; a few more parts are realistic but tight (paperwork from 1996 including Mikhalych's signature, the contractor decision, delivery or installation of parts, keeping the residents calm). Some parts may only be achievable by paying NPCs from the player's own pocket (to bring or install something). Outcomes: passed, passed at a price, or failed; the journalist's article reflects what was shown or hidden. The report to the boss is a short separate task with reduced required hours so it stays achievable; if the player covered for the boss, the report becomes an invitation to the restaurant seen on Monday's drive (the criminals' place), otherwise the old reprimand call. The required hours of the chain must fit the week's free hours with some slack; exact numbers are tuned in the prototype.
- **Money and the side job (Provisional).** The protagonist is poor, lives in a shared dormitory room and has to hustle. His marketable skill is **translator** (language of the neighbouring country), which suits a border district and the later war chapter. The mafia (via Sedov, a smooth-talking fixer who works with them, not for them, and is called in when a problem needs force) can offer him paid translation work that earns money and standing on the criminal track faster. It is a situational offer, not a daily activity (a few per month at most), starts from week 2 and is first planted at the restaurant dinner. It leaves traces and the boss must not learn of it, although the boss himself may deal with the same people through intermediaries. Money sinks beyond rent, taxi and bribes: courses and books, a round at the pub, and **money sent to his sister, who went to study in the capital of the neighbouring country** (a recurring choice on payday; consequences shown as letters, not a meter). There is no clothing or status mechanic and no item inventory. Useful items are bought at the department store: a task card carries a small hint (how explicit is a tuning value) that buying something basic may help. The player can visit the shop on any day while the task timer keeps running, picks from a simple clickable list (prices shown, several items at once if the wallet allows), and the items stay until the end of the week, when unused ones lapse.
- **Mikhalych's secret (Provisional):** last year a contractor took money for boiler repairs that were never done; the completion act (акт приёмки выполненных работ) listed them as finished, and Mikhalych, as the responsible fitter, signed it under pressure. With the commission coming he knows only his signature is on it, so he drinks; two polite men from the restaurant visited him and did nothing but explain what not to say. Violence stays offstage.
- **The House of Culture meeting (Provisional):** residents are afraid after several shootings and the police arrive late or not at all (one concrete incident, for example a shot through a station kiosk window, nobody hurt). Residents want patrols, the police want money and people, the boss wants quiet because he has dealings with these people. The protagonist may promise patrols (police and boss react), criticise the police, or ask the naive question "who benefits?". Both the boss and the criminal side hear him: a sharp remark draws Sedov's later interest, a soothing one pleases the boss.
- **Skills (Provisional, demo-level):** three skills, Бумаги (documents), Улица (street) and Слово (speech), each with two levels, trained in evening sessions that accumulate over several days (a skill never rises in one evening). Level 1 needs two to three evening sessions and level 2 a further three to four (tuning values). Level 1 multiplies the positive effect of matching later actions by 1.5, level 2 by 2; only positive effects are multiplied for now, to be revisited. Nothing is locked in week 1 (the player can always speak, for example at the House of Culture meeting); from week 2 some options may be closed until a skill level is reached, shown greyed out with an honest hint and no numbers. Progress is shown in a character drawer on the right side of the screen, the counterpart of the contacts drawer: portrait plus each skill's progress as small tick marks. The visible payoff of a multiplier is a stronger change in how people treat the protagonist; reputation is itself a currency that will be developed as a game mechanic (not designed yet). Translator is a fixed trait of the protagonist, not one of the three.
- **Reputation is the currency (Provisional).** It replaces the older term "influence", which this README no longer uses as a currency. It has two ledgers: faction standing (public, from open decisions, shown by the existing verbal ladder) and personal bond (private, from conversations and favors). Spending means calling in a favor (bond with a person, standing with a group), in line with "every favor is a debt"; spending is not designed yet. In the demo reputation only rises and falls, and skill multipliers make the change bigger (for example two ladder steps instead of one). It is shown in two places: the character drawer shows the current state per faction and person, the weekly summary shows the movement. The weekly folder's standing tab is expected to move into the drawer so there are only two places. The work-folder button may move slightly higher on the right edge to make room for the drawer button.
- **Progressive interface (Provisional).** The regular HUD and clock appear when work begins. During the prologue, the newspaper, captions, landmark names and hold-to-skip feedback carry the scene. Controls appear as the story gives the player the thing they control: the work folder after the boss's briefing, the map controls on leaving the office, the speed controls when the player first gets free time, the contacts drawer after the first contact is made, the wallet when money first matters, the character drawer when the first evening session is offered. The restart button stays out of the way until the first week is done. Unlock triggers are data, not scene wiring.
- **The journalist (new character, Provisional).** A local woman in her mid-twenties who lives on the protagonist's floor of the dormitory and writes for the regional paper. She needs two looks as a character: at home in the dormitory (Monday evening) and at work as press (Tuesday morning and the Friday inspection). Visual brief and voice: `docs/story/characters/journalist.md`.
- **Difficulty ramp (Provisional).** Later in the game there are noticeably more moments where the player must pause and think hard about where to spend time, money and reputation. In the opening weeks the direction is given explicitly (clear card hints, introduced people, tight guidance); later the signposting fades. The hint explicitness on task cards is therefore a per-week tuning value that decreases over the chapter. Information stays honest (the game still reports the direction of effects); only the nudging is removed.
- Open: how the wait from 08:00 to about 10:00 is shown (the drive itself is an in-game cutscene with a slowed clock from 06:00 to 08:00, arriving on time; the boss comes around 10:00; proposal: a short time skip in reception), the exact conversation time costs, the neighbour's name and portrait, the new opening newspaper edition, how many evening sessions raise a skill level, where the protagonist learned the language, and whether the nearest city across the border is provincial or industrial.

## Current Campaign Concept (Provisional)

- The player starts in an existing fictional state with post-Soviet-like problems and builds a political career, beginning as an aide to the district head. In the first chapter, district head is an intermediate milestone and mayor is the final goal; head of state remains the long-term ambition beyond this chapter.
- The gameplay loop takes inspiration from *This Is the Police*: a map with incoming requests and conflicts from interested parties, but the player does not run a police department. Parties may include residents, businesses, the mafia, police, courts, and powerful political actors.
- The first prototype should show the request map and faction relationships. The player responds to requests either by choosing a position or allocating resources.
- Requests may come from individuals, groups, and organizations.
- Time is the primary source of pressure: it only moves forward, and the story keeps adding new problems. Reputation is what the player spends, by calling in favors, to contain them.
- Money is a separate resource. Bribes and payoffs cannot be handled with reputation alone, though reputation may affect prices. Some quests may require money for a specific task.
- Numbers stay inside the simulation and are hidden from the player for immersion. Faction relationships are shown as a clear verbal status, and choices show only the direction of their effect (for example, "residents will be pleased, the police will not"). The game always reports direction honestly.
- Exception: authored preparation moments before key events, where readiness explicitly decides whether the session continues or must restart (as in *This Is the Police* or *Frostpunk*), may show explicit progress.
- Time follows a weekly hybrid cycle (see Endings and Pacing). Major objectives in the first career segment have deadlines; a rival may overtake the player, and missing a deadline may end the campaign. It is undecided whether individual actions also consume explicit time.
- Reputation is a spendable resource for actions and agreements. Time creates urgency; reputation determines the methods available.
- The first career segment has one prominent rival with a distinct personality and story. Rival progress is shown through story events, not a separate progress bar.
- Reputation may come from completed requests, relationships, compromises, and events.
- Promotion provisionally requires completing a list of objectives before a deadline. The first list of objectives is undecided.
- In the MVP, the rival clearly opposes the player by scheming, intercepting assignments, and damaging the player's reputation. A successful run removes the rival as an obstacle, but the exact resolution is open. Because the rival is an older figure, they can be written off at the end of this chapter, and later chapters can introduce new rivals. The rival will not become the player's friend.
- Delayed requests have consequences that vary by request type. In the first chapter, the protagonist personally makes important decisions; contacts can help with requests, and paperwork delegation is a later progression unlock.
- Pressure is central and remains present on an honest, reform-oriented path. The player may cooperate with the corrupt system or try to act with integrity; the honest path is not an easier mode. The player can change sides at each career stage.
- Sides are dynamic rather than fixed camps. Honest and corrupt approaches share a broad goal but differ in methods, allies, and consequences.
- Pressure comes from distinct forces, such as the police, mafia, superiors, and press, rather than a single global threat meter. The map contains both ordinary requests and timed crises.
- The story combines authored key events with dynamic events between them. Relationships with important people and organizations persist after promotions.
- There is no explicit morality meter. Faction relationships are visible, while the moral character of the player's choices is conveyed through actions and consequences.
- The initial scope should reuse structures for objectives, conflicts, and deadlines across offices. Missing deadlines may end the campaign; implementation details are undecided.
- The first chapter ends when the player becomes mayor. Changing the rules of the system itself (appointing loyalists, shaping which requests arrive) is out of scope for this chapter; interstate politics is not required either.

## References

- Yuri Bykov's films, especially *The Fool* (*Durak*, 2014), *The Factory* (*Zavod*, 2018), and *The Major* (*Mayor*, 2013): sources of characters and situations (a tired official, collective complicity, a factory in crisis, police protecting their own). Borrow characters and situations, not the bleakness; the game's tone stays pragmatic with dark humor. Planned borrowings:
  - The boss follows the template of the district administration head in *The Fool*: not a monster, but someone who has lived inside the system so long that they defend it because they are part of it.
  - A "meeting of accomplices" as an authored turning point: all the officials gather in one room, and it turns out each has taken a share. The player sees how deep the rot goes.
  - Ingratitude of the rescued: people the honest player helps are not automatically grateful.
  - From *The Factory*: workers cheated by the owner of the closing factory, a conflict for the district head stage (business versus ordinary people, with the mafia nearby).
  - From *The Major*: police covering for their own, so even a complete dossier may fail against a protected target.
- *This Is the Police*, *Suzerain*, *Frostpunk*: mechanical references for request maps, political choices, and escalating pressure.
