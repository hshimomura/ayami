import Foundation
import WebKit

/// A local-only renderer produces vector PDF pages and SVG attachments.
@MainActor
final class MermaidPDFRenderer: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
  private let webView: WKWebView
  private var loading: CheckedContinuation<Void, any Error>?
  private var timeout: Task<Void, Never>?
  private var loaded = false

  override init() {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1000, height: 800), configuration: configuration)
    super.init()
    webView.navigationDelegate = self
    configuration.userContentController.add(self, name: "diagram")
  }

  func render(_ source: String) async throws -> Data {
    let size = try await prepare(source)
    let configuration = WKPDFConfiguration()
    configuration.rect = CGRect(origin: .zero, size: size)
    let data = try await webView.pdf(configuration: configuration)
    try Task.checkCancellation()
    return data
  }

  func renderSVG(_ source: String) async throws -> Data {
    _ = try await prepare(source)
    let result = try await webView.evaluateJavaScript("document.querySelector('#diagram svg').outerHTML")
    try Task.checkCancellation()
    guard let svg = result as? String else { throw OutputError.renderingFailed }
    return Data(svg.utf8)
  }

  private func prepare(_ source: String) async throws -> CGSize {
    try Task.checkCancellation()
    guard source.utf8.count <= 65_536 else { throw OutputError.documentTooLarge }
    if !loaded { try await load() }
    let result = try await webView.callAsyncJavaScript("""
      await Promise.race([
        window.renderDiagram(source, 'light', 1),
        new Promise((_, reject) => setTimeout(() => reject(new Error('Diagram timeout')), 12000))
      ]);
      const svg = document.querySelector('#diagram svg');
      if (!svg) throw new Error('Invalid Mermaid diagram');
      svg.style.maxWidth = 'none';
      svg.style.margin = '0';
      document.documentElement.style.background = 'white';
      document.body.style.background = 'white';
      const root = document.getElementById('diagram');
      root.style.padding = '0';
      const bounds = svg.getBoundingClientRect();
      return { width: Math.ceil(bounds.width), height: Math.ceil(bounds.height) };
      """, arguments: ["source": source], in: nil, contentWorld: .page)
    try Task.checkCancellation()
    guard let size = result as? [String: Any],
      let width = size["width"] as? Double, let height = size["height"] as? Double,
      width.isFinite, height.isFinite, width > 0, height > 0, height <= 32_000
    else { throw OutputError.renderingFailed }
    return CGSize(width: width, height: height)
  }

  func close() {
    finish(CancellationError())
    webView.stopLoading()
    webView.navigationDelegate = nil
    webView.configuration.userContentController.removeScriptMessageHandler(forName: "diagram")
  }

  private func load() async throws {
    let html = try MermaidRendererResources.html()
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        loading = continuation
        timeout = Task { [weak self] in
          do { try await Task.sleep(for: .seconds(15)) } catch { return }
          self?.finish(OutputError.timedOut)
        }
        webView.loadHTMLString(html, baseURL: nil)
      }
    } onCancel: {
      Task { @MainActor [weak self] in self?.finish(CancellationError()) }
    }
    loaded = true
  }

  private func finish(_ error: (any Error)? = nil) {
    timeout?.cancel()
    let continuation = loading
    loading = nil
    if let error { continuation?.resume(throwing: error) }
    else { continuation?.resume() }
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finish() }
  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) { finish(error) }
  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) { finish(error) }
  func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
  ) {
    decisionHandler(navigationAction.request.url?.absoluteString == "about:blank" ? .allow : .cancel)
  }
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
}
