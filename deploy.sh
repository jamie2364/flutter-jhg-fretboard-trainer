#!/bin/bash

# --- JHG Global Deploy Wrapper ---
# Finds the jhg_deploy.sh script from the flutter_jhg_elements package
# already downloaded in Flutter's pub-cache (via git dependency).
# No GitHub token or internet connection needed beyond initial flutter pub get.
# Use pub get here, not pub upgrade. Deployment should use the versions already
# resolved by pubspec.lock instead of moving dependencies right before release.
flutter pub get

# --- Preflight: fastlane must be configured, or fastlane drops into its
# interactive setup wizard mid-deploy and waits for an Apple ID by hand.
export FASTLANE_SKIP_UPDATE_CHECK=1
export FASTLANE_HIDE_CHANGELOG=1
export FASTLANE_DISABLE_COLORS=0
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export LANG="${LANG:-en_US.UTF-8}"

MISSING=""
for f in \
  ios/fastlane/Appfile \
  ios/fastlane/Fastfile \
  ios/fastlane/auth/AuthKey_F8YM6T4L3V.p8 \
  android/fastlane/Appfile \
  android/fastlane/Fastfile \
  android/fastlane/auth/play-store-credentials.json \
  release_notes/whats_new.txt \
  .env; do
  [ -e "$f" ] || MISSING="$MISSING\n   - $f"
done

if [ -n "$MISSING" ]; then
  echo "❌ Deployment aborted. Missing fastlane/deploy files:"
  printf "$MISSING\n"
  echo
  echo "   Copy them from a sibling app (e.g. ../flutter-jhg-tuner) and edit the"
  echo "   bundle id in ios/fastlane/Appfile and the package name in android/fastlane/Appfile."
  exit 1
fi

PUB_CACHE_DIR="${PUB_CACHE:-$HOME/.pub-cache}"

# Read the exact commit hash Flutter resolved for flutter_jhg_elements from pubspec.lock
ELEMENTS_HASH=$(grep -A 10 "flutter_jhg_elements:" pubspec.lock | grep "resolved-ref:" | head -n 1 | awk '{print $2}' | tr -d '"')

if [ -n "$ELEMENTS_HASH" ]; then
  SCRIPT_PATH="$PUB_CACHE_DIR/git/flutter_jhg_elements-$ELEMENTS_HASH/scripts/jhg_deploy.sh"
else
  # Fallback: find the most recently modified version in pub-cache
  SCRIPT_PATH=$(find "$PUB_CACHE_DIR/git" -name "jhg_deploy.sh" -path "*flutter_jhg_elements*" 2>/dev/null \
    | xargs ls -t 2>/dev/null | head -n 1)
fi

if [ -z "$SCRIPT_PATH" ]; then
  echo "❌ Could not find jhg_deploy.sh in Flutter pub-cache."
  echo "   Make sure flutter_jhg_elements is listed as a git dependency and run:"
  echo "   flutter pub get"
  exit 1
fi

echo "✅ Found deploy script at: $SCRIPT_PATH"
bash "$SCRIPT_PATH" "$@"
