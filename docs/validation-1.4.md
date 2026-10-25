# あやみ 1.4（19・20）実装・動作検証

## ビルド20: Quick Lookの連続表示

ビルド20ではQuick Lookを印刷用PDFから連続HTMLへ変更した。
Mermaidは同梱ランタイムでSVGを生成し、CID添付として渡す。用紙・改ページ・ページ番号は
印刷／PDF保存のフローに残す。以下はビルド19の結果とは別に実施した確認。

- Macの`swift test`は39件の実行結果が成功。任意のAI実生成1件はskip。
  100段落のHTML保持、スクリプトのエスケープ、SVG添付、無効な図のソース表示を追加し、
  既存の長文PDF改ページ・図のPDF出力も再確認した。
- Macの隔離UIホストで印刷パネルの表示／取消、システムパネル経由のPDF保存が成功。
- FinderでHTMLのWebViewとSVG中の`PrintedDiagram14`を確認し、画面でも本文・表・図を確認。
  PDFのページ一覧・ページ番号は表示されない。
- 最初のFinderテストは、SVGをImage要素として探した点と、空のApplicationフレームを
  スクリーンショットに使った点で失敗した。実際のSVGはGroupと文字として公開されていた。
  文字とQuick Lookウィンドウを検査する形へ直し、Finder単独の再実行は成功した。
- iPhone 17 Pro / iOS 26.5 Simulatorで、PDF・SVG・ビルド番号の対象10件が成功。
  この変更でAI実生成や実機・紙への印刷を追加検証したものではない。
- Mac・iOSの1.4 (20)配布アーカイブ／書き出しで、署名・版・権限・配布資産の検証に成功。

証跡はGit管理外の`.build/results/mac-1.4-20-continuous.xcresult`（印刷・保存成功と初回Finder失敗）、
`mac-1.4-20-finder-confirmed.xcresult`（Finder成功）、`ios-1.4-20-output.xcresult`（対象10件成功）に保持する。
以下はビルド19での検証履歴。

## 目的と状態

2026-10-25、`codex/ayami-1.4-validation` で1.3を基準に実装・検証した記録。
この記録の対象は利用可能なMacとシミュレーターでの動作確認。
検証後に利用者から印刷成功の確認を受けた。AI試作も1.4の配布範囲に含める。
**Macの印刷・PDF保存とFinder Quick Look、iPhone/iPad/Duoの印刷画面・PDF保存を確認した。**
Finderは利用者によるQLMarkdown削除後、製品Release拡張で本文とMermaid図を表示した。
全端末の実機検証や、AIの全プラットフォームでの生成確認を完了したという意味ではない。
実機・AirPrintプリンターは使わないという利用者の指定に従った。
既存の1.3アーカイブは保持し、1.4配布物は `dist/1.4/` に分離する。
審査・提出に関する運用記録はGit管理外の `AppStore/private/` に分け、この動作記録とは区別する。

## 検証結果

| 項目 | 環境 | 結果 |
| --- | --- | --- |
| Apple silicon専用 | Mac M4 / macOS 27.0.1 / Xcode 27.1 | Mac本体・Quick Look拡張とも `arm64` のみ。Apple Development署名の最終Releaseビルド成功 |
| 配布アーカイブ・書き出し | Mac App Store / iOS App Store | 1.4（19）の両配布物で署名・版・権限・資産検証に成功。Mac製品Quick Lookも確認。iOSのFoundationModels弱リンクを確認 |
| 単体・回帰・実モデル | 同Mac、`swift test` | 最終36件成功。日本語の実AI要約、6種類の図のPDF出力、全PDFページの実描画検査を含む |
| PDF生成・図・改ページ | 同Mac | A4の日本語・表・Mermaid図、Letterの100行の表と本文8ページを生成。文字抽出、全ページ画像、本文のインク量を確認 |
| iPhone基本操作 | iPhone 17 Pro / iOS 26.5 Simulator | 一括では単体25件、UI8件成功・AI実生成1件skip。その後の単体26件と印刷・実保存2件も成功。最新の保存完了表示まで追加確認 |
| iPad基本操作 | iPad Pro 13-inch (M5) / iPadOS 26.5 Simulator | 最終一括で単体26件、UI8件成功・AI実生成1件skip。印刷画面、Files経由の実保存・完了表示を含む |
| Duo基本操作 | 専用iPhone Duo / iOS 27.1 Simulator | 基本UI7件成功。その後の単体26件、印刷・実保存2件と最新の保存完了表示まで追加確認。現在選択された画面と回転を対象とし、今回の内外画面切替は未確認 |
| Macの印刷・PDF保存UI | macOS 27.0.1 / XCUITest | 製品と同じソース・サンドボックスを使う専用識別子のアプリで、印刷パネル表示・取消完了、Exportパネル経由のPDF実保存が成功。保存PDFの日本語・表・Mermaid図を画像でも確認。元のMarkdownが変わらないことも検査 |
| Finder Quick Look | macOS 27.0.1 / XCUITest | 利用者によるQLMarkdown削除後に成功。製品識別子のRelease拡張で日本語・表・Mermaid図を表示し、図の文字を独立した表示要素として検査。印刷・保存と合わせた最終3件もすべて成功 |
| 端末内AI実生成 | Mac | `SystemLanguageModel.default` で日本語の要約生成成功。文書の主要数値・Markdown/PDF/Mermaidの説明を目視確認 |
| 端末内AI実生成 | iPhone Simulator | availabilityはavailableだが生成はFoundation Modelsのエラーとなった。実生成の動作確認は失敗。iPad/Duoの実生成は未確認 |
| 紙への印刷・iOS実機 | なし | 対象外。システムの印刷オプション画面までを確認し、印刷ジョブは送信していない |

