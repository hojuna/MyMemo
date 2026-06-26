import AppKit
import SwiftUI

/// Creates the floating panel and keeps it glued beside the Dock — following the
/// Dock across displays. Supports a manual edit mode where the user drags/resizes
/// the panel and saves a per-monitor override.
@MainActor
public final class PanelWindowController: NSObject {

    /// Default panel width when no override exists.
    public static let panelWidth: CGFloat = 320
    /// Fallback height when the Dock is hidden / not reserving space.
    private static let fallbackHeight: CGFloat = 96
    /// Gap kept between the panel and the screen / Dock edges.
    private static let margin: CGFloat = 12

    private enum DockEdge: Equatable { case bottom, left, right }

    public let panel: FloatingPanel
    private var followTimer: Timer?
    private let onOpenEditor: () -> Void
    private var wasEditing = false

    // Hover-to-expand state: a narrow panel grows on hover and shrinks back.
    private var hoverExpanded = false
    private var collapsedFrame: NSRect?
    private var hoverPollTimer: Timer?
    /// Only expand on hover if the panel is narrower than this.
    private static let hoverExpandThreshold: CGFloat = 200
    /// Size the panel expands to while hovered (clamped to screen).
    private static let hoverExpandedWidth: CGFloat = 340
    private static let hoverExpandedHeight: CGFloat = 260

    public init(store: AppStore = .shared, onOpenEditor: @escaping () -> Void = {}) {
        self.onOpenEditor = onOpenEditor

        let rect = NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.fallbackHeight)
        panel = FloatingPanel(contentRect: rect)

        // Opaque, Dock-like frosted backdrop.
        let effect = NSVisualEffectView(frame: rect)
        effect.material = .popover
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.isEmphasized = true
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 14
        effect.layer?.masksToBounds = true
        effect.layer?.borderWidth = 0.5
        effect.layer?.borderColor = NSColor.white.withAlphaComponent(0.18).cgColor
        effect.autoresizingMask = [.width, .height]

        let hosting = NSHostingView(rootView: PanelContentView(store: store))
        hosting.frame = rect
        hosting.autoresizingMask = [.width, .height]
        effect.addSubview(hosting)

        panel.contentView = effect

        super.init()

