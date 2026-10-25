#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
cd "$PROJECT_ROOT"
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath .build/release-ios \
  -archivePath dist/Ayami-iOS-AppStore.xcarchive -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath dist/Ayami-iOS-AppStore.xcarchive \
  -exportPath dist/iOSAppStoreExport -exportOptionsPlist Packaging/ExportOptions.plist \
  -allowProvisioningUpdates
