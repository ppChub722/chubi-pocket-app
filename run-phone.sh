#!/usr/bin/env bash
# Run chubiPocket on a USB-connected Android phone.
# Usage: ./run-phone.sh                 (live VPS backend — default)
#        ./run-phone.sh local           (backend on this PC, over the USB cable)
#        ./run-phone.sh local --profile (anything after the mode goes to
#                                        `flutter run`: --profile, -d <id>, …)
#        ./run-phone.sh attach [local]  (reconnect, no rebuild — see below)
#
# attach: the app got closed / the terminal session ended, but the debug
# build is still installed. Opens it on the phone if it isn't running and
# `flutter attach`es with the same API URL, so r / R work again in seconds.
# (The API URL must match — hot restart recompiles with these defines.)
#
# local mode:
#  - starts ../chubi-pocket-be with `docker compose up -d --build` when
#    http://localhost:8080/health doesn't answer, and waits for it;
#  - `adb reverse tcp:8080 tcp:8080` makes the phone's localhost:8080 reach
#    this PC's 8080 through the cable — no LAN IP, works on any Wi-Fi.
#    Re-run the script after re-plugging the cable (the reverse is dropped).
#  - plain http needs `usesCleartextTraffic` — set in the debug/profile
#    manifests only; release builds stay https-only.
#
# Phone setup (once): Developer options → USB debugging on → plug in → allow
# this computer. `adb devices` should list it as "device".
set -euo pipefail
cd "$(dirname "$0")"

PROD_API="https://chubipocket-api.ppforge.dev/api/v1"
LOCAL_PORT=8080
PACKAGE="com.chubipocket.chubi_pocket"

ATTACH=false
if [[ $# -gt 0 && "$1" == "attach" ]]; then
  ATTACH=true
  shift
fi

MODE="prod"
if [[ $# -gt 0 && ( "$1" == "prod" || "$1" == "local" ) ]]; then
  MODE="$1"
  shift
fi

ADB="$(command -v adb || true)"
if [[ -z "$ADB" ]]; then
  for a in "${ANDROID_HOME:-}/platform-tools/adb.exe" \
           "${LOCALAPPDATA:-}/Android/Sdk/platform-tools/adb.exe" \
           "${ANDROID_HOME:-}/platform-tools/adb"; do
    if [[ -x "$a" ]]; then ADB="$a"; break; fi
  done
fi
if [[ -z "$ADB" ]]; then
  echo "adb not found — install Android SDK platform-tools or set ANDROID_HOME." >&2
  exit 1
fi

# Pick the phone unless the caller passed -d / --device-id.
DEVICE_ARGS=()
if [[ " $* " != *" -d "* && " $* " != *" --device-id"* ]]; then
  mapfile -t DEVICES < <("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1 }')
  if [[ ${#DEVICES[@]} -eq 0 ]]; then
    echo "No phone found. adb says:" >&2
    "$ADB" devices >&2
    echo "→ unlock the phone, allow USB debugging, and pick 'File transfer' mode." >&2
    exit 1
  fi
  if [[ ${#DEVICES[@]} -gt 1 ]]; then
    echo "More than one phone — pass -d <id>:" >&2
    printf '  %s\n' "${DEVICES[@]}" >&2
    exit 1
  fi
  DEVICE_ARGS=(-d "${DEVICES[0]}")
  export ANDROID_SERIAL="${DEVICES[0]}"
fi

if [[ "$MODE" == "local" ]]; then
  HEALTH="http://localhost:${LOCAL_PORT}/health"
  if ! curl -sf -o /dev/null "$HEALTH"; then
    if ! docker info >/dev/null 2>&1; then
      echo "Backend not running and Docker isn't up — start Docker Desktop, then re-run." >&2
      exit 1
    fi
    echo "Backend not running — starting ../chubi-pocket-be (docker compose)…"
    (cd ../chubi-pocket-be && docker compose up -d --build)
    for _ in $(seq 1 90); do
      curl -sf -o /dev/null "$HEALTH" && break
      sleep 2
    done
    if ! curl -sf -o /dev/null "$HEALTH"; then
      echo "Backend didn't come up — check: cd ../chubi-pocket-be && docker compose logs app" >&2
      exit 1
    fi
  fi
  echo "Backend OK at $HEALTH"
  "$ADB" reverse "tcp:${LOCAL_PORT}" "tcp:${LOCAL_PORT}" >/dev/null
  API="http://localhost:${LOCAL_PORT}/api/v1"
else
  API="$PROD_API"
fi

echo "API → $API"

if $ATTACH; then
  if ! "$ADB" shell pm path "$PACKAGE" >/dev/null 2>&1; then
    echo "App isn't installed on the phone — run ./run-phone.sh first." >&2
    exit 1
  fi
  if [[ -z "$("$ADB" shell pidof "$PACKAGE" | tr -d '\r')" ]]; then
    echo "Opening the app on the phone…"
    "$ADB" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 \
      >/dev/null 2>&1
  fi
  exec ./.fvm/flutter_sdk/bin/flutter attach "${DEVICE_ARGS[@]}" \
    --app-id "$PACKAGE" --dart-define=API_BASE_URL="$API" "$@"
fi

exec ./.fvm/flutter_sdk/bin/flutter run "${DEVICE_ARGS[@]}" \
  --dart-define=API_BASE_URL="$API" "$@"
