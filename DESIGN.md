# Ayami 1.3 設計

## 方針

macOS 26+、iOS/iPadOS 18+ の読み取り専用 Markdown ビューアーとする。
SwiftUI の `DocumentGroup(viewing:)` と Textual を共通基盤にし、Mermaid だけを
同梱ランタイムによるローカル WebKit で描画する。編集、Electron、データベース、
アカウント、独自の同期サービス、Quick Look 拡張は追加しない。

対応機能とビルド手順は [README](README.md)、責務と設定の詳細は
[実装仕様](docs/ayami-implementation.md) を正本とする。

## 文書から表示まで

```text
Mac: Finder / File menu          iPhone・iPad: Files document browser
             \                         /
              SwiftUI DocumentGroup(viewing:)
                         |
                 MarkdownDocument
                  UTF-8 -> String
                         |
               PreviewDocumentModel
          Macのみ: 外部変更を約400ms間隔で確認
                         |
               MarkdownContentParser
            見出し / 本文 / Mermaid を分離
                    /           \
       Textual StructuredText   WKWebView + 同梱Mermaid
       ネイティブ本文表示       strict / オフライン
```

Foundation の Markdown 解析を使う Textual に、HTML 改行の独自処理を組み合わせる。
採用バージョン、Prism の制約、更新方法は [依存監査](docs/dependency-audit-1.3.md) を参照する。
検討段階の別ライブラリーの評価は現行の依存仕様として扱わない。

## プラットフォーム境界

- 共通: 読み取り専用文書、パーサー、目次、本文、文字サイズ設定、Mermaid。
- Mac 専用: アプリ入口、File/View/Window メニュー、ネイティブタブ、左右配置、
  外部ファイル監視、印刷、ウィンドウサイズ復元。
- iOS 専用: Files の文書ブラウザー、`UIViewRepresentable`、サイズクラスに応じた表示。
  iPad の複数ウィンドウはシステムへ任せ、Mac Catalyst へ置き換えない。

Mac の目次は `NavigationSplitView`。iOS のナビゲーションは DocumentGroup に一本化し、
compact 幅では目次シート、regular 幅では HStack 内の目次と本文を並べる。
regular 幅を iPad と同一視しない。Duo の内側画面にも同じ配置を適用する。

## 表示設定と文書保護

文字倍率は `ReadingPreferences` と `@AppStorage` で端末単位に保存する。
Textual と Mermaid へ同じ倍率を渡し、文書の内容や保存データには反映しない。
システムの Dynamic Type は無効にしない。

Mac の印刷は画面表示とは別の TextKit レイアウトを使う。Mermaid はソースコードへ
フォールバックする。iOS の印刷・PDF 出力・独自ファイルポーリングは実装しない。

## WebKit とプライバシー

Mac の `network.client` entitlement はローカル WebKit のヘルパープロセス起動のために使う。
Mermaid の HTML/JavaScript は同梱し、`default-src 'none'` を基本にした CSP、
外部ナビゲーション拒否、SVG 内リンク除去、タイムアウトを組み合わせる。
文書や利用情報を開発者へ送信する処理は持たない。

選択した Markdown は書き換えない。Mac のユーザー選択 read/write 権限は
標準 Print パネルで選ぶ PDF 出力先に使う。設定値は端末内の UserDefaults に保存する。
利用者向けの説明は [プライバシーポリシー](docs/privacy.md) を参照する。

## 検証と今後の範囲

1.3（18）は Xcode 27.1 で検証した。テスト件数・実機未検証の範囲は
[検証記録](docs/iphone-duo-validation-1.3.md) に集約する。
依存ライセンスは [第三者通知](THIRD_PARTY_NOTICES.md) と配布物検証で確認する。

残る候補は相対パス画像、安全なファイル参照、Find、iOS 印刷・PDF 出力、
大規模文書の性能・アクセシビリティの追加検証。実装済みの文字サイズ調整、
Universal 2、タブ、印刷、オフライン Mermaid を将来計画には含めない。

Developer ID による直接配布・notarization は、現在の App Store 配布とは別工程とする。
