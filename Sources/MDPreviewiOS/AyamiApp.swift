import SwiftUI

@main
struct AyamiApp: App {
  var body: some Scene {
    DocumentGroup(viewing: MarkdownDocument.self) { configuration in
      PreviewView(document: configuration.document, fileURL: configuration.fileURL)
    }
  }
}
