# Snippet Mini

よく使う定型文（スニペット）を、メニューバーや外部ツールのショートカットから
どのアプリにも即挿入できる macOS 常駐アプリ。

メール・Slack・Figma のテキストなど、繰り返し打つ文章をワンアクションで貼り付ける。

## 特徴

- **メニューバー常駐**（📄 アイコン）。Dock には出ない軽量アプリ
- **URL スキーム `snippetmini://`** で選択パネルを呼び出し。ホットキーは
  BetterTouchTool / Raycast / Shortcuts など好きなツールで自由に割り当てられる
- 選ぶと**直前に使っていたアプリへ自動ペースト**（⌘V を送出）
- **変数展開**で日付・改行を自動挿入
- データはローカルの JSON に保存。保存先を Dropbox 等の同期フォルダに変えれば**複数の Mac で同期**できる

## 必要環境

- macOS 14.0 以降
- 自動ペーストに **アクセシビリティ権限** が必要

## 使い方

### 1. 起動

ビルド済みアプリを起動するか、Xcode から実行する（下記「ビルド」参照）。
起動するとメニューバーに 📄 アイコンが出る。

### 2. アクセシビリティ権限を許可（初回のみ）

自動ペーストには権限が必要。メニューバーの 📄 → **「アクセシビリティを許可…」** から
`システム設定 → プライバシーとセキュリティ → アクセシビリティ` を開き、
**SnippetMini** をオンにする。

> 権限が無くてもパネルは開くが、貼り付けは実行されない。

### 3. スニペットを登録

管理ウィンドウを開いてタイトルと本文を登録する。開き方は次のいずれか。

- メニューバー 📄 → **「スニペットを管理…」**
- 選択パネル右上の **⚙️ アイコン**
- `snippetmini://settings`（ショートカットに割り当ても可）

並び替え・編集・削除も管理ウィンドウで行う。管理ウィンドウは自動では開かず、
上記の操作をしたときだけ開く。

### 4. ショートカットを割り当てる

内蔵ホットキーは持たず、URL スキームで呼び出す方式。BetterTouchTool などで
好きなキーに以下の URL を割り当てる（アクション =「Open URL」）。

| URL | 動作 |
| --- | --- |
| `snippetmini://pick` | 選択パネルを表示（おすすめ） |
| `snippetmini://toggle` | 押すたび表示 / 非表示を切り替え |
| `snippetmini://settings` | スニペット管理ウィンドウを開く |
| `snippetmini://` | `pick` と同じ |

> `⌥⌘Space` は macOS 標準の「Finder 検索ウィンドウ」に予約済みなので避ける。

### 5. 挿入

ショートカット（または 📄 →「スニペットを挿入…」）で選択パネルを開き、
スニペットを選ぶと直前に使っていたアプリへ貼り付けられる。

### 自動起動（任意）

`システム設定 → 一般 → ログイン項目` に `/Applications/SnippetMini.app` を追加すると、
常駐が途切れずショートカットからいつでも呼べる。

## 変数

スニペット本文に書くと、挿入時に自動変換される。

| 記法 | 変換結果 |
| --- | --- |
| `{{date}}` | 今日の日付（例: `2026/07/09`、ja_JP・ローカルタイムゾーン） |
| `{{newline}}` | 改行 |
| `\n` | 改行 |

初期スニペットとして「日付付き挨拶」「署名」が入っている。

## データの保存場所

デフォルトはローカル。

```
~/Library/Application Support/SnippetMini/snippets.json
```

開発者のサーバーへの送信は行わない。

## 複数の Mac で同期する

保存先を Dropbox などの同期フォルダに変えると、複数の Mac で同じスニペットを使える。
管理ウィンドウ右上の 🔄 → **「Dropbox に保存」**（または「フォルダを選択…」）。
同期したい Mac すべてで同じ保存先を選ぶ。

```
~/Library/CloudStorage/Dropbox/app_setting/snippet_mini/snippets.json
```

- 同じ画面の **「Finder で表示」** で、いま使っている `snippets.json` を Finder で開ける
- 保存先を切り替えると、移行先に既存のスニペットがあれば**統合**される（どちらも消えない）
- 他の Mac の変更はファイル監視で**自動的に取り込む**（アプリの再起動は不要）
- 同じスニペットを両方の Mac で編集した場合は、**後に編集した方**が残る
- 削除は墓標（`deletedAt`）として 30 日間保持し、他の Mac に伝わってから消える

> 同期フォルダに置くと、スニペットの中身がそのクラウドサービスに保存される。
> 業務の文面を扱う場合は、会社のポリシーに沿った同期先を選ぶこと。

## ビルド

プロジェクトは [XcodeGen](https://github.com/yonyz/XcodeGen)（`project.yml`）で管理。

```sh
# .xcodeproj を生成（project.yml を変更した場合）
xcodegen

# Release ビルド
xcodebuild -project SnippetMini.xcodeproj -scheme SnippetMini -configuration Release build
```

または `SnippetMini.xcodeproj` を Xcode で開いて ⌘R で実行。

## プロジェクト構成

```
SnippetMini/
├── SnippetMiniApp.swift        # エントリポイント（MenuBarExtra + 管理ウィンドウ）
├── AppDelegate.swift           # URL スキーム(snippetmini://)の受信・ピッカー初期化
├── Models/
│   └── Snippet.swift           # スニペットのデータモデル
├── Services/
│   ├── SnippetStore.swift      # 保存・読み込み・CRUD（JSON 永続化）
│   ├── SnippetPickerController.swift # 選択パネルの表示制御
│   ├── EditorWindowController.swift  # 管理ウィンドウの開閉（AppKit）
│   ├── PasteService.swift      # クリップボード操作 + ⌘V 送出
│   └── VariableExpander.swift  # {{date}} / {{newline}} などの変数展開
└── Views/
    ├── MenuBarContentView.swift  # メニューバーのメニュー
    ├── SnippetEditorView.swift   # スニペット管理ウィンドウ
    └── SnippetPickerView.swift   # 挿入用の選択パネル
```

## ライセンス

Private.
