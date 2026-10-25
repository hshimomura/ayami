---
layout: page
title: Privacy Policy
permalink: /privacy
---

Effective date: July 25, 2026

Last updated: October 25, 2026 (version 1.4: PDF output, Quick Look, on-device highlights).

Ayami (formerly MD Viewer: Reading Window) does not collect, sell, or share
personal data. It does not include analytics, advertising, tracking, accounts,
or an external cloud service. Local reading preferences are described below.

Markdown files are opened only after you select them in the system document
browser, Files, or Finder. Their content is processed locally on your device.
Mermaid diagrams are rendered with a copy of Mermaid bundled inside the app;
the app does not use a CDN. PDF creation is local on Mac, iPhone and iPad;
printing uses the platform's system print interface. A selected printer may
receive the output as part of the print operation. The Mac Quick Look extension
uses the same local PDF renderer and does not run AI.

Document Highlights (Prototype) runs only when you explicitly start generation.
It uses Apple's on-device Foundation Models model, not Private Cloud Compute,
a third-party model or a cloud fallback. Ayami does not upload the selected
document or generated highlights, and it does not write the result back to your
Markdown file. The app does not maintain a summary history or send generation
errors to the developer. AI requires a compatible environment; Apple manages
model preparation and availability through system settings.

Reading preferences are stored locally in UserDefaults. iCloud Drive and other
Files providers may synchronize files under your own provider settings; Ayami
does not operate a document synchronization service.

The app does not transmit document content or usage information to the
developer. The open-source project is hosted on GitHub; visiting GitHub or this
website is subject to the privacy terms of those services.

Questions about this policy can be submitted through the
[Ayami issue tracker](https://github.com/hshimomura/ayami/issues).
