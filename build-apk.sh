#!/usr/bin/env bash
# Build a release APK named after the pubspec version:
#   ./build-apk.sh   ->   kinetic-v0.1.4.apk
# Extra args pass through to `flutter build apk`
# (e.g. --dart-define=SUPABASE_URL=... for the sync build).
set -euo pipefail
cd "$(dirname "$0")"

export PATH="$HOME/development/flutter/bin:$PATH"
flutter --no-version-check build apk --release "$@"

version=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d+ -f1)
cp build/app/outputs/flutter-apk/app-release.apk "kinetic-v${version}.apk"
echo "-> kinetic-v${version}.apk"
