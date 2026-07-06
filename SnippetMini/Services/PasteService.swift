import AppKit
import ApplicationServices
import Carbon
import CoreGraphics

enum PasteService {
    static var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibility(prompt: Bool = true) {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: prompt] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static func paste(_ text: String, returningTo app: NSRunningApplication?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        NSApp.hide(nil)

        if let app {
            app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            simulateCommandV()
        }
    }

    private static func simulateCommandV() {
        guard isAccessibilityTrusted else { return }

        let source = CGEventSource(stateID: .combinedSessionState)
        let keyCode = CGKeyCode(kVK_ANSI_V)

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return }

        keyDown.flags = CGEventFlags.maskCommand
        keyUp.flags = CGEventFlags.maskCommand
        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
