import SwiftUI
import Textual
import WebKit

struct MermaidDiagramView: View {
  let source: String
  var fontScale: CGFloat = 1

  @Environment(\.colorScheme) private var colorScheme
  @State private var height: CGFloat = 180
  @State private var canLoadRenderer = false
  @State private var renderState = MermaidRenderState.loading

  var body: some View {
    Group {
      if renderState == .failed {
        MermaidFallbackView(source: source, fontScale: fontScale)
      } else if canLoadRenderer {
        ZStack {
          MermaidWebView(
            source: source,
            theme: theme,
            fontScale: fontScale,
            height: $height,
            renderState: $renderState
          )

          if renderState == .loading {
            ProgressView()
              .controlSize(.small)
          }
        }
      } else {
        ProgressView()
          .controlSize(.small)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: height)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .overlay {
      RoundedRectangle(cornerRadius: 8)
        .stroke(.separator.opacity(0.55), lineWidth: 1)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel(
      renderState == .failed
        ? "Mermaid diagram source"
        : "Mermaid diagram"
    )
    .accessibilityHint(accessibilityHint)
    .task(id: renderRequest) {
      renderState = .loading
      canLoadRenderer = false
      height = 180
      try? await Task.sleep(for: .milliseconds(120))
      guard !Task.isCancelled else { return }
      canLoadRenderer = true
    }
  }

  private var theme: String {
    colorScheme == .dark ? "dark" : "light"
  }

  private var renderRequest: MermaidRenderRequest {
    MermaidRenderRequest(source: source, theme: theme)
  }

  private var accessibilityHint: String {
    if renderState == .failed {
      return "The local diagram renderer was unavailable. The source remains readable."
    }
    return "Rendered locally from the open Markdown document."
  }
}

private enum MermaidRenderState: Equatable {
  case loading
  case ready
  case failed
}

private struct MermaidRenderRequest: Equatable {
  let source: String
  let theme: String
}

private struct MermaidFallbackView: View {
  let source: String
  let fontScale: CGFloat

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label("Diagram Preview Unavailable", systemImage: "exclamationmark.triangle")
        .font(.callout.weight(.semibold))

      Text("The Mermaid source is shown below.")
        .font(.caption)
        .foregroundStyle(.secondary)

      ScrollView(.horizontal) {
        Text(source)
          .font(.system(.caption, design: .monospaced))
          .textual.fontScale(fontScale)
          .textSelection(.enabled)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(.quaternary.opacity(0.35))
  }
}

#if os(macOS)
  private typealias PlatformWebViewRepresentable = NSViewRepresentable
#else
  private typealias PlatformWebViewRepresentable = UIViewRepresentable
#endif

private struct MermaidWebView: PlatformWebViewRepresentable {
  let source: String
  let theme: String
  let fontScale: CGFloat
  @Binding var height: CGFloat
  @Binding var renderState: MermaidRenderState

  func makeCoordinator() -> Coordinator {
    Coordinator(height: $height, renderState: $renderState)
  }

  private func makeWebView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
    configuration.userContentController.add(
      context.coordinator,
      name: Coordinator.messageName
    )

    let webView = IntrinsicSizeNeutralWebView(
      frame: .zero,
      configuration: configuration
    )
    webView.navigationDelegate = context.coordinator
    webView.underPageBackgroundColor = .clear
    #if os(macOS)
      webView.enclosingScrollView?.hasVerticalScroller = false
      webView.enclosingScrollView?.hasHorizontalScroller = false
    #else
      webView.isOpaque = false
      webView.backgroundColor = .clear
      webView.scrollView.isScrollEnabled = false
    #endif
    context.coordinator.webView = webView
    DispatchQueue.main.async { [weak coordinator = context.coordinator] in
      coordinator?.loadRenderer()
    }
    return webView
  }

  #if os(macOS)
    func makeNSView(context: Context) -> WKWebView {
      makeWebView(context: context)
    }

    func sizeThatFits(
      _ proposal: ProposedViewSize,
      nsView: WKWebView,
      context: Context
    ) -> CGSize? {
      CGSize(
        width: max(proposal.width ?? 600, 1),
        height: max(height, 80)
      )
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
      context.coordinator.render(source: source, theme: theme, fontScale: fontScale)
    }

    static func dismantleNSView(_ webView: WKWebView, coordinator: Coordinator) {
      dismantle(webView, coordinator: coordinator)
    }
  #else
    func makeUIView(context: Context) -> WKWebView {
      makeWebView(context: context)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: WKWebView, context: Context) -> CGSize?
    {
      CGSize(width: max(proposal.width ?? 320, 1), height: max(height, 80))
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
      context.coordinator.render(source: source, theme: theme, fontScale: fontScale)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
      dismantle(webView, coordinator: coordinator)
    }
  #endif

  private static func dismantle(_ webView: WKWebView, coordinator: Coordinator) {
    webView.configuration.userContentController.removeScriptMessageHandler(
      forName: Coordinator.messageName
    )
    webView.navigationDelegate = nil
    coordinator.cancelRenderTimeout()
  }

  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let messageName = "diagram"

    weak var webView: WKWebView?
    private var pendingSource: String?
    private var pendingTheme: String?
    private var renderedSource: String?
    private var renderedTheme: String?
    private var pendingFontScale: CGFloat = 1
    private var renderedFontScale: CGFloat?
    private var rendererReady = false
    private var height: Binding<CGFloat>
    private var renderState: Binding<MermaidRenderState>
    private var renderTimeoutTask: Task<Void, Never>?

    init(
      height: Binding<CGFloat>,
      renderState: Binding<MermaidRenderState>
    ) {
      self.height = height
      self.renderState = renderState
    }

    func loadRenderer() {
      guard let webView, let completeHTML = try? MermaidRendererResources.html() else {
        failRender()
        return
      }
      webView.loadHTMLString(
        completeHTML,
        baseURL: nil
      )
      startRenderTimeout()
    }

    func render(source: String, theme: String, fontScale: CGFloat) {
      pendingSource = source
      pendingTheme = theme
      pendingFontScale = fontScale
      guard rendererReady else { return }
      guard source != renderedSource || theme != renderedTheme || fontScale != renderedFontScale
      else { return }
      performRender(source: source, theme: theme, fontScale: fontScale)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      rendererReady = true
      if let pendingSource, let pendingTheme {
        performRender(source: pendingSource, theme: pendingTheme, fontScale: pendingFontScale)
      }
    }

    func webView(
      _ webView: WKWebView,
      didFail navigation: WKNavigation!,
      withError error: any Error
    ) {
      failRender()
    }

    func webView(
      _ webView: WKWebView,
      didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: any Error
    ) {
      failRender()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      failRender()
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler:
        @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
    ) {
      guard let url = navigationAction.request.url else {
        decisionHandler(.cancel)
        return
      }

      if navigationAction.navigationType == .other,
        url.isFileURL || url.absoluteString == "about:blank"
      {
        decisionHandler(.allow)
      } else {
        decisionHandler(.cancel)
      }
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      guard
        message.name == Self.messageName,
        let body = message.body as? [String: Any],
        let reportedHeight = body["height"] as? Double
      else {
        return
      }
      height.wrappedValue = min(max(reportedHeight, 80), 4_000)
      renderState.wrappedValue = .ready
      cancelRenderTimeout()
    }

    func cancelRenderTimeout() {
      renderTimeoutTask?.cancel()
      renderTimeoutTask = nil
    }

    private func performRender(source: String, theme: String, fontScale: CGFloat) {
      guard let webView else { return }
      renderedSource = source
      renderedTheme = theme
      renderedFontScale = fontScale

      let sourceJSON = Self.jsonString(source)
      let themeJSON = Self.jsonString(theme)
      webView.evaluateJavaScript(
        "window.renderDiagram(\(sourceJSON), \(themeJSON), \(fontScale));"
      )
    }

    private func startRenderTimeout() {
      cancelRenderTimeout()
      renderTimeoutTask = Task { @MainActor [weak self] in
        try? await Task.sleep(for: .seconds(8))
        guard !Task.isCancelled else { return }
        self?.failRender()
      }
    }

    private func failRender() {
      cancelRenderTimeout()
      renderState.wrappedValue = .failed
    }

    private static func jsonString(_ value: String) -> String {
      guard
        let data = try? JSONSerialization.data(withJSONObject: [value]),
        var encoded = String(data: data, encoding: .utf8)
      else {
        return "\"\""
      }
      encoded.removeFirst()
      encoded.removeLast()
      return encoded
    }
  }
}

private final class IntrinsicSizeNeutralWebView: WKWebView {
  #if os(macOS)
    override var intrinsicContentSize: NSSize {
      NSSize(
        width: NSView.noIntrinsicMetric,
        height: NSView.noIntrinsicMetric
      )
    }
  #else
    override var intrinsicContentSize: CGSize {
      CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }
  #endif
}
