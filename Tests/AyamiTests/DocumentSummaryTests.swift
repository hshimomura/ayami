import Foundation
import Testing
@testable import Ayami

struct SummaryInputTests {
  @Test func chunksWithoutDroppingAnyJapaneseOrEmoji() throws {
    let source = String(repeating: "あやみ📖 Markdown\n", count: 150)
    let chunks = try SummaryInput.chunks(source)
    #expect(chunks.count > 1)
    #expect(chunks.allSatisfy { $0.count <= 800 })
    #expect(chunks.joined() == source)
  }

  @Test func rejectsEmptyAndOversizedInput() {
    #expect(throws: SummaryError.self) { try SummaryInput.chunks(" \n\t") }
    #expect(throws: SummaryError.self) { try SummaryInput.chunks(String(repeating: "a", count: 32_001)) }
  }

  @MainActor @Test func reportsActualAvailabilityWithoutGenerating() {
    #expect(!DocumentSummary.availability().message.isEmpty)
  }

  @MainActor
  @Test(.enabled(if: ProcessInfo.processInfo.environment["AYAMI_TEST_LOCAL_AI"] == "1"))
  func nativeModelSummarizesOnlyThePublicSample() async throws {
    #expect(DocumentSummary.availability(language: "ja") == .available)
    let source = """
      # AYAMI_LAB の動作試験
      あやみ1.4は読み取り専用のMarkdownビューアーです。
      外部のサーバーへ文書を送信しません。文字サイズは80%から160%まで変更できます。
      Mermaid図を含む文書をPDFへ保存できます。元のMarkdownファイルは書き換えません。
      """
    let result = try await DocumentSummary.generate(source, language: "ja")
    #expect(result.count > 20)
    #expect(result.contains("1.4") || result.contains("Markdown"))
    #expect(result.contains("PDF") || result.contains("Mermaid"))
    if let path = ProcessInfo.processInfo.environment["AYAMI_QA_OUTPUT"] {
      let directory = URL(filePath: path, directoryHint: .isDirectory)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try result.write(to: directory.appending(path: "native-ai-summary-ja.txt"), atomically: true, encoding: .utf8)
    }
  }
}
