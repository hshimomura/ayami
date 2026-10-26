# iPhone Duo 掲載用スクリーンショット

日本語・英語各5枚、計10枚。1.5（21）の製品ターゲットをiOS 27.1のiPhone Duoシミュレーターへ
インストールして撮影した。UIテスト用ホストや私的な文書は使用していない。

| ファイル | 内容 | 折りたたみ状態 | 実寸 | 画像（ローカル素材） |
| --- | --- | --- | --- | --- |
| `01-inner-reading.jpg` | 設計レビューの本文・Mermaid・表 | 開く、内側、縦向き | 2007×2853 | [日本語](ja/01-inner-reading.jpg) / [English](en-US/01-inner-reading.jpg) |
| `02-inner-mark.jpg` | ピンクの一時マークと件数 | 開く、内側、縦向き | 2007×2853 | [日本語](ja/02-inner-mark.jpg) / [English](en-US/02-inner-mark.jpg) |
| `03-inner-find.jpg` | 検索語・一致件数・本文と表の一致箇所 | 開く、内側、縦向き | 2007×2853 | [日本語](ja/03-inner-find.jpg) / [English](en-US/03-inner-find.jpg) |
| `04-inner-settings.jpg` | 文字サイズ設定とプレビュー | 開く、内側、縦向き | 2007×2853 | [日本語](ja/04-inner-settings.jpg) / [English](en-US/04-inner-settings.jpg) |
| `05-outer-reading.jpg` | 外側での閲覧。日本語は処理の流れ、英語は文書先頭 | 閉じる、外側、縦向き | 1398×2034 | [日本語](ja/05-outer-reading.jpg) / [English](en-US/05-outer-reading.jpg) |

各ファイルは`ja/`と`en-US/`に置く。元文書は
`Sources/Ayami/Resources/Reader/Sample/README.md`と`README-en.md`。
関連資料・画像を含む公開サンプル全体を、撮影端末のアプリ保存領域へコピーして文書ブラウザーから開く。
表示設定は100%。検索語は日本語が「リクエスト」（1 / 3）、英語が`request`（1 / 5）。
マークはUI操作で付けた一時的な状態で、元Markdownは変更していない。

`xcrun simctl io <device> screenshot --display=3 --type=jpeg <path>`で内側、
`--display=1`で外側を保存する。撮影前にDevice Hubで端末の開閉・物理回転を操作し、
実際に読みやすい向きへレイアウトが切り替わったことを確認する。
両画面で目次を閉じ、本文の幅を確保した。ステータスの時刻は9:41。

画像は不透明JPEG。画面の内容・比率・寸法を加工していない。
Mermaidの描画、ロケール、検索結果、UIとの重なり、個人情報の有無を目視確認し、全画像の実寸を検証した。
ファイルごとの寸法・サイズ・SHA-256は`manifest.json`で確認できる。

掲載先はApp Asset Libraryの`APP_SCREENSHOT`／`IPHONE_DUO_PROFILE`。
素材のアップロードだけではApp Storeに公開されない。
1.5の申請対象ローカライズに掲載枠を作成し、画像の処理完了と順序を確認して提出する。
画像ID・API応答・処理状態は`AppStore/private/`に記録し、Gitへ含めない。
