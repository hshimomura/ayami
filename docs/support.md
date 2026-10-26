---
layout: page
title: Support
permalink: /support
---

# Ayami support

## Requirements

- Apple silicon Mac with macOS 26 or later (Intel is not supported in 1.4)
- iOS/iPadOS 18 or later
- UTF-8 Markdown files using `.md` or `.markdown`

The current source release is 1.4 (build 20). Check the
[App Store](https://apps.apple.com/app/id6794576868) for the distributed version.

## Version 1.5 development reader

The development branch adds HTML viewing and literal text for `.txt`, `.json`,
`.c`, and other text extensions. It supports UTF-8, BOM-marked UTF-16/32, and
Shift JIS, up to 20 MiB. HTML scripts are not executed; formatting, tables,
details, and selected inline styles are supported. Print/PDF for non-Markdown
files uses literal source with the existing output limit.

On Mac, local document links open in a new tab by default. In **Reading Settings >
Document Links > Open Document Links In**, choose **New Tab** or **New Window**.
Web links use your browser. File menu commands retain their explicit window/tab
behavior. See the [development validation record](validation-1.5.md).

## Mac actions

- Open a file in a separate window with **File > Open File…** (`Command-O`).
- Add a file to the current window with **File > Open File in New Tab…**
  (`Command-Option-O`).
- Use the standard **Window** menu to move between tabs or merge windows.
- Use **Window > Arrange Markdown Documents Side by Side** to compare all open
  documents. Tabs are separated into windows before they are arranged.
- Toggle the chapter outline from the toolbar or View menu.
- Open **Print and PDF** with `Command-P` or the document-actions menu.
- Select a Markdown file in Finder and press Space for Quick Look.
- Save the file in an external editor to trigger Live Reload.

## Reading settings

Use **Ayami > Settings** on Mac or the **Reading Settings** toolbar button on
iPhone/iPad to adjust text size from 80% to 160%. Changes apply immediately and
are saved on the device. Use **Reset to Default** to return to 100%.

## iPhone and iPad

Select a document through Files. Contents appears as a sheet in compact windows
and a toggleable sidebar at regular width, including the inner Duo display.
iPad uses system-managed multiple windows. Mac-style tabs, file polling,
and Finder Quick Look are not included. Reopen a file if an external provider's
changes are not reflected.

## Print and PDF

On any platform, open **Print and PDF** from the document-actions menu. Select
A4 or Letter, wait for the preview, then use **Save PDF…** or **Print…**.
On iPhone/iPad, save through Files. Paper printing needs a compatible printer.
Source Markdown is not changed, and a successful save shows a confirmation.

Text and tables remain selectable; Mermaid is exported as vector diagrams.
Output has its own layout, independent of the reading-size slider. It does not
reproduce images or exact HTML/CSS screen layout, and supports only a subset of
Markdown. Invalid Mermaid or rendering failures show warnings and source instead.
Output and Quick Look accept UTF-8 input up to 1 MiB. PDF output is limited to
500 pages. Quick Look uses continuous scrolling without paper page breaks.

## On-device Document Highlights (Prototype)

Open the document-actions menu and choose **Document Highlights (Prototype)**.
Check availability, then select **Generate Highlights**. It does not run automatically.
AI requires OS 26+, an Apple Intelligence-supported device, Apple Intelligence
enabled, a prepared model, and a supported language. The model may need system
downloads before it is ready. Input is limited to 32,000 characters; output is
requested in Japanese or English.

Only Apple's on-device model is used. There is no document upload, cloud
fallback, or writeback to the file. Output may be wrong; check the original.
Availability and generation can fail without affecting reading or PDF output.
Mac generation was verified. iPhone simulator generation failed; iPad/Duo
generation and physical iOS devices have not been verified. See the
[1.4 validation record](validation-1.4.md).

## Limitations and troubleshooting

- Use UTF-8; convert other encodings before opening a document.
- Mermaid needs no installation or CDN. If a diagram fails, inspect the displayed
  source fallback and correct the Mermaid syntax in another editor.
- If Finder shows raw Markdown, check **System Settings > General > Login
  Items & Extensions > Quick Look** for Ayami and competing Markdown extensions.
  Moving another app to a different folder does not necessarily unregister its
  extension. In validation, the Ayami preview worked after QLMarkdown was removed;
  this does not establish a general defect or guaranteed selection priority.
- Version 1.4 does not support relative local images or a Find navigator. The 1.5 development reader adds these features; see the [development validation record](validation-1.5.md).

Ayami intentionally does not edit Markdown. Quick Look is included in the
Xcode-built Mac app, not in the old SwiftPM-only bundle packager.

For bug reports and feature requests, use the
[GitHub issue tracker](https://github.com/hshimomura/ayami/issues). Include
your OS and app versions, device, reproduction steps, and a sample Markdown
file with confidential information removed. For Duo layout issues, also specify
the display and fold/rotation state. Simulator validation does not replace real-device testing.
