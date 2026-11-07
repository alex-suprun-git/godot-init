# Story guide: how to write quests without asking about every detail

Purpose: let the narrative partner (Claude Code) draft whole days, quests and conversations on its own from the established canon, and let the user review by exception. The canon itself lives in the root `README.md`; this guide does not repeat it, it says how to use it.

Read before writing: root `README.md` sections "Setting and Tone", "Factions", "Career Paths", "Core Loop", "Player Actions and Requests", "Compromising Material", "Story Arc", "Week 1 Redesign: Arrival and Introductions". Scene drafts live in `docs/story/<week>/`.

## Decision rights

| Claude decides and writes (no question) | The user decides (ask first) |
|---|---|
| Wording, jokes, rhythm of any line | A new major character, or removing one |
| Minor characters: name, look, voice, one-off role | Anything that changes the story arc, the war turn or an ending |
| Which flags, bond and standing changes a choice has | Changing the tone (more violence, more romance, more grimness than the canon) |
| Time costs and prices inside the agreed ranges | New mechanics or changes to the money, time or reputation rules |
| Quest beats that follow the week structure in the root README | Romance direction and how far it goes |
| Small events, rumours, newspaper headlines, letters | Real-world references, real names, anything politically charged |
| Order and pacing inside a day | The protagonist's name, biography and the sister's fate |

**Assumptions list.** Every draft ends with an "Assumptions" section: each non-obvious choice Claude made on its own, one line each. The user reviews the list and vetoes by exception; silence means accepted. Do not ask a question that the canon, this guide or common sense answers.

## Voice and tone

- Pragmatic realism with dark humor, 1997, a decent but rotting provincial border city. No grim horror in chapter one. Violence stays offstage or implied (a freshly repainted booth, "two polite men", a notebook of complaints).
- Hint, do not state. The player should notice, not be told. If a line explains the joke or the threat, cut it.
- Contrast carries tone: a cheerful character falling silent says more than a dramatic speech.
- The protagonist is never judged by the game and never named in text. Inner lines are dry and observant.
- Every honest option has a cost; every dirty option leaves a witness. The truth surfaces later (see Story Arc). Nothing is free.
- Period detail: rubles, kiosks, TVs and VCRs, the Volga, pagers and rare mobile phones, a radio in every car, notices on doors. No anachronisms, no real brands, no real people. The country, city and neighbouring state stay fictional.
- Foreshadow the war quietly and rarely: border incidents, odd cargo, press items. It must read as ordinary border business until much later.

## Writing rules for Russian text

- Written in natural spoken Russian, short on bureaucratic words except when a character is a bureaucrat. Use "ты" from the boss, "вы" from the player and most others; Nina says "молодой человек".
- Headline and notice text is in capitals and short, newspaper style.
- Effects shown to the player are direction only ("жители будут довольны"), never numbers, except taxi fares and prices.
- Log and summary lines are one dry sentence about what happened, not what the player should feel.
- Avoid repeating the same joke structure within a scene. One good joke per beat, not three.
- **No punchline in every line.** One dry remark per scene at most; the rest is ordinary talk. If a joke only works once someone explains it, cut it.
- **Rhythm is part of the character.** Real people talk in run-on sentences with commas, «ну», «значит», «вот», and break off and restart; do not chop speech into short sentences ending in full stops. Reserve short, abrupt lines for moments where someone is shutting a topic down (the boss, Tolik at the restaurant).
- **Concrete things instead of images.** «Восемь стариков, один лежачий» beats a metaphor.
- **Each voice has its own register:** Nina long, complaining, with numbers; Vera quick, curious, asking questions and correcting herself; Gusev a warm salesman with asides and anecdotes; Sedov slow, formal and complete, no slang, no jokes; Tolik a gossip who digresses; the boss laconic but not choppy; Mikhalych mumbling and trailing off; Korotkov precise and impersonal; Georgy gentle and unhurried.
- **Less stage-direction prose.** Only what the player would see on screen.

## Characters (voice cards)

Each card: voice, wants, hides. The full sheet for each character (voice with sample lines, how the bond grows, pointer to the look) is in `docs/story/characters/`; add a sheet and a portrait entry in `art/PROMPTS.md` when a character is introduced. This table is the quick view.