件数は実行ごとの値。Swift Testingの表示件数には、明示的に無効化した任意の実モデルテストが
含まれる場合がある。iOS側の単体26件ではこの1件はskipしている。AIの実生成成功とは扱わない。
Macのアプリホスト式Xcodeテストは起動待ちで停止し、今回のテストプロセスだけを中断した。
製品の検証用Macアプリも、取得したスタックではアプリ本体に入る前の
`_libsecinit_appsandbox` で待機していたため終了した。SwiftPMの成功と区別する。
通常の画面操作ツールも起動できなかったため、Finder操作の
自動化へ進む前にXCUITest利用の可否を利用者へ確認している。

### Mac XCUITestの追加確認

利用者の承認を受け、製品と同じMacソース・サンドボックス設定を使う
`AyamiMacUITestHost` と `AyamiMacUITests` を追加した。
専用Bundle ID `io.github.hshimomura.AyamiMacUITestHost` を使い、
既存の1.3アプリ・文書ウィンドウ・UserDefaultsを操作しない。
ファイル関連付けの優先順位は `LSHandlerRank: None` とする。
`UIValidation` 構成では製品と同じQuick Lookソースを同梱し、拡張の識別子だけを
`io.github.hshimomura.AyamiMacUITestHost.QuickLook` とする。
製品のDebug/Releaseの識別子・対応形式は変更しない。

2026-10-25の初回はUIテストと専用アプリのコンパイル・署名に成功したが、
テストランナーが自動操作の初期化で停止した。ランナーのスタックは
`XCUIDevice.enableAutomationMode` の応答待ちで、`testmanagerd` のログには
`Writer daemon requires authentication to enable automation mode`、
`Enable UI Automation` のLocalAuthentication要求があった。
テスト本体はまだ実行されていない。Mac上で利用者が認証する必要があり、
OSのセキュリティ設定や開発者モードは変更していない。
初回実行は `Timed out while enabling automation mode` で終了した。
結果は `.build/results/mac-1.4-ui-initial.xcresult` に保持する。
これは印刷・PDF・Quick Lookの機能テスト失敗ではなく、テスト開始前の認証タイムアウトである。

その後、利用者がMac上で自動操作を承認し、テストを実行できた。
`mac-1.4-isolated-integration.xcresult` では印刷と実保存の2件が成功し、Finder描画の1件は失敗した。
保存されたPDFは `.build/qa/1.4/mac-ui-save/` に抽出し、A4・1ページ・選択可能な日本語と図を確認した。
印刷では検証アプリだけのローカルネットワーク探索を許可せず、キャンセル後にパネルが閉じることまで検査する。
製品アプリのネットワーク権限やプリンター設定は変更せず、印刷ジョブも送らない。

初回のテスト実装にはTouch Barと画面上のボタンの重複、MacのStaticTextがlabelでなくvalueを使う点、
保存ボタンがSaveでなくExportになる点の指定不備があった。これらはテスト側を修正した。
当初のFinderプレビューにはMarkdownのソースが表示され、拡張の初期化・要求受信・描画完了ログはなかった。
この段階のビルド成功・登録成功は、Quick Lookの動作成功とは扱わない。

利用者がQLMarkdownをApplicationsからDesktopへ移動しても、拡張登録は残った。
利用者の承認を受け `org.sbarex.QLMarkdown.QLExtension` だけを一時的にignoreとして比較したが改善せず、
元のdefault状態に戻した。Desktopのアプリ本体と他の拡張設定は変更していない。
独自UTType `io.github.hshimomura.ayami.ql-validation` と `.ayamiqltest` は対照試験専用で、製品には追加しない。
利用者はシステム設定でAyami拡張が表示・有効であることを確認し、その後QLMarkdownを削除した。
その状態でFinder描画が成功し、拡張のログに `Prepared Quick Look PDF: pages=1, diagrams=1` を確認した。
OSLogの実行ファイルパスは `.build/1.4-validation/Build/Products/Release/Ayami.app/Contents/PlugIns/` 内で、
製品Bundle ID `io.github.hshimomura.MDViewer.QuickLook` のRelease拡張が動いたことを確認した。
共存・登録状態の影響は観測したが、QLMarkdown一般の不具合や常に同じ優先順位になることまでは断定しない。
利用者が削除したQLMarkdownは復元・再登録していない。他社の拡張設定も変更しない。

