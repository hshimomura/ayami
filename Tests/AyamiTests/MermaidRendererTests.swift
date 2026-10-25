import Foundation
import CryptoKit
import Testing
import WebKit
@testable import Ayami

@MainActor
struct MermaidRendererTests {
  @Test func bundledRuntimeMatchesAuditedVersion() throws {
    let directory = try #require(MermaidRendererResources.directory)
    let metadata = try JSONSerialization.jsonObject(with: Data(contentsOf: directory.appending(path: "version.json"))) as? [String: String]
    #expect(metadata?["version"] == "12.2.0")
    let runtime = try Data(contentsOf: directory.appending(path: "mermaid.min.js"))
    let digest = SHA256.hash(data: runtime).map { String(format: "%02x", $0) }.joined()
    #expect(digest == "a8a6a6f805b074a8261a2825c86f99c8054acb3b35f50bb7e24a4f9f2c3c3b9f")
    #expect(metadata?["runtimeSHA256"] == digest)
  }

  @Test func bundledDiagramsRenderOfflineAcrossThemesAndSizes() async throws {
    let renderer = RendererHarness()
    defer { renderer.close() }
    try await renderer.load()
    let diagrams = [
      "flowchart LR\n A[文書] --> B[読む]",
      "sequenceDiagram\n Alice->>Bob: Markdown",
      "classDiagram\n Reader --> Document",
      "stateDiagram-v2\n [*] --> Reading",
      "erDiagram\n READER ||--o{ DOCUMENT : reads",
      "mindmap\n root((Markdown))\n  見出し\n  本文",
    ]
    for (index, source) in diagrams.enumerated() {
      let result = try await renderer.render(source, dark: index.isMultiple(of: 2), scale: index.isMultiple(of: 2) ? 0.8 : 1.6)
      #expect(result["svgCount"] as? Int == 1, "Diagram: \(source)")
      #expect(result["error"] as? String == "")
      #expect(result["layout"] as? String == "dagre")
      #expect(result["look"] as? String == "classic")
      #expect(result["fontSize"] as? String == (index.isMultiple(of: 2) ? "12.8px" : "25.6px"))
    }
    let blocked = try await renderer.webView.callAsyncJavaScript(
      "try { await fetch('https://example.invalid/ayami-test'); return false; } catch { return true; }",
      arguments: [:], in: nil, contentWorld: .page
    )
    #expect(blocked as? Bool == true)
    let resources = try await renderer.webView.evaluateJavaScript(
      "performance.getEntriesByType('resource').filter(e => /^https?:/.test(e.name)).length"
    )
    #expect(resources as? Int == 0)
  }

  @Test func invalidSourceFallsBackAndLinksAreRemoved() async throws {
    let renderer = RendererHarness()
    defer { renderer.close() }
    try await renderer.load()
    let invalid = "this is not a Mermaid diagram <script>alert(1)</script>"
    let failure = try await renderer.render(invalid, dark: false, scale: 1.6)
    #expect(failure["svgCount"] as? Int == 0)
    #expect((failure["error"] as? String)?.contains(invalid) == true)
    let valid = try await renderer.render("flowchart LR\n A[Read] --> B[Done]\n click A \"https://example.com\"", dark: true, scale: 1)
    #expect(valid["svgCount"] as? Int == 1)
    #expect(valid["links"] as? Int == 0)
  }
}

@MainActor
private final class RendererHarness: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
  let webView: WKWebView
  private var loading: CheckedContinuation<Void, any Error>?
  private var timeout: Task<Void, Never>?

  override init() {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 1000), configuration: configuration)
    super.init()
    webView.navigationDelegate = self
    configuration.userContentController.add(self, name: "diagram")
  }

  func load() async throws {
    let html = try MermaidRendererResources.html()
    try await withCheckedThrowingContinuation { continuation in
      loading = continuation
      timeout = Task { [weak self] in
        do { try await Task.sleep(for: .seconds(30)) } catch { return }
        self?.finish(CocoaError(.fileReadUnknown))
      }
      webView.loadHTMLString(html, baseURL: nil)
    }
  }

  func render(_ source: String, dark: Bool, scale: Double) async throws -> [String: Any] {
    let value = try await webView.callAsyncJavaScript("""
      await window.renderDiagram(source, theme, scale);
      const config = mermaid.mermaidAPI.getConfig();
      return {
        svgCount: document.querySelectorAll('#diagram svg').length,
        error: document.querySelector('#diagram .error')?.textContent ?? '',
        links: document.querySelectorAll('#diagram a').length,
        layout: config.layout, look: config.look, fontSize: config.themeVariables.fontSize
      };
      """, arguments: ["source": source, "theme": dark ? "dark" : "light", "scale": scale], in: nil, contentWorld: .page)
    return try #require(value as? [String: Any])
  }

  func close() {
    timeout?.cancel()
    webView.stopLoading()
    webView.configuration.userContentController.removeScriptMessageHandler(forName: "diagram")
    webView.navigationDelegate = nil
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
  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
}
