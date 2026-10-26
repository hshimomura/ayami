#!/usr/bin/env swift
import AppKit

// Reproducible native composition using the existing icon and unmodified public
// product screenshots. The universal artwork supports both App Store placements.
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let width = 5244, height = 2950
func color(_ hex: UInt32) -> NSColor {
  NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255,
          green: CGFloat((hex >> 8) & 255) / 255,
          blue: CGFloat(hex & 255) / 255, alpha: 1)
}
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
  NSRect(x: x, y: CGFloat(height) - y - h, width: w, height: h)
}
for locale in ["ja", "en-US"] {
  let context = CGContext(data: nil, width: width, height: height,
    bitsPerComponent: 8, bytesPerRow: width * 4,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
  let canvas = NSRect(x: 0, y: 0, width: width, height: height)
  NSGradient(starting: color(0xFFF9EF), ending: color(0xF0F1F8))!.draw(in: canvas, angle: -20)
  // The soft shapes frame the focal point without carrying essential content.
  color(0xF8E6DD).withAlphaComponent(0.36).setFill()
  NSBezierPath(ovalIn: rect(2900, 300, 1750, 1750)).fill()
  color(0xE7E9F7).withAlphaComponent(0.36).setFill()
  NSBezierPath(ovalIn: rect(400, 1250, 1700, 1700)).fill()

  func text(_ value: String, x: CGFloat, y: CGFloat, w: CGFloat, size: CGFloat,
            weight: NSFont.Weight = .regular, ink: UInt32 = 0x282A32) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byClipping
    let attributes: [NSAttributedString.Key: Any] = [
      .font: NSFont.systemFont(ofSize: size, weight: weight),
      .foregroundColor: color(ink), .paragraphStyle: paragraph
    ]
    (value as NSString).draw(in: rect(x, y, w, size * 1.6), withAttributes: attributes)
  }
  let icon = NSImage(contentsOf: root.appendingPathComponent("Resources/AppIcon-1024.png"))!
  NSGraphicsContext.saveGraphicsState()
  NSBezierPath(roundedRect: rect(1030, 720, 240, 240), xRadius: 52, yRadius: 52).addClip()
  icon.draw(in: rect(1030, 720, 240, 240), from: .zero, operation: .sourceOver, fraction: 1)
  NSGraphicsContext.restoreGraphicsState()
  text(locale == "ja" ? "あやみ" : "Ayami", x: 1330, y: 740, w: 1300, size: 125, weight: .semibold)
  text("Markdown Reader", x: 1336, y: 895, w: 1300, size: 60, ink: 0x687080)

  color(0xF7B9D3).withAlphaComponent(0.72).setFill()
  NSBezierPath(roundedRect: rect(1025, 1495, locale == "ja" ? 1370 : 1010, 120), xRadius: 18, yRadius: 18).fill()
  text(locale == "ja" ? "読むことに、" : "Quiet Markdown", x: 1015, y: 1120, w: 2080,
       size: locale == "ja" ? 205 : 181, weight: .bold)
  text(locale == "ja" ? "集中できる。" : "reading.", x: 1015, y: 1390, w: 2080,
       size: locale == "ja" ? 205 : 210, weight: .bold)
  text(locale == "ja" ? "READMEも、設計書も。" : "For READMEs and technical docs.",
       x: 1030, y: 1740, w: 2050, size: 78, ink: 0x596272)
  text(locale == "ja" ? "探す。マークする。読み進める。" : "Find. Mark. Keep reading.",
       x: 1030, y: 1900, w: 2050, size: 66, ink: 0x747C8B)

  let screen = NSImage(contentsOf: root.appendingPathComponent(
    "AppStore/Screenshots/1.5/iPhoneDuo/\(locale)/02-inner-mark.jpg"))!
  let card = rect(3260, 660, 1040, 1478)
  NSGraphicsContext.saveGraphicsState()
  let shadow = NSShadow(); shadow.shadowColor = color(0x373E58).withAlphaComponent(0.18)
  shadow.shadowBlurRadius = 90; shadow.shadowOffset = NSSize(width: 0, height: -35); shadow.set()
  NSColor.white.setFill()
  NSBezierPath(roundedRect: card, xRadius: 66, yRadius: 66).fill()
  NSGraphicsContext.restoreGraphicsState()
  NSGraphicsContext.saveGraphicsState()
  NSBezierPath(roundedRect: card, xRadius: 66, yRadius: 66).addClip()
  screen.draw(in: card, from: .zero, operation: .sourceOver, fraction: 1)
  NSGraphicsContext.restoreGraphicsState()
  color(0xD9DCE5).setStroke()
  let border = NSBezierPath(roundedRect: card, xRadius: 66, yRadius: 66)
  border.lineWidth = 3; border.stroke()
  NSGraphicsContext.restoreGraphicsState()
  let output = root.appendingPathComponent("AppStore/Screenshots/1.5/Creative/\(locale)/universal-header-search.png")
  let bitmap = NSBitmapImageRep(cgImage: context.makeImage()!)
  precondition(!bitmap.hasAlpha, "App Store creative assets must be opaque")
  try bitmap.representation(using: .png, properties: [:])!.write(to: output)
  print("Rendered \(locale): \(width)×\(height), opaque RGB PNG")
}
