import AppKit
import Foundation

@MainActor
final class SnippetStore: ObservableObject {
    /// 表示用（削除済みを除く）。
    @Published private(set) var snippets: [Snippet] = []
    @Published private(set) var storageDirectory: URL

    /// 削除済み（墓標）を含む全レコード。同期の統合はこちらで行う。
    private var records: [Snippet] = []

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var watcher: StorageWatcher?
    private var pendingSave: DispatchWorkItem?
    private var pendingReload: DispatchWorkItem?
    /// 自分が書いた内容。監視イベントが自分の保存由来なら無視するために使う。
    private var lastWrittenData: Data?

    /// 墓標をいつまで残すか。これより古い削除済みレコードは捨てる。
    /// 同期フォルダに置いた他のMacが起動して削除を受け取るまでの猶予。
    private static let tombstoneLifetime: TimeInterval = 60 * 60 * 24 * 30

    private var fileURL: URL {
        storageDirectory.appendingPathComponent("snippets.json")
    }

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        storageDirectory = SnippetStorageLocation.current
        Self.ensureDirectory(storageDirectory)
        load()
        startWatching()

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.writeToDisk() }
        }
    }

    // MARK: - 読み書き

    func load() {
        if let disk = readDisk() {
            records = disk
            refresh()
        } else {
            records = Self.defaultSnippets
            refresh()
            writeToDisk()
        }
    }

    /// 即時保存。文字入力のような高頻度の更新は `scheduleSave()` を使う。
    func save() {
        writeToDisk()
    }

    private func readDisk() -> [Snippet]? {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? decoder.decode([Snippet].self, from: data) else { return nil }
        return decoded
    }

    private func writeToDisk() {
        pendingSave?.cancel()
        pendingSave = nil

        // 書く直前にディスクの内容と統合する。こうしないと、他のMacが
        // 追加したスニペットをこちらの丸ごと上書きで消してしまう。
        if let disk = readDisk() {
            records = Self.merge(records, disk)
        }
        records = Self.pruningOldTombstones(records)
        refresh()

        do {
            let data = try encoder.encode(records)
            Self.ensureDirectory(storageDirectory)
            try data.write(to: fileURL, options: .atomic)
            lastWrittenData = data
        } catch {
            NSLog("SnippetMini: failed to save snippets – \(error.localizedDescription)")
        }
    }

    /// 文字入力ごとにディスクへ書くと同期フォルダが騒がしくなるので、少し待ってからまとめて書く。
    private func scheduleSave() {
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.writeToDisk() }
        }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    // MARK: - 同期（他のMacによる変更の取り込み）

    private func startWatching() {
        watcher = StorageWatcher(directory: storageDirectory, fileURL: fileURL) { [weak self] in
            self?.scheduleReload()
        }
    }

    /// アトミックな差し替えや Dropbox の同期は複数のイベントを立て続けに発生させるため、まとめて1回にする。
    private func scheduleReload() {
        pendingReload?.cancel()
        let work = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated { self?.reloadFromDisk() }
        }
        pendingReload = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }

    private func reloadFromDisk() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        guard data != lastWrittenData else { return } // 自分の保存によるイベント
        guard let disk = try? decoder.decode([Snippet].self, from: data) else { return }

        records = Self.merge(records, disk)
        refresh()

        // 統合結果がディスクと違う ＝ こちらにディスクより新しい変更がある場合だけ書き戻す。
        // 差が無いときに書かないことで、Mac 同士が書き戻し合う無限ループを避ける。
        if let encoded = try? encoder.encode(records), encoded != data {
            try? encoded.write(to: fileURL, options: .atomic)
            lastWrittenData = encoded
        } else {
            lastWrittenData = data
        }
    }

    /// 同じ id は updatedAt が新しい方を採用する。片方にしか無い id は残す。
    static func merge(_ lhs: [Snippet], _ rhs: [Snippet]) -> [Snippet] {
        var byID: [UUID: Snippet] = [:]
        for record in lhs + rhs {
            if let existing = byID[record.id], existing.updatedAt >= record.updatedAt { continue }
            byID[record.id] = record
        }
        return byID.values.sorted(by: displayOrder)
    }

    private static func pruningOldTombstones(_ records: [Snippet]) -> [Snippet] {
        let cutoff = Date().addingTimeInterval(-tombstoneLifetime)
        return records.filter { record in
            guard let deletedAt = record.deletedAt else { return true }
            return deletedAt > cutoff
        }
    }

    // MARK: - 保存先の切り替え

    func setStorageDirectory(_ url: URL) {
        guard url != storageDirectory else { return }
        writeToDisk() // 保留中の変更を今の保存先へ確定させる
        watcher = nil

        Self.ensureDirectory(url)
        storageDirectory = url
        SnippetStorageLocation.remember(url)

        // 移行先に既存の snippets.json があれば統合する（片方のMacの内容が消えないように）。
        lastWrittenData = nil
        writeToDisk()
        startWatching()
    }

    // MARK: - 編集

    func add(title: String, body: String) {
        let snippet = Snippet(title: title, body: body, sortOrder: snippets.count)
        records.append(snippet)
        refresh()
        save()
    }

    func update(_ snippet: Snippet) {
        guard let index = records.firstIndex(where: { $0.id == snippet.id }) else { return }
        var updated = snippet
        updated.updatedAt = Date()
        records[index] = updated
        refresh()
        scheduleSave()
    }

    func delete(at offsets: IndexSet) {
        for id in offsets.map({ snippets[$0].id }) {
            markDeleted(id: id)
        }
        applyOrder(activeRecordsInDisplayOrder())
        refresh()
        save()
    }

    func delete(id: UUID) {
        markDeleted(id: id)
        applyOrder(activeRecordsInDisplayOrder())
        refresh()
        save()
    }

    func move(from source: IndexSet, to destination: Int) {
        var reordered = snippets
        reordered.move(fromOffsets: source, toOffset: destination)
        applyOrder(reordered)
        refresh()
        save()
    }

    func copyExpandedBody(of snippet: Snippet) {
        let expanded = VariableExpander.expand(snippet.body)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(expanded, forType: .string)
    }

    // MARK: - 内部

    private func markDeleted(id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        let now = Date()
        records[index].deletedAt = now
        records[index].updatedAt = now
    }

    /// 与えられた並び順を records の sortOrder に書き戻す。
    /// 動かなかったスニペットの updatedAt は据え置く（他のMacの編集を不用意に上書きしないため）。
    private func applyOrder(_ ordered: [Snippet]) {
        let now = Date()
        for (order, snippet) in ordered.enumerated() {
            guard let index = records.firstIndex(where: { $0.id == snippet.id }),
                  records[index].sortOrder != order else { continue }
            records[index].sortOrder = order
            records[index].updatedAt = now
        }
    }

    private func activeRecordsInDisplayOrder() -> [Snippet] {
        records.filter { !$0.isDeleted }.sorted(by: Self.displayOrder)
    }

    private func refresh() {
        snippets = activeRecordsInDisplayOrder()
    }

    /// 表示順・保存順の基準。両方のMacで同じ並び（＝同じバイト列）になるよう id で決定的に整える。
    private static func displayOrder(_ lhs: Snippet, _ rhs: Snippet) -> Bool {
        lhs.sortOrder == rhs.sortOrder
            ? lhs.id.uuidString < rhs.id.uuidString
            : lhs.sortOrder < rhs.sortOrder
    }

    private static func ensureDirectory(_ url: URL) {
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private static let defaultSnippets: [Snippet] = [
        Snippet(title: "日付付き挨拶", body: "お疲れさまです。{{newline}}{{newline}}本日は{{date}}です。", sortOrder: 0),
        Snippet(title: "署名", body: "よろしくお願いいたします。{{newline}}山口", sortOrder: 1)
    ]
}
