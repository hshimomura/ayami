# iPhone・iPad対応と文字サイズ設定の実装計画

> この文書は初期案である。採用仕様・実装順・現行ターゲット構成・検証手順は
> [あやみ実装計画](ayami-implementation.md) を正本とする。
> 名称は「あやみ / Ayami」に決定し、macOSターゲットは `MDPreview` のまま維持する。

## 目的

既存のmacOS版を維持しながら、同じMarkdown閲覧機能をiPhoneとiPadへ展開する。
あわせて、Markdown本文の文字サイズを設定画面のスライダーで調整できるようにする。

この計画では、macOS固有のタブ・ウィンドウ操作を残し、iOS/iPadOSではFilesと
SwiftUIの文書ブラウザー、iPadのマルチウィンドウを利用する。Mac Catalystへの置換は
行わず、既存のネイティブmacOSアプリを継続する。

## 現状

- `DocumentGroup(viewing:)` と `MarkdownDocument` により読み取り専用文書を開く。
- Markdown解析と表示ロジックの大半はSwiftUIとFoundationで実装されている。
- `MDPreviewApp.swift`、`DocumentPrintCoordinator.swift`、
  `WindowSizeRestorer.swift` はAppKitに依存する。
- `MermaidDiagramView.swift` のWebViewラッパーは `NSViewRepresentable` である。
- Textual 0.5.0はmacOS 15以降とiOS 18以降をサポートし、
  `.textual.fontScale(_:)` を提供している。
- 現在のApp Store ConnectレコードはmacOSプラットフォームだけを持つ。

## 採用する構成

### アプリターゲット

`project.yml` に次の2ターゲットを定義する。

| ターゲット | 対象 | 役割 |
| --- | --- | --- |
| `MDPreviewMac` | macOS 26以降 | 現行のタブ、左右配置、印刷、Live Reloadを維持する |
| `MDPreviewiOS` | iOS/iPadOS 18以降 | iPhoneとiPadのFiles連携、共有、マルチウィンドウに対応する |

両ターゲットは同じApp Store ConnectレコードとBundle ID
`io.github.hshimomura.MDViewer` を使用する。AppleのUniversal Purchaseでは、同じ
App Store ConnectレコードとBundle IDを使い、プラットフォーム別のビルドを関連付ける。
iPhoneとiPadは同じiOSターゲットで `TARGETED_DEVICE_FAMILY = "1,2"` とする。

既存のmacOSターゲットを直接マルチプラットフォーム化せず、共有ソースと
プラットフォーム固有ソースを明示的に分ける。これによりAppKitコードを
`#if os(macOS)` だらけにせず、macOS版の挙動を安全に維持できる。

### ディレクトリ構成

```text
Sources/
  Shared/
    MarkdownDocument.swift
    MarkdownContent.swift
    HTMLBreakMarkdownParser.swift
    PreviewDocumentModel.swift
    PreviewView.swift
    ReadingPreferences.swift
    ReadingSettingsView.swift
    Mermaid/
      MermaidDiagramView.swift
      MermaidWebViewCore.swift
      Resources/
  macOS/
    MDPreviewMacApp.swift
    MacDocumentCommands.swift
    MacMermaidWebView.swift
    DocumentPrintCoordinator.swift
    WindowSizeRestorer.swift
  iOS/
    MDPreviewiOSApp.swift
    IOSDocumentCommands.swift
    IOSMermaidWebView.swift
```

共有ソースは両アプリターゲットから参照する。既存テストのうちパーサー、文書、
設定値のテストは共有テストとして実行し、ウィンドウ配置と印刷のテストはmacOS専用に残す。

## 文字サイズ設定

### 設定モデル

`ReadingPreferences` を追加し、`@AppStorage` で端末ごとに値を保存する。

- キー: `readerFontScale`
- 初期値: `1.0`
- 範囲: `0.80 ... 1.60`
- ステップ: `0.05`
- 「標準に戻す」操作を提供する
- 範囲外の保存値は起動時にクランプする

