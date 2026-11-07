# Week 1 script (Russian player-facing text)

Authored text for the week 1 redesign described in the root `README.md` ("Week 1 Redesign: Arrival and Introductions"). Documentation is English; the lines the player reads are Russian. One file per scene group, in play order. Drafts are written by Claude Code and approved by the user before Codex wires them into data.

How to write and what Claude may decide alone: see `docs/story/GUIDE.md`. Character sheet for the new character: `docs/story/characters/journalist.md`.

## Conventions

- `[Place, time]` marks a location card or a time skip.
- `ТОЛИК:` (or any name) is a spoken line, `ВЫ:` is a line the protagonist says aloud; `*...*` is narration or an inner line, shown as a caption.
- `> note` blocks are for implementers, not for the player.
- No choices in the arrival sequence: it is narration only. Choices start with the first conversation.
- Numbers (time cost, money, effects) are tuning values, not decisions, and stay hidden from the player except prices and taxi fares.
- The protagonist is never named; characters use nicknames or titles.

## Files

| File | Content | Status |
|---|---|---|
| `mon-1-arrival.md` | Train newspaper, Tolik's drive, the wait at the boss's door, the empty interface | Draft v1 (Tolik's voice approved) |
| `mon-2-boss-and-block5.md` | Boss monologue, the first conversation with Nina | Draft v0 |
| `mon-3-dormitory.md` | Going home as a quest, Vera in the kitchen | Draft v0 |
| `tue-1-vera-at-work.md` | Vera as press at the executive committee | Draft v0 |
| `tue-2-mikhalych.md` | The pub, getting Mikhalych out, the repair | Draft v0 |
| `tue-3-gusev-and-evening.md` | Gusev's introduction, the first training evening | Draft v0 |
| `wed-1-father-georgy.md` | Tea with the priest, `church_heat` | Draft v0 |
| `wed-2-station-and-meeting.md` | The kiosk with the bullet hole, the meeting in the House of Culture | Draft v0 |
| `thu-1-gusev-day-and-inspection.md` | Gusev's two asks, the inspection announced, the five-part chain | Draft v0 |
| `fri-1-inspection.md` | The engineer's inspection, Vera's article | Draft v0 |
| `fri-2-restaurant.md` | The report, the restaurant, Gureev | Draft v0 |

## Cross-day threads (for consistency)

| Thread | Planted | Pays off |
|---|---|---|
| The false repair act | Nina (Mon), Gusev (Tue), the polite men (Tue) | Thursday evening, Friday noon |
| Vera's identity | Kitchen (Mon) | Steps of the executive committee (Tue), the article (Fri) |
| The restaurant | Tolik's silence (Mon) | The dinner (Fri) |
| The border shootings | The new booth (Mon), Georgy (Wed), the kiosk glass (Wed) | The meeting (Wed), Gureev (Fri) |
| Gusev's favour | The introduction (Tue) | Thursday's two asks, week 2 |
| The language | The sister, the translator trait | Gureev's remark (Fri) |
