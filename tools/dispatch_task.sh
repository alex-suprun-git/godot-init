#!/usr/bin/env bash
# Dispatch a brief from tasks/<id>.md to Codex in its own git worktree.
#
#   tools/dispatch_task.sh <id>            create the worktree and start Codex in the background
#   tools/dispatch_task.sh <id> --status   show the brief status and the tail of the log
#
# Worktree: ../godot-worktrees/<id> on branch task/<id>, cut from the current HEAD.
# Logs:     tasks/logs/<id>.jsonl (events) and tasks/logs/<id>.last.md (final message).
set -euo pipefail

repo="$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)"
id="${1:?usage: dispatch_task.sh <id> [--status]}"
brief="$repo/tasks/$id.md"
worktree="$(dirname "$repo")/godot-worktrees/$id"
logs="$repo/tasks/logs"

if [[ "${2:-}" == "--status" ]]; then
  grep -m1 '^status:' "$worktree/tasks/$id.md" 2>/dev/null || echo "no worktree brief yet"
  tail -n 5 "$logs/$id.jsonl" 2>/dev/null || true
  [[ -f "$logs/$id.last.md" ]] && { echo "--- final message ---"; cat "$logs/$id.last.md"; }
  exit 0
fi

[[ -f "$brief" ]] || { echo "missing brief: $brief" >&2; exit 1; }
mkdir -p "$logs"

if [[ ! -d "$worktree" ]]; then
  git -C "$repo" worktree add -b "task/$id" "$worktree" HEAD
fi
# The brief may not be committed yet; the worker's copy travels back with its branch.
mkdir -p "$worktree/tasks"
cp "$brief" "$worktree/tasks/$id.md"
cp "$repo/tasks/README.md" "$worktree/tasks/README.md"

prompt="Execute the brief tasks/$id.md, following tasks/README.md and AGENTS.md.
You are the worker for this brief. Work only inside this worktree and write only to the brief's Outputs.
Set the brief's status to in-progress when you start. Commit your work on branch task/$id.
Finish by filling in the brief's Report and setting status to review or blocked."

# codex exec uses ChatGPT-account auth, which rejects some models the desktop app
# accepts (gpt-6.1-terra from config.toml failed with model_not_found).
nohup codex exec \
  --model "${CODEX_MODEL:-gpt-6.1-sol}" \
  --cd "$worktree" \
  --sandbox workspace-write \
  -c sandbox_workspace_write.network_access=true \
  --json \
  --output-last-message "$logs/$id.last.md" \
  "$prompt" </dev/null >"$logs/$id.jsonl" 2>&1 &

echo "dispatched $id: pid $!, worktree $worktree"
echo "status: tools/dispatch_task.sh $id --status"
