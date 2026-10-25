# APIでの審査申請・差し替え

以下の`APP_ID`などは読み取りAPIの応答で得たIDに置き換える。実際のID、応答、ペイロードは
`AppStore/private/`へ保存する。対象を特定せずに例を実行しない。

## 読み取りと準備

- `GET /v1/apps?filter[bundleId]=...`でアプリを特定する。
- `GET /v1/apps/APP_ID/appStoreVersions?include=build`でプラットフォーム別のバージョンと選択ビルドを取得する。
- `GET /v1/builds?filter[app]=APP_ID&filter[version]=BUILD_NUMBER&include=preReleaseVersion`で新ビルドを確認する。
  `processingState=VALID`に加え、`preReleaseVersion`の版とプラットフォームも照合する。
- `GET /v1/apps/APP_ID/reviewSubmissions`で進行中・下書きの申請を確認する。
- `GET /v1/reviewSubmissions/SUBMISSION_ID/items?include=appStoreVersion`で申請項目を照合する。
  関連IDが必要な場合は`include`を指定する。既定の応答に`relationships`があるとは限らない。

処理中のビルドは完了を待つ。既に公開された版には同じ版のビルド差し替えを行えないため、
新バージョンが必要になった場合はユーザーの指定を確認する。
Mac・iOS両方を対象とする場合は版・ビルド番号を揃え、既存の検証・書き出しスクリプトとも一致させる。

## 取り下げと編集

差し替え対象の申請だけを取り下げる。複数項目が含まれる場合は全項目への影響を先に確認する。

`PATCH /v1/reviewSubmissions/SUBMISSION_ID`

```json
{"data":{"type":"reviewSubmissions","id":"SUBMISSION_ID","attributes":{"canceled":true}}}
```

取り下げは非同期。対象バージョンが編集可能になり、旧申請の取消処理が完了してから次へ進む。

`PATCH /v1/appStoreVersions/VERSION_ID/relationships/build`

```json
{"data":{"type":"builds","id":"BUILD_ID"}}
```

旧ビルドを先に解除する必要はなく、上記の関連更新で新ビルドを指定できる。
メタデータは`appStoreVersionLocalizations`、審査メモは`appStoreReviewDetails`のPATCHを使い、
変更する属性だけを渡す。既存の画像・添付・連絡先・公開設定を保持する。
iOS初回公開など、APIや画面で許可されない`whatsNew`は無理に更新しない。

ペイロードはファイルから渡す。

```sh
python3 .agents/skills/app-store-connect/scripts/asc_api.py PATCH \
  '/v1/appStoreVersions/VERSION_ID/relationships/build' \
  --body-file AppStore/private/select-build.json \
  --output AppStore/private/select-build-response.json
```

## 下書き作成と最終提出

既存の適切な下書きがあれば再利用する。なければプラットフォーム別に作成し、返却IDを直ちに保存する。

`POST /v1/reviewSubmissions`

```json
{"data":{"type":"reviewSubmissions","attributes":{"platform":"MAC_OS"},"relationships":{"app":{"data":{"type":"apps","id":"APP_ID"}}}}}
```

iOSは`platform`を`IOS`とする。

`POST /v1/reviewSubmissionItems`

```json
{"data":{"type":"reviewSubmissionItems","relationships":{"reviewSubmission":{"data":{"type":"reviewSubmissions","id":"SUBMISSION_ID"}},"appStoreVersion":{"data":{"type":"appStoreVersions","id":"VERSION_ID"}}}}}
```

申請項目と選択ビルドをGETで確認し、ユーザーが審査提出まで依頼している場合に最終送信する。

`PATCH /v1/reviewSubmissions/SUBMISSION_ID`

```json
{"data":{"type":"reviewSubmissions","id":"SUBMISSION_ID","attributes":{"submitted":true}}}
```

送信後に独立したGETで、選択ビルド番号、版、プラットフォーム、バージョン状態、申請状態、公開方式を確認する。
`WAITING_FOR_REVIEW`を確認して審査待ちと報告する。審査承認・公開済みとは区別する。

## 公式仕様

スキーマや状態遷移で不明点があれば、実行前にAppleの現行仕様を確認する。

- [ビルドの関連付け変更](https://developer.apple.com/documentation/appstoreconnectapi/patch-v1-appstoreversions-_id_-relationships-build)
- [Review submissions](https://developer.apple.com/documentation/appstoreconnectapi/review-submissions)
- [Review submission作成](https://developer.apple.com/documentation/appstoreconnectapi/post-v1-reviewsubmissions)
- [Review submission項目作成](https://developer.apple.com/documentation/appstoreconnectapi/post-v1-reviewsubmissionitems)
- [Review submission変更](https://developer.apple.com/documentation/appstoreconnectapi/patch-v1-reviewsubmissions-_id_)
