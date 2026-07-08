import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = SnippetStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        SnippetPickerController.shared.configure(store: store)
    }

    // BetterTouchTool などの外部ツールから snippetmini:// で
    // スニペット選択パネルを呼び出す。ホットキーは外部ツール側で割り当てる。
    //   snippetmini://          → パネルを表示
    //   snippetmini://pick      → パネルを表示
    //   snippetmini://toggle    → 表示中なら閉じる／非表示なら表示
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "snippetmini" {
            if url.host == "toggle" {
                SnippetPickerController.shared.toggle(store: store)
            } else {
                SnippetPickerController.shared.show(store: store)
            }
        }
    }
}
