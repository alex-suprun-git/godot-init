# 2D Grand Strategy — Godot Learning Project

A learning project for exploring Godot and gradually building an original 2D grand strategy game.

## Long-Term Direction

- Combine the broad civilizational development of *Civilization* with the geopolitical depth and simulation of *Hearts of Iron IV*.
- Use Pax Historia as an inspiration point for an alternate-history sandbox, not as a design to copy.
- The gameplay loop, eras, map, and victory conditions are still open design questions.

## Current Campaign Concept (Provisional)

- The player starts in an existing fictional state with post-Soviet-like problems and builds a political career, beginning as an aide to a district or city leader and potentially rising to the head of state.
- The gameplay loop takes inspiration from *This Is the Police*: a map with incoming requests and conflicts from interested parties, but the player does not run a police department. Parties may include residents, businesses, the mafia, police, courts, and powerful political actors.
- The first prototype should show the request map and faction relationships. The player responds to requests either by choosing a position or allocating resources.
- Requests may come from individuals, groups, and organizations. It is undecided whether time or political influence is the primary scarce resource.
- Faction relationships should be shown as both a number and a clear verbal status.
- Time runs continuously and can be paused or sped up. Major objectives in the first career segment have deadlines; a rival may overtake the player, and missing a deadline may end the campaign. It is undecided whether individual actions also consume explicit time.
- Political influence is provisionally a spendable resource for actions and agreements. Time creates urgency; influence determines the methods available.
- The first career segment has one prominent rival with a distinct personality and story. Rival progress is shown through story events, not a separate progress bar.
- Influence may come from completed requests, relationships, compromises, and events.
- Promotion provisionally requires completing a list of objectives before a deadline. The first list of objectives is undecided.
- In the MVP, the rival clearly opposes the player by scheming, intercepting assignments, and damaging the player's reputation. A successful run removes the rival as an obstacle, but the exact resolution is open. A full game may carry the rival into a second act; the rival will not become the player's friend.
- Delayed requests have consequences that vary by request type. In the first chapter, the protagonist personally makes important decisions; delegation is not currently planned.
- Pressure is central and remains present on an honest, reform-oriented path. The player may cooperate with the corrupt system or try to act with integrity; the honest path is not an easier mode. The player can change sides at each career stage.
- Sides are dynamic rather than fixed camps. Honest and corrupt approaches share a broad goal but differ in methods, allies, and consequences.
- Pressure comes from distinct forces, such as the police, mafia, superiors, and press, rather than a single global threat meter. The map contains both ordinary requests and timed crises.
- The story combines authored key events with dynamic events between them. Relationships with important people and organizations persist after promotions.
- There is no explicit morality meter. Faction relationships are visible, while the moral character of the player's choices is conveyed through actions and consequences.
- The initial scope should reuse structures for objectives, conflicts, and deadlines across offices. Missing deadlines may end the campaign; implementation details are undecided.
- The provisional campaign goal is to become head of state. The campaign may end there; interstate politics is not required for this first arc.

## Learning Approach

- Learn Godot through small prototypes, then gradually expand the game's systems.
- Explain new Godot concepts through familiar Software Engineering ideas and apply them in the project.
