import Foundation

/// フォルダの変更を監視する。ファイル単体ではなくフォルダを見るのは、
/// 保存が「一時ファイル → 差し替え」（アトミック書き込み・Dropbox の同期）で行われ、
/// ファイルの fd を握っていると差し替え後の実体を見失うため。
final class DirectoryWatcher {
    private let descriptor: Int32
    private let source: DispatchSourceFileSystemObject

    init?(url: URL, onChange: @escaping () -> Void) {
        descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename],
            queue: .main
        )
        source.setEventHandler(handler: onChange)
        let fd = descriptor
        source.setCancelHandler { close(fd) }
        source.resume()
    }

    deinit {
        source.cancel()
    }
}
