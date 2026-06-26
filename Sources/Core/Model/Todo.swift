import Foundation

/// A single to-do item. Value type, Codable for JSON persistence, Sendable for
/// safe transfer across the actor boundary into off-main-actor persistence.
public struct Todo: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var text: String
    /// "starred" — manual user-set importance flag.
    public var isImportant: Bool
    /// Optional deadline. `nil` means no due date.
    public var dueDate: Date?
    /// Completion flag.
    public var isDone: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        text: String,
        isImportant: Bool = false,
        dueDate: Date? = nil,
        isDone: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isImportant = isImportant
        self.dueDate = dueDate
        self.isDone = isDone
        self.createdAt = createdAt
    }
}
