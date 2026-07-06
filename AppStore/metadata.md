# Snippet Mini — App Store メタデータ

## アプリ名（30文字以内）
Snippet Mini

## サブタイトル（30文字以内）
定型文をどこでも即挿入

## カテゴリ
主: 仕事効率化 (Productivity)
副: ユーティリティ (Utilities)

## 価格
無料

## キーワード（100文字以内、カンマ区切り）
スニペット,定型文,テンプレート,効率化,テキスト,入力補助,ホットキー,メニューバー,日付,署名

## 説明文（日本語）

よく使う定型文を、どのアプリでもワンアクションで挿入。

Snippet Mini は Dock に載らず、メニューバーに常駐する軽量なスニペットツールです。テキスト入力中に ⌥⌘Space を押すとパネルが開き、上下キーで選んで Enter を押すだけで、いま開いているアプリにそのまま挿入されます。

【主な機能】
• ⌥⌘Space でどこでもスニペットパネルを表示
• 上下キーで選択、Enter で元のアプリに挿入
• 日付・改行の変数に対応（{{date}}、{{newline}}）
• スニペットの追加・編集・並べ替え
• 余計な機能なし、軽快な動作

【使い方】
1. テキスト入力中に ⌥⌘Space を押す
2. ↑↓ でスニペットを選ぶ
3. Enter で今いるアプリに挿入（Esc で閉じる）

【変数一覧】
• {{date}} … 今日の日付（yyyy/MM/dd）
• {{newline}} または \n … 改行

メールの署名、チャットの挨拶、日報の定型文など、毎日繰り返す入力を短くしたい方に。

※ 他のアプリへ挿入するには、初回にシステム設定「プライバシーとセキュリティ › アクセシビリティ」で本アプリを許可してください。許可しない場合はクリップボードへのコピーとして動作します。

## プロモーション用テキスト（170文字以内）
テキスト入力中に ⌥⌘Space。開いたパネルから定型文を選んで Enter を押すだけで、そのアプリに即挿入。日付・改行の変数にも対応した、軽快なメニューバー常駐アプリです。

## サポート URL
https://github.com/yamaguchidesign/snippet-mini/issues

## マーケティング URL（任意）
https://github.com/yamaguchidesign/snippet-mini

## プライバシーポリシー URL
https://yamaguchidesign.github.io/snippet-mini/privacy.html

## 著作権
© 2026 Yamaguchi Shohei

## 年齢制限
4+

## App Store Connect — プライバシー質問
- データ収集: なし
- 第三者共有: なし
- トラッキング: なし
- 収集するデータ型: 該当なし（すべて端末内に保存）

## 審査ノート（App Review Information → Notes に貼る）

日本語版:
------------------------------------------------------------
Snippet Mini は、ユーザーが事前に登録した定型文（スニペット）を、
ユーザー自身の操作で任意のテキストフィールドに挿入するユーティリティです。

・グローバルホットキー（⌥⌘Space）で選択パネルを表示します。
・ユーザーが上下キーでスニペットを選び、Enter を押した場合のみ、
  直前にフォアグラウンドだったアプリへテキストを挿入します。
・挿入は、クリップボードにテキストを設定し、⌘V 相当のキーストローク
  （CGEvent）を送出することで行います。
・このキーストローク送出には macOS のアクセシビリティ許可が必要です。
  許可はユーザーがシステム設定で明示的に付与し、アプリ内でも用途を説明します。
・アクセシビリティが許可されていない場合は、テキストをクリップボードに
  コピーするだけの動作にフォールバックし、機能は成立します。

本アプリは他アプリの内容を読み取ったり、監視したりしません。
アクセシビリティは「ユーザーが選んだ定型文を挿入する」目的のみに使用します。
ネットワーク通信・データ収集・トラッキングは一切行いません。
すべてのデータは端末内（App Sandbox 内）に保存されます。

動作確認手順:
1. アプリを起動（メニューバーにアイコンが表示されます）。
2. システム設定 › プライバシーとセキュリティ › アクセシビリティ で
   Snippet Mini を許可。
3. テキストエディタ等で ⌥⌘Space を押し、スニペットを選んで Enter。
------------------------------------------------------------

English version:
------------------------------------------------------------
Snippet Mini is a utility that inserts user-defined text snippets into any
text field, triggered explicitly by the user.

- A global hotkey (Option-Command-Space) shows a picker panel.
- Only when the user selects a snippet with arrow keys and presses Enter
  does the app insert text into the app that was frontmost.
- Insertion is done by placing text on the pasteboard and posting a
  Command-V keystroke (CGEvent).
- This keystroke posting requires the macOS Accessibility permission, which
  the user grants explicitly in System Settings. The app explains the purpose.
- If Accessibility is not granted, the app falls back to simply copying the
  text to the clipboard, so the app remains functional.

The app does not read or monitor the contents of other apps. Accessibility
is used solely to insert the snippet the user chose. No network requests,
no data collection, no tracking. All data is stored locally within the
App Sandbox.

How to test:
1. Launch the app (a menu bar icon appears).
2. Grant Accessibility to Snippet Mini in System Settings ›
   Privacy & Security › Accessibility.
3. In a text editor, press Option-Command-Space, pick a snippet, press Enter.
------------------------------------------------------------

## スクリーンショット要件（macOS）
- 1280 x 800 以上（推奨: 2880 x 1800 Retina）
- 最低 1 枚、最大 10 枚
- 保存先: `AppStore/screenshots/`
