import AppKit
import SwiftUI

@MainActor
final class SnippetPickerController {
    static let shared = SnippetPickerController()

    private var panel: KeyablePanel?
    private var previousApp: NSRunningApplication?
    private var selectedIndex = 0
    private weak var store: SnippetStore?
    private var localKeyMonitor: Any?
    private var globalKeyMonitor: Any?

    private init() {}

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

        selectedIndex = 0
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

    // esc（keyCode 53）でパネルを閉じる。
    // バックグラウンド起動だとパネルがキー入力フォーカスを得られないことがあるため、
    // ローカル（フォーカスがある場合）とグローバル（他アプリがアクティブでも発火）の
    // 両方でイベントを監視する。グローバル監視はアクセシビリティ権限が前提。
    private func installKeyMonitor() {
        removeKeyMonitor()
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismiss()
                return nil
            }
            return event
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.dismiss()
            }
        }
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

        let rootView = SnippetPickerView(
            selectedIndex: Binding(
                get: { [weak self] in self?.selectedIndex ?? 0 },
                set: { [weak self] in self?.selectedIndex = $0 }
            ),
            onConfirm: { [weak self] snippet in
                self?.insert(snippet)
            },
            onCancel: { [weak self] in
                self?.dismiss()
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

private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
