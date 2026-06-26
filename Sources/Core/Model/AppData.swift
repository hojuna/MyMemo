import Foundation

/// Top-level persistence container. Codable + Sendable so a snapshot can be
/// captured on the main actor and written to disk off the main actor.
public struct AppData: Codable, Equatable, Sendable {
    public var todos: [Todo]
    public var memo: Memo

    public init(todos: [Todo] = [], memo: Memo = Memo()) {
        self.todos = todos
        self.memo = memo
    }
}
