#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
# Exit immediately if a command exits with a non-zero status.
# set -e  <-- DISABLED GLOBAL EXIT to handle per-platform errors gracefully

#NOTE: 

# Always use the following variables for deployment change on base of the app.
# DEPLOY_APP_SLUG="JHG Vocal Separator" 
# APP_NAME="JHG Vocal Separator"
# WEB_APP_SLUG="mt-vocal-separator"

# use the following command to store the notarytool credentials in mac for macos deployment
# xcrun notarytool store-credentials "JHGAppsProfile" \
#  --key "ios/fastlane/auth/AuthKey_F8YM6T4L3V.p8" \
#  --key-id "F8YM6T4L3V" \
#  --issuer "ca5f4edc-93a1-4df0-b445-d03b4905f203"


# Make the script aware of the rbenv environment if you use it.
export PATH="$HOME/.rbenv/shims:$PATH"

# --- Helper Functions for Colored Output ---
color_green() {
  echo -e "\033[0;32m$1\033[0m"
}
color_blue() {
  echo -e "\033[0;34m$1\033[0m"
}
color_yellow() {
  echo -e "\033[0;33m$1\033[0m"
}
color_red() {
  echo -e "\033[0;31m$1\033[0m"
}

# --- ⭐️ CONFIGURATION ⭐️ ---

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  set -a # Automatically export all variables
  source .env
  set +a
fi

# Your app's core configuration details
APP_NAME="JHG Fretboard Trainer"
WEB_APP_SLUG="mt-fretboard-trainer"
CODE_SIGN_IDENTITY="Developer ID Application: Jamie Harrison Media Ltd. (WY4JPY3VA6)"
KEYCHAIN_PROFILE="JHGAppsProfile" # Profile name in your local Keychain

# Custom Server Deployment Configuration
DEPLOY_API_TOKEN="24e82fb369136d50e2d12689a3b91f11"
DEPLOY_APP_SLUG="JHG Fretboard Trainer"
DEPLOY_URL_MAC="https://musictools.io/wp-json/mt-apps/v1/deploy-mac"
DEPLOY_URL_WEB="https://musictools.io/wp-json/mt-apps/v1/deploy-web"

# --- CUSTOM SERVER UPLOAD FUNCTION ---
upload_to_custom_server() {
  local local_file_path=$1
  local remote_subdirectory=$2
  local is_raw=$3 # true or false (default true if not provided)
  local target_app_slug=$4
  local deploy_url=$5
  local file_param_name=$6
  
  local filename=$(basename "$local_file_path")
  
  if [ -z "$is_raw" ]; then
    is_raw="true"
  fi

  if [ -z "$target_app_slug" ]; then
    target_app_slug="$DEPLOY_APP_SLUG"
  fi

  if [ -z "$deploy_url" ]; then
    deploy_url="$DEPLOY_URL_MAC"
  fi

  if [ -z "$file_param_name" ]; then
    file_param_name="file"
  fi
  
  color_blue "⬆️ Uploading $filename to Musictools.io Server..."
  color_yellow "   - Target Subdirectory: $remote_subdirectory"
  color_yellow "   - URL: $deploy_url"
  
  response=$(curl -s -w "\n%{http_code}" -X POST \
    -H "X-Deploy-Token: $DEPLOY_API_TOKEN" \
    -F "app_name=$target_app_slug" \
    -F "subdir=$remote_subdirectory" \
    -F "raw_file=$is_raw" \
    -F "$file_param_name=@$local_file_path" \
    "$deploy_url")

  # Extract body and status code
  http_body=$(echo "$response" | sed '$d')
  http_code=$(echo "$response" | tail -n 1)

  if [ "$http_code" -eq 200 ]; then
    color_green "✅ Successfully uploaded $filename."
    # echo "Response: $http_body"
  else
    color_red "❌ Failed to upload $filename. HTTP response code: $http_code"
    color_red "   Server Response: $http_body"
    exit 1
  fi
  echo
}

