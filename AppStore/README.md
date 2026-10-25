# Public App Store metadata

This directory contains only information suitable for a public open-source
repository. App Store Connect is the source of truth for review workflow and
submission state.

## Public app record

- Store name: `あやみ — Markdownビューア` / `Ayami: Markdown Reader`
- Installed name: `あやみ` (Japanese) / `Ayami` (other languages)
- Bundle ID: `io.github.hshimomura.MDViewer`
- Platforms in source: macOS, iOS (iPhone and iPad)
- Primary category: Productivity
- Price: Free
- Version: `1.3`
- Build: `18`
- Copyright: `2026 Hideaki Shimomura`
- Support URL: `https://hshimomura.github.io/ayami/support`
- Marketing URL: `https://hshimomura.github.io/ayami/`
- Privacy Policy URL: `https://hshimomura.github.io/ayami/privacy`

## Tracked public material

- English (U.S.) product-page text in `metadata/en-US`
- Japanese product-page text in `metadata/ja`
- iPhone/iPad-specific descriptions and first-release note drafts in `metadata/ios`.
  The initial iOS edition uses version 1.3; its App Store form has no What's New field.
- Public screenshot sample documents in `Samples`
- Screenshot requirements in `Screenshots/README.md`
- Reproducible source and build checks in `release-checklist.md`

The screenshot image files themselves are ignored by Git. Store media must use
only public `Sample.md` or `Samples/` content and must not contain private documents.
Metadata files are platform/localization copy sources, not duplicate developer guides.

## Privacy and export compliance

The app does not collect data or perform tracking. Documents and bundled
Mermaid rendering remain local. `ITSAppUsesNonExemptEncryption` is `false`
because the app does not implement or ship encryption beyond Apple system
frameworks.

## Repository policy

Do not commit App Store review status, submission dates or identifiers,
reviewer contact details, review notes, agreement status, trader declarations,
certificate identities, provisioning profiles, or screenshots containing
non-public documents.

Local operational records belong under `AppStore/private/`, which is ignored
by Git.

## Validation

Validate both localizations against App Store Connect character limits after
making changes:

```sh
./Scripts/verify-app-store-metadata.sh
```

Build/export commands and source releases are documented once in the
[release checklist](release-checklist.md). Feature changes belong in the
[release notes](../docs/releases/1.3.md); test outcomes belong in the
[validation record](../docs/iphone-duo-validation-1.3.md).
