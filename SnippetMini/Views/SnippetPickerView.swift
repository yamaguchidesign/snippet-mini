import SwiftUI

struct SnippetPickerView: View {
    @EnvironmentObject private var store: SnippetStore
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var selection: PickerSelection
    let onConfirm: (Snippet) -> Void
    let onOpenSettings: () -> Void

    // Drives the gentle appear animation (scale + fade in).
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .frame(width: 460, height: 380)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.hairline(colorScheme), lineWidth: 1)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.14),
                radius: 22, x: 0, y: 14)
        .scaleEffect(appeared ? 1 : 0.965)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            selection.index = min(selection.index, max(store.snippets.count - 1, 0))
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }

    // MARK: - Panel background

    private var panelBackground: some View {
        ZStack {
            Rectangle().fill(.regularMaterial)
            // A soft warm/cool wash so light mode reads "clean & fresh"
            // rather than a flat gray sheet. Gated per appearance.
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.white.opacity(0.02), Color.clear]
                    : [Color.white.opacity(0.55), Color(red: 0.97, green: 0.98, blue: 1.0).opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.accent.gradient)

                Text("スニペット")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                Text("\(store.snippets.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(Palette.chipFill(colorScheme))
                    )

                SettingsButton(action: onOpenSettings)
            }
            .padding(.horizontal, 18)
            .padding(.top, 15)
            .padding(.bottom, 13)

            Rectangle()
                .fill(Palette.hairline(colorScheme))
                .frame(height: 1)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if store.snippets.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(Array(store.snippets.enumerated()), id: \.element.id) { index, snippet in
                            SnippetPickerRow(
                                snippet: snippet,
                                isSelected: index == selection.index
                            )
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selection.index = index
                                confirmSelection()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .animation(.spring(response: 0.28, dampingFraction: 0.86),
                               value: selection.index)
                }
                .onChange(of: selection.index) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.16)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Palette.accent.opacity(colorScheme == .dark ? 0.18 : 0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "text.badge.plus")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Palette.accent.gradient)
            }

            VStack(spacing: 5) {
                Text("スニペットがありません")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("右上の設定から追加してください。")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Palette.hairline(colorScheme))
                .frame(height: 1)

            HStack(spacing: 18) {
                KeyHint(keys: ["↑", "↓"], label: "選択")
                KeyHint(keys: ["↩"], label: "挿入")
                KeyHint(keys: ["esc"], label: "閉じる")
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
        }
    }

    // MARK: - Actions

    private func confirmSelection() {
        guard store.snippets.indices.contains(selection.index) else { return }
        onConfirm(store.snippets[selection.index])
    }
}

// MARK: - Row

private struct SnippetPickerRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let snippet: Snippet
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Monogram(title: snippet.title, isSelected: isSelected)

            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(preview)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "return")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .scale(scale: 0.6)))
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background(rowBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(
                    isSelected ? Palette.accent.opacity(0.28) : Color.clear,
                    lineWidth: 1
                )
        )
        .scaleEffect(isSelected ? 1.0 : 0.995)
    }

    @ViewBuilder
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 11, style: .continuous)
            .fill(
                isSelected
                    ? AnyShapeStyle(Palette.accent.opacity(colorScheme == .dark ? 0.22 : 0.13))
                    : AnyShapeStyle(Color.clear)
            )
            .shadow(
                color: isSelected ? Palette.accent.opacity(0.18) : .clear,
                radius: 6, x: 0, y: 2
            )
    }

    private var displayTitle: String {
        snippet.title.isEmpty ? "無題のスニペット" : snippet.title
    }

    private var preview: String {
        let expanded = VariableExpander.expand(snippet.body)
            .replacingOccurrences(of: "\n", with: " ↵ ")
            .trimmingCharacters(in: .whitespaces)
        return expanded.isEmpty ? "（空）" : expanded
    }
}

// MARK: - Monogram / color chip

private struct Monogram: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        let tint = Palette.tint(for: title)
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(tint.gradient) : AnyShapeStyle(tint.opacity(0.16)))
            Text(initial)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : tint)
        }
        .frame(width: 32, height: 32)
        .shadow(color: isSelected ? tint.opacity(0.4) : .clear, radius: 5, x: 0, y: 2)
    }

    private var initial: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "#" }
        return String(first).uppercased()
    }
}

// MARK: - Settings button (hover-aware)

private struct SettingsButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Image(systemName: "gearshape")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(hovering ? Color.primary : .secondary)
            .frame(width: 28, height: 28)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(hovering ? Palette.chipFill(colorScheme) : Color.clear)
            )
            .contentShape(Rectangle())
            .onTapGesture { action() }
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.15), value: hovering)
            .help("スニペットを管理")
    }
}

// MARK: - Key hint

private struct KeyHint: View {
    @Environment(\.colorScheme) private var colorScheme
    let keys: [String]
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 3) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary.opacity(0.75))
                        .frame(minWidth: 16)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2.5)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Palette.keycapFill(colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .strokeBorder(Palette.hairline(colorScheme), lineWidth: 0.5)
                                )
                        )
                }
            }
            Text(label)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Palette

private enum Palette {
    static let accent = Color.accentColor

    static func hairline(_ scheme: ColorScheme) -> Color {
        Color.primary.opacity(scheme == .dark ? 0.12 : 0.07)
    }

    static func chipFill(_ scheme: ColorScheme) -> Color {
        Color.primary.opacity(scheme == .dark ? 0.10 : 0.06)
    }

    static func keycapFill(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.white.opacity(0.9)
    }

    // Stable-per-title soft tint for the monogram chip.
    private static let tints: [Color] = [
        Color(red: 0.36, green: 0.55, blue: 0.96), // blue
        Color(red: 0.40, green: 0.72, blue: 0.55), // green
        Color(red: 0.95, green: 0.60, blue: 0.32), // amber
        Color(red: 0.86, green: 0.44, blue: 0.60), // rose
        Color(red: 0.56, green: 0.50, blue: 0.90), // violet
        Color(red: 0.30, green: 0.70, blue: 0.78)  // teal
    ]

    static func tint(for title: String) -> Color {
        guard !title.isEmpty else { return tints[0] }
        var hash = 5381
        for scalar in title.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return tints[abs(hash) % tints.count]
    }
}
