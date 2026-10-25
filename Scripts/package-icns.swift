import Foundation

// ICNS PNG element identifiers defined by the Apple icon family format.
let arguments = CommandLine.arguments
guard arguments.count == 3 else { fatalError("Usage: package-icns.swift iconset output.icns") }
let directory = URL(fileURLWithPath: arguments[1])
let variants = [
  ("icp4", "icon_16x16.png"), ("icp5", "icon_32x32.png"),
  ("icp6", "icon_32x32@2x.png"), ("ic07", "icon_128x128.png"),
  ("ic08", "icon_256x256.png"), ("ic09", "icon_512x512.png"),
  ("ic10", "icon_512x512@2x.png"), ("ic11", "icon_16x16@2x.png"),
  ("ic12", "icon_32x32@2x.png"), ("ic13", "icon_128x128@2x.png"),
  ("ic14", "icon_256x256@2x.png"),
]
func lengthBytes(_ length: Int) -> Data {
  var value = UInt32(length).bigEndian
  return withUnsafeBytes(of: &value) { Data($0) }
}
var elements = Data()
for (type, filename) in variants {
  let png = try Data(contentsOf: directory.appendingPathComponent(filename))
  elements.append(Data(type.utf8))
  elements.append(lengthBytes(png.count + 8))
  elements.append(png)
}
var icon = Data("icns".utf8)
icon.append(lengthBytes(elements.count + 8))
icon.append(elements)
try icon.write(to: URL(fileURLWithPath: arguments[2]), options: .atomic)
print("Packaged current icon: \(arguments[2])")
