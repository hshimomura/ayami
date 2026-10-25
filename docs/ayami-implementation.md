# あやみ 1.3（18）実装仕様

Mac、iPhone、iPad の読み取り専用ビューアーを共通 SwiftUI コードで構成する。
名称・アイコンは実装済みで、旧名の Bundle ID は互換性のため維持する。
利用者向け機能は [README](../README.md)、データフローは [設計](../DESIGN.md) を参照する。

## ターゲットと責務

| 対象 | 実装 |
| --- | --- |
| Mac | `Ayami` スキーム、macOS 26+、`Sources/Ayami/AyamiMacApp.swift` |
| iPhone・iPad | `AyamiIOS` スキーム、iOS/iPadOS 18+、`Sources/AyamiIOS/AyamiApp.swift` |
| 共有ソース | `Sources/Ayami/`。Mac 固有ファイルは iOS ターゲットから除外 |
| 文書管理 | `MarkdownDocument` と `DocumentGroup(viewing:)` |
| 表示モデル | `PreviewDocumentModel`。Mac のみ外部ファイルを監視 |
| 目次・本文 | `PreviewView`、`OutlineSidebar`、Textual |
| 図表 | `MermaidDiagramView` と同梱リソース。macOS は NSViewRepresentable、iOS は UIViewRepresentable |
| 表示設定 | `ReadingPreferences`、`ReadingSettingsView`、`@AppStorage` |

XcodeGen の `project.yml` がターゲット構成の正本。
ソース名・リソース bundle・互換性識別子は [構成変更記録](repository-rename.md) に集約する。

## 文字サイズ

- キー: `readerFontScale`。初期値 1.0、範囲 0.80〜1.60、5% 刻み。
- 端末単位に保存し、開いている文書へ即時反映する。「標準に戻す」は 100%。
- 範囲外は制限し、NaN・無限大は初期値へ戻す。
- Textual の `fontScale` と Mermaid の `themeVariables.fontSize` に同じ倍率を渡す。
- 見出し、本文、表、コード、図へ適用する。目次・ステータスはシステムの文字設定に従う。
- 設定画面の日本語プレビューに対応し、iOS には印刷の説明を表示しない。
- 文字倍率は Markdown ファイルや Mac の独立した印刷レイアウトを変更しない。

## 文書と画面の適応

Mac では個別ウィンドウを既定とし、必要に応じてネイティブタブへ追加する。
左右配置は文書ウィンドウを対象とし、設定ウィンドウは含めない。

iOS は Files の文書ブラウザーで開き、compact 幅では目次シート、regular 幅では
230pt の目次と本文を HStack で並べる。目次の表示をツールバーで切り替えられる。
DocumentGroup に NavigationSplitView を重ねないことで、Duo の開閉時のバー重複を防ぐ。
端末名・`.phone`・固定画面サイズで iPhone/iPad を区別しない。

iOS は独自のファイルポーリングをせず、SwiftUI が管理する文書変更をモデルへ反映する。
Files/iCloud Drive などで外部変更した内容は必要に応じて開き直す。
iPad の複数ウィンドウはシステムを使い、Mac の NSWindow 操作を移植しない。

## プライバシーと配布境界

ユーザー選択文書を読み取り専用で処理し、文書のアップロードや独自同期は行わない。
Privacy Manifest は UserDefaults の理由 `CA92.1`、ファイル更新時刻の理由 `3B52.1` を記録する。
データ収集・追跡は追加しない。

Mermaid は本番とテストで同じ `MermaidRendererResources` を使用する。
ローカル描画、CSP、外部遷移拒否、タイムアウトとソース表示のフォールバックを共有する。
依存バージョンと描画・セキュリティ検証は [依存監査](dependency-audit-1.3.md) が正本。

## 検証と制限

1.3（18）の単体・UI テスト、Duo の内外画面と開閉の製品版確認は
[検証記録](iphone-duo-validation-1.3.md) に集約する。
UI テストは共有画面を使う専用ホストで実行し、製品アプリにはテスト用文書や
ブラウザーバイパスを含めない。ストア画像は製品ターゲットから撮影する。

実機の Files/iCloud Drive、iOS 18 の実行、VoiceOver、最大 Dynamic Type、
大規模文書・図表の追加確認は残る。Mac/iOS の署名付き配布物は別々に検証する。
具体的なコマンドは [README](../README.md)、[配布チェックリスト](../AppStore/release-checklist.md) を参照する。

## 関連記録

- [名称とアイコンの決定](app-name-plan.md)
- [初期計画からの差分](ios-ipados-font-size-implementation-plan.md)
- [スクリーンショット仕様](../AppStore/Screenshots/README.md)
- [1.3 リリースノート](releases/1.3.md)
