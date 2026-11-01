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
- When delivering work from a worktree, always include the exact absolute Godot editor launch command (`<Godot binary> --editor --path <worktree>/init`) and identify that project folder, so the user can open the correct copy.
- Run the game locally with F5. Running Godot and local game builds does not incur usage fees.
- Do not add or run automated tests unless the user asks. For visual changes, launch and inspect the game where practical.
- To check a visual or gameplay change without clicking, run the dev autoplay, which plays the first week and saves screenshots of each phase: `Godot --path init -- --autoplay --shots=<absolute output dir>` (Godot is at `/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot`). Read the PNGs it writes. Run only the parts a change needs with `--only=<scenario>[,...]` (`office` for UI panels and the request card, about 10 s; `map` for the district map tour; `week` for the live week, summary and week two, about 100 s; plus `edges`, `vehicles`, `crosswalks`, `traffic-lights`, `render-cost`); without it the full `office,map,week` run plays. Add `--turbo` (or `--turbo=N`, default 10) to speed up the engine clock for quick agent checks: `week` drops to about 15 s with the same results; use the normal speed when judging animation or pacing. Run `Godot --headless --path init --import` first when new assets were added.
- Every run writes a playtest log (JSON lines plus a week summary with waiting time, request latency and contact utilization) to `~/Library/Application Support/Godot/app_userdata/Init/playtests/`; files ending in `_player.jsonl` are real plays, `_autoplay.jsonl` come from the dev autoplay, and `--no-log` turns it off. When asked to analyze a playtest, read the latest `_player` log first, find where the week drags or stalls, and only then compare with the user's own feedback.
- After sprites are added or redrawn, run `Godot --headless --path init --script res://scripts/dev/measure_sprite_anchors.gd` to refresh `scripts/data/sprite_anchors.gd` (where each sprite touches the ground and which map axis it is drawn along).
- Generated art is described in `art/PROMPTS.md`; game-ready images live under `init/assets/`, concepts under `art/concepts/`.
- For map-area visuals, start from an actual current Godot screenshot and the project's existing style work. Develop and integrate the area in its real map context; an approved combined 2D painting can occupy one moved/resized lot as an interim implementation. Standalone polished object concept art is produced only when explicitly requested, not as the default map workflow. See `art/ASSET_PIPELINE.md`.
- For new or replaced generated raster art, follow `art/ASSET_PIPELINE.md`: preserve the original outside `init/`, review and obtain the applicable visual approval, run `uv run tools/optimize_asset.py` as a separate preparation step, then integrate the optimized copy into Godot. Do not bypass optimization or retroactively bulk-process existing assets without a migration task.
- Do not commit or push unless explicitly asked.

## Roles and Parallel Work

- Claude Code and Codex run as two equal desktop sessions on the same checkout, each in its own chat on its own topic. The user coordinates them; neither session assigns work to the other and neither is a "lead" or a "worker". Briefs in `tasks/` are shared notes, not dispatch orders.
- Before editing, run `git status` and `git diff --stat`. A file that is already modified and is not yours may be mid-edit in the other session: do not touch it, and ask the user whether the other session is finished. Never overwrite, revert or stage another session's changes.
- Stage by path when committing, so a commit contains only your own topic.
- `tools/dispatch_task.sh <id>` (a brief run with `codex exec` in `../godot-worktrees/<id>`) is optional and not the usual flow. If a brief is run in a worktree, write only to its *Outputs* and record needed changes to `init/scripts/`, scenes, `sprite_anchors.gd`, `README.md` or `AGENTS.md` in the brief's report. See `tasks/README.md`.

## Working Economically

Tokens are the scarcest resource; spend them on the result, not on ceremony.

