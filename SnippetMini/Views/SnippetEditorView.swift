import SwiftUI

struct SnippetEditorView: View {
    @EnvironmentObject private var store: SnippetStore
    @State private var selection: Snippet.ID?
    @State private var draftTitle = ""
    @State private var draftBody = ""

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
            if let selection, let snippet = store.snippets.first(where: { $0.id == selection }) {
                SnippetFormView(
                    title: $draftTitle,
                    bodyText: $draftBody,
                    onSave: { save(snippetID: snippet.id) }
                )
                .onAppear { loadDraft(from: snippet) }
                .onChange(of: selection) { _, newValue in
                    if let snippet = store.snippets.first(where: { $0.id == newValue }) {
                        loadDraft(from: snippet)
                    }
                }
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
            if let selection, let snippet = store.snippets.first(where: { $0.id == selection }) {
                loadDraft(from: snippet)
            }
        }
    }

    private func addSnippet() {
        store.add(title: "新しいスニペット", body: "")
        if let newest = store.snippets.last {
            selection = newest.id
            loadDraft(from: newest)
        }
    }

    private func deleteSelected() {
        guard let selection else { return }
        store.delete(id: selection)
        self.selection = store.snippets.first?.id
        if let first = store.snippets.first {
            loadDraft(from: first)
        } else {
            draftTitle = ""
            draftBody = ""
        }
    }

    private func loadDraft(from snippet: Snippet) {
        draftTitle = snippet.title
        draftBody = snippet.body
    }

    private func save(snippetID: UUID) {
        guard var snippet = store.snippets.first(where: { $0.id == snippetID }) else { return }
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
        Form {
            Section("タイトル") {
                TextField("メニューに表示する名前", text: $title)
                    .onChange(of: title) { _, _ in onSave() }
            }

            Section("本文") {
                TextEditor(text: $bodyText)
                    .font(.body.monospaced())
                    .frame(minHeight: 180)
                    .onChange(of: bodyText) { _, _ in onSave() }
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("使える変数")
                        .font(.subheadline.weight(.semibold))
                    Text("{{date}} … 今日の日付（yyyy/MM/dd）")
                    Text("{{newline}} … 改行")
                    Text("\\n … 改行（エスケープ表記）")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