公開サンプルは、テストランナーからのDocuments読み取りがTCCで拒否されたため、
`Scripts/prepare-mac-ui-fixtures.sh` で `/private/tmp/ayami-1.4-quicklook-public/` へ用意する。
既存ファイルは上書きせず、所有者・シンボリックリンク・内容を検査する。
Finderの同名ウィンドウが複数ある場合の要素指定も修正した。
Macの印刷はSwiftUIの出力画面が開いていても操作できるよう、アクティブなウィンドウに付随する
印刷パネルを使うよう変更し、取消後にパネルが閉じることまで再確認した。

最終 `mac-1.4-final-confirmed.xcresult` は印刷・PDF実保存・Finder描画の3件すべて成功。
続けて `mac-1.4-preview-for-user.xcresult` のFinder単独テストも成功し、利用者の依頼に従って
`PublicSample14.md` のQuick Lookを開いたままにした。
その後の最終Releaseビルドと実モデルを含む `swift test` 36件も成功した。

再現コマンド（認証ダイアログが表示されたらMac上で承認する）：

```sh
./Scripts/prepare-mac-ui-fixtures.sh
xcodegen generate --spec project.yml
xcodebuild -project Ayami.xcodeproj -scheme AyamiMacUIValidation -configuration UIValidation \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath .build/1.4-mac-ui \
  -only-testing:AyamiMacUITests/MacOutputUITests/testNativePrintPanelOpensAndCancelsWithoutJob \
  -only-testing:AyamiMacUITests/MacOutputUITests/testPDFSaveThroughSystemPanelPreservesSource \
  -only-testing:AyamiMacUITests/MacOutputUITests/testZFinderQuickLookRendersPublicSample \
  -parallel-testing-enabled NO DEVELOPMENT_TEAM=ZLX73742D3 \
  CODE_SIGN_IDENTITY='Apple Development' test
```

製品拡張を登録・有効化した状態で上記3件を実行する。
対照用UTTypeのテストは検証専用拡張の登録が必要なため、この製品確認には含めない。
Finder単独テストでビルド設定 `AYAMI_KEEP_PREVIEW_OPEN=1` を渡した場合だけ、
確認用のQuick Lookと専用Finderウィンドウを閉じずに残す。通常実行では閉じる。

保存テストは一意の一時フォルダーに公開サンプルを作り、システム保存パネルでPDFを保存し、
PDFの本文・図・元のMarkdownが変わらないことを検査する。
印刷テストはパネルを開いてキャンセルし、印刷ジョブを送らない。
Finderテストは専用フォルダーを新しいFinderウィンドウで開いてQuick Lookを取得する。
図の文字がPDFの独立した表示要素として現れることを確認し、汎用のソース表示だけでは成功にしない。

## 実装との対応

構成・データフロー・上限の正本は[設計](../DESIGN.md)と[実装仕様](ayami-implementation.md)。
以下は検証時に確認した要点と診断経緯であり、別の仕様を定義するものではない。

### MacをApple silicon専用にする

`project.yml` のMac本体・テスト・Quick Lookで `ARCHS: arm64` を指定した。
生成されたMach-Oを `lipo -archs` で確認した。Universal 2ではなくApple silicon専用とする。
Bundle IDは継続し、既存文書との関連付けは変更しない。

### 全プラットフォームの印刷・PDF・Mermaid

共通PDF生成では本文の文字抽出、日本語、表の改ページ・見出し繰り返しを検査した。
フロー、シーケンス、クラス、状態、ER、マインドマップの6種類をPDF生成で確認した。
無効な図の警告・ソースへのフォールバック、入力上限、取消、空文書も単体試験の対象。
出力UIでは実ファイルと保存完了表示、Macの取消後の印刷パネル終了を確認した。
対応記法・サイズ上限・OS別の印刷実装は[実装仕様](ayami-implementation.md)に集約する。

### Mac Quick Look

現状は**実装済み・製品Release拡張によるFinderでの専用描画確認済み**。
次のいずれも、単独では実動作成功の代替にはしない。

- `pluginkit` に1.4が登録されることだけ。
- `QLPreviewPanel` が表示されることだけ。
- 共通PDF生成の単体テストが通ることだけ。