| Character | Voice | Wants | Hides |
|---|---|---|---|
| **Boris Savvich** (boss) | Heavy, unhurried, sardonic; never raises his voice; "ты" | Quiet, a clean report, to hold on until retirement | Kickback on the fuel oil; dealings with the criminals through Sedov |
| **Tolik** (driver) | Cheerful, talkative, warm, self-mocking; knows more than he says | To be liked, to keep the Volga running | Stops talking at the restaurant; he knows who eats there |
| **Baba Nina** | Sharp, suspicious, short punchy lines, a notebook; tests newcomers | Hot water and someone who comes to the yard and tells people the truth | Nothing; she writes it all down |
| **Mikhalych** (fitter) | Quiet, ashamed, dry self-deprecating humor | Not to be asked about last autumn | He signed the false completion act; two polite men visited |
| **Gusev** (businessman, contractor) | Friendly, expansive, generous with promises | Contracts, the wasteland, a friend in the administration | His backing; the envelope is removed for now |
| **Vera Lisitsyna** (journalist, neighbour) | Curious, quick, lightly ironic; does not know who the protagonist is until Tuesday; full sheet in `docs/story/characters/journalist.md` | A story that is true | That she is a journalist (Monday); an old story about the boiler repairs nobody would print |
| **Sedov** (fixer) | Smooth, reasonable, speaks the language of both sides; mirror of the protagonist | To stay useful to both sides | He works with the criminals, not for them, and is called in when force is needed |
| **Father Georgy** | Gentle, humorous, a good listener; strong tea | Heat for the church, a shelter | What he hears in confession |
| **The commission engineer** | Dry, procedural, tired; appears only on Friday of week 1 | A signed report | What he does with a forged act |
| **The protagonist** | Dry inner voice; translator of the neighbour's language; poor; a sister studying in the neighbour's capital | A way up, for someone | Everything; his name is never shown |

## Quest template (resolution)

Matches the fields in `init/scripts/data/week1.gd`.

- **id, type** (plea, conflict, crisis, offer), **lot** (where), **asker**.
- **title** and **text**: the fiction in one or two lines, a voice from the scene, not a task label.
- **appear** (day, hour), **urgency** class (now, today, days, week), **wait_text** in the card's own words.
- **escalation** steps if ignored (a complaint becomes a letter, then a picket).
- **options** (two or three): label, a hint with direction only, actor, hours, chance, success and fail effects, and a log line. One option may keep the request open (a promise).
- **thread**: what carries over into the next week.
- **hint for the shop** (small, tunable): a note on the card that something basic may help.

## Conversation template (scene)

- **Place and backdrop**, **cast**, **time cost** (about 0.5 to 2 game hours, spent as a time skip behind the scene).
- **Opening beat** that shows who the person is before the player speaks.
- **Three choice beats**: how you introduce yourself, what you ask (several questions allowed, each small), how you leave. Choices change bond, sometimes standing, sometimes open an option later.
- **Information given** (what the player learns, as flags) and **a thread** it plants.
- **Closing line** in the character's voice, then the time skip.
- Nothing is locked in week 1. From week 2 some options may be closed until a skill level is reached, shown greyed out with an honest hint.

## Consistency checklist (run before saving a draft)

1. Does it fit the day and hour table of the current week in the root README?
2. Does the character speak in their voice card?
3. Does the choice have a real cost on both sides? Is there a witness for a dirty option?
4. Does it plant a thread that a later scene can use, or pay off an earlier one?
5. Is it direction-only for the player, with no numbers?
6. Is the tone within the canon: no gratuitous violence, hint over statement?
7. Did I invent something that is not in the canon? If yes, list it under Assumptions.

## Workflow

1. Draft a whole day or a coherent scene group in one file in `docs/story/<week>/`, status "Draft v0".
2. End with an "Assumptions" section and an "Open" section (only real open questions).
3. Commit on the docs branch, update the status table in `docs/story/<week>/README.md`.
4. The user reviews. After approval the file's status becomes "Approved" and a GitHub Issue with "Done when" is prepared for Codex (see the root `AGENTS.md`, Backlog).
5. Canon changes (a new rule, a new character) go into the root `README.md`; wording rules go here.
