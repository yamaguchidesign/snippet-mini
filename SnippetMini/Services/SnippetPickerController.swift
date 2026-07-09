import AppKit
import SwiftUI

/// パネルの選択状態。矢印キーの処理はキーウィンドウになれない場面でも
/// 効くよう NSEvent監視側で行うため、SwiftUIのFocusStateではなくこちらで持つ。
@MainActor
final class PickerSelection: ObservableObject {
    @Published var index = 0
}

@MainActor
final class SnippetPickerController: NSObject {
    static let shared = SnippetPickerController()

    private var panel: KeyablePanel?
    private var previousApp: NSRunningApplication?
    private let selection = PickerSelection()
    private weak var store: SnippetStore?
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?

    private override init() {}

    func configure(store: SnippetStore) {
        self.store = store
    }

    func toggle(store: SnippetStore) {
        if panel?.isVisible == true {
            dismiss()
        } else {
            show(store: store)
        }
    }

    func show(store: SnippetStore) {
        self.store = store
        previousApp = NSWorkspace.shared.frontmostApplication

        if !PasteService.isAccessibilityTrusted {
            PasteService.requestAccessibility(prompt: true)
        }

        selection.index = 0
        let panel = panel ?? makePanel(store: store)
        self.panel = panel

        positionPanel(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        installKeyMonitor()
    }

    /// esc / キャンセル。パネルを閉じる。
    func dismiss() {
        hidePanel()
    }

    /// パネルを隠す（イベント監視も解除）。
    private func hidePanel() {
        removeKeyMonitor()
        panel?.orderOut(nil)
    }

    // 上下矢印（126/125）・Return（36）・esc（53）を処理する。
    // バックグラウンド起動だとパネルがキー入力フォーカスを得られないことがあるため、
    // SwiftUI側のFocusStateには頼らず、ローカル（フォーカスがある場合）と
    // グローバル（他アプリがアクティブでも発火）の両方でイベントを監視する。
    // グローバル監視はアクセシビリティ権限が前提。
    private func installKeyMonitor() {
        removeKeyMonitor()
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.handleKeyDown(keyCode: event.keyCode) else { return event }
            return nil
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.handleKeyDown(keyCode: event.keyCode)
        }
    }

    /// 処理したら true を返す（呼び出し元でイベントを握りつぶすかどうかの判断に使う）。
    @discardableResult
    private func handleKeyDown(keyCode: UInt16) -> Bool {
        switch keyCode {
        case 53: // esc
            dismiss()
        case 126: // up
            moveSelection(by: -1)
        case 125: // down
            moveSelection(by: 1)
        case 36, 76: // return / keypad enter
            confirmSelection()
        default:
            return false
        }
        return true
    }

    private func moveSelection(by offset: Int) {
        guard let count = store?.snippets.count, count > 0 else { return }
        selection.index = min(max(selection.index + offset, 0), count - 1)
    }

    private func confirmSelection() {
        guard let snippets = store?.snippets, snippets.indices.contains(selection.index) else { return }
        insert(snippets[selection.index])
    }

    private func removeKeyMonitor() {
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
    }

    private func makePanel(store: SnippetStore) -> KeyablePanel {
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.delegate = self

        let rootView = SnippetPickerView(
            selection: selection,
            onConfirm: { [weak self] snippet in
                self?.insert(snippet)
            },
            onOpenSettings: { [weak self] in
                guard let self else { return }
                // 管理ウィンドウを開くので accessory へは戻さず（.regular のまま）
                // フォーカスも元アプリへ戻さない。
                self.hidePanel()
                if let store = self.store {
                    EditorWindowController.shared.show(store: store)
                }
            }
        )
        .environmentObject(store)

        panel.contentView = NSHostingView(rootView: rootView)
        return panel
    }

    // 常に画面（マウスがあるスクリーン、無ければメイン）の中央に表示する。
    private func positionPanel(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) })
            ?? NSScreen.main
            ?? NSScreen.screens.first

        var frame = panel.frame
        if let screen {
            let visible = screen.visibleFrame
            frame.origin = NSPoint(
                x: visible.midX - frame.width / 2,
                y: visible.midY - frame.height / 2
            )
        }

        panel.setFrame(frame, display: true)
    }

    private func insert(_ snippet: Snippet) {
        hidePanel()
        NSApp.setActivationPolicy(.accessory)

        let text = VariableExpander.expand(snippet.body)

        if PasteService.isAccessibilityTrusted {
            PasteService.paste(text, returningTo: previousApp)
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        if let previousApp {
            previousApp.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
        }

        showAccessibilityAlert()
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "アクセシビリティの許可が必要です"
        alert.informativeText = "他のアプリへ自動でペーストするには、システム設定 › プライバシーとセキュリティ › アクセシビリティ で Snippet Mini をオンにしてください。いまはクリップボードにコピーしました。"
        alert.addButton(withTitle: "システム設定を開く")
        alert.addButton(withTitle: "OK")

        if alert.runModal() == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

extension SnippetPickerController: NSWindowDelegate {
    // 他アプリのウィンドウをクリックしてキーフォーカスを失ったらパネルを消す。
    func windowDidResignKey(_ notification: Notification) {
        dismiss()
    }
}

private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