# --- METADATA JSON GENERATION FUNCTION ---
generate_and_upload_json() {
  local dmg_path=$1
  local json_path="${dmg_path%.dmg}-metadata.json"

  color_blue "⚙️Generating system requirements JSON..."

  # Read version from pubspec.yaml
  APP_VERSION=$(grep 'version:' pubspec.yaml | cut -d ' ' -f 2)
  MACOS_MIN_VERSION=$(grep -m 1 "platform :osx" macos/Podfile | sed "s/.*'\(.*\)'/\1/")
  LAST_UPDATED=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  FILE_SIZE_BYTES=$(stat -f%z "$dmg_path")
  FILE_SIZE_MB=$(echo "scale=1; $FILE_SIZE_BYTES / 1024 / 1024" | bc)

  cat > "$json_path" <<EOF
{
"appName": "$APP_NAME",
"version": "$APP_VERSION",
"lastUpdated": "$LAST_UPDATED",
"systemRequirements": {
"platform": "macOS",
"minimumVersion": "$MACOS_MIN_VERSION",
"architecture": "Apple Silicon & Intel (Universal)"
},
"download": {
"fileType": "DMG",
"fileSizeMB": $FILE_SIZE_MB
}
}
EOF

  color_green "✅ JSON metadata file created at $json_path"
  upload_to_custom_server "$json_path" "Mac" "true" "" "$DEPLOY_URL_MAC" "file"
}

# --- Main Build Process ---

# --- Command-line argument parsing for skipping platforms ---
BUILD_MACOS=true
BUILD_IOS=true
BUILD_ANDROID=true
BUILD_WEB=true

# --- Command-line argument parsing for skipping platforms ---
BUILD_MACOS=true
BUILD_IOS=true
BUILD_ANDROID=true
BUILD_WEB=true

# Initialize Status Variables
STATUS_MACOS="SKIPPED"
STATUS_WEB="SKIPPED"
STATUS_IOS="SKIPPED"
STATUS_ANDROID="SKIPPED"

# --- 🛑 CRITICAL SETUP SECTION (Exit on failure) ---
# We enable set -e for the setup phase because if this fails, nothing can be built.
set -e

for arg in "$@"; do
  case $arg in
  --skip-macos)
    BUILD_MACOS=false
    shift
    ;;
  --skip-ios)
    BUILD_IOS=false
    shift
    ;;
  --skip-android)
    BUILD_ANDROID=false
    shift
    ;;
  --skip-web)
    BUILD_WEB=false
    shift
    ;;
  *)
    color_yellow "⚠️Warning: Unrecognized argument '$arg' will be ignored."
    shift
    ;;
  esac
done

color_green "🚀 Starting Full build process..."
echo

# 🔐 CRITICAL FIX: Unlock Keychain before codesigning starts
if [ "$BUILD_MACOS" = true ]; then
  color_blue "🔐 Authenticating to unlock Keychain for code signing..."
  # Assuming $KEYCHAIN_PASSWORD environment variable is set.
  # If not set, the user will need to set it before running the script.
  security unlock-keychain -p "$KEYCHAIN_PASSWORD" || {
    color_red "❌ Failed to unlock login keychain. Ensure KEYCHAIN_PASSWORD environment variable is set and correct."
    # We exit gracefully because code signing will fail anyway
  }
fi
echo

color_blue "Configuration:"
color_blue "Build macOS: $BUILD_MACOS"
color_blue "Build iOS: $BUILD_IOS"
color_blue "Build Android: $BUILD_ANDROID"
color_blue "Build Web: $BUILD_WEB"
echo

# 1. Fetch Latest Version and Build Info
color_blue "🔎 Fetching latest version info..."
cd "$(dirname "$0")"

# --- Fetch version directly from pubspec.yaml ---
color_yellow " - Reading version from pubspec.yaml..."
original_full_version_string=$(grep 'version:' pubspec.yaml | cut -d ' ' -f 2)
current_version=$(echo "$original_full_version_string" | cut -d '+' -f 1)

