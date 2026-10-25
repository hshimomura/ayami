# あやみ 1.4（19）実装仕様

Mac・iPhone・iPadの読み取り専用ビューアーを共通SwiftUIコードで構成する。
利用者向け機能は[README](../README.md)、データフローは[設計](../DESIGN.md)、
動作確認の証跡は[1.4検証記録](validation-1.4.md)を正本とする。

## ターゲットと責務

| 対象・責務 | 実装 |
| --- | --- |
| Mac | `Ayami`、Apple silicon、macOS 26+、`AyamiMacApp.swift` |
| iPhone・iPad | `AyamiIOS`、iOS/iPadOS 18+、`Sources/AyamiIOS/AyamiApp.swift` |
| 共有ソース | `Sources/Ayami/`。Mac専用の入口・ウィンドウ制御はiOSから除外 |
| 文書管理・監視 | `MarkdownDocument`、`DocumentGroup(viewing:)`、`PreviewDocumentModel` |
| 読書・目次・設定 | `PreviewView`、Textual、`OutlineSidebar`、`ReadingPreferences`、`ReadingSettingsView` |
| 読書画面の図 | `MermaidDiagramView`、`MermaidRendererResources`、同梱ランタイム |
| PDF入力・スタイル | `OutputDocument`、`OutputTextStyle` |
| PDF生成・図合成 | `DocumentPDFGenerator`、`MermaidPDFRenderer` |
| 出力画面・OS操作 | `DocumentOutputView`、PDFKit、`PDFExportDocument`、OS別印刷ボタン |
| Finder Quick Look | `AyamiQuickLook`、`Sources/AyamiQuickLook/PreviewProvider.swift` |
| 端末内AI | `DocumentSummary`、`DocumentSummaryView` |

`project.yml`が構成の正本。Mac本体・拡張・Macテストは`ARCHS: arm64`。
アプリと拡張のバージョンは1.4、ビルドは19。アプリのBundle IDは
`io.github.hshimomura.MDViewer`、製品拡張は末尾`.QuickLook`で互換性を維持する。
改名時の判断は[構成変更記録](repository-rename.md)に残す。

## 文字サイズと文書画面

- `readerFontScale`を端末単位の`@AppStorage`で保存。初期値1.0、範囲0.80〜1.60、5%刻み。
- 範囲外を制限し、NaN・無限大は初期値へ戻す。「標準に戻す」は100%。
- Textualの`fontScale`とMermaidの`themeVariables.fontSize`へ適用。目次・ステータスはシステム設定に従う。
- MarkdownやPDFの独立したレイアウトは変更しない。Dynamic Typeも維持する。

Macは個別ウィンドウを既定とし、任意にネイティブタブへ追加する。
左右配置は文書ウィンドウだけを対象とし、Macのみ外部ファイルを約400ms間隔で監視する。

iOSはFilesから開き、compact幅は目次シート、regular幅は230ptの目次と本文をHStackで並べる。
DocumentGroupにNavigationSplitViewを重ねず、Duoの文書バー重複を防ぐ。
端末名や`.phone`で配置を固定せず、iPadの複数ウィンドウはOSへ任せる。
独自のファイルポーリングは行わず、外部変更が反映されない場合は文書を開き直す。

## 印刷・PDF

文書メニューの「印刷とPDF」、MacのCommand-Pから共通画面を開く。
入力は開いているMarkdownのスナップショット。A4/Letterを選び直すと生成をやり直し、
PDFKitでプレビューする。保存成功のコールバック後だけ完了表示し、取消はエラーにしない。

- `OutputDocument`: UTF-8、最大1MiB。見出し、段落、リスト、引用、コード、表、水平線、Mermaidを分離。
- `OutputTextStyle`: FoundationのインラインMarkdown解析とCoreTextの文字属性。コード以外の`<br>`に対応。
- `DocumentPDFGenerator`: CoreText/CoreGraphicsで最大500ページ。選択可能な文字、ページ番号、表見出しの繰り返し。
- 大きすぎる表の行や幅は文字として改ページし、切り落としを避ける。
- `MermaidPDFRenderer`: 非永続WKWebViewで同梱JSからSVGを作り、WebKitのベクターPDFを合成。
  図の上限64KiB、ロード待ち15秒・描画待ち12秒。失敗時だけ警告とソースへフォールバック。
- Mac: `NSPrintOperation`をアクティブなウィンドウに付随させ、出力シートから操作できるようにする。
- iOS: `UIPrintInteractionController`。用紙変更後の最新PDFとタイトルをCoordinatorへ反映する。

読書画面とは別レンダラーであり、画像の外部・相対パス解決、HTML/CSSの完全再現、
入れ子リストや表の配置指定の完全対応は行わない。
旧`DocumentPrintCoordinator`とTextKit印刷フォーマッターは削除し、二重実装を残さない。

## Finder Quick Look

Macアプリが`AyamiQuickLook.appex`を同梱する。`net.daringfireball.markdown`を対象に、
データ方式の`QLPreviewProvider`が共通の読み込み・PDF生成を行い、`QLPreviewReply`で返す。
OSが選択・スクロール・ズームを管理する。AI、アプリの設定、独自ビューアーは組み込まない。

サンドボックス、ユーザー選択read-only、ローカルWebKit用`network.client`を付ける。
本文やファイル名はログに含めず、初期化・準備要求・ページ数・図数・エラー型だけを記録する。
他社のMarkdown拡張が残る環境では選択・登録状態の確認が必要。診断経緯は検証記録へ分離する。

## 端末内AI「文書の要点」（試作）

OS 26+で`SystemLanguageModel.default`の利用可否・言語対応を確認し、明示的な生成操作だけで実行する。
未対応端末、Apple Intelligence無効、モデル準備中、非対応言語は説明を表示する。
生成失敗・取消は読書やPDFへ波及させない。結果は画面表示だけで、元文書へ書き戻さない。

- 最大32,000文字。800文字単位に分割し、長文は部分要約から段階的に縮約する。
- 日本語環境では日本語、それ以外は英語を出力指示する。
- 文書中の命令を信頼せず、参照資料内の事実だけを要約するよう指示する。
- クラウドフォールバック、Private Cloud Compute、他社モデル、ツール、ファイル操作は渡さない。
- AIが誤る可能性と原文照合を画面に表示する。iOSは弱リンクとavailabilityで最低OS 18を維持する。

生成精度と全端末での利用成功は保証しない。Mac実生成は成功したが、iPhoneシミュレーターの失敗と
iPad/Duoの未確認が残る。試作を配布対象へ含める判断と検証範囲は[検証記録](validation-1.4.md)を参照する。

## 資産・プライバシー・ビルド

固定依存は1.3から変更していない。[依存監査](dependency-audit-1.3.md)を参照する。
読書用と出力用Mermaidは同じ資産を使い、CSP・外部遷移拒否・リンク除去・タイムアウトを適用する。
Privacy ManifestはUserDefaults理由`CA92.1`、更新時刻理由`3B52.1`、収集・追跡なしを記録する。

ローカルMacも拡張を同梱するXcodeビルドを使う。SwiftPMは単体テストに使うが拡張の配布バンドルを作らない。
Mac UIテストは別識別子の同じ製品ソース、iOS UIテストは共有画面の専用ホストを使う。
製品にブラウザーバイパスを追加せず、ストア画像は製品ターゲットから撮影する。

[ビルドとテストの入口](../README.md) · [配布チェックリスト](../AppStore/release-checklist.md) ·
[名称・アイコン](app-name-plan.md) · [初期iOS計画との差分](ios-ipados-font-size-implementation-plan.md)
