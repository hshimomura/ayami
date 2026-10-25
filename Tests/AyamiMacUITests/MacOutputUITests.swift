import Foundation
import PDFKit
import XCTest

final class MacOutputUITests: XCTestCase {
  private var fixtureDirectory: URL!
  private var sourceURL: URL!
  private var original: Data!

  override func setUpWithError() throws {
    continueAfterFailure = false
    if name.contains("FinderQuickLook") {
      let kind = name.contains("CustomTypeControl") ? "control" : "markdown"
      fixtureDirectory = URL(filePath: "/private/tmp/ayami-1.4-quicklook-public", directoryHint: .isDirectory)
        .appending(path: kind, directoryHint: .isDirectory)
      sourceURL = fixtureDirectory.appending(path: "PublicSample14." + (kind == "control" ? "ayamiqltest" : "md"))
      original = try Data(contentsOf: sourceURL)
      return
    }
    fixtureDirectory = FileManager.default.temporaryDirectory
      .appending(path: "Ayami14-MacUI-" + UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: fixtureDirectory, withIntermediateDirectories: true)
    let ext = name.contains("CustomTypeControl") ? "ayamiqltest" : "md"
    sourceURL = fixtureDirectory.appending(path: "PublicSample14." + ext)
    original = Data("""
      # Ayami 1.4 Public UI Sample

      日本語の文書を読み取り専用で確認します。**Selectable Markdown**.

      | Name | Value |
      | --- | --- |
      | Version | 1.4 |

      ```mermaid
      flowchart LR
        A[ReadOnly] --> B[PrintedDiagram14]
      ```
      """.utf8)
    try original.write(to: sourceURL, options: .withoutOverwriting)
  }

  @MainActor
  func testPDFSaveThroughSystemPanelPreservesSource() throws {
    let app = try openPublicFixture()
    defer { app.terminate() }
    app.typeKey("p", modifierFlags: .command)
    XCTAssertTrue(app.staticTexts["pdfReady"].waitForExistence(timeout: 30), app.debugDescription)
    let ready = app.staticTexts["pdfReady"]
    XCTAssertTrue((ready.label + String(describing: ready.value)).contains("1 diagrams"))
    app.buttons["savePDF"].click()
    let export = app.sheets["save-panel"].buttons["OKButton"]
    XCTAssertTrue(export.waitForExistence(timeout: 10), app.debugDescription)
    goTo(fixtureDirectory.path, in: app)
    export.click()
    XCTAssertTrue(app.staticTexts["pdfSaved"].waitForExistence(timeout: 20), app.debugDescription)
    let outputURL = fixtureDirectory.appending(path: "PublicSample14.pdf")
    let pdf = try XCTUnwrap(PDFDocument(url: outputURL))
    XCTAssertEqual(pdf.pageCount, 1)
    XCTAssertTrue(pdf.string?.contains("PrintedDiagram14") == true)
    XCTAssertTrue(pdf.string?.contains("日本語") == true)
    XCTAssertFalse(pdf.string?.contains("flowchart LR") == true)
    XCTAssertEqual(try Data(contentsOf: sourceURL), original)
    keep(app.screenshot(), name: "Mac 1.4 system PDF save completed")
    let file = XCTAttachment(contentsOfFile: outputURL)
    file.name = "Mac 1.4 system-saved public PDF"
    file.lifetime = .keepAlways
    add(file)
  }

  @MainActor
  func testNativePrintPanelOpensAndCancelsWithoutJob() throws {
    let app = try openPublicFixture()
    defer { app.terminate() }
    app.typeKey("p", modifierFlags: .command)
    XCTAssertTrue(app.staticTexts["pdfReady"].waitForExistence(timeout: 30), app.debugDescription)
    app.buttons["printPDF"].click()
    denyTestHostNetworkDiscoveryIfRequested()
    let panel = app.descendants(matching: .any).matching(identifier: "PDPrintPanel").firstMatch
    XCTAssertTrue(panel.waitForExistence(timeout: 15), app.debugDescription)
    let cancel = panel.buttons["PDCancel"]
    keep(app.screenshot(), name: "Mac 1.4 native print panel - no job submitted")
    cancel.click()
    XCTAssertTrue(panel.waitForNonExistence(timeout: 10), app.debugDescription)
    XCTAssertTrue(app.buttons["printPDF"].waitForExistence(timeout: 10))
    XCTAssertEqual(try Data(contentsOf: sourceURL), original)
  }

