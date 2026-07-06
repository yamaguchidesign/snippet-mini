import SwiftUI

struct SnippetPickerView: View {
    @EnvironmentObject private var store: SnippetStore

    @Binding var selectedIndex: Int
    let onConfirm: (Snippet) -> Void
    let onCancel: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if store.snippets.isEmpty {
                ContentUnavailableView(
                    "スニペットがありません",
                    systemImage: "doc.text",
                    description: Text("メニューバーから管理画面を開いて追加してください。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(Array(store.snippets.enumerated()), id: \.element.id) { index, snippet in
                            SnippetPickerRow(
                                snippet: snippet,
                                isSelected: index == selectedIndex
                            )
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedIndex = index
                                confirmSelection()
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .onChange(of: selectedIndex) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.12)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Text("↑↓ 選択　↩ 挿入　⎋ 閉じる")
                Spacer()
                Text("⌥⌘Space")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 360, height: 300)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .focusable()
        .focused($isFocused)
        .onAppear {
            selectedIndex = min(selectedIndex, max(store.snippets.count - 1, 0))
            isFocused = true
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            confirmSelection()
            return .handled
        }
        .onKeyPress(.escape) {
            onCancel()
            return .handled
        }
    }

    private func moveSelection(by offset: Int) {
        guard !store.snippets.isEmpty else { return }
        let next = min(max(selectedIndex + offset, 0), store.snippets.count - 1)
        selectedIndex = next
    }

    private func confirmSelection() {
        guard store.snippets.indices.contains(selectedIndex) else { return }
        onConfirm(store.snippets[selectedIndex])
    }
}

private struct SnippetPickerRow: View {
    let snippet: Snippet
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(snippet.title)
                    .font(.body.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.primary)

                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
                .padding(.horizontal, 4)
        )
    }

    private var preview: String {
        VariableExpander.expand(snippet.body)
            .replacingOccurrences(of: "\n", with: " / ")
    }
}
