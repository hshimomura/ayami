import Foundation
import Testing
@testable import Ayami

struct TextDocumentTests {
  @Test func decodesUTF8BOMUTF16UTF32AndJapaneseSource() throws {
    let source = "日本語のソース\nint main(void) { return 0; }\n"
    for encoding in [String.Encoding.utf8, .utf16, .utf32, .shiftJIS] {
      let data = try #require(source.data(using: encoding))
      #expect(try TextFileContent.decode(data) == source)
    }
    #expect(try TextFileContent.decode(Data([0xEF, 0xBB, 0xBF]) + Data(source.utf8)) == source)
    #expect(try TextFileContent.decode(Data()) == "")
    #expect(throws: TextFileError.self) { try TextFileContent.decode(Data([0, 1, 2, 255])) }
  }

  @Test func choosesRenderingByFileExtensionAndPreservesPlainOutput() throws {
    #expect(DocumentFormat.format(for: URL(filePath: "/tmp/README.MD")) == .markdown)
    #expect(DocumentFormat.format(for: URL(filePath: "/tmp/report.html")) == .html)
    for ext in ["txt", "json", "c", "log", "custom"] {
      let url = URL(filePath: "/tmp/file." + ext)
      #expect(DocumentFormat.format(for: url) == .plainText)
      let source = "# Literal heading\n```\n日本語の原文"
      #expect(try OutputDocument.blocks(DocumentFormat.outputSource(source, url: url)) == [.code(source, nil)])
    }
  }

  @Test func documentLinkDestinationDefaultsToTabsAndPersistsWindowPreference() throws {
    let suite = "AyamiLinkPreferences-" + UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    #expect(DocumentLinkDestination.resolved(defaults.string(forKey: ReadingPreferences.linkDestinationKey)) == .tab)
    defaults.set("window", forKey: ReadingPreferences.linkDestinationKey)
    #expect(DocumentLinkDestination.resolved(defaults.string(forKey: ReadingPreferences.linkDestinationKey)) == .window)
    #expect(DocumentLinkDestination.resolved("invalid") == .tab)
  }
}
