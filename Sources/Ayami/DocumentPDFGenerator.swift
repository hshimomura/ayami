import CoreGraphics
import CoreText
import Foundation

enum OutputPaper: String, CaseIterable, Identifiable {
  case a4 = "A4", letter = "Letter"
  var id: String { rawValue }
  var size: CGSize {
    switch self {
    case .a4: CGSize(width: 595.28, height: 841.89)
    case .letter: CGSize(width: 612, height: 792)
    }
  }
}

struct GeneratedPDF {
  let data: Data
  let pageCount: Int
  let diagramCount: Int
  let warnings: [String]
}

@MainActor
enum DocumentPDFGenerator {
  static func generate(markdown: String, title: String, paper: OutputPaper = .a4) async throws -> GeneratedPDF {
    try Task.checkCancellation()
    let blocks = try OutputDocument.blocks(markdown)
    let writer = try PDFPageWriter(title: title, paper: paper)
    let renderer = MermaidPDFRenderer()
    defer { renderer.close() }
    var diagrams = 0
    var warnings: [String] = []
    for block in blocks {
      try Task.checkCancellation()
      switch block {
      case let .heading(text, level):
        try writer.text(OutputTextStyle.text(text, size: [24, 19, 16, 13.5, 12, 11.5][level - 1], bold: true), keepWithNext: true)
      case let .paragraph(text): try writer.text(OutputTextStyle.text(text))
      case let .list(text): try writer.text(OutputTextStyle.text(text), inset: 8)
      case let .quote(text): try writer.text(OutputTextStyle.text("│ " + text, gray: true), inset: 12)
      case let .code(text, language):
        if let language { try writer.text(OutputTextStyle.text(language, size: 8.5, gray: true), keepWithNext: true) }
        try writer.text(OutputTextStyle.text(text.isEmpty ? " " : text, size: 10, code: true))
      case let .table(rows): try writer.table(rows)
      case .rule: try writer.rule()
      case let .mermaid(source):
        do {
          let data = try await renderer.render(source)
          try writer.diagram(data)
          diagrams += 1
        } catch is CancellationError { throw CancellationError() }
        catch {
          warnings.append(String(localized: "A Mermaid diagram could not be rendered and is shown as source."))
          try writer.text(OutputTextStyle.text(String(localized: "Mermaid diagram unavailable"), bold: true), keepWithNext: true)
          try writer.text(OutputTextStyle.text(source, size: 10, code: true))
        }
      }
    }
    return GeneratedPDF(data: writer.finish(), pageCount: writer.pageCount, diagramCount: diagrams, warnings: warnings)
  }
}

private final class PDFPageWriter {
  private let bytes = NSMutableData()
  private let context: CGContext
  private let size: CGSize
  private let title: String
  private let margin: CGFloat = 42
  private var top: CGFloat = 0
  private(set) var pageCount = 0
  private var finished = false
  private var width: CGFloat { size.width - margin * 2 }
  private var available: CGFloat { top - 52 }
  private var fullHeight: CGFloat { size.height - margin - 52 }

  init(title: String, paper: OutputPaper) throws {
    size = paper.size
    self.title = String(title.prefix(100))
    var bounds = CGRect(origin: .zero, size: paper.size)
    guard let consumer = CGDataConsumer(data: bytes as CFMutableData),
      let pdf = CGContext(consumer: consumer, mediaBox: &bounds, [
        kCGPDFContextTitle as String: title,
        kCGPDFContextCreator as String: "Ayami",
      ] as CFDictionary) else { throw OutputError.renderingFailed }
    context = pdf
    try nextPage()
  }

  deinit { if !finished { context.closePDF() } }

