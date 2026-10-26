import SwiftUI
import Textual

struct ReadingSettingsView: View {
  @AppStorage(ReadingPreferences.fontScaleKey)
  private var storedFontScale = ReadingPreferences.defaultFontScale
  @AppStorage(ReadingPreferences.linkDestinationKey)
  private var storedLinkDestination = ReadingPreferences.defaultLinkDestination.rawValue

  private var fontScale: Double {
    ReadingPreferences.normalizedFontScale(storedFontScale)
  }

  var body: some View {
    Form {
      Section {
        HStack {
          Text("Text Size")
          Spacer()
          Text(fontScale, format: .percent.precision(.fractionLength(0)))
            .monospacedDigit()
            .foregroundStyle(.secondary)
        }
        Slider(
          value: Binding(
            get: { fontScale },
            set: { storedFontScale = ReadingPreferences.normalizedFontScale($0) }
          ),
          in: ReadingPreferences.fontScaleRange,
          step: ReadingPreferences.fontScaleStep
        ) {
          Text("Text Size")
        } minimumValueLabel: {
          Image(systemName: "textformat.size.smaller")
        } maximumValueLabel: {
          Image(systemName: "textformat.size.larger")
        }
        .accessibilityIdentifier("readerFontScale")
        .accessibilityValue(Text(fontScale, format: .percent.precision(.fractionLength(0))))

        Button("Reset to Default") {
          storedFontScale = ReadingPreferences.defaultFontScale
        }
        .accessibilityIdentifier("resetReaderFontScale")
      } header: {
        Text("Reading")
      } footer: {
        #if os(macOS)
        Text(
          "Applies immediately to all open documents on this device. System text size is also respected. Printing is unchanged."
        )
        #else
        Text("Applies immediately to all open documents on this device. System text size is also respected.")
        #endif
      }

      #if os(macOS)
        Section {
          Picker("Open Document Links In", selection: Binding(
            get: { DocumentLinkDestination.resolved(storedLinkDestination) },
            set: { storedLinkDestination = $0.rawValue }
          )) {
            Text("New Tab").tag(DocumentLinkDestination.tab)
            Text("New Window").tag(DocumentLinkDestination.window)
          }
          .accessibilityIdentifier("documentLinkDestination")
        } header: {
          Text("Document Links")
        } footer: {
          Text("Choose where linked local documents open. Web links open in your browser.")
        }
      #endif

      Section("Preview") {
        StructuredText(
          markdown: String(localized: "## Ayami\n\nRead Markdown quietly.\n\n- Headings, paragraphs and code scale together.")
        )
        .textual.structuredTextStyle(.gitHub)
        .textual.fontScale(CGFloat(fontScale))
      }
    }
    .formStyle(.grouped)
    .onAppear {
      storedFontScale = fontScale
    }
  }
}

struct ReadingSettingsSheet: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ReadingSettingsView()
        .navigationTitle("Reading Settings")
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button("Done") { dismiss() }
          }
        }
    }
    #if os(macOS)
      .frame(width: 460, height: 440)
    #endif
  }
}
