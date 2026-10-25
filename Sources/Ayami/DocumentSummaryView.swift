import SwiftUI

struct DocumentSummaryView: View {
  let markdown: String
  @Environment(\.dismiss) private var dismiss
  @State private var state = SummaryAvailability.notReady
  @State private var summary: String?
  @State private var errorMessage: String?
  @State private var task: Task<Void, Never>?
  @State private var progress: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Document Highlights (Prototype)").font(.title2.bold())
      Text("Only the open document is processed, on this device. Nothing is uploaded or written back to the file.")
        .font(.caption).foregroundStyle(.secondary)
      Text(state.message).font(.callout).accessibilityIdentifier("summaryAvailability")
      if task != nil {
        ProgressView(progress ?? String(localized: "Generating highlights…"))
          .accessibilityIdentifier("summaryGenerating")
      }
      if let summary {
        ScrollView {
          Text(summary).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("summaryResult")
        }
        Text("AI-generated highlights may contain mistakes. Check the original document.")
          .font(.caption).foregroundStyle(.secondary)
      } else if let errorMessage {
        ScrollView { Text(errorMessage).foregroundStyle(.red).textSelection(.enabled) }
          .accessibilityIdentifier("summaryError")
      } else { Spacer() }
      HStack {
        Button(task == nil ? String(localized: "Done") : String(localized: "Cancel")) { task?.cancel(); dismiss() }
          .keyboardShortcut(.cancelAction)
        Spacer()
        Button("Check Again") { state = DocumentSummary.availability() }
          .disabled(task != nil)
        Button("Generate Highlights") { generate() }
          .disabled(state != .available || task != nil)
          .accessibilityIdentifier("generateSummary")
      }
    }
    .padding(24)
    .frame(minWidth: minimumWidth, minHeight: minimumHeight)
    .onAppear { state = DocumentSummary.availability() }
    .onDisappear { task?.cancel() }
  }

  private var minimumWidth: CGFloat {
    #if os(macOS)
    560
    #else
    0
    #endif
  }

  private var minimumHeight: CGFloat {
    #if os(macOS)
    400
    #else
    0
    #endif
  }

  private func generate() {
    summary = nil
    errorMessage = nil
    progress = nil
    task = Task { @MainActor in
      defer { task = nil }
      do {
        let result = try await DocumentSummary.generate(markdown) { current, total in
          progress = String(localized: "Reading sections") + " \(current)/\(total)"
        }
        try Task.checkCancellation()
        summary = result
      } catch is CancellationError { }
      catch { errorMessage = error.localizedDescription }
    }
  }
}
