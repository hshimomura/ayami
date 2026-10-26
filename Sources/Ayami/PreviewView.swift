import SwiftUI
import UniformTypeIdentifiers

struct PreviewView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  #if os(macOS)
    @Environment(\.openDocument) private var openDocument
  #else
    @State private var linkedDocument: LinkedReadingDocument?
  #endif
  @Environment(\.openURL) private var openURL
  #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  #endif
  @AppStorage(ReadingPreferences.fontScaleKey)
  private var storedFontScale = ReadingPreferences.defaultFontScale
  @AppStorage(ReadingPreferences.linkDestinationKey)
  private var storedLinkDestination = ReadingPreferences.defaultLinkDestination.rawValue
  @ScaledMetric(relativeTo: .body) private var dynamicFontSize: CGFloat = 16

  private let documentText: String
  private let documentURL: URL?

  @State private var model: PreviewDocumentModel
  @State private var reader = ReaderSession()
  @State private var projectAccess = ProjectFolderAccess.shared
  @State private var showsFind = false
  @State private var findQuery = ""
  @FocusState private var findFocused: Bool
  @State private var showsFolderPicker = false
  @State private var showsGuide = false
  @State private var splitViewVisibility: NavigationSplitViewVisibility = .all
  @State private var showsReadingSettings = false
  @State private var showsOutline = false
  @State private var showsOutput = false
  @State private var showsSummary = false

  init(document: MarkdownDocument, fileURL: URL?) {
    documentText = document.text
    documentURL = fileURL
    _model = State(
      initialValue: PreviewDocumentModel(
        text: document.text,
        fileURL: fileURL
      )
    )
  }

  var body: some View {
    Group {
      if model.text.isEmpty {
        ContentUnavailableView(
          "Empty Document",
          systemImage: "doc.text.magnifyingglass",
          description: Text("This document contains no text.")
        )
      } else if usesCompactLayout {
        documentPreview
      } else {
        #if os(iOS)
        // DocumentGroup owns the navigation container. Nesting a second
        // NavigationSplitView duplicates document bars after Duo display changes.
        HStack(spacing: 0) {
          if isContentsVisible {
            OutlineSidebar(
              headings: reader.headings,
              currentSectionID: reader.currentSectionID
            ) { sectionID in
              reader.jump(sectionID)
            }
            .frame(width: 230)
            Divider()
          }
          documentPreview
        }
        #else
        NavigationSplitView(columnVisibility: $splitViewVisibility) {
          OutlineSidebar(
            headings: reader.headings,
            currentSectionID: reader.currentSectionID
          ) { sectionID in
            reader.jump(sectionID)
          }
          .navigationSplitViewColumnWidth(
            min: 190,
            ideal: 230,
            max: 320
          )
        } detail: {
          documentPreview
        }
        .navigationSplitViewStyle(.prominentDetail)
        #endif
      }
    }
    #if os(macOS)
      .frame(minWidth: 560, minHeight: 420)
      .background {
        WindowSizeRestorer()
        FileMenuOrganizer()
      }
    #endif
    .safeAreaInset(edge: .bottom, spacing: 0) {
      statusBar
    }
    #if os(macOS)
      .focusedSceneValue(
        \.previewCommandActions,
        PreviewCommandActions(
          isContentsVisible: isContentsVisible,
          toggleContents: toggleContents,
          printDocument: { showsOutput = true },
          find: showFind,
          findNext: { reader.command("nextMatch", [1]) },
          findPrevious: { reader.command("nextMatch", [-1]) },
          markSelection: { reader.command("markSelection") },
          canMark: reader.hasSelection
        )
      )
    #endif
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button("Find in Document", systemImage: "magnifyingglass", action: showFind)
          .accessibilityIdentifier("findDocument")
      }
      ToolbarItem(placement: .primaryAction) {
        Button("Mark Selection", systemImage: "highlighter") { reader.command("markSelection") }
          .tint(.pink)
          .disabled(!reader.hasSelection)
          .help("Select text to mark it. Marks disappear when this document is closed.")
          .accessibilityIdentifier("markSelection")
      }

      ToolbarItem(placement: .primaryAction) {
        Menu {
          Button("Remove Selected Mark", systemImage: "highlighter") { reader.command("removeMark") }
            .disabled(!reader.hasActiveMark)
          Button("Clear All Marks", systemImage: "eraser") { reader.command("clearMarks") }
            .disabled(reader.markCount == 0)
            .accessibilityIdentifier("clearMarks")
          Divider()
          Button("Allow Project Folder…", systemImage: "folder.badge.plus") { showsFolderPicker = true }
            .accessibilityIdentifier("allowProjectFolder")
          Button("Reading and Quick Look Guide", systemImage: "questionmark.circle") { showsGuide = true }
          Divider()
          Button("Print and PDF", systemImage: "printer") { showsOutput = true }
            .accessibilityIdentifier("documentOutput")
          Button("Document Highlights (Prototype)", systemImage: "sparkles") { showsSummary = true }
            .accessibilityIdentifier("documentSummary")
        } label: {
          Label("Document Actions", systemImage: "ellipsis.circle")
        }
        .accessibilityIdentifier("documentActions")
      }
      #if os(iOS)
        if !reader.headings.isEmpty {
          ToolbarItem(placement: .primaryAction) {
            Button {
              if usesCompactLayout { showsOutline = true }
              else { toggleContents() }
            } label: {
              if usesCompactLayout {
                Label("Contents", systemImage: "list.bullet.indent")
              } else {
                Label("Toggle Contents", systemImage: "sidebar.left")
              }
            }
            .accessibilityIdentifier(usesCompactLayout ? "outlineSheetButton" : "outlineSidebarButton")
          }
        }
      #endif
      ToolbarItem(placement: .primaryAction) {
        Button("Reading Settings", systemImage: "textformat.size") {
          showsReadingSettings = true
        }
        .accessibilityIdentifier("readingSettings")
      }
    }
    .sheet(isPresented: $showsGuide) { ReaderGuideView() }
    #if os(iOS)
      .sheet(item: $linkedDocument) { LinkedReadingDocumentView(document: $0) }
    #endif
    .fileImporter(isPresented: $showsFolderPicker, allowedContentTypes: [.folder]) { result in
      if case let .success(url) = result {
        projectAccess.grant(url)
        reader.hasUnavailableImages = false
      }
    }
    .alert("Unable to Open", isPresented: Binding(get: { reader.error != nil }, set: { if !$0 { reader.error = nil } })) {
      Button("Done") { reader.error = nil }
    } message: { Text(reader.error ?? "") }
    .sheet(isPresented: $showsReadingSettings) {
      ReadingSettingsSheet()
    }
    .sheet(isPresented: $showsOutput) {
      DocumentOutputView(markdown: DocumentFormat.outputSource(model.text, url: model.fileURL), fileURL: model.fileURL)
        .presentationDetents([.large])
    }
    .sheet(isPresented: $showsSummary) {
      DocumentSummaryView(markdown: model.text)
        .presentationDetents([.large])
    }
    .sheet(isPresented: $showsOutline) {
      NavigationStack {
        OutlineSidebar(headings: reader.headings, currentSectionID: reader.currentSectionID) {
          sectionID in
          reader.jump(sectionID)
          showsOutline = false
        }
        .navigationTitle("Contents")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { showsOutline = false }
          }
        }
      }
    }
    .task(id: documentURL) {
      if model.fileURL != documentURL {
        model = PreviewDocumentModel(text: documentText, fileURL: documentURL)
        reader = ReaderSession()
        findQuery = ""
        showsFind = false
      }
      #if os(macOS)
        await model.monitorFile()
      #endif
    }
    .onChange(of: documentText) { _, newText in
      model.updateDocumentText(newText)
    }
    .onReceive(NotificationCenter.default.publisher(for: ReaderNavigation.notification)) { notification in
      guard let url = notification.object as? URL, url == model.fileURL?.standardizedFileURL,
        reader.isReady, let fragment = ReaderNavigation.takeFragment(for: url) else { return }
      reader.jump(fragment)
    }
    .onChange(of: findQuery) { _, query in reader.find(query) }
    .onChange(of: reader.markCount) { oldValue, newValue in
      if oldValue == 0 && newValue > 0 {
        reader.notice = String(localized: "Marks disappear when this document is closed. Markdown and PDF are unchanged.")
      }
    }
  }

  private var fontScale: CGFloat {
    CGFloat(ReadingPreferences.normalizedFontScale(storedFontScale)) * dynamicFontSize / 16
  }

  private var usesCompactLayout: Bool {
    #if os(iOS)
      horizontalSizeClass == .compact
    #else
      false
    #endif
  }

  private var documentPreview: some View {
    VStack(spacing: 0) {
      if showsFind { findBar }
      if reader.hasUnavailableImages {
        HStack {
          Label("Some images could not be loaded. Allow the project folder to read local images. Remote images stay blocked.", systemImage: "photo.badge.exclamationmark")
            .font(.caption)
          Spacer()
          Button("Allow Folder…") { showsFolderPicker = true }
          Button("Dismiss", systemImage: "xmark") { reader.hasUnavailableImages = false }
            .labelStyle(.iconOnly)
        }
        .padding(10)
        .background(.background.secondary)
      }
      if let notice = reader.notice {
        HStack {
          Text(notice).font(.caption)
          Spacer()
          Button("Dismiss", systemImage: "xmark") { reader.notice = nil }.labelStyle(.iconOnly)
        }.padding(10).background(.background.secondary)
      }
      ReaderWebView(markdown: model.text, fileURL: model.fileURL, fontScale: fontScale,
        session: reader, folders: projectAccess.folders, onLink: followLink)
        .id(ObjectIdentifier(reader))
    }
  }

  private var findBar: some View {
    HStack(spacing: 8) {
      TextField("Find in Document", text: $findQuery)
        .textFieldStyle(.roundedBorder)
        .focused($findFocused)
        .onSubmit { reader.command("nextMatch", [1]) }
        .accessibilityIdentifier("documentFindField")
      Text(findStatus)
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("documentFindCount")
      Button("Previous Match", systemImage: "chevron.up") { reader.command("nextMatch", [-1]) }
        .labelStyle(.iconOnly).disabled(reader.matchCount == 0)
        .accessibilityIdentifier("findPrevious")
      Button("Next Match", systemImage: "chevron.down") { reader.command("nextMatch", [1]) }
        .labelStyle(.iconOnly).disabled(reader.matchCount == 0)
        .accessibilityIdentifier("findNext")
      Button("Done") { showsFind = false; findQuery = ""; reader.find("") }
        .accessibilityIdentifier("closeFind")
    }
    .padding(10)
    .background(.bar)
    #if os(macOS)
      .onExitCommand { showsFind = false; findQuery = ""; reader.find("") }
    #endif
  }

  private var findStatus: String {
    guard !findQuery.isEmpty else { return "" }
    if reader.matchCount == 0 { return String(localized: "No matches") }
    return "\(reader.matchIndex + 1) / \(reader.matchCount)" + (reader.matchLimitReached ? "+" : "")
  }

  private func showFind() {
    showsFind = true
    findFocused = true
  }

  private func followLink(_ request: ReaderLinkRequest) {
    let reference = request.reference
    guard let url = URL(string: reference, relativeTo: model.fileURL)?.absoluteURL else { return }
    if ["https", "http", "mailto"].contains(url.scheme?.lowercased() ?? "") {
      openURL(url)
      return
    }
    do {
      let policy = DocumentResourcePolicy(documentURL: model.fileURL, grantedFolders: projectAccess.folders)
      let target = try policy.resolve(reference)
      if target == model.fileURL?.standardizedFileURL.resolvingSymlinksInPath() {
        reader.jump(url.fragment ?? "")
      } else {
        #if os(macOS)
        let destination = request.destination ?? DocumentLinkDestination.resolved(storedLinkDestination)
        let origin = model.fileURL.flatMap { MarkdownWindowManager.documentWindow(for: $0) }
          ?? MarkdownWindowManager.activeDocumentWindow
        Task { @MainActor in
          do {
            try await openDocument(at: target)
            ReaderNavigation.prepare(url: target, fragment: url.fragment)
            await MarkdownWindowManager.placeLinkedDocument(at: target, from: origin, destination: destination)
          } catch { reader.error = error.localizedDescription }
        }
        #else
          let text = try TextFileContent.read(target)
          ReaderNavigation.prepare(url: target, fragment: url.fragment)
          linkedDocument = LinkedReadingDocument(url: target, text: text)
        #endif
      }
    } catch {
      reader.error = String(localized: "The linked file is unavailable. Allow its project folder from Document Actions, then try again.")
    }
  }

  private var statusBar: some View {
    HStack(spacing: 12) {
      Label(
        model.fileURL?.lastPathComponent ?? "Markdown",
        systemImage: "doc.text"
      )
      .lineLimit(1)

      if !usesCompactLayout, let currentHeading {
        Divider()
          .frame(height: 12)
        Text(currentHeading.title)
          .lineLimit(1)
      }

      Spacer()

      if !usesCompactLayout { reloadStatus }

      if reader.markCount > 0 {
        Label("\(reader.markCount)", systemImage: "highlighter")
          .foregroundStyle(.pink)
          .help("Marks disappear when this document is closed.")
          .accessibilityIdentifier("temporaryMarkCount")
      }
      Text("Read Only")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal, 12)
    .frame(height: 28)
    .background(.bar)
    .overlay(alignment: .top) {
      Divider()
    }
  }

  @ViewBuilder
  private var reloadStatus: some View {
    switch model.reloadState {
    case .watching:
      Label("Live", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
    case .reloaded:
      Label("Reloaded", systemImage: "checkmark.circle")
    case .unavailable:
      Label("Not Watching", systemImage: "exclamationmark.triangle")
    case .documentManaged:
      Label("Files", systemImage: "folder")
    }
  }

  private var currentHeading: MarkdownHeading? {
    reader.headings.first { $0.id == reader.currentSectionID }
  }

  private var isContentsVisible: Bool {
    splitViewVisibility != .detailOnly
  }

  private func toggleContents() {
    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
      splitViewVisibility = isContentsVisible ? .detailOnly : .all
    }
  }
}

