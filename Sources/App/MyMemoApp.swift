import SwiftUI

/// Thin `@main` entry point. All windows are managed by `AppDelegate` in AppKit,
/// so the only SwiftUI scene is an empty `Settings` scene (which does not
/// auto-open a window at launch).
@main
struct MyMemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
