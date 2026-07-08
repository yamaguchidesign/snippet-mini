import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var store: SnippetStore

    var body: some View {
        Button("スニペットを挿入…  ⌥⌘Space") {
            SnippetPickerController.shared.show(store: store)
        }
        .disabled(store.snippets.isEmpty)

        Divider()

        if PasteService.isAccessibilityTrusted {
            Text("アクセシビリティ: 許可済み")
                .foregroundStyle(.secondary)
        } else {
            Button("アクセシビリティを許可…") {
                PasteService.requestAccessibility(prompt: true)
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }

        Divider()

        Button("スニペットを管理…") {
            EditorWindowController.shared.show(store: store)
        }

        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
