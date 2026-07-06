import SwiftUI

@main
struct SnippetMiniApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Snippet Mini", systemImage: "doc.on.doc") {
            MenuBarContentView()
                .environmentObject(appDelegate.store)
        }
        .menuBarExtraStyle(.menu)

        Window("スニペット管理", id: "editor") {
            SnippetEditorView()
                .environmentObject(appDelegate.store)
        }
        .defaultSize(width: 640, height: 420)
    }
}
