import SwiftUI

struct SnippetPickerView: View {
    @EnvironmentObject private var store: SnippetStore

    @Binding var selectedIndex: Int
    let onConfirm: (Snippet) -> Void
    let onCancel: () -> Void
    let onOpenSettings: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            content
            Divider().opacity(0.4)
            footer
        }
        .frame(width: 440, height: 360)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
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

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            Text("スニペット")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Image(systemName: "gearshape")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .onTapGesture { onOpenSettings() }
                .help("スニペットを管理")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var content: some View {
        if store.snippets.isEmpty {
            ContentUnavailableView(
                "スニペットがありません",
                systemImage: "doc.text",
                description: Text("右上の設定から追加してください。")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .onChange(of: selectedIndex) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.12)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            KeyHint(key: "↑↓", label: "選択")
            KeyHint(key: "↩", label: "挿入")
            KeyHint(key: "esc", label: "閉じる")
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func moveSelection(by offset: Int) {
        guard !store.snippets.isEmpty else { return }
        selectedIndex = min(max(selectedIndex + offset, 0), store.snippets.count - 1)
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
        HStack(spacing: 12) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(snippet.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(preview)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
    }

    private var preview: String {
        VariableExpander.expand(snippet.body)
            .replacingOccurrences(of: "\n", with: " ↵ ")
    }
}

private struct KeyHint: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                )
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }
}
