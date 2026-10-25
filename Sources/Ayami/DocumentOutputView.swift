import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct PDFExportDocument: FileDocument {
  static let readableContentTypes: [UTType] = [.pdf]
  let data: Data
  init(data: Data) { self.data = data }
  init(configuration: ReadConfiguration) throws {
    guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
    self.data = data
  }
  func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}

struct DocumentOutputView: View {
  let markdown: String
  let fileURL: URL?
  @Environment(\.dismiss) private var dismiss
  @State private var paper = OutputPaper.a4
  @State private var output: GeneratedPDF?
  @State private var errorMessage: String?
  @State private var showsExporter = false
  @State private var hasSavedPDF = false

  private var title: String {
    OutputDocument.title(for: fileURL)
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Print and PDF").font(.headline)
        Spacer()
        Picker("Paper Size", selection: $paper) {
          ForEach(OutputPaper.allCases) { Text($0.rawValue).tag($0) }
        }
        .fixedSize()
        .accessibilityIdentifier("outputPaper")
      }
      .padding()
      Divider()
      if let output {
        PDFOutputPreview(data: output.data)
          .accessibilityIdentifier("pdfPreview")
        Divider()
        VStack(alignment: .leading, spacing: 5) {
          Text("\(output.pageCount) pages · \(output.diagramCount) diagrams")
            .font(.caption).accessibilityIdentifier("pdfReady")
          if hasSavedPDF {
            Text("PDF saved.").font(.caption).foregroundStyle(.secondary)
              .accessibilityIdentifier("pdfSaved")
          }
          ForEach(output.warnings.indices, id: \.self) { index in
            Text(output.warnings[index]).font(.caption).foregroundStyle(.orange)
          }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
      } else if let errorMessage {
        ContentUnavailableView("PDF unavailable", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
          .accessibilityIdentifier("pdfError")
      } else {
        Spacer()
        ProgressView("Preparing PDF…").accessibilityIdentifier("pdfPreparing")
        Spacer()
      }
      HStack {
        Button("Done") { dismiss() }.keyboardShortcut(.cancelAction)
        Spacer()
        if let output {
          PlatformPrintButton(data: output.data, title: title).fixedSize()
          Button("Save PDF…") { hasSavedPDF = false; showsExporter = true }
            .accessibilityIdentifier("savePDF")
        }
      }.padding()
    }
    .frame(minWidth: minimumWidth, minHeight: minimumHeight)
    .task(id: paper) {
      output = nil
      hasSavedPDF = false
      errorMessage = nil
      do {
        let generated = try await DocumentPDFGenerator.generate(markdown: markdown, title: title, paper: paper)
        try Task.checkCancellation()
        output = generated
      } catch is CancellationError { }
      catch { errorMessage = error.localizedDescription }
    }
    .fileExporter(isPresented: $showsExporter, document: output.map { PDFExportDocument(data: $0.data) },
      contentType: .pdf, defaultFilename: title) { result in
      switch result {
      case .success: hasSavedPDF = true
      case let .failure(error):
        let failure = error as NSError
        if failure.domain != NSCocoaErrorDomain || failure.code != NSUserCancelledError {
          errorMessage = error.localizedDescription
        }
      }
    }
    .alert("Output failed", isPresented: Binding(
      get: { output != nil && errorMessage != nil },
      set: { if !$0 { errorMessage = nil } }
    )) {
      Button("OK") { errorMessage = nil }
    } message: { Text(errorMessage ?? "") }
  }

  private var minimumWidth: CGFloat {
    #if os(macOS)
    640
    #else
    0
    #endif
  }
  private var minimumHeight: CGFloat {
    #if os(macOS)
    600
    #else
    0
    #endif
  }
}

#if os(macOS)
private struct PDFOutputPreview: NSViewRepresentable {
  let data: Data
  final class Coordinator { var data: Data? }
  func makeCoordinator() -> Coordinator { Coordinator() }
  func makeNSView(context: Context) -> PDFView {
    let view = PDFView()
    view.autoScales = true
    view.displayMode = .singlePageContinuous
    view.document = PDFDocument(data: data)
    context.coordinator.data = data
    return view
  }
  func updateNSView(_ view: PDFView, context: Context) {
    if context.coordinator.data != data {
      view.document = PDFDocument(data: data)
      context.coordinator.data = data
    }
  }
}

private struct PlatformPrintButton: View {
  let data: Data
  let title: String
  var body: some View {
    Button("Print…") {
      guard let document = PDFDocument(data: data),
        let operation = document.printOperation(for: NSPrintInfo.shared,
          scalingMode: .pageScaleToFit, autoRotate: true) else { return }
      operation.jobTitle = title
      operation.showsPrintPanel = true
      operation.showsProgressPanel = true
      if let window = NSApp.keyWindow {
        // The preview is already a SwiftUI sheet. Attach printing to that
        // window instead of nesting another application-modal run loop.
        operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
      } else {
        operation.run()
      }
    }
    .accessibilityIdentifier("printPDF")
  }
}
#else
private struct PDFOutputPreview: UIViewRepresentable {
  let data: Data
  final class Coordinator { var data: Data? }
  func makeCoordinator() -> Coordinator { Coordinator() }
  func makeUIView(context: Context) -> PDFView {
    let view = PDFView()
    view.autoScales = true
    view.displayMode = .singlePageContinuous
    view.document = PDFDocument(data: data)
    context.coordinator.data = data
    return view
  }
  func updateUIView(_ view: PDFView, context: Context) {
    if context.coordinator.data != data {
      view.document = PDFDocument(data: data)
      context.coordinator.data = data
    }
  }
}

private struct PlatformPrintButton: UIViewRepresentable {
  let data: Data
  let title: String
  final class Coordinator {
    var data: Data
    var title: String
    init(data: Data, title: String) { self.data = data; self.title = title }
  }
  func makeCoordinator() -> Coordinator { Coordinator(data: data, title: title) }
  func makeUIView(context: Context) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(String(localized: "Print…"), for: .normal)
    button.accessibilityIdentifier = "printPDF"
    button.setContentHuggingPriority(.required, for: .horizontal)
    let coordinator = context.coordinator
    button.addAction(UIAction { [weak coordinator] action in
      guard let source = action.sender as? UIView, let coordinator else { return }
      let controller = UIPrintInteractionController.shared
      let info = UIPrintInfo(dictionary: nil)
      info.jobName = coordinator.title
      info.outputType = .general
      controller.printInfo = info
      controller.printingItem = coordinator.data
      controller.present(from: source.bounds, in: source, animated: true, completionHandler: nil)
    }, for: .touchUpInside)
    return button
  }
  func updateUIView(_ button: UIButton, context: Context) {
    // SwiftUI can coalesce a fast paper-size regeneration without removing the
    // button. Keep the native action in sync instead of capturing the first PDF.
    context.coordinator.data = data
    context.coordinator.title = title
  }
}
#endif
