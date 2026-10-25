# 文書案内 — Ayami 1.4

現行ソースは1.4（19）。利用方法は既存の英語公開ページ、開発・検証・判断記録は日本語Markdownを基本とする。
機能説明、実装、検証結果を分け、重複する表や手順では正本へリンクする。

## 現行文書

| 読者・目的 | 正本 |
| --- | --- |
| 機能・対応OS・ビルドとテストの入口 | [README](../README.md) |
| 利用方法・制限・問い合わせ | [Support](support.md) |
| 利用者向け紹介 | [公開サイト](index.md) |
| データの扱い・端末内AI | [Privacy Policy](privacy.md) |
| アーキテクチャと設計判断 | [設計](../DESIGN.md) |
| 実装・設定・プラットフォーム境界 | [実装仕様](ayami-implementation.md) |
| 成功・失敗・未確認の範囲 | [1.4検証記録](validation-1.4.md) |
| バージョン変更・公開資産 | [1.4リリースノート](releases/1.4.md) |
| 固定依存とライセンス | [1.3依存監査（1.4も同じ固定版）](dependency-audit-1.3.md)、[第三者通知](../THIRD_PARTY_NOTICES.md) |
| ストア原稿・公開情報の管理 | [AppStore](../AppStore/README.md) |
| 配布画像の管理 | [スクリーンショット仕様](../AppStore/Screenshots/README.md) |
| 配布・GitHub Releaseの再現と検証 | [公開チェックリスト](../AppStore/release-checklist.md) |

## 履歴・判断記録

- [1.3リリースノート](releases/1.3.md)と[1.3 Duo・回帰検証](iphone-duo-validation-1.3.md)は当時の仕様・結果。
  1.3で成功した操作を、1.4の新規画面でも再検証済みとは扱わない。
- [構成変更の記録](repository-rename.md)は改名時の配置・互換識別子。
- [名称・アイコン](app-name-plan.md)は採用したブランドの判断。
- [初期iOS計画との差分](ios-ipados-font-size-implementation-plan.md)は当時の選択。

旧URL・ファイル名は参照互換性のため維持するが、過去仕様を現行手順として案内しない。
App Store Connectの審査状態、連絡先、証明書、提出記録はGit管理外の`AppStore/private/`へ分離する。
GitHubのソース公開とストアでの提供状況は区別する。
