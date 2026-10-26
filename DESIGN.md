# Ayami 1.5 開発版 設計

## 方針

Apple silicon搭載Mac（macOS 26+）、iPhone・iPad（iOS/iPadOS 18+）の
読み取り専用Markdownビューアーとする。編集、Electron、データベース、アカウント、
独自の同期・文書アップロードサービスは追加しない。

1.5では文書内検索、一時マーク、相対ファイル、コードコピー、図の拡大、導入ガイドを追加する。
文書リンクはMacでタブを既定とし、ウィンドウへ切り替え可能にする。HTMLは許可した要素を表示し、
その他のテキスト・JSON・ソースコードは原文を保持して開く。
実装と今回の検証範囲は[1.5検証記録](docs/validation-1.5.md)を参照する。
1.4では全プラットフォームの印刷・PDF、MacのFinder Quick Look、端末内AIの試作を追加した。
利用者向け機能は[README](README.md)、ファイル・設定・制限の詳細は
[実装仕様](docs/ayami-implementation.md)、成功・失敗の証跡は[検証記録](docs/validation-1.4.md)へ分ける。

## 読む・出力する・要点を生成する

```text
Finder / File menu / Files
            |
   DocumentGroup(viewing:)
            |
    MarkdownDocument -> PreviewDocumentModel
            |            Macのみ外部変更を約400ms間隔で監視
            |
            +-> 読書: ReaderSession / ReaderWebView（非永続、文書ごと）
            |          +-> 同梱markdown-it / Prism / Mermaid
            |          +-> 選択・検索・一時マーク・段落の位置保持
            |          +-> DocumentResourcePolicy（相対画像と許可フォルダー）
            |
            +-> 出力: OutputDocument
            |          +-> CoreText / CoreGraphics（本文・表・改ページ）
            |          +-> MermaidPDFRenderer（SVG -> ベクターPDF）
            |                       |
            |                GeneratedPDF
            |                       +-> PDFKitプレビュー / 保存 / OS別印刷
            |
            +-> 明示操作のみ: DocumentSummary -> 端末内Foundation Models

Finder Quick Look -> PreviewProvider -> OutputDocument -> 連続HTML + Mermaid SVG添付 -> QLPreviewReply
```

読書画面と出力は別のレンダラーとする。本文の読みやすさとOS標準の文書操作を維持しつつ、
出力では選択可能な文字とベクター図を生成する。画面全体のスクリーンショットや
HTML/CSSの完全再現には依存しない。出力の対応記法・上限は実装仕様に集約する。

Quick Lookは表示専用の小さな拡張とし、アプリの起動・設定・AIを必要としない。
本文と表を連続HTMLで返し、Mermaidはローカル生成したSVGを添付する。
改ページ・用紙サイズ・ページ番号は印刷とPDF保存の出力フローに限定する。
選択とスクロールはOSへ任せる。バンドル識別子は既存アプリと分ける。

## プラットフォーム境界

- 共通: 文書、読書画面、目次、文字倍率、Mermaid、PDF生成・プレビュー・保存、任意のAI要点。
- Mac専用: アプリ入口、File/View/Windowメニュー、タブ、左右配置、外部ファイル監視、
  ウィンドウサイズ復元、`NSPrintOperation`、Finder Quick Look。
- iOS専用: Filesの文書ブラウザー、`UIViewRepresentable`、`UIPrintInteractionController`。
  iPadの複数ウィンドウはシステムへ任せ、Mac Catalystへ置き換えない。

Macの目次は`NavigationSplitView`。iOSはDocumentGroupにナビゲーションを一本化し、
compact幅は目次シート、regular幅はHStack内に目次と本文を並べる。
regular幅をiPadと同一視せず、Duoにも同じ配置を適用する。

## 端末内AIの境界

`SystemLanguageModel.default`のみを使い、利用者が生成を開始した文書だけを処理する。
モデルにツールやファイル書き込み権限を渡さず、文書中の命令は信頼しない参照資料として扱う。
Private Cloud Computeや他社サービスへのフォールバックは持たない。

AIはOS 26+で利用状態を確認する。iOSの最低対応を18に保つためFoundationModelsを弱リンクし、
実行箇所をavailabilityで制御する。利用不可・生成失敗・取消を読書やPDFの失敗へ波及させない。
試作の表示と原文照合の注意を維持し、全端末での生成成功や要約精度を保証しない。

## 文書保護とプライバシー

文字倍率とMacのリンク表示先は端末内のUserDefaultsに保存し、元文書や独立した出力レイアウトを書き換えない。
HTMLはDOMPurifyと要素・属性・CSSの許可リストで処理し、文書のスクリプトは実行しない。
文書内のIDと操作用属性を読書UIから分離し、ローカルファイルの境界検証を通して参照する。
PDFは新しい出力先へ保存する。Macのユーザー選択read/write権限はその保存先に使い、
Quick Lookはユーザー選択ファイルのread-only権限とする。

MermaidのHTML/JavaScriptは同梱する。CSP、外部ナビゲーション拒否、SVG内リンク除去、
タイムアウトを組み合わせ、Macの`network.client`権限はローカルWebKitヘルパーに使う。
アプリによる文書・利用情報の収集は追加しない。利用者向けの説明は
[プライバシーポリシー](docs/privacy.md)を正本とする。

## 検証・今後の範囲

1.4の成功結果と未検証項目は[検証記録](docs/validation-1.4.md)に集約する。
1.5の相対画像、Find、1MiBの長文、レイアウト変更時のマーク保持を検証する。
VoiceOverの全操作、旧バージョンのOS、実機は追加検証が必要。
画像の追加対応はアプリの閲覧画面を対象とし、Quick LookとPDFへは広げていない。
Intel対応は廃止し、実装済みの印刷・PDF・Quick Lookを将来計画として重複掲載しない。
Developer IDによる直接配布・notarizationはApp Store配布とは別工程とする。
