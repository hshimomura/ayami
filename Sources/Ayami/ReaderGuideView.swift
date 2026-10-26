import SwiftUI
#if os(macOS)
import ServiceManagement
#endif

enum TechnicalSample {
  static var url: URL? {
    let language = Locale.preferredLanguages.first ?? "en"
    return ReaderResources.directory?.appending(path: "Sample/" + (language.hasPrefix("ja") ? "README.md" : "README-en.md"))
  }
}

struct ReaderGuideView: View {
  @Environment(\.dismiss) private var dismiss
  #if os(macOS)
    @Environment(\.openDocument) private var openDocument
  #else
    @State private var sampleDocument: LinkedReadingDocument?
  #endif
  @State private var error: String?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          Label("Read Technical Documents", systemImage: "doc.text.magnifyingglass")
            .font(.title2.bold())
          Text("Read README files, design documents, and AI-generated Markdown with tables, code, local images, and Mermaid diagrams.")
          Button("Open Technical Sample", systemImage: "doc.text") {
            guard let url = TechnicalSample.url else { return }
            #if os(macOS)
            Task { @MainActor in
              do { try await openDocument(at: url); dismiss() }
              catch { self.error = error.localizedDescription }
            }
            #else
              do { sampleDocument = LinkedReadingDocument(url: url, text: try TextFileContent.read(url)) }
              catch { self.error = error.localizedDescription }
            #endif
          }
          .accessibilityIdentifier("openTechnicalSample")

          guideSection("Find and Mark", icon: "highlighter",
            text: "Search from the magnifying glass (⌘F on Mac). Select text and choose Mark Selection to add a pink mark. Click a mark to select it, then remove it from Document Actions. Marks disappear when the document is closed; they are never written to Markdown or PDF.")
          guideSection("Read a Project", icon: "folder",
            text: "If local images or related documents cannot be opened, choose Allow Project Folder from Document Actions and select the folder containing the project. Access lasts for this app session. Remote images are not loaded.")
          guideSection("Inspect Diagrams and Code", icon: "arrow.up.left.and.arrow.down.right",
            text: "Use Expand Diagram above a Mermaid diagram, then zoom or scroll to inspect details. Copy Code copies just the code, without Markdown fences.")
          #if os(macOS)
            guideSection("Finder Quick Look", icon: "eye",
              text: "Select a Markdown file in Finder and press Space. If Ayami's preview is unavailable, open System Settings → General → Login Items & Extensions → Quick Look and enable Ayami. Another Markdown extension may be selected instead. Quick Look uses continuous reading; paper pages are used only for printing and PDF.")
            Button("Open Quick Look Settings", systemImage: "gearshape", action: QuickLookSettings.open)
              .accessibilityIdentifier("openQuickLookSettings")
          #endif
          if let error { Text(error).foregroundStyle(.red) }
        }
        .padding(24)
        .frame(maxWidth: 660, alignment: .leading)
      }
      .navigationTitle("Reading and Quick Look Guide")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
      }
    }
    #if os(macOS)
      .frame(width: 660, height: 600)
    #else
      .sheet(item: $sampleDocument) { LinkedReadingDocumentView(document: $0) }
    #endif
  }

  private func guideSection(_ title: LocalizedStringKey, icon: String, text: LocalizedStringKey) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      Label(title, systemImage: icon).font(.headline)
      Text(text).foregroundStyle(.secondary)
    }
  }
}

#if os(iOS)
struct LinkedReadingDocument: Identifiable {
  let id = UUID()
  let url: URL
  let text: String
}

struct LinkedReadingDocumentView: View {
  let document: LinkedReadingDocument
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      PreviewView(document: MarkdownDocument(text: document.text), fileURL: document.url)
        .navigationTitle(document.url.lastPathComponent)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
        }
    }
  }
}
#endif

#if os(macOS)
enum QuickLookSettings {
  @MainActor
  static func open() {
    // System Settings supports this destination URL; retain the manual route in
    // the guide because the subsection query is not a documented API contract.
    let destination = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension?extensionPointIdentifier=com.apple.quicklook.preview")!
    if !NSWorkspace.shared.open(destination) {
      SMAppService.openSystemSettingsLoginItems()
    }
  }
}

struct ReaderWelcomeView: View {
  @Environment(\.openDocument) private var openDocument
  @Environment(\.dismissWindow) private var dismissWindow
  @AppStorage(ReadingPreferences.showWelcomeAtLaunchKey)
  private var showWelcomeAtLaunch = ReadingPreferences.defaultShowWelcomeAtLaunch
  @AppStorage(ReadingPreferences.hasSeenWelcomeKey)
  private var hasSeenWelcome = false
  @State private var showsGuide = false
  @State private var error: String?

  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "doc.richtext").font(.system(size: 46)).foregroundStyle(.tint)
      Text("Welcome to Ayami").font(.largeTitle.bold())
      Text("README files, design documents, and diagrams.\nA quiet place to read and review.")
        .multilineTextAlignment(.center).foregroundStyle(.secondary)
      Button("Open Technical Sample", systemImage: "doc.text") {
        guard let url = TechnicalSample.url else { return }
        open(url)
      }
      .buttonStyle(.borderedProminent).controlSize(.large)
      .accessibilityIdentifier("openTechnicalSample")
      Button("Open Text Document…", systemImage: "folder") {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = MarkdownDocument.readableContentTypes
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { open(url) }
      }
      Button("Reading and Quick Look Guide", systemImage: "questionmark.circle") { showsGuide = true }
      Toggle("Show this window on next launch", isOn: $showWelcomeAtLaunch)
        .toggleStyle(.checkbox)
        .accessibilityIdentifier("showWelcomeAtLaunch")
      if let error { Text(error).font(.caption).foregroundStyle(.red) }
    }
    .padding(40)
    .frame(width: 520, height: 440)
    .sheet(isPresented: $showsGuide) { ReaderGuideView() }
    .onAppear { hasSeenWelcome = true }
  }

  private func open(_ url: URL) {
    Task { @MainActor in
      do { try await openDocument(at: url); dismissWindow(id: "welcome") }
      catch { self.error = error.localizedDescription }
    }
  }
}
#endif
