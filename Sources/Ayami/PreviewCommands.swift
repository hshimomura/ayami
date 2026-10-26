import SwiftUI

struct PreviewCommandActions {
  let isContentsVisible: Bool
  let toggleContents: () -> Void
  let printDocument: () -> Void
  let find: () -> Void
  let findNext: () -> Void
  let findPrevious: () -> Void
  let markSelection: () -> Void
  let canMark: Bool
}

#if os(macOS)
struct DocumentReadingCommands: Commands {
  @FocusedValue(\.previewCommandActions) private var actions

  var body: some Commands {
    CommandGroup(after: .textEditing) {
      Button("Find in Document…") { actions?.find() }
        .keyboardShortcut("f", modifiers: .command).disabled(actions == nil)
      Button("Find Next") { actions?.findNext() }
        .keyboardShortcut("g", modifiers: .command).disabled(actions == nil)
      Button("Find Previous") { actions?.findPrevious() }
        .keyboardShortcut("g", modifiers: [.command, .shift]).disabled(actions == nil)
      Divider()
      Button("Mark Selection") { actions?.markSelection() }
        .keyboardShortcut("h", modifiers: [.command, .shift]).disabled(actions?.canMark != true)
    }
  }
}
#endif

private struct PreviewCommandActionsKey: FocusedValueKey {
  typealias Value = PreviewCommandActions
}

extension FocusedValues {
  var previewCommandActions: PreviewCommandActions? {
    get { self[PreviewCommandActionsKey.self] }
    set { self[PreviewCommandActionsKey.self] = newValue }
  }
}
