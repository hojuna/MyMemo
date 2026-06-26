import SwiftUI

// MARK: - MemoEditorView

public struct MemoEditorView: View {

    @State private var store: AppStore
    @FocusState private var editorFocused: Bool

    public init(store: AppStore) {
        self._store = State(initialValue: store)
    }

    // MARK: Derived stats

    private var charCount: Int {
        store.data.memo.text.count
    }

    private var lineCount: Int {
        store.data.memo.text.isEmpty ? 0 :
            store.data.memo.text.components(separatedBy: "\n").count
    }

    // MARK: Body

    public var body: some View {
        let text = Binding(
            get: { store.data.memo.text },
            set: { store.updateMemo($0) }
        )

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // TextEditor
                TextEditor(text: text)
                    .font(.system(size: 13, design: .default))
                    .lineSpacing(3)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 36)  // space for the footer bar
                    .focused($editorFocused)
                    .background(Color.clear)

                // Placeholder
                if store.data.memo.text.isEmpty {
                    Text("자유롭게 메모를 작성하세요…")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(memoBackground)
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)
            .onTapGesture {
                editorFocused = true
            }

            // Footer stat bar
            footer
        }
    }

    // MARK: Background

    private var memoBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.primary.opacity(editorFocused ? 0.045 : 0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        editorFocused
                            ? Color.editorAmber.opacity(0.4)
                            : Color.primary.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: editorFocused)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 0) {
            Spacer()
            if charCount > 0 {
                HStack(spacing: 10) {
                    statChip(icon: "character.cursor.ibeam", value: charCount, suffix: "자")
                    statChip(icon: "text.alignleft", value: lineCount, suffix: "줄")
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .animation(.easeInOut(duration: 0.2), value: charCount > 0)
    }

    private func statChip(icon: String, value: Int, suffix: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text("\(value)\(suffix)")
                .font(.system(size: 10, design: .monospaced))
        }
        .foregroundStyle(.tertiary)
    }
}
