import SwiftUI

// A separate test-only app exercises the real shared reader without adding
// bypasses or sample-launch flags to the production document browser.
@main
struct UITestHostApp: App {
  init() {
    if CommandLine.arguments.contains("--ui-testing-reset") {
      UserDefaults.standard.removeObject(forKey: ReadingPreferences.fontScaleKey)
    }
    // A public fixture gives the system Files picker a real, writable location.
    // This is confined to this separate test application's sandbox.
    try? FileManager.default.createDirectory(at: Self.sampleURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? Self.markdown.write(to: Self.sampleURL, atomically: true, encoding: .utf8)
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        PreviewView(document: MarkdownDocument(text: Self.markdown), fileURL: Self.sampleURL)
          .navigationTitle("Ayami \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")")
      }
    }
  }

  private static let sampleURL = URL.documentsDirectory.appending(path:
    (ProcessInfo.processInfo.environment["AYAMI_TEST_FILENAME"] ?? "Ayami14QA-Sample") + ".md")

  private static let markdown = """
    # Reading Sample

    Markdownを、静かに読む。This is selectable **Markdown**.

    ## Diagram

    ```mermaid
    flowchart LR
      A[Markdown] --> B[Ayami]
    ```

    ## Details

    | Name | Value |
    | --- | --- |
    | Text size | Adjustable |
    """
}
