# 名称・アイコンの決定記録

1.3 では「あやみ / Ayami」を採用する。以前の候補名・旧版ビルド番号に基づく
提出計画は廃止した。ファイル名は既存リンクを保つため変更しない。

| 用途 | 採用表記 |
| --- | --- |
| 日本語 App Store 名 | `あやみ — Markdownビューア` |
| 英語 App Store 名 | `Ayami: Markdown Reader` |
| インストール後の名称 | 日本語 `あやみ`、その他 `Ayami` |
| 日本語サブタイトル | `記法をほどいて、ことばを読む` |
| 英語サブタイトル | `Quiet Markdown reading` |

用途を伝える説明と短い固有名を分け、柔らかい日本語名と Markdown 閲覧用途を両立する。
候補調査だけで名称の利用可能性や商標を保証するものではない。

## アイコン

明るい生成り・杏色の背景、白い文書、テラコッタ色の見台を採用した。
青い窓枠、封筒、鉛筆、ダウンロード矢印は使わず、編集アプリや手紙との誤認を避ける。

- マスター: `Resources/Ayami-Icon-Master.png`
- 再生成: `./Scripts/build-icon.sh`
- [生成プロンプト](ayami-icon-prompt.txt)

現在は完成済みの不透明なラスター画像であり、Icon Composer のレイヤー付き `.icon` ではない。
Liquid Glass のレイヤー化は現行仕様に含めない。

Bundle ID は既存の `io.github.hshimomura.MDViewer` を維持する。
GitHub 名やソースの名称変更は [リポジトリ構成](repository-rename.md)、
製品実装は [実装仕様](ayami-implementation.md)、ストア文字列の正本は
[AppStore/metadata](../AppStore/README.md) を参照する。
