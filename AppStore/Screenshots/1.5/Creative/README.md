# Header and Search Results用画像

日本語・英語のUniversal Creative Asset。各言語1枚を、iOS/iPadOS 27以降の
プロダクトページHeaderとSearch Resultsの両方へ配置する。Macの掲載枠は対象外。

- 5244×2950、不透明のRGB PNG。アルファチャンネルなし。
- 日本語: 「読むことに、集中できる。」、英語: 「Quiet Markdown reading.」。
- 既存アイコンと、製品ターゲットで撮影した公開技術文書サンプルのDuo画面を使用。
- アイコン・本文を生成AIで描き直さず、ネイティブ描画によって背景・文字と組み合わせる。
- 主要要素を中央へ集め、21:9のHeaderと3:2のSearch Resultsの切り抜きでも残る構成とする。
- バージョン番号・価格・URL・受賞表現は画像に入れない。

再生成はリポジトリルートで行う。

```sh
swift -module-cache-path .build/creative-module-cache Scripts/render-app-store-creative.swift
```

各言語の`universal-header-search.png`が出力される。画像はGit管理外。
寸法・ファイルサイズ・SHA-256は`manifest.json`へ記録する。
APIへは`CREATIVE_ASSETS`として登録し、`DEFAULT_PROFILE`の
`PRODUCT_PAGE_HEADER_ASSET`と`APP_STORE_SEARCH_RESULTS_ASSET`へ配置する。
保管だけでは掲載されない。掲載枠と審査対象への関連付けを独立したGETで確認する。

Appleの[画像仕様](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications)と
[作成ガイド](https://developer.apple.com/app-store/asset-best-practices/)を参照。
