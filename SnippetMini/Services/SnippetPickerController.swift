import AppKit
import SwiftUI

@MainActor
final class SnippetPickerController {
    static let shared = SnippetPickerController()

    private var panel: KeyablePanel?
    private var previousApp: NSRunningApplication?
    private var selectedIndex = 0
    private weak var store: SnippetStore?

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
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func dismiss() {
        panel?.orderOut(nil)
    }

    private func makePanel(store: SnippetStore) -> KeyablePanel {
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 360),
            styleMask: [.borderless, .nonactivatingPanel],
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
                self.dismiss()
                if let store = self.store {
                    EditorWindowController.shared.show(store: store)
                }
            }
        )
        .environmentObject(store)

        panel.contentView = NSHostingView(rootView: rootView)
        return panel
    }

    private func positionPanel(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        var frame = panel.frame
        frame.origin = NSPoint(
            x: mouse.x - frame.width / 2,
            y: mouse.y - frame.height - 16
        )

        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main {
            let visible = screen.visibleFrame
            frame.origin.x = min(max(frame.origin.x, visible.minX + 12), visible.maxX - frame.width - 12)
            frame.origin.y = min(max(frame.origin.y, visible.minY + 12), visible.maxY - frame.height - 12)
        }

        panel.setFrame(frame, display: true)
    }

    private func insert(_ snippet: Snippet) {
        dismiss()

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
