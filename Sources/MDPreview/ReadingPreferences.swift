import Foundation

enum ReadingPreferences {
  static let fontScaleKey = "readerFontScale"
  static let defaultFontScale = 1.0
  static let fontScaleRange = 0.8...1.6
  static let fontScaleStep = 0.05

  static func normalizedFontScale(_ value: Double) -> Double {
    guard value.isFinite else { return defaultFontScale }
    let clamped = min(max(value, fontScaleRange.lowerBound), fontScaleRange.upperBound)
    return (clamped / fontScaleStep).rounded() * fontScaleStep
  }
}
