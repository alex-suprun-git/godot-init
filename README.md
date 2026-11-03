# 2D Grand Strategy — Godot Learning Project

A learning project for exploring Godot and gradually building an original 2D grand strategy game.

## Long-Term Direction

- Combine the broad civilizational development of *Civilization* with the geopolitical depth and simulation of *Hearts of Iron IV*.
- Use Pax Historia as an inspiration point for an alternate-history sandbox, not as a design to copy.
- The gameplay loop, eras, map, and victory conditions are still open design questions.

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
- A clothing market directly beside the railway station, where traders, the mafia, police, and ordinary people meet. It produces many requests. The approved map-based direction is now implemented as one combined 2D painting in the moved `market` lot: dense colourful stalls, a small railway building near a clear passenger platform, and a straight row of bus bays on the road side. The old market site is grass for now. A metal mesh fence separates the market side from the railway; its concrete boundary and the station platform edge form one straight line, with no railway-side decorative planting. Both parallel through tracks remain free, and the old passenger-line freight wagon is removed. The user requested a slightly larger station, smaller stalls and a clear gap between market and station; asset v7 depicts those revisions. This is a static interim implementation; separate 3D models are deferred. The final in-game framing awaits review. Source, calibration, limitations and actual Godot frames: `art/market_hub/README.md`. Brief: `tasks/market-rework.md`.
- An old center with merchant houses and a cathedral, so the city has real visual beauty, not only gray.
- The long northern reserve between the highway and north street is a wheat field, following the user's approved map concept and in-game review. The expanded lot retains roadside verges and uses a low crop canopy, soil headland and paired tractor tramlines. Season previews show the same site after harvest in autumn (short cut stems, scattered straw and soil wheel ruts) and under snow in winter (mostly buried stubble and softened ruts). This is static map dressing driven by the existing season selector, without a harvest simulation; implementation: `art/source_images/wheat_field/README.md`.
- Soviet housing estates and one factory on the verge of closing: background and a source of social tension, not the face of the city.
- River, embankment, and suburban dachas with forest: space for decisions such as clearing forest for a new housing block.
- Visual contrast is the signature look: beautiful old buildings next to kiosks, advertising, and new gangster mansions. The 1990s without grim horror.
- City park (`city_park`, behind the department store): the old combined painting was removed at the user request. The 54 x 84 m lot remains grass, reserved for a replacement developed on a separate branch. No replacement park is built in the tree migration.
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
- Starting resources of an aide: influence initially comes from the boss's name and cannot be abused without the boss noticing. The salary is close to nothing; real money comes mostly through gray channels (envelopes, kickbacks, favors). Without money tasks are hard, and the only easy money is dirty.
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
- Contact availability stays in a compact dock along the bottom edge. Selecting a person opens their role, full status, and a map focus action without keeping a large character card on screen.
- Approved UI direction: "Living Chancellery" — cream paper, warm graphite, burgundy ink, Roboto Slab headings, and Golos Text controls/body copy. Weekly objectives are lines in a personal work folder; contact availability uses small framed photos with status marks and work progress. The player is excluded from the contacts dock; they remain on the map and can act personally on requests. Character messages and optional press items have distinct document layouts. Font binaries and their licenses are bundled under `init/assets/fonts/`.
- Map portraits and on-map request markers shrink smoothly to a minimum of 78% when zooming out. People at the same position remain centered as a group, with portrait spacing reduced from 64 screen pixels at close/default zoom to about 50 in the overview. On-screen request markers seek a nearby free position around portraits, names and previously placed request markers; off-screen request indicators retain their full size. Travel paths remain attached to the scaled portraits.
- Press items use a newspaper front page: a strong masthead, issue/date/section line, editorial columns, a pull quote and captioned duotone photo, subtle paper grain, and printed rules. The work folder keeps a shared inset below all tabs so page content does not touch the active-tab underline.
- Calls: a phone call is fast but only works from the office and only with strong contacts; a visit is slower but stronger. A mobile phone (rare and a status symbol in 1997–98) is a career reward that allows calls from anywhere; a pager may be an intermediate step.
- Dialogs remain for rare, short key story moments (the boss, the meeting of accomplices, deals with the rival), like cutscenes.
- Each week is a self-contained run: urgency and timers live within one working or calendar week, together with NPC interactions.
- Two kinds of map change:
  - Instant: sudden events such as a fire, a picket, or an accident appear in the middle of the week as overlays.
  - Gradual: slow changes such as a new housing block change lot states only between weeks, at the start of the next week, alongside the consequences of the previous one. Long projects pass through visible intermediate stages over several weeks (fence, foundation, frame) rather than appearing out of nowhere.
