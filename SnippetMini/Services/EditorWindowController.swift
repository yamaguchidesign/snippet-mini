import AppKit
import SwiftUI

/// スニペット管理ウィンドウを AppKit で明示的に開閉する。
/// SwiftUI の Window シーンだとアプリのアクティブ化のたびに勝手に復元されて
/// しまうため、必要なとき（メニューバー or パネルの設定アイコン）だけ開く。
@MainActor
final class EditorWindowController: NSObject, NSWindowDelegate {
    static let shared = EditorWindowController()

    private var window: NSWindow?
    private weak var store: SnippetStore?

    private override init() {}

    func configure(store: SnippetStore) {
        self.store = store
    }

    func show(store: SnippetStore) {
        self.store = store

        if window == nil {
            let hosting = NSHostingController(
                rootView: SnippetEditorView().environmentObject(store)
            )
            let window = NSWindow(contentViewController: hosting)
            window.title = "スニペット管理"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 640, height: 440))
            window.isReleasedWhenClosed = false
            // macOS のウィンドウ状態復元で、起動のたびに勝手に開くのを防ぐ
            window.isRestorable = false
            window.delegate = self
            window.center()
            self.window = window
        }

        // accessory アプリのままだとウィンドウがフォーカスを得られないため、
        // 管理ウィンドウ表示中は通常アプリ化する。
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    // ウィンドウを閉じたらメニューバー常駐へ戻す（Dock アイコンを出さない）。
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
