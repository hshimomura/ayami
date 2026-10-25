# あやみ：iPhone・iPad対応と表示設定

## 採用仕様

名称を「あやみ / Ayami」へ変更し、macOS版を残したままiPhone・iPad版を追加する。
Markdown文書を読み取り専用で開く方針、オフラインMermaid、データを収集しない方針は維持する。

| 項目 | 実装 |
| --- | --- |
| 日本語App Store名（ローカル原稿） | `あやみ — Markdownビューア` |
| 英語App Store名（ローカル原稿） | `Ayami: Markdown Reader` |
| インストール後の名称 | 日本語 `あやみ`、その他 `Ayami` |
| macOS | 26以降、既存の `MDPreview` スキーム |
| iPhone・iPad | iOS/iPadOS 18以降、新しい `AyamiIOS` スキーム |
| バージョン | 1.3、ビルド17（依存更新後の検証は [依存監査](dependency-audit-1.3.md) を参照） |
| Bundle ID | `io.github.hshimomura.MDViewer` を維持 |
| 文字サイズ | 80〜160%、5%刻み、初期値100%、端末内保存 |
| アイコン | 明るい生成り・杏色背景、白いMarkdown文書、テラコッタ色の見台 |

App Store名は原稿の変更であり、今回App Store Connectへの名称保存や提出は行わない。
海外の既存 `AYAMI` とは異なる用途だが、名称の保存可否や審査承認は未確認である。

## 実装順と責務

1. **ターゲット分離**: `project.yml` にiOSアプリと単体・UIテストターゲットを追加する。
   AppKit依存のアプリ入口、印刷、ウィンドウ復元はiOSターゲットから除外する。
2. **共通表示設定**: `ReadingPreferences` に範囲・初期値・正規化を定義する。
   `ReadingSettingsView` と `@AppStorage` で全ウィンドウへ即時反映する。
3. **本文と図の拡大**: Textualの `fontScale`、Mermaidの `themeVariables.fontSize` へ
   同じ倍率を渡す。Dynamic Typeは無効にせず、UI全体の拡大変換は使わない。
4. **適応レイアウト**: compact幅では本文を優先し目次をsheetへ、regular幅では
   `NavigationSplitView` のサイドバーへ表示する。
5. **WebKit移植**: 同じCoordinatorを使い、macOSは `NSViewRepresentable`、iOSは
   `UIViewRepresentable` とする。ローカル描画・外部遷移拒否・タイムアウトを共通化する。
6. **改名とアイコン**: Info.plist、InfoPlist.strings、生成物名、検証スクリプト、
   App Store原稿、公開文書を更新する。
7. **検証**: macOS単体テスト、iOSコンパイル、iPhone/iPadの単体・UIテストを実施する。

既存ソースの大規模移動は避け、今回はXcodeGenのソース除外でAppKit依存を分離する。
共有の `PreviewView` とMermaidラッパーのプラットフォーム差分だけを条件コンパイルにする。
旧計画の `Shared/macOS/iOS` ディレクトリへの全面移動は後続の整理事項とする。

## 設定の挙動

- macOSはアプリメニューのSettingsと文書ツールバーから表示設定を開く。
- iPhone・iPadはツールバーの文字サイズボタンから開く。
- 本文、見出し、コード、表、Mermaidへ倍率を渡す。目次とステータスはシステム設定に従う。
- 設定を変えてもMarkdownファイルへ書き込まない。
- 「標準に戻す」で100%へ戻す。
- 保存値が範囲外なら制限し、NaNや無限大なら100%へ戻す。
- 印刷は従来どおり独立した読みやすいレイアウトを使い、閲覧倍率では変更しない。
- Privacy Manifestへアプリ内UserDefaultsの利用理由 `CA92.1` と、macOSのユーザー選択
  文書に対する更新検知の利用理由 `3B52.1` を記載する。データ収集・追跡は追加しない。

## 文書管理

macOSのLive Reloadは従来の監視を継続する。iOSではファイルURLをポーリングせず、
`DocumentGroup(viewing:)` が管理する読み取り専用文書の変更を共有モデルへ反映する。
FilesやiCloud Driveなどの外部プロバイダーで更新した際は、必要に応じて文書を開き直す。

macOSのネイティブタブ・左右配置・印刷は維持する。設定ウィンドウは文書の左右配置対象に含めない。
iPadはシステムのマルチウィンドウを使い、macOSの `NSWindow` 操作を移植しない。
iOSの印刷・PDF出力、独自のブックマーク同期、独自のiCloudストレージは今回追加しない。

