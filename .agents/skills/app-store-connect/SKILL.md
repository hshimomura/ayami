---
name: app-store-connect
description: AyamiのApp Store Connectでビルド、メタデータ、審査申請・差し替え・状態確認を扱うときに使う。既存認証とREST APIを優先し、署名付きバイナリの作成・アップロードはリポジトリのCLIを使う。
---

# App Store Connect

## 操作経路

- **App Store Connectの確認・変更は原則REST APIで行う。** ブラウザーを開く前に、既存API認証とAPI対応を確認する。
- 認証は環境変数または`~/.env`の`ASC_KEY_ID`、`ASC_ISSUER_ID`、`ASC_KEY_FILEPATH`を使う。ファイルをshellの`source`で実行せず、必要な3項目だけを読む。
- [scripts/asc_api.py](scripts/asc_api.py)でJWTをメモリー内に生成する。APIキー・秘密鍵・JWTを会話、ログ、Gitへ出力しない。Pythonの`cryptography`が必要。実行環境の依存不足とAPI認証の失敗を区別する。
- バイナリは`Scripts/archive-*-app-store.sh`、`Scripts/verify-*-app-store-export.sh`、`Scripts/upload-*-app-store.sh`の既存CLI経路を使う。Mac用は`archive-app-store.sh`、`verify-app-store-export.sh`、`upload-app-store.sh`。
- ブラウザーへの切り替えは、ユーザーの明示指定、公式APIの非対応操作、または既存認証・権限の問題を解決できない場合に限る。理由と必要な画面操作を説明してから切り替える。APIで完了した作業にブラウザー確認やスクリーンショットを必須としない。

## 進め方

1. [AppStore/README.md](../../../AppStore/README.md)と[release-checklist.md](../../../AppStore/release-checklist.md)で対象・公開方針・配布手順を確認する。実行はリポジトリルートから行う。
2. 最初に読み取りAPIでアプリ、プラットフォーム、バージョン、選択ビルド、進行中の申請を特定する。ID・ビルド番号は今回の応答から取得し、以前の申請記録をそのまま使わない。
3. 差し替え・再提出では[references/submission-workflow.md](references/submission-workflow.md)を読む。変更前の状態を保存し、対象ビルドの処理完了と版・プラットフォームの一致を確認してから申請を取り下げる。
4. 変更後は別のGETで選択ビルド、バージョン状態、申請状態を確認する。PATCHやPOSTの成功応答だけで完了としない。

```sh
python3 .agents/skills/app-store-connect/scripts/asc_api.py GET \
  '/v1/apps?filter[bundleId]=io.github.hshimomura.MDViewer&fields[apps]=name,bundleId&limit=1'
```

## 実行範囲と記録

- ユーザーが依頼した申請・差し替えの範囲を実行する。既に認められた操作への再確認を重ねない。アップロードだけの依頼から審査提出を推定しない。
- 公開方式、価格、対象地域、権限、契約を依頼なく変更しない。既存の承認後自動公開などの設定を維持する。
- APIに新しい契約同意・認証・権限付与が必要と分かった場合は、依頼範囲内で進められる準備を済ませ、必要な対応を具体的に伝える。
- 申請状態・識別子・審査メモ・連絡先・API応答はGit管理外の`AppStore/private/`へ保存する。公開メタデータは`AppStore/metadata/`を使う。
- 失敗やタイムアウトの後はGETで実状態を確認する。取り下げ、申請作成、項目追加、最終提出を無条件に再送しない。作成済みIDを保存して重複申請を避ける。
- バージョン変更やストア申請から、GitHubタグの変更・Release公開を推定しない。
