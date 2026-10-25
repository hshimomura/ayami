import Foundation
import Testing

@testable import MDPreview

struct ReadingPreferencesTests {
  @Test func clampsAndRejectsInvalidValues() {
    #expect(ReadingPreferences.normalizedFontScale(0) == 0.8)
    #expect(ReadingPreferences.normalizedFontScale(3) == 1.6)
    #expect(ReadingPreferences.normalizedFontScale(.nan) == 1)
    #expect(ReadingPreferences.normalizedFontScale(.infinity) == 1)
    #expect(abs(ReadingPreferences.normalizedFontScale(1.13) - 1.15) < 0.0001)
  }

  @Test func settingsCanBePersistedAndReset() throws {
    let suite = "ReadingPreferencesTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    defaults.set(1.4, forKey: ReadingPreferences.fontScaleKey)
    #expect(defaults.double(forKey: ReadingPreferences.fontScaleKey) == 1.4)
    defaults.set(ReadingPreferences.defaultFontScale, forKey: ReadingPreferences.fontScaleKey)
    #expect(defaults.double(forKey: ReadingPreferences.fontScaleKey) == 1)
  }
}

@MainActor
struct DocumentUpdateTests {
  @Test func updatesFromDocumentGroupWithoutDirectFileAccess() {
    let model = PreviewDocumentModel(text: "# Before", fileURL: nil)
    model.updateDocumentText("# After\n\nUpdated")
    #expect(model.text.contains("Updated"))
    #expect(model.content.headings.map(\.title) == ["After"])
  }
}
