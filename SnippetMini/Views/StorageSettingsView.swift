import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 同期する snippets.json 本体、またはそれを置くフォルダを Finder のパネルから選ばせる。
/// 返り値は保存先フォルダ（ファイルを選んだ場合はその親フォルダ）。
@MainActor
enum SnippetSyncFilePicker {
    static func choose(startingAt directory: URL) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.prompt = "選択"
        panel.message = "同期する snippets.json、またはそれを置くフォルダを選んでください。"
        panel.directoryURL = directory

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return isDirectory.boolValue ? url : url.deletingLastPathComponent()
    }
}

struct StorageSettingsView: View {
    @EnvironmentObject private var store: SnippetStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("保存先")
                .font(.headline)

            Text("Dropbox など同期フォルダを指定すると、複数の Mac で同じスニペットを使えます。両方の Mac で同じ保存先を選んでください。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .foregroundStyle(.secondary)
                Text(store.fileURL.path)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)

                Spacer(minLength: 8)

                Button("Finder で表示") {
                    store.revealInFinder()
                }
                .controlSize(.small)
                .fixedSize()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )

            HStack {
                Button("Dropbox に保存") {
                    store.setStorageDirectory(SnippetStorageLocation.dropbox)
                }
                .disabled(!SnippetStorageLocation.isDropboxAvailable
                          || store.storageDirectory == SnippetStorageLocation.dropbox)

                Button("この Mac のみ") {
                    store.setStorageDirectory(SnippetStorageLocation.local)
                }
                .disabled(store.storageDirectory == SnippetStorageLocation.local)

                Button("Finder から選択…") {
                    chooseFromFinder()
                }
            }

            if !SnippetStorageLocation.isDropboxAvailable {
                Label("この Mac では Dropbox が見つかりません。", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("保存先を切り替えると、移行先にすでにスニペットがある場合は統合されます（どちらの内容も消えません）。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("閉じる") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 480)
    }

    private func chooseFromFinder() {
        guard let directory = SnippetSyncFilePicker.choose(startingAt: store.storageDirectory) else { return }
        store.setStorageDirectory(directory)
    }
}
