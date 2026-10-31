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
- Every run writes a playtest log (JSON lines plus a week summary with waiting time, request latency and contact utilization) to `~/Library/Application Support/Godot/app_userdata/Init/playtests/`; files ending in `_player.jsonl` are real plays, `_autoplay.jsonl` come from the dev autoplay, and `--no-log` turns it off. When asked to analyze a playtest, read the latest `_player` log first, find where the week drags or stalls, and only then compare with the user's own feedback.
- After sprites are added or redrawn, run `Godot --headless --path init --script res://scripts/dev/measure_sprite_anchors.gd` to refresh `scripts/data/sprite_anchors.gd` (where each sprite touches the ground and which map axis it is drawn along).
- Generated art is described in `art/PROMPTS.md`; game-ready images live under `init/assets/`, concepts under `art/concepts/`.
- For new or replaced generated raster art, follow `art/ASSET_PIPELINE.md`: preserve the original outside `init/`, review and obtain the applicable visual approval, run `uv run tools/optimize_asset.py` as a separate preparation step, then integrate the optimized copy into Godot. Do not bypass optimization or retroactively bulk-process existing assets without a migration task.
- Do not commit or push unless explicitly asked.

## Blender and 3D Assets

- Use the project skill at `.agents/skills/blender-godot-assets/SKILL.md` for Blender modeling, export and Godot integration. The reusable MCP client is `tools/blender_mcp.py`; prefer the working API over repeated UI attempts.
- For downloaded models, read the skill's `references/asset-sourcing.md`: it records acquisition, automated inspection, adaptation, previews and the division of work with the user. Handle routine technical work independently; involve the user for meaningful creative choices or a concrete acquisition blocker.
- Resume asset work from `art/models/<asset>/SOURCING.md` and its asset README, not from assumed chat memory. The Volga shortlist and pending acquisition are recorded in `art/models/volga/SOURCING.md`.
- Match the reference and intended map camera. Inspect the silhouette from several angles before expensive detailing, baking or rendering; show an actual Godot frame when reporting in-game results.
- Choose geometry, material and texture budgets for the intended viewing distance before detailing. Keep the editable Blender source separate from its game export.
- Keep build, material bake, export and preview as resumable stages. Record progress for long operations; an MCP timeout does not cancel Blender work, so check status and outputs before retrying.
- Verify uncertain API names against the installed application. Scope glTF exports explicitly to the asset scene or collection and inspect the exported contents.

## Durable Project Context

- Keep agreed workflows and actionable handoff state in the repository before ending a task that establishes them. Gameplay decisions belong in `README.md`, repeatable asset procedures in the project skill, and asset-specific decisions/progress beside that asset.
- Record what actually exists, what was inspected, remaining blockers and the next action. Distinguish planned automation from implemented scripts and verified results. Update the existing source of truth rather than maintaining duplicate chat summaries.