- Provisional target: about 35–40 weeks per chapter at roughly 3–4 minutes each. Exact numbers are tuned in the prototype, and day length is a configuration value.
- Prototype pacing: at ×1, one game hour takes four real seconds (64 seconds per 06:00–22:00 day; five minutes twenty seconds per five-day live week, excluding pauses and overtime). ×2 and ×4 multiply that simulation rate; pause stops it. The base rate and supported speeds live in `init/scripts/data/settings.gd`.
- During the live week, Space toggles pause and resumes the last selected running speed, including after a crisis pauses the game. Holding Space does not repeatedly toggle it.
- The shift to this core loop needs deliberate balancing.

- Planned office workload (not implemented): alongside direct assignments from the boss, the protagonist has a recurring activity, "Работа с документами" (paperwork), at the administration. Use a fixed 20 hours per week as the initial balance setting; no separate weekly fiction or authored paperwork quests are needed at this stage. Work can be interrupted and resumed; completed hours persist across days within that week. While doing paperwork, the protagonist can make calls, but must interrupt it before attending anything personally. Initially the work must be done personally; delegation unlocks through later progression, with conditions still undecided. Leaving to build relationships competes with this workload. Incomplete paperwork at the weekly deadline damages standing with the boss; the penalty remains undecided. Other requests are voluntary opportunities for money, influence or kindness, unless explicitly assigned by the boss.

## City Audio (Prototype)

- The first audio layer is a continuous, non-positional city-outskirts recording, selected by the user as an initial ambience trial. It starts with the map and fades in over two seconds. It keeps its natural playback speed during pause, planning, summary, and simulation speed changes; camera movement does not affect it yet.
- A dedicated `CityAmbience` player uses the `Ambience` bus independently of the short sound-event pool. Default gain is 50% (about -6 dB); F3 exposes a 0–100% slider, with zero muting without restarting the recording. This audition setting lasts for the current run only.
- The 7:46.790 source is prepared as a 7:42.790 Ogg Vorbis loop with a four-second equal-power overlap. The Desktop WAV is preserved outside the game; only the prepared Ogg is imported. Asset provenance, attribution, preparation, and verification are recorded in `art/audio/city/SOURCING.md`; the bundled attribution is in `init/assets/audio/ATTRIBUTION.md` and linked in F3.
- This is a first listening trial, not an approved final soundscape. Localized sources, night/weather layers, music, persistent audio preferences, and automatic pause ducking are not implemented.

## Player Mobility and Personal Money (Provisional)

Mobility and money are both scarce for a junior aide, which is part of what makes the map matter.

The opening demo starts with only Mikhalych as a contact: he is already around the district administration. Baba Nina is not yet acquainted with the protagonist, so she remains a resident/requester but is disabled as an assignable contact, including her map token and dispatch choices. Acquaintance and relationship progression are deferred.

Opening demo: Tolik is disabled through his actor `enabled` flag, not removed. He is absent from contacts, map tokens and request choices, and cannot automatically drive the protagonist. His data and driving logic remain for later relationship mechanics. Player walking pace is calibrated to 15 game minutes from the administration to House 5: 707.68 map metres per game hour on the current 176.92 m route. All other walks use the same speed and their actual route length, without added travel time. Quest work duration is separate and should follow the activity: tea with the priest now takes 1.5 hours; other existing quest durations still need review. One game hour still takes 4 real seconds at ×1; clock pacing is unchanged.

- **Transport is a privilege, not a default.** The protagonist starts on foot or with a bicycle. The black Volga belongs to the boss. The administration's driver (Tolik) drives the boss and only gives the player a lift when the player has earned some goodwill and the Volga is free.
  - Modes: on foot, bicycle (about twice as fast, can use yard paths), bus (stops, fixed routes, waiting), taxi (paid, fast), a lift from Tolik (free, conditional).
  - The boss's car is busy in random time windows (not an authored schedule). A lift is possible only outside a window and with enough standing with the boss; the exact threshold is tuned in the prototype.
- **Sending people works only from the executive committee** (the office phone), as already stated in the calls rule above. There are no payphones. Away from the office the player can act only in person. Results of people already sent and new requests are visible at once; that is a game convention, not a rule to simulate. Mobile phones and pagers remain career rewards that lift the office restriction.
- **Personal money.** The player has a small personal reserve, shown plainly in the UI. Unlike influence, the player cannot yet take from the budget, so money is scarce and bribes carry real weight.
  - Money sinks: taxi fares (the fare is shown before the player chooses, an explicit exception to the rule that numbers stay hidden), bribes the story requires (some situations can only be settled with a payoff, or offer it as an option), and weekly dormitory rent: 250 rubles, automatically charged on Friday after returning home.
  - Income: 1,500 rubles once a month, on the 1st (the next playable weekday if the date falls on a skipped weekend). The starting reserve is 1,200 rubles. Amounts are provisional balance settings; all money uses stable fictional rubles, without denomination changes.
  - Unpaid rent is recorded as debt when the reserve is insufficient. Collector pressure and ways to repay arrears remain planned, not implemented.
  - The protagonist initially lives in the western dormitory; housing upgrades remain out of scope for now.
