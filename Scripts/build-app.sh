#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
OUTPUT_APP_PATH="$PROJECT_ROOT/dist/Ayami.app"

cd "$PROJECT_ROOT"

export CLANG_MODULE_CACHE_PATH="$PROJECT_ROOT/.build/module-cache"
export SWIFT_MODULECACHE_PATH="$PROJECT_ROOT/.build/module-cache"

"$PROJECT_ROOT/Scripts/build-icon.sh"

swift build -c release --arch arm64
BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

# Build a fresh bundle so renamed modules cannot leave obsolete resources behind.
mkdir -p "$PROJECT_ROOT/dist"
STAGING_ROOT="$(mktemp -d "$PROJECT_ROOT/dist/ayami-build.XXXXXX")"
APP_PATH="$STAGING_ROOT/Ayami.app"
trap '[[ "$STAGING_ROOT" == "$PROJECT_ROOT"/dist/ayami-build.* ]] && rm -r -- "$STAGING_ROOT"' EXIT

mkdir -p \
    "$APP_PATH/Contents/MacOS" \
    "$APP_PATH/Contents/Resources/ThirdPartyLicenses"

/usr/bin/ditto "$BIN_DIR/Ayami" "$APP_PATH/Contents/MacOS/Ayami"
/usr/bin/ditto "$PROJECT_ROOT/Packaging/Info.plist" "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleExecutable -string Ayami \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleIdentifier \
    -string io.github.hshimomura.MDViewer \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleShortVersionString -string 1.3 \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace CFBundleVersion -string 17 \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/plutil -replace LSMinimumSystemVersion -string 26.0 \
    "$APP_PATH/Contents/Info.plist"
/usr/bin/ditto "$PROJECT_ROOT/Resources/AppIcon.icns" \
    "$APP_PATH/Contents/Resources/AppIcon.icns"
/usr/bin/ditto "$PROJECT_ROOT/THIRD_PARTY_NOTICES.md" \
    "$APP_PATH/Contents/Resources/THIRD_PARTY_NOTICES.md"
/usr/bin/ditto "$PROJECT_ROOT/Packaging/PrivacyInfo.xcprivacy" \
    "$APP_PATH/Contents/Resources/PrivacyInfo.xcprivacy"
/usr/bin/ditto "$PROJECT_ROOT/Packaging/Localizations" \
    "$APP_PATH/Contents/Resources"
/usr/bin/ditto "$PROJECT_ROOT/Legal/Prism-LICENSE.txt" \
    "$APP_PATH/Contents/Resources/ThirdPartyLicenses/Prism-LICENSE.txt"

for resource_name in Ayami_Ayami textual_Textual swiftui-math_SwiftUIMath; do
    resource_bundle="$BIN_DIR/$resource_name.bundle"
    [[ -d "$resource_bundle" ]] || { print -u2 "Missing resource bundle: $resource_bundle"; exit 1; }
    /usr/bin/ditto "$resource_bundle" \
        "$APP_PATH/Contents/Resources/${resource_bundle:t}"
done

typeset -A license_sources
license_sources=(
    "Textual" "$PROJECT_ROOT/.build/checkouts/textual/LICENSE"
    "SwiftUIMath" "$PROJECT_ROOT/.build/checkouts/swiftui-math/LICENSE"
    "ConcurrencyExtras" "$PROJECT_ROOT/.build/checkouts/swift-concurrency-extras/LICENSE"
    "Mermaid" "$PROJECT_ROOT/Legal/Mermaid-LICENSE.txt"
)

for component source_path in "${(@kv)license_sources}"; do
    if [[ -f "$source_path" ]]; then
        /usr/bin/ditto "$source_path" \
            "$APP_PATH/Contents/Resources/ThirdPartyLicenses/$component-LICENSE.txt"
    fi
done

/usr/bin/codesign --force --deep --sign - "$APP_PATH"
/usr/bin/plutil -lint "$APP_PATH/Contents/Info.plist"
/usr/bin/codesign --verify --deep --strict "$APP_PATH"

if [[ -e "$OUTPUT_APP_PATH" ]]; then
    PREVIOUS_BUILD_ROOT="$(mktemp -d "$PROJECT_ROOT/.build/previous-local-app.XXXXXX")"
    mv "$OUTPUT_APP_PATH" "$PREVIOUS_BUILD_ROOT/Ayami.app"
    print "Previous local app preserved at $PREVIOUS_BUILD_ROOT/Ayami.app"
fi
mv "$APP_PATH" "$OUTPUT_APP_PATH"
print "Built $OUTPUT_APP_PATH"
