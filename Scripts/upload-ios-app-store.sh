#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
cd "$PROJECT_ROOT"
ARCHIVE_PATH="$PROJECT_ROOT/dist/Ayami-iOS-AppStore.xcarchive"
APP_PATH="$ARCHIVE_PATH/Products/Applications/Ayami.app"
[[ -d "$APP_PATH" ]] || { print -u2 'Missing iOS archive'; exit 1; }
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Info.plist")" == '1.3' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_PATH/Info.plist")" == '18' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP_PATH/Info.plist")" == 'io.github.hshimomura.MDViewer' ]]
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" \
  -exportPath dist/iOSUpload -exportOptionsPlist Packaging/UploadOptions.plist \
  -allowProvisioningUpdates
