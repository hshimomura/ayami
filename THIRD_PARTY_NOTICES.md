# Third-party notices

Ayami includes the following runtime dependencies. Their complete license
texts are retained in the built application. The location depends on the build:

| Build | License directory |
| --- | --- |
| Xcode macOS app / App Store export | `Contents/Resources/Legal/` |
| Xcode iOS app / App Store export | `Legal/` inside `Ayami.app` |
| Historical 1.3 SwiftPM script build | `Contents/Resources/ThirdPartyLicenses/` |

| Component | Version | License | Source |
| --- | --- | --- | --- |
| Textual | 0.5.0 | MIT | https://github.com/gonzalezreal/textual |
| SwiftUIMath | 0.1.0 | MIT | https://github.com/gonzalezreal/swiftui-math |
| ConcurrencyExtras | 1.4.3 | MIT | https://github.com/pointfreeco/swift-concurrency-extras |
| Prism.js | 1.29.0 (bundled by Textual) | MIT | https://github.com/PrismJS/prism |
| markdown-it | 15.0.3 | MIT | https://github.com/markdown-it/markdown-it |
| DOMPurify | 3.4.17 | Apache-2.0 (selected from dual license) | https://github.com/cure53/DOMPurify |
| Mermaid | 12.2.0 | MIT | https://github.com/mermaid-js/mermaid |

SwiftUIMath includes math fonts under the SIL Open Font License 1.1 and the
GUST Font License. The complete `OFL.txt` and `GUST-FONT-LICENSE.txt` files
are retained inside the distributed
`swiftui-math_SwiftUIMath.bundle/mathFonts.bundle`.

Mermaid is included as a fixed local browser bundle so diagrams render
offline. Its complete MIT license is `Mermaid-LICENSE.txt` in the directory
listed above. In 1.4, the same bundled runtime is also used for vector PDF
output and the embedded Mac Quick Look extension. The local 1.4 Xcode build
uses `Contents/Resources/Legal/`, like the App Store app.

Before each public release, review both committed `Package.resolved` files and
the dependency graph with `swift package show-dependencies`. Update locks only
when intentionally changing dependencies, then confirm this notice and the
bundled license texts match the distributed versions.

The 1.5 reading view bundles markdown-it 15.0.3 and the same Prism.js 1.29.0
runtime shipped by Textual 0.5.0. DOMPurify 3.4.17 sanitizes Markdown-embedded
HTML and HTML documents; Ayami then applies an inline-style allowlist.
Parser and diagram scripts are loaded locally; document scripts and remote
image requests are blocked. See `markdown-it-LICENSE.txt`, `Prism-LICENSE.txt`,
and `DOMPurify-LICENSE.txt` in the license directory.