        // Double-click opens the editor (AppKit recognizer — reliable on a
        // nonactivating panel where SwiftUI taps are not).
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(handleDoubleClick))
        doubleClick.numberOfClicksRequired = 2
        hosting.addGestureRecognizer(doubleClick)

        // Apply editor-driven layout changes immediately.
        PanelLayout.shared.onRequest = { [weak self] in self?.relayout() }
        PanelLayout.shared.hoverHandler = { [weak self] in self?.setHover($0) }
        panel.acceptsMouseMovedEvents = true

        relayout()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // The Dock can hop between monitors without a notification — poll.
        let timer = Timer.scheduledTimer(
            timeInterval: 0.5, target: self, selector: #selector(tick),
            userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        followTimer = timer
    }

    public func show() {
        panel.orderFrontRegardless()
    }

    @objc private func handleDoubleClick() {
        onOpenEditor()
    }

    public func toggleVisibility() {
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            relayout()
            panel.orderFrontRegardless()
        }
    }

    @objc private func screenParametersChanged() { relayout() }
    @objc private func tick() { relayout() }

    // MARK: - Relayout (edit mode, overrides, auto-follow)

    private func relayout() {
        let L = PanelLayout.shared

        // Consume edit requests.
        if L.saveRequested {
            L.saveRequested = false
            saveCurrentFrameAsOverride()
            L.isEditing = false
        }
        if L.resetRequested {
            L.resetRequested = false
            if let scr = dockScreen() { L.clearOverride(forKey: screenKey(scr)) }
            L.isEditing = false
        }

        // Hover-expanded: don't fight the temporary expansion.
        if hoverExpanded { return }

        // Editing: let the user drag & resize; don't auto-reposition.
        if L.isEditing {
            if !wasEditing {
                wasEditing = true
                panel.isMovable = true
                panel.isMovableByWindowBackground = true
                L.editWidth = panel.frame.width
            }
            applyEditWidth(L.editWidth)
            return
        }
        if wasEditing {
            wasEditing = false
            panel.isMovable = false
            panel.isMovableByWindowBackground = false
        }

        // Normal: use this monitor's saved override, else auto-anchor to the Dock.
        guard let screen = dockScreen() else { return }
        if let ov = L.override(forKey: screenKey(screen)), ov.count == 4 {
            let f = NSRect(x: screen.frame.minX + ov[0], y: screen.frame.minY + ov[1],
                           width: ov[2], height: ov[3])
            panel.setFrame(clampOnScreen(f, screen), display: true)
        } else {
            anchorBesideDock(on: screen)
        }
    }

    // MARK: - Hover to expand

    /// Hover enter from the panel view triggers a one-time expand. We deliberately
    /// IGNORE the hover=false event (it fires spuriously while the resize
    /// animation reshapes the tracking area, which caused jitter). Collapse is
    /// driven instead by polling the real cursor location against the expanded
    /// frame — so the panel only shrinks when the mouse genuinely leaves.
    private func setHover(_ hovering: Bool) {
        guard hovering, !PanelLayout.shared.isEditing, !hoverExpanded else { return }
        guard panel.frame.width < Self.hoverExpandThreshold,
              let screen = panel.screen ?? dockScreen() else { return }

        collapsedFrame = panel.frame
        hoverExpanded = true

        var f = panel.frame
        f.size.width = min(Self.hoverExpandedWidth, screen.frame.width - 2 * Self.margin)
        f.size.height = min(Self.hoverExpandedHeight, screen.frame.height - 2 * Self.margin)
        if f.maxX > screen.frame.maxX - Self.margin {
            f.origin.x = screen.frame.maxX - Self.margin - f.width
        }
        if f.minX < screen.frame.minX + Self.margin {
            f.origin.x = screen.frame.minX + Self.margin
        }
        if f.maxY > screen.frame.maxY - Self.margin {
            f.origin.y = screen.frame.maxY - Self.margin - f.height
        }

        panel.level = aboveDockLevel      // draw in front of the Dock
        animateFrame(f)
        startHoverPoll()
    }

    private func startHoverPoll() {
        hoverPollTimer?.invalidate()
        let timer = Timer.scheduledTimer(
            timeInterval: 0.15, target: self, selector: #selector(hoverPoll),
            userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        hoverPollTimer = timer
    }

    /// Collapse once the cursor has truly left the expanded frame.
    @objc private func hoverPoll() {
        guard hoverExpanded else { hoverPollTimer?.invalidate(); hoverPollTimer = nil; return }
        // A little tolerance so edge jitter doesn't collapse prematurely.
        let area = panel.frame.insetBy(dx: -4, dy: -4)
        if !area.contains(NSEvent.mouseLocation) {
            collapse()
        }
    }

    private func collapse() {
        hoverPollTimer?.invalidate()
        hoverPollTimer = nil
        guard hoverExpanded, let collapsed = collapsedFrame else { return }
        hoverExpanded = false
        collapsedFrame = nil
        animateFrame(collapsed) { [weak self] in
            self?.panel.level = .floating
        }
    }

    /// A window level just above the Dock so the expanded panel covers it.
    private var aboveDockLevel: NSWindow.Level {
        NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
    }

    private func animateFrame(_ frame: NSRect, completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
        }, completionHandler: completion)
    }

    private func applyEditWidth(_ w: CGFloat) {
        guard let screen = panel.screen ?? dockScreen() else { return }
        var f = panel.frame
        let maxW = screen.frame.width - 2 * Self.margin
        let width = min(max(60, w), maxW)
        guard abs(f.width - width) > 0.5 else { return }
        f.size.width = width
        if f.maxX > screen.frame.maxX - Self.margin { f.origin.x = screen.frame.maxX - Self.margin - width }
        if f.minX < screen.frame.minX + Self.margin { f.origin.x = screen.frame.minX + Self.margin }
        panel.setFrame(f, display: true)
    }

    private func saveCurrentFrameAsOverride() {
        guard let screen = panel.screen ?? dockScreen() else { return }
        let f = panel.frame
        let rel = [Double(f.minX - screen.frame.minX), Double(f.minY - screen.frame.minY),
                   Double(f.width), Double(f.height)]
        PanelLayout.shared.setOverride(rel, forKey: screenKey(screen))
    }

    /// Keep the panel within the screen WITHOUT forcing an edge margin, so a
    /// panel saved flush to the bottom (matching the Dock height) stays flush
    /// instead of being lifted up by a margin.
    private func clampOnScreen(_ frame: NSRect, _ screen: NSScreen) -> NSRect {
        var f = frame
        let b = screen.frame
        if f.width > b.width { f.size.width = b.width }
        if f.height > b.height { f.size.height = b.height }
        if f.maxX > b.maxX { f.origin.x = b.maxX - f.width }
        if f.minX < b.minX { f.origin.x = b.minX }
        if f.maxY > b.maxY { f.origin.y = b.maxY - f.height }
        if f.minY < b.minY { f.origin.y = b.minY }
        return f
    }

    private func screenKey(_ screen: NSScreen) -> String {
        let f = screen.frame
        return "\(Int(f.width))x\(Int(f.height))"
    }

    // MARK: - Dock tracking

    private func dockScreen() -> NSScreen? {
        currentDockInfo()?.screen ?? NSScreen.main
    }

    /// The screen currently hosting the Dock and which edge it sits on.
    private func currentDockInfo() -> (screen: NSScreen, edge: DockEdge, inset: CGFloat)? {
        var best: (screen: NSScreen, edge: DockEdge, inset: CGFloat)?
        for screen in NSScreen.screens {
            let full = screen.frame
            let vis = screen.visibleFrame
            let candidates: [(DockEdge, CGFloat)] = [
                (.bottom, vis.minY - full.minY),
                (.left, vis.minX - full.minX),
                (.right, full.maxX - vis.maxX)
            ]
            for (edge, inset) in candidates where inset > 1 {
                if best == nil || inset > best!.inset { best = (screen, edge, inset) }
            }
        }
        return best
    }

    /// Estimate the on-screen width of a bottom Dock from its preferences
    /// (no Accessibility permission needed; approximate).
    private func estimatedDockWidth() -> CGFloat {
        let domain = "com.apple.dock" as CFString
        func count(_ key: String) -> Int {
            (CFPreferencesCopyAppValue(key as CFString, domain) as? [Any])?.count ?? 0
        }
        let tile = (CFPreferencesCopyAppValue("tilesize" as CFString, domain) as? NSNumber)?.doubleValue ?? 48
        let apps = count("persistent-apps")
        let others = count("persistent-others")
        let showRecents = (CFPreferencesCopyAppValue("show-recents" as CFString, domain) as? Bool) ?? true
        let recents = showRecents ? count("recent-apps") : 0
        let tiles = Double(2 + apps + others + recents)   // + Finder + Trash
        let separators = Double((recents > 0 ? 1 : 0) + (others > 0 ? 1 : 0))
        let t = CGFloat(tile)
        return CGFloat(tiles) * (t * 1.12) + CGFloat(separators) * (t * 0.4) + 24 + t * 0.6
    }

    /// Auto-anchor beside the Dock, sized to the Dock's empty side space (width)
    /// and the Dock band thickness (height). Always stays fully on-screen.
    public func anchorBesideDock(on screen: NSScreen? = nil) {
        let m = Self.margin
        guard let info = currentDockInfo() else {
            guard let main = screen ?? NSScreen.main else { return }
            let f = main.frame
            panel.setFrame(
                NSRect(x: f.maxX - Self.panelWidth - m, y: f.minY + m,
                       width: Self.panelWidth, height: Self.fallbackHeight),
                display: true)
            return
        }

        let full = info.screen.frame
        let vis = info.screen.visibleFrame

        switch info.edge {
        case .bottom:
            let dockHalf = estimatedDockWidth() / 2
            let dockClearance: CGFloat = 16
            let floorWidth: CGFloat = 90
            let capWidth: CGFloat = 600
            var x = full.midX + dockHalf + dockClearance
            var width = full.maxX - m - x
            if width > capWidth { width = capWidth }
            if width < floorWidth { width = floorWidth; x = full.maxX - m - width }
            panel.setFrame(NSRect(x: x, y: full.minY, width: width, height: info.inset), display: true)
        case .left:
            panel.setFrame(NSRect(x: vis.minX + m, y: full.minY + m,
                                  width: Self.panelWidth, height: info.inset), display: true)
        case .right:
            panel.setFrame(NSRect(x: vis.maxX - Self.panelWidth - m, y: full.minY + m,
                                  width: Self.panelWidth, height: info.inset), display: true)
        }
    }
}