  private func nextPage() throws {
    guard pageCount < 500 else { throw OutputError.tooManyPages }
    if pageCount > 0 { endPage() }
    context.beginPDFPage(nil)
    pageCount += 1
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(origin: .zero, size: size))
    top = size.height - margin
    drawLine(OutputTextStyle.text(title, size: 8, gray: true), x: margin, y: size.height - 24)
  }

  private func endPage() {
    let label = OutputTextStyle.text("\(pageCount)", size: 8, gray: true)
    let line = CTLineCreateWithAttributedString(label)
    let lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
    drawLine(label, x: (size.width - lineWidth) / 2, y: 25)
    context.endPDFPage()
  }

  func text(_ text: NSAttributedString, inset: CGFloat = 0, keepWithNext: Bool = false) throws {
    guard text.length > 0 else { return }
    if available < (keepWithNext ? 70 : 24) { try nextPage() }
    let setter = CTFramesetterCreateWithAttributedString(text)
    var offset = 0
    while offset < text.length {
      if available < 20 { try nextPage() }
      let frame = CTFramesetterCreateFrame(setter, CFRange(location: offset, length: 0),
        CGPath(rect: CGRect(x: margin + inset, y: 52, width: width - inset, height: available), transform: nil), nil)
      let visible = CTFrameGetVisibleStringRange(frame)
      guard visible.length > 0 else { throw OutputError.renderingFailed }
      context.textMatrix = .identity
      CTFrameDraw(frame, context)
      let used = CTFramesetterSuggestFrameSizeWithConstraints(setter, visible, nil,
        CGSize(width: width - inset, height: .greatestFiniteMagnitude), nil).height
      top -= min(available, ceil(used)) + 9
      offset += visible.length
      if offset < text.length { try nextPage() }
    }
  }

  func table(_ rows: [[String]]) throws {
    guard let header = rows.first else { return }
    let columns = rows.map(\.count).max() ?? header.count
    guard columns > 0 else { return }
    let columnWidth = width / CGFloat(columns)
    func drawRow(_ row: [String], header: Bool) throws {
      let cells = (0..<columns).map { index in
        OutputTextStyle.text(index < row.count ? row[index] : "", size: 10.5, bold: header)
      }
      let heights = cells.map { value in
        CTFramesetterSuggestFrameSizeWithConstraints(CTFramesetterCreateWithAttributedString(value),
          CFRange(location: 0, length: 0), nil,
          CGSize(width: max(1, columnWidth - 12), height: .greatestFiniteMagnitude), nil).height
      }
      let height = ceil(heights.max() ?? 12) + 14
      // Oversized cells remain selectable and are paginated as text, never clipped.
      if height > fullHeight || columns > 12 {
        try text(OutputTextStyle.text(row.joined(separator: " | "), size: 10.5, bold: header))
        return
      }
      if height > available { try nextPage() }
      for (index, cell) in cells.enumerated() {
        let box = CGRect(x: margin + CGFloat(index) * columnWidth, y: top - height, width: columnWidth, height: height)
        context.setFillColor(CGColor(gray: header ? 0.94 : 1, alpha: 1))
        context.fill(box)
        context.setStrokeColor(CGColor(gray: 0.78, alpha: 1))
        context.setLineWidth(0.5)
        context.stroke(box)
        let frame = CTFramesetterCreateFrame(CTFramesetterCreateWithAttributedString(cell), CFRange(location: 0, length: 0),
          CGPath(rect: box.insetBy(dx: 6, dy: 6), transform: nil), nil)
        CTFrameDraw(frame, context)
      }
      top -= height
    }
    try drawRow(header, header: true)
    for row in rows.dropFirst() {
      let estimate = row.map {
        CTFramesetterSuggestFrameSizeWithConstraints(CTFramesetterCreateWithAttributedString(OutputTextStyle.text($0, size: 10.5)),
          CFRange(location: 0, length: 0), nil, CGSize(width: max(1, columnWidth - 12), height: .greatestFiniteMagnitude), nil).height
      }.max() ?? 12
      if estimate + 14 > available, estimate + 14 <= fullHeight {
        try nextPage()
        try drawRow(header, header: true)
      }
      try drawRow(row, header: false)
    }
    top -= 12
  }

  func diagram(_ data: Data) throws {
    guard let provider = CGDataProvider(data: data as CFData), let document = CGPDFDocument(provider),
      let page = document.page(at: 1) else { throw OutputError.renderingFailed }
    let bounds = page.getBoxRect(.mediaBox)
    guard bounds.width > 0, bounds.height > 0 else { throw OutputError.renderingFailed }
    let scale = min(width / bounds.width, fullHeight / bounds.height, 1)
    let height = bounds.height * scale
    if height > available { try nextPage() }
    let rect = CGRect(x: margin + (width - bounds.width * scale) / 2, y: top - height,
      width: bounds.width * scale, height: height)
    context.saveGState()
    context.concatenate(page.getDrawingTransform(.mediaBox, rect: rect, rotate: 0, preserveAspectRatio: true))
    context.drawPDFPage(page)
    context.restoreGState()
    top -= height + 14
  }

  func rule() throws {
    if available < 24 { try nextPage() }
    context.setStrokeColor(CGColor(gray: 0.7, alpha: 1))
    context.move(to: CGPoint(x: margin, y: top - 6))
    context.addLine(to: CGPoint(x: size.width - margin, y: top - 6))
    context.strokePath()
    top -= 20
  }

  private func drawLine(_ text: NSAttributedString, x: CGFloat, y: CGFloat) {
    context.saveGState()
    context.clip(to: CGRect(x: margin, y: 0, width: width, height: size.height))
    context.textMatrix = .identity
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(CTLineCreateWithAttributedString(text), context)
    context.restoreGState()
  }

  func finish() -> Data {
    endPage()
    context.closePDF()
    finished = true
    return bytes as Data
  }
}
