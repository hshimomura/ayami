# iPhone・iPad 初期計画との差分

iPhone/iPad 対応と文字サイズ設定は 1.3（18）で実装済み。
この文書は初期案からの判断変更だけを残す。現行仕様は
[実装仕様](ayami-implementation.md)、テスト結果は [検証記録](iphone-duo-validation-1.3.md) を参照する。

| 初期案 | 採用した構成・理由 |
| --- | --- |
| Mac ターゲット `AyamiMac` | 既存 Mac ターゲットを `Ayami`、iOS を `AyamiIOS` に統一 |
| `Sources/Shared`・`macOS`・`iOS` へ全面移動 | `Sources/Ayami` を共有し、AppKit 依存を XcodeGen の除外指定で分離。iOS の入口だけ `Sources/AyamiIOS` |
| `MermaidWebViewCore` と OS 別ファイルへ分割 | 同じ `MermaidDiagramView` の Coordinator を使い、representable 部分のみ条件コンパイル |
| 広い画面を iPad とみなし NavigationSplitView を入れる | サイズクラスで配置を選択。iOS のナビゲーションは DocumentGroup に一本化し、regular 幅は HStack。Duo でも適用 |
| 最初の iOS 版は 1.0 | Mac と同じ 1.3、ビルド18を使用 |
| iOS の共有・印刷を初版に含める案 | 読み取り専用オープンを優先。独自の共有・印刷・PDF 出力は追加しない |
| 無警告ビルドを一律の完了条件にする | ビルド・テストの成功と、失敗を伴わないシステム診断を区別して記録 |

## 維持した方針

- Mac Catalyst に置き換えず、ネイティブ Mac アプリを維持する。
- iOS は Files と DocumentGroup、iPad はシステム管理の複数ウィンドウを使う。
- Mac のタブ・左右配置・Live Reload・印刷は iOS へ移植しない。
- 端末内に保存する文字倍率を Textual と Mermaid に適用し、元の Markdown は変更しない。
- 同じ Bundle ID を使うプラットフォーム別ターゲットとし、新しい別アプリにはしない。

実機 Files/iCloud Drive、iOS 18 上の実行、最大 Dynamic Type、VoiceOver、
ファイルプロバイダーごとの挙動の追加確認は、シミュレーターの合格と混同しない。
