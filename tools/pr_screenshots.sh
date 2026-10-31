#!/bin/bash
# Capture screenshots for a pull request.
#   tools/pr_screenshots.sh <feature-slug>                    run autoplay, list available shots
#   tools/pr_screenshots.sh <feature-slug> --pick a b c        keep the named shots (no .png)
#   tools/pr_screenshots.sh <feature-slug> --from <dir> --pick a   reuse an existing shots folder
# Output: docs/pr-assets/<feature-slug>/<shot>.png, resized to at most 1600 px.
set -euo pipefail

GODOT="${GODOT:-/Users/oleksiisuprun/Desktop/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SLUG="${1:?usage: tools/pr_screenshots.sh <feature-slug> [--from <dir>] [--pick <shot>...]}"
shift

FROM=""
PICKS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    --pick) shift; while [ $# -gt 0 ] && [[ "$1" != --* ]]; do PICKS+=("$1"); shift; done ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [ -z "$FROM" ]; then
  FROM="$(mktemp -d)"
  echo "Running the autoplay into $FROM (about 40 seconds)..."
  "$GODOT" --path "$ROOT/init" --no-log -- --autoplay --shots="$FROM" > "$FROM/autoplay.log" 2>&1 &
  PID=$!
  for _ in $(seq 1 120); do
    kill -0 "$PID" 2>/dev/null || break
    sleep 1
  done
  kill "$PID" 2>/dev/null || true
fi

if [ ${#PICKS[@]} -eq 0 ]; then
  echo "Available shots in $FROM (re-run with --from $FROM --pick <names>):"
  ls "$FROM" | grep '\.png$' | sed 's/\.png$//'
  exit 0
fi

OUT="$ROOT/docs/pr-assets/$SLUG"
mkdir -p "$OUT"
for shot in "${PICKS[@]}"; do
  src="$FROM/$shot.png"
  [ -f "$src" ] || { echo "missing: $src" >&2; exit 1; }
  sips -Z 1600 "$src" --out "$OUT/$shot.png" > /dev/null
  echo "$OUT/$shot.png ($(du -k "$OUT/$shot.png" | cut -f1) KB)"
done
echo "Next: read the images, commit them on their own, then embed them with commit permalinks (docs/PR_WORKFLOW.md)."
