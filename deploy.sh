#!/bin/bash

# --- JHG Global Deploy Wrapper ---
# Finds the jhg_deploy.sh script from the flutter_jhg_elements package
# already downloaded in Flutter's pub-cache (via git dependency).
# No GitHub token or internet connection needed beyond initial flutter pub get.
flutter pub upgrade
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
