# Third-party notices

Ayami includes the following runtime dependencies. Their complete license
texts are retained in the built application. The location depends on the build:

| Build | License directory |
| --- | --- |
| Xcode macOS app / App Store export | `Contents/Resources/Legal/` |
| Xcode iOS app / App Store export | `Legal/` inside `Ayami.app` |
| Local Mac script build | `Contents/Resources/ThirdPartyLicenses/` |

| Component | Version | License | Source |
| --- | --- | --- | --- |
| Textual | 0.5.0 | MIT | https://github.com/gonzalezreal/textual |
| SwiftUIMath | 0.1.0 | MIT | https://github.com/gonzalezreal/swiftui-math |
| ConcurrencyExtras | 1.4.3 | MIT | https://github.com/pointfreeco/swift-concurrency-extras |
| Prism.js | 1.29.0 (bundled by Textual) | MIT | https://github.com/PrismJS/prism |
| Mermaid | 12.2.0 | MIT | https://github.com/mermaid-js/mermaid |

SwiftUIMath includes math fonts under the SIL Open Font License 1.1 and the
GUST Font License. The complete `OFL.txt` and `GUST-FONT-LICENSE.txt` files
are retained inside the distributed
`swiftui-math_SwiftUIMath.bundle/mathFonts.bundle`.

Mermaid is included as a fixed local browser bundle so diagrams render
offline. Its complete MIT license is `Mermaid-LICENSE.txt` in the directory
listed above.

Before each public release, review both committed `Package.resolved` files and
the dependency graph with `swift package show-dependencies`. Update locks only
when intentionally changing dependencies, then confirm this notice and the
bundled license texts match the distributed versions.
