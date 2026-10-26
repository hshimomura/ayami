#if os(macOS)
import AppKit
import Foundation
import Testing
@testable import Ayami

@MainActor
struct ReaderLinkMenuTests {
  @Test func menuRoutesOpenActionsAndCopiesTheActualDocumentURL() throws {
    let session = ReaderSession()
    session.resources.policy = DocumentResourcePolicy(documentURL: URL(filePath: "/tmp/ayami-link-menu/README.md"))
    var requests: [ReaderLinkRequest] = []
    let coordinator = ReaderWebView.Coordinator(session: session, onLink: { requests.append($0) })
    let menu = try coordinator.makeLinkMenu(reference: "docs/config.json#details")
    for action in [ReaderLinkMenuAction.open, .tab, .window] {
      let item = try #require(menu.items.first { $0.tag == action.rawValue && !$0.isSeparatorItem })
      _ = item.target?.perform(try #require(item.action), with: item)
    }
    #expect(requests.map(\.reference) == Array(repeating: "docs/config.json#details", count: 3))
    #expect(requests.map(\.destination) == [nil, .tab, .window])
    let pasteboard = NSPasteboard.withUniqueName()
    defer { pasteboard.releaseGlobally() }
    try coordinator.copyLink("docs/config.json#details", to: pasteboard)
    #expect(pasteboard.string(forType: .string) == "file:///tmp/ayami-link-menu/docs/config.json#details")
    #expect(pasteboard.string(forType: .URL) == "file:///tmp/ayami-link-menu/docs/config.json#details")
    let webMenu = try coordinator.makeLinkMenu(reference: "https://example.com/report.json")
    #expect(!webMenu.items.contains { $0.tag == ReaderLinkMenuAction.tab.rawValue && !$0.isSeparatorItem })
    #expect(throws: CocoaError.self) { try coordinator.makeLinkMenu(reference: "ayami-reader://bundle/docs/config.json") }
  }

  @Test func savingALinkCopiesOriginalBytesAndProtectsTheSource() throws {
    let folder = FileManager.default.temporaryDirectory.appending(path: "AyamiLinkSave-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let source = folder.appending(path: "source.json"), destination = folder.appending(path: "saved.json")
    let original = Data("{\"message\":\"日本語\"}\n".utf8)
    try original.write(to: source)
    try Data("old destination".utf8).write(to: destination)
    try ReaderLinkFileCopy.save(from: source, to: destination)
    #expect(try Data(contentsOf: destination) == original)
    #expect(try Data(contentsOf: source) == original)
    #expect(throws: CocoaError.self) { try ReaderLinkFileCopy.save(from: source, to: source) }
    let alias = folder.appending(path: "alias.json")
    try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: source)
    #expect(throws: CocoaError.self) { try ReaderLinkFileCopy.save(from: source, to: alias) }
    #expect(try Data(contentsOf: source) == original)
  }
}
#endif
