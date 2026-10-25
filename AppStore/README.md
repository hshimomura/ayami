# Public App Store metadata

This directory contains only information suitable for a public open-source
repository. App Store Connect is the source of truth for review workflow and
submission state.

## Public app record

- Planned name: `あやみ — Markdownビューア` / `Ayami: Markdown Reader`
- Installed name: `あやみ` (Japanese) / `Ayami` (other languages)
- Bundle ID: `io.github.hshimomura.MDViewer`
- Platforms in source: macOS, iOS (iPhone and iPad)
- Primary category: Productivity
- Price: Free
- Version: `1.3`
- Build: `17`
- Copyright: `2026 Hideaki Shimomura`
- Support URL: `https://hshimomura.github.io/Ayami/support`
- Marketing URL: `https://hshimomura.github.io/Ayami/`
- Privacy Policy URL: `https://hshimomura.github.io/Ayami/privacy`

## Tracked public material

- English (U.S.) product-page text in `metadata/en-US`
- Japanese product-page text in `metadata/ja`
- Screenshot requirements in `Screenshots/README.md`
- Reproducible source and build checks in `release-checklist.md`

The screenshot image files themselves are ignored by Git. Store media must use
only the bundled public `Sample.md` and must not contain private documents.

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
