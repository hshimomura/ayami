# 文書案内 — Ayami 1.3

文書ごとの役割を以下に分けます。同じ仕様やテスト結果は、なるべく正本を参照します。
利用方法は英語の既存公開ページ、開発・判断記録は日本語 Markdown を基本とします。

| 読者・目的 | 正本 |
| --- | --- |
| 機能・対応 OS・ビルドとテストの入口 | [README](../README.md) |
| 利用方法・制限・問い合わせ | [Support](support.md) |
| 利用者向け紹介 | [公開サイト](index.md) |
| データの扱い | [Privacy Policy](privacy.md) |
| 現行アーキテクチャ | [設計](../DESIGN.md) |
| 共有実装・設定・プラットフォーム境界 | [実装仕様](ayami-implementation.md) |
| Markdown 解析・依存・ライセンス監査 | [1.3 依存監査](dependency-audit-1.3.md)、[第三者通知](../THIRD_PARTY_NOTICES.md) |
| 1.3（18）のテスト結果と限界 | [Duo・回帰検証](iphone-duo-validation-1.3.md) |
| 新旧識別子・ソース配置 | [構成変更の記録](repository-rename.md) |
| 名称とアイコンの決定 | [名称の決定記録](app-name-plan.md) |
| 初期の iOS 案から採用仕様への変更 | [計画との差分](ios-ipados-font-size-implementation-plan.md) |
| ストア原稿・公開情報の管理 | [AppStore](../AppStore/README.md) |
| 配布用画像 | [スクリーンショット仕様](../AppStore/Screenshots/README.md) |
| 配布物と GitHub Release の再現・検証 | [公開チェックリスト](../AppStore/release-checklist.md) |
| バージョンごとの変更点 | [1.3 リリースノート](releases/1.3.md) |

`*-plan.md` の URL は既存参照を保つため維持しますが、未採用案を現行手順としては案内しません。
App Store Connect の審査状態、連絡先、証明書、提出記録は公開文書へ載せず、
Git 管理外の `AppStore/private/` に分離します。GitHub Release とストアでの提供状況も区別します。