if [ -z "$current_version" ]; then
  color_red "❌ Version not found in pubspec.yaml."
  exit 1
fi

PROJECT_NAME=$(grep 'name:' pubspec.yaml | cut -d ' ' -f 2)
if [ -z "$PROJECT_NAME" ]; then
    color_yellow "⚠️  Could not determine project name from pubspec.yaml. Defaulting to '$APP_NAME'."
    PROJECT_NAME="$APP_NAME"
fi
color_blue "ℹ️  Project Name: $PROJECT_NAME"
color_blue "ℹ️  Target App Name: $APP_NAME"

# --- Fetch build numbers from the stores ---
color_yellow " - Fetching latest build numbers from stores..."
latest_ios_build_raw=$( (cd ios && bundle exec fastlane get_latest_build version:"$current_version") 2>/dev/null | grep "Result:" | tail -n 1 | awk '{print $NF}' )
latest_ios_build=${latest_ios_build_raw:-0}
color_green "✅ Latest iOS build for version $current_version is: $latest_ios_build"

# --- NEW: Check all tracks for Android to find the true latest version code ---
color_yellow " - Checking all Android tracks for the latest version code..."

# --- ⭐️ FIX 1: Patched get_track_version function ---
# This version hides fastlane errors (2>/dev/null) and adds '|| true' to prevent
# 'set -e' from exiting if fastlane fails (e.g., on an empty track).
# It defaults to "0" if no version codes are found.
get_track_version() {
  local version_codes
  version_codes=$((cd android && bundle exec fastlane run google_play_track_version_codes track:$1) 2>/dev/null | grep "Result:" | tail -n 1 | sed -E 's/.*\[(.*)\].*/\1/' | tr ',' '\n' | sort -nr | head -1 || true)
  echo "${version_codes:-0}"
}

prod_version=$(get_track_version "production")
beta_version=$(get_track_version "beta")
alpha_version=$(get_track_version "alpha")
internal_version=$(get_track_version "internal")

# Find the maximum version code from all tracks
latest_android_build_raw=$(printf "%s\n" "${prod_version:-0}" "${beta_version:-0}" "${alpha_version:-0}" "${internal_version:-0}" | sort -nr | head -1)
latest_android_build=${latest_android_build_raw:-0}
color_green "✅ Latest Android build is: $latest_android_build"

# --- Determine the true highest build number ---
clean_ios_build=$(echo "$latest_ios_build" | tr -d -c 0-9)
clean_android_build=$(echo "$latest_android_build" | tr -d -c 0-9)
clean_ios_build=${clean_ios_build:-0}
clean_android_build=${clean_android_build:-0}

if [ "$clean_ios_build" -gt "$clean_android_build" ]; then
  highest_build=$clean_ios_build
else
  highest_build=$clean_android_build
fi
color_blue "➡️Current version is $current_version with highest build number $highest_build."
echo

# --- Pre-calculate next values ---
major=$(echo "$current_version" | cut -d '.' -f 1 | tr -d -c 0-9)
minor=$(echo "$current_version" | cut -d '.' -f 2 | tr -d -c 0-9)
patch=$(echo "$current_version" | cut -d '.' -f 3 | tr -d -c 0-9)
next_patch=$((patch + 1))
next_version_prefix="$major.$minor.$next_patch"
next_build_code=$((highest_build + 1))

# --- Automatically Increment Version and Build ---
color_yellow "➡️Automatically incrementing VERSION and BUILD number..."
new_version_name="$next_version_prefix"
ios_build_number=$((clean_ios_build + 1))
android_build_number=$next_build_code
pubspec_build_number=1
color_blue "⬆️Setting new version to ${new_version_name} (iOS Build: ${ios_build_number}, Android Build: ${android_build_number})"

new_full_version="${new_version_name}+${pubspec_build_number}"

