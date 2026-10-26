import Foundation
import Observation
import UniformTypeIdentifiers
import Darwin

enum ReaderResources {
  static var directory: URL? {
    #if SWIFT_PACKAGE
      let root = Bundle.module.resourceURL
    #else
      let root = Bundle.main.resourceURL
    #endif
    return ["Reader", "Resources/Reader"].compactMap { root?.appending(path: $0) }
      .first { FileManager.default.fileExists(atPath: $0.appending(path: "index.html").path) }
  }

  static func resource(_ name: String) throws -> (Data, String) {
    if name == "mermaid.min.js", let directory = MermaidRendererResources.directory {
      return (try Data(contentsOf: directory.appending(path: name)), "text/javascript")
    }
    let types = ["index.html": "text/html", "reader.css": "text/css", "reader.js": "text/javascript",
      "markdown-it.min.js": "text/javascript", "prism.js": "text/javascript", "purify.min.js": "text/javascript"]
    guard let type = types[name], let directory else { throw CocoaError(.fileNoSuchFile) }
    return (try Data(contentsOf: directory.appending(path: name)), type)
  }

  static func json(_ object: Any) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed, .sortedKeys]),
      let text = String(data: data, encoding: .utf8) else { return "null" }
    return text
  }
}

/// Restricts the web process to image files in the document folder or an explicitly granted project.
struct DocumentResourcePolicy {
  let documentURL: URL?
  var grantedFolders: [URL] = []

  func resolve(_ reference: String) throws -> URL {
    guard let documentURL,
      let url = URL(string: reference, relativeTo: documentURL)?.absoluteURL,
      url.isFileURL,
      let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
      components.query == nil
    else { throw CocoaError(.fileReadNoPermission) }
    var fileComponents = components
    fileComponents.fragment = nil
    guard let target = fileComponents.url, let file = Self.canonical(target) else {
      throw CocoaError(.fileReadNoPermission)
    }
    var folders = [documentURL.deletingLastPathComponent()] + grantedFolders
    if let sample = ReaderResources.directory?.appending(path: "Sample"),
      documentURL.standardizedFileURL.path.hasPrefix(sample.standardizedFileURL.path + "/") {
      folders.append(sample)
    }
    guard folders.contains(where: { folder in
      guard let root = Self.canonical(folder)?.path else { return false }
      return file.path.hasPrefix(root.hasSuffix("/") ? root : root + "/")
    }) else { throw CocoaError(.fileReadNoPermission) }
    return file
  }

  private static func canonical(_ url: URL) -> URL? {
    guard let path = realpath(url.path, nil) else { return nil }
    defer { free(path) }
    return URL(filePath: String(cString: path))
  }

  func image(_ reference: String) throws -> (Data, String) {
    let url = try resolve(reference)
    let allowed = ["png", "jpg", "jpeg", "gif", "webp", "svg", "heic", "heif", "tif", "tiff", "bmp", "avif"]
    guard allowed.contains(url.pathExtension.lowercased()),
      let type = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType
    else { throw CocoaError(.fileReadUnsupportedScheme) }
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    let data = try handle.read(upToCount: 20 * 1024 * 1024 + 1) ?? Data()
    guard data.count <= 20 * 1024 * 1024 else { throw CocoaError(.fileReadTooLarge) }
    return (data, type)
  }
}

@MainActor
@Observable
final class ProjectFolderAccess {
  static let shared = ProjectFolderAccess()
  private(set) var folders: [URL] = []

  func grant(_ url: URL) {
    guard !folders.contains(url) else { return }
    // The grant remains in memory for this app session; no bookmarks or document data are saved.
    // NSOpenPanel on Mac can already provide access without an additional scoped start.
    // The explicit selection still defines the reader's allowed project boundary.
    _ = url.startAccessingSecurityScopedResource()
    folders.append(url)
  }
}
