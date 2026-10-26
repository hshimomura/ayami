import XCTest

final class ReadingUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  @MainActor
  func testDocumentFindNavigatesFormattedText() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    let find = app.buttons["findDocument"]
    XCTAssertTrue(find.waitForExistence(timeout: 15))
    find.tap()
    let field = app.textFields["documentFindField"]
    XCTAssertTrue(field.waitForExistence(timeout: 10))
    field.tap()
    field.typeText("Markdown")
    let count = app.staticTexts["documentFindCount"]
    XCTAssertTrue(count.waitForExistence(timeout: 10))
    XCTAssertEqual(count.label, "1 / 2")
    app.buttons["findNext"].tap()
    XCTAssertEqual(count.label, "2 / 2")
    app.buttons["findPrevious"].tap()
    XCTAssertEqual(count.label, "1 / 2")
    app.buttons["closeFind"].tap()
    XCTAssertTrue(field.waitForNonExistence(timeout: 10))
  }

  @MainActor
  func testGuideOpensTheBundledTechnicalSample() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["documentActions"].waitForExistence(timeout: 15))
    app.buttons["documentActions"].tap()
    app.buttons["Reading and Quick Look Guide"].tap()
    let sample = app.buttons["openTechnicalSample"]
    XCTAssertTrue(sample.waitForExistence(timeout: 10))
    sample.tap()
    XCTAssertTrue(app.staticTexts["Notification Service — Design Review"].waitForExistence(timeout: 15), app.debugDescription)
    let contents = app.buttons.matching(identifier: "outlineSheetButton").allElementsBoundByIndex.last(where: { $0.isHittable })
    if let contents { contents.tap() }
    app.buttons["3. Related documents and images"].tap()
    let related = app.links["Jump to incident response"]
    XCTAssertTrue(related.waitForExistence(timeout: 10))
    related.tap()
    XCTAssertTrue(app.staticTexts["Notification Service — Operations"].waitForExistence(timeout: 15), app.debugDescription)
  }

  @MainActor
  func testRelatedJSONFileOpensAsLiteralText() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["documentActions"].waitForExistence(timeout: 15))
    app.buttons["documentActions"].tap()
    app.buttons["Reading and Quick Look Guide"].tap()
    let sample = app.buttons["openTechnicalSample"]
    XCTAssertTrue(sample.waitForExistence(timeout: 10))
    sample.tap()
    XCTAssertTrue(app.staticTexts["Notification Service — Design Review"].waitForExistence(timeout: 15))
    let contents = app.buttons.matching(identifier: "outlineSheetButton").allElementsBoundByIndex.last(where: { $0.isHittable })
    if let contents { contents.tap() }
    app.buttons["5. HTML and source files"].tap()
    let related = app.links["Configuration (JSON)"]
    XCTAssertTrue(related.waitForExistence(timeout: 10))
    related.tap()
    let source = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "public-notification-sample")).firstMatch
    XCTAssertTrue(source.waitForExistence(timeout: 15), app.debugDescription)
    // Syntax highlighting can expose individual tokens as separate AX text nodes.
    let literalHTML = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "<strong>source text</strong>")).firstMatch
    XCTAssertTrue(literalHTML.waitForExistence(timeout: 10), app.debugDescription)
    XCTAssertTrue(app.buttons["Copy Code"].exists)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami linked JSON as literal source"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  func testReadingSettingsPersistAndReset() throws {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale",
      "en_US",
    ]
    app.launch()
    let settings = app.buttons["readingSettings"]
    XCTAssertTrue(settings.waitForExistence(timeout: 15))
    settings.tap()
    let slider = app.sliders["readerFontScale"]
    XCTAssertTrue(slider.waitForExistence(timeout: 10))
    slider.adjust(toNormalizedSliderPosition: 1)
    XCTAssertTrue(String(describing: slider.value).contains("160"))
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami Reading Settings"
    screenshot.lifetime = .keepAlways
    add(screenshot)
    app.buttons["Done"].tap()
    app.terminate()

    app.launchArguments.removeAll { $0 == "--ui-testing-reset" }
    app.launch()
    XCTAssertTrue(settings.waitForExistence(timeout: 15))
    settings.tap()
    XCTAssertTrue(slider.waitForExistence(timeout: 10))
    XCTAssertTrue(String(describing: slider.value).contains("160"))
    app.buttons["resetReaderFontScale"].tap()
    XCTAssertTrue(String(describing: slider.value).contains("100"))
  }

  @MainActor
  func testOutlineIsAvailable() {
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale",
      "en_US",
    ]
    app.launch()
    XCTAssertTrue(app.buttons["readingSettings"].waitForExistence(timeout: 15))
    let contents = app.buttons["outlineSheetButton"]
    // A phone can have a regular-width inner display; test the actual layout.
    if contents.exists {
      XCTAssertTrue(contents.exists)
      contents.tap()
      XCTAssertTrue(app.buttons["Details"].waitForExistence(timeout: 5))
      app.buttons["Details"].tap()
      XCTAssertFalse(app.buttons["Done"].exists)
    } else {
      let sidebarToggle = app.buttons["outlineSidebarButton"]
      XCTAssertTrue(sidebarToggle.exists)
      sidebarToggle.tap()
      XCTAssertFalse(app.buttons["Details"].exists)
      sidebarToggle.tap()
      XCTAssertTrue(app.buttons["Details"].waitForExistence(timeout: 10))
      app.buttons["Details"].tap()
    }
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami Document"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  func testReadingLayoutSurvivesPhysicalRotation() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    defer { XCUIDevice.shared.orientation = .portrait }
    app.launch()
    XCTAssertTrue(app.buttons["readingSettings"].waitForExistence(timeout: 15))
    XCUIDevice.shared.orientation = .landscapeLeft
    XCTAssertTrue(app.buttons["readingSettings"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["readingSettings"].isHittable)
    // Duo's inner display does not follow interface-orientation masks.
    // Check usable controls after physical rotation, not a fixed aspect ratio.
    let landscapeScreen = app.screenshot()
    let landscape = XCTAttachment(screenshot: landscapeScreen)
    landscape.name = "Ayami after physical rotation"
    landscape.lifetime = .keepAlways
    add(landscape)
    XCUIDevice.shared.orientation = .portrait
    XCTAssertTrue(app.buttons["readingSettings"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["readingSettings"].isHittable)
    app.buttons["readingSettings"].tap()
    XCTAssertTrue(app.sliders["readerFontScale"].waitForExistence(timeout: 10))
  }

  @MainActor
  func testPDFOutputContainsDiagramAndExportActions() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["documentActions"].waitForExistence(timeout: 15))
    app.buttons["documentActions"].tap()
    app.buttons["Print and PDF"].tap()
    let ready = app.staticTexts["pdfReady"]
    XCTAssertTrue(ready.waitForExistence(timeout: 40))
    XCTAssertTrue(ready.label.contains("1 diagrams"))
    XCTAssertTrue(app.buttons["savePDF"].exists)
    XCTAssertTrue(app.buttons["printPDF"].exists)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami 1.4 PDF output"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  func testSummaryReportsDeviceAvailabilityWithoutAutomaticGeneration() {
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["documentActions"].waitForExistence(timeout: 15))
    app.buttons["documentActions"].tap()
    app.buttons["Document Highlights (Prototype)"].tap()
    XCTAssertTrue(app.staticTexts["summaryAvailability"].waitForExistence(timeout: 10))
    XCTAssertTrue(app.buttons["generateSummary"].exists)
    XCTAssertFalse(app.staticTexts["summaryResult"].exists)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami 1.4 on-device model availability"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  func testSystemPrintOptionsOpenWithoutSubmittingPrintJob() {
    let app = openPDFOutput()
    app.buttons["printPDF"].tap()
    let printer = app.staticTexts["Printer"]
    let printerButton = app.buttons["Printer"]
    let options = app.navigationBars["Print Options"]
    XCTAssertTrue(printer.waitForExistence(timeout: 10) || printerButton.exists || options.exists,
      "Print controls: \(app.buttons.allElementsBoundByIndex.map(\.label))")
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami 1.4 system print options - no job submitted"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  func testSystemPDFExportPickerOpens() {
    let app = openPDFOutput()
    app.buttons["savePDF"].tap()
    let export = app.buttons["Export"]
    let save = app.buttons["Save"]
    XCTAssertTrue(export.waitForExistence(timeout: 10) || save.exists,
      "Export controls: \(app.buttons.allElementsBoundByIndex.map(\.label))")
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami 1.4 system PDF export picker"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  func testSystemPDFExportSavesPublicSample() {
    let app = openPDFOutput()
    app.buttons["savePDF"].tap()
    let save = app.buttons["Save"]
    XCTAssertTrue(save.waitForExistence(timeout: 10))
    // The test host exposes only its own public fixture folder to Files.
    let folder = app.cells.containing(.staticText, identifier: "Ayami").firstMatch
    if folder.exists && folder.isHittable { folder.tap() }
    XCTAssertTrue(save.isEnabled, app.debugDescription)
    save.tap()
    XCTAssertTrue(app.staticTexts["pdfSaved"].waitForExistence(timeout: 15), app.debugDescription)
    XCTAssertTrue(app.staticTexts["pdfReady"].waitForExistence(timeout: 15))
    XCTAssertFalse(app.alerts["Output failed"].exists)
    // Files finishes exporting and dismissing asynchronously, especially on
    // iPad. The PDF sheet underneath can already exist during that animation.
    XCTAssertTrue(save.waitForNonExistence(timeout: 15), app.debugDescription)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami 1.4 after system PDF save"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  func testNativeSummaryGeneratesWhenModelIsAvailable() throws {
    guard ProcessInfo.processInfo.environment["AYAMI_TEST_LOCAL_AI"] == "1" else {
      throw XCTSkip("Opt-in model integration test. Simulator generation requires compatible host/model assets; see docs/validation-1.4.md.")
    }
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["documentActions"].waitForExistence(timeout: 15))
    app.buttons["documentActions"].tap()
    app.buttons["Document Highlights (Prototype)"].tap()
    XCTAssertTrue(app.staticTexts["summaryAvailability"].waitForExistence(timeout: 10))
    let generate = app.buttons["generateSummary"]
    guard generate.isEnabled else {
      throw XCTSkip("Actual system model unavailable: \(app.staticTexts["summaryAvailability"].label)")
    }
    generate.tap()
    let result = app.staticTexts["summaryResult"]
    XCTAssertTrue(result.waitForExistence(timeout: 60), app.debugDescription)
    XCTAssertGreaterThan(result.label.count, 20)
    XCTAssertTrue(result.label.lowercased().contains("markdown") || result.label.contains("Ayami"))
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami 1.4 actual native summary"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  @MainActor
  private func openPDFOutput() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment["AYAMI_TEST_FILENAME"] = "Ayami14QA-" + UUID().uuidString
    app.launchArguments = ["--ui-testing-sample", "--ui-testing-reset", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["documentActions"].waitForExistence(timeout: 15))
    app.buttons["documentActions"].tap()
    app.buttons["Print and PDF"].tap()
    XCTAssertTrue(app.staticTexts["pdfReady"].waitForExistence(timeout: 40))
    return app
  }
}
