---
layout: page
title: Support
permalink: /support
---

# Ayami support

## Requirements

- macOS 26 or later
- iOS/iPadOS 18 or later
- UTF-8 Markdown files using `.md` or `.markdown`

The current source release is 1.3 (build 18). Check the
[App Store](https://apps.apple.com/app/id6794576868) for the distributed version.

## Mac actions

- Open a file in a separate window with **File > Open File…** (`Command-O`).
- Add a file to the current window with **File > Open File in New Tab…**
  (`Command-Option-O`).
- Use the standard **Window** menu to move between tabs or merge windows.
- Use **Window > Arrange Markdown Documents Side by Side** to compare all open
  documents. Tabs are separated into windows before they are arranged.
- Toggle the chapter outline from the toolbar or View menu.
- Print with `Command-P`; choose **PDF > Save as PDF…** for PDF output.
- Save the file in an external editor to trigger Live Reload.

## Reading settings

Use **Ayami > Settings** on Mac or the **Reading Settings** toolbar button on
iPhone/iPad to adjust text size from 80% to 160%. Changes apply immediately and
are saved on the device. Use **Reset to Default** to return to 100%.

## iPhone and iPad

Select a document through Files. Contents appears as a sheet in compact windows
and a toggleable sidebar at regular width, including the inner Duo display.
iPad uses system-managed multiple windows. Mac-style tabs, file polling,
printing, and PDF output are not included. Reopen a file if an external provider's
changes are not reflected.

## Limitations and troubleshooting

- Use UTF-8; convert other encodings before opening a document.
- Mermaid needs no installation or CDN. If a diagram fails, inspect the displayed
  source fallback and correct the Mermaid syntax in another editor.
- On Mac, printing uses a separate layout and shows Mermaid as source text.
- Relative local images and a Find navigator are not implemented.

Ayami intentionally does not edit Markdown and does not include a Quick
Look extension.

For bug reports and feature requests, use the
[GitHub issue tracker](https://github.com/hshimomura/ayami/issues). Include
your OS and app versions, device, reproduction steps, and a sample Markdown
file with confidential information removed. For Duo layout issues, also specify
the display and fold/rotation state. Simulator validation does not replace real-device testing.
