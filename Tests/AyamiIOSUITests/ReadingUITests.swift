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
    if UIDevice.current.userInterfaceIdiom == .phone {
      let contents = app.buttons["Contents"]
      XCTAssertTrue(contents.exists)
      contents.tap()
      XCTAssertTrue(app.buttons["Details"].waitForExistence(timeout: 5))
      app.buttons["Details"].tap()
      XCTAssertFalse(app.buttons["Done"].exists)
    } else {
      XCTAssertTrue(app.buttons["Details"].waitForExistence(timeout: 10))
      app.buttons["Details"].tap()
    }
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "Ayami Document"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }
}
