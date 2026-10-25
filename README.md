# Ayami — あやみ

Ayami is a quiet, read-only Markdown viewer for Mac, iPhone, and iPad.
Open UTF-8 `.md` and `.markdown` files as structured documents, with a heading
outline, adjustable text size, and offline Mermaid diagrams. There is no editor,
account, analytics, advertising, or document-upload service.

## Version 1.3

Version **1.3 (build 18)** introduces the Ayami name, a bright reading-stand
icon, iPhone/iPad support, saved 80–160% text sizing, and Mermaid 12.2.0.
It also fixes duplicate document navigation bars when iPhone Duo changes displays.

- [Release notes](docs/releases/1.3.md)
- [GitHub Releases](https://github.com/hshimomura/ayami/releases)
- [Documentation index / 日本語の文書案内](docs/README.md)

GitHub Releases publish source code, independently of App Store availability.
Check the [App Store product page](https://apps.apple.com/app/id6794576868)
for the currently available app version.

## Features and platforms

| Feature | Mac | iPhone / iPad |
| --- | --- | --- |
| Read-only Markdown, tables, code, links, selectable text | Yes | Yes |
| Offline Mermaid, system light/dark appearance | Yes | Yes |
| Text-size slider (80–160%, saved per device) | Yes | Yes |
| Heading outline | Sidebar | Sheet in compact windows; sidebar at regular width, including Duo |
| Open documents | Finder / File menu | Files document browser |
| Multiple documents | Separate windows by default, optional native tabs and side-by-side arrangement | System-managed multiple windows on iPad; no Mac-style tabs |
| Live Reload after external saves | Yes, including atomic replacements | Reopen externally changed documents when needed |
| Printing and PDF output | Yes; Mermaid prints as source text | Not implemented |

System Dynamic Type remains supported. Reading Settings never changes the
Markdown file, and the reading scale does not change the separate Mac print layout.

For shortcuts, document handling, and troubleshooting, see [Support](docs/support.md).
Relative local images and a Find navigator are not implemented. Quick Look,
editing, an in-app theme picker, and a standalone updater are outside the current scope.

## Requirements

- App: macOS 26+ or iOS/iPadOS 18+.
- Validated development environment: Xcode 27.1 with Swift 6.4.
  The project uses Swift 6 language mode; `Package.swift` declares tools version 6.2.
- XcodeGen and network access for initial Swift Package Manager resolution.
- App Store Mac archives are Universal 2 (Apple silicon and Intel).

## Build and test

```sh
brew install xcodegen
./Scripts/generate-xcode-project.sh
open Ayami.xcodeproj
```

Choose scheme `Ayami` for Mac or `AyamiIOS` for iPhone/iPad. Both retain the
existing Bundle ID `io.github.hshimomura.MDViewer` so the renamed app keeps its identity.

For a local, ad-hoc-signed Mac build:

```sh
./Scripts/build-app.sh
./Scripts/verify-app.sh
./Scripts/launch-local-app.sh
# Or open your own documents:
./Scripts/launch-local-app.sh README.md Sample.md
```

The local app is `dist/Ayami.app`. Launch through the script, Finder, or `open`;
do not run the executable inside the bundle directly, which bypasses LaunchServices.

```sh
swift test
xcodebuild -project Ayami.xcodeproj -scheme Ayami \
  -destination 'platform=macOS' test
# Check available simulator names with xcrun simctl list devices available.
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
```

The Swift package builds the Mac executable; use the Xcode iOS scheme for iPhone/iPad.
The UI tests use a separate sample host, not a hidden bypass in the production app.
See [1.3 validation results and limitations](docs/iphone-duo-validation-1.3.md).

Distribution archives require Apple signing credentials. Commands, verification,
metadata, and source-release checks are maintained in the
[public release checklist](AppStore/release-checklist.md).

## Architecture and licenses

SwiftUI `DocumentGroup(viewing:)` owns the read-only document lifecycle.
Textual renders Markdown natively; only Mermaid uses a restricted local WebKit view.
The Mac file monitor, printing, and window controls are excluded from the iOS target.

- [Architecture](DESIGN.md)
- [Implementation](docs/ayami-implementation.md)
- [Pinned dependencies and parser audit](docs/dependency-audit-1.3.md)
- [Repository layout and compatibility identifiers](docs/repository-rename.md)
- [MIT license](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md)

Dependency versions are pinned in both `Package.resolved` files. Release signing
uses a trusted local environment; there is no repository CI test/signing workflow
at this version.

## Privacy and support

[Product page](https://hshimomura.github.io/ayami/) ·
[Privacy policy](https://hshimomura.github.io/ayami/privacy) ·
[Support](https://hshimomura.github.io/ayami/support) ·
[Issues](https://github.com/hshimomura/ayami/issues)
