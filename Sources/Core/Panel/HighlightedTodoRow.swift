import SwiftUI

/// A single read-only todo row in the panel, with star + due-soon indicators.
public struct HighlightedTodoRow: View {
    let todo: Todo

    public init(todo: Todo) {
        self.todo = todo
    }

    private var dueSoon: Bool { HighlightRule.isDueSoon(todo) }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: todo.isImportant ? "star.fill" : "circle")
                .font(.caption)
                .foregroundStyle(todo.isImportant ? Color.yellow : Color.secondary)
                .frame(width: 14)

            Text(todo.text)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)

            Spacer(minLength: 4)

            if let due = todo.dueDate {
                Text(due, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(dueSoon ? Color.orange.opacity(0.25) : Color.secondary.opacity(0.15))
                    )
                    .foregroundStyle(dueSoon ? Color.orange : Color.secondary)
            }
        }
    }
}
