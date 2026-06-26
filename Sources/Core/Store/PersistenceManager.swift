import Foundation

/// Handles JSON encode/decode of `AppData` to a file in Application Support.
///
/// `save(_:)` is `nonisolated` and accepts a Sendable value-type snapshot, so it
/// can run off the main actor without capturing actor-isolated state.
public struct PersistenceManager: Sendable {

    public static let shared = PersistenceManager()

    private let fileURL: URL

    /// Default initializer points at `~/Library/Application Support/MyMemo/data.json`.
    public init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.fileURL = base
            .appendingPathComponent("MyMemo", isDirectory: true)
            .appendingPathComponent("data.json", isDirectory: false)
    }

    /// Initializer for tests — write to an arbitrary location.
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Encode and write atomically. Safe to call off the main actor.
    public func save(_ snapshot: AppData) {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // Persistence failure is non-fatal for a local scratch app; log to stderr.
            FileHandle.standardError.write(Data("MyMemo: save failed: \(error)\n".utf8))
        }
    }

    /// Read and decode. Returns an empty `AppData` on first launch or any failure.
    public func load() -> AppData {
        guard let data = try? Data(contentsOf: fileURL) else { return AppData() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(AppData.self, from: data)) ?? AppData()
    }
}
