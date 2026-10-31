# Task briefs for parallel work

Work that runs in parallel with the main session (for example asset production by Codex while mechanics are built in the main checkout) is handed over as a brief in this folder, not through chat. A brief survives closed chats: any agent can resume from it.

## Roles

- **Lead / integrator** (the main session, currently Claude): writes briefs, reviews results, integrates them into the game and owns the shared integration files listed below.
- **Workers** (currently Codex): execute one brief each, in their own git worktree and branch, and write a report back into the brief.
- **The user** is the creative lead and approves visual and design choices.

## File ownership

Parallel work stays conflict-free when each brief writes only to the paths listed under *Outputs*. Workers never edit:

- `init/scripts/`, `init/*.tscn` and other scenes;
- `init/scripts/data/sprite_anchors.gd` (refreshed by the integrator);
- `README.md` and `AGENTS.md`;
- another brief's outputs.

Wiring an asset into a scene or script is integration and belongs to the lead. A worker that needs a change outside its outputs records it under *Report → Requests for the integrator* instead of making it.

## Lifecycle

1. The lead copies `_TEMPLATE.md` to `tasks/<id>.md` and fills in the brief. `status: ready`.
2. The brief is dispatched, either by hand ("Execute `tasks/<id>.md`" in Codex) or with `tools/dispatch_task.sh <id>`, which creates the worktree `../godot-worktrees/<id>` on branch `task/<id>` and runs `codex exec` in the background.
3. The worker sets `status: in-progress`, works only inside its worktree, commits on its branch and fills in *Report*. It ends with `status: review` or `status: blocked`.
4. The lead reads the report and outputs, merges the branch, integrates, checks the game (autoplay screenshots) and sets `status: done`, or appends review notes and sets `status: ready` for another round.

## Shared resources

- **Blender**: Blender MCP drives one live Blender instance. Run at most one Blender brief at a time.
- **Godot import cache**: a fresh worktree has no `.godot/`. Run `Godot --headless --path init --import` inside the worktree before using Godot there.
- **Uncommitted work**: a worktree starts from the last commit, so it does not see uncommitted changes in the main checkout. Commit anything a brief depends on before dispatching it.
