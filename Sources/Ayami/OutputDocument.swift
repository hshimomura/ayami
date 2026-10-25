import Foundation

enum OutputBlock: Equatable, Sendable {
  case heading(String, Int)
  case paragraph(String)
  case list(String)
  case quote(String)
  case code(String, String?)
  case table([[String]])
  case rule
  case mermaid(String)
}

enum OutputDocument {
  static let maximumBytes = 1_048_576

  static func title(for url: URL?) -> String {
    let name = url?.deletingPathExtension().lastPathComponent ?? "Markdown"
    return name.isEmpty ? "Markdown" : name
  }

  static func read(_ url: URL) throws -> String {
    let file = try FileHandle(forReadingFrom: url)
    defer { try? file.close() }
    let data = try file.read(upToCount: maximumBytes + 1) ?? Data()
    guard data.count <= maximumBytes else { throw OutputError.documentTooLarge }
    guard let text = String(data: data, encoding: .utf8) else {
      throw CocoaError(.fileReadInapplicableStringEncoding)
    }
    return text
  }

  static func blocks(_ source: String) throws -> [OutputBlock] {
    guard source.utf8.count <= maximumBytes else { throw OutputError.documentTooLarge }
    let lines = source.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
    var result: [OutputBlock] = []
    var paragraph: [String] = []
    var index = 0
    func flush() {
      if !paragraph.isEmpty { result.append(.paragraph(paragraph.joined(separator: " "))) }
      paragraph.removeAll(keepingCapacity: true)
    }
    while index < lines.count {
      let line = lines[index].trimmingCharacters(in: .whitespaces)
      index += 1
      if line.isEmpty { flush(); continue }
      if let marker = line.first, marker == "`" || marker == "~" {
        let count = line.prefix(while: { $0 == marker }).count
        if count >= 3 {
          flush()
          let language = line.dropFirst(count).trimmingCharacters(in: .whitespaces)
          var code: [String] = []
          while index < lines.count {
            let candidate = lines[index].trimmingCharacters(in: .whitespaces)
            index += 1
            if candidate.prefix(while: { $0 == marker }).count >= count,
              candidate.allSatisfy({ $0 == marker || $0.isWhitespace }) { break }
            code.append(lines[index - 1])
          }
          let body = code.joined(separator: "\n")
          if language.lowercased() == "mermaid" { result.append(.mermaid(body)) }
          else { result.append(.code(body, language.isEmpty ? nil : language)) }
          continue
        }
      }
      if index < lines.count, let cells = tableCells(line), isTableDivider(lines[index]) {
        flush()
        index += 1
        var rows = [cells]
        while index < lines.count, let row = tableCells(lines[index]) {
          rows.append(row)
          index += 1
        }
        result.append(.table(rows))
        continue
      }
      let level = line.prefix(while: { $0 == "#" }).count
      if (1...6).contains(level), line.dropFirst(level).first?.isWhitespace ?? true {
        flush()
        let title = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
          .replacingOccurrences(of: #"\s+#+\s*$"#, with: "", options: .regularExpression)
        result.append(.heading(title, level))
      } else if line == "---" || line == "***" || line == "___" {
        flush(); result.append(.rule)
      } else if line.hasPrefix(">") {
        flush(); result.append(.quote(String(line.dropFirst()).trimmingCharacters(in: .whitespaces)))
      } else if line.range(of: #"^([-+*]\s+|\d+[.)]\s+)"#, options: .regularExpression) != nil {
        flush()
        let value = line.replacingOccurrences(of: #"^[-+*]\s+"#, with: "• ", options: .regularExpression)
        result.append(.list(value))
      } else {
        paragraph.append(line)
      }
    }
    flush()
    return result.isEmpty ? [.paragraph(String(localized: "This Markdown document is empty."))] : result
  }

  private static func tableCells(_ line: String) -> [String]? {
    let source = line.trimmingCharacters(in: .whitespaces)
    guard source.contains("|") else { return nil }
    var cells: [String] = [], cell = "", escaped = false, inCode = false
    for character in source {
      if escaped { cell.append(character); escaped = false; continue }
      if character == "\\" { escaped = true; cell.append(character); continue }
      if character == "`" { inCode.toggle() }
      if character == "|" && !inCode {
        cells.append(cell.trimmingCharacters(in: .whitespaces)); cell = ""
      } else { cell.append(character) }
    }
    cells.append(cell.trimmingCharacters(in: .whitespaces))
    if source.hasPrefix("|") { cells.removeFirst() }
    if source.hasSuffix("|") { cells.removeLast() }
    return cells.isEmpty ? nil : cells
  }

  private static func isTableDivider(_ line: String) -> Bool {
    guard let cells = tableCells(line), !cells.isEmpty else { return false }
    return cells.allSatisfy {
      $0.range(of: #"^:?-{3,}:?$"#, options: .regularExpression) != nil
    }
  }
}

enum OutputError: LocalizedError {
  case documentTooLarge, tooManyPages, renderingFailed, timedOut

  var errorDescription: String? {
    switch self {
    case .documentTooLarge: String(localized: "This prototype supports documents up to 1 MB.")
    case .tooManyPages: String(localized: "The document exceeds the 500-page output limit.")
    case .renderingFailed: String(localized: "The document could not be rendered.")
    case .timedOut: String(localized: "Rendering timed out. Please try a smaller diagram.")
    }
  }
}
