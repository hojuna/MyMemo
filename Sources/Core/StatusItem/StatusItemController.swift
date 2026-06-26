import AppKit

/// Menu-bar status item — the only reliable entry point to the app under the
/// `.accessory` activation policy (no Dock icon).
@MainActor
public final class StatusItemController {

    private let statusItem: NSStatusItem
    private let onOpenEditor: () -> Void
    private let onTogglePanel: () -> Void

    public init(onOpenEditor: @escaping () -> Void, onTogglePanel: @escaping () -> Void) {
        self.onOpenEditor = onOpenEditor
        self.onTogglePanel = onTogglePanel
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "MyMemo")
        }

        let menu = NSMenu()

        let openItem = NSMenuItem(title: "메모 편집창 열기", action: #selector(openEditor), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)

        let toggleItem = NSMenuItem(title: "패널 표시/숨김", action: #selector(togglePanel), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "종료", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openEditor() { onOpenEditor() }
    @objc private func togglePanel() { onTogglePanel() }
    @objc private func quit() { NSApp.terminate(nil) }
}
