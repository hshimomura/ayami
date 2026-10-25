# スクリーンショット仕様

1.3 の画像は `1.3/<platform>/<locale>/` に保存します。
`locale` は `ja` と `en-US`、公開用サンプルは `AppStore/Samples/` です。
画像は Git 管理外です。個人の文書、連絡先、審査画面をストア画像へ含めません。

| platform | 撮影内容 | 使用する画像寸法 |
| --- | --- | --- |
| macOS | 目次・本文・Mermaid | 2560 × 1600 |
| iPhone | 閲覧、文字サイズ設定 | 1320 × 2868 |
| iPad | 閲覧、文字サイズ設定 | 2064 × 2752 |
| iPhoneDuo | 内側の閲覧・設定、外側の閲覧（追加検証用） | 内側 2007 × 2853、外側 1398 × 2034。横向きも可 |

`01-reading.jpg` を先頭にし、iPhone/iPad の `02-settings.jpg` を続けます。
Mac の設定シート単体は指定の縦横比にならないため、登録画像には使いません。

## 撮影と確認

- 実際の製品ターゲットを起動して公開用サンプルを開きます。UI テスト用ホストの画像は登録しません。
- シミュレーターは `xcrun simctl io <device> screenshot --type=jpeg <path>` で撮影します。Duo は `--display=1` が外側、`--display=3` が内側です。
- Mac は撮影専用の起動引数 `-documentWindowContentWidth 1280 -documentWindowContentHeight 800` でウィンドウを調整し、実画面を撮影します。取得後に寸法を検証します。
- JPEG は不透明とし、実画面の内容や比率を加工しません。Mac の PNG は寸法を変えず JPEG に符号化できます。
- Mermaid の描画完了、表示言語、文字切れ、ツールバーの重複、個人情報がないことを目視確認します。
- Media Manager では iPhone の大画面枠と iPad 13 インチ枠を指定します。ほかのサイズへの継承と、各言語の独自画像を確認します。
- 過去版の画像は Asset Library から再選択できます。差し替え時はバージョン側の参照だけを外し、ライブラリーから恒久削除しません。

Apple の受け入れ寸法は変更されるため、登録時に
[スクリーンショット仕様](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
と App Store Connect の表示を再確認してください。
