#if os(macOS)
import AppKit
import Foundation

enum ReaderLinkMenuAction: Int {
  case open, tab, window, download, copy
}

extension DocumentResourcePolicy {
  /// Resolve the authored link, never the WebKit page's private resource URL.
  func linkURL(_ reference: String) throws -> URL {
    guard let url = URL(string: reference, relativeTo: documentURL)?.absoluteURL,
      ["file", "http", "https", "mailto"].contains(url.scheme?.lowercased() ?? "")
    else { throw CocoaError(.fileReadUnsupportedScheme) }
    guard url.isFileURL else { return url }
    // standardizedFileURL drops the fragment; retain heading links when copying.
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      throw CocoaError(.fileReadUnsupportedScheme)
    }
    components.path = url.standardizedFileURL.path
    guard let resolved = components.url else { throw CocoaError(.fileReadUnsupportedScheme) }
    return resolved
  }
}

@MainActor
extension ReaderWebView.Coordinator {
  func makeLinkMenu(reference: String) throws -> NSMenu {
    let url = try resources.policy.linkURL(reference)
    let menu = NSMenu()
    menu.autoenablesItems = false
    func add(_ title: String, _ action: ReaderLinkMenuAction) {
      let item = NSMenuItem(title: title, action: #selector(performLinkMenuAction(_:)), keyEquivalent: "")
      item.target = self
      item.tag = action.rawValue
      item.representedObject = reference
      menu.addItem(item)
    }
    add(String(localized: "Open Link"), .open)
    if url.isFileURL {
      add(String(localized: "Open Link in New Tab"), .tab)
      add(String(localized: "Open Link in New Window"), .window)
    }
    if url.isFileURL || ["https", "http"].contains(url.scheme?.lowercased() ?? "") {
      add(String(localized: "Download Linked File…"), .download)
    }
    menu.addItem(.separator())
    add(String(localized: "Copy Link"), .copy)
    return menu
  }

  func showLinkContextMenu(reference: String, x: Double, y: Double) {
    guard let view = session.webView, x.isFinite, y.isFinite else { return }
    do {
      let menu = try makeLinkMenu(reference: reference)
      let point = NSPoint(x: min(max(x, 0), view.bounds.width),
        y: min(max(view.isFlipped ? y : view.bounds.height - y, 0), view.bounds.height))
      menu.popUp(positioning: nil, at: point, in: view)
    } catch { session.error = error.localizedDescription }
  }

  @objc private func performLinkMenuAction(_ item: NSMenuItem) {
    guard let reference = item.representedObject as? String,
      let action = ReaderLinkMenuAction(rawValue: item.tag) else { return }
    do {
      switch action {
      case .open: onLink(ReaderLinkRequest(reference: reference))
      case .tab: onLink(ReaderLinkRequest(reference: reference, destination: .tab))
      case .window: onLink(ReaderLinkRequest(reference: reference, destination: .window))
      case .copy: try copyLink(reference)
      case .download: try downloadLink(reference)
      }
    } catch { session.error = error.localizedDescription }
  }

  func copyLink(_ reference: String, to pasteboard: NSPasteboard = .general) throws {
    let url = try resources.policy.linkURL(reference)
    pasteboard.clearContents()
    pasteboard.writeObjects([url as NSURL])
    pasteboard.setString(url.absoluteString, forType: .URL)
    // Include plain text for editors and terminals as well as the URL type.
    pasteboard.setString(url.absoluteString, forType: .string)
  }

  private func downloadLink(_ reference: String) throws {
    let url = try resources.policy.linkURL(reference)
    // Apply the same folder permission and real-path boundary used by opening links.
    let localSource = url.isFileURL ? try resources.policy.resolve(reference) : nil
    guard let window = session.webView?.window else { return }
    let panel = NSSavePanel()
    panel.title = String(localized: "Download Linked File…")
    panel.nameFieldStringValue = url.lastPathComponent.isEmpty ? "download" : url.lastPathComponent
    panel.canCreateDirectories = true
    panel.beginSheetModal(for: window) { [weak self] response in
      guard response == .OK, let destination = panel.url, let self else { return }
      Task { @MainActor in
        do {
          if let localSource {
            try ReaderLinkFileCopy.save(from: localSource, to: destination)
          } else {
            self.session.notice = String(localized: "Downloading linked file…")
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieStorage = nil
            configuration.urlCredentialStorage = nil
            configuration.urlCache = nil
            configuration.timeoutIntervalForResource = 60
            let download = URLSession(configuration: configuration)
            defer { download.invalidateAndCancel() }
            let (temporary, response) = try await download.download(from: url)
            defer { try? FileManager.default.removeItem(at: temporary) }
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
              throw URLError(.badServerResponse)
            }
            try ReaderLinkFileCopy.save(from: temporary, to: destination)
          }
          self.session.notice = String(localized: "Linked file saved.")
        } catch {
          self.session.notice = nil
          self.session.error = error.localizedDescription
        }
      }
    }
  }
}

enum ReaderLinkFileCopy {
  static func save(from source: URL, to destination: URL) throws {
    guard source.standardizedFileURL.resolvingSymlinksInPath() != destination.standardizedFileURL.resolvingSymlinksInPath() else {
      throw CocoaError(.fileWriteFileExists)
    }
    let access = destination.startAccessingSecurityScopedResource()
    defer { if access { destination.stopAccessingSecurityScopedResource() } }
    try Data(contentsOf: source, options: .mappedIfSafe).write(to: destination, options: .atomic)
  }
}
#endif
