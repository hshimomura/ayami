import SwiftUI
import WebKit

struct ReaderLinkRequest {
  let reference: String
  var destination: DocumentLinkDestination?
}

@MainActor
@Observable
final class ReaderSession {
  var headings: [MarkdownHeading] = []
  var currentSectionID: String?
  var isReady = false
  var diagramsReady = false
  var hasSelection = false
  var hasActiveMark = false
  var markCount = 0
  var matchCount = 0
  var matchIndex = -1
  var matchLimitReached = false
  var hasUnavailableImages = false
  var notice: String?
  var error: String?
  private(set) var query = ""
  // Keep one reading page per document, even when compact/regular layouts replace the native view.
  var webView: WKWebView?
  let resources = ReaderSchemeHandler()
  let messageHandler = WeakReaderMessageHandler()
  var pageLoaded = false
  var renderedOptions: String?

  func command(_ name: String, _ arguments: [Any] = []) {
    let args = arguments.map(ReaderResources.json).joined(separator: ",")
    webView?.evaluateJavaScript("window.reader?.\(name)(\(args)); void 0;")
  }

  func find(_ query: String) { self.query = query; command("find", [query]) }
  func jump(_ id: String) { command("jump", [id]) }
}

@MainActor
enum ReaderNavigation {
  static let notification = Notification.Name("AyamiReaderNavigate")
  private static var pending: [URL: String] = [:]

  static func prepare(url: URL, fragment: String?) {
    guard let fragment, !fragment.isEmpty else { return }
    pending[url.standardizedFileURL] = fragment
    NotificationCenter.default.post(name: notification, object: url.standardizedFileURL)
  }

  static func takeFragment(for url: URL?) -> String? {
    guard let url else { return nil }
    return pending.removeValue(forKey: url.standardizedFileURL)
  }
}

#if os(macOS)
  private typealias ReaderRepresentable = NSViewRepresentable
#else
  private typealias ReaderRepresentable = UIViewRepresentable
#endif

struct ReaderWebView: ReaderRepresentable {
  let markdown: String
  let fileURL: URL?
  let fontScale: CGFloat
  let session: ReaderSession
  let folders: [URL]
  let onLink: (ReaderLinkRequest) -> Void
  @Environment(\.colorScheme) private var colorScheme

  func makeCoordinator() -> Coordinator { Coordinator(session: session, onLink: onLink) }

  private func makeWebView(context: Context) -> WKWebView {
    session.messageHandler.target = context.coordinator
    if let view = session.webView {
      view.navigationDelegate = context.coordinator
      return view
    }
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
    configuration.userContentController.add(session.messageHandler, name: "reader")
    configuration.setURLSchemeHandler(context.coordinator.resources, forURLScheme: "ayami-reader")
    configuration.setURLSchemeHandler(context.coordinator.resources, forURLScheme: "ayami-asset")
    let view = WKWebView(frame: .zero, configuration: configuration)
    view.navigationDelegate = context.coordinator
    #if os(macOS)
      view.setValue(false, forKey: "drawsBackground")
      view.setAccessibilityIdentifier("markdownReader")
    #else
      view.isOpaque = false
      view.backgroundColor = .clear
      view.scrollView.contentInsetAdjustmentBehavior = .never
      view.accessibilityIdentifier = "markdownReader"
    #endif
    session.webView = view
    context.coordinator.resources.policy = DocumentResourcePolicy(documentURL: fileURL, grantedFolders: folders)
    view.load(URLRequest(url: URL(string: "ayami-reader://bundle/index.html")!))
    return view
  }

  private func update(_ view: WKWebView, context: Context) {
    context.coordinator.onLink = onLink
    let changedFolders = context.coordinator.resources.policy.grantedFolders != folders
    context.coordinator.resources.policy = DocumentResourcePolicy(documentURL: fileURL, grantedFolders: folders)
    context.coordinator.render(markdown: markdown, scale: fontScale, theme: colorScheme == .dark ? "dark" : "light")
    if changedFolders { session.command("reloadImages") }
  }

