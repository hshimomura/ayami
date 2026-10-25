import CoreText
import Foundation
import PDFKit
import Testing
@testable import Ayami

struct OutputDocumentTests {
  @Test func usesMarkdownFileNameForPDFAndPrintJob() {
    #expect(OutputDocument.title(for: URL(filePath: "/Documents/Example_Report.md")) == "Example_Report")
    #expect(OutputDocument.title(for: nil) == "Markdown")
  }
  @Test func parsesTablesFencesAndLiteralHTMLSafely() throws {
    let source = "# Output\n\n| Name | Value |\n| --- | --- |\n| `a|b` | c\\|d |\n\n```swift\n<br>\n```\n\n~~~mermaid\nflowchart LR\nA-->B\n~~~"
    let blocks = try OutputDocument.blocks(source)
    #expect(blocks.contains(.heading("Output", 1)))
    #expect(blocks.contains(.table([["Name", "Value"], ["`a|b`", "c\\|d"]])))
    #expect(blocks.contains(.code("<br>", "swift")))
    #expect(blocks.contains(.mermaid("flowchart LR\nA-->B")))
    #expect(OutputTextStyle.text("a<br>b `c<br>d`").string == "a\nb c<br>d")
  }

  @Test func limitsInputAndPreservesUnclosedFences() throws {
    #expect(throws: OutputError.self) { try OutputDocument.blocks(String(repeating: "x", count: OutputDocument.maximumBytes + 1)) }
    #expect(try OutputDocument.blocks("```swift\nlet value = 1") == [.code("let value = 1", "swift")])
  }

  @Test func pdfFileDocumentKeepsExactData() throws {
    let data = Data("%PDF-test".utf8)
    let document = PDFExportDocument(data: data)
    #expect(document.data == data)
    #expect(PDFExportDocument.readableContentTypes.first?.identifier == "com.adobe.pdf")
  }
}

@MainActor
@Suite(.serialized)
struct DocumentPDFTests {
  @Test func producesSelectableJapaneseTextAndVectorMermaid() async throws {
    let source = """
      # あやみ 印刷テスト

      日本語を読み取り専用で印刷します。**Bold text** and `code`.

      | 名前 | 値 |
      | --- | --- |
      | あやみ | 1.4 |

      ```mermaid
      flowchart LR
        A[Markdown] --> B[PrintedDiagram]
      ```

      ## 終了

      Original document remains unchanged.
      """
    let output = try await DocumentPDFGenerator.generate(markdown: source, title: "Ayami 1.4 QA")
    let pdf = try #require(PDFDocument(data: output.data))
    let text = pdf.string ?? ""
    #expect(pdf.pageCount == output.pageCount)
    #expect(text.contains("あやみ"))
    #expect(text.contains("PrintedDiagram"))
    #expect(!text.contains("flowchart LR"))
    #expect(text.contains("Original document remains unchanged."))
    #expect(output.diagramCount == 1)
    #expect(output.warnings.isEmpty)
    try saveQA(output.data, name: "selectable-japanese-mermaid.pdf")
  }

  @Test func paginatesLongTextAndRepeatsTableHeaders() async throws {
    let rows = (1...100).map { "| Row-\($0) | 日本語の表を改ページしても欠落させません。 |" }.joined(separator: "\n")
    let source = "# Table\n\n| RepeatedHeader | Value |\n| --- | --- |\n" + rows + "\n\n" + String(repeating: "長い文書と selectable text を確認します。\n\n", count: 90)
    let output = try await DocumentPDFGenerator.generate(markdown: source, title: "Pagination", paper: .letter)
    let pdf = try #require(PDFDocument(data: output.data))
    let text = pdf.string ?? ""
    #expect(pdf.pageCount > 3)
    #expect(text.contains("Row-1"))
    #expect(text.contains("Row-100"))
    #expect(text.components(separatedBy: "RepeatedHeader").count > 2)
    #expect(abs((pdf.page(at: 0)?.bounds(for: .mediaBox).width ?? 0) - 612) < 1)
    // Extracted text can exist even when leaked drawing state clips it away.
    // Verify actual ink in the body of every rasterized page as well.
    let provider = try #require(CGDataProvider(data: output.data as CFData))
    let drawing = try #require(CGPDFDocument(provider))
    for pageIndex in 1...drawing.numberOfPages {
      let page = try #require(drawing.page(at: pageIndex))
      #expect(try bodyInkPixels(page) > 100, "Missing visible body on page \(pageIndex)")
    }
    try saveQA(output.data, name: "letter-pagination-table.pdf")
  }