  @MainActor
  func testZFinderQuickLookRendersPublicSample() throws {
    try verifyFinderPreview()
  }

  @MainActor
  func testZFinderQuickLookCustomTypeControl() throws {
    try verifyFinderPreview()
  }

  @MainActor
  private func verifyFinderPreview() throws {
    // Never launch/terminate Finder or navigate an existing user window.
    let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
    finder.activate()
    finder.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
    finder.typeKey("n", modifierFlags: .command)
    goTo(fixtureDirectory.path, in: finder)
    let window = finder.windows.matching(NSPredicate(format: "title == %@", fixtureDirectory.lastPathComponent)).firstMatch
    XCTAssertTrue(window.waitForExistence(timeout: 10))
    defer {
      if ProcessInfo.processInfo.environment["AYAMI_KEEP_PREVIEW_OPEN"] != "1" {
        finder.typeKey(XCUIKeyboardKey.escape, modifierFlags: [])
        if window.exists { window.buttons[XCUIIdentifierCloseWindow].click() }
      }
    }
    let item = window.descendants(matching: .any)
      .matching(NSPredicate(format: "label BEGINSWITH %@", "PublicSample14")).firstMatch
    XCTAssertTrue(item.waitForExistence(timeout: 10), window.debugDescription)
    item.click()
    finder.typeKey(" ", modifierFlags: [])
    let rendered = finder.staticTexts.matching(NSPredicate(format: "value == %@ OR label == %@",
      "PrintedDiagram14", "PrintedDiagram14")).firstMatch
    let didRender = rendered.waitForExistence(timeout: 20)
    let preview = finder.windows["Quick Look"].firstMatch
    XCTAssertTrue(preview.webViews.firstMatch.exists, "Quick Look must use continuous HTML rather than paginated PDF")
    keep(preview.screenshot(), name: "Mac 1.4 continuous Finder Quick Look public fixture")
    let tree = XCTAttachment(string: "Rendered diagram label: \(didRender)")
    tree.name = "Public fixture Quick Look rendering check"
    tree.lifetime = .keepAlways
    add(tree)
    XCTAssertEqual(try Data(contentsOf: sourceURL), original)
    XCTAssertTrue(didRender, "Finder did not expose the rendered SVG diagram label")
  }

  @MainActor
  private func openPublicFixture() throws -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-ApplePersistenceIgnoreState", "YES"]
    // LaunchServices opens the public document in this exact application.
    // No production browser bypass or launch flag is needed.
    app.open(sourceURL)
    let actions = app.descendants(matching: .any).matching(identifier: "documentActions").firstMatch
    XCTAssertTrue(actions.waitForExistence(timeout: 20), app.debugDescription)
    return app
  }

  @MainActor
  private func goTo(_ path: String, in app: XCUIApplication) {
    app.typeKey("g", modifierFlags: [.command, .shift])
    app.typeText(path)
    app.typeKey(XCUIKeyboardKey.return, modifierFlags: [])
  }

  @MainActor
  private func denyTestHostNetworkDiscoveryIfRequested() {
    let notifications = XCUIApplication(bundleIdentifier: "com.apple.UserNotificationCenter")
    let alert = notifications.dialogs["alert"]
    guard alert.exists else { return }
    let text = alert.staticTexts.allElementsBoundByIndex.map {
      $0.label + String(describing: $0.value)
    }.joined(separator: " ")
    guard text.contains("AyamiMacUITestHost"), text.contains("local networks") else { return }
    // No printer/device discovery is needed. Deny only this fresh test app's
    // request; never grant access or modify the user's production app settings.
    let denyLabels = ["Don't Allow", "Don’t Allow"]
    alert.buttons.matching(NSPredicate(format: "title IN %@ OR label IN %@", denyLabels, denyLabels))
      .firstMatch.click()
  }

  @MainActor
  private func keep(_ screenshot: XCUIScreenshot, name: String) {
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
