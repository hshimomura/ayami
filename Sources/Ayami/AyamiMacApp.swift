import AppKit
import SwiftUI

@main
struct AyamiMacApp: App {
  private let showsWelcomeAtLaunch: Bool

  init() {
    NSWindow.allowsAutomaticWindowTabbing = false
    showsWelcomeAtLaunch = ReadingPreferences.shouldShowWelcomeAtLaunch()
  }

  var body: some Scene {
    Window("Welcome to Ayami", id: "welcome") {
      ReaderWelcomeView()
    }
    .windowResizability(.contentSize)
    .defaultLaunchBehavior(showsWelcomeAtLaunch ? .presented : .suppressed)
    .restorationBehavior(.disabled)
    .commands {
      ReaderWindowCommands()
    }

    DocumentGroup(viewing: MarkdownDocument.self) { configuration in
      PreviewView(
        document: configuration.document,
        fileURL: configuration.fileURL
      )
    }
    .defaultLaunchBehavior(showsWelcomeAtLaunch ? .suppressed : .automatic)
    .commands {
      OpenMarkdownFileCommands()
      DocumentReadingCommands()
      ReaderHelpCommands()

      CommandGroup(replacing: .saveItem) {
        Button("Close Tab or Window") {
          NSApp.keyWindow?.performClose(nil)
        }
        .keyboardShortcut("w", modifiers: .command)
      }

      CommandGroup(replacing: .printItem) {
        PrintDocumentCommand()
      }

      CommandGroup(replacing: .sidebar) {
        ToggleContentsCommand()
      }

      CommandGroup(after: .windowArrangement) {
        Button("Arrange Documents Side by Side") {
          MarkdownWindowManager.arrangeDocumentsSideBySide()
        }
      }
    }

    Settings {
      ReadingSettingsView()
        .frame(width: 460, height: 440)
    }
  }
}

private struct ReaderWindowCommands: Commands {
  @Environment(\.openWindow) private var openWindow

  var body: some Commands {
    CommandGroup(before: .windowList) {
      Button("Show Welcome Window") {
        openWindow(id: "welcome")
      }
      .accessibilityIdentifier("showWelcomeWindow")
    }
  }
}

private struct ReaderHelpCommands: Commands {
  @Environment(\.openWindow) private var openWindow
  @Environment(\.openDocument) private var openDocument

  var body: some Commands {
    CommandGroup(replacing: .help) {
      Button("Welcome to Ayami") { openWindow(id: "welcome") }
      Button("Open Technical Sample") {
        guard let url = TechnicalSample.url else { return }
        Task { @MainActor in
          do { try await openDocument(at: url) }
          catch { NSAlert(error: error).runModal() }
        }
      }
    }
  }
}

private struct OpenMarkdownFileCommands: Commands {
  @Environment(\.openDocument) private var openDocument

  var body: some Commands {
    CommandGroup(replacing: .newItem) {
      Button("Open File…") {
        openMarkdownFile(as: .window)
      }
      .keyboardShortcut("o", modifiers: .command)

      Button("Open File in New Tab…") {
        openMarkdownFile(as: .tab)
      }
      .keyboardShortcut("o", modifiers: [.command, .option])
    }
  }

  private func openMarkdownFile(as destination: DocumentLinkDestination) {
    let startingWindow =
      destination == .tab
      ? MarkdownWindowManager.activeDocumentWindow
      : nil
    let panel = NSOpenPanel()
    panel.title =
      destination == .tab
      ? "Open File in New Tab"
      : "Open File"
    panel.message =
      destination == .tab
      ? "Select a text document to add to the current window."
      : "Select a text document to open in a new window."
    panel.prompt = "Open"
    panel.allowedContentTypes = MarkdownDocument.readableContentTypes
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false

    guard panel.runModal() == .OK, let url = panel.url else { return }

    Task { @MainActor in
      do {
        try await openDocument(at: url)
        await Task.yield()
      } catch {
        NSAlert(error: error).runModal()
        return
      }

      guard
        destination == .tab,
        let startingWindow,
        let openedWindow = MarkdownWindowManager.documentWindow(for: url)
      else {
        return
      }

      MarkdownWindowManager.mergeAsTabs([startingWindow, openedWindow])
    }
  }
}

@MainActor
struct FileMenuOrganizer: NSViewRepresentable {
  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeNSView(context: Context) -> NSView {
    context.coordinator.attach()
    return NSView()
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    context.coordinator.attach()
  }

  static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
    coordinator.detach()
  }

  @MainActor
  final class Coordinator: NSObject {
    private weak var fileMenu: NSMenu?
    private var isUpdateScheduled = false

    func attach() {
      guard
        let menu = NSApp.mainMenu?.item(withTitle: "File")?.submenu
      else {
        return
      }

      if fileMenu !== menu {
        detach()
        fileMenu = menu
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(menuContentsDidChange(_:)),
          name: NSMenu.didBeginTrackingNotification,
          object: menu
        )
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(menuContentsDidChange(_:)),
          name: NSMenu.didAddItemNotification,
          object: menu
        )
        NotificationCenter.default.addObserver(
          self,
          selector: #selector(menuContentsDidChange(_:)),
          name: NSMenu.didChangeItemNotification,
          object: menu
        )
      }

      hideSystemOpenCommand()
    }

    func detach() {
      NotificationCenter.default.removeObserver(
        self,
        name: nil,
        object: fileMenu
      )
      fileMenu = nil
    }

    @objc
    private func menuContentsDidChange(_ notification: Notification) {
      guard !isUpdateScheduled else { return }
      isUpdateScheduled = true

      Task { @MainActor [weak self] in
        await Task.yield()
        self?.isUpdateScheduled = false
        self?.hideSystemOpenCommand()
      }
    }

    private func hideSystemOpenCommand() {
      let systemOpenAction = #selector(NSDocumentController.openDocument(_:))
      for item in fileMenu?.items ?? []
      where item.action == systemOpenAction && !item.isHidden {
        item.isHidden = true
      }
    }

    deinit {
      NotificationCenter.default.removeObserver(self)
    }
  }
}

