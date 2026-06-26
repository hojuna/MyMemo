import SwiftUI

// MARK: - TodoRowEditorView

/// A single polished todo row. Reads live from the store, writes via
/// computed Bindings — no cached @State that could desync.
public struct TodoRowEditorView: View {

    @State private var store: AppStore
    let todoID: UUID

    /// Internal hover/expand state — purely local, not persisted.
    @State private var isHovering = false
    @State private var showDatePicker = false

    public init(store: AppStore, todoID: UUID) {
        self._store = State(initialValue: store)
        self.todoID = todoID
    }

    // MARK: Live lookups

    private var todo: Todo? {
        store.data.todos.first { $0.id == todoID }
    }

    // MARK: Body

    public var body: some View {
        if let todo {
            card(for: todo)
                .onAppear {
                    // Expand date picker if date was already set
                    showDatePicker = todo.dueDate != nil
                }
        }
    }

    // MARK: Card

    @ViewBuilder
    private func card(for todo: Todo) -> some View {
        let textBinding = Binding(
            get: { store.data.todos.first { $0.id == todoID }?.text ?? "" },
            set: { store.updateText(todoID, text: $0) }
        )
        let dueBinding = Binding(
            get: { store.data.todos.first { $0.id == todoID }?.dueDate ?? Date() },
            set: { store.updateDueDate(todoID, dueDate: $0) }
        )

        let urgency = rowUrgency(for: todo)

        HStack(spacing: 0) {
            // Left accent stripe
            urgencyStripe(urgency: urgency, isDone: todo.isDone)

            VStack(alignment: .leading, spacing: 5) {
                // Main row
                HStack(spacing: 9) {
                    doneButton(isDone: todo.isDone)

                    TextField("할 일", text: textBinding)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .strikethrough(todo.isDone, color: .secondary)
                        .foregroundStyle(todo.isDone ? AnyShapeStyle(Color.secondary) : AnyShapeStyle(Color.primary))

                    Spacer(minLength: 4)

                    importantButton(isImportant: todo.isImportant)
                }

                // Date + delete row (shown on hover or when date exists)
                if isHovering || todo.dueDate != nil {
                    dateDeleteRow(todo: todo, dueBinding: dueBinding, urgency: urgency)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
        }
        .background(rowBackground(urgency: urgency, isDone: todo.isDone))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .animation(.easeInOut(duration: 0.16), value: isHovering)
        .animation(.easeInOut(duration: 0.18), value: todo.isDone)
        .onHover { isHovering = $0 }
    }

    // MARK: Sub-views

    private func urgencyStripe(urgency: RowUrgency, isDone: Bool) -> some View {
        Rectangle()
            .fill(isDone ? Color.clear : urgency.stripeColor)
            .frame(width: 3)
            .clipShape(
                .rect(topLeadingRadius: 8, bottomLeadingRadius: 8, style: .continuous)
            )
    }

    private func doneButton(isDone: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                store.toggleDone(todoID)
            }
        } label: {
            ZStack {
                // Fill (transparent when not done) makes the WHOLE circle a hit
                // target — a hollow strokeBorder only registers clicks on the thin
                // ring, which is why it felt unclickable.
                Circle()
                    .fill(isDone ? Color.editorAmber.opacity(0.85) : Color.primary.opacity(0.001))
                Circle()
                    .strokeBorder(isDone ? Color.clear : Color.primary.opacity(0.3), lineWidth: 1.5)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 22, height: 22)
            .padding(4)                 // enlarge the clickable target
            .contentShape(Rectangle())  // entire 30×30 area is clickable
        }
        .buttonStyle(.plain)
    }

    private func importantButton(isImportant: Bool) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                store.toggleImportant(todoID)
            }
        } label: {
            Image(systemName: isImportant ? "star.fill" : "star")
                .font(.system(size: 12))
                .foregroundStyle(isImportant ? Color.editorAmber : Color.primary.opacity(0.2))
                .scaleEffect(isImportant ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dateDeleteRow(todo: Todo, dueBinding: Binding<Date>, urgency: RowUrgency) -> some View {
        HStack(spacing: 8) {
            // Date toggle chip
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if todo.dueDate != nil {
                        store.updateDueDate(todoID, dueDate: nil)
                        showDatePicker = false
                    } else {
                        store.updateDueDate(todoID, dueDate: Date())
                        showDatePicker = true
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: todo.dueDate != nil ? "calendar.badge.checkmark" : "calendar.badge.plus")
                        .font(.system(size: 10))
                    if todo.dueDate == nil {
                        Text("마감일")
                            .font(.system(size: 10))
                    }
                }
                .foregroundStyle(todo.dueDate != nil ? urgency.labelColor : Color.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(todo.dueDate != nil ? urgency.chipBackground : Color.primary.opacity(0.06))
                )
            }
            .buttonStyle(.plain)

            // Inline date picker when a date is set
            if todo.dueDate != nil {
                DatePicker("", selection: dueBinding, displayedComponents: [.date])
                    .labelsHidden()
                    .font(.system(size: 10))
                    .datePickerStyle(.compact)
                    .scaleEffect(0.82, anchor: .leading)
                    .frame(height: 20)
                    .clipped()
            }

            Spacer()

            // Delete button (hover only)
            if isHovering {
                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        store.deleteTodo(todoID)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.editorRed.opacity(0.7))
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.editorRed.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.leading, 29)  // align under text, past the done button
    }

    private func rowBackground(urgency: RowUrgency, isDone: Bool) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(isDone
                ? Color.primary.opacity(0.03)
                : (urgency == .overdue
                    ? Color.editorRed.opacity(isHovering ? 0.07 : 0.04)
                    : (urgency == .dueSoon
                        ? Color.editorAmber.opacity(isHovering ? 0.10 : 0.06)
                        : Color.primary.opacity(isHovering ? 0.05 : 0.03)
                    )
                )
            )
    }
}

// MARK: - Urgency

enum RowUrgency {
    case normal, dueSoon, overdue

    var stripeColor: Color {
        switch self {
        case .normal:  return Color.primary.opacity(0.12)
        case .dueSoon: return Color.editorAmber
        case .overdue: return Color.editorRed
        }
    }

    var labelColor: Color {
        switch self {
        case .normal:  return .secondary
        case .dueSoon: return Color.editorAmber
        case .overdue: return Color.editorRed
        }
    }

    var chipBackground: Color {
        switch self {
        case .normal:  return Color.primary.opacity(0.06)
        case .dueSoon: return Color.editorAmber.opacity(0.12)
        case .overdue: return Color.editorRed.opacity(0.10)
        }
    }
}

private func rowUrgency(for todo: Todo) -> RowUrgency {
    guard let due = todo.dueDate, !todo.isDone else { return .normal }
    let now = Date()
    if due < now { return .overdue }
    if due.timeIntervalSince(now) <= 24 * 60 * 60 { return .dueSoon }
    return .normal
}
