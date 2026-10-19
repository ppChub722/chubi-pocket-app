#!/usr/bin/env bash
# Run chubiPocket in Chrome at phone size.
# Usage: ./run-web.sh              (phone size 412x915, live VPS backend)
#        ./run-web.sh local        (backend on this PC, localhost:8080)
#        ./run-web.sh 390 844      (custom width height; also after `local`)
#        PORT=5174 ./run-web.sh    (another port; default 5173)
#
# Why not `-d chrome --web-browser-flag=--window-size=W,H`:
#  - flutter splits that flag's value on commas, so Chrome got "915" as a URL
#    (→ an extra tab at http://0.0.3.147/) and no size at all;
#  - a normal (tabbed) Chrome window on Windows can't go narrower than ~500px
#    anyway — only an `--app` window (no tab strip) reaches phone width.
# So flutter only serves (`-d web-server`) and this script opens its own
# `--app` window once the server answers. r / R in this terminal still hot
# reload / restart it. Close the old window before re-running with another
# size: a still-open window on this profile keeps its original size.
set -euo pipefail
cd "$(dirname "$0")"

API="https://chubipocket-api.ppforge.dev/api/v1"
if [[ "${1:-}" == "local" ]]; then
  API="http://localhost:8080/api/v1"
  shift
  if ! curl -sf -o /dev/null http://localhost:8080/health; then
    echo "Local backend not answering on :8080 — run ../chubi-pocket-be/scripts/redeploy.ps1 first." >&2
    exit 1
  fi
fi

W="${1:-412}"
H="${2:-915}"
PORT="${PORT:-5173}"
URL="http://localhost:${PORT}"

CHROME="${CHROME_EXECUTABLE:-}"
if [[ -z "$CHROME" ]]; then
  for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" \
           "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" \
           "$(command -v google-chrome || true)" \
           "$(command -v chromium || true)"; do
    if [[ -n "$c" && -x "$c" ]]; then CHROME="$c"; break; fi
  done
fi
if [[ -z "$CHROME" ]]; then
  echo "Chrome not found — set CHROME_EXECUTABLE." >&2
  exit 1
fi

# Own profile → a fresh window that honours --window-size even when a normal
# Chrome is already open (it'd otherwise just add a tab there).
PROFILE="${TMPDIR:-/tmp}/chubi-pocket-chrome"
command -v cygpath >/dev/null && PROFILE="$(cygpath -w "$PROFILE")"

(
  until curl -sf -o /dev/null "$URL"; do sleep 1; done
  "$CHROME" --user-data-dir="$PROFILE" --window-size="${W},${H}" \
    --app="$URL" >/dev/null 2>&1
) &

exec ./.fvm/flutter_sdk/bin/flutter run -d web-server --web-port="$PORT" \
  --dart-define=API_BASE_URL="$API"