  @Test func showsExplicitFallbackForInvalidDiagram() async throws {
    let output = try await DocumentPDFGenerator.generate(markdown: "```mermaid\nnot a valid diagram\n```", title: "Invalid")
    #expect(output.diagramCount == 0)
    #expect(output.warnings.count == 1)
    #expect(PDFDocument(data: output.data)?.string?.contains("not a valid diagram") == true)
  }

  @Test func exportsSixDiagramFamiliesWithoutSourceFallback() async throws {
    let diagrams = [
      "flowchart LR\n A[文書] --> B[読む]",
      "sequenceDiagram\n Alice->>Bob: Markdown",
      "classDiagram\n Reader --> Document",
      "stateDiagram-v2\n [*] --> Reading",
      "erDiagram\n READER ||--o{ DOCUMENT : reads",
      "mindmap\n root((Markdown))\n  見出し\n  本文",
    ]
    let source = diagrams.map { "```mermaid\n\($0)\n```" }.joined(separator: "\n\n")
    let output = try await DocumentPDFGenerator.generate(markdown: source, title: "Six diagram families")
    #expect(output.diagramCount == diagrams.count)
    #expect(output.warnings.isEmpty)
    let pdf = try #require(PDFDocument(data: output.data))
    #expect(pdf.pageCount >= 1)
    #expect(pdf.string?.contains("Alice") == true)
    #expect(pdf.string?.contains("Reader") == true)
  }

  @Test func cancelsBeforeDoingAnyRendering() async throws {
    let task = Task { @MainActor in
      try Task.checkCancellation()
      return try await DocumentPDFGenerator.generate(markdown: "# Cancel", title: "Cancel")
    }
    task.cancel()
    do { _ = try await task.value; Issue.record("Cancelled output unexpectedly succeeded") }
    catch is CancellationError { }
  }

  @Test func handlesEmptyDocuments() async throws {
    let output = try await DocumentPDFGenerator.generate(markdown: "", title: "Empty")
    #expect(output.pageCount == 1)
    #expect(PDFDocument(data: output.data)?.string?.contains("empty") == true)
  }

  private func saveQA(_ data: Data, name: String) throws {
    let directory: URL
    if let path = ProcessInfo.processInfo.environment["AYAMI_QA_OUTPUT"] {
      directory = URL(filePath: path, directoryHint: .isDirectory)
    } else {
      #if os(iOS)
      directory = FileManager.default.temporaryDirectory.appending(path: "Ayami-QA-1.4", directoryHint: .isDirectory)
      #else
      return
      #endif
    }
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    try data.write(to: directory.appending(path: name))
  }

  private func bodyInkPixels(_ page: CGPDFPage) throws -> Int {
    let size = page.getBoxRect(.mediaBox).size
    let width = Int(size.width), height = Int(size.height)
    let context = try #require(CGContext(data: nil, width: width, height: height,
      bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(origin: .zero, size: size))
    context.drawPDFPage(page)
    let pixels = try #require(context.data?.assumingMemoryBound(to: UInt8.self))
    var ink = 0
    for y in 40..<(height - 40) {
      for x in 40..<(width - 40) {
        let offset = y * width * 4 + x * 4
        if pixels[offset] < 180 && pixels[offset + 1] < 180 && pixels[offset + 2] < 180 { ink += 1 }
      }
    }
    return ink
  }
}
