import SwiftUI

/// Read-only content for the Dock-height strip. Adapts to the available width:
/// wide → todos + memo; narrow → todos only. Double-click opens the editor.
public struct PanelContentView: View {

    @State private var store: AppStore
    @State private var layout = PanelLayout.shared

    public init(store: AppStore) {
        self._store = State(initialValue: store)
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let showMemo = w >= 240          // hide memo when the strip is narrow
            let todoCount = w >= 150 ? 3 : 2

            Group {
                if w < 110 {
                    compactSummary          // too narrow — hover to expand
                } else {
                    HStack(alignment: .top, spacing: 10) {
                        todosColumn(max: todoCount)
                        if showMemo {
                            Divider().padding(.vertical, 2)
                            memoColumn
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .contentShape(Rectangle())
            .onHover { layout.hoverHandler?($0) }
            .help("더블클릭하면 편집창이 열립니다")
            .overlay { if layout.isEditing { editOverlay } }
        }
    }

    /// Ultra-compact view for a very narrow panel: a checklist icon + the count
    /// of highlighted todos. Hovering expands the panel to reveal full content.
    private var compactSummary: some View {
        let count = store.highlightedTodos.count
        return HStack(spacing: 5) {
            Image(systemName: "checklist")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(count > 0 ? .primary : .tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var editOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .foregroundStyle(.orange)
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                Text("드래그해 이동")
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(.black.opacity(0.35)))
        }
        .allowsHitTesting(false)
    }

    private func todosColumn(max: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("할 일", systemImage: "checklist")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            let items = Array(store.highlightedTodos.prefix(max))
            if items.isEmpty {
                Text("없음")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(items) { todo in
                    HStack(spacing: 4) {
                        Image(systemName: todo.isImportant ? "star.fill" : "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(todo.isImportant ? Color.yellow : Color.secondary)
                        Text(todo.text)
                            .font(.system(size: 11))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(HighlightRule.isDueSoon(todo) ? Color.orange : Color.primary)
                    }
                }
            }
        }
        .frame(minWidth: 70, alignment: .leading)
        .layoutPriority(1)
    }

    private var memoColumn: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("메모", systemImage: "note.text")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            if store.data.memo.text.isEmpty {
                Text("비어 있음")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                Text(store.data.memo.text)
                    .font(.system(size: 11))
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
