import AppKit
import Observation

/// Shared model for the floating panel's layout. Holds the "editing" state and
/// per-monitor manual overrides (keyed by the monitor's resolution). Observed by
/// both the editor window (controls) and the panel controller (applies them).
@MainActor
@Observable
public final class PanelLayout {

    public static let shared = PanelLayout()

    /// True while the user is manually positioning / sizing the panel.
    public var isEditing = false

    /// Live width bound to the editor's slider while editing.
    public var editWidth: CGFloat = 320

    /// Request flags consumed (and reset) by the panel controller.
    public internal(set) var saveRequested = false
    public internal(set) var resetRequested = false

    /// Invoked on any editor-driven change so the controller applies it
    /// immediately instead of waiting for the next poll tick.
    public var onRequest: (() -> Void)?

    /// Set by the panel controller; called by the panel view on hover so a
    /// narrow panel can temporarily expand to reveal its full content.
    public var hoverHandler: ((Bool) -> Void)?

    private let defaultsKey = "panelOverrides.v1"
    /// monitorKey ("WxH") -> [relX, relY, width, height] relative to screen origin.
    private var overrides: [String: [Double]]

    private init() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let dict = try? JSONDecoder().decode([String: [Double]].self, from: data) {
            overrides = dict
        } else {
            overrides = [:]
        }
    }

    // MARK: - Editor-facing actions

    public func beginEditing() { isEditing = true; onRequest?() }
    public func setWidth(_ w: CGFloat) { editWidth = w; onRequest?() }
    public func requestSave() { saveRequested = true; onRequest?() }
    public func requestReset() { resetRequested = true; onRequest?() }
    public func cancelEditing() { isEditing = false; onRequest?() }

    public func hasOverride(forKey key: String) -> Bool { overrides[key] != nil }

    // MARK: - Controller-facing storage

    public func override(forKey key: String) -> [Double]? { overrides[key] }

    public func setOverride(_ rect: [Double], forKey key: String) {
        overrides[key] = rect
        persist()
    }

    public func clearOverride(forKey key: String) {
        overrides.removeValue(forKey: key)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(overrides) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