- Start a new chat per task. Long chats re-send the whole history, including every image, on each step.
- Reuse existing frames before capturing new ones; if the frame you need does not exist, take it once with the narrowest `--only=` scenario and `--turbo`.
- Look at no more than two or three images per task. Judge visuals from the default game camera, not from isolated tiles; a night, alternate-camera or material-preview frame is taken only when the change concerns it or the user asks.
- Map screenshots and capture logs are not repository content: keep them in the scratchpad or an ignored folder (`art/bridges/`, `art/sidewalks/` and similar are in `.gitignore`). Upload selected PR images as GitHub attachments with `gh pr create/edit --attach`; keep prepared JPEGs in ignored `.local/pr-assets/<slug>/`. Do not commit new review images. Existing tracked `docs/pr-assets/` images stay until the separately authorized later cleanup; see `docs/PR_WORKFLOW.md`.
- Documentation stays short: one section in one existing README per feature. No byte counts, no copied logs, no repeated status in several files.
- Visual rules and art targets are written into docs only after the user has approved a live in-game example of them.

## Blender and 3D Assets

- For new vehicle models, use the current truck and Volga as the benchmarks for dimensions, proportions and visual quality. Follow the comparison rules in the project Blender skill; the Lada scale factor is legacy implementation behavior, not the default for new assets.

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

## Git and Pull Requests

These rules extend and, where they differ, replace "Do not commit or push unless explicitly asked" in Workflow.

- **Never commit or push to `main`.** Everything reaches `main` through a pull request that the user merges. Never enable auto-merge.
- **Ask before committing new feature work.** Before the first commit of any feature, fix or art change, ask the user which branch it belongs on, or propose a branch name and wait for a yes. Do not decide silently and do not commit "to be safe". Committing is allowed only when the user asks for it.
- **One feature or one coherent update per branch and per PR, no hurry.** Do not pile unrelated work into one branch. If the working tree mixes topics, stop and split it: stage by path (never `git add -A` across topics) and use a separate branch per topic. Leave changes that are not yours uncommitted and tell the user.
- **Do not start a second feature on a branch that already has an open PR.** Branch from `main` (or ask what to stack on) instead.
- **Branch names:** `feat/<slug>`, `fix/<slug>`, `art/<slug>`, `docs/<slug>`, `chore/<slug>`; briefs for workers use `task/<id>` (see `tasks/README.md`).
- **Pull requests** use `.github/pull_request_template.md`: summary, scope, what changed, screenshots per feature, how to verify, risks and what was not verified. The title says what the PR does in one line; the body is English. Follow `docs/PR_WORKFLOW.md` for the screenshots.
- **Label every PR when opening it** (`gh pr create --label ...`, or `gh pr edit --add-label` afterwards), using the Backlog labels: every `area:*` the diff touches (tooling, CI and agent docs are `area:process`), exactly one `type:*`, and the linked issue's `leverage:*`. Never put `ready` on a PR. If the scope changes later, update the labels too.
- A worker's result (`task/<id>` branch) is integrated by the lead through its own PR, one PR per brief or per coherent group the user approves.

## Backlog

- The backlog is GitHub Issues of this repository: one issue is one future feature or coherent update, which becomes one branch and one PR. Do not keep a second list in a Markdown file.
- Labels: area (`area:map`, `area:sim`, `area:ui`, `area:art`, `area:story`, `area:process`), type (`type:feature`, `type:fix`, `type:question`), `leverage:high|med|low` (interview value, see the global career focus) and `ready` (acceptance criteria exist and, for delegated work, a brief in `tasks/`).
- An issue gets `ready` only with a "Done when" statement. Open design questions are `type:question` and stay out of `ready` until answered; record answers in `README.md`.
- Pick the next item by `leverage` first, then by what it unblocks; say plainly when an item is low value.
- Every PR starts with `Closes #n` (or `Refs #n`); the issue closes when the PR is merged. A brief in `tasks/` names its issue in `issue:`.
- List and update issues with `gh issue list --label ready` and `gh issue edit`; do not change issue state or labels on someone else's behalf without being asked.
