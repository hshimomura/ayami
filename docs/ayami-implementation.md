# あやみ 1.5 開発版（21）実装仕様

Mac・iPhone・iPadの読み取り専用ビューアーを共通SwiftUIコードで構成する。
利用者向け機能は[README](../README.md)、データフローは[設計](../DESIGN.md)、
1.5の変更と検証は[1.5検証記録](validation-1.5.md)、従来機能の履歴は
[1.4検証記録](validation-1.4.md)を参照する。

## ターゲットと責務

| 対象・責務 | 実装 |
| --- | --- |
| Mac | `Ayami`、Apple silicon、macOS 26+、`AyamiMacApp.swift` |
| iPhone・iPad | `AyamiIOS`、iOS/iPadOS 18+、`Sources/AyamiIOS/AyamiApp.swift` |
| 共有ソース | `Sources/Ayami/`。Mac専用の入口・ウィンドウ制御はiOSから除外 |
| 文書管理・監視 | `MarkdownDocument`、`DocumentGroup(viewing:)`、`PreviewDocumentModel` |
| 読書・目次・設定 | `PreviewView`、`ReaderSession`、`ReaderWebView`、`OutlineSidebar`、`ReadingPreferences`、`ReadingSettingsView` |
| 読書画面の図 | `Resources/Reader/reader.js`、`MermaidRendererResources`、同梱ランタイム |
| PDF入力・スタイル | `OutputDocument`、`OutputTextStyle` |
| PDF生成・図合成 | `DocumentPDFGenerator`、`MermaidPDFRenderer` |
| 出力画面・OS操作 | `DocumentOutputView`、PDFKit、`PDFExportDocument`、OS別印刷ボタン |
| Finder Quick Look | `AyamiQuickLook`、`PreviewProvider`、`QuickLookHTMLRenderer`、SVG添付 |
| 端末内AI | `DocumentSummary`、`DocumentSummaryView` |

`project.yml`が構成の正本。Mac本体・拡張・Macテストは`ARCHS: arm64`。
アプリと拡張のバージョンは1.5、ビルドは21。アプリのBundle IDは
`io.github.hshimomura.MDViewer`、製品拡張は末尾`.QuickLook`で互換性を維持する。
改名時の判断は[構成変更記録](repository-rename.md)に残す。

## 文字サイズと文書画面

- `readerFontScale`を端末単位の`@AppStorage`で保存。初期値1.0、範囲0.80〜1.60、5%刻み。
- 範囲外を制限し、NaN・無限大は初期値へ戻す。「標準に戻す」は100%。
- 本文のCSSルート文字サイズへ適用。Dynamic Typeの倍率も反映。目次・ステータスはシステム設定に従う。
- MarkdownやPDFの独立したレイアウトは変更しない。Dynamic Typeも維持する。

Macの「ファイルを開く」は個別ウィンドウ、「新しいタブでファイルを開く」はネイティブタブへ追加する。
文書中のローカルリンクはタブが初期値。「閲覧設定」の「文書リンク」で新しいウィンドウにも変更できる。
`readerLinkDestination`に`tab`または`window`を保存し、同一ファイル内のアンカーは現在の文書で移動する。
Webリンクは既定のブラウザーへ渡す。
Macのリンク右クリックはアプリの専用メニューを使い、通常表示・新しいタブ・新しいウィンドウ・
保存・URLコピーを扱う。WebKitの表示用URLではなく、元文書を基準にした実URLを解決する。
保存は保存先パネルで選択し、ローカルファイルには通常のフォルダー境界検証を適用する。
元ファイル自身への保存は拒否する。HTTP(S)の保存は利用者の操作時だけ、非永続URLSessionで取得する。
Webリンクの表示先はブラウザーへ任せ、Macのタブ・ウィンドウ指定はローカル文書に限定する。
起動画面は初回に一度案内する。「次回起動時もこの画面を表示する」は初期値オフ。
`hasSeenWelcome`と`showWelcomeAtLaunch`を端末内に保存し、次回以降はチェックした場合だけ表示する。
非表示にした後も「ヘルプ」から起動画面と技術文書サンプルを開ける。
「ウインドウ → 起動画面を表示」は起動画面のSceneに登録し、文書を開いていない状態でも使えるようにする。
すべてのウインドウを閉じてもアプリは終了しない。このメニューから起動画面を再表示し、文書を開き直せる。
左右配置は文書ウィンドウだけを対象とし、Macのみ外部ファイルを約400ms間隔で監視する。

iOSはFilesから開き、compact幅は目次シート、regular幅は230ptの目次と本文をHStackで並べる。
DocumentGroupにNavigationSplitViewを重ねず、Duoの文書バー重複を防ぐ。
端末名や`.phone`で配置を固定せず、iPadの複数ウィンドウはOSへ任せる。
独自のファイルポーリングは行わず、外部変更が反映されない場合は文書を開き直す。

## 1.5の閲覧セッション

