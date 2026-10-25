import Foundation
import Testing
@testable import Ayami

@MainActor
@Suite(.serialized)
struct QuickLookHTMLTests {
  @Test func keepsLongDocumentsContinuousAndEscapesActiveContent() async throws {
    let paragraphs = (1...100).map { "本文-\($0) **強調**" }.joined(separator: "\n\n")
    let output = try await QuickLookHTMLRenderer.render(
      markdown: "# 読む\n\n" + paragraphs + "\n\n<script>alert(1)</script>\n\n3. Third\n4. Fourth",
      title: "<unsafe title>"
    )
    let html = try #require(String(data: output.data, encoding: .utf8))
    #expect(html.contains("本文-1 "))
    #expect(html.contains("本文-100 "))
    #expect(html.contains("<strong>強調</strong>"))
    #expect(html.contains("&lt;unsafe title&gt;"))
    #expect(!html.contains("<script>"))
    #expect(!html.contains("page-break"))
    #expect(!html.contains("break-after"))
    #expect(html.contains("<ol start=\"4\">"))
    #expect(output.diagrams.isEmpty)
  }

  @Test func suppliesLocalVectorDiagramAttachments() async throws {
    let output = try await QuickLookHTMLRenderer.render(
      markdown: "```mermaid\nflowchart LR\n A[Markdown] --> B[ContinuousDiagram]\n```", title: "Diagram"
    )
    let html = try #require(String(data: output.data, encoding: .utf8))
    let svg = try #require(output.diagrams["diagram-0.svg"])
    let content = try #require(String(data: svg, encoding: .utf8))
    #expect(html.contains("cid:diagram-0.svg"))
    #expect(!html.contains("flowchart LR"))
    #expect(content.contains("<svg"))
    #expect(content.contains("ContinuousDiagram"))
  }

  @Test func preservesInvalidDiagramSource() async throws {
    let output = try await QuickLookHTMLRenderer.render(
      markdown: "```mermaid\ninvalid diagram <script>\n```", title: "Invalid"
    )
    let html = try #require(String(data: output.data, encoding: .utf8))
    #expect(output.diagrams.isEmpty)
    #expect(html.contains("invalid diagram &lt;script&gt;"))
    #expect(!html.contains("<script>"))
  }
}
