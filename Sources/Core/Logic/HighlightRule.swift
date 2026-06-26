import Foundation

/// Deterministic rule that selects which todos are shown (highlighted) in the
/// read-only floating panel.
///
/// Ordering:
///   1. Exclude completed todos (`isDone == true`).
///   2. Important (starred) todos sort before non-important.
///   3. Within the same importance tier: ascending `dueDate`; `nil` due dates
///      sort LAST within their tier.
///   4. Final tiebreaker: ascending `createdAt`.
///   5. Cap the result to `max` items.
public enum HighlightRule {

    /// Default cap for v1. The panel layout is sized so ~5 rows fit comfortably.
    // TODO: measure actual panel height and compute the cap dynamically.
    public static let defaultMax = 5

    public static func highlighted(from todos: [Todo], max: Int = defaultMax) -> [Todo] {
        guard max > 0 else { return [] }

        let active = todos.filter { !$0.isDone }

        let sorted = active.sorted { lhs, rhs in
            // 1) importance tier
            if lhs.isImportant != rhs.isImportant {
                return lhs.isImportant && !rhs.isImportant
            }
            // 2) due date ascending, nil last
            switch (lhs.dueDate, rhs.dueDate) {
            case let (l?, r?):
                if l != r { return l < r }
            case (nil, _?):
                return false   // lhs has no due date -> sorts after rhs
            case (_?, nil):
                return true    // lhs has a due date -> sorts before rhs
            case (nil, nil):
                break
            }
            // 3) createdAt ascending
            return lhs.createdAt < rhs.createdAt
        }

        return Array(sorted.prefix(max))
    }

    /// Whether a todo is "due soon" (within the next 24 hours, not overdue past
    /// a day ago) — used purely for an extra visual tint in the panel.
    public static func isDueSoon(_ todo: Todo, now: Date = Date()) -> Bool {
        guard let due = todo.dueDate else { return false }
        let interval = due.timeIntervalSince(now)
        // Due within the next 24h, or already overdue.
        return interval <= 24 * 60 * 60
    }
}
