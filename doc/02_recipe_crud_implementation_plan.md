# レシピのCRUD実装計画

## 目的

LLMを経由せずに、ユーザーが手書きでレシピのCRUD操作を行えるようにする

## データモデル

### Recipe (レシピ)
- `id`: integer (primary key)
- `prompt_id`: integer (外部キー、Promptへの参照)
- `title`: string (タイトル)
- `ingredients`: text (材料)
- `instructions`: text (作り方)
- `created_at`: datetime
- `updated_at`: datetime

### リレーション
- Recipe belongs_to :prompt
- Prompt has_many :recipes

## 実装手順

### 1. データベースマイグレーション

#### 1.1 Recipeテーブル作成
```bash
rails generate model Recipe prompt:references title:string ingredients:text instructions:text
```

#### 1.2 マイグレーション実行
```bash
rails db:migrate
```

### 2. モデルの実装

#### 2.1 Recipeモデル
- バリデーション:
  - `title`: presence, length (maximum: 255)
  - `ingredients`: presence
  - `instructions`: presence
  - `prompt_id`: presence
- アソシエーション:
  - `belongs_to :prompt`

#### 2.2 Promptモデルの更新
- アソシエーション追加:
  - `has_many :recipes, dependent: :destroy`

### 3. ルーティング設定

#### 3.1 RecipesリソースとPromptとのネスト
```ruby
resources :prompts do
  resources :recipes, only: [:new, :create]
end

resources :recipes, only: [:show, :edit, :update, :destroy]
```

### 4. コントローラーの実装

#### 4.1 RecipesController
- アクション:
  - `new`: 新規レシピ作成フォーム（プロンプト指定）
  - `create`: レシピ作成
  - `show`: レシピ詳細
  - `edit`: レシピ編集フォーム
  - `update`: レシピ更新
  - `destroy`: レシピ削除

### 5. ビューの実装

#### 5.1 Recipes views
- `show.html.erb`: レシピ詳細
  - タイトル、材料、作り方
  - 関連プロンプトへのリンク
  - 編集、削除リンク

- `new.html.erb / edit.html.erb`: フォーム
  - タイトル入力フィールド
  - 材料入力フィールド(textarea)
  - 作り方入力フィールド(textarea)
  - 送信ボタン

- `_form.html.erb`: フォーム部分テンプレート

#### 5.2 Prompts views の更新
- `show.html.erb`: プロンプト詳細ページに関連レシピ一覧を追加
  - レシピのタイトル一覧
  - 各レシピへのリンク
  - 新規レシピ作成リンク

### 6. テスト実装

#### 6.1 モデルテスト
- `test/models/recipe_test.rb`
  - バリデーションテスト
    - titleが空の場合は無効
    - ingredientsが空の場合は無効
    - instructionsが空の場合は無効
    - titleが255文字を超える場合は無効
    - 正常な値の場合は有効
  - アソシエーションテスト
    - promptに紐づいている

#### 6.2 Request spec
- `test/requests/recipes_test.rb`
  - show: レシピ詳細が表示される
  - new: 新規作成フォームが表示される
  - create: レシピが作成される
  - edit: 編集フォームが表示される
  - update: レシピが更新される
  - destroy: レシピが削除される

## 実装の注意点

1. **外部キー制約**: prompt_idは必須
2. **dependent: :destroy**: プロンプト削除時に関連レシピも削除
3. **ネストしたルーティング**: 新規作成はプロンプトから
4. **バリデーション**: 必須項目の入力チェック
5. **エラーハンドリング**: フォーム送信時のエラー表示
6. **削除確認**: データ削除時の確認ダイアログ
7. **テストの実行**: 各実装後にテストを実行して動作確認
8. **小さなコミット**: 機能ごとに意味のある単位でコミット

## 完了条件

- [ ] データベースマイグレーション完了
- [ ] モデルとバリデーション実装完了
- [ ] アソシエーション設定完了
- [ ] RecipesControllerのCRUD実装完了
- [ ] すべてのビュー実装完了
- [ ] Promptsビューの更新完了
- [ ] テストがすべて通る
- [ ] ブラウザで動作確認完了
