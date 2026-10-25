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
        let result = try await DocumentPDFGenerator.generate(markdown: markdown, title: url.lastPathComponent)
        try Task.checkCancellation()
        let data = result.data
        // Let Quick Look own PDF display, selection, scrolling and zooming.
        let reply = QLPreviewReply(dataOfContentType: .pdf, contentSize: OutputPaper.a4.size) { _ in data }
        logger.info("Prepared Quick Look PDF: pages=\(result.pageCount), diagrams=\(result.diagramCount)")
        handler(reply, nil)
      } catch {
        logger.error("Quick Look preparation failed: \(String(describing: type(of: error)), privacy: .public)")
        handler(nil, error)
      }
    }
  }
}