文字倍率は文書単位ではなくアプリ全体の設定とする。同じ端末で開くすべての文書に
即時反映する。

### UI

- macOS: `Settings` シーンに「表示」設定を追加する。
- iPhone/iPad: 文書画面のツールバーに `textformat.size` ボタンを追加し、
  シートまたはpopoverで同じ `ReadingSettingsView` を表示する。
- スライダーの左右に小さい `A` と大きい `A` を表示する。
- 現在値をパーセント表示し、VoiceOver向けに「文字サイズ、100パーセント」の
  accessibility valueを設定する。

### 描画への適用

`MarkdownSectionView` へ倍率を渡し、Textualに次を適用する。

```swift
StructuredText(source, parser: HTMLBreakMarkdownParser())
  .textual.structuredTextStyle(.gitHub)
  .textual.fontScale(fontScale)
```

これにより本文、見出し、リスト、コードブロック、表を同じ比率で拡大する。
サイドバーとステータス表示はDynamic Typeを優先し、独自倍率は本文へだけ適用する。

Mermaidについては `renderDiagram(source, theme, fontScale)` に拡張し、Mermaidの
`themeVariables.fontSize` とフォールバック表示へ倍率を渡す。倍率変更時は同じWebViewで
再描画し、高さを再計測する。

## iPhone・iPad対応

### 文書のオープン

iOS/iPadOSでも `DocumentGroup(viewing: MarkdownDocument.self)` を使う。
SwiftUIのDocumentGroupはiOSでFilesベースの文書ブラウザーとマルチウィンドウを提供する。

- iPhone: Filesから `.md` を選択し、1文書を1画面で表示する。
- iPad: DocumentGroupのマルチウィンドウとステージマネージャに任せる。
- macOS固有の「新しいタブで開く」と「左右に並べる」はiOSターゲットへ含めない。
- iPadでは標準のSplit View、Stage Manager、複数ウィンドウで比較できることを案内する。

### 画面レイアウト

`PreviewView` をサイズクラスへ適応させる。

- iPadと横向きの広い画面: 現行の `NavigationSplitView` で目次と本文を並べる。
- iPhoneと狭い画面: 本文を優先し、目次はツールバーからsheetとして開く。
- macOS専用の最小フレーム `700 × 420`、`WindowSizeRestorer`、
  `FileMenuOrganizer` はmacOSターゲットだけに適用する。
- 下部ステータスバーはiPhoneでは省スペース表示にし、ファイル名と更新状態を
  ツールバーまたはsafe-area insetへ移す。

### Mermaid WebView

共有する描画状態とCoordinatorを `MermaidWebViewCore` に分離する。

- macOS: `NSViewRepresentable`
- iOS/iPadOS: `UIViewRepresentable`
- 両方で同じ `WKWebViewConfiguration`、CSP、ローカルJavaScript、外部遷移拒否を使う。
- iOS側では `isOpaque = false` と背景色の透明化を設定する。
- WebViewの高さ通知、タイムアウト、エラーフォールバックは共通化する。

### Live Reloadと印刷

- Live Reloadのファイル監視は当面macOS専用にする。
- iOSではDocumentGroupが提供する文書ライフサイクルを正本とし、アプリ復帰時や
  ファイル再オープン時に内容を更新する。セキュリティスコープ外のURLを継続監視しない。
- iOSの印刷は第2段階で `UIPrintInteractionController` を使って追加する。
  初回iOSリリースの必須条件にはせず、共有フォーマッターをUIKitへ移植できた時点で有効化する。

## 実装手順

### フェーズ1: 共有コードの分離

1. 現行ターゲット名と製品名を維持したまま、ソースを `Shared` と `macOS` へ移動する。
2. AppKit依存をmacOSディレクトリへ集約する。
3. XcodeGenでmacOSターゲットを再生成し、既存17テストとApp Store検証を通す。
4. この時点では機能変更を行わず、差分をリファクタリングだけに限定する。

### フェーズ2: 文字サイズ設定

