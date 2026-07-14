import Foundation

/// snippets.json の保存先の決定と永続化。
/// 同期フォルダ（Dropbox 等）を指定すると、複数の Mac が同じファイルを見る。
enum SnippetStorageLocation {
    private static let defaultsKey = "storageDirectoryPath"

    /// このMacのみ。従来の保存先。
    static var local: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("SnippetMini", isDirectory: true)
    }

    /// Dropbox の設定置き場（他アプリの設定と同じ階層に置く）。
    static var dropbox: URL {
        dropboxRoot.appendingPathComponent("app_setting/snippet_mini", isDirectory: true)
    }

    /// Dropbox が Mac にセットアップされているか。未導入なら普通のフォルダを
    /// 作ってしまうだけで同期されないため、UI 側で選ばせない。
    static var isDropboxAvailable: Bool {
        FileManager.default.fileExists(atPath: dropboxRoot.path)
    }

    static var current: URL {
        guard let path = UserDefaults.standard.string(forKey: defaultsKey), !path.isEmpty else {
            return local
        }
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    static func remember(_ url: URL) {
        if url == local {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        } else {
            UserDefaults.standard.set(url.path, forKey: defaultsKey)
        }
    }

    private static var dropboxRoot: URL {
        URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent("Library/CloudStorage/Dropbox", isDirectory: true)
    }
}
