import AppKit
import Foundation

@MainActor
final class SnippetStore: ObservableObject {
    @Published private(set) var snippets: [Snippet] = []

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SnippetMini", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent("snippets.json")
        load()
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            snippets = Self.defaultSnippets
            save()
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            snippets = try decoder.decode([Snippet].self, from: data)
                .sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            snippets = Self.defaultSnippets
            save()
        }
    }

    func save() {
        do {
            let data = try encoder.encode(snippets)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            NSLog("SnippetMini: failed to save snippets – \(error.localizedDescription)")
        }
    }

    func add(title: String, body: String) {
        let snippet = Snippet(title: title, body: body, sortOrder: snippets.count)
        snippets.append(snippet)
        save()
    }

    func update(_ snippet: Snippet) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[index] = snippet
        save()
    }

    func delete(at offsets: IndexSet) {
        snippets.remove(atOffsets: offsets)
        reindexSortOrder()
        save()
    }

    func delete(id: UUID) {
        snippets.removeAll { $0.id == id }
        reindexSortOrder()
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        snippets.move(fromOffsets: source, toOffset: destination)
        reindexSortOrder()
        save()
    }

    func copyExpandedBody(of snippet: Snippet) {
        let expanded = VariableExpander.expand(snippet.body)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(expanded, forType: .string)
    }

    private func reindexSortOrder() {
        for index in snippets.indices {
            snippets[index].sortOrder = index
        }
    }

    private static let defaultSnippets: [Snippet] = [
        Snippet(title: "日付付き挨拶", body: "お疲れさまです。{{newline}}{{newline}}本日は{{date}}です。", sortOrder: 0),
        Snippet(title: "署名", body: "よろしくお願いいたします。{{newline}}山口", sortOrder: 1)
    ]
}
