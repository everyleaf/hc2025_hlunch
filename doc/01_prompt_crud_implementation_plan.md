# プロンプトのCRUD実装計画

## 目的

LLMを経由せずに、ユーザーが手書きでプロンプトのCRUD操作を行えるようにする

## データモデル

### Prompt (プロンプト)
- `id`: integer (primary key)
- `title`: string (タイトル)
- `prompt`: text (プロンプト本文)
- `created_at`: datetime
- `updated_at`: datetime

## 実装手順

### 1. データベースマイグレーション

#### 1.1 Promptテーブル作成
```bash
rails generate model Prompt title:string prompt:text
```

#### 1.2 マイグレーション実行
```bash
rails db:migrate
```

### 2. モデルの実装

#### 2.1 Promptモデル
- バリデーション:
  - `title`: presence, length (maximum: 255)
  - `prompt`: presence

### 3. ルーティング設定

#### 3.1 Promptsリソース
```ruby
Rails.application.routes.draw do
  root "prompts#index"

  resources :prompts
end
```

### 4. コントローラーの実装

#### 4.1 PromptsController
- アクション:
  - `index`: プロンプト一覧
  - `show`: プロンプト詳細
  - `new`: 新規プロンプト作成フォーム
  - `create`: プロンプト作成
  - `edit`: プロンプト編集フォーム
  - `update`: プロンプト更新
  - `destroy`: プロンプト削除

### 5. ビューの実装

#### 5.1 Prompts views
- `index.html.erb`: プロンプト一覧
  - 各プロンプトのタイトル、作成日時
  - 詳細、編集、削除リンク
  - 新規作成リンク

- `show.html.erb`: プロンプト詳細
  - タイトル、プロンプト本文
  - 編集、削除、一覧に戻るリンク

- `new.html.erb / edit.html.erb`: フォーム
  - タイトル入力フィールド
  - プロンプト入力フィールド(textarea)
  - 送信ボタン

- `_form.html.erb`: フォーム部分テンプレート

### 6. テスト実装

#### 6.1 モデルテスト
- `test/models/prompt_test.rb`
  - バリデーションテスト
    - titleが空の場合は無効
    - promptが空の場合は無効
    - titleが255文字を超える場合は無効
    - 正常な値の場合は有効

#### 6.2 Request spec
- `test/requests/prompts_test.rb`
  - index: プロンプト一覧が表示される
  - show: プロンプト詳細が表示される
  - new: 新規作成フォームが表示される
  - create: プロンプトが作成される
  - edit: 編集フォームが表示される
  - update: プロンプトが更新される
  - destroy: プロンプトが削除される

### 7. スタイリング

#### 7.1 基本レイアウト
- Railsデフォルトのアセットパイプラインを使用
- シンプルで使いやすいUI
- レスポンシブデザイン対応

#### 7.2 フラッシュメッセージ
- 成功メッセージ: プロンプトが作成/更新/削除された時
- エラーメッセージ: バリデーションエラー時

## 実装の注意点

1. **バリデーション**: 必須項目の入力チェック
2. **エラーハンドリング**: フォーム送信時のエラー表示
3. **削除確認**: データ削除時の確認ダイアログ (data-turbo-method="delete", data-turbo-confirm)
4. **テストの実行**: 各実装後にテストを実行して動作確認
5. **小さなコミット**: 機能ごとに意味のある単位でコミット

## 完了条件

- [ ] データベースマイグレーション完了
- [ ] モデルとバリデーション実装完了
- [ ] PromptsControllerのCRUD実装完了
- [ ] すべてのビュー実装完了
- [ ] テストがすべて通る
- [ ] ブラウザで動作確認完了
