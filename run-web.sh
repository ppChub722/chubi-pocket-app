#!/usr/bin/env bash
# Run chubiPocket in Chrome at phone size, pointed at the live VPS backend.
# Usage: ./run-web.sh            (phone size 412x915)
#        ./run-web.sh 390 844    (custom width height)
set -euo pipefail
cd "$(dirname "$0")"

W="${1:-412}"
H="${2:-915}"

exec ./.fvm/flutter_sdk/bin/flutter run -d chrome \
  --web-browser-flag="--window-size=${W},${H}" \
  --dart-define=API_BASE_URL=https://chubipocket-api.ppforge.dev/api/v1
