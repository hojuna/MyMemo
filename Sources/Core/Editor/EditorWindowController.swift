import AppKit
import SwiftUI

/// Owns the editor `NSWindow` (hosting the SwiftUI `EditorView`).
///
/// The app normally runs as an `.accessory` agent (no Dock icon, menu-bar only).
/// An accessory app never becomes the active app, so its window controls don't
/// receive clicks (the first click is consumed just to activate the window).
/// To make the editor fully interactive, we promote the app to `.regular` while
/// the editor is open and demote back to `.accessory` when it closes.
@MainActor
public final class EditorWindowController: NSObject, NSWindowDelegate {

    private let window: NSWindow

    public init(store: AppStore = .shared) {
        let content = EditorView(store: store)
        let hosting = NSHostingController(rootView: content)

        window = NSWindow(contentViewController: hosting)
        window.title = "MyMemo"
        window.setContentSize(NSSize(width: 420, height: 520))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false   // keep instance alive after close

        super.init()
        window.delegate = self
        window.center()
    }

    /// Bring the editor to the foreground as a real active window.
    public func show() {
        NSApp.setActivationPolicy(.regular)        // become a normal foreground app
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    // When the editor closes, go back to a menu-bar-only agent (no Dock icon).
    public func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
