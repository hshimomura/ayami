# アプリ名称の検討・変更計画

> 以下は候補検討時の記録である。現在の採用名は「あやみ / Ayami」。
> 日本語名は `あやみ — Markdownビューア`、英語名は `Ayami: Markdown Reader` とする。
> 改名の実装と検証は [あやみ実装計画](ayami-implementation.md) を正本とする。
> App Store Connectでの保存・審査承認は別途確認する。

## 結論

第一候補は **「よみまど / Yomimado」** とする。

| ローカライズ | App Store名 | サブタイトル | インストール後の表示名 |
| --- | --- | --- | --- |
| 日本語 | `よみまど：Markdownビューア` | `Markdownを静かに読む` | `よみまど` |
| 英語（米国） | `Yomimado: Markdown Reader` | `Quiet Markdown reading` | `Yomimado` |

「よみまど」は「読む」と「窓」を組み合わせた造語である。ひらがなの柔らかさを持ち、
現行コンセプトの「Reading Window」を引き継ぐ。用途は名前の後半に
`Markdownビューア` / `Markdown Reader` を置いて明確にする。

## Appleの命名条件

- App Store名は2文字以上30文字以内。
- サブタイトルは30文字以内。
- 名前は短く、覚えやすく、綴りやすく、用途を想起できることが推奨される。
- 一般名だけにせず、既存アプリと区別できる名前にする。
- アプリ名はローカライズできる。
- 現在のように新バージョンが編集可能な間は、App Review提出前に変更できる。

`よみまど：Markdownビューア` と `Yomimado: Markdown Reader` はいずれも
30文字以内に収まる。固有部分と機能説明を分けることで、独自性と検索性を両立する。

## 候補調査

2026年10月25日時点で、公開App Store検索と一般Web検索を使って完全一致と
近い製品を確認した。公開検索で一致しないことは、App Store Connectでの名称確保や
商標上の利用可能性を保証しない。最終確認はApp Store Connectでの保存と、必要に応じた
J-PlatPat等の商標調査で行う。

| 候補 | 分かりやすさ | 柔らかさ | 独自性 | 判定 |
| --- | ---: | ---: | ---: | --- |
| `よみまど / Yomimado` | 4 | 5 | 5 | **第一候補**。公開App Store検索で完全一致なし |
| `Markdown日和` | 5 | 5 | 4 | 日本語では魅力的。英語圏で読みと意味が伝わりにくい |
| `Markdownしおり` | 5 | 5 | 3 | 用途は明確だが、既存の文書リーダー `Shiori` と印象が近い |
| `ことのはMD` | 3 | 5 | 3 | 柔らかいが、Markdownビューアであることが弱い |
| `Stillmark` | 2 | 3 | 4 | 落ち着きはあるが、日本語らしさと用途説明が弱い |
| `Markpane` | 5 | 3 | 1 | **不採用**。同名のMarkdownアプリがMac App Storeに存在する |
| `Folio / Folio MD` | 3 | 3 | 1 | **不採用**。複数の既存Markdown製品が使用している |

`ふみまど` は造語としては柔らかいが、「踏み惑う」を連想できるため採用しない。

## 推奨するブランド表現

### 名前

- 固有名: `よみまど` / `Yomimado`
- 発音: よ・み・ま・ど
- 意味: Markdown文書を開き、落ち着いて読むための窓
- 表記: 日本語ではひらがな、英語では先頭のみ大文字

名称だけを `よみまど` にすると検索時に用途が伝わりにくい。そのためApp Store名では
`Markdownビューア` を付け、Dock、ホーム画面、メニューバーでは短い固有名だけを使う。

### 紹介文の核

> Markdownを、静かな窓で読む。

英語では次を使う。

> A quiet window for reading Markdown.

### アイコンとの対応

コンサル案の「文書を読むための窓」は `よみまど` と相性がよい。次の方針で進める。

- 深い青緑の背景に、薄いガラス質の抽象的なフレームを置く。
- 中央に余白の広い白い文書を置く。
- 文書内は太い見出し線1本と本文線2〜3本に絞る。
- Markdownの手掛かりには、小さな `#` と見出し線を使う。
- `M＋下向き矢印` はダウンロード操作に見える可能性があるため使わない。
- 鉛筆、カーソル、コード記号を入れず、編集アプリとの誤認を避ける。
- Liquid Glassは外周フレームの仕上げに限定し、形状だけでも識別できるようにする。

## 変更範囲

App Store上の名前だけを変えると、インストール後に `MD Viewer` と表示され続ける。
名称と体験を一致させるため、バイナリ、メタデータ、ドキュメント、スクリーンショットを
同じリリースで変更する。

### 変更するもの

- `Packaging/Info.plist`
  - `CFBundleDisplayName`
  - `CFBundleName`
- `project.yml`
  - `PRODUCT_NAME`
  - テストホストと生成物のパス
- `Scripts/verify-app.sh`
- `Scripts/verify-app-store-export.sh`
- App Storeの日本語・英語の名前、サブタイトル、説明、レビュー情報
- `README.md`、`AppStore/README.md`、`docs/` の名称表記
- アプリ名が写るスクリーンショット
- アイコンと各プラットフォームのAppIcon assets

### 変更しないもの

- Bundle ID `io.github.hshimomura.MDViewer`
- App Store ConnectのApple IDとSKU
- Gitリポジトリ名 `MDPreview`
- Swiftの内部モジュール名

Bundle IDは最初のビルドをアップロードした後に変更できない。ユーザーには通常見えないため、
既存値を維持する。

## リリース手順

現在の `1.2 (15)` はApp Store Connectで `Prepare for Submission` にある。
名称変更を1.2へ含める場合は、提出前に次の順序で実施する。

1. `よみまど / Yomimado` を最終決定する。
2. App Store Connectの日本語・英語名が保存可能か確認する。
3. バイナリと文書内のユーザー向け名称を変更する。
4. 新アイコンをMac・iPhone・iPad向けに作成する。
5. macOS版を `1.2 (16)` として再ビルドし、テストする。
6. 名前とアイコンを反映したスクリーンショットを再作成する。
7. App Store Connectでビルド15を外し、ビルド16を選択する。
8. 日本語・英語メタデータとApp Review notesを更新する。
9. App Reviewへ提出する。

iOS/iPadOS版は既存レコードへiOSプラットフォームを追加し、同じ
`よみまど / Yomimado` ブランドを使う。プラットフォームごとに別名を付けない。

## 判断ゲート

実装前に次の3点を確認する。

1. `よみまど / Yomimado` を正式名として採用するか。
2. 名称変更を未提出のmacOS 1.2へ含めるか、次版へ分けるか。
3. アイコンを同時に刷新するか、まず名前だけを変更するか。

推奨は、**macOS 1.2の提出を一度止め、名前とアイコンを揃えたビルド16へ差し替えてから
提出する**進め方である。iPhone・iPad版を追加する前にブランドを確定でき、
3プラットフォームで同じ名前とアイコンを最初から使える。

## 参考資料

- [Apple: App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
- [Apple: Creating Your Product Page](https://developer.apple.com/app-store/product-page/)
- [Apple: App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple: Localize app information](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information/)
- [Markpane – Markdown Workspace](https://apps.apple.com/us/app/markpane-markdown-workspace/id6781085194?mt=12)
- [Folio MD](https://foliomd.app/)
