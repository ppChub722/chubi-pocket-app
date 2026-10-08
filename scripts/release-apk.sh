#!/usr/bin/env bash
# Build the release APK against the live API and send it to the testers
# through Firebase App Distribution (see ops-runbook.md §3).
#
#   ./scripts/release-apk.sh                 # notes = last commit subject
#   ./scripts/release-apk.sh -m "notes"
#
# Run from Git Bash (any cwd). Builds what is in the working tree. The build
# number is the commit count, so every release installs over the last one
# without touching pubspec.yaml. Needs `npx firebase-tools login` once.
set -euo pipefail

API="https://chubipocket-api.ppforge.dev/api/v1"
FIREBASE_APP="1:1059791337506:android:426c08daa2b6a91d5a327b"
# Not GROUPS: that name is a read-only bash builtin (your Unix group ids).
TESTER_GROUPS="firsttester"

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

notes=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--notes) notes="${2:-}"; shift ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

# The pinned SDK (FVM); the `flutter` on PATH is too old for this project.
FLUTTER="$HOME/fvm/versions/3.47.3/bin/flutter"
[[ -x "$FLUTTER" ]] || FLUTTER="$APP_DIR/.fvm/flutter_sdk/bin/flutter"

build="$(git rev-list --count HEAD)"
commit="$(git rev-parse --short HEAD)"
[[ -n "$notes" ]] || notes="$(git log -1 --format=%s) ($commit)"
if [[ -n "$(git status --porcelain)" ]]; then
  echo "⚠ chubi-pocket-app has uncommitted changes — they are in this build."
fi

echo "▶ building APK (build $build, commit $commit)"
"$FLUTTER" build apk --release --split-per-abi \
  --build-number="$build" \
  --dart-define=API_BASE_URL="$API"

apk="build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo "▶ uploading $apk to Firebase ($TESTER_GROUPS)"
npx -y firebase-tools appdistribution:distribute "$apk" \
  --app "$FIREBASE_APP" --groups "$TESTER_GROUPS" --release-notes "$notes"
echo "✓ APK build $build sent to $TESTER_GROUPS"
