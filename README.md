# Ayami — あやみ

Ayami is a quiet, read-only Markdown viewer for Mac, iPhone, and iPad.
Open UTF-8 `.md` and `.markdown` files with a heading outline, adjustable text
size, and offline Mermaid diagrams. No editor, account, ads, tracking, or
document-upload service.

## v1.5 開発版

`codex/v1.5`で1.5（build 21）を開発中です。文書内検索、一時的なピンクの蛍光ペン、
相対画像・関連Markdown、コードコピー、読書位置を保つMac Live Reload、Mermaid拡大表示、
公開技術文書サンプルとQuick Look案内を追加しています。
Macの文書リンクは初期設定で新しいタブへ開き、「閲覧設定」で新しいウィンドウにも変更できます。
Markdown内のHTMLと`.html`を表示し、`.txt`・`.json`・`.c`などは原文のテキストとして開けます。
UTF-8、BOM付きUTF-16/32、Shift JIS、最大20MiBに対応します。
マークは文書を閉じると消え、Markdown・PDFへ保存しません。
起動画面は初回だけ表示し、「次回起動時もこの画面を表示する」にチェックした場合に再表示します。
技術文書サンプルと起動画面は「ヘルプ」からいつでも開けます。
すべてのウインドウを閉じた後も「ウインドウ → 起動画面を表示」から戻れます。

- [1.5の実装と検証範囲](docs/validation-1.5.md)
- Mac検証アプリ: `dist/validation-1.5/Ayami.app`
- ストア画像の準備: `AppStore/Screenshots/1.5/`（ローカル生成物、Git管理外）

以下の1.4は公開済みソースの説明です。1.5のストア提供を意味しません。

## Version 1.4

**1.4 (build 20)** adds A4/Letter printing and PDF export on all platforms,
Mermaid diagrams in output, Finder Quick Look on Mac, and optional on-device
Document Highlights (Prototype). The Mac app now requires Apple silicon;
Intel Macs are no longer supported.

Build 20 uses a continuous Quick Look preview. Paper pagination is used for
printing and PDF export.

- [1.4 release notes](docs/releases/1.4.md)
- [Validation results and known limitations](docs/validation-1.4.md)
- [Documentation index / 日本語の文書案内](docs/README.md)
- [GitHub Releases](https://github.com/hshimomura/ayami/releases)

GitHub source releases and App Store availability are separate. Check the
[App Store](https://apps.apple.com/app/id6794576868) for the distributed version.

## Features and platforms

| Feature | Mac | iPhone / iPad |
| --- | --- | --- |
| Read-only Markdown, tables, code, links, selectable text | Yes | Yes |
| Offline Mermaid; system light/dark appearance | Yes | Yes |
| Saved reading-size slider (80–160%); Dynamic Type | Yes | Yes |
| Heading outline | Sidebar | Sheet at compact width; sidebar at regular width, including Duo |
| Open documents | Finder / File menu | Files document browser |
| Multiple documents | Separate windows by default, optional native tabs and side-by-side arrangement | System-managed multiple windows on iPad; no Mac-style tabs |
| Live Reload after external saves | Yes, including atomic replacements | Reopen externally changed documents when needed |
| A4/Letter preview, printing and PDF export with Mermaid diagrams | Yes | Yes |
| Finder Quick Look with Mermaid diagrams | Yes | Not applicable |
| On-device Document Highlights (Prototype) | Requires Apple Intelligence | Requires OS 26+ and Apple Intelligence |

AI is optional and never runs automatically. Mac generation was verified;
iPhone simulator generation failed, and iPad/Duo generation is unverified.
Availability or generation failures do not disable reading or PDF output.
Check AI output against the original document.

Print/PDF output uses its own layout and supports a subset of Markdown, not
pixel-identical HTML/CSS or images. Invalid Mermaid and rendering failures show
a warning and source fallback. In 1.4, relative local images and a Find navigator are not implemented.
The 1.5 development reader adds both; printing/PDF and Quick Look retain their
separate 1.4 image limitations. Editing, an in-app theme picker, and a standalone
updater are not implemented.
For operation and troubleshooting, see [Support](docs/support.md).

## Requirements

- Mac: Apple silicon, macOS 26 or later.
- iPhone/iPad: iOS/iPadOS 18 or later. AI additionally requires OS 26+, a
  supported device/language, Apple Intelligence enabled, and a prepared model.
- Validated development environment: Xcode 27.1, Swift 6.4, and XcodeGen.
  Swift language mode is 6; `Package.swift` uses tools version 6.2.
- Network access for initial dependency resolution. Pinned packages and
  bundled Mermaid are unchanged from the [1.3 dependency audit](docs/dependency-audit-1.3.md).

## Build and test

XcodeGen's `project.yml` is the source of truth. Use scheme `Ayami` for Mac and
`AyamiIOS` for iPhone/iPad. Both retain Bundle ID
`io.github.hshimomura.MDViewer` for compatibility.

```sh
brew install xcodegen
./Scripts/generate-xcode-project.sh
open Ayami.xcodeproj
```

For a local Mac build including Quick Look, an Apple Development signing
identity is required. Use your own team in Xcode when building independently.

```sh
./Scripts/build-validation-app.sh
open dist/validation-1.5/Ayami.app Sample.md
```

On this branch, this builds the 1.5 development app without replacing `/Applications/Ayami.app`. Launch the `.app`
through Finder or `open`, not its internal executable. The old SwiftPM bundle
packager (`build-app.sh`), verifier and launcher are 1.3 helpers; they are not
the 1.4 build path. SwiftPM does not package the Quick Look extension.

```sh
swift test
# Optional: generate highlights from the public sample with the local model.
AYAMI_TEST_LOCAL_AI=1 swift test
# Check available device names with xcrun simctl list devices available.
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO test
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' \
  -parallel-testing-enabled NO test
```

Mac print/save/Finder operation tests use the isolated `AyamiMacUIValidation`
scheme. Preparation, extension registration, permissions and the exact selected
tests are documented in the [validation record](docs/validation-1.4.md).
The product contains no document-browser bypass for tests.

App Store archives and exports use `dist/1.4/`. Signing, verification, uploads
and GitHub source assets are covered by the [release checklist](AppStore/release-checklist.md).
There is no repository CI test/signing workflow; release builds use a trusted
local environment.

## Architecture and licenses

SwiftUI `DocumentGroup(viewing:)` owns the document lifecycle. The 1.5 reading view uses a nonpersistent WebKit page with bundled markdown-it,
Prism and Mermaid. Textual remains for the settings sample and compatibility
parser coverage. A separate
CoreText/CoreGraphics pipeline generates PDFs shared by all platforms and the
Mac Quick Look extension. Highlights use Apple's on-device Foundation Models
only, without a cloud fallback or changes to the original file.

- [Architecture](DESIGN.md)
- [Implementation](docs/ayami-implementation.md)
- [Repository layout and compatibility identifiers](docs/repository-rename.md)
- [MIT license](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md)

## Privacy and support

[Product page](https://hshimomura.github.io/ayami/) ·
[Privacy policy](https://hshimomura.github.io/ayami/privacy) ·
[Support](https://hshimomura.github.io/ayami/support) ·
[Issues](https://github.com/hshimomura/ayami/issues)
