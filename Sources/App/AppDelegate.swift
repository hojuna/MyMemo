import AppKit
import MyMemoCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panelController: PanelWindowController?
    private var statusItemController: StatusItemController?
    private var editorController: EditorWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Agent app: no Dock icon, menu-bar status item is the entry point.
        NSApp.setActivationPolicy(.accessory)

        // Editor window (created up front, shown on demand).
        let editor = EditorWindowController(store: .shared)
        editorController = editor

        // Floating panel (read-only display). Double-click opens the editor.
        let panel = PanelWindowController(store: .shared, onOpenEditor: { editor.show() })
        panel.show()
        panelController = panel

        // Menu-bar status item — the user's entry point.
        statusItemController = StatusItemController(
            onOpenEditor: { [weak self] in self?.editorController?.show() },
            onTogglePanel: { [weak self] in self?.panelController?.toggleVisibility() }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppStore.shared.saveNow()
    }
}