- Future idea, not in the first prototype: poor standing has consequences for the bicycle. Each key building has its own resident person or group (guards, regulars, local toughs). If the player's standing with a faction is very bad and they arrive there by bicycle, there is a chance the bicycle is damaged or stolen, with a mocking note left behind, and the player pays for repair or a new one. The player is warned once, in advance and separately (a contact's remark, a message, a newspaper note), when standing drops to a dangerous level. There are no repeated warnings at the building itself: the player is expected to remember and decide.
- The map is deliberately large and slow so that travel and waiting carry the weight of every decision (see Starting District Layout).

## Player Actions and Requests (Provisional)

- Besides answering requests, the player can act on their own initiative: call the right person (spend influence), give or take a bribe (money), arrange a meeting between two sides (compromise), leak information to the press, and make promises.
- Promises are the signature mechanic: they cost nothing now and become a debt later. Broken promises surface as consequences on the map, such as pickets.
- At most 3–4 requests are active on the map at the same time.
- How long a request stays open follows from its situation, not from a hand-set date. Each request has an urgency class:
  - Now (about 3 hours): people stand on the spot and wait (a conflict at the market, coal being stolen, a visitor in the office).
  - Today (until 20:00): a deal that goes to someone else in the evening (the storekeeper's fuel, Gusev's stalls, a meeting tonight).
  - Days (about two days): a complaint that can wait (the pipes, the church).
  - Week (until Friday): the week's tasks (the contractor, the report).
- The request card states the fiction, not a bare time: "Waiting for you at the station, about 3 h left" rather than "until Fri 12:00".
- Requests that can wait escalate while unanswered instead of only expiring: the pipe complaint turns into a letter to the newspaper and then a picket. Waiting is allowed but grows more expensive. A promise pauses a request's deadline and escalation until the promised date.
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

- Connections are part of influence, not a separate resource.
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
- Daily routine: the playable day starts at 06:00 at the protagonist's dormitory in the western housing reserve, with the newspaper and personal notices. The protagonist automatically walks to the administration in time for 08:00; the boss's briefing and weekly assignments first appear on arrival. Official duty runs 08:00–18:00; the evening remains available until 22:00. At 22:00 new actions are blocked, but a personal job already underway, including travel to it, finishes in overtime before the automatic walk home. Only after arriving at the dormitory does the day end and the next-day calendar appear; Friday rent is charged then, before the week summary. The next morning begins at home at 06:00. Contacts return to their own start lots overnight and resume unfinished jobs the next day. The dormitory currently uses an intact temporary building with existing materials; a dedicated design inspired by intact dormitory references is pending review. Focused development capture: `--autoplay --only=routine`.
- Lighting follows the clock and the season (sunrise and sunset differ by season); windows and street lamps light up at dusk. Purely visual for now.
- Feeling the city and the player's impact on it matters more than covering many calendar years. The first chapter therefore covers a short period of about 1–2 years, ending by 2000 at the latest. It starts in late August 1997; the end date is open.
- Undecided: whether the protagonist has stats or perks.

## City Map (Provisional)

