# Project: 2D Grand Strategy Learning Project

## Long-Term Game Direction

- The long-term goal is an original 2D grand strategy game combining the broad civilizational development of *Civilization* with the geopolitical depth and simulation of *Hearts of Iron IV*.
- Pax Historia is an inspiration point for an alternate-history sandbox, not a fixed design or a game to clone.
- Specific rules, eras, map structure, and victory conditions are undecided. Do not treat them as settled without discussing them with the user.
- Do not use a character, fighter, or *Punch Club* as a model or comparison for this game.
- Small learning prototypes are steps toward this goal; they do not need to contain the full depth of the eventual game.

## Current Campaign Concept

- The current campaign concept lives in `README.md`, which is the single source of truth. Read it before working on game design or gameplay, and record new design decisions there rather than here.

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
- To check a visual or gameplay change without clicking, run the dev autoplay, which plays the first week and saves screenshots of each phase: `Godot --path init -- --autoplay --shots=<absolute output dir>` (Godot is at `/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot`). Read the PNGs it writes. Run `Godot --headless --path init --import` first when new assets were added.
- Generated art is described in `art/PROMPTS.md`; game-ready images live under `init/assets/`, concepts under `art/concepts/`.
- Do not commit or push unless explicitly asked.
