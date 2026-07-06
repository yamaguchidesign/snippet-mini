import SwiftUI

@main
struct SnippetMiniApp: App {
    @StateObject private var store = SnippetStore()

    var body: some Scene {
        MenuBarExtra("Snippet Mini", systemImage: "doc.on.doc") {
            MenuBarContentView()
                .environmentObject(store)
        }
        .menuBarExtraStyle(.menu)

        Window("スニペット管理", id: "editor") {
            SnippetEditorView()
                .environmentObject(store)
        }
        .defaultSize(width: 640, height: 420)
    }
}
