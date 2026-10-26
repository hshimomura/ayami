import Foundation

enum ReadingPreferences {
  static let fontScaleKey = "readerFontScale"
  static let defaultFontScale = 1.0
  static let fontScaleRange = 0.8...1.6
  static let fontScaleStep = 0.05
  static let linkDestinationKey = "readerLinkDestination"
  static let defaultLinkDestination = DocumentLinkDestination.tab
  static let showWelcomeAtLaunchKey = "showWelcomeAtLaunch"
  static let hasSeenWelcomeKey = "hasSeenWelcome"
  static let defaultShowWelcomeAtLaunch = false

  static func shouldShowWelcomeAtLaunch(in defaults: UserDefaults = .standard) -> Bool {
    !defaults.bool(forKey: hasSeenWelcomeKey) || defaults.bool(forKey: showWelcomeAtLaunchKey)
  }

  static func normalizedFontScale(_ value: Double) -> Double {
    guard value.isFinite else { return defaultFontScale }
    let clamped = min(max(value, fontScaleRange.lowerBound), fontScaleRange.upperBound)
    return (clamped / fontScaleStep).rounded() * fontScaleStep
  }
}

enum DocumentLinkDestination: String, CaseIterable, Identifiable {
  case tab
  case window

  var id: String { rawValue }

  static func resolved(_ rawValue: String?) -> Self {
    rawValue.flatMap(Self.init(rawValue:)) ?? ReadingPreferences.defaultLinkDestination
  }
}