- A detailed, good-looking city map is a key priority.
- Asphalt and crosswalk rendering: town surfaces use a world-aligned shader with subdued fine texture and a cooler, cleared-road winter appearance; zebra paint has its own muted material. The user approved the town treatment. The highway now uses the same shader with a slightly darker, cooler and quieter surface; it was checked in summer and winter. Narrow earth, yard and paved paths also have a world-aligned material with subdued texture and compacted-snow winter tones; it was checked in summer and winter. Large squares and courtyard ground patches retain their existing materials. The two main internal housing paths are narrowed from 10 m to 4 m, retaining their centre lines and endpoints; the user approved this width change. Other street geometry is unchanged.
- Street layout follows art direction and map composition. Long travel detours alone do not justify rebuilding streets or adding shortcuts to make requests easier to complete; the proposed route-efficiency redesign in #11 is abandoned.
- Visual direction: the playable map is a stylized 3D scene seen from above at an angle (similar to *Smuggler*), so the whole area can be shown at a consistent scale and stay alive: moving traffic and people, day and night, weather, construction stages, smoke, pickets, and fire through the engine rather than redrawn art.
- Buildings are simple 3D shapes dressed with generated painted facade textures, matching the mood of `art/concepts/isometric-city-direction-v2.png`. Key locations get distinct, recognizable models.
- Lada cars on streets, at the polyclinic and in the House 5 courtyard use the shared Blender V2 GLB at real scale, with actual 3D orientation and shadows. Editable source and rebuild instructions are in `art/models/lada/README.md`.
- Civilian Volgas use the reviewed GAZ-24 GLB, with approximately one in fifteen passenger cars selected deterministically in ambient/parked traffic. The administration's Volga retains its original black lacquer. Paint variants share materials and preserve glass/chrome/rubber finishes. All Volgas have a user-requested uniform 10% presentation reduction (`VOLGA_VISUAL_SCALE = 0.90`), applied by the shared vehicle factory to traffic, parked and administration variants; the source GLB retains its dimensions.
- Bridge materials (implemented, appearance review pending): railway overpasses and the river rail bridge use grey concrete structure, darker ballast between/beside the existing tracks, narrow concrete maintenance edges and matte grey-blue truss steel. The road bridge shares the concrete family. The ballast continues along the whole eastern embankment crown; quay paving, road sidewalks and separately rendered road paint continue through the edge haze. Existing road/rail dimensions, traffic and mist remain. Sources, actual Godot frames and limitations: `art/bridges/README.md`.
- Railway track artwork refresh (implemented, final appearance review pending): the existing 2D ground texture now depicts intact wooden sleepers, clearer steel running surfaces and substantially less rust and vegetation, following the maintained-city direction. This iteration retains the flat textured geometry; 3D rails are deferred. The separate darker embankment ballast still has a visible hard boundary against the lighter track strips. Sources, preparation and actual game close-ups: `art/railway/README.md`.
- Ambient trains: the reviewed M62-inspired locomotive with eight brick/blue-grey/olive container platforms uses the outer eastern track (x=420); the four-car ER2 uses the inner track (x=410). Each shuttles along its own fixed route between the western and northern haze, reversing only after the whole formation is concealed. Cars follow the rounded southern bend and embankment/bridge heights separately. ER2 is already moving beside the village at startup; freight starts after 10 s. Each train independently waits 10 s after a complete trip, so simultaneous passes are allowed. Exactly one reusable formation owns each dedicated track; it is never relaunched while still on the route. ER2 travels at 20 m/s and freight at 14 m/s. This is ambient movement during planning and live play, without station stops or a passenger/freight simulation. Focused visual review: `--autoplay --only=trains --shots=<absolute directory>`; sources and model measurements: `art/models/freight_train/README.md`.
- Sidewalk materials (implemented, final appearance review pending): the civic `axis` south of the `north_street` junction uses light concrete slabs at approximately 50 cm scale; the approach north towards the river and other existing asphalt-road sidewalks use finer, lighter pedestrian asphalt. North of that junction the median stays grass without trees; the planted southern boulevard remains. Materials stay aligned across junction cuts, overlapping corner surfaces are removed, and winter uses the existing snow surfaces. After user review, pedestrian asphalt has stronger grain/tonal variation; orthographic camera distance is decoupled from zoom to prevent close-up building clipping. Widths and pedestrian routes are unchanged. Sources and visual verification: `art/source_images/sidewalks/README.md`, `art/sidewalks/README.md`.
- Ambient pedestrians use a dedicated pavement/path graph with street crossings derived from the same layout data as the zebra markings. Crossings cover the civic avenue, intersecting streets and courtyard/village links; pedestrians cross asphalt on these links. The walker pool is 288 (20% above the previous 240), retaining district/hour visibility; the car pool remains 130. Focused visual review: `--autoplay --crosswalks-only --shots=<absolute output dir>`. Background traffic still has no collision or right-of-way simulation.
- Static period-inspired 3D traffic lights stand at the civic axis junctions with the river highway, north cross street and south station/market street (11 fixtures: 4/4/3 incoming approaches). `traffic_intersections.gd` registers stable intersection/approach IDs, road and zebra links, and future signal groups; geometry comes from named roads in `DistrictLayout.ROADS`. Each red/amber/green lens can be controlled through `set_signal()`, using shared emissive materials. All signals stay off in normal play; phase cycling, yielding and stopping remain deferred. Courtyard accesses remain unsignalized. Source, rebuild and visual checks: `art/models/traffic_lights/README.md`; focused review: `--autoplay --traffic-lights-only --shots=<absolute output dir>`.
- Map edges use world-anchored haze authored in `map_boundaries.gd`. The three western roads, eastern road ends and southern rails continue into it; the western clear boundary now extends past the relocated forest. Seven gateways remain available, although the current open traffic trips use only the two highway ends and the near-bank bridge head. The bridge stays veiled until the far-bank city exists; crossing and border-control gameplay remain deferred.
- Public transport model direction: both LiAZ-5256 and PAZ-3205 buses, with versions appropriate to 1997, and an ER2 commuter train with the angular, square-front cab. The square cab supersedes the initial round-cab choice. ER2 head/motor GLBs are built; the user chose a four-car head–motor–motor–head formation, superseding the old three-car art brief and the temporary two-car proposal. Dimensions inherit the actual Volga's vehicle stylization and the same shared map scale; full train length is about 82.3 map metres. The user positively reviewed the model; it now operates as described under Ambient trains above. An interactive comparison scene and actual map captures exist. LiAZ-5256 and PAZ-3205 models are integrated into ambient traffic and ATP parking, with an approved uniform 20% presentation reduction; editable sources and Godot review are recorded in `art/models/public_transport/README.md`. Progress: `art/models/public_transport/PLAN.md`; ER2 measurements and source: `art/models/public_transport/er2/README.md`.
- Traffic paint direction is historically inspired and deliberately curated rather than a complete factory catalogue: no red, burgundy, pink, mint or vivid orange cars. Calm light and mid-tone cars are favoured over dark ones. Lada sedan/wagon weights: warm ivory 18%, plain grey 16%, muted blue 23%, sand beige 18%, subdued olive 8%, muted ochre 2%, dark green 9%, dark blue 6%. Civilian Volga weights: ivory 24%, grey 22%, grey-blue 22%, beige 17%, bottle green 9%, dark blue 6%. Thus dark shades total 15% for either passenger-car family, with rare subdued accents. These are sampling weights, not exact quotas in each scene. Truck cabs also exclude red; freight container colours remain separate.
- The district executive committee is a prominent civic landmark, larger in mass than an ordinary five-storey Khrushchev-era block: a broad facade, high ceilings and a formal entrance facing the square. The church should have a substantial body and an easily recognizable silhouette. (Merchant houses belong to the old city center, which is not part of the starting district; see Starting District Layout.)
- Everything shown in windows is 2D painted art in the same mood: location scenes, event illustrations, contact portraits, and story scenes.
- The playable area grows with the career: the aide's micro-district first, then the district, then the city, each as its own map.
- In-game text is in Russian. Code, identifiers, and documentation stay in English; UI strings should go through Godot's translation system so other languages remain possible.
- The first layout-only mockup's visual style was rejected. The approved interface direction is now "Living Chancellery" (see Core Loop); map art remains a separate visual system.
- The map visibly reflects decisions: a cleared forest becomes a new housing block; broken promises to garage owners lead to pickets.
- Contextual events and tasks appear in different parts of the map. The player's contacts span the whole city, not only their district.
- Panels and tabs show details such as the satisfaction of factions and individuals and the request backlog.
- The player mainly thinks about resource management and long-term decisions.
- Technical approach: the city is divided into lots (forest, yard, square, wasteland, factory). Each lot has states with their own 3D models (forest → clearing → construction → housing block; square → kiosks → market). Temporary overlays sit on top (pickets, garbage, a police van, the rival's advertising). Player decisions change lot states.

## Far-Bank City and Visual Comparison (Provisional)

- User direction: the city across the border river in the brotherly republic should have a distinct visual identity. As our district changes over time, the player may want to compare it with other places or NPC-run areas. The comparison mechanic and progression rules remain undecided.
- First art proposal: an older riverside town with compact masonry streets, pitched terracotta roofs, a modest market square and an inhabited promenade, sharing the same post-Soviet past and 1997 visual world. This contrasts with our late-Soviet transport district through urban form, not a predetermined wealth or moral ranking. It is an exploratory direction, not approved architecture or a new map implementation.
- Concept: `art/concepts/far-bank-city-direction-v1.png`; exact prompt and review notes: `art/concepts/far-bank-city-v1.prompt.md`. The near bank, river and two existing crossings are retained from the border concept.
- Proposed approach for future comparisons: keep the viewpoint and recognisable landmarks stable; show matched seasons/weather on both banks, and changes through repairs, construction, market activity and waterfront use. Compare equivalent functions where possible: a historic town centre and a transport yard are not direct evidence of better or worse management.
- Open implementation option: authored stages of change in the neighbouring town can provide visible independent progress. Whether it needs a deeper NPC simulation, what is visible from our map, and how much changes independently of the player are still open.

## Starting District Layout (Provisional)

The starting district is an outskirt, not the city center. The center lies far beyond the map and is not part of the first version.

- Function: the district lives on transport, the border, and trade. Its core is the border crossing with customs, the river port, the transport hub, and the railway junction. Around them: a bus and truck depot (ATP), a truck stop for long-haul drivers, shuttle traders, and a spontaneous market.
- History in layers: an old village by the river with a church and gardens came first; then the port, the railway, and transport enterprises; then late-1980s panel housing for their workers. In the 1990s, parking lots, trading, warehouses, and side businesses grew around the flows of people and goods. The district was planned for further growth, and part of the promised infrastructure was never built, which explains empty plots and awkward connections.
- Condition differs by layer and is a visual rule, not decoration:
  - Late panel housing (built about 1982–1988, so 10–15 years old in 1997): intact facades, ordinary yards, young trees, some landscaping left unfinished. Not ruined.
  - Transport and industry: wear from use, not from age: oil stains, broken driveways, repair bays, queues, temporary structures.
  - Old village: slowly emptying; abandoned plots alternate with tidy, inhabited houses.
  - Unfinished: reserved plots that stayed wasteland, an abandoned construction site.
- Planning grid: the map is built from fixed lots, and unique buildings are added gradually by changing what stands on a lot, not by moving the layout.
  - W, housing lot: one panel block.
  - K, core lot: the center of every residential superblock (four W lots around one K lot), reserved for a school or kindergarten. Until then it is a yard, sports ground, or wasteland ("a school was supposed to stand here").
  - G, street lot: small public or commercial buildings along a street (police, polyclinic, pharmacy, exchange office, cafe, garages).
  - X, large lot: transport and industry (ATP, truck stop, checkpoint and customs, port, boiler house, market, station).
  - D, village plot: a large farmstead plot with a garden, reached by dirt roads. The old village has 17 of them, each about 38 m deep and 38–50 m wide (about 15–20 sotok), with the house near the street and the garden behind; old villages have no shortage of space. Plan: `art/concepts/village_plot_plan_v1.svg`; the lot data in `district_layout.gd` follows it. Only 2 of the 17 plots are abandoned: the village is emptying slowly, not ruined.
  - Each village plot is fenced and filled by condition (`VILLAGE_FILL` in `building_catalog.gd`): tidy plots have a whole fence, vegetable beds, an orchard and a shed; fading ones have a patchy fence, one bed and a few trees; abandoned ones have a half-fallen fence and nothing planted. Fences and beds are drawn as procedural boxes; they are placeholders until real models replace them.
  - The old village cemetery lies directly west of the church (lot `cemetery`, about 35 × 46 m): a fenced field with a gate on the north street, rows of mounds with mostly wooden, leaning crosses and a few stone stelae, a central path and old trees. The church faces west toward it.
  - Village dirt roads form closed loops (north street, west street, the road around the church, the east street, the south street and an east lane); no dead ends. The deep plot d_13 south of the church is an old orchard farmstead facing the south street.
  - Open idea, not decided: the old village may have been a collective farm (kolkhoz) in the early Soviet years, leaving an office or club, a cattle yard or a barn as ruins on some plots.
  - R, reserve: a whole empty block.
  - Ground floors of panel blocks can host small public places (district police officer, pharmacy, savings bank) by swapping the facade only.
- Layout, north to south: the neighboring "western" country; the border river with a road bridge and a separate railway bridge; a transport band along the embankment (ATP, truck stop, checkpoint and customs with a truck holding area, port with fuel depot and freight transfer station); a highway along the river; a reserve band (boiler house, garages, empty reserve block); four residential superblocks in the west; a public axis from the bridge to the station; the old village with the church in the east; the market, the passenger station, and the bus station in the south; a double-track passenger line along the south edge; and a freight line along the east edge to the railway bridge.
- The public axis runs from the checkpoint to the station. Along it, from the highway inward: police, polyclinic, the district executive committee one block further from the river, then free street lots. The executive committee does not sit directly at the river.
- No tram and no merchant houses in this district. Dirt roads exist only in the village.
- The district executive committee is a late-Soviet modernist building, built together with the district in the 1980s, not a Stalinist one.
- The medical facility is a mid-size polyclinic, not a hospital complex.
- Open: how many superblocks the first version has (four planned, room for two more in the west).
- Civic-area rework: the administrative centre retains the approved D4 layout (`art/concepts/district_areas_v2.svg`), with police at the west cross-street corner, a separate polyclinic and ambulance yard west of the avenue, four elite towers (one northern and three matching 12-storey southern towers using the northern tan-brick facade set at the same 3 m floor pitch, evenly spaced between the avenue and village street; the short dead-end southern avenue spur is removed), department store, city park and southern slabs. The administration lot now uses a separate four-storey 3D office bar and taller hall, a 32 x 24 m entrance-aligned square flush with the avenue sidewalk, a separate side court for the worker-founder monument, a compact service garage/parking screened by shrubs, and a rear garden organized around a connected path loop with planted lawns and seating. The northern path continues through to the avenue, and the remaining rear ground is filled with trees as an interim reserve; its future use is undecided. The lawn between the southern tower row and the square is also filled with trees at the user request, keeping the memorial court and existing paths clear. Trees, shrubs and furniture remain separate 3D assets. Public arrival and pedestrian links follow the relocated square-facing entrance. This replaces the earlier building/monument placeholders in normal F5; the latest integrated appearance awaits user review. Sources, rebuild commands and verification: `art/models/civic_center/README.md`. House of Culture and restaurant-casino concepts remain separate follow-ups.
- Next civic landmarks (concept direction, not implemented): the overall perspective composition is `art/source_images/ispolkom/map-direction-v7.png`, showing the administration, rear green, House of Culture, restaurant-casino and village-side enclosure. The House of Culture direction is `art/source_images/culture_house/multiview-1997-v3.png`: late-Soviet red brick/pale concrete, glazed foyer and auditorium mosaic partly covered by cheap imported-electronics advertising, with small tenants/notices appropriate to August 1997. The restaurant-casino is a compact showy venue for the new local elite, with pale neoclassical/Greek-influenced trim, green roof and arched glazed entrance facing the village-side street; map v7 is provisional, not final art approval. Before 3D production, the user explicitly requested a consistent restaurant-casino multiview sheet like the DK: front, rear, both sides and three-quarter, with coherent scale/massing/entry/service layout. Earlier concepts put the DK on the northern tower site; exact parcels, sizes and access must be reconciled with the current map, whose rear grove is an interim reserve. The PO-2 concrete enclosure belongs on the village side of the street, signaling land acquisition pressure while cottages/gardens/access remain; it is not the public park boundary. DK gameplay proposals (clubs, residents' meetings, maintenance/rental conflicts, later political gatherings), restaurant ownership/name/gameplay and final parcel dimensions remain open. Begin the next chat with `art/source_images/ispolkom/README.md`, section "Resume here — DK and restaurant-casino"; preserve the completed administration and do not treat the old concept as current game geometry.
- Civic service vehicles: cream-and-blue UAZ-452-family police van and off-white/red RAF-22031 ambulance GLBs and editable Blender sources are built and reviewed. Both use a user-requested uniform 15% reduction embedded in the exports. A standalone Godot comparison shows them beside the current Volga, PAZ and ZIL; rebuild/review instructions are under `art/models/uaz_service/` and `art/models/raf_ambulance/`. Police/clinic placement and catalog registration remain a follow-up.
- Districts and subzones in `district_layout.gd` retain population, foot/car density, fleet and hourly profiles. Ambient pedestrian visibility still follows district/hour data; moving cars now use the separate route-based flows below.

- Ambient buses: at most five slots in the road-traffic pool, including gateway transitions. The existing district mix selects candidates; excess bus candidates become passenger cars. Initial spawn and gateway re-entry share the cap. Total traffic slots and parked buses are unchanged; fewer than five may be visible because of district/hour visibility or departures.
- Moving traffic uses `traffic_flows.gd`: 30 through-highway slots, 14 highway/border slots, 18 city-loop slots and 4 courtyard slots (66 total, reduced after user review). A car stays visible throughout its trip; only off-map waiting hides it. Through traffic never leaves the highway; border trips connect either highway direction with the bridge head. City cars circulate on eastern/western loops. Only the explicitly marked housing spine and cross-street admit rare courtyard passenger cars, with road speed `0.5`; normal road speed is `1.0`, highway speed `2.0`, and other roads can set their own multiplier later. Lane-to-lane Bezier turns follow travelled distance, align the body to the tangent and ease speed through corners. Pedestrian movement rules and the five-bus cap remain. Shared `TrafficRules` owns road access and lane placement: buses always use the outer right lane by travel direction, including turn endpoints and gateway legs. Roads declare lanes per direction (two on the highway and axis, one by default); median width is excluded when calculating lane centres. Review: `tasks/car-junction-turns.md`; focused capture: `--autoplay --only=traffic`.

- Early GAZ-2705 cargo vans (white, muted blue, sand) replace half of moving ZIL selections by probability, with equal colour weights. `traffic_vehicle_models.gd` applies this at spawn and gateway re-entry; the 66 traffic slots, class budgets, KamAZ selection, parked and event vehicles are unchanged. The user approved the reference-led model and final 0.831725 presentation scale, which is already baked into each GLB. Sources, measured export and map verification: `art/models/gazelle/README.md`; focused capture: `--autoplay --only=gazelle`.

## Natural Landmarks

- Approved: a small irregular pond beside the old village, with reeds, footpaths and two fishing seats; a distinct wooded area west of the residential superblocks, with paths and an open event clearing.
- Both have named map locations (`pond`, `forest`) for future requests. No events are assigned to them yet.
- All standalone trees now use the original civic-centre 3D meshes through `vegetation_models.gd`, including the forest, roadsides, village gardens, cemetery and courtyards. Existing placement, height ranges and young-tree scales are retained; yaw varies deterministically. Shared mesh resources and seasonal materials are reused: autumn foliage turns ochre, winter deciduous foliage hides and conifers retain subdued needles with partial snow on upward-facing surfaces. The grove uses these same seasonal models. The pond freezes visually in winter; shoreline paths use the seasonal ground textures. Nature layers are named for later event changes such as litter, lighting or improvements; those event states are not implemented yet.

## Residential Compaction

- Approved spacing target: 12% shorter residential spacing in both map axes, while all building footprints, floors and prop sizes remain unchanged. The four-superblock pattern is retained.
- Housing centres and core reserves contract toward the public axis / northern residential street; internal lane widths remain unchanged. The inter-block crossing moves with the housing.
- Released space is collected into west and south housing reserves; no additional housing is placed yet. The new western street connects north and south streets at x=-480, the forest and clearing move 30 m west, and the west reserve is 76.5 m deep east of the new sidewalk for future buildings. Forest access paths and the western haze boundary follow the relocation; the precise layout awaits user review.
- The original SVG layout is a historical sketch; `district_layout.gd` is the current coordinate source.

## Courtyard Detail Pilot

- B1 (House 5 / Baba Nina) is the first detailed residential superblock: inhabited but neglected, with intact housing, worn play equipment, benches, entrance gardens, narrow paths, a small service loop and a few parked cars. It should not read as a dump.
- Roads and the district skeleton remain the reference; residential buildings may move within a block when composition requires it.
- The school/kindergarten core remains available for future development. Ground surfaces, furniture, planting and residents are grouped separately for later seasonal and event changes; additional seasonal/event variants are not yet implemented.

## Heating Infrastructure Detail Pilot

- House 5 has a small paired basement heating inlet, valve wheels, basement grilles and inspection covers. A short paired main on supports leaves the boiler house and descends underground. Most residential distribution remains buried.
- These are static geometry props, slightly emphasized for map readability. They do not imply a new leak or active heating; steam, repair/damage variants and thawed winter routes are not implemented. Named groups allow later authored event states.

## Opening Scenario (Provisional)

The first stretch of the game is built around one concrete 1990s objective: the heating season.

- Setup: late August 1997, about seven weeks before the deadline. The boss, the district head, orders the player to have the district ready for heating by October 15, when a city commission will inspect it. Failing is not an option. This is the first objective with a deadline.
- Every faction has a stake: residents fear another winter in coats; business wants the fuel oil supply and boiler repair contracts; the mafia steals fuel oil and wants its own contractor; the police protect the fuel depot; the church asks to heat the cathedral or open a shelter.
- Day one: each request teaches one mechanic.
  1. Plea: elderly residents of a five-storey block ask to fix the pipes. Teaches basic responses and spending money or influence.
  2. Offer: a businessman puts an envelope on the desk to get his repair contract signed. Teaches bribes and the first trace.
  3. Residents' meeting: the player may promise heating by October 1. Teaches promises, the first debt.
  4. Conflict: two contractors fight over the boiler house; one is quietly backed by the mafia, which the player does not know yet. Teaches picking a side.
  5. Evening: the rival appears on TV claiming their district is ready for winter. First encounter with the rival.
- About ten days later, consequences show on the map: repairs at the boiler house or an abandoned construction site; unhappy residents gathering as the promised date nears; a newspaper note hinting that someone is interested in the player's affairs.
- Early October: the first trial run of the heating system bursts a pipe at Block 5, a crisis (art: `init/assets/events/pipe_burst.png`). Week one needs its own late-summer crisis; it is undecided.
- Seasons move visibly through the opening: summer greenery with the first yellow leaves in late August, heavy leaf fall by October.
- Hidden hook: the boss is taking a kickback on the fuel oil contract. This is the player's first chance to start digging under the boss, quietly opening the compromising-material path without telling the player directly.
- This scenario is also the content of the first prototype: one objective, a handful of requests, faction relationships, and visible map changes.

## Current Campaign Concept (Provisional)

- The player starts in an existing fictional state with post-Soviet-like problems and builds a political career, beginning as an aide to the district head. In the first chapter, district head is an intermediate milestone and mayor is the final goal; head of state remains the long-term ambition beyond this chapter.
- The gameplay loop takes inspiration from *This Is the Police*: a map with incoming requests and conflicts from interested parties, but the player does not run a police department. Parties may include residents, businesses, the mafia, police, courts, and powerful political actors.
- The first prototype should show the request map and faction relationships. The player responds to requests either by choosing a position or allocating resources.
- Requests may come from individuals, groups, and organizations.
- Time is the primary source of pressure: it only moves forward, and the story keeps adding new problems. Influence (reputation) is what the player spends to contain them.
- Money is a separate resource. Bribes and payoffs cannot be handled with influence alone, though influence may affect prices. Some quests may require money for a specific task.
- Numbers stay inside the simulation and are hidden from the player for immersion. Faction relationships are shown as a clear verbal status, and choices show only the direction of their effect (for example, "residents will be pleased, the police will not"). The game always reports direction honestly.
- Exception: authored preparation moments before key events, where readiness explicitly decides whether the session continues or must restart (as in *This Is the Police* or *Frostpunk*), may show explicit progress.
- Time follows a weekly hybrid cycle (see Endings and Pacing). Major objectives in the first career segment have deadlines; a rival may overtake the player, and missing a deadline may end the campaign. It is undecided whether individual actions also consume explicit time.
- Political influence is provisionally a spendable resource for actions and agreements. Time creates urgency; influence determines the methods available.
- The first career segment has one prominent rival with a distinct personality and story. Rival progress is shown through story events, not a separate progress bar.
- Influence may come from completed requests, relationships, compromises, and events.
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

## Learning Approach

- Learn Godot through small prototypes, then gradually expand the game's systems.
- Explain new Godot concepts through familiar Software Engineering ideas and apply them in the project.
