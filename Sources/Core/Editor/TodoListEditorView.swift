import SwiftUI

// MARK: - TodoListEditorView

public struct TodoListEditorView: View {

    @State private var store: AppStore
    @State private var newText: String = ""
    @State private var filter: TodoFilter = .active
    @FocusState private var addFieldFocused: Bool

    public init(store: AppStore) {
        self._store = State(initialValue: store)
    }

    // MARK: Filtered list

    private var displayedTodos: [Todo] {
        switch filter {
        case .all:      return store.data.todos
        case .active:   return store.data.todos.filter { !$0.isDone }
        case .done:     return store.data.todos.filter {  $0.isDone }
        }
    }

    private var activeCount: Int { store.data.todos.filter { !$0.isDone }.count }
    private var totalCount: Int  { store.data.todos.count }

    // MARK: Body

    public var body: some View {
        VStack(spacing: 0) {
            summaryBar
            addBar
            filterBar
            Divider().opacity(0.3)
            listContent
        }
    }

    // MARK: Summary bar

    private var summaryBar: some View {
        HStack(spacing: 0) {
            if totalCount == 0 {
                Text("할 일을 추가해 보세요")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                Text("\(activeCount)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.editorAmber)
                Text(" 개 남음 · 총 \(totalCount)개")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: Add bar

    private var addBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(addFieldFocused ? AnyShapeStyle(Color.editorAmber) : AnyShapeStyle(.tertiary))
                    .animation(.easeInOut(duration: 0.15), value: addFieldFocused)

                TextField("새 할 일 추가…", text: $newText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($addFieldFocused)
                    .onSubmit(add)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.primary.opacity(addFieldFocused ? 0.06 : 0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(
                                addFieldFocused
                                    ? Color.editorAmber.opacity(0.5)
                                    : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
            .animation(.easeInOut(duration: 0.18), value: addFieldFocused)

            Button(action: add) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(
                        newText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? AnyShapeStyle(Color.primary.opacity(0.2))
                            : AnyShapeStyle(Color.editorAmber)
                    )
                    .animation(.easeInOut(duration: 0.15), value: newText.isEmpty)
            }
            .buttonStyle(.plain)
            .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: Filter bar

    private var filterBar: some View {
        HStack(spacing: 4) {
            ForEach(TodoFilter.allCases, id: \.self) { f in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { filter = f }
                } label: {
                    Text(f.label)
                        .font(.system(size: 11, weight: filter == f ? .semibold : .regular))
                        .foregroundStyle(filter == f ? Color.editorAmber : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            if filter == f {
                                Capsule()
                                    .fill(Color.editorAmber.opacity(0.12))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    // MARK: List content

    @ViewBuilder
    private var listContent: some View {
        if displayedTodos.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(displayedTodos) { todo in
                        TodoRowEditorView(store: store, todoID: todo.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: filter == .done ? "checkmark.circle" : "checklist")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(Color.primary.opacity(0.2))
            Text(emptyMessage)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyMessage: String {
        switch filter {
        case .all:    return "할 일이 없습니다"
        case .active: return "완료되지 않은 항목이 없습니다"
        case .done:   return "완료된 항목이 없습니다"
        }
    }

    // MARK: Add action

    private func add() {
        guard !newText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            store.addTodo(newText)
            newText = ""
        }
    }
}

// MARK: - Filter

enum TodoFilter: CaseIterable {
    // 진행 중 is the primary tab (listed first, selected by default).
    case active, all, done

    var label: String {
        switch self {
        case .all:    return "전체"
        case .active: return "진행 중"
        case .done:   return "완료"
        }
    }
}