sed -i '' "s/version: $original_full_version_string/version: $new_full_version/" pubspec.yaml
color_green "✅ pubspec.yaml updated to version $new_full_version"
echo

# 2. Clean and get dependencies
color_blue "🧹 Cleaning and fetching dependencies..."
flutter clean
flutter pub get
echo

# --- ✨ NEW: Load Release Notes from File ✨ ---
RELEASE_NOTES_PATH="release_notes/whats_new.txt"
WHATS_NEW_CONTENT=""
if [ -f "$RELEASE_NOTES_PATH" ]; then
  WHATS_NEW_CONTENT=$(cat "$RELEASE_NOTES_PATH")
  color_green "✅ Loaded release notes from $RELEASE_NOTES_PATH"
else
  if [ "$BUILD_IOS" = true ] || [ "$BUILD_ANDROID" = true ]; then
    color_red "❌ Release notes file not found at '$RELEASE_NOTES_PATH'. This is required for iOS/Android builds."
    exit 1
  fi
fi
echo

# --- END CRITICAL SETUP SECTION ---
set +e  # Disable automatic exit for the platform build phases


# --- macOS DEPLOYMENT ---
if [ "$BUILD_MACOS" = true ]; then
  color_blue "🚀 Starting macOS Build & Deployment..."
  
  # Run in a subshell with set -e and pipefail to stop execution of this block on first error
  if (
    set -e
    set -o pipefail
    
    color_green "🍎 Building for macOS..."
    flutter build macos --release
    color_green "✅ macOS build completed."
    echo

    # Define paths
    BUILD_DIR="build/macos/Build/Products/Release"
    BUILT_APP_PATH="$BUILD_DIR/$PROJECT_NAME.app"
    TARGET_APP_PATH="$BUILD_DIR/$APP_NAME.app"

    # Rename if necessary
    # Rename if necessary
    if [ "$PROJECT_NAME" != "$APP_NAME" ]; then
        # Check if the expected built app exists, if not, search for ANY .app file
        if [ ! -d "$BUILT_APP_PATH" ] && [ ! -d "$TARGET_APP_PATH" ]; then
             # Find the first .app directory in the build folder
             # We use head -n 1 to just take the first one found if multiple exist (unlikely in fresh build)
             FOUND_APP=$(find "$BUILD_DIR" -maxdepth 1 -name "*.app" | head -n 1)
             if [ -n "$FOUND_APP" ]; then
                 color_yellow "⚠️  Could not find '$BUILT_APP_PATH', but found '$FOUND_APP'. Using it."
                 BUILT_APP_PATH="$FOUND_APP"
             fi
        fi

        if [ -d "$BUILT_APP_PATH" ]; then
            color_blue "🔄 Renaming '$(basename "$BUILT_APP_PATH")' to '$APP_NAME.app'..."
            rm -rf "$TARGET_APP_PATH"
            mv "$BUILT_APP_PATH" "$TARGET_APP_PATH"
        elif [ -d "$TARGET_APP_PATH" ]; then
             color_yellow "ℹ️  '$TARGET_APP_PATH' already exists. Using it."
        else
             color_red "❌ Could not find built app at '$BUILT_APP_PATH' or '$TARGET_APP_PATH'."
             color_red "   Contents of $BUILD_DIR:"
             ls -1 "$BUILD_DIR"
             exit 1
        fi
    fi
    
    APP_PATH="$TARGET_APP_PATH"
    if [ ! -d "$APP_PATH" ]; then
        color_red "❌ App bundle not found at '$APP_PATH'. Build may have failed."
        exit 1
    fi

    FRAMEWORKS_PATH="$APP_PATH/Contents/Frameworks"

    # --- ⭐️ CRITICAL FIX: Clear only insecure RPATHs ---
    color_blue "🧹 Cleaning insecure RPATHs from binaries..."
    find "$APP_PATH/Contents" -type f \( -name "*.dylib" -o -perm +111 \) | while read -r file; do
      
      # 1. Delete ONLY absolute, insecure RPATHs that point to the build directory.
      # We look for paths starting with /Users, /Volumes, or /opt (for homebrew)
      # We leave relative paths like @rpath or @loader_path alone, as they are needed.
      otool -l "$file" | grep -A 2 LC_RPATH | grep 'path ' | awk '{print $2}' | grep -E '^(/Users|/Volumes|/opt)' | while read -r rpath; do
        color_yellow "   > Removing insecure rpath: $rpath from $file"
        install_name_tool -delete_rpath "$rpath" "$file" 2>/dev/null || true
      done
    done
    color_green "✅ Insecure RPATH cleaning complete."
    echo

    # --- ⭐️ Patched macOS Code Signing (Deep Inside-Out) ⭐️ ---
    
    color_blue "✍️Performing robust inside-out code signing..."

    # Step 1: Sign all nested dylibs and frameworks (Plugins)
    color_yellow " - Signing all nested dynamic libraries and plugin frameworks..."

    # Find all dylibs and sign them
    find "$FRAMEWORKS_PATH" -name "*.dylib" | while read -r dylib; do
      codesign --force --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$dylib"
    done

    # Find all nested frameworks and sign the internal executable and the directory
    find "$FRAMEWORKS_PATH" -name "*.framework" | while read -r framework; do
      FRAMEWORK_EXECUTABLE="$(basename "$framework" .framework)"
      EXECUTABLE_PATH="$framework/Versions/A/$FRAMEWORK_EXECUTABLE"
      
      # Check if the expected executable path exists inside the framework bundle
      if [ -f "$EXECUTABLE_PATH" ]; then
        color_yellow "   > Signing executable inside: $FRAMEWORK_EXECUTABLE"
        codesign --force --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$EXECUTABLE_PATH"
      fi
      
      # Then sign the framework directory itself (ensures resources are covered)
      color_yellow "   > Re-signing framework directory: $FRAMEWORK_EXECUTABLE"
      codesign --force --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$framework"
    done

    # Step 2: Explicitly sign the main Flutter and App executables (Using Full Descriptive Name)
    color_yellow " - Signing core Flutter and App executables..."
    codesign --force --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$FRAMEWORKS_PATH/FlutterMacOS.framework/Versions/A/FlutterMacOS"
    codesign --force --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$FRAMEWORKS_PATH/App.framework/Versions/A/App"

    # Step 3: Sign the main application executable (The primary binary)
    color_yellow " - Signing main $APP_NAME executable..."
    # Entitlements are only applied to the .app bundle in Step 4
    codesign --force --options runtime --timestamp --sign "$CODE_SIGN_IDENTITY" "$APP_PATH/Contents/MacOS/$APP_NAME"

    # Step 4: Sign the entire app bundle (LAST STEP - IMPORTANT for Entitlements)
    color_yellow " - Signing the main app bundle with entitlements..."
    codesign --force --options runtime --timestamp --entitlements "macos/Runner/Release.entitlements" --sign "$CODE_SIGN_IDENTITY" "$APP_PATH"

    color_green "✅ App successfully code signed."
    echo
    
    color_blue "📦 Archiving and Notarizing app..."
    ARCHIVE_PATH="build/macos/Build/Products/Release/$APP_NAME.zip"
    ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"
    xcrun notarytool submit "$ARCHIVE_PATH" --keychain-profile "$KEYCHAIN_PROFILE" --wait
    color_green "✅ Notarization successful."
    echo

    color_blue "🔩 Stapling notarization ticket to the app..."
    xcrun stapler staple "$APP_PATH"
    color_green "✅ Stapling complete."
    echo

    color_blue "💿 Creating macOS disk image (.dmg)..."
    DMG_PATH="build/macos/Build/Products/Release/$APP_NAME.dmg"
    rm -f "$DMG_PATH"
    create-dmg \
      --window-size 600 400 \
      --icon-size 130 \
      --icon "$APP_NAME.app" 175 150 \
      --app-drop-link 425 150 \
      "$DMG_PATH" \
      "$APP_PATH"
    color_green "✅ macOS installer (.dmg) created."

    # Upload files to custom server
    upload_to_custom_server "$DMG_PATH" "Mac" "true" "" "$DEPLOY_URL_MAC" "file"
    generate_and_upload_json "$DMG_PATH"
  ); then
    STATUS_MACOS="SUCCESS"
    color_green "✅ macOS Deployment Finished Successfully."
  else
    STATUS_MACOS="FAILED"
    color_red "❌ macOS Deployment FAILED. Moving to next platform..."
  fi
