# iPhone Duo 対応確認 — 1.3（18）

## 対象と環境

2026-10-25 に、Xcode 27.1（27A9275）の公式 iOS 27.1（24A94425）
シミュレーターを使い、1.3（18）を検証しました。実機検証ではありません。
通常の iPhone と iPad は iOS/iPadOS 26.5 シミュレーターでも回帰確認しました。

## 修正内容

DocumentGroup が所有するナビゲーションの内側に NavigationSplitView を
重ねると、Duo の画面切り替えで文書バーが二重表示されました。
iOS の regular 幅では目次と本文を HStack で並べ、ナビゲーションを
DocumentGroup に一本化しました。macOS の NavigationSplitView は維持しています。

compact 幅では目次シート、regular 幅では表示を切り替えられる目次サイドバーを
使います。端末名や `.phone` 判定ではなく、実際のサイズクラスに従います。
設定画面では iOS にない印刷の説明を除き、日本語プレビューも追加しました。

## 結果

| 対象 | 自動テスト | 結果 |
| --- | --- | --- |
| Swift Package | 25 件 | 成功 |
| macOS | 26 件 | 成功 |
| iPhone 17 Pro | 単体 12 件、UI 3 件 | 成功。最終 UI 3 件も再実行して成功 |
| iPad Pro 13 インチ（M5） | 単体 12 件、UI 3 件 | 成功。最終 UI 3 件も再実行して成功 |
| Duo 外側 | 単体 12 件、UI 3 件 | 成功 |
| Duo 内側 | 単体 12 件、UI 3 件 | 成功。最終 UI 3 件も再実行して成功 |

UI テストは共有 PreviewView の専用ホストで、文字サイズの保持・リセット、
目次の選択、regular 幅でのサイドバー表示切り替え、物理回転後の設定操作を確認します。
ホストにも製品と同じ回転許可を設定しています。

製品ターゲットでも Files から公開サンプルを開き、外側から内側への展開、
閉じる操作、再展開、回転、目次の表示切り替え、設定、ローカル Mermaid 描画を
確認しました。文書は開閉後も保持され、ナビゲーションの重複は解消しています。

## 検証上の注意

- Duo 内側では物理的な端末の向きと interface orientation の扱いが異なります。
  「回転したらスクリーンショットが横長になる」という固定アスペクト比の判定は使いません。
  回転後の読み取り・設定ボタンの操作可能性と、実画面の配置を確認します。
- シミュレーターの開閉中には一時的な黒画面や直前のフレームが見えることがあります。
  遷移終了後、対象 display を明示したネイティブ画像でも確認します。
- 実機のヒンジ、実際の性能・メモリー、iCloud/他社ファイルプロバイダーの連携は
  シミュレーターだけでは保証できません。配布後の不具合確認とは別に実機で追試できます。
- テスト結果と画像は `.build/results/`、`.build/qa/` に置き、Git には含めません。

## 参照

- [Apple: Prepare your app for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/)
- [Apple: Adapt your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)
- [Apple: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)

App Store Connect の下書き・審査・アカウントの状態は本書に記録しません。
