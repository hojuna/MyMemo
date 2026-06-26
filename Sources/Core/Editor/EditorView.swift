import SwiftUI

// MARK: - Design tokens

extension Color {
    /// Warm near-black — adapts: near-black in light, near-white in dark.
    static var editorForeground: Color { Color("editorForeground", bundle: nil) }

    // Semantic amber accent used throughout the editor.
    static let editorAmber = Color(red: 0.851, green: 0.471, blue: 0.024)  // #D97706
    static let editorAmberLight = Color(red: 1.0,  green: 0.922, blue: 0.796) // #FBEECB
    static let editorRed   = Color(red: 0.863, green: 0.149, blue: 0.149)  // #DC2626
    static let editorRedLight = Color(red: 0.996, green: 0.894, blue: 0.894) // #FEE4E4
}

// MARK: - EditorView

/// The main editor window content.  Replaces `TabView` with a custom
/// segmented header so the transition feels native and intentional.
public struct EditorView: View {

    @State private var store: AppStore
    @State private var selectedTab: EditorTab = .todos

    public init(store: AppStore) {
        self._store = State(initialValue: store)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
                .opacity(0.4)
            content
            Divider()
                .opacity(0.4)
            PanelAdjustBar()
        }
        .frame(minWidth: 380, minHeight: 460)
        .background(.background)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 0) {
            // App title / wordmark area
            HStack(spacing: 6) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.editorAmber)
                Text("MyMemo")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .padding(.leading, 16)

            Spacer()

            // Segmented tab picker
            EditorTabPicker(selection: $selectedTab)
                .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(.bar)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .todos:
            TodoListEditorView(store: store)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal:   .move(edge: .trailing).combined(with: .opacity)
                ))
        case .memo:
            MemoEditorView(store: store)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
        }
    }
}

// MARK: - Panel adjust bar (manual width/position override per monitor)

private struct PanelAdjustBar: View {
    @State private var layout = PanelLayout.shared

    var body: some View {
        Group {
            if layout.isEditing {
                editingControls
            } else {
                Button {
                    layout.beginEditing()
                } label: {
                    Label("패널 위치·폭 수정하기", systemImage: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.editorAmber)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
            }
        }
        .background(.bar)
    }

    private var editingControls: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("독 옆 패널을 드래그해 위치를 옮기고, 아래에서 폭을 조절하세요. 저장하면 이 모니터에 고정됩니다.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(get: { layout.editWidth }, set: { layout.setWidth($0) }),
                    in: 60...1200
                )
                Text("\(Int(layout.editWidth))px")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 46, alignment: .trailing)
            }

            HStack(spacing: 8) {
                Button("저장") { layout.requestSave() }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.editorAmber)
                Button("자동으로") { layout.requestReset() }
                    .buttonStyle(.bordered)
                Button("취소") { layout.cancelEditing() }
                    .buttonStyle(.bordered)
                Spacer()
            }
            .font(.system(size: 11))
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Tab model

enum EditorTab: String, CaseIterable {
    case todos = "할 일"
    case memo  = "메모"

    var icon: String {
        switch self {
        case .todos: return "checklist"
        case .memo:  return "note.text"
        }
    }
}

// MARK: - Custom segmented picker

private struct EditorTabPicker: View {
    @Binding var selection: EditorTab
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 2) {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        )
    }

    private func tabButton(_ tab: EditorTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selection = tab
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: tab.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(selection == tab ? .primary : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                if selection == tab {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                        .matchedGeometryEffect(id: "pill", in: ns)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