private struct OutlineSidebar: View {
  let headings: [MarkdownHeading]
  let currentSectionID: String?
  let onSelect: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Contents", systemImage: "list.bullet.indent")
        .font(.headline)
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 10)

      Divider()

      if headings.isEmpty {
        ContentUnavailableView(
          "No Headings",
          systemImage: "text.alignleft",
          description: Text("This document has no headings.")
        )
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 1) {
            ForEach(headings) { heading in
              Button {
                onSelect(heading.id)
              } label: {
                Text(heading.title)
                  .font(.callout)
                  .lineLimit(2)
                  .multilineTextAlignment(.leading)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(.leading, CGFloat(max(heading.level - 1, 0)) * 14)
                  .padding(.horizontal, 9)
                  .padding(.vertical, 4)
                  .contentShape(.rect)
              }
              .buttonStyle(.plain)
              .foregroundStyle(
                currentSectionID == heading.id ? .primary : .secondary
              )
              .background(
                currentSectionID == heading.id
                  ? Color.accentColor.opacity(0.16)
                  : Color.clear,
                in: RoundedRectangle(cornerRadius: 7)
              )
              .accessibilityAddTraits(
                currentSectionID == heading.id ? .isSelected : []
              )
            }
          }
          .padding(8)
        }
      }
    }
    .background(.background.secondary)
  }
}
