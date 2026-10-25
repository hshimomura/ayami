import Foundation
import OSLog
import QuickLookUI
import UniformTypeIdentifiers

@MainActor
final class PreviewProvider: QLPreviewProvider, @preconcurrency QLPreviewingController {
  private var preparation: Task<Void, Never>?
  private let logger = Logger(subsystem: "io.github.hshimomura.MDViewer.QuickLook", category: "Preview")

  override init() {
    super.init()
    logger.info("Quick Look provider initialized")
  }

  func providePreview(for request: QLFilePreviewRequest,
    completionHandler handler: @escaping (QLPreviewReply?, (any Error)?) -> Void) {
    logger.info("Quick Look preparation requested")
    preparation?.cancel()
    preparation = Task { @MainActor in
      do {
        let url = request.fileURL
        let markdown = try OutputDocument.read(url)
        let result = try await QuickLookHTMLRenderer.render(markdown: markdown, title: url.lastPathComponent)
        try Task.checkCancellation()
        // HTML keeps Quick Look's reading preview continuous. Pagination belongs
        // to the separate print and PDF export flow in the main app.
        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 960, height: 720)) { _ in result.data }
        reply.attachments = result.diagrams.mapValues { QLPreviewReplyAttachment(data: $0, contentType: .svg) }
        reply.title = url.lastPathComponent
        logger.info("Prepared continuous Quick Look HTML preview")
        handler(reply, nil)
      } catch {
        logger.error("Quick Look preparation failed: \(String(describing: type(of: error)), privacy: .public)")
        handler(nil, error)
      }
    }
  }
}
