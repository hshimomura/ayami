# Ayamiへのリポジトリ構成統一

## 変更範囲

2026年10月25日、バージョン1.3 / build 17の検証済み実装をコミットした後、
リポジトリと開発用識別子をAyami基準に統一した。

| 対象 | 新しい名称・配置 |
| --- | --- |
| GitHubリポジトリ | `hshimomura/ayami` |
| ローカルフォルダー | `/Users/hshimomu/Documents/ayami` |
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
| 公開サイト | `https://hshimomura.github.io/ayami/` |

Mac固有の印刷・ウィンドウ制御は従来どおりiOSターゲットから除外する。
共有ファイルを大規模に分類し直す変更は行わない。

## 維持した識別子

アプリのBundle ID `io.github.hshimomura.MDViewer` は既存のApp Store配布を引き継ぐため維持する。
テスト用Bundle IDと既存のウィンドウ識別子も維持する。`LICENSE` の過去の著作権表示も改変しない。
コード・文書に残る旧名称は、これらの互換性・履歴のためのものに限定する。
マーケティングバージョン1.3、ビルド17、依存ライブラリの採用バージョンは変更しない。

## Gitと公開サイト

`origin` は `git@github.com:hshimomura/ayami.git` とする。
GitHub Pagesは `main` ブランチの `/docs` を引き続き使用し、Jekyllの `baseurl` を `/ayami` に変更する。
README、サポート、プライバシー、ストア用原稿のリンクを新URLへ揃える。
App Store Connectの関連URLは、新サイトが正常に表示されることを確認してから保存する。
この作業ではバイナリのアップロード・審査提出・GitHub Releaseの新規公開は行わない。

## ビルドと検証

```sh
./Scripts/generate-xcode-project.sh
swift test
xcodebuild -project Ayami.xcodeproj -scheme Ayami -destination 'platform=macOS' test
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
xcodebuild -project Ayami.xcodeproj -scheme AyamiIOS \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)' test
./Scripts/build-app.sh
./Scripts/verify-app.sh
```

ローカルMacビルドは新しい一時領域にappを組み立て、使用する3つのリソースbundleだけを同梱する。
旧モジュールのリソースが残らないようにし、既存のローカルappは `.build/previous-local-app.*` に退避する。

構成変更後もバージョン1.3 / build 17で検証した。

| 検証 | 結果 |
| --- | --- |
| SwiftPM | 25件成功 |
| MacアプリのXcodeテスト | 26件成功 |
| iPhone 17 Pro / iOS 26.5 Simulator | 単体12件、UI2件成功 |
| iPad Pro 13-inch (M5) / iOS 26.5 Simulator | 単体12件、UI2件成功 |
| ローカルMacアプリ | ビルド・署名・バージョン・新リソース名の検証成功 |
| 日英ストア原稿 | 文字数制限の検証成功 |

公開済みバージョンのストアURLは編集できないため、次期版での反映までは旧URLの互換性に注意する。
ストアの審査状態など非公開の運用記録は `AppStore/private/` に保存し、コミットしない。
