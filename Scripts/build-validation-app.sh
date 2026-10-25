#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
DERIVED_PATH="$PROJECT_ROOT/.build/1.4-validation"
OUTPUT_APP_PATH="$PROJECT_ROOT/dist/validation-1.4/Ayami.app"
SIGNING_IDENTITY="${AYAMI_SIGNING_IDENTITY:-Apple Development}"

cd "$PROJECT_ROOT"
xcodegen generate --spec project.yml
xcodebuild -project Ayami.xcodeproj -scheme Ayami -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$DERIVED_PATH" \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=ZLX73742D3 build

BUILT_APP="$DERIVED_PATH/Build/Products/Debug/Ayami.app"
EXTENSION_PATH="$BUILT_APP/Contents/PlugIns/AyamiQuickLook.appex"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$BUILT_APP/Contents/Info.plist")" == 1.4 ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$BUILT_APP/Contents/Info.plist")" == 19 ]]
[[ "$(lipo -archs "$BUILT_APP/Contents/MacOS/Ayami")" == arm64 ]]
[[ "$(lipo -archs "$EXTENSION_PATH/Contents/MacOS/AyamiQuickLook")" == arm64 ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionAttributes:QLIsDataBasedPreview' "$EXTENSION_PATH/Contents/Info.plist")" == true ]]
codesign --verify --deep --strict "$BUILT_APP"

mkdir -p "$PROJECT_ROOT/dist/validation-1.4"
if [[ -e "$OUTPUT_APP_PATH" ]]; then
  PREVIOUS_ROOT="$(mktemp -d "$PROJECT_ROOT/.build/previous-validation-app.XXXXXX")"
  mv "$OUTPUT_APP_PATH" "$PREVIOUS_ROOT/Ayami.app"
  print "Previous validation build preserved at $PREVIOUS_ROOT/Ayami.app"
fi
ditto "$BUILT_APP" "$OUTPUT_APP_PATH"
print "Built Ayami 1.4 (19), arm64 only: $OUTPUT_APP_PATH"
print "Local validation only. Nothing was uploaded, submitted, or released."