fi

# --- WEB DEPLOYMENT ---
if [ "$BUILD_WEB" = true ]; then
  color_blue "🌍 Starting Web Build & Deployment..."
  
  if (
    set -e
    set -o pipefail
    color_green "🌍 Building Web App ($WEB_APP_SLUG)..."
    flutter build web --release
    
    # Update <base href="/"> to <base href="/music-tools-apps/$WEB_APP_SLUG/">
    color_blue "🔧 Updating base href in index.html..."
    sed -i '' "s|<base href=\"/\">|<base href=\"/music-tools-apps/$WEB_APP_SLUG/\">|g" build/web/index.html

    color_blue "📦 Zipping Web Build..."
    # Clean up previous zip if exists
    rm -f build/web_build.zip
    
    # Zip the contents of build/web
    (cd build/web && zip -r ../web_build.zip .)
    
    WEB_ZIP_PATH="build/web_build.zip"
    
    if [ -f "$WEB_ZIP_PATH" ]; then
      color_blue "⬆️ Deploying Web App..."
      # Upload with is_raw="false" (so it unzips) and explicit slug
      upload_to_custom_server "$WEB_ZIP_PATH" "" "false" "$WEB_APP_SLUG" "$DEPLOY_URL_WEB" "build_zip"
      color_green "✅ Web deployment completed."
    else
      color_red "❌ Failed to create web build zip."
      exit 1
    fi
  ); then
    STATUS_WEB="SUCCESS"
    color_green "✅ Web Deployment Finished Successfully."
    echo
  else
    STATUS_WEB="FAILED"
    color_red "❌ Web Deployment FAILED. Moving to next platform..."
    echo
  fi
