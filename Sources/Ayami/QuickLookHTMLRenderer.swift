import Foundation

struct GeneratedQuickLookHTML: Sendable {
  let data: Data
  let diagrams: [String: Data]
}

@MainActor
enum QuickLookHTMLRenderer {
  static func render(markdown: String, title: String) async throws -> GeneratedQuickLookHTML {
    let blocks = try OutputDocument.blocks(markdown)
    var fragments: [String] = []
    var diagrams: [String: Data] = [:]
    var renderer: MermaidPDFRenderer?
    defer { renderer?.close() }
    for block in blocks {
      try Task.checkCancellation()
      if case let .mermaid(source) = block {
        do {
          if renderer == nil { renderer = MermaidPDFRenderer() }
          let svg = try await renderer!.renderSVG(source)
          let name = "diagram-\(diagrams.count).svg"
          diagrams[name] = svg
          fragments.append("<figure><img src=\"cid:\(name)\" alt=\"Mermaid diagram\"></figure>")
        } catch is CancellationError { throw CancellationError() }
        catch {
          fragments.append("<p>\(escape(String(localized: "Mermaid diagram unavailable")))</p><pre><code>\(escape(source))</code></pre>")
        }
      } else {
        fragments.append(render(block))
      }
    }
    let body = fragments.joined(separator: "\n")
    let html = """
      <!doctype html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src cid: data:;">
        <title>\(escape(title))</title>
        <style>
          :root { color-scheme: light dark; font: 16px/1.7 -apple-system, BlinkMacSystemFont, sans-serif; }
          body { box-sizing: border-box; max-width: 960px; margin: 0 auto; padding: 32px 40px 56px; color: CanvasText; background: Canvas; overflow-wrap: anywhere; }
          h1, h2, h3, h4, h5, h6 { line-height: 1.3; margin: 1.35em 0 .55em; }
          h1 { font-size: 2em; } h2 { font-size: 1.6em; } h3 { font-size: 1.3em; }
          p, ul, ol, blockquote, pre, table, hr { margin: .8em 0; }
          blockquote { margin-left: 0; padding: .15em 1em; border-left: 3px solid color-mix(in srgb, CanvasText 25%, transparent); color: color-mix(in srgb, CanvasText 78%, transparent); }
          pre, code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
          pre { padding: 14px 16px; border-radius: 8px; background: color-mix(in srgb, CanvasText 7%, transparent); white-space: pre-wrap; }
          :not(pre) > code { padding: .12em .35em; border-radius: 4px; background: color-mix(in srgb, CanvasText 9%, transparent); }
          table { border-collapse: collapse; width: 100%; }
          th, td { border: 1px solid color-mix(in srgb, CanvasText 20%, transparent); padding: 8px 10px; text-align: left; vertical-align: top; }
          th { background: color-mix(in srgb, CanvasText 6%, transparent); }
          figure { margin: 1em 0; padding: 14px; border-radius: 8px; background: white; }
          img { display: block; max-width: 100%; height: auto; margin: auto; }
          @media (max-width: 600px) { body { padding: 22px 18px 40px; } }
        </style>
      </head>
      <body>
      \(body)
      </body>
      </html>
      """
    return GeneratedQuickLookHTML(data: Data(html.utf8), diagrams: diagrams)
  }

  private static func render(_ block: OutputBlock) -> String {
    switch block {
    case let .heading(text, level):
      let level = min(max(level, 1), 6)
      return "<h\(level)>\(inline(text))</h\(level)>"
    case let .paragraph(text): return "<p>\(inline(text))</p>"
    case let .list(text):
      if let item = text.range(of: #"^\d+[.)]\s+"#, options: .regularExpression) {
        let start = text.prefix(while: \.isNumber)
        return "<ol start=\"\(start)\"><li>\(inline(String(text[item.upperBound...])))</li></ol>"
      }
      let content = text.replacingOccurrences(of: #"^•\s*"#, with: "", options: .regularExpression)
      return "<ul><li>\(inline(content))</li></ul>"
    case let .quote(text): return "<blockquote><p>\(inline(text))</p></blockquote>"
    case let .code(text, language):
      let label = language.map { "<div><small>\(escape($0))</small></div>" } ?? ""
      return "\(label)<pre><code>\(escape(text))</code></pre>"
    case let .table(rows):
      guard let header = rows.first else { return "" }
      let head = "<thead><tr>" + header.map { "<th>\(inline($0))</th>" }.joined() + "</tr></thead>"
      let body = rows.dropFirst().map { row in
        "<tr>" + row.map { "<td>\(inline($0))</td>" }.joined() + "</tr>"
      }.joined()
      return "<table>\(head)<tbody>\(body)</tbody></table>"
    case .rule: return "<hr>"
    case let .mermaid(source): return "<pre><code>\(escape(source))</code></pre>"
    }
  }

  private static func inline(_ source: String) -> String {
    guard let parsed = try? AttributedString(markdown: source, options: .init(
      interpretedSyntax: .inlineOnlyPreservingWhitespace,
      failurePolicy: .returnPartiallyParsedIfPossible
    )) else { return escape(source) }

    return parsed.runs.map { run in
      let value = String(parsed[run.range].characters)
      if run.inlinePresentationIntent?.contains(.inlineHTML) == true {
        let tag = value.filter { !$0.isWhitespace }.lowercased()
        if tag == "<br>" || tag == "<br/>" { return "<br>" }
      }
      var content = escape(value)
      if let intent = run.inlinePresentationIntent {
        if intent.contains(.code) { content = "<code>\(content)</code>" }
        if intent.contains(.emphasized) { content = "<em>\(content)</em>" }
        if intent.contains(.stronglyEmphasized) { content = "<strong>\(content)</strong>" }
        if intent.contains(.strikethrough) { content = "<del>\(content)</del>" }
      }
      if let link = run.link, ["http", "https", "mailto"].contains(link.scheme?.lowercased() ?? "") {
        content = "<a href=\"\(escape(link.absoluteString))\">\(content)</a>"
      }
      return content
    }.joined()
  }

  private static func escape(_ value: String) -> String {
    value
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "'", with: "&#39;")
  }
}
