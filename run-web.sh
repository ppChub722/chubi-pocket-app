#!/usr/bin/env bash
# Run chubiPocket on the web and open it in the normal browser.
# Usage: ./run-web.sh              (live VPS backend)
#        ./run-web.sh local        (backend on this PC, localhost:8080)
#        PORT=5174 ./run-web.sh    (another port; default 5173)
#
# Phone size: open DevTools (F12) → device toolbar (Ctrl+Shift+M).
# flutter only serves (`-d web-server`); this script opens the page in the
# default browser once the server answers. r / R in this terminal still hot
# reload / restart it (refresh the browser tab after R).
set -euo pipefail
cd "$(dirname "$0")"

API="https://chubipocket-api.ppforge.dev/api/v1"
if [[ "${1:-}" == "local" ]]; then
  API="http://localhost:8080/api/v1"
  shift
  if ! curl -sf -o /dev/null http://localhost:8080/health; then
    echo "Local backend not answering on :8080 — start it first (chubi-pocket-be: docker compose up -d)." >&2
    exit 1
  fi
fi

PORT="${PORT:-5173}"
URL="http://localhost:${PORT}"

open_browser() {
  if command -v cmd.exe >/dev/null; then
    cmd.exe /c start "" "$1" >/dev/null 2>&1
  elif command -v open >/dev/null; then
    open "$1"
  else
    xdg-open "$1" >/dev/null 2>&1
  fi
}

(
  until curl -sf -o /dev/null "$URL"; do sleep 1; done
  open_browser "$URL"
) &

exec ./.fvm/flutter_sdk/bin/flutter run -d web-server --web-port="$PORT" \
  --dart-define=API_BASE_URL="$API"
