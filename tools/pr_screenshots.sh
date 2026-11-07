#!/bin/bash
# Capture screenshots for a pull request.
#   tools/pr_screenshots.sh <feature-slug>                    run autoplay, list available shots
#   tools/pr_screenshots.sh <feature-slug> --pick a b c        keep the named shots (no .png)
#   tools/pr_screenshots.sh <feature-slug> --from <dir> --pick a   reuse an existing shots folder
# Output: ignored .local/pr-assets/<feature-slug>/<shot>.jpg (maximum edge 1600 px, JPEG quality 80).
set -euo pipefail

GODOT="${GODOT:-/c/Users/alexe/Desktop/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
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
  # Native Windows Godot cannot read Git Bash paths such as /tmp/...; convert them.
  NATIVE_FROM="$(cygpath -m "$FROM" 2>/dev/null || echo "$FROM")"
  NATIVE_ROOT="$(cygpath -m "$ROOT" 2>/dev/null || echo "$ROOT")"
  echo "Running the autoplay into $FROM (about 40 seconds)..."
  "$GODOT" --path "$NATIVE_ROOT/init" -- --autoplay --no-log --shots="$NATIVE_FROM" > "$FROM/autoplay.log" 2>&1 &
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

OUT="$ROOT/.local/pr-assets/$SLUG"
mkdir -p "$OUT"
for shot in "${PICKS[@]}"; do
  src="$FROM/$shot.png"
  [ -f "$src" ] || { echo "missing: $src" >&2; exit 1; }
  uv run --quiet --no-project --with Pillow==12.0.0 python -c '
import sys
from PIL import Image
image = Image.open(sys.argv[1]).convert("RGB")
image.thumbnail((1600, 1600))
image.save(sys.argv[2], "JPEG", quality=80)
' "$src" "$OUT/$shot.jpg"
  echo "$OUT/$shot.jpg ($(du -k "$OUT/$shot.jpg" | cut -f1) KB)"
done
echo "Next: inspect these local images, then upload them with gh pr create/edit --attach (docs/PR_WORKFLOW.md). Do not commit them."
