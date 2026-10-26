# スクリーンショット仕様

画像は `<version>/<platform>/<locale>/` に保存します。既存の1.3閲覧・設定画像は
同じ機能を表す範囲で1.4へ継承できます。新しい印刷・AI画面の画像と混同せず、
1.4を撮り直す場合は `1.4/<platform>/<locale>/` を使います。
`locale` は `ja` と `en-US`、公開用サンプルは `AppStore/Samples/` です。
画像は Git 管理外です。個人の文書、連絡先、審査画面をストア画像へ含めません。

| platform | 撮影内容 | 使用する画像寸法 |
| --- | --- | --- |
| macOS | 目次・本文・Mermaid | 2560 × 1600 |
| iPhone | 閲覧、文字サイズ設定 | 1320 × 2868 |
| iPad | 閲覧、文字サイズ設定 | 2064 × 2752 |
| iPhoneDuo | 内側の閲覧・マーク・検索・設定、外側の閲覧 | 内側 2007 × 2853、外側 1398 × 2034。横向きも可 |

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

上表は1.3で使用した寸法の記録です。Appleの受け入れ寸法は変更されるため、登録時に
[スクリーンショット仕様](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
と App Store Connect の表示を再確認してください。

## 1.5 開発版の素材

`1.5/macOS/ja/`と`1.5/macOS/en-US/`に、製品ターゲットと同梱の公開サンプルで
蛍光ペン、検索、図の拡大、相対画像・リンク、コードコピーの画面を用意する。
これらの新機能画面は撮り直しと選定を始めた段階であり、掲載枠へは追加しない。
撮影後は寸法・ロケール・元文書・ビルドを[1.5検証記録](../../docs/validation-1.5.md)へ記録する。
`getAXStateAndScreenshot()`の元画像は2560×1600、通常の`getScreenshot()`の返値は
1280×800の場合があるため、ファイルの実寸を確認する。拡大補間は行わない。

### iPhone Duo

`1.5/iPhoneDuo/ja/`と`1.5/iPhoneDuo/en-US/`に各5枚、計10枚を保存する。
内容・撮影条件は[素材一覧](1.5/iPhoneDuo/README.md)、寸法・ファイルサイズ・SHA-256は
同ディレクトリーの`manifest.json`に記録する。元画像はGit管理外。

App Asset Libraryの参照データAPIで`APP_SCREENSHOT`／`IPHONE_DUO_PROFILE`に
内側・外側の縦横両方向が含まれることを確認した。今回の素材はすべて縦向きの実画面で、
寸法変更や拡大補間は行わない。1.5のローカライズごとの掲載枠へ追加し、画像の処理と順序を確認する。
動画のApp Previewとは別に扱う。

## Quick Look の掲載素材

日英の`06-quicklook.jpg`は1280×800の不透明JPEG。Finder Quick Lookの実画面を使い、
`quicklook-layout.html?locale=ja`または`?locale=en-US`で短い見出しを添えた。
`06-quicklook-source.jpg`に原画を残し、画面内の内容や縦横比は変更していない。
原画は1940×1526で、掲載画像では850px幅へ縮小する。拡大補間は行わない。

- 元文書：`AppStore/Samples/QuickLook/ja/通知サービス.md`、`en-US/Notification-Service.md`
- 撮影対象：インストール済み製品アプリに同梱のQuick Look拡張（1.5開発版）。表示に関わるQuick Lookソースは1.4と同じ。
- 画像内の「Open with MarkEdit」は撮影環境の既定エディターを示すFinder標準UI。
- 寸法：App Asset Libraryの`APP_SCREENSHOT`／`MAC_PROFILE`が受け入れる1280×800を使用。
- APIによる保存先：App Asset Libraryの未提出素材。1.4の掲載画像は変更せず、1.5で追加する。

再生成はこのディレクトリーのみをlocalhostで配信し、上記HTMLを1280×800の全ページ画像として撮影する。
画面の描画完了、ロケール、文字切れ、個人情報の有無を確認してからアップロードする。
画像ID・アップロード応答・審査状態の記録は`AppStore/private/`へ保存する。

## Header and Search Results

1.5のiOS/iPadOS向け日英共通画像は[Creative](1.5/Creative/README.md)を参照。
Universal Creative AssetをHeaderとSearch Resultsの両方へ配置する。
スクリーンショットとは独立した掲載枠で、Macは対象外。
