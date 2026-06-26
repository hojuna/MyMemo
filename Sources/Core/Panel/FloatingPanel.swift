import AppKit

/// A borderless, translucent, always-on-top panel that never steals focus.
public final class FloatingPanel: NSPanel {

    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        // Float above normal windows, including over the Dock area.
        level = .floating
        // Visible on every Space and during fullscreen; stays put on switches.
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        // Glued to the Dock — the user must not be able to drag it around.
        isMovable = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        // Keep the panel out of the window cycle / app-switcher.
        isExcludedFromWindowsMenu = true
        becomesKeyOnlyIfNeeded = true
    }

    // Never become key or main — this is the core "do not steal focus" guarantee.
    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }
}