初期の診断では `qlmanage -p -o ...` が `EXConcreteExtension` 内の `key cannot be nil` 例外で終了し、
当拡張の準備完了ログは確認できなかった。ad-hocとApple Development署名の双方で再現。
データ方式への変更後も同じだったが、最終判定はその後成功したFinderでの実表示を使う。
`Tests/AyamiQuickLookProbe` は独立したAPI診断用アプリで、製品に組み込まれない。
初期の切り分け終了時には検証登録を解除し1.3を再登録したが、その後製品1.4を再登録して確認した。
最終状態では製品Quick Lookを有効のまま残し、検証専用拡張の明示的な選択はdefaultへ戻した。
既存の1.3アプリプロセス・文書ウィンドウは終了していない。

### 端末内AI「文書の要点」（試作）

`SystemLanguageModel.default`による公開サンプルの日本語実生成をMacで確認した。
利用状態の表示だけを生成成功とは扱わず、iPhoneの生成失敗記録も保持する。
OS条件、分割・生成方式、プライバシー境界は[実装仕様](ayami-implementation.md)を参照する。

**採否判断:** Macで基本的な有効性は確認できたが、iOSの実生成は未確認・失敗が残る。
利用者はこの制限を認識したうえでAIも1.4の配布へ含めることを明示した。
試作の表示と利用条件・生成失敗時の説明を維持する。要約精度の網羅評価も終わっていない。
シミュレーターはホストMacのモデルを使い、OS/モデルのバージョン差で失敗し得ると
[Appleの説明](https://developer.apple.com/forums/thread/787445)にある。
今回の組合せが原因だと確定したわけではなく、対応するモデル環境で再検証する。

## 再現方法と証跡

```sh
# Mac本体と拡張を同時にビルド。Apple Development証明書が必要。
./Scripts/build-validation-app.sh
# 出力: dist/validation-1.4/Ayami.app。旧dist/Ayami.appや配布アーカイブは保持。

# 実モデル生成は明示的な任意実行。公開テスト用本文だけを処理する。
AYAMI_TEST_LOCAL_AI=1 AYAMI_QA_OUTPUT="$PWD/.build/qa/1.4/mac" swift test

# 利用可能な端末名は xcrun simctl list devices available で確認。
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO test
```

UIテストは専用ホストの公開サンプルを使う。保存テストはUUID付きファイル名にし、
既存文書を上書きしない。システムの保存先はFilesが選ぶため、テストホストとは別の
製品アプリのDocumentsへ保存される場合もある。今回のiPhone/iPadでは実ファイルも確認した。
実モデルUIテストは `AYAMI_TEST_LOCAL_AI=1` をテストランナーへ渡す明示的な任意実行であり、
通常はskipする。失敗した実行結果を成功へ置き換えない。

ローカルの証跡はGit管理外の `.build/results/`（xcresult）と `.build/qa/1.4/`。
`iphone-1.4.xcresult`、`ipad-1.4.xcresult`、`duo-1.4.xcresult` が基本テスト。
`*-system-output.xcresult` がシステム画面、`ipad-1.4-save-final.xcresult` がiPad保存。
`iphone-1.4-save-ai.xcresult` は保存成功とAI生成失敗を含むので、全体は失敗。
`iphone-1.4-final.xcresult`、`ipad-1.4-verified.xcresult` が一括回帰の成功記録。
`*-print-latest.xcresult` が追加の単体・印刷・保存、`*-save-verified.xcresult` が
iPhone/Duoの保存完了表示を含む確認結果。
`ipad-1.4-final.xcresult` は保存画面の終了アニメーションを待たないテスト不備で失敗した。
PDFの実保存は確認でき、保存完了コールバックと画面終了を待つ修正後の一括実行で成功した。
Macの実要約は `native-ai-summary-ja.txt`、PDFは `mac/`、シミュレーター抽出分は
`iphone-saved/`、`ipad-generated/`、`duo-generated/` に整理した。

## 残る検証・制限

- 通常の配布識別子でのMac起動は、既存1.3のウィンドウ・設定を保護した状態で別途確認する。印刷・保存機能自体は同じ製品ソースの隔離環境で確認済み。
- Finderでの公開サンプルの表示と閉じる・再表示は確認済み。別ファイルへの連続切替、無効な図・大きすぎる入力のFinder上での失敗表示は追加確認とする。共通生成処理の単体テストとは区別する。
- Duoの内外画面切替で新しいPDF・要点画面が維持されることを確認する。
- AIは試作表示のまま配布する。互換モデル環境でのiPhone/iPad実生成と、長文・取消・精度の追加評価は残る。

物理プリンター・実機を今回の必須条件へ戻さない。未検証として記録し、
App Storeの説明・審査資料を変更する場合は、これらの限界を引き継ぐ。