  #if os(macOS)
    func makeNSView(context: Context) -> WKWebView { makeWebView(context: context) }
    func updateNSView(_ view: WKWebView, context: Context) { update(view, context: context) }
    static func dismantleNSView(_ view: WKWebView, coordinator: Coordinator) { coordinator.close(view) }
  #else
    func makeUIView(context: Context) -> WKWebView { makeWebView(context: context) }
    func updateUIView(_ view: WKWebView, context: Context) { update(view, context: context) }
    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) { coordinator.close(view) }
  #endif

  @MainActor
  final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    let session: ReaderSession
    var resources: ReaderSchemeHandler { session.resources }
    var onLink: (ReaderLinkRequest) -> Void
    private var pending: String?

    init(session: ReaderSession, onLink: @escaping (ReaderLinkRequest) -> Void) {
      self.session = session
      self.onLink = onLink
    }

    func render(markdown: String, scale: CGFloat, theme: String) {
      let labels = ["copy": String(localized: "Copy Code"), "copied": String(localized: "Copied"),
        "code": String(localized: "Code"), "expand": String(localized: "Expand Diagram"),
        "fit": String(localized: "Fit"), "close": String(localized: "Done"),
        "zoomIn": String(localized: "Zoom In"), "zoomOut": String(localized: "Zoom Out"),
        "diagramError": String(localized: "Mermaid diagram unavailable")]
      #if os(macOS)
        let nativeLinkMenu = true
      #else
        let nativeLinkMenu = false
      #endif
      let options: [String: Any] = ["markdown": markdown, "scale": scale, "theme": theme,
        "nativeLinkMenu": nativeLinkMenu,
        "format": DocumentFormat.format(for: resources.policy.documentURL).rawValue,
        "syntaxLanguage": DocumentFormat.language(for: resources.policy.documentURL),
        "language": Locale.preferredLanguages.first ?? "en", "labels": labels]
      pending = ReaderResources.json(options)
      performRender()
    }

    private func performRender() {
      guard session.pageLoaded, let pending, pending != session.renderedOptions, let view = session.webView else { return }
      session.renderedOptions = pending
      view.evaluateJavaScript("window.reader.update(\(pending)).catch(() => window.webkit.messageHandlers.reader.postMessage({type:'failed'})); void 0;") { [weak self] _, error in
        if error != nil { self?.session.error = String(localized: "The document could not be rendered.") }
      }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      guard message.frameInfo.isMainFrame, let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
      switch type {
      case "loaded": session.pageLoaded = true; performRender()
      case "rendering": session.diagramsReady = false; session.hasUnavailableImages = false
      case "ready":
        let firstReady = !session.isReady
        session.isReady = true
        session.headings = (body["headings"] as? [[String: Any]] ?? []).compactMap { heading in
          guard let id = heading["id"] as? String, let title = heading["title"] as? String, let level = heading["level"] as? Int else { return nil }
          return MarkdownHeading(id: id, level: level, title: title)
        }
        if !session.headings.contains(where: { $0.id == session.currentSectionID }) {
          session.currentSectionID = session.headings.first?.id
        }
        if firstReady && !session.query.isEmpty { session.find(session.query) }
        if let fragment = ReaderNavigation.takeFragment(for: resources.policy.documentURL) { session.jump(fragment) }
      case "diagramsReady": session.diagramsReady = true
      case "state":
        session.hasSelection = body["hasSelection"] as? Bool ?? false
        session.hasActiveMark = body["hasActiveMark"] as? Bool ?? false
        session.markCount = body["markCount"] as? Int ?? 0
        session.matchCount = body["matchCount"] as? Int ?? 0
        session.matchIndex = body["matchIndex"] as? Int ?? -1
        session.matchLimitReached = body["matchLimitReached"] as? Bool ?? false
      case "section": session.currentSectionID = body["id"] as? String
      case "copy":
        guard let text = body["text"] as? String else { return }
        #if os(macOS)
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(text, forType: .string)
        #else
          UIPasteboard.general.string = text
        #endif
      case "link": if let href = body["href"] as? String { onLink(ReaderLinkRequest(reference: href)) }
      #if os(macOS)
      case "linkContextMenu":
        if let href = body["href"] as? String, let x = body["x"] as? Double, let y = body["y"] as? Double {
          showLinkContextMenu(reference: href, x: x, y: y)
        }
      #endif
      case "imageUnavailable": session.hasUnavailableImages = true
      case "anchorMissing": session.notice = String(localized: "The linked heading was not found.")
      case "marksRemoved": session.notice = String(localized: "Some marks were removed because the original text changed.")
      case "failed": session.error = String(localized: "The document could not be rendered.")
      default: break
      }
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
      decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
      decisionHandler(action.navigationType == .other && action.request.url?.absoluteString == "ayami-reader://bundle/index.html" ? .allow : .cancel)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
      session.error = String(localized: "The document could not be rendered.")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      if !session.pageLoaded { session.error = String(localized: "The document could not be rendered.") }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      session.error = String(localized: "The reader stopped. Reopen the document to continue.")
    }

    func close(_ view: WKWebView) {
      // A layout transition may already have attached a new coordinator to this same page.
      if session.messageHandler.target === self {
        session.messageHandler.target = nil
        view.navigationDelegate = nil
      }
    }
  }
}

@MainActor
final class WeakReaderMessageHandler: NSObject, WKScriptMessageHandler {
  weak var target: (any WKScriptMessageHandler)?

  func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
    target?.userContentController(controller, didReceive: message)
  }
}

@MainActor
final class ReaderSchemeHandler: NSObject, WKURLSchemeHandler {
  var policy = DocumentResourcePolicy(documentURL: nil)

  func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
    guard let url = task.request.url else { return }
    do {
      let data: Data, type: String
      switch (url.scheme, url.host) {
      case ("ayami-reader", "bundle"):
        (data, type) = try ReaderResources.resource(String(url.path.dropFirst()))
      case ("ayami-asset", "document"):
        guard let reference = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "path" })?.value else { throw CocoaError(.fileReadNoPermission) }
        (data, type) = try policy.image(reference)
      default: throw CocoaError(.fileReadNoPermission)
      }
      task.didReceive(URLResponse(url: url, mimeType: type, expectedContentLength: data.count, textEncodingName: type.hasPrefix("text/") ? "utf-8" : nil))
      task.didReceive(data)
      task.didFinish()
    } catch { task.didFailWithError(error) }
  }

  func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}
}