1. `ReadingPreferences` と `ReadingSettingsView` を追加する。
2. Textualの `.fontScale(_:)` を本文へ適用する。
3. Mermaid描画へ倍率を渡す。
4. macOS SettingsとiOS用設定popoverを接続する。
5. 永続化、クランプ、リセット、即時反映をテストする。

### フェーズ3: iOS/iPadOSターゲット

1. `MDPreviewiOS` ターゲットとiOS用Info.plist、entitlements、アイコンを追加する。
2. iPhone/iPadの両device familyを有効にする。
3. iOS用AppエントリとMermaid WebViewラッパーを実装する。
4. compact/regular size classで目次表示を切り替える。
5. Files、iCloud Drive、On My iPhone/iPadからの読み取りを実機で確認する。
6. iPadのSplit View、Stage Manager、複数ウィンドウを確認する。

### フェーズ4: 配布準備

1. 同じApp Store ConnectレコードでiOSプラットフォームを追加する。
2. 同じBundle IDを使い、iOS版の最初のバージョンを `1.0` とする。
3. iPhone 6.9インチ系とiPad 13インチ系を中心にスクリーンショットを作成する。
4. iOS/iPadOS向け説明、サポート情報、レビュー手順を追加する。
5. macOSとiOSの両プラットフォームが承認された時点でUniversal Purchaseになることを確認する。

## テスト計画

### 単体テスト

- Markdown解析、見出し抽出、Mermaid分離が両プラットフォームで同じ結果になる。
- `readerFontScale` の初期値、上下限、ステップ、リセットが正しい。
- 文字倍率変更でMermaidの再描画キーが変わる。
- iOS用レイアウト判定でcompact時に目次がsheetへ切り替わる。
- macOSのウィンドウ配置、印刷、Live Reloadの既存テストが維持される。

### UI・実機テスト

- iPhoneとiPadでFilesからUTF-8 Markdownを開ける。
- 日本語、英語、長いコード、表、リンク、Mermaidが表示される。
- 文字サイズを最小・標準・最大へ変更しても横スクロールや欠落が発生しない。
- 設定値が再起動後も保持される。
- VoiceOver、Dynamic Type、Reduce Motion、ライト／ダーク表示を確認する。
- iPadで回転、Split View、Stage Manager、外部キーボードを確認する。
- macOS版のタブ、左右配置、印刷、Live Reloadに退行がない。

## 完了条件

- macOS、iPhone、iPadの各スキームがXcode 27.1で警告なくビルドできる。
- 共有単体テストとプラットフォーム別テストがすべて成功する。
- 文字サイズを80%から160%まで変更でき、全Markdown要素へ即時反映される。
- iPhoneとiPadのFilesからMarkdownを読み取り専用で開ける。
- 外部ネットワークなしでMermaidが描画される。
- macOS版の既存機能とApp Sandbox設定に退行がない。
- App Store Connectの同一アプリレコードにmacOS版とiOS版を提出できる。

## 主なリスクと対策

| リスク | 対策 |
| --- | --- |
| AppKit依存が共有ビューへ漏れる | ソースを共有・macOS・iOSの3領域に分け、ターゲットで明示的に選択する |
| iOSのファイルURLを常時監視してアクセス権を失う | iOSではDocumentGroupのライフサイクルを使い、直接ポーリングしない |
| 文字倍率で表やコードが画面外へ出る | Textualのoverflow設定と横スクロールを実機で検証する |
| Mermaid SVGの文字だけ倍率が変わらない | `themeVariables.fontSize` を描画要求へ含め、高さを再計測する |
| iOS対応によってmacOSの提出物が変わる | 共有化、文字サイズ、iOS追加を別コミット・別検証段階に分ける |
| Universal Purchaseの設定を別レコードで作ってしまう | 新規アプリを作らず、既存App Store ConnectレコードのAdd Platformを使う |

## 参考資料

- [Apple: Add platforms](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-platforms/)
- [Apple: universal purchase](https://developer.apple.com/help/glossary/universal-purchase)
- [Apple: DocumentGroup](https://developer.apple.com/documentation/swiftui/documentgroup)
- [XcodeGen: Project Spec](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
