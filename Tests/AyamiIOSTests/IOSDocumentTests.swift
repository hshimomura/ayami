import Foundation
import Testing

@testable import MDPreview

struct IOSDocumentTests {
  @Test func keepsMarkdownReadOnlyViewerType() {
    let document = MarkdownDocument(text: "# あやみ\n\nRead only")
    #expect(document.text.contains("あやみ"))
    #expect(
      MarkdownDocument.readableContentTypes.first?.identifier == "net.daringfireball.markdown")
  }

  @Test func extractsOutlineAndOfflineDiagram() {
    let content = MarkdownContentParser.parse(
      "# Intro\n\n```mermaid\nflowchart LR\nA-->B\n```\n\n## End")
    #expect(content.headings.map(\.title) == ["Intro", "End"])
    #expect(content.sections.flatMap(\.blocks).contains(.mermaid("flowchart LR\nA-->B")))
  }

  @MainActor @Test func usesSystemManagedDocuments() {
    let model = PreviewDocumentModel(text: "# iPad", fileURL: nil)
    #expect(model.reloadState == .documentManaged)
  }
}
