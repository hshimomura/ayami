#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
PACKAGE_PATH="$PROJECT_ROOT/dist/1.4/AppStoreExport/Ayami.pkg"
TEMP_PARENT="$(/usr/bin/mktemp -d /private/tmp/ayami-app-store.XXXXXX)"
EXPANDED_PATH="$TEMP_PARENT/expanded"

cleanup() {
    /bin/rm -rf "$TEMP_PARENT"
}
trap cleanup EXIT

if [[ ! -f "$PACKAGE_PATH" ]]; then
    print -u2 "Missing App Store package: $PACKAGE_PATH"
    exit 1
fi

package_signature="$(/usr/sbin/pkgutil --check-signature "$PACKAGE_PATH")"
print -r -- "$package_signature" |
    /usr/bin/grep -q "3rd Party Mac Developer Installer:"

/usr/sbin/pkgutil --expand-full "$PACKAGE_PATH" "$EXPANDED_PATH"

typeset -a app_paths
app_paths=("${(@f)$(/usr/bin/find "$EXPANDED_PATH" \
    -type d -name "Ayami.app" -print)}")

if (( ${#app_paths} != 1 )); then
    print -u2 "Expected one Ayami.app in package, found ${#app_paths}."
    exit 1
fi

APP_PATH="$app_paths[1]"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
EXECUTABLE="$APP_PATH/Contents/MacOS/Ayami"
RESOURCES="$APP_PATH/Contents/Resources"
ENTITLEMENTS_PATH="$TEMP_PARENT/entitlements.plist"

/usr/bin/codesign --verify --deep --strict "$APP_PATH"

signature_details="$(/usr/bin/codesign -dv --verbose=4 "$APP_PATH" 2>&1)"
print -r -- "$signature_details" |
    /usr/bin/grep -q "Authority=Apple Distribution:"
print -r -- "$signature_details" |
    /usr/bin/grep -q "flags=0x10000(runtime)"

architectures="$(/usr/bin/lipo -archs "$EXECUTABLE")"
[[ "$architectures" == "arm64" ]]

bundle_identifier="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleIdentifier" "$INFO_PLIST")"
marketing_version="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
build_version="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleVersion" "$INFO_PLIST")"
minimum_system="$(/usr/libexec/PlistBuddy \
    -c "Print :LSMinimumSystemVersion" "$INFO_PLIST")"
document_role="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleDocumentTypes:0:CFBundleTypeRole" "$INFO_PLIST")"
markdown_type="$(/usr/libexec/PlistBuddy \
    -c "Print :CFBundleDocumentTypes:0:LSItemContentTypes:0" "$INFO_PLIST")"
uses_non_exempt_encryption="$(/usr/libexec/PlistBuddy \
    -c "Print :ITSAppUsesNonExemptEncryption" "$INFO_PLIST")"
app_category="$(/usr/libexec/PlistBuddy \
    -c "Print :LSApplicationCategoryType" "$INFO_PLIST")"

[[ "$bundle_identifier" == "io.github.hshimomura.MDViewer" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$INFO_PLIST")" == "Ayami" ]]
[[ "$marketing_version" == "1.4" ]]
[[ "$build_version" == "19" ]]
[[ "$minimum_system" == "26.0" ]]
[[ "$document_role" == "Viewer" ]]
[[ "$markdown_type" == "net.daringfireball.markdown" ]]
[[ "$uses_non_exempt_encryption" == "false" ]]
[[ "$app_category" == "public.app-category.productivity" ]]

/usr/bin/codesign -d --entitlements :- "$APP_PATH" \
    >"$ENTITLEMENTS_PATH" 2>/dev/null

typeset -a required_entitlements
required_entitlements=(
    "com.apple.security.app-sandbox"
    "com.apple.security.files.user-selected.read-write"
    "com.apple.security.network.client"
    "com.apple.security.print"
)

for entitlement in "$required_entitlements[@]"; do
    value="$(/usr/libexec/PlistBuddy \
        -c "Print :$entitlement" "$ENTITLEMENTS_PATH")"
    [[ "$value" == "true" ]]
done

typeset -a required_resources
required_resources=(
    "$RESOURCES/PrivacyInfo.xcprivacy"
    "$RESOURCES/THIRD_PARTY_NOTICES.md"
    "$RESOURCES/Legal/Textual-LICENSE.txt"
    "$RESOURCES/Legal/SwiftUIMath-LICENSE.txt"
    "$RESOURCES/Legal/ConcurrencyExtras-LICENSE.txt"
    "$RESOURCES/Legal/Prism-LICENSE.txt"
    "$RESOURCES/Legal/Mermaid-LICENSE.txt"
    "$RESOURCES/Mermaid/mermaid.min.js"
    "$RESOURCES/Mermaid/renderer.html"
    "$RESOURCES/swiftui-math_SwiftUIMath.bundle/Contents/Resources/mathFonts.bundle/OFL.txt"
    "$RESOURCES/swiftui-math_SwiftUIMath.bundle/Contents/Resources/mathFonts.bundle/GUST-FONT-LICENSE.txt"
)

for resource in "$required_resources[@]"; do
    if [[ ! -f "$resource" ]]; then
        print -u2 "Missing required distributed resource: $resource"
        exit 1
    fi
done

QUICKLOOK_APP="$APP_PATH/Contents/PlugIns/AyamiQuickLook.appex"
QUICKLOOK_INFO="$QUICKLOOK_APP/Contents/Info.plist"
[[ -d "$QUICKLOOK_APP" ]]
/usr/bin/codesign --verify --strict "$QUICKLOOK_APP"
[[ "$(/usr/bin/lipo -archs "$QUICKLOOK_APP/Contents/MacOS/AyamiQuickLook")" == "arm64" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$QUICKLOOK_INFO")" == "io.github.hshimomura.MDViewer.QuickLook" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$QUICKLOOK_INFO")" == "1.4" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$QUICKLOOK_INFO")" == "19" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :NSExtension:NSExtensionAttributes:QLSupportedContentTypes:0' "$QUICKLOOK_INFO")" == "net.daringfireball.markdown" ]]
/usr/bin/codesign -d --entitlements :- "$QUICKLOOK_APP" > "$TEMP_PARENT/quicklook-entitlements.plist" 2>/dev/null
[[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.app-sandbox' "$TEMP_PARENT/quicklook-entitlements.plist")" == "true" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.security.files.user-selected.read-only' "$TEMP_PARENT/quicklook-entitlements.plist")" == "true" ]]
[[ -f "$QUICKLOOK_APP/Contents/Resources/PrivacyInfo.xcprivacy" ]]
[[ -f "$QUICKLOOK_APP/Contents/Resources/Mermaid/mermaid.min.js" ]]

package_checksum="$(/usr/bin/shasum -a 256 "$PACKAGE_PATH" |
    /usr/bin/awk '{print $1}')"

print "Verified Ayami 1.4 (19) App Store export, including the production Quick Look extension."
print "Architectures: $architectures"
print "Package SHA-256: $package_checksum"