fi

# --- iOS DEPLOYMENT ---
if [ "$BUILD_IOS" = true ]; then
  color_blue "🚀 Starting iOS Build & Deployment..."

  if (
    set -e
    set -o pipefail
    color_blue "🚀 Preparing and building iOS App (.ipa)..."

    # Install CocoaPods dependencies
    color_yellow " - Installing CocoaPods dependencies..."
    (cd ios && bundle exec pod install)
    color_green "✅ Pods installed."

    (cd ios && bundle exec fastlane set_version_and_build version_number:$new_version_name build_number:$ios_build_number)
    flutter build ipa --release
    color_green "✅ iOS build completed."
    echo

    color_blue "⬆️Uploading iOS App to App Store Connect & submitting for review..."
    IPA_PATH="build/ios/ipa/$PROJECT_NAME.ipa" 

    # Check if the expected IPA exists, if not, search for any .ipa
    if [ ! -f "$IPA_PATH" ]; then
        FOUND_IPA=$(find "build/ios/ipa" -maxdepth 1 -name "*.ipa" | head -n 1)
        if [ -n "$FOUND_IPA" ]; then
             color_yellow "⚠️  Could not find '$IPA_PATH', but found '$FOUND_IPA'. Using it."
             IPA_PATH="$FOUND_IPA"
        else
             color_red "❌ Could not find any .ipa file in build/ios/ipa/"
             exit 1
        fi
    fi

    # MODIFIED: Pass the changelog content to the fastlane command
    LOG_FILE=$(mktemp)
    if (cd ios && bundle exec fastlane app_store_release ipa_path:"../$IPA_PATH" changelog:"$WHATS_NEW_CONTENT") 2>&1 | tee "$LOG_FILE"; then
        # Check for specific Fastlane failure message even if exit code was 0
        if grep -q "fastlane finished with errors" "$LOG_FILE"; then
             color_red "❌ Fastlane reported errors (captured from logs). Failing build."
             rm -f "$LOG_FILE"
             exit 1
        fi
        rm -f "$LOG_FILE"
        color_green "✅ iOS deployment completed and submitted for review."
    else
        color_red "❌ Fastlane command failed with non-zero exit code."
        rm -f "$LOG_FILE"
        exit 1
    fi
  ); then
    STATUS_IOS="SUCCESS"
    color_green "✅ iOS Deployment Finished Successfully."
    echo
  else
    STATUS_IOS="FAILED"
    color_red "❌ iOS Deployment FAILED. Moving to next platform..."
    echo
  fi
