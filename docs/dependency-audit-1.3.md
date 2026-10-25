# バージョン1.3：Markdown関連依存の監査と検証

## 対象と結論

確認日：2026年10月25日。リリース予定の **1.3 / build 17** を対象とする。
macOSアプリ、iOS/iPadOSアプリ、UIテスト用ホスト、ローカル配布・検証・アップロードの
バージョンチェックを同じ値に揃えた。App Store Connectへのアップロードや公開は行わない。

## 依存構成

| 用途 | 採用バージョン | 今回の対応 |
| --- | --- | --- |
| Markdown本文の表示：Textual | 0.5.0 | 最新安定版であることを確認し維持 |
| Markdown構文解析：Foundation `AttributedString(markdown:)` | OSに付属 | Textualの実装を確認。独立したSwiftパッケージではない |
| 数式表示：SwiftUIMath | 0.1.0 | 最新安定版であることを確認し維持 |
| 並行処理補助：ConcurrencyExtras | 1.4.3 | 1.4.0から更新。SwiftPMとXcode両方のロックを更新 |
| 図表：Mermaid | 12.2.0 | 11.15.0から最新安定版へ更新 |
| コードの色分け：Prism.js | 1.29.0 | Textual 0.5.0に内蔵された版を維持。単体最新版は1.30.0 |

Textualの `AttributedStringMarkdownParser` はFoundationで構文を解析し、
presentation intentを保持したままSwiftUIで表示する。独立した `swift-markdown` は使っていない。
アプリ独自の `HTMLBreakMarkdownParser` はその結果を受け取り、コード以外の `<br>` を改行へ変換する。
独自の `MarkdownContentParser` は目次・セクション・Mermaidフェンスを分離する。
macOS印刷は独自の簡易フォーマッターを使うため、本文表示と同一のレンダラーではない。

### Prism.jsについての制約

Prism 1.30.0への直接更新は未実施。Textualの内部リソースであり、公開されたランタイム差し替えAPIがない。
`.build/checkouts` を書き換える方式は再現性がなく、Textualの独自フォークも今回導入しない。
したがって「すべての内部部品が単体最新版」ではなく、「公開された最新安定版のTextualと、
アプリが直接同梱する最新安定版Mermaid」を採用した状態である。

## Mermaid 12への移行

- npm公式配布物の `dist/mermaid.min.js` をローカル同梱する。CDNや実行時ダウンロードは使わない。
- `layout: "dagre"` と `look: "classic"` を明示し、12系の既定レイアウト変更による見た目の変化を抑える。
- `securityLevel: "strict"`、外部通信を許可しないCSP、SVG内リンク除去、外部画面遷移拒否を維持する。
- 本番とテストが `MermaidRendererResources` から同じHTML・JavaScriptを読み込む。
- Mermaid 12のSafari 17.4以降という要件は、アプリの最低対象macOS 26 / iOS 18の範囲内。
  ただしiOS 18での実行試験は未実施である。
- MITライセンスと第三者依存一覧を更新した。

公式ファイルのバイト列は変更しない。再取得は以下で行う。

```sh
./Scripts/update-mermaid.sh
```

スクリプトは一時ディレクトリで公式アーカイブを取得し、アーカイブとランタイムのSHA-256を
検証してから配置する。バージョンとハッシュは同梱の `Mermaid/version.json` にも記録する。
今後更新するときは、バージョンだけでなくハッシュ・互換性・テスト期待値もレビューする。

## 検証内容

- 日本語、強調、リンク、表、インラインコード、HTML改行の解析・属性維持。
- 既存の目次分離、Mermaid分離、コードフェンス、Live Reload、印刷、ウィンドウ配置のMac回帰テスト。
- 実際のWebKitによるflowchart / sequence / class / state / ER / mindmapのSVG生成。
- ライト・ダーク、80%・160%の文字サイズ、dagre/classic設定の維持。
- 不正な図のソース付きエラー表示、リンク除去、外部fetch拒否、HTTP(S)リソース未取得。
- 同梱Mermaidのバージョン・SHA-256検証。
- アプリホストのInfo.plistが1.3 / build 17であることを確認するXcodeテスト。
- iPhone・iPadで目次操作、文字サイズの変更・再起動後保持・標準へリセット。

### 実行環境と結果

Xcode 27.1、macOS 27.0.1（Apple Silicon）、macOS 27.0 SDK / iOS 27.1 SDKを使用。
以下は1.3 / build 17で実行した最終結果である。

| 検証 | 結果 |
| --- | --- |
| SwiftPM単体・WebKit回帰テスト | 25件成功 |
| macOSアプリ1.3のXcodeテスト | 26件成功 |
| iPhone 17 Pro / iOS 26.5 Simulator | 最終単体12件・UI2件成功。文書・設定画面も目視確認 |
| iPad Pro 13-inch (M5) / iOS 26.5 Simulator | 単体12件・UI2件成功。目次との横並び・図・設定画面も目視確認 |
| 実機向けReleaseコンパイル | arm64、iOS 27.1 SDK、署名なしで成功 |
| ローカルMacアプリ1.3 | ビルド、署名・バージョン・同梱リソース検証成功 |
| 更新スクリプト・日英App Store原稿 | ハッシュ検証・再取得・原稿文字数検査成功 |

テスト記録は `.build/results/*1.3*.xcresult`、画面確認用の画像は `.build/qa/v1.3/` に保存する。
これらはローカル検証用でGit管理対象外。SwiftPMのテスト実行ホストは通常のテストバイナリなので
アプリのInfo.plist検証はXcodeのアプリホストで行い、UIテストホストも1.3 / build 17でビルドする。

### リリース前に残る確認

実機Files/iCloud Drive、iOS 18での実行、配布署名付きアーカイブ、App Store検証・審査提出は別工程。
今回のシミュレーター検証や署名なしコンパイルで、実機動作・審査承認まで保証するものではない。
シミュレーターのOSビルド番号に関するXcode診断、WebKitプロセス終了時のシステムログ、
未使用のAppIntentsに関するメタデータ抽出警告は記録されているが、テスト失敗・ビルド失敗ではない。

## 一次資料

- [Textual 0.5.0](https://github.com/gonzalezreal/textual/releases/tag/0.5.0)
- [TextualのFoundationパーサー実装](https://github.com/gonzalezreal/textual/blob/0.5.0/Sources/Textual/MarkdownParser/AttributedStringMarkdownParser.swift)
- [SwiftUIMath 0.1.0](https://github.com/gonzalezreal/swiftui-math/releases/tag/0.1.0)
- [ConcurrencyExtras 1.4.3](https://github.com/pointfreeco/swift-concurrency-extras/releases/tag/1.4.3)
- [Mermaid 12.2.0](https://github.com/mermaid-js/mermaid/releases/tag/mermaid@12.2.0)
- [Mermaid 12.0.0の破壊的変更と移行方法](https://github.com/mermaid-js/mermaid/releases/tag/mermaid@12.0.0)
- [Prism 1.30.0](https://github.com/PrismJS/prism/releases/tag/v1.30.0)
