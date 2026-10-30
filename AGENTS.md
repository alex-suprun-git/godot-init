# Project: 2D Grand Strategy Learning Project

## Long-Term Game Direction

- The long-term goal is an original 2D grand strategy game combining the broad civilizational development of *Civilization* with the geopolitical depth and simulation of *Hearts of Iron IV*.
- Pax Historia is an inspiration point for an alternate-history sandbox, not a fixed design or a game to clone.
- Specific rules, eras, map structure, and victory conditions are undecided. Do not treat them as settled without discussing them with the user.
- Do not use a character, fighter, or *Punch Club* as a model or comparison for this game.
- Small learning prototypes are steps toward this goal; they do not need to contain the full depth of the eventual game.

## Current Campaign Concept (Provisional)

- The first campaign starts in an existing fictional state with post-Soviet-like problems. The player begins as an individual and climbs through political offices, potentially from an aide to a local leader through city and regional roles to the head of state.
- The first chapter/prototype specifically starts with the player as an aide to a district or city leader.
- The recurring gameplay loop takes inspiration from *This Is the Police*: a map with incoming requests and events from interested parties. In this game, those parties may include residents, businesses, the mafia, police, courts, and more powerful actors. The player is not a police chief and does not dispatch police units.
- The first playable prototype should show both the request map and faction relationships. Depending on the request, the player chooses a position or allocates resources.
- Requests can come from individuals, groups, and organizations. It is undecided whether time or political influence is the primary scarce resource; do not assume either one is settled.
- Faction relationships should be visible as both a numeric value and an understandable verbal status.
- Time currently runs continuously and can be paused or sped up. In the first career segment, major objectives have deadlines: a rival can overtake the protagonist, and missing the objective may end the campaign. Whether individual actions also consume explicit hours or days is undecided.
- Political influence is provisionally a spendable pool for actions and agreements. Time creates urgency; influence determines which methods are available.
- The first career segment has one prominent rival with a distinct personality and story. The player learns about the rival's progress through story events rather than a separate progress bar.
- Political influence may come from several sources, including completed requests, relationships, compromises, and events.
- Promotion is provisionally unlocked by completing a list of objectives before a deadline. The specific objectives for the first segment are undecided.
- In the MVP, the rival is a clear antagonist who schemes, intercepts assignments, and damages the protagonist's reputation. Success removes the rival as an obstacle, but the exact resolution is undecided. A full game may carry the rival into a second act; the rival will not become the protagonist's friend.
- Delayed requests have different consequences depending on their type. In the first campaign segment, the protagonist personally handles important decisions; delegating important tasks is not currently planned.
- Pressure is central and remains present on an honest, reform-oriented path. The player may cooperate with the corrupt system or try to act with integrity; the honest path is not an easier difficulty setting. The player should be able to change sides at each career stage.
- Sides are not two fixed camps; they shift with the ongoing story and conflicts. Honest and corrupt approaches share a broad goal but differ in methods, allies, and consequences.
- Pressure comes from distinct groups and institutions, such as the police, mafia, superiors, and press, rather than one global danger meter. The map includes both ordinary requests and time-critical crises.
- The campaign provisionally combines authored key events with dynamic events between them. Relationships with important people and organizations persist after promotions.
- There is no explicit morality meter. Faction relationships are visible; whether the player acts with integrity or becomes corrupt is communicated indirectly through choices, methods, and consequences.
- To keep scope manageable, offices should initially reuse structures built around objectives, conflicts, and deadlines. Missing a deadline may end the campaign. Exact implementation is undecided.
- The provisional goal of this campaign is to become head of state. The campaign may end there; interstate politics is not required for this first arc. Whether later campaigns or phases go beyond it is open.

## Goals and Roles

- The user is the creative lead and sets the game's ideas, tone, and intended feel.
- Codex acts as the development team and learning partner: handle technical implementation, briefly explain relevant decisions, and ask about genuine design choices.
- The project is also a practical way for the user to learn Godot while building a game.

## Explanation Style

- The user is new to Godot but experienced in Software Engineering.
- Explain Godot concepts step by step and connect them to familiar Software Engineering ideas where useful.
- Do not repeat basic programming concepts unnecessarily. Briefly explain what changed, why, and how it appears in the game.
- Keep all project documentation in English. In chat, respond in the user's language unless they request otherwise.

## Workflow

- For small, clear tasks, edit project files directly and show the result in Godot where practical.
- Match the pace to the task: use manageable steps for learning, and complete small features when appropriate.
- Align on creative direction and intended behavior; resolve technical details independently when they do not materially change the game's scope.
- Project files are under `init/`; the main scene is `init/main.tscn`. The project uses Godot 4.7.1.
- Run the game locally with F5. Running Godot and local game builds does not incur usage fees.
- Do not add or run automated tests unless the user asks. For visual changes, launch and inspect the game where practical.
- Do not commit or push unless explicitly asked.