fi

# --- ANDROID DEPLOYMENT ---
if [ "$BUILD_ANDROID" = true ]; then
  color_blue "🤖 Starting Android Build & Deployment..."

  if (
    set -e
    set -o pipefail
    color_blue "🤖 Building for Android (Release App Bundle)..."
    flutter build appbundle --release --build-name=$new_version_name --build-number=$android_build_number
    color_green "✅ Android build completed."
    echo

    color_blue "⬆️Uploading Android App to Google Play..."
    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
    # MODIFIED: Pass the changelog content to the fastlane command
    # MODIFIED: Pass the changelog content to the fastlane command
    LOG_FILE_ANDROID=$(mktemp)
    if (cd android && bundle exec fastlane release aab_path:"../$AAB_PATH" version_code:$android_build_number version_name:$new_version_name changelog:"$WHATS_NEW_CONTENT") 2>&1 | tee "$LOG_FILE_ANDROID"; then
        # Check for specific Fastlane failure message even if exit code was 0
        if grep -q "fastlane finished with errors" "$LOG_FILE_ANDROID"; then
             color_red "❌ Fastlane reported errors (captured from logs). Failing build."
             rm -f "$LOG_FILE_ANDROID"
             exit 1
        fi
        rm -f "$LOG_FILE_ANDROID"
        color_green "✅ Android deployment completed."
    else
        color_red "❌ Fastlane command failed with non-zero exit code."
        rm -f "$LOG_FILE_ANDROID"
        exit 1
    fi
  ); then
    STATUS_ANDROID="SUCCESS"
    color_green "✅ Android Deployment Finished Successfully."
    echo
  else
    STATUS_ANDROID="FAILED"
    color_red "❌ Android Deployment FAILED. Moving to next platform..."
    echo
  fi
fi

# --- SUMMARY REPORT ---
echo
echo "======================================"
echo "       🎉 DEPLOYMENT SUMMARY 🎉       "
echo "======================================"
echo

print_status() {
    local platform=$1
    local status=$2
    if [ "$status" == "SUCCESS" ]; then
        echo -e "${platform}: \033[0;32mSUCCESS ✅\033[0m"
    elif [ "$status" == "FAILED" ]; then
        echo -e "${platform}: \033[0;31mFAILED ❌\033[0m"
    else
        echo -e "${platform}: \033[0;33mSKIPPED ⏭️\033[0m"
    fi
}

print_status "macOS  " "$STATUS_MACOS"
print_status "Web    " "$STATUS_WEB"
print_status "iOS    " "$STATUS_IOS"
print_status "Android" "$STATUS_ANDROID"

echo
if [ "$STATUS_MACOS" == "FAILED" ] || [ "$STATUS_WEB" == "FAILED" ] || [ "$STATUS_IOS" == "FAILED" ] || [ "$STATUS_ANDROID" == "FAILED" ]; then
    color_yellow "⚠️  Some platforms failed to deploy. Check the logs above for details."
    exit 1
else
    color_green "✨ All requested platforms finished successfully!"
    exit 0
fi