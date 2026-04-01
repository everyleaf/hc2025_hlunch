# Issue #9: ロゴ画像の導入とグローバルナビゲーション作成

## Context

issue #9 で1024x1024のロゴ画像が作成された。これをWebアプリのlayoutとREADME.mdに組み込む。
現状layoutにはnavbarが存在しないため、Bootstrapのnavbarを新規作成してロゴを配置する。

## 実装ステップ

### Step 1: ロゴ画像を配置
- ダウンロード済みのロゴ画像(`/tmp/claude/hlunch_logo.png`)を `app/assets/images/logo.png` にコピー
- README用にも `images/logo.png` にコピー

### Step 2: layoutにBootstrap navbarを追加
- `app/views/layouts/application.html.erb` の `<body>` 直後にnavbarを追加
- navbarの内容:
  - ロゴ画像（`image_tag`で表示、高さ30px程度に縮小）+ アプリ名をbrandとして配置、root_pathへリンク
  - 「プロンプト一覧」リンク (`prompts_path`)
  - 「プロンプト合成」リンク (`compose_form_prompts_path`)
- Bootstrap標準のレスポンシブnavbar（`navbar-expand-lg`）を使用
- flashメッセージはnavbarの下に表示（現状の位置を維持）

### Step 3: README.mdにロゴを追加
- `# hlunch` の直下にロゴ画像を表示（`![hlunch ロゴ](./images/logo.png)` のような形式）

## 対象ファイル
- `app/assets/images/logo.png` (新規)
- `images/logo.png` (新規)
- `app/views/layouts/application.html.erb` (編集)
- `README.md` (編集)

## 検証
- `bin/dev` でサーバー起動し、各ページでnavbarとロゴが表示されることを確認
- navbarのリンクが正しく機能することを確認
- レスポンシブ（モバイル幅）でハンバーガーメニューが動作することを確認
- `bundle exec rspec` でテストが通ることを確認
