# Task briefs for parallel work

Work that runs in parallel with the main session (for example asset production by Codex while mechanics are built in the main checkout) is handed over as a brief in this folder, not through chat. A brief survives closed chats: any agent can resume from it.

## Current task index

Audited against the main checkout and existing reports on 2026-11-01. This was a file/documentation audit, not a new gameplay run. `ready` means work remains; `review` does not imply final user approval.

| Brief | Status | Actual state / next action |
| --- | --- | --- |
| [bridge-materials](bridge-materials.md) | review | Concrete, ballast and steel integrated; three overpasses and river bridges inspected in both cameras and at night. Final appearance review pending. |
| [bridge-texel-density](bridge-texel-density.md) | ready | #31: measure screen px per metre, resize bridge detail to ≥ 3 px, before/after for user approval. |
| [sidewalk-textures](sidewalk-textures.md) | review | Slabs/asphalt integrated and visually inspected; user feedback addressed with stronger asphalt detail and orthographic clipping fix. Corrected day/night/winter captures inspected; northern approach now asphalt with treeless median, current junction capture v3 ready for review. |
| [map-edges-traffic](map-edges-traffic.md) | review | Haze, seven gateways and traffic recycling implemented in the current base branch; remaining observations and visual review are recorded in its brief. |
| [freight-vehicles](freight-vehicles.md) | review | Food ZIL, coal ZIL and container KamAZ multi-view references generated and inspected; appearance and container interpretation await review. Reference scope only. |
| [traffic-lights](traffic-lights.md) | planned | Reference exists; model, fixture integration and intersection registry remain. |
| [civic-vehicles](civic-vehicles.md) | in-progress | Police UAZ and RAF-22031 ambulance reference directions approved; resolve technical details, then model police first and RAF next. No GLBs yet. |
| [d4-building-art](d4-building-art.md) | ready | New facade outputs are absent; D4 still uses existing placeholder textures. |
| [elite-towers](elite-towers.md) | ready | Reference sheets and new tower textures are absent; three placeholders exist in the map. |
| [volga-gaz24-model](volga-gaz24-model.md) | review | GLB integrated. Final shape review and consolidation of editable sources from the asset worktree remain. |
| [market-rework](market-rework.md) | review | Combined 2D v7 integrated; final in-game framing review remains. Separate 3D stalls are deferred. |
| [situation-banners](situation-banners.md) | review | All eleven prepared images, originals and optimization reports exist. HUD already loads images automatically by request ID; only final visual review remains. |

Completed briefs are moved to `tasks/archive/`, preserving reports and review evidence rather than deleting them:

- [d4-rebuild](archive/d4-rebuild.md): implemented placeholder layout, recorded checks and user approval; verified current lots/catalog entries exist. Replacement art is tracked separately above.

## Roles

Claude Code and Codex are equal desktop sessions on the same checkout (see `AGENTS.md`, "Roles and Parallel Work"). A brief is a shared note that survives closed chats; either session can pick one up. The user coordinates and approves visual and design choices.

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
4. The lead reads the report and outputs, merges the branch, integrates, checks the game (autoplay screenshots) and sets `status: done`, or appends review notes and sets `status: ready` for another round. Completed briefs can then move to `tasks/archive/`; update references and the current task index when archiving.

## Shared resources

- **Blender**: Blender MCP drives one live Blender instance. Run at most one Blender brief at a time.
- **Godot import cache**: a fresh worktree has no `.godot/`. Run `Godot --headless --path init --import` inside the worktree before using Godot there.
- **Uncommitted work**: a worktree starts from the last commit, so it does not see uncommitted changes in the main checkout. Commit anything a brief depends on before dispatching it.
