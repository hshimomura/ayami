import AppKit
import QuickLookUI
import OSLog

// A separate API-level diagnostic host, not Finder automation. It displays only
// the explicitly supplied public fixture, never opens or saves user documents.
@MainActor
final class PreviewHost: NSWindowController, @preconcurrency QLPreviewPanelDataSource {
  let sample: URL
  init(sample: URL) {
    self.sample = sample
    super.init(window: NSWindow(contentRect: NSRect(x: 100, y: 100, width: 400, height: 180),
      styleMask: [.titled, .closable], backing: .buffered, defer: false))
    window?.title = "Ayami 1.4 Quick Look API Probe"
    let label = NSTextField(labelWithString: "Public Markdown fixture · API-level Quick Look test")
    label.frame = NSRect(x: 20, y: 70, width: 370, height: 50)
    window?.contentView?.addSubview(label)
  }
  required init?(coder: NSCoder) { fatalError("Not used") }
  nonisolated override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool { true }
  nonisolated override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
    // AppKit sends these legacy, unannotated Objective-C callbacks on main.
    MainActor.assumeIsolated { panel.dataSource = self }
  }
  nonisolated override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
    MainActor.assumeIsolated { panel.dataSource = nil }
  }
  func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { 1 }
  func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! { sample as NSURL }
}

@MainActor
final class ProbeDelegate: NSObject, NSApplicationDelegate {
  var host: PreviewHost?
  private let logger = Logger(subsystem: "io.github.hshimomura.AyamiQuickLookProbe", category: "Probe")
  nonisolated override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool { true }
  nonisolated override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
    MainActor.assumeIsolated {
      logger.info("Quick Look acquired the public-fixture data source")
      panel.dataSource = host
    }
  }
  nonisolated override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
    MainActor.assumeIsolated { panel.dataSource = nil }
  }
  func applicationDidFinishLaunching(_ notification: Notification) {
    guard let argument = CommandLine.arguments.dropFirst().first else { NSApp.terminate(nil); return }
    let host = PreviewHost(sample: URL(filePath: argument))
    self.host = host
    host.showWindow(nil)
    host.window?.makeMain()
    NSApp.activate(ignoringOtherApps: true)
    Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(500))
      let panel = QLPreviewPanel.shared()!
      panel.updateController()
      panel.makeKeyAndOrderFront(nil)
      guard panel.currentController != nil else {
        logger.error("No Quick Look panel controller acquired")
        NSApp.terminate(nil)
        return
      }
      panel.reloadData()
      panel.currentPreviewItemIndex = 0
      panel.refreshCurrentPreviewItem()
      logger.info("Quick Look API panel visible: \(panel.isVisible)")
      try? await Task.sleep(for: .seconds(12))
      panel.orderOut(nil)
      NSApp.terminate(nil)
    }
  }
}

@main
enum Probe {
  @MainActor static func main() {
    let app = NSApplication.shared
    let delegate = ProbeDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    withExtendedLifetime(delegate) { app.run() }
  }
}