@MainActor
enum MarkdownWindowManager {
  static var activeDocumentWindow: NSWindow? {
    guard let window = NSApp.keyWindow, isDocumentWindow(window) else {
      return nil
    }
    return window
  }

  static var documentWindows: [NSWindow] {
    var seen: Set<ObjectIdentifier> = []

    return NSApp.windows.flatMap { window -> [NSWindow] in
      let groupIsVisible = window.tabGroup?.selectedWindow?.isVisible == true
      guard
        isDocumentWindow(window),
        window.isVisible || groupIsVisible
      else {
        return []
      }

      return window.tabGroup?.windows ?? [window]
    }
    .filter { seen.insert(ObjectIdentifier($0)).inserted }
  }

  static func documentWindow(for fileURL: URL) -> NSWindow? {
    let standardizedURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()
    return NSApp.windows.first { window in
      isDocumentWindow(window)
        && window.representedURL?.standardizedFileURL.resolvingSymlinksInPath() == standardizedURL
    }
  }

  static func placeLinkedDocument(at url: URL, from origin: NSWindow?, destination: DocumentLinkDestination) async {
    // DocumentGroup may return before SwiftUI attaches the document window.
    for _ in 0..<40 {
      if let opened = documentWindow(for: url) {
        if destination == .tab, let origin, origin !== opened {
          mergeAsTabs([origin, opened])
        } else if destination == .window {
          if let group = opened.tabGroup, group.windows.count > 1 { group.removeWindow(opened) }
          opened.makeKeyAndOrderFront(nil)
        }
        return
      }
      try? await Task.sleep(for: .milliseconds(25))
      if Task.isCancelled { return }
    }
  }

  static func mergeAsTabs(_ windows: [NSWindow]) {
    let uniqueWindows = windows.reduce(into: [NSWindow]()) { result, window in
      guard !result.contains(where: { $0 === window }) else { return }
      result.append(window)
    }
    guard let anchor = uniqueWindows.first else { return }

    for window in uniqueWindows.dropFirst() where window !== anchor {
      guard anchor.tabGroup?.windows.contains(where: { $0 === window }) != true else { continue }
      anchor.addTabbedWindow(window, ordered: .above)
    }

    anchor.tabGroup?.selectedWindow = uniqueWindows.last
    uniqueWindows.last?.makeKeyAndOrderFront(nil)
  }

  static func arrangeDocumentsSideBySide() {
    let windows = documentWindows
    guard windows.count > 1, let screen = NSApp.keyWindow?.screen ?? NSScreen.main
    else {
      return
    }

    let visibleFrame = screen.visibleFrame
    let frames = MarkdownWindowLayout.sideBySideFrames(
      count: windows.count,
      in: visibleFrame
    )
    let shouldAnimate = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

    for window in windows where (window.tabGroup?.windows.count ?? 1) > 1 {
      window.tabGroup?.removeWindow(window)
      window.orderFront(nil)
    }

    NSAnimationContext.runAnimationGroup { context in
      context.duration = shouldAnimate ? 0.2 : 0

      for (window, frame) in zip(windows, frames) {
        window.animator().setFrame(frame, display: true)
      }
    }

    windows.first?.makeKeyAndOrderFront(nil)
  }

  private static func isDocumentWindow(_ window: NSWindow) -> Bool {
    window.canBecomeMain
      && !(window is NSPanel)
      && window.styleMask.contains(.titled)
      && window.tabbingIdentifier == "io.github.hshimomura.MDViewer.document"
  }
}

enum MarkdownWindowLayout {
  static func sideBySideFrames(count: Int, in visibleFrame: NSRect) -> [NSRect] {
    guard count > 0 else { return [] }

    let columnCount = min(count, 3)
    let rowCount = Int(ceil(Double(count) / Double(columnCount)))
    let windowWidth = visibleFrame.width / CGFloat(columnCount)
    let windowHeight = visibleFrame.height / CGFloat(rowCount)

    return (0..<count).map { index in
      let column = index % columnCount
      let row = index / columnCount
      return NSRect(
        x: visibleFrame.minX + CGFloat(column) * windowWidth,
        y: visibleFrame.maxY - CGFloat(row + 1) * windowHeight,
        width: windowWidth,
        height: windowHeight
      )
    }
  }
}

private struct PrintDocumentCommand: View {
  @FocusedValue(\.previewCommandActions) private var actions

  var body: some View {
    Button("Print…") {
      actions?.printDocument()
    }
    .keyboardShortcut("p", modifiers: .command)
    .disabled(actions == nil)
  }
}

private struct ToggleContentsCommand: View {
  @FocusedValue(\.previewCommandActions) private var actions

  var body: some View {
    Button(actions?.isContentsVisible == true ? "Hide Contents" : "Show Contents") {
      actions?.toggleContents()
    }
    .keyboardShortcut("s", modifiers: [.command, .control])
    .disabled(actions == nil)
  }
}
