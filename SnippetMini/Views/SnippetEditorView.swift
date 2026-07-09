import SwiftUI

struct SnippetEditorView: View {
    @EnvironmentObject private var store: SnippetStore
    @State private var selection: Snippet.ID?
    @State private var draftTitle = ""
    @State private var draftBody = ""
    // loadDraft() でドラフトを書き換えている最中は onChange 経由の自動保存を止める。
    // 選択切り替え時に「新しく読み込んだ内容」が「古いID」へ保存されてしまう
    // 競合（別スニペットへの誤上書き）を防ぐためのガード。
    @State private var isLoadingDraft = false

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(store.snippets) { snippet in
                    Text(snippet.title)
                        .tag(snippet.id)
                }
                .onMove(perform: store.move)
                .onDelete(perform: store.delete)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 260)
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        addSnippet()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("新規スニペット")

                    Button {
                        deleteSelected()
                    } label: {
                        Image(systemName: "minus")
                    }
                    .disabled(selection == nil)
                    .help("削除")
                }
            }
        } detail: {
            if selection != nil {
                SnippetFormView(
                    title: $draftTitle,
                    bodyText: $draftBody,
                    onSave: save
                )
            } else {
                ContentUnavailableView(
                    "スニペットを選択",
                    systemImage: "doc.text",
                    description: Text("左の一覧から選ぶか、＋で追加してください。")
                )
            }
        }
        .frame(minWidth: 520, minHeight: 360)
        .onAppear {
            if selection == nil {
                selection = store.snippets.first?.id
            }
            loadDraftForCurrentSelection()
        }
        .onChange(of: selection) { _, _ in
            loadDraftForCurrentSelection()
        }
    }

    private func loadDraftForCurrentSelection() {
        isLoadingDraft = true
        if let selection, let snippet = store.snippets.first(where: { $0.id == selection }) {
            draftTitle = snippet.title
            draftBody = snippet.body
        } else {
            draftTitle = ""
            draftBody = ""
        }
        // onChange は同一ランループ内で同期的に呼ばれるため、
        // 次のランループまでガードを維持してから解除する。
        DispatchQueue.main.async {
            isLoadingDraft = false
        }
    }

    private func addSnippet() {
        store.add(title: "新しいスニペット", body: "")
        if let newest = store.snippets.last {
            selection = newest.id
        }
    }

    private func deleteSelected() {
        guard let selection else { return }
        store.delete(id: selection)
        self.selection = store.snippets.first?.id
    }

    private func save() {
        guard !isLoadingDraft,
              let selection,
              var snippet = store.snippets.first(where: { $0.id == selection }) else { return }
        snippet.title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "無題" : draftTitle
        snippet.body = draftBody
        store.update(snippet)
    }
}

private struct SnippetFormView: View {
    @Binding var title: String
    @Binding var bodyText: String
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionCard(title: "タイトル") {
                    TextField("", text: $title)
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.leading)
                        .onChange(of: title) { _, _ in onSave() }
                }

                sectionCard(title: "本文") {
                    TextEditor(text: $bodyText)
                        .font(.body.monospaced())
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .onChange(of: bodyText) { _, _ in onSave() }
                }

                sectionCard(title: nil) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("使える変数")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("{{date}} … 今日の日付（yyyy/MM/dd）")
                        Text("{{newline}} … 改行")
                        Text("\\n … 改行（エスケープ表記）")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(
        title: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
