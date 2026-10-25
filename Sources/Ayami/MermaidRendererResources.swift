import Foundation

enum MermaidRendererResources {
  static var directory: URL? {
    #if SWIFT_PACKAGE
    let root = Bundle.module.resourceURL
    #else
    let root = Bundle.main.resourceURL
    #endif
    guard let root else { return nil }
    return ["Mermaid", "Resources/Mermaid"].map {
      root.appending(path: $0, directoryHint: .isDirectory)
    }.first {
      FileManager.default.fileExists(atPath: $0.appending(path: "renderer.html").path)
    }
  }

  static func html() throws -> String {
    guard let directory else { throw CocoaError(.fileNoSuchFile) }
    let html = try String(contentsOf: directory.appending(path: "renderer.html"), encoding: .utf8)
    let script = try String(contentsOf: directory.appending(path: "mermaid.min.js"), encoding: .utf8)
    return html.replacingOccurrences(
      of: #"<script src="mermaid.min.js"></script>"#,
      with: "<script>\(script)</script>"
    )
  }
}
