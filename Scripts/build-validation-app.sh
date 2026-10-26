#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
DERIVED_PATH="$PROJECT_ROOT/.build/1.5-validation"
OUTPUT_APP_PATH="$PROJECT_ROOT/dist/validation-1.5/Ayami.app"
SIGNING_IDENTITY="${AYAMI_SIGNING_IDENTITY:-Apple Development}"

cd "$PROJECT_ROOT"
xcodegen generate --spec project.yml
xcodebuild -project Ayami.xcodeproj -scheme Ayami -configuration Debug \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$DERIVED_PATH" \
  CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=ZLX73742D3 build

BUILT_APP="$DERIVED_PATH/Build/Products/Debug/Ayami.app"
EXTENSION_PATH="$BUILT_APP/Contents/PlugIns/AyamiQuickLook.appex"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$BUILT_APP/Contents/Info.plist")" == 1.5 ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$BUILT_APP/Contents/Info.plist")" == 21 ]]
[[ "$(lipo -archs "$BUILT_APP/Contents/MacOS/Ayami")" == arm64 ]]
[[ "$(lipo -archs "$EXTENSION_PATH/Contents/MacOS/AyamiQuickLook")" == arm64 ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionAttributes:QLIsDataBasedPreview' "$EXTENSION_PATH/Contents/Info.plist")" == true ]]
codesign --verify --deep --strict "$BUILT_APP"

mkdir -p "$PROJECT_ROOT/dist/validation-1.5"
if [[ -e "$OUTPUT_APP_PATH" ]]; then
  # This path is a generated development copy. The verified build above remains
  # in DerivedData, so repeated local builds do not need binary backups.
  [[ -d "$OUTPUT_APP_PATH" && ! -L "$OUTPUT_APP_PATH" ]] || exit 1
  rm -rf -- "$OUTPUT_APP_PATH"
fi
ditto "$BUILT_APP" "$OUTPUT_APP_PATH"
# Register the final, retained copy as well as Xcode's intermediate build.
# Otherwise extension discovery can refer only to a disposable build location.
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
  -f -R -trusted "$OUTPUT_APP_PATH"
/usr/bin/pluginkit -a "$OUTPUT_APP_PATH/Contents/PlugIns/AyamiQuickLook.appex"
# ditto preserves Xcode's original bundle-directory timestamp even when the
# executable was rebuilt. Show when this validation package was refreshed.
touch "$OUTPUT_APP_PATH"
print "Built Ayami 1.5 (21), arm64 only: $OUTPUT_APP_PATH"
print "Local validation only. Nothing was uploaded, submitted, or released."
