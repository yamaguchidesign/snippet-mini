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
    }
}
