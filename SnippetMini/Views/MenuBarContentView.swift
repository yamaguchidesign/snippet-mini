import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var store: SnippetStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if store.snippets.isEmpty {
            Text("スニペットがありません")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        } else {
            ForEach(store.snippets) { snippet in
                Button(snippet.title) {
                    store.copyExpandedBody(of: snippet)
                }
            }
        }

        Divider()

        Button("スニペットを管理…") {
            openWindow(id: "editor")
            NSApp.activate(ignoringOtherApps: true)
        }

        Button("終了") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
