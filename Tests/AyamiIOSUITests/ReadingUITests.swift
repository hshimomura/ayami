import XCTest

final class ReadingUITests: XCTestCase {
  override func setUpWithError() throws {
    continueAfterFailure = false
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
}
