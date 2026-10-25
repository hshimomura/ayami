import SwiftUI

// A separate test-only app exercises the real shared reader without adding
// bypasses or sample-launch flags to the production document browser.
@main
struct UITestHostApp: App {
  init() {
    if CommandLine.arguments.contains("--ui-testing-reset") {
      UserDefaults.standard.removeObject(forKey: ReadingPreferences.fontScaleKey)
    }
  }

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        PreviewView(document: MarkdownDocument(text: Self.markdown), fileURL: nil)
          .navigationTitle("Ayami \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")")
      }
    }
  }

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
