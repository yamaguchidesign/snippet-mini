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
- データはローカルの JSON に保存（クラウド送信なし）

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

📄 → **「スニペットを管理…」** で管理ウィンドウを開き、タイトルと本文を登録。
並び替え・編集・削除もここで行う。

### 4. ショートカットを割り当てる

内蔵ホットキーは持たず、URL スキームで呼び出す方式。BetterTouchTool などで
好きなキーに以下の URL を割り当てる（アクション =「Open URL」）。

| URL | 動作 |
| --- | --- |
| `snippetmini://pick` | 選択パネルを表示（おすすめ） |
| `snippetmini://toggle` | 押すたび表示 / 非表示を切り替え |
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

```
~/Library/Application Support/SnippetMini/snippets.json
```

すべてローカル保存。外部送信は行わない。

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
│   ├── PasteService.swift      # クリップボード操作 + ⌘V 送出
│   └── VariableExpander.swift  # {{date}} / {{newline}} などの変数展開
└── Views/
    ├── MenuBarContentView.swift  # メニューバーのメニュー
    ├── SnippetEditorView.swift   # スニペット管理ウィンドウ
    └── SnippetPickerView.swift   # 挿入用の選択パネル
```

## ライセンス

Private.
