import Foundation

/// snippets.json の変更を監視する。
///
/// フォルダとファイルの両方を見る必要がある:
/// - ファイルだけ監視 → アトミック書き込み（一時ファイル → 差し替え）で実体を見失う
/// - フォルダだけ監視 → ファイルの中身をその場で上書きされた変更を拾えない
///
/// Dropbox の同期がどちらの書き方をするかに依存したくないので、両方を見て、
/// ファイルが差し替えられたら監視を張り直す。
final class StorageWatcher {
    private let directory: URL
    private let fileURL: URL
    private let onChange: () -> Void

    private var directorySource: DispatchSourceFileSystemObject?
    private var fileSource: DispatchSourceFileSystemObject?

    init(directory: URL, fileURL: URL, onChange: @escaping () -> Void) {
        self.directory = directory
        self.fileURL = fileURL
        self.onChange = onChange

        directorySource = Self.makeSource(for: directory, mask: [.write, .delete, .rename]) { [weak self] _ in
            // ファイルが作られた / 差し替えられた可能性があるので張り直す
            self?.rearmFileSource()
            self?.onChange()
        }
        rearmFileSource()
    }

    deinit {
        directorySource?.cancel()
        fileSource?.cancel()
    }

    private func rearmFileSource() {
        fileSource?.cancel()
        fileSource = Self.makeSource(
            for: fileURL,
            mask: [.write, .extend, .attrib, .delete, .rename]
        ) { [weak self] events in
            self?.onChange()
            if events.contains(.delete) || events.contains(.rename) {
                self?.rearmFileSource()
            }
        }
    }

    private static func makeSource(
        for url: URL,
        mask: DispatchSource.FileSystemEvent,
        handler: @escaping (DispatchSource.FileSystemEvent) -> Void
    ) -> DispatchSourceFileSystemObject? {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: mask,
            queue: .main
        )
        source.setEventHandler { [weak source] in
            guard let source else { return }
            handler(source.data)
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        return source
    }
}
