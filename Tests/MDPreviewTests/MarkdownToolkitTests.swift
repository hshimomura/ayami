import Foundation
import Testing
@testable import MDPreview

// Shared coverage runs against the actual Textual/Foundation parser on all platforms.
@MainActor
struct MarkdownToolkitTests {
  @Test func preservesJapaneseFormattingLinksTablesAndCode() throws {
    let source = """
      # 日本語の見出し

      **強調**と[リンク](https://example.com)。

      `<br>`

      | 項目 | 値 |
      | --- | --- |
      | 本文 | 読む |
      """
    let parsed = try HTMLBreakMarkdownParser().attributedString(for: source)
    let text = String(parsed.characters)
    #expect(text.contains("日本語の見出し"))
    #expect(text.contains("<br>"))
    #expect(text.contains("本文"))
    #expect(parsed.runs.contains { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true })
    #expect(parsed.runs.contains { $0.inlinePresentationIntent?.contains(.code) == true })
    #expect(parsed.runs.contains { $0.link?.absoluteString == "https://example.com" })
    #expect(parsed.runs.contains { $0.presentationIntent != nil })
  }

  @Test func convertsBreakTagsWithoutDamagingCodeOrEmphasis() throws {
    let parsed = try HTMLBreakMarkdownParser().attributedString(for: "**前**<BR />後と`<br>`")
    #expect(String(parsed.characters) == "前\n後と<br>")
    #expect(parsed.runs.contains { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true })
    #expect(parsed.runs.contains { $0.inlinePresentationIntent?.contains(.code) == true })
  }
}
