import Foundation
import SwiftUI
import Testing
import WebKit
@testable import Ayami

@MainActor
@Suite(.serialized)
struct ReaderRuntimeTests {
  #if os(macOS)
  @Test func removingMarksRepaintsWithoutReselectingTheText() async throws {
    let source = "# Review\n\nFirst highlighted passage.\n\nSecond highlighted passage."
    let reader = try await ReaderHarness(source)
    defer { reader.close() }
    _ = NSApplication.shared
    let window = NSWindow(contentRect: reader.view.bounds, styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.title = "Ayami highlight repaint validation"
    window.contentView = reader.view
    window.orderFront(nil)
    defer { window.close() }
    func pinkPixels() async throws -> Int {
      let configuration = WKSnapshotConfiguration()
      configuration.rect = reader.view.bounds
      configuration.snapshotWidth = 450
      let image = try await reader.view.takeSnapshot(configuration: configuration)
      let cgImage = try #require(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
      let pixels = NSBitmapImageRep(cgImage: cgImage)
      var count = 0
      for y in 0..<pixels.pixelsHigh {
        for x in 0..<pixels.pixelsWide {
          guard let color = pixels.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
          if color.redComponent > color.greenComponent + 0.12,
            color.blueComponent > color.greenComponent + 0.04,
            color.redComponent > 0.5 { count += 1 }
        }
      }
      return count
    }
    func renderedPinkPixels(where matches: (Int) -> Bool) async throws -> Int {
      // Native status arrives before WebKit commits the next painted frame.
      // Observe the result without selecting, clicking, or scrolling the text.
      var count = 0
      for _ in 0..<20 {
        count = try await pinkPixels()
        if matches(count) { return count }
        try await Task.sleep(for: .milliseconds(50))
      }
      return count
    }
    #expect(try await pinkPixels() == 0)
    try await reader.select("First highlighted passage")
    reader.session.command("markSelection")
    try await reader.wait { reader.session.markCount == 1 }
    #expect(try await renderedPinkPixels(where: { $0 > 100 }) > 100)
    _ = try await reader.js("""
      (() => {
        const rect = [...CSS.highlights.get('ayami-pink')][0].getClientRects()[0];
        document.querySelector('p').dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: rect.x + 3, clientY: rect.y + rect.height / 2 }));
        return true;
      })()
      """)
    try await reader.wait { reader.session.hasActiveMark }
    reader.session.command("removeMark")
    try await reader.wait { reader.session.markCount == 0 }
    #expect(try await reader.js("CSS.highlights.get('ayami-pink').size + CSS.highlights.get('ayami-selected-mark').size") as? Int == 0)
    // No selection, click, or scroll is sent between removal and the snapshot.
    #expect(try await renderedPinkPixels(where: { $0 == 0 }) == 0)
    for passage in ["First highlighted passage", "Second highlighted passage"] {
      try await reader.select(passage)
      reader.session.command("markSelection")
      try await reader.wait { !reader.session.hasSelection }
    }
    try await reader.wait { reader.session.markCount == 2 }
    #expect(try await renderedPinkPixels(where: { $0 > 100 }) > 100)
    reader.session.command("clearMarks")
    try await reader.wait { reader.session.markCount == 0 }
    #expect(try await renderedPinkPixels(where: { $0 == 0 }) == 0)
    #expect(try await reader.js("document.querySelector('p').textContent") as? String == "First highlighted passage.")
  }
  #endif

  @Test func readsOneMiBOfTechnicalTextWithoutDroppingTheTail() async throws {
    let paragraph = "設計の前提とリトライの動作を確認します。A technical review paragraph.\n\n"
    let repetitions = 1_048_576 / paragraph.utf8.count
    let source = "# Large document\n\n" + String(repeating: paragraph, count: repetitions) + "\n\n終端-END15"
    let reader = try await ReaderHarness(source)
    defer { reader.close() }
    reader.session.find("終端-END15")
    try await reader.wait { reader.session.matchCount == 1 }
    #expect(try await reader.js("document.querySelector('article').textContent.endsWith('終端-END15\\n')") as? Bool == true)
    reader.session.find("設計")
    try await reader.wait { reader.session.matchCount == min(repetitions, 10000) }
  }

  @Test func searchesJapaneseAcrossFormattingCodeAndTablesAndTreatsQueryLiterally() async throws {
    let reader = try await ReaderHarness("""
      # Review
      日本語 **レビュー** と 日本語。a+b

      | Name | Value |
      | --- | --- |
      | Language | 日本語 |

      ```sh
      printf '日本語'
      ```
      """)
    defer { reader.close() }
    reader.session.find("日本語")
    try await reader.wait { reader.session.matchCount == 4 }
    reader.session.command("nextMatch", [1])
    try await reader.wait { reader.session.matchIndex == 1 }
    reader.session.command("nextMatch", [-1])
    try await reader.wait { reader.session.matchIndex == 0 }
    reader.session.find("日本語 レビュー")
    try await reader.wait { reader.session.matchCount == 1 }
    reader.session.find("a+b")
    try await reader.wait { reader.session.matchCount == 1 }
    reader.session.find("missing")
    try await reader.wait { reader.session.matchCount == 0 }
    #expect(try await reader.js("document.querySelector('.code-block code').textContent") as? String == "printf '日本語'\n")
    #expect(try await reader.js("document.querySelector('code .token') !== null") as? Bool == true)
  }

  @Test func marksAreTemporaryAndReanchorOnlyWhenOriginalPassageCanBeIdentified() async throws {
    let source = "# Review\n\n前提を確認する。重要な仕様です。\n\n別の段落。"
    let reader = try await ReaderHarness(source)
    defer { reader.close() }
    try await reader.select("重要な仕様")
    reader.session.command("markSelection")
    try await reader.wait { reader.session.markCount == 1 }
    #expect(try await reader.js("[...CSS.highlights.get('ayami-pink')][0].toString()") as? String == "重要な仕様")

    reader.render("# New section\n\n追加した文章。\n\n" + source)
    try await reader.wait { reader.session.headings.count == 2 }
    #expect(reader.session.markCount == 1)
    #expect(try await reader.js("[...CSS.highlights.get('ayami-pink')][0].toString()") as? String == "重要な仕様")
    reader.render(source.replacingOccurrences(of: "重要な仕様", with: "変更した仕様"))
    try await reader.wait { reader.session.markCount == 0 }
    #expect(reader.session.notice != nil)
    try await reader.select("変更した仕様")
    reader.session.command("markSelection")
    try await reader.wait { reader.session.markCount == 1 }
    reader.session.command("clearMarks")
    try await reader.wait { reader.session.markCount == 0 }

    let reopened = try await ReaderHarness(source)
    defer { reopened.close() }
    #expect(reopened.session.markCount == 0)
    #expect(reopened.view.configuration.websiteDataStore.isPersistent == false)
  }

  @Test func retainsReadingParagraphAfterInsertionAboveIt() async throws {
    let paragraphs = (0..<70).map { "段落\($0)：設計の前提を確認するための文章です。" }.joined(separator: "\n\n")
    let source = "# Long document\n\n" + paragraphs
    let reader = try await ReaderHarness(source)
    defer { reader.close() }
    reader.session.find("段落20")
    try await reader.wait { reader.session.matchCount == 1 }
    _ = try await reader.js("[...document.querySelectorAll('p')].find(p => p.textContent.startsWith('段落35：')).scrollIntoView(); true")
    let top = try #require(try await reader.js("[...document.querySelectorAll('p')].find(p => p.textContent.startsWith('段落35：')).getBoundingClientRect().top") as? Double)
    reader.render("# Inserted\n\n" + String(repeating: "追加した文章。\n\n", count: 15) + source)
    try await reader.wait { reader.session.headings.count == 2 }
    let restored = try #require(try await reader.js("[...document.querySelectorAll('p')].find(p => p.textContent.startsWith('段落35：')).getBoundingClientRect().top") as? Double)
    #expect(abs(top - restored) < 3)
  }

  @Test func escapesHTMLLoadsOnlyLocalImagesAndSupportsHeadingAnchors() async throws {
    let reader = try await ReaderHarness("""
      # 日本語の見出し
      # 日本語の見出し
      <script>window.__ayamiUntrustedScriptRan15 = true</script>

      A<br>B

      ![local](images/test.png)
      ![remote](https://example.invalid/tracker.png)
      [Related](docs/guide.md#section)
      """)
    defer { reader.close() }
    #expect(reader.session.headings.map(\.id) == ["reader-content-日本語の見出し", "reader-content-日本語の見出し-1"])
    #expect(try await reader.js("window.__ayamiUntrustedScriptRan15 !== true") as? Bool == true)
    #expect(try await reader.js("document.querySelectorAll('article script').length") as? Int == 0)
    #expect(try await reader.js("document.querySelectorAll('article br').length") as? Int == 1)
    #expect(try await reader.js("document.querySelectorAll('img[src^=\"https:\"]').length") as? Int == 0)
    #expect(try await reader.js("document.querySelector('img').getAttribute('src').startsWith('ayami-asset:')") as? Bool == true)
    _ = try await reader.js("document.querySelector('article a').click(); true")
    #expect(reader.links == ["docs/guide.md#section"])
    #expect(try await reader.js("window.reader.jump('日本語の見出し-1')") as? Bool == true)
  }

  @Test func expandsMermaidAndPreservesInvalidSource() async throws {
    let reader = try await ReaderHarness("""
      # Diagram
      ```mermaid
      flowchart LR
       A[Read] --> B[Review15]
      ```
      ```mermaid
      invalid diagram
      ```
      """)
    defer { reader.close() }
    try await reader.wait { reader.session.diagramsReady }
    #expect(try await reader.js("document.querySelectorAll('.diagram svg').length") as? Int == 1)
    #expect(try await reader.js("document.querySelectorAll('.diagram pre').length") as? Int == 1)
    _ = try await reader.js("document.querySelector('[data-expand]').click(); true")
    #expect(try await reader.js("document.querySelector('dialog').open") as? Bool == true)
    _ = try await reader.js("document.getElementById('diagram-plus').click(); true")
    #expect(try await reader.js("document.getElementById('diagram-scale').textContent") as? String == "125%")
    reader.session.command("closeDiagram")
    try await reader.waitJS("!document.querySelector('dialog').open")
  }

  @Test func rendersHTMLFormattingDetailsAndAnchorsWithoutDocumentScriptsOrForgedControls() async throws {
    let reader = try await ReaderHarness("""
      # HTML review

      <p id="intro" style="color: #c00; position:fixed; top:0" onclick="window.untrusted15=true">HTMLの<strong>強調</strong>です。</p>
      <details><summary>詳細</summary><h2 id="install">導入手順</h2><p>内部の確認事項</p></details>
      <table><tr><th>項目</th></tr><tr><td>HTMLの表</td></tr></table>
      <a href="docs/guide.txt">テキスト資料</a>
      <button data-copy data-reader-ui onclick="window.untrusted15=true">Fake copy</button>
      <div id="diagram-dialog" class="diagram" data-source="evil">Content</div>
      <script>window.untrusted15=true</script>
      <iframe srcdoc="<script>window.untrusted15=true</script>"></iframe>
      <a href="javascript:alert(1)">Unsafe</a>

      ```html
      <strong>This stays source</strong>
      ```
      """)
    defer { reader.close() }
    #expect(try await reader.js("document.querySelector('article p strong').textContent") as? String == "強調")
    #expect(try await reader.js("document.querySelector('article p').style.color !== '' && document.querySelector('article p').style.position === ''") as? Bool == true)
    #expect(try await reader.js("document.querySelectorAll('article script,article iframe,article [onclick],article a[href^=\"javascript:\"]').length") as? Int == 0)
    #expect(try await reader.js("document.querySelectorAll('#diagram-dialog').length") as? Int == 1)
    #expect(try await reader.js("document.querySelectorAll('article [data-copy]').length") as? Int == 1)
    #expect(try await reader.js("document.querySelector('article pre code').textContent") as? String == "<strong>This stays source</strong>\n")
    #expect(try await reader.js("window.untrusted15 !== true") as? Bool == true)
    #expect(try await reader.js("document.querySelector('details').open") as? Bool == false)
    reader.session.find("内部の確認事項")
    try await reader.wait { reader.session.matchCount == 1 }
    #expect(try await reader.js("document.querySelector('details').open") as? Bool == true)
    #expect(try await reader.js("window.reader.jump('install')") as? Bool == true)
    _ = try await reader.js("document.querySelector('article a').click(); true")
    #expect(reader.links == ["docs/guide.txt"])
  }

  @Test(arguments: ["txt", "json", "c", "custom"])
  func nonMarkdownFilesPreserveLiteralText(_ ext: String) async throws {
    let source = "# Literal heading\n\t<strong>Literal HTML</strong>\n{\"日本語\": \"value\"}\nint main(void) { return 0; }\n"
    let reader = try await ReaderHarness(source, fileURL: URL(filePath: "/tmp/sample." + ext))
    defer { reader.close() }
    #expect(reader.session.headings.isEmpty)
    #expect(try await reader.js("document.querySelector('article code').textContent") as? String == source)
    #expect(try await reader.js("document.querySelectorAll('article h1, article strong').length") as? Int == 0)
    reader.session.find("日本語")
    try await reader.wait { reader.session.matchCount == 1 }
    try await reader.select("Literal heading")
    reader.session.command("markSelection")
    try await reader.wait { reader.session.markCount == 1 }
  }

  @Test func standaloneHTMLUsesHTMLRatherThanMarkdownParsing() async throws {
    let reader = try await ReaderHarness("<!doctype html><html><head><title>Title</title></head><body><h1 id=overview>HTML文書</h1><p># Literal Markdown</p></body></html>", fileURL: URL(filePath: "/tmp/sample.html"))
    defer { reader.close() }
    #expect(reader.session.headings.map(\.title) == ["HTML文書"])
    #expect(try await reader.js("document.querySelector('article p').textContent") as? String == "# Literal Markdown")
    #expect(try await reader.js("window.reader.jump('overview')") as? Bool == true)
  }

  @Test func retriesLocalImagesAfterProjectAccessIsGranted() async throws {
    let root = FileManager.default.temporaryDirectory.appending(path: "AyamiImageGrant-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: root.appending(path: "docs"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"80\" height=\"40\"><rect width=\"80\" height=\"40\" fill=\"pink\"/></svg>"
    try Data(svg.utf8).write(to: root.appending(path: "diagram.svg"))
    let document = root.appending(path: "docs/README.md")
    let original = Data("# Images\n\n![Local image](../diagram.svg)".utf8)
    try original.write(to: document)
    let reader = try await ReaderHarness(String(decoding: original, as: UTF8.self), fileURL: document)
    defer { reader.close() }
    try await reader.wait { reader.session.hasUnavailableImages }
    let access = ProjectFolderAccess()
    access.grant(root)
    #expect(access.folders == [root])
    reader.coordinator.resources.policy = DocumentResourcePolicy(documentURL: document, grantedFolders: access.folders)
    reader.session.command("reloadImages")
    try await reader.waitJS("document.querySelector('img').naturalWidth === 80")
    #expect(try Data(contentsOf: document) == original)
  }

  @Test func retainsMarksWhenTheReadingPageIsReattachedToAnotherLayout() async throws {
    let source = "# Layout\n\nKeep this mark across rotation."
    let reader = try await ReaderHarness(source)
    defer { reader.close() }
    try await reader.select("Keep this mark")
    reader.session.command("markSelection")
    try await reader.wait { reader.session.markCount == 1 }
    let replacement = ReaderWebView.Coordinator(session: reader.session, onLink: { _ in })
    reader.session.messageHandler.target = replacement
    reader.view.navigationDelegate = replacement
    // The old view can be dismantled after the replacement has attached.
    reader.coordinator.close(reader.view)
    replacement.render(markdown: source, scale: 1.4, theme: "dark")
    try await reader.waitJS("document.documentElement.style.colorScheme === 'dark'")
    #expect(reader.session.markCount == 1)
    #expect(try await reader.js("[...CSS.highlights.get('ayami-pink')][0].toString()") as? String == "Keep this mark")
    reader.session.command("clearMarks")
    try await reader.wait { reader.session.markCount == 0 }
    replacement.close(reader.view)
  }
}

@MainActor
private final class ReaderHarness {
  let session = ReaderSession()
  let view: WKWebView
  let coordinator: ReaderWebView.Coordinator
  var links: [String] = []

  init(_ source: String, fileURL: URL? = nil) async throws {
    coordinator = ReaderWebView.Coordinator(session: session, onLink: { _ in })
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()
    session.messageHandler.target = coordinator
    configuration.userContentController.add(session.messageHandler, name: "reader")
    configuration.setURLSchemeHandler(coordinator.resources, forURLScheme: "ayami-reader")
    configuration.setURLSchemeHandler(coordinator.resources, forURLScheme: "ayami-asset")
    view = WKWebView(frame: CGRect(x: 0, y: 0, width: 900, height: 700), configuration: configuration)
    session.webView = view
    coordinator.resources.policy = DocumentResourcePolicy(documentURL: fileURL)
    view.navigationDelegate = coordinator
    coordinator.onLink = { [weak self] in self?.links.append($0.reference) }
    render(source)
    view.load(URLRequest(url: URL(string: "ayami-reader://bundle/index.html")!))
    try await wait { self.session.isReady || self.session.error != nil }
    #expect(session.error == nil)
    if let error = session.error { throw NSError(domain: error, code: 1) }
  }

  func render(_ source: String) { coordinator.render(markdown: source, scale: 1, theme: "light") }
  func close() { coordinator.close(view); view.stopLoading(); session.webView = nil }
  func js(_ source: String) async throws -> Any? { try await view.evaluateJavaScript(source) }

  func wait(_ predicate: () -> Bool) async throws {
    for _ in 0..<300 {
      if predicate() { return }
      try await Task.sleep(for: .milliseconds(50))
    }
    throw NSError(domain: "Reader wait timed out: \(session.error ?? "no native error")", code: 2)
  }

  func waitJS(_ script: String) async throws {
    for _ in 0..<100 {
      if try await js(script) as? Bool == true { return }
      try await Task.sleep(for: .milliseconds(50))
    }
    throw NSError(domain: "Reader JavaScript wait timed out", code: 3)
  }

  func select(_ text: String) async throws {
    _ = try await js("""
      (() => {
        const target = \(ReaderResources.json(text));
        const walker = document.createTreeWalker(document.querySelector('article'), NodeFilter.SHOW_TEXT);
        for (let node; node = walker.nextNode();) {
          const at = node.textContent.indexOf(target);
          if (at < 0) continue;
          const range = document.createRange(); range.setStart(node, at); range.setEnd(node, at + target.length);
          const selected = getSelection(); selected.removeAllRanges(); selected.addRange(range); return true;
        }
        return false;
      })()
      """)
    try await wait { self.session.hasSelection }
  }
}

struct DocumentResourcePolicyTests {
  @Test func restrictsImagesToAuthorizedFoldersAndRejectsSymlinkEscapes() throws {
    let root = FileManager.default.temporaryDirectory.appending(path: "AyamiResources-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: root.appending(path: "docs"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: root.appending(path: "images"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }
    let document = root.appending(path: "docs/README.md")
    let image = root.appending(path: "images/日本語.png")
    try Data([1, 2, 3]).write(to: image)
    let restricted = DocumentResourcePolicy(documentURL: document)
    #expect(throws: (any Error).self) { try restricted.image("../images/日本語.png") }
    let granted = DocumentResourcePolicy(documentURL: document, grantedFolders: [root])
    #expect(try granted.image("../images/%E6%97%A5%E6%9C%AC%E8%AA%9E.png").0 == Data([1, 2, 3]))
    #expect(throws: (any Error).self) { try granted.image("https://example.com/tracker.png") }
    #expect(throws: (any Error).self) { try granted.image("../../outside.png") }
    #expect(throws: (any Error).self) { try granted.image("../secrets.txt") }
    try FileManager.default.createSymbolicLink(at: root.appending(path: "docs/escape"), withDestinationURL: root.deletingLastPathComponent())
    #expect(throws: (any Error).self) { try granted.resolve("escape/outside.png") }
  }
}
