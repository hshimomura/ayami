#!/bin/zsh
set -euo pipefail
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
IPA_PATH="$PROJECT_ROOT/dist/1.4/iOSAppStoreExport/Ayami.ipa"
VERIFY_ROOT="$(mktemp -d /private/tmp/ayami-ios-verify.XXXXXX)"
trap '[[ "$VERIFY_ROOT" == /private/tmp/ayami-ios-verify.* ]] && rm -r -- "$VERIFY_ROOT"' EXIT
[[ -f "$IPA_PATH" ]] || { print -u2 'Missing App Store IPA'; exit 1; }
ditto -x -k "$IPA_PATH" "$VERIFY_ROOT"
APP_PATH="$VERIFY_ROOT/Payload/Ayami.app"
INFO_PATH="$APP_PATH/Info.plist"
codesign --verify --deep --strict "$APP_PATH"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INFO_PATH")" == 'io.github.hshimomura.MDViewer' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PATH")" == '1.4' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PATH")" == '20' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$INFO_PATH")" == '18.0' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleSupportedPlatforms:0' "$INFO_PATH")" == 'iPhoneOS' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :UIDeviceFamily:0' "$INFO_PATH")" == '1' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :UIDeviceFamily:1' "$INFO_PATH")" == '2' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :ITSAppUsesNonExemptEncryption' "$INFO_PATH")" == 'false' ]]
[[ "$(lipo -archs "$APP_PATH/Ayami")" == 'arm64' ]]
codesign -d --entitlements :- "$APP_PATH" > "$VERIFY_ROOT/entitlements.plist" 2>/dev/null
[[ "$(/usr/libexec/PlistBuddy -c 'Print :get-task-allow' "$VERIFY_ROOT/entitlements.plist")" == 'false' ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :application-identifier' "$VERIFY_ROOT/entitlements.plist")" == 'ZLX73742D3.io.github.hshimomura.MDViewer' ]]
security cms -D -i "$APP_PATH/embedded.mobileprovision" > "$VERIFY_ROOT/profile.plist"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:beta-reports-active' "$VERIFY_ROOT/profile.plist")" == 'true' ]]
if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' "$VERIFY_ROOT/profile.plist" >/dev/null 2>&1; then
  print -u2 'Expected App Store distribution profile, found device-specific profile'; exit 1
fi
for resource in PrivacyInfo.xcprivacy THIRD_PARTY_NOTICES.md Mermaid/renderer.html Mermaid/version.json \
  Legal/Textual-LICENSE.txt Legal/SwiftUIMath-LICENSE.txt Legal/ConcurrencyExtras-LICENSE.txt \
  Legal/Prism-LICENSE.txt Legal/Mermaid-LICENSE.txt \
  swiftui-math_SwiftUIMath.bundle/mathFonts.bundle/OFL.txt \
  swiftui-math_SwiftUIMath.bundle/mathFonts.bundle/GUST-FONT-LICENSE.txt; do
  [[ -f "$APP_PATH/$resource" ]] || { print -u2 "Missing distributed resource: $resource"; exit 1; }
done
[[ "$(plutil -extract version raw -o - "$APP_PATH/Mermaid/version.json")" == '12.2.0' ]]
[[ "$(shasum -a 256 "$APP_PATH/Mermaid/mermaid.min.js" | cut -d ' ' -f 1)" == 'a8a6a6f805b074a8261a2825c86f99c8054acb3b35f50bb7e24a4f9f2c3c3b9f' ]]
print 'Verified Ayami iOS 1.4 (20): App Store profile, arm64, iPhone/iPad, iOS 18+, privacy manifest and offline runtime.'
shasum -a 256 "$IPA_PATH"