## アイコン生成

組み込みのimagegenで新しいラスターのマスターを生成した。青背景を使わず、
明るい生成りと淡い杏色、白い文書、暖色の見台に限定する。
窓の赤黄緑ボタン、鉛筆、封筒、ダウンロード矢印は使わない。

- マスター: `Resources/Ayami-Icon-Master.png`
- 1024px配布元: `Resources/AppIcon-1024.png`
- macOS: `Resources/AppIcon.icns` とmac idiomのAppIcon画像
- iOS: AppIcon asset catalogの1024px universal画像
- 再生成: `./Scripts/build-icon.sh`
- プロンプト: [ayami-icon-prompt.txt](ayami-icon-prompt.txt)

これはフラットな完成画像で、Icon Composerのレイヤー付き `.icon` ではない。
アイコンのLiquid Glassレイヤー化は、必要なら別工程で行う。
`iconutil` が失敗した場合も、古いICNSを再利用せず、新しいPNGからICNSを組み立てる。

## 検証手順

```sh
./Scripts/generate-xcode-project.sh
swift test
./Scripts/verify-app-store-metadata.sh

xcodebuild -project MDViewer.xcodeproj -scheme MDPreview \
  -destination 'platform=macOS' test

xcodebuild -project MDViewer.xcodeproj -scheme AyamiIOS \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build

# xcrun simctl list devices available で端末名を確認して実行する
xcodebuild -project MDViewer.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
xcodebuild -project MDViewer.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
```

UIテストは配布アプリとは別のテスト専用ホストで、共有の文書画面にサンプルを表示する。
スライダーの変更、再起動後の保持、100%へのリセット、目次の選択を確認する。
配布アプリにはテスト用の起動引数や文書ブラウザーのバイパスを含めない。

## 配布前に残る確認

- 実機のFiles / iCloud Driveからのオープン、外部プロバイダー更新、回転、複数ウィンドウ
- VoiceOver、最大Dynamic Type、長い表・コード・大きいMermaid図
- 日本語表示名と小サイズ・ダーク表示でのアイコンの視認性
- App Store Connectで日英名称の保存可否を確認
- 新名称・設定画面を含めたスクリーンショットを作成
- 同じApp Store ConnectレコードへiOSプラットフォームを追加し、署名とプロビジョニングを確認
- macOS/iOSの配布署名アーカイブとApp Store用検証、アップロード、審査提出

## 実施済み検証（依存更新前の1.2 / build 16）

2026年10月25日、Xcode 27.1で検証した。以下は依存更新前の結果であり、
リリース予定の1.3については [依存監査と検証結果](dependency-audit-1.3.md) を参照する。

| 検証 | 結果 |
| --- | --- |
| macOS単体テスト（SwiftPMとXcode） | 20テスト成功 |
| iPhone 17 Pro / iOS 26.5 Simulator | 単体6テスト、UI2テスト成功 |
| iPad Pro 13-inch (M5) / iOS 26.5 Simulator | 単体6テスト成功、横並び修正後のUI2テスト成功 |
| 実機向けReleaseコンパイル | iOS 27.1 SDK、arm64、署名なしで成功 |
| ローカルmacOSアプリ | 改名・日本語表示名・署名・Mermaidリソースの検証に成功 |
| 日英App Store原稿 | 文字数制限の検証に成功 |
| 新アイコン | 1024px、不透明のiOS画像、ICNS生成・再展開を確認 |

iPadの初回UIテストではアクセシビリティ接続が失われた。別テストとして再実行すると成功した。
目視確認で目次のオーバーレイ表示も見つけ、iOSでは `.balanced` スタイルへ調整した。
テスト用ホストでのiPhone/iPadスクリーンショットも目視確認した。FilesやiCloud Driveの実機試験、
iOS 18の実行試験、App Store向け配布署名の検証までは完了していない。

以前のアーカイブを誤送信しないよう、アップロードスクリプトは `Ayami 1.3 (17)` 以外の
アーカイブを拒否する。今回の変更は未コミットで、ストアへのアップロードは行っていない。

## 参考

- [Apple: DocumentGroup](https://developer.apple.com/documentation/swiftui/documentgroup)
- [Apple: Settings](https://developer.apple.com/documentation/swiftui/settings)
- [Apple: AppStorage](https://developer.apple.com/documentation/swiftui/appstorage)
- [Apple: Add platforms](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-platforms/)
