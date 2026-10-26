import Foundation
import SwiftUI
import UniformTypeIdentifiers

extension UTType {
  static let markdownDocument = UTType(
    importedAs: "net.daringfireball.markdown",
    conformingTo: .utf8PlainText
  )
}

struct MarkdownDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.markdownDocument, .text, .json, .sourceCode, .data]

  let text: String

  init(text: String) {
    self.text = text
  }

  init(configuration: ReadConfiguration) throws {
    guard
      let data = configuration.file.regularFileContents
    else {
      throw CocoaError(.fileReadCorruptFile)
    }

    self.text = try TextFileContent.decode(data)
  }

  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: Data(text.utf8))
  }
}

enum DocumentFormat: String {
  case markdown
  case html
  case plainText

  static func format(for url: URL?) -> Self {
    guard let url else { return .markdown }
    switch url.pathExtension.lowercased() {
    case "md", "markdown": return .markdown
    case "html", "htm": return .html
    default: return .plainText
    }
  }

  static func language(for url: URL?) -> String {
    let ext = url?.pathExtension.lowercased() ?? ""
    let aliases = ["h": "c", "cc": "cpp", "cxx": "cpp", "hpp": "cpp", "js": "javascript",
      "ts": "typescript", "py": "python", "rb": "ruby", "yml": "yaml", "sh": "bash"]
    return aliases[ext] ?? ext
  }

  static func outputSource(_ source: String, url: URL?) -> String {
    guard format(for: url) != .markdown else { return source }
    // Preserve literal text in the separate Markdown-based PDF pipeline.
    let fence = String(repeating: "`", count: max(3, source.components(separatedBy: .newlines).map {
      $0.trimmingCharacters(in: .whitespaces).prefix(while: { $0 == "`" }).count + 1
    }.max() ?? 3))
    return "\(fence)\n\(source)\n\(fence)"
  }
}

enum TextFileContent {
  static let maximumBytes = 20 * 1024 * 1024

  static func read(_ url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    return try decode(handle.read(upToCount: maximumBytes + 1) ?? Data())
  }

  static func decode(_ data: Data) throws -> String {
    guard data.count <= maximumBytes else { throw TextFileError.tooLarge }
    let text: String?
    if data.starts(with: [0xFF, 0xFE, 0x00, 0x00]) || data.starts(with: [0x00, 0x00, 0xFE, 0xFF]) {
      text = String(data: data, encoding: .utf32)
    } else if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
      text = String(data: data, encoding: .utf16)
    } else if data.starts(with: [0xEF, 0xBB, 0xBF]) {
      text = String(data: data.dropFirst(3), encoding: .utf8)
    } else {
      text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .shiftJIS)
    }
    guard let text, !text.unicodeScalars.contains(where: {
      ($0.value < 32 && ![9, 10, 12, 13].contains($0.value)) || $0.value == 127
    }) else { throw TextFileError.notText }
    return text
  }
}

enum TextFileError: LocalizedError {
  case notText
  case tooLarge

  var errorDescription: String? {
    switch self {
    case .notText: String(localized: "This file could not be read as text. Use UTF-8, UTF-16, or Shift JIS.")
    case .tooLarge: String(localized: "Text files up to 20 MB can be opened.")
    }
  }
}
