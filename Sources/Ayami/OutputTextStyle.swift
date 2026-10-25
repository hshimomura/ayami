import CoreText
import Foundation

enum OutputTextStyle {
  static func text(
    _ source: String, size: CGFloat = 11.5, bold: Bool = false,
    code: Bool = false, gray: Bool = false
  ) -> NSAttributedString {
    let base = font(size: size, bold: bold, code: code)
    let color = CGColor(gray: gray ? 0.35 : 0.08, alpha: 1)
    let fontKey = NSAttributedString.Key(kCTFontAttributeName as String)
    let colorKey = NSAttributedString.Key(kCTForegroundColorAttributeName as String)
    let paragraphKey = NSAttributedString.Key(kCTParagraphStyleAttributeName as String)
    var lineSpacing: CGFloat = 3
    var wrapping = CTLineBreakMode.byWordWrapping
    let settings = withUnsafePointer(to: &lineSpacing) { spacing in
      withUnsafePointer(to: &wrapping) { mode in
        CTParagraphStyleCreate([
          CTParagraphStyleSetting(spec: .lineSpacingAdjustment, valueSize: MemoryLayout<CGFloat>.size, value: spacing),
          CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout<CTLineBreakMode>.size, value: mode),
        ], 2)
      }
    }
    let attributes: [NSAttributedString.Key: Any] = [fontKey: base, colorKey: color, paragraphKey: settings]
    if code { return NSAttributedString(string: source, attributes: attributes) }
    guard let parsed = try? AttributedString(markdown: source, options: .init(
      interpretedSyntax: .inlineOnlyPreservingWhitespace,
      failurePolicy: .returnPartiallyParsedIfPossible
    )) else { return NSAttributedString(string: source, attributes: attributes) }
    let output = NSMutableAttributedString(string: "")
    for run in parsed.runs {
      var styled = attributes
      if let intent = run.inlinePresentationIntent {
        let isCode = intent.contains(.code)
        var traits: CTFontSymbolicTraits = []
        if bold || intent.contains(.stronglyEmphasized) { traits.insert(.boldTrait) }
        if intent.contains(.emphasized) { traits.insert(.italicTrait) }
        let selected = font(size: isCode ? size * 0.92 : size, bold: false, code: isCode)
        styled[fontKey] = CTFontCreateCopyWithSymbolicTraits(selected, 0, nil, traits, traits) ?? selected
      }
      var value = String(parsed[run.range].characters)
      if run.inlinePresentationIntent?.contains(.inlineHTML) == true {
        let tag = value.filter { !$0.isWhitespace }.lowercased()
        if tag == "<br>" || tag == "<br/>" { value = "\n" }
      }
      output.append(NSAttributedString(string: value, attributes: styled))
    }
    return output
  }

  private static func font(size: CGFloat, bold: Bool, code: Bool) -> CTFont {
    let name = code ? "Menlo" : "Helvetica"
    let base = CTFontCreateWithName(name as CFString, size, nil)
    return bold ? CTFontCreateCopyWithSymbolicTraits(base, 0, nil, .boldTrait, .boldTrait) ?? base : base
  }
}
