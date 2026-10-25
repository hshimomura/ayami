# Ayamiへのリポジトリ構成統一

## 変更範囲

2026年10月25日、バージョン1.3 / build 17の検証済み実装をコミットした後、
リポジトリと開発用識別子をAyami基準に統一した。これは改名時の履歴であり、
当時の基準は [1.3（18）](releases/1.3.md)。以下の配置表は改名時点の履歴であり、
現行1.4のビルド手順は [README](../README.md) を参照する。

| 対象 | 新しい名称・配置 |
| --- | --- |
| GitHubリポジトリ | `hshimomura/ayami` |
| ローカルフォルダー | `ayami/`（旧 `MDPreview/` は残さない） |
| Xcodeプロジェクト | `Ayami.xcodeproj` |
| Macスキーム・ターゲット | `Ayami` |
| iOSスキーム・ターゲット | `AyamiIOS` |
| Swift Package・共通モジュール | `Ayami` |
| 共通ソース・Macの入口 | `Sources/Ayami/`、`AyamiMacApp.swift` |
| iOSの入口 | `Sources/AyamiIOS/AyamiApp.swift` |
| 共通テスト | `Tests/AyamiTests/` |
| App Sandbox設定 | `Packaging/Ayami.entitlements` |
| ローカル成果物 | `dist/Ayami.app` |
| ストア用Macアーカイブ | `dist/Ayami-AppStore.xcarchive` |
| ストア用iOSアーカイブ | `dist/Ayami-iOS-AppStore.xcarchive` |
| 公開サイト | `https://hshimomura.github.io/ayami/` |

1.3ではMac固有の印刷・ウィンドウ制御をiOSターゲットから除外した。
共有ファイルを大規模に分類し直す変更は行わない。
1.4では印刷・PDFを共有ソースへ置き換え、Mac Quick Look拡張を追加した。
ローカルMacは `dist/validation-1.4/Ayami.app`、ストア配布物は `dist/1.4/` に分ける。

## 維持した識別子

アプリのBundle ID `io.github.hshimomura.MDViewer` は既存のApp Store配布を引き継ぐため維持する。
テスト用Bundle IDと既存のウィンドウ識別子も維持する。`LICENSE` の過去の著作権表示も改変しない。
コード・文書に残る旧名称は、これらの互換性・履歴のためのものに限定する。
改名時にはバージョン・依存を変更せず、その後の Duo 修正でビルド18へ更新した。

## Gitと公開サイト

`origin` は `git@github.com:hshimomura/ayami.git` とする。
GitHub Pagesは `main` ブランチの `/docs` を引き続き使用し、Jekyllの `baseurl` を `/ayami` に変更する。
README、サポート、プライバシー、ストア用原稿のリンクを新URLへ揃える。
公開文書とストア原稿は新 URL を使用する。旧 URL 用の互換サイトや旧ローカルパスへの
シンボリックリンクは作らない。古いブックマークやローカル設定は新しい名前へ開き直す。

## リソースと検証

1.3のローカルMacビルドは新しい一時領域にappを組み立て、使用する3つのリソースbundleだけを同梱した。
旧モジュールのリソースが残らないようにし、既存のローカルappは `.build/previous-local-app.*` に退避する。

ビルド・テストのコマンドは [README](../README.md)、
改名後のビルド18の結果は [1.3検証記録](iphone-duo-validation-1.3.md)、
現行版は [1.4検証記録](validation-1.4.md) を参照する。

公開済みバージョンのストアURLは編集できないため、次期版での反映までは旧URLの互換性に注意する。
ストアの審査状態など非公開の運用記録は `AppStore/private/` に保存し、コミットしない。
