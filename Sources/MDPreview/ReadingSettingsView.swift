import SwiftUI
import Textual

struct ReadingSettingsView: View {
  @AppStorage(ReadingPreferences.fontScaleKey)
  private var storedFontScale = ReadingPreferences.defaultFontScale

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
        Text(
          "Applies immediately to all open documents on this device. System text size is also respected. Printing is unchanged."
        )
      }

      Section("Preview") {
        StructuredText(
          markdown:
            "## Ayami\n\nRead Markdown quietly.\n\n- Headings, paragraphs and code scale together."
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
