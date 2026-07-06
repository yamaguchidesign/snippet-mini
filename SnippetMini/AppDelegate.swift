import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = SnippetStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        SnippetPickerController.shared.configure(store: store)

        HotKeyManager.shared.onTrigger = { [weak self] in
            guard let self else { return }
            SnippetPickerController.shared.toggle(store: self.store)
        }
        HotKeyManager.shared.register()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregister()
    }
}
