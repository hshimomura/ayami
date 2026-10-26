# Public App Store metadata

This directory contains only information suitable for a public open-source
repository. App Store Connect is the source of truth for review workflow and
submission state.

The metadata files describe version 1.5. Japanese and English copy covers Mac and
iPhone/iPad separately. Editorial notes remain in [drafts/1.5](drafts/1.5/README.md).

## Public app record

- Store name: `あやみ : Markdownビューア` / `Ayami: Markdown Reader`
- Subtitle: `読むことに、集中できる` / `Quiet Markdown reading`
- Installed name: `あやみ` (Japanese) / `Ayami` (other languages)
- Bundle ID: `io.github.hshimomura.MDViewer`
- Platforms in source: macOS, iOS (iPhone and iPad)
- Primary category: Productivity
- Price: Free
- Version: `1.5`
- Build: `21`
- Copyright: `2026 Hideaki Shimomura`
- Support URL: `https://hshimomura.github.io/ayami/support`
- Marketing URL: `https://hshimomura.github.io/ayami/`
- Privacy Policy URL: `https://hshimomura.github.io/ayami/privacy`

## Tracked public material

- English (U.S.) product-page text in `metadata/en-US`
- Japanese product-page text in `metadata/ja`
- iPhone/iPad-specific descriptions and release-note drafts in `metadata/ios`.
  The initial iOS App Store form has no What's New field; retain the draft locally when that field is unavailable.
- Version 1.5 copy proposals and Japanese editorial notes in `drafts/1.5/`.
- Public screenshot sample documents in `Samples`
- Screenshot requirements in `Screenshots/README.md`
- Reproducible source and build checks in `release-checklist.md`

The screenshot image files themselves are ignored by Git. Store media must use
only public `Sample.md` or `Samples/` content and must not contain private documents.
Metadata files are platform/localization copy sources, not duplicate developer guides.

## Version 1.5 submission policy

Version 1.5 replaces the pending 1.4 submission. Verify the signed 1.5 packages
and their processed builds before withdrawing the corresponding 1.4 reviews.
Keep the existing automatic-release setting and apply the 1.5 localized copy.

Use the prepared Japanese and English Mac screenshots, including Finder Quick
Look, and the iPhone Duo screenshots. Also place the localized universal creative assets
on the iOS Header and Search Results surfaces. Create version-localization placements
for library assets and verify their processing state and order before submission.
An asset stored in the library alone does not appear on the App Store.

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
./Scripts/verify-app-store-metadata.sh AppStore/drafts/1.5/metadata
```

Build/export commands and source releases are documented once in the
[release checklist](release-checklist.md). Feature changes belong in the
[release notes](../docs/releases/1.4.md); test outcomes belong in the
[validation record](../docs/validation-1.4.md).