- 文書ごとに非永続`WKWebView`を保持。compact/regularのレイアウト変更でも同じページを再利用する。
- メッセージハンドラーは弱参照の中継を使い、ページとCoordinator・セッションの循環参照を避ける。
- 検索とピンクのマークはCSS Custom Highlightで描画。元文書の文字列やDOMの本文を注釈用に書き換えない。
- 登録済みの`Highlight`を保持し、`clear()`／`add()`で描画範囲を更新する。
  同じキーへの`CSS.highlights.set()`による置き換えは、WebKitで再描画されない場合があるため避ける。
- マークはページのメモリーだけに置く。保存、UserDefaults、ログ、PDFへの転記を行わない。
- 再読み込み時は引用文字列と前後の文脈でマークを照合。特定できないマークは解除して案内する。
- 読書位置は表示中の段落の内容と画面内の位置で復元。挿入された文章の行数に依存しない。
- 相対画像は専用URL schemeで渡す。文書のフォルダー、利用者が選んだプロジェクト、同梱サンプルだけを許可する。
- 実パスの解決でシンボリックリンクの範囲外参照を拒否。画像は1件20MiBまで。外部画像は読み込まない。
- プロジェクトの許可はアプリのセッション内だけ有効。ブックマークとして保存しない。
- 関連文書はMacではDocumentGroupで開く。iOSでは専用の読み取り専用画面で開く。
- Markdown内のHTMLと`.html`／`.htm`をDOMPurifyで処理。表・強調・折りたたみと許可したインラインCSSを表示する。
- 文書のスクリプト、iframe、フォーム、イベント属性を除去。文書のIDは接頭辞で読書UIと分離する。
- スクリプトは同梱資産のみ。外部通信はCSPで拒否し、画像は許可したローカル画像とrasterのdata URIに限定する。

## テキストファイル

`MarkdownDocument`はMarkdownのほか、テキスト・JSON・ソースコード・一般データのViewerとして登録する。
追加形式は`LSHandlerRank=None`で既定アプリを奪わず、読み込み時にテキストかどうか判定する。
`TextFileContent`は最大20MiB、UTF-8（BOM含む）、BOM付きUTF-16/32、Shift JISに対応する。
NULなどの制御文字を含むバイナリーと上限を超える入力は説明付きで拒否する。

`.md`／`.markdown`はMarkdown、`.html`／`.htm`はHTML、それ以外の拡張子は原文を保つテキストとして表示する。
JSON・Cなどは対応するPrism文法がある場合に色分けし、検索・マーク・コピーも利用できる。
印刷・PDFは別パイプラインのため、Markdown以外は原文をコードとして出力する。
HTMLの見た目の再現は行わない。出力側の1MiB上限は維持する。

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

閲覧ガイドの「Quick Lookの設定を開く」は、システム設定のログイン項目と機能拡張へ
`extensionPointIdentifier=com.apple.quicklook.preview`を指定して移動する。
Quick Lookの一覧を直接開くURLはOS側の仕様に依存するため、ガイドの手動経路も残す。
URLの起動要求が失敗した場合は公開APIの`SMAppService.openSystemSettingsLoginItems()`へ戻す。
有効化スイッチをアプリから変更することはない。

Macアプリが`AyamiQuickLook.appex`を同梱する。`net.daringfireball.markdown`を対象に、
データ方式の`QLPreviewProvider`がUTF-8を読み、`QuickLookHTMLRenderer`で連続HTMLを生成する。
Mermaidは同梱ランタイムでSVGを生成し、`QLPreviewReplyAttachment`としてCID参照で渡す。
HTML内で文書由来のスクリプトは実行せず、本文のHTML記号をエスケープする。
改ページ・用紙サイズ・ページ番号は印刷／PDF保存に限定する。
OSが選択とスクロールを管理する。AIやアプリの設定は組み込まない。

サンドボックス、ユーザー選択read-only、ローカルWebKit用`network.client`を付ける。
本文やファイル名はログに含めず、初期化・準備要求・完了・エラー型だけを記録する。
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

Swift依存とMermaidの固定版は1.3と同じ。1.5ではmarkdown-it 15.0.3と、Textual同梱版と同じ
Prism 1.29.0のブラウザーバンドルを追加。取得元・SHA-256・ライセンスは[1.5検証記録](validation-1.5.md)と
[第三者通知](../THIRD_PARTY_NOTICES.md)を参照する。
読書用と出力用Mermaidは同じ資産を使い、CSP・外部遷移拒否・リンク除去・タイムアウトを適用する。
Privacy ManifestはUserDefaults理由`CA92.1`、更新時刻理由`3B52.1`、収集・追跡なしを記録する。

ローカルMacも拡張を同梱するXcodeビルドを使う。SwiftPMは単体テストに使うが拡張の配布バンドルを作らない。
Mac UIテストは別識別子の同じ製品ソース、iOS UIテストは共有画面の専用ホストを使う。
製品にブラウザーバイパスを追加せず、ストア画像は製品ターゲットから撮影する。

[ビルドとテストの入口](../README.md) · [配布チェックリスト](../AppStore/release-checklist.md) ·
[名称・アイコン](app-name-plan.md) · [初期iOS計画との差分](ios-ipados-font-size-implementation-plan.md)
